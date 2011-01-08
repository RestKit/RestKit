//
//  DiscussionBoardAppDelegate.m
//  DiscussionBoard
//
//  Created by Daniel Hammond on 1/7/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "DiscussionBoardAppDelegate.h"
#import <RestKit/RestKit.h>
#import <Three20/Three20.h>
#import <Three20/Three20+Additions.h>
#import "DBTopicsTableViewController.h"
#import "DBTopic.h"

@implementation DiscussionBoardAppDelegate

@synthesize window;


#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
	// Initialize object manager
	RKObjectManager* objectManager = [RKObjectManager objectManagerWithBaseURL:kDBBaseURLString];
	
	// Initialize object store
	objectManager.objectStore = [[[RKManagedObjectStore alloc] initWithStoreFilename:@"DiscussionBoard.sqlite"] autorelease];
	
	RKObjectMapper* mapper =  objectManager.mapper;
	
	[mapper registerClass:[DBTopic class] forElementNamed:@"topic"];
	
	// Initialize Three20
	TTURLMap* map = [[TTNavigator navigator] URLMap];
	[map from:@"db://topics" toViewController:[DBTopicsTableViewController class]];
	
	
	TTOpenURL(@"db://topics");
	[[TTNavigator navigator].window makeKeyAndVisible];
	return YES;
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
