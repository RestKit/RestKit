//
//  RKRequest.m
//  RestKit
//
//  Created by Jeremy Ellison on 7/27/09.
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

#import "RKRequest.h"
#import "RKResponse.h"
#import "NSDictionary+RKRequestSerialization.h"
#import "RKNotifications.h"
#import "Support.h"
#import "RKURL.h"
#import "NSData+RKAdditions.h"
#import "NSString+RKAdditions.h"
#import "RKLog.h"
#import "RKRequestCache.h"
#import "GCOAuth.h"
#import "NSURL+RKAdditions.h"
#import "RKReachabilityObserver.h"
#import "RKRequestQueue.h"
#import "RKParams.h"
#import "RKParserRegistry.h"
#import "RKRequestSerialization.h"

NSString *RKRequestMethodNameFromType(RKRequestMethod method) {
    switch (method) {
        case RKRequestMethodGET:
            return @"GET";
            break;

        case RKRequestMethodPOST:
            return @"POST";
            break;

        case RKRequestMethodPUT:
            return @"PUT";
            break;

        case RKRequestMethodDELETE:
            return @"DELETE";
            break;

        case RKRequestMethodHEAD:
            return @"HEAD";
            break;

        default:
            break;
    }

    return nil;
}

RKRequestMethod RKRequestMethodTypeFromName(NSString *methodName) {
    if ([methodName isEqualToString:@"GET"]) {
        return RKRequestMethodGET;
    } else if ([methodName isEqualToString:@"POST"]) {
        return RKRequestMethodPOST;
    } else if ([methodName isEqualToString:@"PUT"]) {
        return RKRequestMethodPUT;
    } else if ([methodName isEqualToString:@"DELETE"]) {
        return RKRequestMethodDELETE;
    } else if ([methodName isEqualToString:@"HEAD"]) {
        return RKRequestMethodHEAD;
    }

    return RKRequestMethodInvalid;
}

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitNetwork

@interface RKRequest ()
@property (nonatomic, assign, readwrite, getter = isLoaded) BOOL loaded;
@property (nonatomic, assign, readwrite, getter = isLoading) BOOL loading;
@property (nonatomic, assign, readwrite, getter = isCancelled) BOOL cancelled;
@property (nonatomic, retain, readwrite) RKResponse *response;
@end

@implementation RKRequest
@class GCOAuth;

@synthesize URL = _URL;
@synthesize URLRequest = _URLRequest;
@synthesize delegate = _delegate;
@synthesize additionalHTTPHeaders = _additionalHTTPHeaders;
@synthesize params = _params;
@synthesize userData = _userData;
@synthesize authenticationType = _authenticationType;
@synthesize username = _username;
@synthesize password = _password;
@synthesize method = _method;
@synthesize cachePolicy = _cachePolicy;
@synthesize cache = _cache;
@synthesize cacheTimeoutInterval = _cacheTimeoutInterval;
@synthesize OAuth1ConsumerKey = _OAuth1ConsumerKey;
@synthesize OAuth1ConsumerSecret = _OAuth1ConsumerSecret;
@synthesize OAuth1AccessToken = _OAuth1AccessToken;
@synthesize OAuth1AccessTokenSecret = _OAuth1AccessTokenSecret;
@synthesize OAuth2AccessToken = _OAuth2AccessToken;
@synthesize OAuth2RefreshToken = _OAuth2RefreshToken;
@synthesize queue = _queue;
@synthesize timeoutInterval = _timeoutInterval;
@synthesize reachabilityObserver = _reachabilityObserver;
@synthesize defaultHTTPEncoding = _defaultHTTPEncoding;
@synthesize configurationDelegate = _configurationDelegate;
@synthesize onDidLoadResponse;
@synthesize onDidFailLoadWithError;
@synthesize additionalRootCertificates = _additionalRootCertificates;
@synthesize disableCertificateValidation = _disableCertificateValidation;
@synthesize followRedirect = _followRedirect;
@synthesize runLoopMode = _runLoopMode;
@synthesize loaded = _loaded;
@synthesize loading = _loading;
@synthesize response = _response;
@synthesize cancelled = _cancelled;

