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

@synthesize window;
@synthesize viewController;


#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    // Initialize RestKit
	RKObjectManager* objectManager = [RKObjectManager objectManagerWithBaseURL:@"http://twitter.com"];
	RKObjectMapper* mapper = objectManager.mapper;
	
	// Add our element to object mappings
	[mapper registerClass:[RKTUser class] forElementNamed:@"user"];
	[mapper registerClass:[RKTStatus class] forElementNamed:@"status"];

    // Add the view controller's view to the window and display.
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];

    return YES;
}

- (void)dealloc {
    [viewController release];
    [window release];
    [super dealloc];
}


@end
