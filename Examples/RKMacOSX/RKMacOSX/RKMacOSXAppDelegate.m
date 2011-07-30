//
//  RKMacOSXAppDelegate.m
//  RKMacOSX
//
//  Created by Blake Watters on 4/10/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "RKMacOSXAppDelegate.h"

@implementation RKMacOSXAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Initialize RestKit
    RKClient* client = [RKClient clientWithBaseURL:@"http://twitter.com"];
    [client get:@"/status/user_timeline/twotoasters.json" delegate:self];
}

- (void)request:(RKRequest*)request didLoadResponse:(RKResponse *)response {
    NSLog(@"Loaded JSON: %@", [response bodyAsString]);
}

- (void)dealloc {
    [super dealloc];
}

@end