#if TARGET_OS_IPHONE
@synthesize backgroundPolicy = _backgroundPolicy;
@synthesize backgroundTaskIdentifier = _backgroundTaskIdentifier;
#endif

+ (RKRequest *)requestWithURL:(NSURL *)URL
{
    return [[[RKRequest alloc] initWithURL:URL] autorelease];
}

- (id)initWithURL:(NSURL *)URL
{
    self = [self init];
    if (self) {
        _URL = [URL retain];
        [self reset];
        _authenticationType = RKRequestAuthenticationTypeNone;
        _cachePolicy = RKRequestCachePolicyDefault;
        _cacheTimeoutInterval = 0;
        _timeoutInterval = 120.0;
        _defaultHTTPEncoding = NSUTF8StringEncoding;
        _followRedirect = YES;
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.runLoopMode = NSRunLoopCommonModes;
#if TARGET_OS_IPHONE
        _backgroundPolicy = RKRequestBackgroundPolicyNone;
        _backgroundTaskIdentifier = 0;
        BOOL backgroundOK = &UIBackgroundTaskInvalid != NULL;
        if (backgroundOK) {
            _backgroundTaskIdentifier = UIBackgroundTaskInvalid;
        }
#endif
    }

    return self;
}

- (void)reset
{
    if (self.isLoading) {
        RKLogWarning(@"Request was reset while loading: %@. Canceling.", self);
        [self cancel];
    }
    [_URLRequest release];
    _URLRequest = [[NSMutableURLRequest alloc] initWithURL:_URL];
    [_URLRequest setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    [_connection release];
    _connection = nil;
    self.loading = NO;
    self.loaded = NO;
    self.cancelled = NO;
}

- (void)cleanupBackgroundTask
{
    #if TARGET_OS_IPHONE
    BOOL backgroundOK = &UIBackgroundTaskInvalid != NULL;
    if (backgroundOK && UIBackgroundTaskInvalid == self.backgroundTaskIdentifier) {
        return;
    }

    UIApplication *app = [UIApplication sharedApplication];
    if ([app respondsToSelector:@selector(beginBackgroundTaskWithExpirationHandler:)]) {
            [app endBackgroundTask:_backgroundTaskIdentifier];
            _backgroundTaskIdentifier = UIBackgroundTaskInvalid;
    }
    #endif
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.delegate = nil;
    if (_onDidLoadResponse) Block_release(_onDidLoadResponse);
    if (_onDidFailLoadWithError) Block_release(_onDidFailLoadWithError);

    _delegate = nil;
    _configurationDelegate = nil;
    [_reachabilityObserver release];
    _reachabilityObserver = nil;
    [_connection cancel];
    [_connection release];
    _connection = nil;
    [_response release];
    _response = nil;
    [_userData release];
    _userData = nil;
    [_URL release];
    _URL = nil;
    [_URLRequest release];
    _URLRequest = nil;
    [_params release];
    _params = nil;
    [_additionalHTTPHeaders release];
    _additionalHTTPHeaders = nil;
    [_username release];
    _username = nil;
    [_password release];
    _password = nil;
    [_cache release];
    _cache = nil;
    [_OAuth1ConsumerKey release];
    _OAuth1ConsumerKey = nil;
    [_OAuth1ConsumerSecret release];
    _OAuth1ConsumerSecret = nil;
    [_OAuth1AccessToken release];
    _OAuth1AccessToken = nil;
    [_OAuth1AccessTokenSecret release];
    _OAuth1AccessTokenSecret = nil;
    [_OAuth2AccessToken release];
    _OAuth2AccessToken = nil;
    [_OAuth2RefreshToken release];
    _OAuth2RefreshToken = nil;
    [onDidFailLoadWithError release];
    onDidFailLoadWithError = nil;
    [onDidLoadResponse release];
    onDidLoadResponse = nil;
    [self invalidateTimeoutTimer];
    [_timeoutTimer release];
    _timeoutTimer = nil;
    [_runLoopMode release];
    _runLoopMode = nil;

    // Cleanup a background task if there is any
    [self cleanupBackgroundTask];

    [super dealloc];
}

- (BOOL)shouldSendParams
{
    return (_params && (_method != RKRequestMethodGET && _method != RKRequestMethodHEAD));
}

- (void)setRequestBody
{
    if ([self shouldSendParams]) {
        // Prefer the use of a stream over a raw body
        if ([_params respondsToSelector:@selector(HTTPBodyStream)]) {
            // NOTE: This causes the stream to be retained. For RKParams, this will
            // cause a leak unless the stream is released. See [RKParams close]
            [_URLRequest setHTTPBodyStream:[_params HTTPBodyStream]];
        } else {
            [_URLRequest setHTTPBody:[_params HTTPBody]];
        }
    }
}

- (NSData *)HTTPBody
{
    return self.URLRequest.HTTPBody;
}

- (void)setHTTPBody:(NSData *)HTTPBody
{
    [self.URLRequest setHTTPBody:HTTPBody];
}

- (NSString *)HTTPBodyString
{
    return [[[NSString alloc] initWithData:self.URLRequest.HTTPBody encoding:NSASCIIStringEncoding] autorelease];
}

- (void)setHTTPBodyString:(NSString *)HTTPBodyString
{
    [self.URLRequest setHTTPBody:[HTTPBodyString dataUsingEncoding:NSASCIIStringEncoding]];
}

- (void)addHeadersToRequest
{
    NSString *header = nil;
    for (header in _additionalHTTPHeaders) {
        [_URLRequest setValue:[_additionalHTTPHeaders valueForKey:header] forHTTPHeaderField:header];
    }

    if ([self shouldSendParams]) {
        // Temporarily support older RKRequestSerializable implementations
        if ([_params respondsToSelector:@selector(HTTPHeaderValueForContentType)]) {
            [_URLRequest setValue:[_params HTTPHeaderValueForContentType] forHTTPHeaderField:@"Content-Type"];
        } else if ([_params respondsToSelector:@selector(ContentTypeHTTPHeader)]) {
            [_URLRequest setValue:[_params performSelector:@selector(ContentTypeHTTPHeader)] forHTTPHeaderField:@"Content-Type"];
        }
        if ([_params respondsToSelector:@selector(HTTPHeaderValueForContentLength)]) {
            [_URLRequest setValue:[NSString stringWithFormat:@"%d", [_params HTTPHeaderValueForContentLength]] forHTTPHeaderField:@"Content-Length"];
        }
    } else {
        [_URLRequest setValue:@"0" forHTTPHeaderField:@"Content-Length"];
    }

    // Add authentication headers so we don't have to deal with an extra cycle for each message requiring basic auth.
    if (self.authenticationType == RKRequestAuthenticationTypeHTTPBasic && _username && _password) {
        CFHTTPMessageRef dummyRequest = CFHTTPMessageCreateRequest(kCFAllocatorDefault, (CFStringRef)[self HTTPMethod], (CFURLRef)[self URL], kCFHTTPVersion1_1);
        if (dummyRequest) {
          CFHTTPMessageAddAuthentication(dummyRequest, nil, (CFStringRef)_username, (CFStringRef)_password, kCFHTTPAuthenticationSchemeBasic, FALSE);
          CFStringRef authorizationString = CFHTTPMessageCopyHeaderFieldValue(dummyRequest, CFSTR("Authorization"));
          if (authorizationString) {
            [_URLRequest setValue:(NSString *)authorizationString forHTTPHeaderField:@"Authorization"];
            CFRelease(authorizationString);
          }
          CFRelease(dummyRequest);
        }
    }

    // Add OAuth headers if necessary
    // OAuth 1
    if (self.authenticationType == RKRequestAuthenticationTypeOAuth1) {
        NSURLRequest *echo = nil;

        // use the suitable parameters dict
        NSDictionary *parameters = nil;
        if ([self.params isKindOfClass:[RKParams class]])
            parameters = [(RKParams *)self.params dictionaryOfPlainTextParams];
        else
            parameters = [_URL queryParameters];
        
        NSString *methodString = RKRequestMethodNameFromType(self.method);        
        echo = [GCOAuth URLRequestForPath:[_URL path] 
                               HTTPMethod:methodString 
                               parameters:(self.method == RKRequestMethodGET) ? [_URL queryParameters] : parameters 
                                   scheme:[_URL scheme] 
                                     host:[_URL host] 
                              consumerKey:self.OAuth1ConsumerKey 
                           consumerSecret:self.OAuth1ConsumerSecret 
                              accessToken:self.OAuth1AccessToken 
                              tokenSecret:self.OAuth1AccessTokenSecret];
        [_URLRequest setValue:[echo valueForHTTPHeaderField:@"Authorization"] forHTTPHeaderField:@"Authorization"];
        [_URLRequest setValue:[echo valueForHTTPHeaderField:@"Accept-Encoding"] forHTTPHeaderField:@"Accept-Encoding"];
        [_URLRequest setValue:[echo valueForHTTPHeaderField:@"User-Agent"] forHTTPHeaderField:@"User-Agent"];
    }

    // OAuth 2 valid request
    if (self.authenticationType == RKRequestAuthenticationTypeOAuth2) {
        NSString *authorizationString = [NSString stringWithFormat:@"OAuth2 %@", self.OAuth2AccessToken];
        [_URLRequest setValue:authorizationString forHTTPHeaderField:@"Authorization"];
    }

    if (self.cachePolicy & RKRequestCachePolicyEtag) {
        NSString *etag = [self.cache etagForRequest:self];
        if (etag) {
            RKLogTrace(@"Setting If-None-Match header to '%@'", etag);
            [_URLRequest setValue:etag forHTTPHeaderField:@"If-None-Match"];
        }
    }
}

// Setup the NSURLRequest. The request must be prepared right before dispatching
- (BOOL)prepareURLRequest
{
    [_URLRequest setHTTPMethod:[self HTTPMethod]];

    if ([self.delegate respondsToSelector:@selector(requestWillPrepareForSend:)]) {
        [self.delegate requestWillPrepareForSend:self];
    }

    [self setRequestBody];
    [self addHeadersToRequest];

    NSString *body = [[NSString alloc] initWithData:[_URLRequest HTTPBody] encoding:NSUTF8StringEncoding];
    RKLogTrace(@"Prepared %@ URLRequest '%@'. HTTP Headers: %@. HTTP Body: %@.", [self HTTPMethod], _URLRequest, [_URLRequest allHTTPHeaderFields], body);
    [body release];

    return YES;
}

- (void)cancelAndInformDelegate:(BOOL)informDelegate
{
    self.cancelled = YES;
    [_connection cancel];
    [_connection release];
    _connection = nil;
    [self invalidateTimeoutTimer];
    self.loading = NO;

    if (informDelegate && [_delegate respondsToSelector:@selector(requestDidCancelLoad:)]) {
        [_delegate requestDidCancelLoad:self];
    }
}

- (NSString *)HTTPMethod
{
    return RKRequestMethodNameFromType(self.method);
}

// NOTE: We could factor the knowledge about the queue out of RKRequest entirely, but it will break behavior.
- (void)send
{
    NSAssert(NO == self.isLoading || NO == self.isLoaded, @"Cannot send a request that is loading or loaded without resetting it first.");
    if (self.queue) {
        [self.queue addRequest:self];
    } else {
        [self sendAsynchronously];
    }
}

- (void)fireAsynchronousRequest
{
    RKLogDebug(@"Sending asynchronous %@ request to URL %@.", [self HTTPMethod], [[self URL] absoluteString]);
    if (![self prepareURLRequest]) {
        RKLogWarning(@"Failed to send request asynchronously: prepareURLRequest returned NO.");
        return;
    }

    self.loading = YES;

    if ([self.delegate respondsToSelector:@selector(requestDidStartLoad:)]) {
        [self.delegate requestDidStartLoad:self];
    }

    RKResponse *response = [[[RKResponse alloc] initWithRequest:self] autorelease];

    _connection = [[[[NSURLConnection alloc] initWithRequest:_URLRequest delegate:response startImmediately:NO] autorelease] retain];
    [_connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:self.runLoopMode];
    [_connection start];

    [[NSNotificationCenter defaultCenter] postNotificationName:RKRequestSentNotification object:self userInfo:nil];
}

- (BOOL)shouldLoadFromCache
{
    // if RKRequestCachePolicyEnabled or if RKRequestCachePolicyTimeout and we are in the timeout
    if ([self.cache hasResponseForRequest:self]) {
        if (self.cachePolicy & RKRequestCachePolicyEnabled) {
            return YES;
        } else if (self.cachePolicy & RKRequestCachePolicyTimeout) {
            NSDate *date = [self.cache cacheDateForRequest:self];
            NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:date];
            return interval <= self.cacheTimeoutInterval;
        }
    }
    return NO;
}

