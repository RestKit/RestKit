//
//  RKClient.m
//  RestKit
//
//  Created by Blake Watters on 7/28/09.
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

#import "RKClient.h"
#import "RKURL.h"
#import "RKNotifications.h"
#import "RKAlert.h"
#import "RKLog.h"
#import "RKPathMatcher.h"
#import "NSString+RKAdditions.h"
#import "RKDirectory.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitNetwork

///////////////////////////////////////////////////////////////////////////////////////////////////
// Global

static RKClient *sharedClient = nil;

///////////////////////////////////////////////////////////////////////////////////////////////////
// URL Conveniences functions

NSURL *RKMakeURL(NSString *resourcePath) {
    return [[RKClient sharedClient].baseURL URLByAppendingResourcePath:resourcePath];
}

NSString *RKMakeURLPath(NSString *resourcePath) {
    return [[[RKClient sharedClient].baseURL URLByAppendingResourcePath:resourcePath] absoluteString];
}

NSString *RKMakePathWithObjectAddingEscapes(NSString *pattern, id object, BOOL addEscapes) {
    NSCAssert(pattern != NULL, @"Pattern string must not be empty in order to create a path from an interpolated object.");
    NSCAssert(object != NULL, @"Object provided is invalid; cannot create a path from a NULL object");
    RKPathMatcher *matcher = [RKPathMatcher matcherWithPattern:pattern];
    NSString *interpolatedPath = [matcher pathFromObject:object addingEscapes:addEscapes];
    return interpolatedPath;
}

NSString *RKMakePathWithObject(NSString *pattern, id object) {
    return RKMakePathWithObjectAddingEscapes(pattern, object, YES);
}

NSString *RKPathAppendQueryParams(NSString *resourcePath, NSDictionary *queryParams) {
    return [resourcePath stringByAppendingQueryParameters:queryParams];
}

///////////////////////////////////////////////////////////////////////////////////////////////////

@interface RKClient ()
@property (nonatomic, retain, readwrite) NSMutableDictionary *HTTPHeaders;
@property (nonatomic, retain, readwrite) NSSet *additionalRootCertificates;
@end

@implementation RKClient

@synthesize baseURL = _baseURL;
@synthesize authenticationType = _authenticationType;
@synthesize username = _username;
@synthesize password = _password;
@synthesize OAuth1ConsumerKey = _OAuth1ConsumerKey;
@synthesize OAuth1ConsumerSecret = _OAuth1ConsumerSecret;
@synthesize OAuth1AccessToken = _OAuth1AccessToken;
@synthesize OAuth1AccessTokenSecret = _OAuth1AccessTokenSecret;
@synthesize OAuth2AccessToken = _OAuth2AccessToken;
@synthesize OAuth2RefreshToken = _OAuth2RefreshToken;
@synthesize HTTPHeaders = _HTTPHeaders;
@synthesize additionalRootCertificates = _additionalRootCertificates;
@synthesize disableCertificateValidation = _disableCertificateValidation;
@synthesize reachabilityObserver = _reachabilityObserver;
@synthesize serviceUnavailableAlertTitle = _serviceUnavailableAlertTitle;
@synthesize serviceUnavailableAlertMessage = _serviceUnavailableAlertMessage;
@synthesize serviceUnavailableAlertEnabled = _serviceUnavailableAlertEnabled;
@synthesize requestCache = _requestCache;
@synthesize cachePolicy = _cachePolicy;
@synthesize requestQueue = _requestQueue;
@synthesize timeoutInterval = _timeoutInterval;
@synthesize defaultHTTPEncoding = _defaultHTTPEncoding;
@synthesize cacheTimeoutInterval = _cacheTimeoutInterval;
@synthesize runLoopMode = _runLoopMode;

+ (RKClient *)sharedClient
{
    return sharedClient;
}

+ (void)setSharedClient:(RKClient *)client
{
    [sharedClient release];
    sharedClient = [client retain];
}

+ (RKClient *)clientWithBaseURLString:(NSString *)baseURLString
{
    return [self clientWithBaseURL:[RKURL URLWithString:baseURLString]];
}

+ (RKClient *)clientWithBaseURL:(NSURL *)baseURL
{
    RKClient *client = [[[self alloc] initWithBaseURL:baseURL] autorelease];
    return client;
}

