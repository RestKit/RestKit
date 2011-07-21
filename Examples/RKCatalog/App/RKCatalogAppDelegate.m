//
//  RKCatalogAppDelegate.m
//  RKCatalog
//
//  Created by Blake Watters on 4/21/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKCatalogAppDelegate.h"
#import "RootViewController.h"

NSString* gRKCatalogBaseURL = nil;

@implementation RKCatalogAppDelegate

@synthesize window=_window;
@synthesize navigationController=_navigationController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    // Add the navigation controller's view to the window and display.
    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];
    
    
    // gRKCatalogBaseURL = [@"http://localhost:4567" retain];
    gRKCatalogBaseURL = [@"http://rkcatalog.heroku.com" retain];
    
    return YES;
}

- (void)dealloc {
    [_window release];
    [_navigationController release];
    [super dealloc];
}

@end