- (RKResponse *)loadResponseFromCache
{
    RKLogDebug(@"Found cached content, loading...");
    return [self.cache responseForRequest:self];
}

- (BOOL)shouldDispatchRequest
{
    if (nil == self.reachabilityObserver || NO == [self.reachabilityObserver isReachabilityDetermined]) {
        return YES;
    }

    return [self.reachabilityObserver isNetworkReachable];
}

- (void)sendAsynchronously
{
    NSAssert(NO == self.loading || NO == self.loaded, @"Cannot send a request that is loading or loaded without resetting it first.");
    _sentSynchronously = NO;
    if ([self shouldLoadFromCache]) {
        RKResponse *response = [self loadResponseFromCache];
        self.loading = YES;
        [self performSelector:@selector(didFinishLoad:) withObject:response afterDelay:0];
    } else if ([self shouldDispatchRequest]) {
        [self createTimeoutTimer];
#if TARGET_OS_IPHONE
        // Background Request Policy support
        UIApplication *app = [UIApplication sharedApplication];
        if (self.backgroundPolicy == RKRequestBackgroundPolicyNone ||
            NO == [app respondsToSelector:@selector(beginBackgroundTaskWithExpirationHandler:)]) {
            // No support for background (iOS 3.x) or the policy is none -- just fire the request
            [self fireAsynchronousRequest];
        } else if (self.backgroundPolicy == RKRequestBackgroundPolicyCancel || self.backgroundPolicy == RKRequestBackgroundPolicyRequeue) {
            // For cancel or requeue behaviors, we watch for background transition notifications
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(appDidEnterBackgroundNotification:)
                                                         name:UIApplicationDidEnterBackgroundNotification
                                                       object:nil];
            [self fireAsynchronousRequest];
        } else if (self.backgroundPolicy == RKRequestBackgroundPolicyContinue) {
            RKLogInfo(@"Beginning background task to perform processing...");

            // Fork a background task for continueing a long-running request
            __block RKRequest *weakSelf = self;
            __block id<RKRequestDelegate> weakDelegate = _delegate;
            _backgroundTaskIdentifier = [app beginBackgroundTaskWithExpirationHandler:^{
                RKLogInfo(@"Background request time expired, canceling request.");

                [weakSelf cancelAndInformDelegate:NO];
                [weakSelf cleanupBackgroundTask];

                if ([weakDelegate respondsToSelector:@selector(requestDidTimeout:)]) {
                    [weakDelegate requestDidTimeout:weakSelf];
                }
            }];

            // Start the potentially long-running request
            [self fireAsynchronousRequest];
        }
#else
        [self fireAsynchronousRequest];
#endif
    } else {
        RKLogTrace(@"Declined to dispatch request %@: reachability observer reported the network is not available.", self);

        if (_cachePolicy & RKRequestCachePolicyLoadIfOffline &&
            [self.cache hasResponseForRequest:self]) {
            self.loading = YES;
            [self didFinishLoad:[self loadResponseFromCache]];
        } else {
            self.loading = YES;

            RKLogError(@"Failed to send request to %@ due to unreachable network. Reachability observer = %@", [[self URL] absoluteString], self.reachabilityObserver);
            NSString *errorMessage = [NSString stringWithFormat:@"The client is unable to contact the resource at %@", [[self URL] absoluteString]];
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                      errorMessage, NSLocalizedDescriptionKey,
                                      nil];
            NSError *error = [NSError errorWithDomain:RKErrorDomain code:RKRequestBaseURLOfflineError userInfo:userInfo];
            [self performSelector:@selector(didFailLoadWithError:) withObject:error afterDelay:0];
        }
    }
}

