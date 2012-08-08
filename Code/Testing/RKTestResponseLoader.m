//
//  RKTestResponseLoader.m
//  RestKit
//
//  Created by Blake Watters on 1/14/10.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
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

#import "RKTestResponseLoader.h"
#import "RKLog.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitTesting

NSString * const RKTestResponseLoaderTimeoutException = @"RKTestResponseLoaderTimeoutException";

@interface RKTestResponseLoader ()

@property (nonatomic, assign, getter = isAwaitingResponse) BOOL awaitingResponse;
@property (nonatomic, retain, readwrite) RKResponse *response;
@property (nonatomic, copy, readwrite) NSError *error;
@property (nonatomic, retain, readwrite) NSArray *objects;

@end

@implementation RKTestResponseLoader

@synthesize response;
@synthesize objects;
@synthesize error;
@synthesize successful;
@synthesize timeout;
@synthesize cancelled;
@synthesize unexpectedResponse;
@synthesize awaitingResponse;

+ (RKTestResponseLoader *)responseLoader
{
    return [[[self alloc] init] autorelease];
}

- (id)init
{
    self = [super init];
    if (self) {
        timeout = 4;
        awaitingResponse = NO;
    }

    return self;
}

- (void)dealloc
{
    [response release];
    response = nil;
    [error release];
    error = nil;
    [objects release];
    objects = nil;

    [super dealloc];
}

- (void)waitForResponse
{
    awaitingResponse = YES;
    NSDate *startDate = [NSDate date];

    RKLogTrace(@"%@ Awaiting response loaded from for %f seconds...", self, self.timeout);
    while (awaitingResponse) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        if ([[NSDate date] timeIntervalSinceDate:startDate] > self.timeout) {
            [NSException raise:RKTestResponseLoaderTimeoutException format:@"*** Operation timed out after %f seconds...", self.timeout];
            awaitingResponse = NO;
        }
    }
}

- (void)loadError:(NSError *)theError
{
    awaitingResponse = NO;
    successful = NO;
    self.error = theError;
}

- (NSString *)errorMessage
{
    if (self.error) {
        return [[self.error userInfo] valueForKey:NSLocalizedDescriptionKey];
    }

    return nil;
}

- (void)request:(RKRequest *)request didReceiveResponse:(RKResponse *)response
{
    // Implemented for expectations
}

- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)aResponse
{
    self.response = aResponse;

    // If request is an Object Loader, then objectLoader:didLoadObjects:
    // will be sent after didLoadResponse:
    if (NO == [request isKindOfClass:[RKObjectLoader class]]) {
        awaitingResponse = NO;
        successful = YES;
    }
}

- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)anError
{
    // If request is an Object Loader, then objectLoader:didFailWithError:
    // will be sent after didFailLoadWithError:
    if (NO == [request isKindOfClass:[RKObjectLoader class]]) {
        [self loadError:anError];
    }

    // Ensure we get no further delegate messages
    [request cancel];
}

- (void)requestDidCancelLoad:(RKRequest *)request
{
    awaitingResponse = NO;
    successful = NO;
    cancelled = YES;
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)theObjects
{
    RKLogTrace(@"%@ Loaded response for %@ with body: %@", self, objectLoader, [objectLoader.response bodyAsString]);
    RKLogDebug(@"%@ Loaded objects for %@: %@", self, objectLoader, objects);
    self.objects = theObjects;
    awaitingResponse = NO;
    successful = YES;
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)theError
{
    [self loadError:theError];
}

- (void)objectLoaderDidLoadUnexpectedResponse:(RKObjectLoader *)objectLoader
{
    RKLogDebug(@"%@ Loaded unexpected response for: %@", self, objectLoader);
    successful = NO;
    awaitingResponse = NO;
    unexpectedResponse = YES;
}

- (void)objectLoaderDidFinishLoading:(RKObjectLoader *)objectLoader
{
    // Implemented for expectations
}

#pragma mark - OAuth delegates

- (void)OAuthClient:(RKOAuthClient *)client didAcquireAccessToken:(NSString *)token
{
    awaitingResponse = NO;
    successful = YES;
}


- (void)OAuthClient:(RKOAuthClient *)client didFailWithInvalidGrantError:(NSError *)error
{
    awaitingResponse = NO;
    successful = NO;
}

@end