+ (RKClient *)clientWithBaseURL:(NSString *)baseURL username:(NSString *)username password:(NSString *)password
{
    RKClient *client = [RKClient clientWithBaseURLString:baseURL];
    client.authenticationType = RKRequestAuthenticationTypeHTTPBasic;
    client.username = username;
    client.password = password;
    return client;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.HTTPHeaders = [NSMutableDictionary dictionary];
        self.additionalRootCertificates = [NSMutableSet set];
        self.defaultHTTPEncoding = NSUTF8StringEncoding;
        self.cacheTimeoutInterval = 0;
        self.runLoopMode = NSRunLoopCommonModes;
        self.requestQueue = [RKRequestQueue requestQueue];
        self.serviceUnavailableAlertEnabled = NO;
        self.serviceUnavailableAlertTitle = NSLocalizedString(@"Service Unavailable", nil);
        self.serviceUnavailableAlertMessage = NSLocalizedString(@"The remote resource is unavailable. Please try again later.", nil);
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(serviceDidBecomeUnavailableNotification:)
                                                     name:RKServiceDidBecomeUnavailableNotification
                                                   object:nil];

        // Configure observers
        [self addObserver:self forKeyPath:@"reachabilityObserver" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
        [self addObserver:self forKeyPath:@"baseURL" options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self forKeyPath:@"requestQueue" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionInitial context:nil];
    }

    return self;
}

- (id)initWithBaseURL:(NSURL *)baseURL
{
    self = [self init];
    if (self) {
        self.cachePolicy = RKRequestCachePolicyDefault;
        self.baseURL = [RKURL URLWithBaseURL:baseURL];

        if (sharedClient == nil) {
            [RKClient setSharedClient:self];

            // Initialize Logging as soon as a client is created
            RKLogInitialize();
        }
    }

    return self;
}

- (id)initWithBaseURLString:(NSString *)baseURLString
{
    return [self initWithBaseURL:[RKURL URLWithString:baseURLString]];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    // Allow KVO to fire
    self.reachabilityObserver = nil;
    self.baseURL = nil;
    self.requestQueue = nil;

    [self removeObserver:self forKeyPath:@"reachabilityObserver"];
    [self removeObserver:self forKeyPath:@"baseURL"];
    [self removeObserver:self forKeyPath:@"requestQueue"];

    self.username = nil;
    self.password = nil;
    self.serviceUnavailableAlertTitle = nil;
    self.serviceUnavailableAlertMessage = nil;
    self.requestCache = nil;
    self.runLoopMode = nil;
    [_HTTPHeaders release];
    [_additionalRootCertificates release];

    if (sharedClient == self) sharedClient = nil;

    [super dealloc];
}

- (NSString *)cachePath
{
    NSString *cacheDirForClient = [NSString stringWithFormat:@"RKClientRequestCache-%@", [self.baseURL host]];
    NSString *cachePath = [[RKDirectory cachesDirectory]
                           stringByAppendingPathComponent:cacheDirForClient];
    return cachePath;
}

- (BOOL)isNetworkReachable
{
    BOOL isNetworkReachable = YES;
    if (self.reachabilityObserver) {
        isNetworkReachable = [self.reachabilityObserver isNetworkReachable];
    }

    return isNetworkReachable;
}

- (void)configureRequest:(RKRequest *)request
{
    request.additionalHTTPHeaders = _HTTPHeaders;
    request.authenticationType = self.authenticationType;
    request.username = self.username;
    request.password = self.password;
    request.cachePolicy = self.cachePolicy;
    request.cache = self.requestCache;
    request.queue = self.requestQueue;
    request.reachabilityObserver = self.reachabilityObserver;
    request.defaultHTTPEncoding = self.defaultHTTPEncoding;

    request.additionalRootCertificates = self.additionalRootCertificates;
    request.disableCertificateValidation = self.disableCertificateValidation;
    request.runLoopMode = self.runLoopMode;

    // If a timeoutInterval was set on the client, we'll pass it on to the request.
    // Otherwise, we'll let the request default to its own timeout interval.
    if (self.timeoutInterval) {
        request.timeoutInterval = self.timeoutInterval;
    }

    if (self.cacheTimeoutInterval) {
        request.cacheTimeoutInterval = self.cacheTimeoutInterval;
    }

    // OAuth 1 Parameters
    request.OAuth1AccessToken = self.OAuth1AccessToken;
    request.OAuth1AccessTokenSecret = self.OAuth1AccessTokenSecret;
    request.OAuth1ConsumerKey = self.OAuth1ConsumerKey;
    request.OAuth1ConsumerSecret = self.OAuth1ConsumerSecret;

    // OAuth2 Parameters
    request.OAuth2AccessToken = self.OAuth2AccessToken;
    request.OAuth2RefreshToken = self.OAuth2RefreshToken;
}

- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)header
{
    [_HTTPHeaders setValue:value forKey:header];
}

- (void)addRootCertificate:(SecCertificateRef)cert
{
    [_additionalRootCertificates addObject:(id)cert];
}