- (RKResponse *)sendSynchronously
{
    NSAssert(NO == self.loading || NO == self.loaded, @"Cannot send a request that is loading or loaded without resetting it first.");
    NSHTTPURLResponse *URLResponse = nil;
    NSError *error;
    NSData *payload = nil;
    RKResponse *response = nil;
    _sentSynchronously = YES;

    if ([self shouldLoadFromCache]) {
        response = [self loadResponseFromCache];
        self.loading = YES;
        [self didFinishLoad:response];
    } else if ([self shouldDispatchRequest]) {
        RKLogDebug(@"Sending synchronous %@ request to URL %@.", [self HTTPMethod], [[self URL] absoluteString]);

        if (![self prepareURLRequest]) {
            RKLogWarning(@"Failed to send request synchronously: prepareURLRequest returned NO.");
            return nil;
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:RKRequestSentNotification object:self userInfo:nil];

        self.loading = YES;
        if ([self.delegate respondsToSelector:@selector(requestDidStartLoad:)]) {
            [self.delegate requestDidStartLoad:self];
        }

        _URLRequest.timeoutInterval = _timeoutInterval;
        payload = [NSURLConnection sendSynchronousRequest:_URLRequest returningResponse:&URLResponse error:&error];

        if (payload != nil) error = nil;

        response = [[[RKResponse alloc] initWithSynchronousRequest:self URLResponse:URLResponse body:payload error:error] autorelease];

        if (error.code == NSURLErrorTimedOut) {
            [self timeout];
        } else if (payload == nil) {
            [self didFailLoadWithError:error];
        } else {
            [self didFinishLoad:response];
        }

    } else {
        if (_cachePolicy & RKRequestCachePolicyLoadIfOffline &&
            [self.cache hasResponseForRequest:self]) {

            response = [self loadResponseFromCache];

        } else {
            NSString *errorMessage = [NSString stringWithFormat:@"The client is unable to contact the resource at %@", [[self URL] absoluteString]];
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                      errorMessage, NSLocalizedDescriptionKey,
                                      nil];
            error = [NSError errorWithDomain:RKErrorDomain code:RKRequestBaseURLOfflineError userInfo:userInfo];
            [self didFailLoadWithError:error];
            response = [[[RKResponse alloc] initWithSynchronousRequest:self URLResponse:URLResponse body:payload error:error] autorelease];
        }
    }

    return response;
}

