//
//  RKReachabilityExample.m
//  RKCatalog
//
//  Created by Blake Watters on 4/21/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <RestKit/RestKit.h>
#import "RKReachabilityExample.h"

@implementation RKReachabilityExample

@synthesize observer = _observer;
@synthesize statusLabel = _statusLabel;
@synthesize flagsLabel = _flagsLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
       self.observer = [[RKReachabilityObserver alloc] initWithHost:@"restkit.org"];
//        self.observer = [RKReachabilityObserver reachabilityObserverForLocalWifi];
//        self.observer = [RKReachabilityObserver reachabilityObserverForInternet];

        // Register for notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reachabilityChanged:)
                                                     name:RKReachabilityDidChangeNotification
                                                   object:_observer];
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_observer release];
    [super dealloc];
}

- (void)viewDidLoad
{
    if (! [_observer isReachabilityDetermined]) {
        _statusLabel.text = @"Reachability is indeterminate...";
        _statusLabel.textColor = [UIColor blueColor];
    }
}

- (void)reachabilityChanged:(NSNotification *)notification
{
    RKReachabilityObserver *observer = (RKReachabilityObserver *)[notification object];

    RKLogCritical(@"Received reachability update: %@", observer);
    _flagsLabel.text = [NSString stringWithFormat:@"Host: %@ -> %@", observer.host, [observer reachabilityFlagsDescription]];

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
