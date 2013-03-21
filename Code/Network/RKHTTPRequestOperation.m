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

#import <objc/runtime.h>
#import "RKHTTPRequestOperation.h"
#import "RKLog.h"
#import "lcl_RK.h"
#import "RKHTTPUtilities.h"
#import "RKMIMETypes.h"

extern NSString * const RKErrorDomain;

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent RKlcl_cRestKitNetwork

NSString *RKStringFromIndexSet(NSIndexSet *indexSet); // Defined in RKResponseDescriptor.m

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
        maxMessageLength = RKLogIsStringBlank([envVars objectForKey:@"RKLogMaxLength"]) ? NSIntegerMax : [[envVars objectForKey:@"RKLogMaxLength"] integerValue];
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

static void *RKHTTPRequestOperationStartDate = &RKHTTPRequestOperationStartDate;

- (void)HTTPOperationDidStart:(NSNotification *)notification
{
    RKHTTPRequestOperation *operation = [notification object];
    
    if (![operation isKindOfClass:[AFHTTPRequestOperation class]]) {
        return;
    }
    
    objc_setAssociatedObject(operation, RKHTTPRequestOperationStartDate, [NSDate date], OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    if ((_RKlcl_component_level[(__RKlcl_log_symbol(RKlcl_cRestKitNetwork))]) >= (__RKlcl_log_symbol(RKlcl_vTrace))) {
        NSString *body = nil;
        if ([operation.request HTTPBody]) {
            body = RKLogTruncateString([[NSString alloc] initWithData:[operation.request HTTPBody] encoding:NSUTF8StringEncoding]);
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
    
    if (![operation isKindOfClass:[AFHTTPRequestOperation class]]) {
        return;
    }
    
    NSTimeInterval elapsedTime = [[NSDate date] timeIntervalSinceDate:objc_getAssociatedObject(operation, RKHTTPRequestOperationStartDate)];
    
    NSString *statusCodeString = RKStringFromStatusCode([operation.response statusCode]);
    NSString *elapsedTimeString = [NSString stringWithFormat:@"[%.04f s]", elapsedTime];
    NSString *statusCodeAndElapsedTime = statusCodeString ? [NSString stringWithFormat:@"(%ld %@) %@", (long)[operation.response statusCode], statusCodeString, elapsedTimeString] : [NSString stringWithFormat:@"(%ld) %@", (long)[operation.response statusCode], elapsedTimeString];
    if (operation.error) {
        if ((_RKlcl_component_level[(__RKlcl_log_symbol(RKlcl_cRestKitNetwork))]) >= (__RKlcl_log_symbol(RKlcl_vTrace))) {
            RKLogError(@"%@ '%@' %@:\nerror=%@\nresponse.body=%@", [operation.request HTTPMethod], [[operation.request URL] absoluteString], statusCodeAndElapsedTime, operation.error, operation.responseString);
        } else {
            if (operation.error.code == NSURLErrorCancelled) {
                RKLogError(@"%@ '%@' %@: Cancelled", [operation.request HTTPMethod], [[operation.request URL] absoluteString], statusCodeAndElapsedTime);
            } else {
                RKLogError(@"%@ '%@' %@: %@", [operation.request HTTPMethod], [[operation.request URL] absoluteString], statusCodeAndElapsedTime, operation.error);
            }
        }
    } else {
        if ((_RKlcl_component_level[(__RKlcl_log_symbol(RKlcl_cRestKitNetwork))]) >= (__RKlcl_log_symbol(RKlcl_vTrace))) {
            RKLogTrace(@"%@ '%@' %@:\nresponse.headers=%@\nresponse.body=%@", [operation.request HTTPMethod], [[operation.request URL] absoluteString], statusCodeAndElapsedTime, [operation.response allHeaderFields], RKLogTruncateString(operation.responseString));
        } else {
            RKLogInfo(@"%@ '%@' %@", [operation.request HTTPMethod], [[operation.request URL] absoluteString], statusCodeAndElapsedTime);
        }
    }
}

@end

@interface AFURLConnectionOperation () <NSURLConnectionDataDelegate>
@property (readwrite, nonatomic, strong) NSRecursiveLock *lock;
@end

@interface RKHTTPRequestOperation ()
@property (readwrite, nonatomic, strong) NSError *rkHTTPError;
@end

@implementation RKHTTPRequestOperation

+ (BOOL)canProcessRequest:(NSURLRequest *)request
{
    return YES;
}

// Disable class level Content/Status Code inspection in our superclass
+ (NSSet *)acceptableContentTypes
{
    return nil;
}

+ (NSIndexSet *)acceptableStatusCodes
{
    return nil;
}

- (BOOL)hasAcceptableStatusCode
{
    if (! self.response) return NO;
    NSUInteger statusCode = ([self.response isKindOfClass:[NSHTTPURLResponse class]]) ? (NSUInteger)[self.response statusCode] : 200;
    return self.acceptableStatusCodes ? [self.acceptableStatusCodes containsIndex:statusCode] : [super hasAcceptableStatusCode];
}

- (BOOL)hasAcceptableContentType
{
    if (! self.response) return NO;
    NSString *contentType = [self.response MIMEType] ?: @"application/octet-stream";
    return self.acceptableContentTypes ? RKMIMETypeInSet(contentType, self.acceptableContentTypes) : [super hasAcceptableContentType];
}

// NOTE: We reimplement this because the AFNetworking implementation keeps Acceptable Status Code/MIME Type at class level
- (NSError *)error
{
    [self.lock lock];

    if (!self.rkHTTPError && self.response) {
        if (![self hasAcceptableStatusCode] || ![self hasAcceptableContentType]) {
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
            [userInfo setValue:self.responseString forKey:NSLocalizedRecoverySuggestionErrorKey];
            [userInfo setValue:[self.request URL] forKey:NSURLErrorFailingURLErrorKey];
            [userInfo setValue:self.request forKey:AFNetworkingOperationFailingURLRequestErrorKey];
            [userInfo setValue:self.response forKey:AFNetworkingOperationFailingURLResponseErrorKey];
            
            if (![self hasAcceptableStatusCode]) {
                NSUInteger statusCode = ([self.response isKindOfClass:[NSHTTPURLResponse class]]) ? (NSUInteger)[self.response statusCode] : 200;
                [userInfo setValue:[NSString stringWithFormat:NSLocalizedString(@"Expected status code in (%@), got %d", nil), RKStringFromIndexSet(self.acceptableStatusCodes ?: [NSMutableIndexSet indexSet]), statusCode] forKey:NSLocalizedDescriptionKey];
                self.rkHTTPError = [[NSError alloc] initWithDomain:RKErrorDomain code:NSURLErrorBadServerResponse userInfo:userInfo];
            } else if (![self hasAcceptableContentType] && self.response.statusCode != 204) {
                // NOTE: 204 responses come back as text/plain, which we don't want
                [userInfo setValue:[NSString stringWithFormat:NSLocalizedString(@"Expected content type %@, got %@", nil), self.acceptableContentTypes, [self.response MIMEType]] forKey:NSLocalizedDescriptionKey];
                self.rkHTTPError = [[NSError alloc] initWithDomain:RKErrorDomain code:NSURLErrorCannotDecodeContentData userInfo:userInfo];
            }
        }
    }
    
    NSError *error = self.rkHTTPError ?: [super error];
    [self.lock unlock];
    return error;
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
