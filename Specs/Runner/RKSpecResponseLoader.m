//
//  RKSpecResponseLoader.m
//  RestKit
//
//  Created by Blake Watters on 1/14/10.
//  Copyright 2010 Two Toasters
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//  http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "RKSpecResponseLoader.h"

NSString * const RKSpecResponseLoaderTimeoutException = @"RKSpecResponseLoaderTimeoutException";

@implementation RKSpecResponseLoader

@synthesize response = _response;
@synthesize objects = _objects;
@synthesize failureError = _failureError;
@synthesize errorMessage = _errorMessage;
@synthesize success = _success;
@synthesize timeout = _timeout;
@synthesize wasCancelled = _wasCancelled;
@synthesize unknownResponse = _unknownResponse;

+ (RKSpecResponseLoader*)responseLoader {
    return [[[self alloc] init] autorelease];
}

- (id)init {
    self = [super init];
	if (self) {
		_timeout = 4;
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
			[NSException raise:RKSpecResponseLoaderTimeoutException format:@"*** Operation timed out after %f seconds...", self.timeout];
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
    
    // If request is an Object Loader, then objectLoader:didLoadObjects:
    // will be sent after didLoadResponse:
    if (NO == [request isKindOfClass:[RKObjectLoader class]]) {
        _awaitingResponse = NO;
        _success = YES;
    }
}

- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error {
    // If request is an Object Loader, then objectLoader:didFailWithError:
    // will be sent after didFailLoadWithError:
    if (NO == [request isKindOfClass:[RKObjectLoader class]]) {
        [self loadError:error];
    }
}

- (void)requestDidCancelLoad:(RKRequest *)request {
    _awaitingResponse = NO;
    _success = NO;
    _wasCancelled = YES;
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

- (void)objectLoaderDidLoadUnexpectedResponse:(RKObjectLoader*)objectLoader {
    NSLog(@"*** Loaded unexpected response in spec response loader");
    _success = NO;
    _awaitingResponse = NO;
    _unknownResponse = YES;
}

#pragma mark - OAuth delegates

- (void)OAuthClient:(RKOAuthClient *)client didAcquireAccessToken:(NSString *)token {
    _awaitingResponse = NO;
    _success = YES;
}


- (void)OAuthClient:(RKOAuthClient *)client didFailWithInvalidGrantError:(NSError *)error {
    _awaitingResponse = NO;
    _success = NO;
}

@end
