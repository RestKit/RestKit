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

static BOOL RKLogIsStringBlank(NSString *string)
{
    return ([[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0);
}

static NSString *RKLogTruncateString(NSString *string)
{
    static NSInteger maxMessageLength;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary *envVars = [[NSProcessInfo processInfo] environment];
        maxMessageLength = RKLogIsStringBlank(envVars[@"RKLogMaxLength"]) ? NSIntegerMax : [envVars[@"RKLogMaxLength"] integerValue];
    });
    
    return ([string length] <= maxMessageLength)
        ? string
        : [NSString stringWithFormat:@"%@... (truncated at %ld characters)",
           [string substringToIndex:maxMessageLength],
           (long) maxMessageLength];
}

static NSString *RKStringFromStreamStatus(NSStreamStatus streamStatus)
{
    switch (streamStatus) {
        case NSStreamStatusNotOpen:     return @"Not Open";
        case NSStreamStatusOpening:     return @"Opening";
        case NSStreamStatusOpen:        return @"Open";
        case NSStreamStatusReading:     return @"Reading";
        case NSStreamStatusWriting:     return @"Writing";
        case NSStreamStatusAtEnd:       return @"At End";
        case NSStreamStatusClosed:      return @"Closed";
        case NSStreamStatusError:       return @"Error";
        default:                        break;
    }
    return nil;
}

static NSString *RKStringDescribingStream(NSStream *stream)
{
    NSString *errorDescription = ([stream streamStatus] == NSStreamStatusError) ? [NSString stringWithFormat:@", error=%@", [stream streamError]] : @"";
    if ([stream isKindOfClass:[NSInputStream class]]) {
        return [NSString stringWithFormat:@"<%@: %p hasBytesAvailable=%@, status='%@'%@>", [stream class], stream, [(NSInputStream *)stream hasBytesAvailable] ? @"YES" : @"NO", RKStringFromStreamStatus([stream streamStatus]), errorDescription];
    } else if ([stream isKindOfClass:[NSOutputStream class]]) {
        return [NSString stringWithFormat:@"<%@: %p hasSpaceAvailable=%@, status='%@'%@>", [stream class], stream, [(NSOutputStream *)stream hasSpaceAvailable] ? @"YES" : @"NO", RKStringFromStreamStatus([stream streamStatus]), errorDescription];
    } else {
        return [stream description];
    }
}

@interface RKHTTPRequestOperationLogger : NSObject

+ (id)sharedLogger;

@end

@implementation RKHTTPRequestOperationLogger

+ (id)sharedLogger
{
    static RKHTTPRequestOperationLogger *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

+ (void)load
{
    @autoreleasepool {
        [self sharedLogger];
    };
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

    if ((_RKlcl_component_level[(__RKlcl_log_symbol(RKlcl_cRestKitNetwork))]) >= (__RKlcl_log_symbol(RKlcl_vTrace))) {
        NSString *body = nil;
        if ([operation.request HTTPBody]) {
            body = RKLogTruncateString([NSString stringWithUTF8String:[[operation.request HTTPBody] bytes]]);
        } else if ([operation.request HTTPBodyStream]) {
            body = RKStringDescribingStream([operation.request HTTPBodyStream]);
        }
        
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
            RKLogTrace(@"%@ '%@' (%ld):\nresponse.headers=%@\nresponse.body=%@", [operation.request HTTPMethod], [[operation.request URL] absoluteString], (long)[operation.response statusCode], [operation.response allHeaderFields], RKLogTruncateString(operation.responseString));
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

- (BOOL)wasNotModified
{
    return [(NSString *)[[self.response allHeaderFields] objectForKey:@"Status"] isEqualToString:@"304 Not Modified"];
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
            if (redirectResponse) RKLogDebug(@"Following redirect request: %@", returnValue);
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
