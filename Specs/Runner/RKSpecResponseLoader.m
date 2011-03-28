//
//  RKSpecResponseLoader.m
//  RestKit
//
//  Created by Blake Watters on 1/14/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKSpecResponseLoader.h"


@implementation RKSpecResponseLoader

@synthesize response = _response;
@synthesize objects = _objects;
@synthesize failureError = _failureError;
@synthesize errorMessage = _errorMessage;
@synthesize success = _success;
@synthesize timeout = _timeout;

+ (RKSpecResponseLoader*)responseLoader {
    return [[[self alloc] init] autorelease];
}

- (id)init {
    self = [super init];
	if (self) {
		_timeout = 3;
		_awaitingResponse = NO;
	}
	
	return self;
}

- (void)dealloc {
	[_response release];
	[_failureError release];
	[_errorMessage release];
	[super dealloc];
}

- (void)waitForResponse {
	_awaitingResponse = YES;
	NSDate* startDate = [NSDate date];
	
	while (_awaitingResponse) {		
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
		if ([[NSDate date] timeIntervalSinceDate:startDate] > self.timeout) {
			[NSException raise:nil format:@"*** Operation timed out after %f seconds...", self.timeout];
			_awaitingResponse = NO;
		}
	}
}

- (void)loadError:(NSError*)error {
    NSLog(@"Error: %@", error);
    _awaitingResponse = NO;
	_success = NO;
	_failureError = [error retain];
}

- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response {
    NSLog(@"Loaded response: %@", response);
	_response = [response retain];
	_awaitingResponse = NO;
	_success = YES;
}

- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error {
    [self loadError:error];
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray*)objects {
	NSLog(@"Response: %@", [objectLoader.response bodyAsString]);
	NSLog(@"Loaded objects: %@", objects);
	_objects = [objects retain];
	_awaitingResponse = NO;
	_success = YES;
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error; {	
	[self loadError:error];
}

@end
