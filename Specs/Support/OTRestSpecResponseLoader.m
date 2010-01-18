//
//  OTRestSpecResponseLoader.m
//  OTRestFramework
//
//  Created by Blake Watters on 1/14/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "OTRestSpecResponseLoader.h"


@implementation OTRestSpecResponseLoader

@synthesize response = _response;
@synthesize failureError = _failureError;
@synthesize errorMessage = _errorMessage;
@synthesize success = _success;

- (void)dealloc {
	[_response release];
	[_failureError release];
	[_errorMessage release];
	[super dealloc];
}

- (void)waitForResponse {
	_awaitingResponse = YES;
	while (_awaitingResponse == YES) {
		[[NSRunLoop currentRunLoop] runUntilDate:
		 [NSDate dateWithTimeIntervalSinceNow:1.0]];
	}
}

- (void)loadResponse:(id)response {
	NSLog(@"The response: %@", response);
	_response = [response retain];
	_awaitingResponse = NO;
	_success = YES;
}

- (void)modelLoaderRequest:(OTRestRequest*)request didFailWithError:(NSError*)error response:(OTRestResponse*)response model:(id<OTRestModelMappable>)model {
	_awaitingResponse = NO;
	_success = NO;
	_failureError = [error retain];
}

- (void)modelLoaderRequest:(OTRestRequest*)request didReturnErrorMessage:(NSString*)errorMessage response:(OTRestResponse*)response model:(id<OTRestModelMappable>)model {
	_awaitingResponse = NO;
	_success = NO;
	_errorMessage = [errorMessage retain];
}

@end
