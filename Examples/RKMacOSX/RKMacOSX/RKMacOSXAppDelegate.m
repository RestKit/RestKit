//
//  RKMacOSXAppDelegate.m
//  RKMacOSX
//
//  Created by Blake Watters on 4/10/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKMacOSXAppDelegate.h"

@implementation RKMacOSXAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Initialize RestKit
    self.objectManager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:@"http://twitter.com"]];
}


@end
