//
//  RKCatalogAppDelegate.m
//  RKCatalog
//
//  Created by Blake Watters on 4/21/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKCatalogAppDelegate.h"
#import "RootViewController.h"

NSURL *gRKCatalogBaseURL = nil;

@implementation RKCatalogAppDelegate

@synthesize window;
@synthesize navigationController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    // Add the navigation controller's view to the window and display.
    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];


    gRKCatalogBaseURL = [[NSURL alloc] initWithString:@"http://rkcatalog.heroku.com"];

    return YES;
}

- (void)dealloc
{
    [window release];
    [navigationController release];
    [super dealloc];
}

@end