- (void)cancel
{
    [self cancelAndInformDelegate:YES];
}

- (void)createTimeoutTimer
{
    _timeoutTimer = [NSTimer scheduledTimerWithTimeInterval:self.timeoutInterval target:self selector:@selector(timeout) userInfo:nil repeats:NO];
}

- (void)timeout
{
    [self cancelAndInformDelegate:NO];
    RKLogError(@"Failed to send request to %@ due to connection timeout. Timeout interval = %f", [[self URL] absoluteString], self.timeoutInterval);
    NSString *errorMessage = [NSString stringWithFormat:@"The client timed out connecting to the resource at %@", [[self URL] absoluteString]];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              errorMessage, NSLocalizedDescriptionKey,
                              nil];
    NSError *error = [NSError errorWithDomain:RKErrorDomain code:RKRequestConnectionTimeoutError userInfo:userInfo];
    [self didFailLoadWithError:error];
}

- (void)invalidateTimeoutTimer
{
    [_timeoutTimer invalidate];
    _timeoutTimer = nil;
}

- (void)didFailLoadWithError:(NSError *)error
{
    if (_cachePolicy & RKRequestCachePolicyLoadOnError &&
        [self.cache hasResponseForRequest:self]) {

        [self didFinishLoad:[self loadResponseFromCache]];
    } else {
        self.loaded = YES;
        self.loading = NO;

        if ([_delegate respondsToSelector:@selector(request:didFailLoadWithError:)]) {
            [_delegate request:self didFailLoadWithError:error];
        }

        if (self.onDidFailLoadWithError) {
            self.onDidFailLoadWithError(error);
        }


        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:error forKey:RKRequestDidFailWithErrorNotificationUserInfoErrorKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:RKRequestDidFailWithErrorNotification
                                                            object:self
                                                          userInfo:userInfo];
    }

    // NOTE: This notification must be posted last as the request queue releases the request when it
    // receives the notification
    [[NSNotificationCenter defaultCenter] postNotificationName:RKRequestDidFinishLoadingNotification object:self];
}

