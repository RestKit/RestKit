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
    
    // Initialize RestKit
	RKObjectManager* objectManager = [RKObjectManager objectManagerWithBaseURL:@"http://twitter.com"];
    
    // Uncomment this to use XML, comment it to use JSON
    [objectManager setFormat:RKMappingFormatXML];
    
	RKObjectMapper* mapper = objectManager.mapper;
	
	// Add our element to object mappings
	[mapper registerClass:[RKTUser class] forElementNamed:@"user"];
	[mapper registerClass:[RKTStatus class] forElementNamed:@"status"];
	
	// Update date format so that we can parse twitter dates properly
	// Wed Sep 29 15:31:08 +0000 2010
	NSMutableArray* dateFormats = [[[mapper dateFormats] mutableCopy] autorelease];
	[dateFormats addObject:@"E MMM d HH:mm:ss Z y"];
	[mapper setDateFormats:dateFormats];
	
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