- (void)reachabilityObserverDidChange:(NSDictionary *)change
{
    RKReachabilityObserver *oldReachabilityObserver = [change objectForKey:NSKeyValueChangeOldKey];
    RKReachabilityObserver *newReachabilityObserver = [change objectForKey:NSKeyValueChangeNewKey];

    if (! [oldReachabilityObserver isEqual:[NSNull null]]) {
        RKLogDebug(@"Reachability observer changed for RKClient %@, disposing of previous instance: %@", self, oldReachabilityObserver);
        // Cleanup if changed immediately after client init
        [[NSNotificationCenter defaultCenter] removeObserver:self name:RKReachabilityWasDeterminedNotification object:oldReachabilityObserver];
    }

    if (! [newReachabilityObserver isEqual:[NSNull null]]) {
        // Suspend the queue until reachability to our new hostname is established
        if (! [newReachabilityObserver isReachabilityDetermined]) {
            self.requestQueue.suspended = YES;
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(reachabilityWasDetermined:)
                                                         name:RKReachabilityWasDeterminedNotification
                                                       object:newReachabilityObserver];

            RKLogDebug(@"Reachability observer changed for client %@, suspending queue %@ until reachability to host '%@' can be determined",
                       self, self.requestQueue, newReachabilityObserver.host);

            // Maintain a flag for Reachability determination status. This ensures that we can do the right thing in the
            // event that the requestQueue is changed while we are in an inderminate suspension state
            _awaitingReachabilityDetermination = YES;
        } else {
            self.requestQueue.suspended = NO;
            RKLogDebug(@"Reachability observer changed for client %@, unsuspending queue %@ as new observer already has determined reachability to %@",
                       self, self.requestQueue, newReachabilityObserver.host);
            _awaitingReachabilityDetermination = NO;
        }
    }
}

- (void)baseURLDidChange:(NSDictionary *)change
{
    RKURL *newBaseURL = [change objectForKey:NSKeyValueChangeNewKey];

    // Don't crash if baseURL is nil'd out (i.e. dealloc)
    if (! [newBaseURL isEqual:[NSNull null]]) {
        // Configure a cache for the new base URL
        [_requestCache release];
        _requestCache = [[RKRequestCache alloc] initWithPath:[self cachePath]
                                                    storagePolicy:RKRequestCacheStoragePolicyPermanently];

        // Determine reachability strategy (if user has not already done so)
        if (self.reachabilityObserver == nil) {
            NSString *hostName = [newBaseURL host];
            if ([hostName isEqualToString:@"localhost"] || [hostName isIPAddress]) {
                self.reachabilityObserver = [RKReachabilityObserver reachabilityObserverForHost:hostName];
            } else {
                self.reachabilityObserver = [RKReachabilityObserver reachabilityObserverForInternet];
            }
        }
    }
}

- (void)requestQueueDidChange:(NSDictionary *)change
{
    if (! _awaitingReachabilityDetermination) {
        return;
    }

    // If we are awaiting reachability determination, suspend the new queue
    RKRequestQueue *newQueue = [change objectForKey:NSKeyValueChangeNewKey];

    if (! [newQueue isEqual:[NSNull null]]) {
        // The request queue has changed while we were awaiting reachability.
        // Suspend the queue until reachability is determined
        newQueue.suspended = !self.reachabilityObserver.reachabilityDetermined;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"baseURL"]) {
        [self baseURLDidChange:change];
    } else if ([keyPath isEqualToString:@"requestQueue"]) {
        [self requestQueueDidChange:change];
    } else if ([keyPath isEqualToString:@"reachabilityObserver"]) {
        [self reachabilityObserverDidChange:change];
    }
}

- (RKRequest *)requestWithResourcePath:(NSString *)resourcePath
{
    RKRequest *request = [[RKRequest alloc] initWithURL:[self.baseURL URLByAppendingResourcePath:resourcePath]];
    [self configureRequest:request];
    [request autorelease];

    return request;
}

