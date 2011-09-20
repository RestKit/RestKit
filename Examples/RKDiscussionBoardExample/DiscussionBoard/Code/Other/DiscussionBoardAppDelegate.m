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
#import <RestKit/CoreData/CoreData.h>
#import <RestKit/Support/JSON/JSONKit/RKJSONParserJSONKit.h>
#import <RestKit/Support/JSON/SBJSON/RKJSONParserSBJSON.h>
#import <RestKit/Support/JSON/YAJL/RKJSONParserYAJL.h>

// Three20
#import <Three20/Three20.h>
#import <Three20/Three20+Additions.h>

// Discussion Board
#import "DBManagedObjectCache.h"
#import "../Controllers/DBTopicViewController.h"
#import "../Controllers/DBTopicsTableViewController.h"
#import "../Controllers/DBPostsTableViewController.h"
#import "../Controllers/DBPostTableViewController.h"
#import "../Controllers/DBLoginOrSignUpViewController.h"
#import "../Models/DBTopic.h"
#import "../Models/DBPost.h"
#import "../Models/DBUser.h"

/**
 * The HTTP Header Field we transmit the authentication token obtained
 * during login/sign-up back to the server. This token is verified server
 * side to establish an authenticated session
 */
static NSString* const kDBAccessTokenHTTPHeaderField = @"X-USER-ACCESS-TOKEN";

@implementation DiscussionBoardAppDelegate