- (void)updateInternalCacheDate
{
    NSDate *date = [NSDate date];
    RKLogInfo(@"Updating cache date for request %@ to %@", self, date);
    [self.cache setCacheDate:date forRequest:self];
}

- (void)didFinishLoad:(RKResponse *)response
{
    self.loading = NO;
    self.loaded = YES;

    RKLogInfo(@"Status Code: %ld", (long)[response statusCode]);
    RKLogDebug(@"Body: %@", [response bodyAsString]);

    self.response = response;

    if ((_cachePolicy & RKRequestCachePolicyEtag) && [response isNotModified]) {
        self.response = [self loadResponseFromCache];
        [self updateInternalCacheDate];
    }

    if (![response wasLoadedFromCache] && [response isSuccessful] && (_cachePolicy != RKRequestCachePolicyNone)) {
        [self.cache storeResponse:response forRequest:self];
    }

    if ([_delegate respondsToSelector:@selector(request:didLoadResponse:)]) {
        [_delegate request:self didLoadResponse:self.response];
    }

    if (self.onDidLoadResponse) {
        self.onDidLoadResponse(self.response);
    }

    if ([response isServiceUnavailable]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:RKServiceDidBecomeUnavailableNotification object:self];
    }

    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:self.response
                                                         forKey:RKRequestDidLoadResponseNotificationUserInfoResponseKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:RKRequestDidLoadResponseNotification
                                                        object:self
                                                      userInfo:userInfo];

    // NOTE: This notification must be posted last as the request queue releases the request when it
    // receives the notification
    [[NSNotificationCenter defaultCenter] postNotificationName:RKRequestDidFinishLoadingNotification object:self];
}

