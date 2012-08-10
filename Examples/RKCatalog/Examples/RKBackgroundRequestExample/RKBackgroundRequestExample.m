//
//  RKBackgroundRequestExample.m
//  RKCatalog
//
//  Created by Blake Watters on 4/21/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <RestKit/RestKit.h>
#import "RKBackgroundRequestExample.h"

@implementation RKBackgroundRequestExample

@synthesize sendButton = _sendButton;
@synthesize segmentedControl = _segmentedControl;
@synthesize statusLabel = _statusLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        RKClient *client = [RKClient clientWithBaseURL:gRKCatalogBaseURL];
        [RKClient setSharedClient:client];
    }

    return self;
}

- (void)dealloc
{
    [[RKClient sharedClient].requestQueue cancelRequestsWithDelegate:self];

    [super dealloc];
}

- (IBAction)sendRequest
{
    RKRequest *request = [[RKClient sharedClient] requestWithResourcePath:@"/RKBackgroundRequestExample"];
    request.delegate = self;
    request.backgroundPolicy = _segmentedControl.selectedSegmentIndex;
    [request send];
    _sendButton.enabled = NO;
}

- (void)requestDidStartLoad:(RKRequest *)request
{
    _statusLabel.text = [NSString stringWithFormat:@"Sent request with background policy %d at %@", request.backgroundPolicy, [NSDate date]];
}

- (void)requestDidTimeout:(RKRequest *)request
{
    _statusLabel.text = @"Request timed out during background processing";
    _sendButton.enabled = YES;
}

- (void)requestDidCancelLoad:(RKRequest *)request
{
    _statusLabel.text = @"Request canceled";
    _sendButton.enabled = YES;
}

- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response
{
    _statusLabel.text = [NSString stringWithFormat:@"Request completed with response: '%@'", [response bodyAsString]];
    _sendButton.enabled = YES;
}

- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error
{
    _statusLabel.text = [NSString stringWithFormat:@"Request failed with error: %@", [error localizedDescription]];
    _sendButton.enabled = YES;
}

@end
