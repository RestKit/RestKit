//
//  RKTwitterAppDelegate.m
//  RKTwitter
//
//  Created by Blake Watters on 9/5/10.
//  Copyright Two Toasters 2010. All rights reserved.
//

#import <RestKit/RestKit.h>
#import "RKTwitterAppDelegate.h"
#import "RKTwitterViewController.h"
#import "RKTStatus.h"
#import "RKTUser.h"

@implementation RKTwitterAppDelegate

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    RKLogConfigureByName("RestKit/Network*", RKLogLevelTrace);
    // Initialize RestKit
	RKObjectManager* objectManager = [RKObjectManager objectManagerWithBaseURL:@"http://twitter.com"];
    
    // Enable automatic network activity indicator management
    objectManager.client.requestQueue.showsNetworkActivityIndicatorWhenBusy = YES;
    
    // Setup our object mappings
    RKObjectMapping* userMapping = [RKObjectMapping mappingForClass:[RKTUser class]];
    [userMapping mapKeyPath:@"id" toAttribute:@"userID"];
    [userMapping mapKeyPath:@"screen_name" toAttribute:@"screenName"];
    [userMapping mapAttributes:@"name", nil];
    
    RKObjectMapping* statusMapping = [RKObjectMapping mappingForClass:[RKTStatus class]];
    [statusMapping mapKeyPathsToAttributes:@"id", @"statusID",
         @"created_at", @"createdAt",
         @"text", @"text",
         @"url", @"urlString",
         @"in_reply_to_screen_name", @"inReplyToScreenName",
         @"favorited", @"isFavorited",
         nil];
    [statusMapping mapRelationship:@"user" withMapping:userMapping];
    
    // Update date format so that we can parse Twitter dates properly
	// Wed Sep 29 15:31:08 +0000 2010
    [RKObjectMapping addDefaultDateFormatterForString:@"E MMM d HH:mm:ss Z y" inTimeZone:nil];
    
    // Register our mappings with the provider
    [objectManager.mappingProvider setMapping:userMapping forKeyPath:@"user"];
    [objectManager.mappingProvider setMapping:statusMapping forKeyPath:@"status"];
    
    // Uncomment this to use XML, comment it to use JSON
//  objectManager.acceptMIMEType = RKMIMETypeXML;
//  [objectManager.mappingProvider setMapping:statusMapping forKeyPath:@"statuses.status"];
	
    // Create Window and View Controllers
	RKTwitterViewController* viewController = [[[RKTwitterViewController alloc] initWithNibName:nil bundle:nil] autorelease];
	UINavigationController* controller = [[UINavigationController alloc] initWithRootViewController:viewController];
	UIWindow* window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
    [window addSubview:controller.view];
    [window makeKeyAndVisible];
	
    return YES;
}

- (void)dealloc {
    [super dealloc];
}


@end