- (BOOL)isGET
{
    return _method == RKRequestMethodGET;
}

- (BOOL)isPOST
{
    return _method == RKRequestMethodPOST;
}

- (BOOL)isPUT
{
    return _method == RKRequestMethodPUT;
}

- (BOOL)isDELETE
{
    return _method == RKRequestMethodDELETE;
}

- (BOOL)isHEAD
{
    return _method == RKRequestMethodHEAD;
}

- (BOOL)isUnsent
{
    return self.loading == NO && self.loaded == NO;
}

- (NSString *)resourcePath
{
    NSString *resourcePath = nil;
    if ([self.URL isKindOfClass:[RKURL class]]) {
        RKURL *url = (RKURL *)self.URL;
        resourcePath = url.resourcePath;
    }
    return resourcePath;
}

- (void)setURL:(NSURL *)URL
{
    [URL retain];
    [_URL release];
    _URL = URL;
    _URLRequest.URL = URL;
}

- (void)setResourcePath:(NSString *)resourcePath
{
    if ([self.URL isKindOfClass:[RKURL class]]) {
        self.URL = [(RKURL *)self.URL URLByReplacingResourcePath:resourcePath];
    } else {
        self.URL = [RKURL URLWithBaseURL:self.URL resourcePath:resourcePath];
    }
}

