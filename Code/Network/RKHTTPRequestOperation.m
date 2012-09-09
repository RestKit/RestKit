//
//  RKHTTPRequestOperation.m
//  GateGuru
//
//  Created by Blake Watters on 8/7/12.
//  Copyright (c) 2012 GateGuru, Inc. All rights reserved.
//

#import "RKHTTPRequestOperation.h"
#import "RKLog.h"
#import "lcl.h"
#import "RKHTTPUtilities.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitNetwork

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

    if ((_lcl_component_level[(__lcl_log_symbol(lcl_cRestKitNetwork))]) >= (__lcl_log_symbol(lcl_vTrace))) {
        RKLogTrace(@"%@ '%@': %@ %@", [operation.request HTTPMethod], [[operation.request URL] absoluteString], [operation.request allHTTPHeaderFields], body);
    } else {
        RKLogInfo(@"%@ '%@'", [operation.request HTTPMethod], [[operation.request URL] absoluteString]);
    }
}

- (void)HTTPOperationDidFinish:(NSNotification *)notification
{
    RKHTTPRequestOperation *operation = [notification object];
    if (operation.error) {
        if ((_lcl_component_level[(__lcl_log_symbol(lcl_cRestKitNetwork))]) >= (__lcl_log_symbol(lcl_vTrace))) {
            RKLogError(@"%@ '%@' (%ld): %@ %@", [operation.request HTTPMethod], [[operation.request URL] absoluteString], (long)[operation.response statusCode], operation.error, operation.responseString);
        } else {
          RKLogError(@"%@ '%@' (%ld): %@", [operation.request HTTPMethod], [[operation.request URL] absoluteString], (long)[operation.response statusCode], operation.error);
        }
    } else {
        if ((_lcl_component_level[(__lcl_log_symbol(lcl_cRestKitNetwork))]) >= (__lcl_log_symbol(lcl_vTrace))) {
            RKLogTrace(@"%@ '%@' (%ld): %@ %@", [operation.request HTTPMethod], [[operation.request URL] absoluteString], (long)[operation.response statusCode], [operation.response allHeaderFields], operation.responseString);
        } else {
            RKLogInfo(@"%@ '%@' (%ld)", [operation.request HTTPMethod], [[operation.request URL] absoluteString], (long)[operation.response statusCode]);
        }
    }
}

@end

@interface AFURLConnectionOperation () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
@end

@implementation RKHTTPRequestOperation

// RestKit will attempt to parse information about failed client errors from the payload
+ (NSIndexSet *)acceptableStatusCodes
{
    NSMutableIndexSet *statusCodes = [NSMutableIndexSet new];
    [statusCodes addIndexesInRange:RKStatusCodeRangeForClass(RKStatusCodeClassSuccessful)];
    [statusCodes addIndexesInRange:RKStatusCodeRangeForClass(RKStatusCodeClassClientError)];
    return statusCodes;
}

+ (NSSet *)acceptableContentTypes
{
    return [NSSet setWithObject:@"application/json"];
}

- (BOOL)hasAcceptableStatusCode {
    return self.acceptableStatusCodes ? [self.acceptableStatusCodes containsIndex:[self.response statusCode]] : [super hasAcceptableStatusCode];
}

- (BOOL)hasAcceptableContentType {
    return self.acceptableContentTypes ? [self.acceptableContentTypes containsObject:[self.response MIMEType]] : [super hasAcceptableContentType];
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