@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
	// Initialize the RestKit Object Manager
	RKObjectManager* objectManager = [RKObjectManager objectManagerWithBaseURL:DBRestKitBaseURL];

	// Set the default refresh rate to 1. This means we should always hit the web if we can.
	// If the server is unavailable, we will load from the Core Data cache.
	[RKObjectLoaderTTModel setDefaultRefreshRate:1];

	// Initialize object store
	// We are using the Core Data support, so we have initialized a managed object store backed
	// with a SQLite database. We are also utilizing the managed object cache support to provide
	// offline access to locally cached content.
	objectManager.objectStore = [[[RKManagedObjectStore alloc] initWithStoreFilename:@"DiscussionBoard.sqlite"] autorelease];
	objectManager.objectStore.managedObjectCache = [[DBManagedObjectCache new] autorelease];

	// Set Up the Object Mapper
	// The object mapper is responsible for mapping JSON encoded representations of objects
	// back to local object representations. Here we instruct RestKit how to connect
	// sub-dictionaries of attributes to local classes.
    RKManagedObjectMapping* userMapping = [RKManagedObjectMapping mappingForClass:[DBUser class]];
    userMapping.primaryKeyAttribute = @"userID";
    userMapping.setDefaultValueForMissingAttributes = YES; // clear out any missing attributes (token on logout)
    [userMapping mapKeyPathsToAttributes:
     @"id", @"userID",
     @"email", @"email",
     @"username", @"username",
     @"single_access_token", @"singleAccessToken",
     @"password", @"password",
     @"password_confirmation", @"passwordConfirmation",
     nil];
    
    RKManagedObjectMapping* topicMapping = [RKManagedObjectMapping mappingForClass:[DBTopic class]];
    /**
     * Informs RestKit which property contains the primary key for identifying
     * this object. This is used to ensure that objects are updated
     */
    topicMapping.primaryKeyAttribute = @"topicID";
    
    /**
     * Map keyPaths in the JSON to attributes of the DBTopic entity
     */
    [topicMapping mapKeyPathsToAttributes:
     @"id", @"topicID",
     @"name", @"name",
     @"user_id", @"userID",
     @"created_at", @"createdAt",
     @"updated_at", @"updatedAt",
     nil];
    
    /**
     * Informs RestKit which properties contain the primary key values that
     * can be used to hydrate relationships to other objects. This hint enables
     * RestKit to automatically maintain true Core Data relationships between objects
     * in your local store.
     *
     * Here we have asked RestKit to connect the 'user' relationship by performing a
     * primary key lookup with the value in 'userID' property. This is the declarative
     * equivalent of doing self.user = [DBUser objectWithPrimaryKeyValue:self.userID];
     */
    [topicMapping mapRelationship:@"user" withMapping:userMapping];
    
    RKManagedObjectMapping* postMapping = [RKManagedObjectMapping mappingForClass:[DBPost class]];
    postMapping.primaryKeyAttribute = @"postID";
    [postMapping mapKeyPathsToAttributes:
     @"id",@"postID",
     @"topic_id",@"topicID",
     @"user_id",@"userID",
     @"created_at",@"createdAt",
     @"updated_at",@"updatedAt",
     @"attachment_content_type", @"attachmentContentType",
     @"attachment_file_name", @"attachmentFileName",
     @"attachment_file_size", @"attachmentFileSize",
     @"attachment_path", @"attachmentPath",
     @"attachment_updated_at", @"attachmentUpdatedAt",
     @"body", @"body",
    nil];
    [postMapping mapRelationship:@"user" withMapping:userMapping];
    
    // Register the mappings with the mapping provider. Use of registerMapping:withRootKeyPath:
    // configures the mapping provider with both object and serialization mappings for the specified
    // keyPath.
    [objectManager.mappingProvider registerMapping:userMapping withRootKeyPath:@"user"];
    [objectManager.mappingProvider registerMapping:topicMapping withRootKeyPath:@"topic"];
    [objectManager.mappingProvider registerMapping:postMapping withRootKeyPath:@"post"];

	// Set Up Router
	// The router is responsible for generating the appropriate resource path to
	// GET/POST/PUT/DELETE an object representation. This prevents your code from
	// becoming littered with identical resource paths as you manipulate common 
	// objects across your application. Note that a single object representation
	// can be loaded from any number of resource paths. You can also PUT/POST
	// an object to arbitrary paths by configuring the object loader yourself. The
	// router is just for configuring the default 'home address' for an object.
	[objectManager.router routeClass:[DBUser class] toResourcePath:@"/signup" forMethod:RKRequestMethodPOST];
	[objectManager.router routeClass:[DBUser class] toResourcePath:@"/login" forMethod:RKRequestMethodPUT];

	[objectManager.router routeClass:[DBTopic class] toResourcePath:@"/topics" forMethod:RKRequestMethodPOST];
	[objectManager.router routeClass:[DBTopic class] toResourcePath:@"/topics/(topicID)" forMethod:RKRequestMethodPUT];
	[objectManager.router routeClass:[DBTopic class] toResourcePath:@"/topics/(topicID)" forMethod:RKRequestMethodDELETE];

	[objectManager.router routeClass:[DBPost class] toResourcePath:@"/topics/(topicID)/posts" forMethod:RKRequestMethodPOST];
	[objectManager.router routeClass:[DBPost class] toResourcePath:@"/topics/(topicID)/posts/(postID)" forMethod:RKRequestMethodPUT];
	[objectManager.router routeClass:[DBPost class] toResourcePath:@"/topics/(topicID)/posts/(postID)" forMethod:RKRequestMethodDELETE];
    
    /**
     Configure RestKit Logging
     
     RestKit ships with a robust logging framework that can be used to instrument
     the libraries activities in great detail. Logging is configured by specifying a
     logging component and a log level to use for that component.
     
     By default, RestKit is configured to log at the Info or Warning levels for all components
     depending on the presence of the DEBUG pre-processor macro. This can be configured at run-time
     via calls to RKLogConfigureByName as detailed below.
     
     See RKLog.h and lcl_log_components.h for details on the logging macros available
     */    
    RKLogConfigureByName("RestKit", RKLogLevelTrace);
    RKLogConfigureByName("RestKit/Network", RKLogLevelDebug);
    RKLogConfigureByName("RestKit/ObjectMapping", RKLogLevelDebug);
    RKLogConfigureByName("RestKit/Network/Queue", RKLogLevelDebug);
    
    // Enable boatloads of trace info from the mapper
    // RKLogConfigureByName("RestKit/ObjectMapping", RKLogLevelTrace);
    
    /**
     Enable verbose logging for the App component. 
     
     This component is exported by RestKit to allow you to leverage the same logging
     facilities and macros in your app that are used internally by the library. When
     you #import <RestKit/RestKit.h>, the default logging component is set to 'App'
     for you. Calls to RKLog() within your application will log at the level specified below.
     */
    RKLogSetAppLoggingLevel(RKLogLevelTrace);
    
    RKLogDebug(@"Discussion Board is starting up...");
    
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
		RKLogInfo(@"Found logged in User record for username '%@' [Access Token: %@]", user.username, user.singleAccessToken);
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
