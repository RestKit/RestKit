//
//  RKMacOSXAppDelegate.m
//  RKMacOSX
//
//  Created by Blake Watters on 4/10/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKMacOSXAppDelegate.h"

@implementation RKMacOSXAppDelegate

@synthesize client = _client;
@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Initialize RestKit
    self.client = [RKClient clientWithBaseURL:[RKURL URLWithBaseURLString:@"http://twitter.com"]];
    [self.client get:@"/status/user_timeline/RestKit.json" delegate:self];
}

- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response
{
    NSLog(@"Loaded JSON: %@", [response bodyAsString]);
}

- (void)dealloc
{
    [super dealloc];
}

@end
