//
//  RKHTTPRequestOperation.m
//  RestKit
//
//  Created by Blake Watters on 8/7/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
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

#import "RKHTTPRequestOperation.h"
#import "RKLog.h"
#import "lcl_RK.h"
#import "RKHTTPUtilities.h"
#import "RKMIMETypes.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent RKlcl_cRestKitNetwork

@interface RKHTTPRequestOperationLogger : NSObject

+ (id)sharedLogger;

@end

@implementation RKHTTPRequestOperationLogger

+ (id)sharedLogger
{
    static RKHTTPRequestOperationLogger *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[RKHTTPRequestOperationLogger alloc] init];
    });
    return sharedInstance;
}

+ (void)load
{
    [self sharedLogger];
}

- (id)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(HTTPOperationDidStart:)
                                                     name:AFNetworkingOperationDidStartNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(HTTPOperationDidFinish:)
                                                     name:AFNetworkingOperationDidFinishNotification
                                                   object:nil];
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)HTTPOperationDidStart:(NSNotification *)notification
{
    RKHTTPRequestOperation *operation = [notification object];
    NSString *body = nil;
    if ([operation.request HTTPBody]) {
        body = [NSString stringWithUTF8String:[[operation.request HTTPBody] bytes]];
    }

    if ((_RKlcl_component_level[(__RKlcl_log_symbol(RKlcl_cRestKitNetwork))]) >= (__RKlcl_log_symbol(RKlcl_vTrace))) {
        RKLogTrace(@"%@ '%@':\nrequest.headers=%@\nrequest.body=%@", [operation.request HTTPMethod], [[operation.request URL] absoluteString], [operation.request allHTTPHeaderFields], body);
    } else {
        RKLogInfo(@"%@ '%@'", [operation.request HTTPMethod], [[operation.request URL] absoluteString]);
    }
}

- (void)HTTPOperationDidFinish:(NSNotification *)notification
{
    RKHTTPRequestOperation *operation = [notification object];
    if (operation.error) {
        if ((_RKlcl_component_level[(__RKlcl_log_symbol(RKlcl_cRestKitNetwork))]) >= (__RKlcl_log_symbol(RKlcl_vTrace))) {
            RKLogError(@"%@ '%@' (%ld):\nerror=%@\nresponse.body=%@", [operation.request HTTPMethod], [[operation.request URL] absoluteString], (long)[operation.response statusCode], operation.error, operation.responseString);
        } else {
          RKLogError(@"%@ '%@' (%ld): %@", [operation.request HTTPMethod], [[operation.request URL] absoluteString], (long)[operation.response statusCode], operation.error);
        }
    } else {
        if ((_RKlcl_component_level[(__RKlcl_log_symbol(RKlcl_cRestKitNetwork))]) >= (__RKlcl_log_symbol(RKlcl_vTrace))) {
            RKLogTrace(@"%@ '%@' (%ld):\nresponse.headers=%@\nresponse.body=%@", [operation.request HTTPMethod], [[operation.request URL] absoluteString], (long)[operation.response statusCode], [operation.response allHeaderFields], operation.responseString);
        } else {
            RKLogInfo(@"%@ '%@' (%ld)", [operation.request HTTPMethod], [[operation.request URL] absoluteString], (long)[operation.response statusCode]);
        }
    }
}

@end

@interface AFURLConnectionOperation () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
@end

@implementation RKHTTPRequestOperation

- (BOOL)hasAcceptableStatusCode
{
    return self.acceptableStatusCodes ? [self.acceptableStatusCodes containsIndex:[self.response statusCode]] : [super hasAcceptableStatusCode];
}

- (BOOL)hasAcceptableContentType
{
    return self.acceptableContentTypes ? RKMIMETypeInSet([self.response MIMEType], self.acceptableContentTypes) : [super hasAcceptableContentType];
}

#pragma mark - NSURLConnectionDelegate methods

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    [super connection:connection didReceiveAuthenticationChallenge:challenge];

    RKLogDebug(@"Received authentication challenge");
}

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
{
    if ([AFHTTPRequestOperation instancesRespondToSelector:@selector(connection:willSendRequest:redirectResponse:)]) {
        NSURLRequest *returnValue = [super connection:connection willSendRequest:request redirectResponse:redirectResponse];
        if (returnValue) {
            RKLogDebug(@"Following redirect request: %@", returnValue);
            return returnValue;
        } else {
            RKLogDebug(@"Not following redirect to %@", request);
            return nil;
        }
    } else {
        if (redirectResponse) RKLogDebug(@"Following redirect request: %@", request);
        return request;
    }
}

@end
