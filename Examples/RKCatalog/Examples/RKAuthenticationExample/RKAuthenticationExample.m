//
//  RKAuthenticationExample.m
//  RKCatalog
//
//  Created by Blake Watters on 9/27/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKAuthenticationExample.h"

@implementation RKAuthenticationExample

@synthesize authenticatedRequest;
@synthesize URLTextField;
@synthesize usernameTextField;
@synthesize passwordTextField;
@synthesize authenticationTypePickerView;

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
    [authenticatedRequest cancel];
    [authenticatedRequest release];
    authenticatedRequest = nil;

    [super dealloc];
}

/**
 We are constructing our own RKRequest here rather than working with the client.
 It is important to remember that RKClient is really just a factory object for instances
 of RKRequest. At any time you can directly configure an RKRequest instead.
 */
- (void)sendRequest
{
    NSURL *URL = [NSURL URLWithString:[URLTextField text]];
    RKRequest *newRequest = [RKRequest requestWithURL:URL];
    newRequest.delegate = self;
    newRequest.authenticationType = RKRequestAuthenticationTypeHTTP;
    newRequest.username = [usernameTextField text];
    newRequest.password = [passwordTextField text];

    self.authenticatedRequest = newRequest;
}

- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error
{
    RKLogError(@"Load of RKRequest %@ failed with error: %@", request, error);
    [request release];
}

- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response
{
    RKLogCritical(@"Loading of RKRequest %@ completed with status code %d. Response body: %@", request, response.statusCode, [response bodyAsString]);
    [request release];
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return 0;
}

@end
