//
//  RKReachabilityExample.m
//  RKCatalog
//
//  Created by Blake Watters on 4/21/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <RestKit/RestKit.h>
#import "RKReachabilityExample.h"

@implementation RKReachabilityExample

@synthesize statusLabel = _statusLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _observer = [[RKReachabilityObserver alloc] initWithHostname:@"restkit.org"];

        // Register for notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reachabilityChanged:)
                                                     name:RKReachabilityStateChangedNotification
                                                   object:_observer];
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_observer release];    
    [super dealloc];
}

- (void)reachabilityChanged:(NSNotification*)notification {
    RKReachabilityObserver* observer = (RKReachabilityObserver*)[notification object];
    
    if ([observer isNetworkReachable]) {
        if ([observer isConnectionRequired]) {
            _statusLabel.text = @"Connection is available...";
            _statusLabel.textColor = [UIColor yellowColor];
            return;
        }
                
        _statusLabel.textColor = [UIColor greenColor];
        
        if (RKReachabilityReachableViaWiFi == [observer networkStatus]) {
            _statusLabel.text = @"Online via WiFi";
        } else if (RKReachabilityReachableViaWWAN == [observer networkStatus]) {
            _statusLabel.text = @"Online via 3G or Edge";
        }
    } else {
        _statusLabel.text = @"Network unreachable!";
        _statusLabel.textColor = [UIColor redColor];
    }
}

@end