- (RKRequest *)requestWithResourcePath:(NSString *)resourcePath delegate:(NSObject<RKRequestDelegate> *)delegate
{
    RKRequest *request = [self requestWithResourcePath:resourcePath];
    request.delegate = delegate;

    return request;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// Asynchronous Requests
///////////////////////////////////////////////////////////////////////////////////////////////////////////

- (RKRequest *)load:(NSString *)resourcePath method:(RKRequestMethod)method params:(NSObject<RKRequestSerializable> *)params delegate:(id)delegate
{
    RKURL *resourcePathURL = nil;
    if (method == RKRequestMethodGET) {
        resourcePathURL = [self.baseURL URLByAppendingResourcePath:resourcePath queryParameters:(NSDictionary *)params];
    } else {
        resourcePathURL = [self.baseURL URLByAppendingResourcePath:resourcePath];
    }
    RKRequest *request = [RKRequest requestWithURL:resourcePathURL];
    request.delegate = delegate;
    [self configureRequest:request];
    request.method = method;
    if (method != RKRequestMethodGET) {
        request.params = params;
    }

    [request send];

    return request;
}

- (RKRequest *)get:(NSString *)resourcePath delegate:(id)delegate
{
    return [self load:resourcePath method:RKRequestMethodGET params:nil delegate:delegate];
}

- (RKRequest *)get:(NSString *)resourcePath queryParameters:(NSDictionary *)queryParameters delegate:(id)delegate
{
    return [self load:resourcePath method:RKRequestMethodGET params:queryParameters delegate:delegate];
}

- (RKRequest *)post:(NSString *)resourcePath params:(NSObject<RKRequestSerializable> *)params delegate:(id)delegate
{
    return [self load:resourcePath method:RKRequestMethodPOST params:params delegate:delegate];
}

- (RKRequest *)put:(NSString *)resourcePath params:(NSObject<RKRequestSerializable> *)params delegate:(id)delegate
{
    return [self load:resourcePath method:RKRequestMethodPUT params:params delegate:delegate];
}

- (RKRequest *)delete:(NSString *)resourcePath delegate:(id)delegate
{
    return [self load:resourcePath method:RKRequestMethodDELETE params:nil delegate:delegate];
}

- (void)serviceDidBecomeUnavailableNotification:(NSNotification *)notification
{
    if (self.serviceUnavailableAlertEnabled) {
        RKAlertWithTitle(self.serviceUnavailableAlertMessage, self.serviceUnavailableAlertTitle);
    }
}

- (void)reachabilityWasDetermined:(NSNotification *)notification
{
    RKReachabilityObserver *observer = (RKReachabilityObserver *)[notification object];
    NSAssert(observer == self.reachabilityObserver, @"Received unexpected reachability notification from inappropriate reachability observer");

    RKLogDebug(@"Reachability to host '%@' determined for client %@, unsuspending queue %@", observer.host, self, self.requestQueue);
    _awaitingReachabilityDetermination = NO;
    self.requestQueue.suspended = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RKReachabilityWasDeterminedNotification object:observer];
}

#pragma mark - Deprecations

// deprecated
- (RKRequestCache *)cache
{
    return _requestCache;
}

// deprecated
- (void)setCache:(RKRequestCache *)requestCache
{
    self.requestCache = requestCache;
}

#pragma mark - Block Request Dispatching

- (RKRequest *)sendRequestToResourcePath:(NSString *)resourcePath usingBlock:(void (^)(RKRequest *request))block
{
    RKRequest *request = [self requestWithResourcePath:resourcePath];
    if (block) block(request);
    [request send];
    return request;
}

- (void)get:(NSString *)resourcePath usingBlock:(void (^)(RKRequest *request))block
{
    [self sendRequestToResourcePath:resourcePath usingBlock:^(RKRequest *request) {
        request.method = RKRequestMethodGET;
        block(request);
    }];
}

- (void)post:(NSString *)resourcePath usingBlock:(void (^)(RKRequest *request))block
{
    [self sendRequestToResourcePath:resourcePath usingBlock:^(RKRequest *request) {
        request.method = RKRequestMethodPOST;
        block(request);
    }];
}

- (void)put:(NSString *)resourcePath usingBlock:(void (^)(RKRequest *request))block
{
    [self sendRequestToResourcePath:resourcePath usingBlock:^(RKRequest *request) {
        request.method = RKRequestMethodPUT;
        block(request);
    }];
}

- (void)delete:(NSString *)resourcePath usingBlock:(void (^)(RKRequest *request))block
{
    [self sendRequestToResourcePath:resourcePath usingBlock:^(RKRequest *request) {
        request.method = RKRequestMethodDELETE;
        block(request);
    }];
}

// deprecated
- (BOOL)isNetworkAvailable
{
    return [self isNetworkReachable];
}

- (NSString *)resourcePath:(NSString *)resourcePath withQueryParams:(NSDictionary *)queryParams
{
    return RKPathAppendQueryParams(resourcePath, queryParams);
}

- (NSURL *)URLForResourcePath:(NSString *)resourcePath
{
    return [self.baseURL URLByAppendingResourcePath:resourcePath];
}

- (NSString *)URLPathForResourcePath:(NSString *)resourcePath
{
    return [[self URLForResourcePath:resourcePath] absoluteString];
}

- (NSURL *)URLForResourcePath:(NSString *)resourcePath queryParams:(NSDictionary *)queryParams
{
    return [self.baseURL URLByAppendingResourcePath:resourcePath queryParameters:queryParams];
}

@end
