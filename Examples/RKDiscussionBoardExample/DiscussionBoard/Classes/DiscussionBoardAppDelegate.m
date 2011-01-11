//
//  DiscussionBoardAppDelegate.m
//  DiscussionBoard
//
//  Created by Daniel Hammond on 1/7/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "DiscussionBoardAppDelegate.h"
#import <RestKit/RestKit.h>
#import <RestKit/ObjectMapping/RKDynamicRouter.h>
#import <Three20/Three20.h>
#import <Three20/Three20+Additions.h>
#import "DBTopicsTableViewController.h"
#import "DBTopic.h"
#import "DBPostsTableViewController.h"
#import "DBPost.h"
#import "DBManagedObjectCache.h"
#import "DBTopicViewController.h"
#import "DBLoginViewController.h"
#import "DBUser.h"
#import "DBPostTableViewController.h"

static NSString* const kAccessTokenHeaderField = @"HTTP_USER_ACCESS_TOKEN";

@implementation DiscussionBoardAppDelegate

@synthesize window;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
	// Initialize object manager
	RKObjectManager* objectManager = [RKObjectManager objectManagerWithBaseURL:kDBBaseURLString];
	
	// Set the default refresh rate to 1. This means we should always hit the web if we can.
	// If the server is unavailable, we will load from the core data cache.
	[RKRequestTTModel setDefaultRefreshRate:1];
	
	// Do not overwrite properties that are missing in the payload to nil.
	objectManager.mapper.missingElementMappingPolicy = RKIgnoreMissingElementMappingPolicy;
	
	// Initialize object store
	objectManager.objectStore = [[[RKManagedObjectStore alloc] initWithStoreFilename:@"DiscussionBoard.sqlite"] autorelease];
	objectManager.objectStore.managedObjectCache = [[DBManagedObjectCache new] autorelease];
	
	// Set Up Mapper
	RKObjectMapper* mapper =  objectManager.mapper;
	[mapper registerClass:[DBTopic class] forElementNamed:@"topic"];
	[mapper registerClass:[DBPost class] forElementNamed:@"post"];
	
	// Set Up Router
	RKDynamicRouter* router = [[[RKDynamicRouter alloc] init] autorelease];
	[router routeClass:[DBUser class] toResourcePath:@"/signup" forMethod:RKRequestMethodPOST];
	[router routeClass:[DBUser class] toResourcePath:@"/login" forMethod:RKRequestMethodPUT];
	
	[router routeClass:[DBTopic class] toResourcePath:@"/topics" forMethod:RKRequestMethodPOST];
	[router routeClass:[DBTopic class] toResourcePath:@"/topics/(topicID)" forMethod:RKRequestMethodPUT];
	[router routeClass:[DBTopic class] toResourcePath:@"/topics/(topicID)" forMethod:RKRequestMethodDELETE];
	
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
	[map from:@"db://login" toModalViewController:[DBLoginViewController class]];
	
	
	[map from:@"*" toViewController:[TTWebController class]];
	
	TTOpenURL(@"db://topics");
	[[TTNavigator navigator].window makeKeyAndVisible];
	
	// Authentication
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLoggedIn:) name:kUserLoggedInNotificationName object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userLoggedOut:) name:kUserLoggedOutNotificationName object:nil];
	DBUser* user = [DBUser currentUser];
	NSLog(@"Token: %@", user.singleAccessToken);
	NSLog(@"User: %@", user);
	[objectManager.client setValue:[DBUser currentUser].singleAccessToken forHTTPHeaderField:@"USER_ACCESS_TOKEN"];
	
	// Testing
	TTOpenURL(@"db://posts/9");
	
	return YES;
}

- (void)userLoggedIn:(NSNotification*)note {
	RKObjectManager* objectManager = [RKObjectManager sharedManager];
	[objectManager.client setValue:[DBUser currentUser].singleAccessToken forHTTPHeaderField:kAccessTokenHeaderField];
}

- (void)userLoggedOut:(NSNotification*)note {
	RKObjectManager* objectManager = [RKObjectManager sharedManager];
	[objectManager.client setValue:nil forHTTPHeaderField:kAccessTokenHeaderField];
}


- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


- (void)dealloc {
    [window release];
    [super dealloc];
}


@end
