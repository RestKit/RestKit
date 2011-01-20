//
//  DiscussionBoardAppDelegate.m
//  DiscussionBoard
//
//  Created by Daniel Hammond on 1/7/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "DiscussionBoardAppDelegate.h"

// RestKit
#import <RestKit/RestKit.h>
#import <RestKit/ObjectMapping/RKDynamicRouter.h>
#import <RestKit/ObjectMapping/RKRailsRouter.h>

// Three20
#import <Three20/Three20.h>
#import <Three20/Three20+Additions.h>

// Discussion Board
#import "DBTopicsTableViewController.h"
#import "DBTopic.h"
#import "DBPostsTableViewController.h"
#import "DBPost.h"
#import "DBManagedObjectCache.h"
#import "DBTopicViewController.h"
#import "DBLoginOrSignUpViewController.h"
#import "DBUser.h"
#import "DBPostTableViewController.h"

/**
 * The HTTP Header Field we transmit the authentication token obtained
 * during login/sign-up back to the server. This token is verified server
 * side to establish an authenticated session
 */
static NSString* const kDBAccessTokenHTTPHeaderField = @"X-USER-ACCESS-TOKEN";

@implementation DiscussionBoardAppDelegate

@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	// Initialize object manager
	RKObjectManager* objectManager = [RKObjectManager objectManagerWithBaseURL:DBRestKitBaseURL];

	// Set the default refresh rate to 1. This means we should always hit the web if we can.
	// If the server is unavailable, we will load from the core data cache.
	[RKRequestTTModel setDefaultRefreshRate:1];

	// Do not overwrite properties that are missing in the payload to nil.
	// TODO: Fix! There is a bug where elements that are in the payload
//	objectManager.mapper.missingElementMappingPolicy = RKIgnoreMissingElementMappingPolicy;
	objectManager.mapper.missingElementMappingPolicy = RKSetNilForMissingElementMappingPolicy;

	// Initialize object store
	objectManager.objectStore = [[[RKManagedObjectStore alloc] initWithStoreFilename:@"DiscussionBoard.sqlite"] autorelease];
	objectManager.objectStore.managedObjectCache = [[DBManagedObjectCache new] autorelease];

	// Set Up Mapper
	RKObjectMapper* mapper =  objectManager.mapper;
	[mapper registerClass:[DBTopic class] forElementNamed:@"topic"];
	[mapper registerClass:[DBPost class] forElementNamed:@"post"];

	// Set Up Router
	// TODO: Comment me!
	RKRailsRouter* router = [[[RKRailsRouter alloc] init] autorelease];
	[router setModelName:@"user" forClass:[DBUser class]];
	[router routeClass:[DBUser class] toResourcePath:@"/signup" forMethod:RKRequestMethodPOST];
	[router routeClass:[DBUser class] toResourcePath:@"/login" forMethod:RKRequestMethodPUT];

	[router setModelName:@"topic" forClass:[DBTopic class]];
	[router routeClass:[DBTopic class] toResourcePath:@"/topics" forMethod:RKRequestMethodPOST];
	[router routeClass:[DBTopic class] toResourcePath:@"/topics/(topicID)" forMethod:RKRequestMethodPUT];
	[router routeClass:[DBTopic class] toResourcePath:@"/topics/(topicID)" forMethod:RKRequestMethodDELETE];

	[router setModelName:@"post" forClass:[DBPost class]];
	[router routeClass:[DBPost class] toResourcePath:@"/topics/(topicID)/posts" forMethod:RKRequestMethodPOST];
	[router routeClass:[DBPost class] toResourcePath:@"/topics/(topicID)/posts/(postID)" forMethod:RKRequestMethodPUT];
	[router routeClass:[DBPost class] toResourcePath:@"/topics/(topicID)/posts/(postID)" forMethod:RKRequestMethodDELETE];

	objectManager.router = router;

	// Initialize Three20
	TTURLMap* map = [[TTNavigator navigator] URLMap];
	[map from:@"db://topics" toViewController:[DBTopicsTableViewController class]];
	[map from:@"db://topics/(initWithTopicID:)/posts" toViewController:[DBPostsTableViewController class]];
	[map from:@"db://topics/(initWithTopicID:)/edit" toViewController:[DBTopicViewController class]];
	[map from:@"db://topics/new" toViewController:[DBTopicViewController class]];
	[map from:@"db://posts/(initWithPostID:)" toViewController:[DBPostTableViewController class]];
	[map from:@"db://topics/(initWithTopicID:)/posts/new" toViewController:[DBPostTableViewController class]];
	[map from:@"db://login" toModalViewController:[DBLoginOrSignUpViewController class]];

	[map from:@"*" toViewController:[TTWebController class]];

	[[TTURLRequestQueue mainQueue] setMaxContentLength:0]; // Don't limit content length.	
	
	// Register for authentication notifications
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setAccessTokenHeaderFromAuthenticationNotification:) name:DBUserDidLoginNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setAccessTokenHeaderFromAuthenticationNotification:) name:DBUserDidLogoutNotification object:nil];
	
	// Initialize authenticated access if we have a logged in current User reference
	DBUser* user = [DBUser currentUser];
	if ([user isLoggedIn]) {
		NSLog(@"Found logged in User record for username '%@' [Access Token: %@]", user.username, user.singleAccessToken);
		[objectManager.client setValue:user.singleAccessToken forHTTPHeaderField:kDBAccessTokenHTTPHeaderField];
	}
	
	// Fire up the UI!
	TTOpenURL(@"db://topics");
	[[TTNavigator navigator].window makeKeyAndVisible];

	return YES;
}

// Watch for login/logout events and set the Access Token HTTP Header
- (void)setAccessTokenHeaderFromAuthenticationNotification:(NSNotification*)notification {
	DBUser* user = (DBUser*) [notification object];
	RKObjectManager* objectManager = [RKObjectManager sharedManager];
	[objectManager.client setValue:user.singleAccessToken forHTTPHeaderField:kDBAccessTokenHTTPHeaderField];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [window release];
    [super dealloc];
}

@end