- (BOOL)wasSentToResourcePath:(NSString *)resourcePath
{
    return [[self resourcePath] isEqualToString:resourcePath];
}

- (BOOL)wasSentToResourcePath:(NSString *)resourcePath method:(RKRequestMethod)method
{
    return (self.method == method && [self wasSentToResourcePath:resourcePath]);
}

- (void)appDidEnterBackgroundNotification:(NSNotification *)notification
{
#if TARGET_OS_IPHONE
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    if (self.backgroundPolicy == RKRequestBackgroundPolicyCancel) {
        [self cancel];
    } else if (self.backgroundPolicy == RKRequestBackgroundPolicyRequeue) {
        // Cancel the existing request
        [self cancelAndInformDelegate:NO];
        [self send];
    }
#endif
}

- (BOOL)isCacheable
{
    return _method == RKRequestMethodGET;
}

- (NSString *)cacheKey
{
    if (! [self isCacheable]) {
        return nil;
    }

    // Use [_params HTTPBody] because the URLRequest body may not have been set up yet.
    NSString *compositeCacheKey = nil;
    if (_params) {
        if ([_params respondsToSelector:@selector(HTTPBody)]) {
            compositeCacheKey = [NSString stringWithFormat:@"%@-%d-%@", self.URL, _method, [_params HTTPBody]];
        } else if ([_params isKindOfClass:[RKParams class]]) {
            compositeCacheKey = [NSString stringWithFormat:@"%@-%d-%@", self.URL, _method, [(RKParams *)_params MD5]];
        }
    } else {
        compositeCacheKey = [NSString stringWithFormat:@"%@-%d", self.URL, _method];
    }
    NSAssert(compositeCacheKey, @"Expected a cacheKey to be generated for request %@, but got nil", compositeCacheKey);
    return [compositeCacheKey MD5];
}

- (void)setBody:(NSDictionary *)body forMIMEType:(NSString *)MIMEType
{
    id<RKParser> parser = [[RKParserRegistry sharedRegistry] parserForMIMEType:MIMEType];

    NSError *error = nil;
    NSString *parsedValue = [parser stringFromObject:body error:&error];

    RKLogTrace(@"parser=%@, error=%@, parsedValue=%@", parser, error, parsedValue);

    if (error == nil && parsedValue) {
        self.params = [RKRequestSerialization serializationWithData:[parsedValue dataUsingEncoding:NSUTF8StringEncoding]
                                                           MIMEType:MIMEType];
    }
}

// Deprecations
+ (RKRequest *)requestWithURL:(NSURL *)URL delegate:(id)delegate
{
    return [[[RKRequest alloc] initWithURL:URL delegate:delegate] autorelease];
}

- (id)initWithURL:(NSURL *)URL delegate:(id)delegate
{
    self = [self initWithURL:URL];
    if (self) {
        _delegate = delegate;
    }
    return self;
}

@end
