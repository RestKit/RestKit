//
//  RKClient.m
//  RestKit
//
//  Created by Blake Watters on 7/28/09.
//  Copyright 2009 RestKit
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
#import "NSString+RestKit.h"
#import "RKDirectory.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitNetwork

///////////////////////////////////////////////////////////////////////////////////////////////////
// Global

static RKClient* sharedClient = nil;

///////////////////////////////////////////////////////////////////////////////////////////////////
// URL Conveniences functions

NSURL *RKMakeURL(NSString *resourcePath) {
    return [[RKClient sharedClient] URLForResourcePath:resourcePath];
}

NSString *RKMakeURLPath(NSString *resourcePath) {
    return [[RKClient sharedClient] URLPathForResourcePath:resourcePath];
}

NSString *RKMakePathWithObjectAddingEscapes(NSString* pattern, id object, BOOL addEscapes) {
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
    if ([queryParams count] > 0) {
        return [NSString stringWithFormat:@"%@?%@", resourcePath, [queryParams stringWithURLEncodedEntries]];
    }
    return resourcePath;
}

///////////////////////////////////////////////////////////////////////////////////////////////////

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

+ (RKClient *)sharedClient {
	return sharedClient;
}

+ (void)setSharedClient:(RKClient *)client {
	[sharedClient release];
	sharedClient = [client retain];
}

+ (RKClient *)clientWithBaseURL:(NSString *)baseURL {
	RKClient *client = [[[self alloc] initWithBaseURL:baseURL] autorelease];
	return client;
}

+ (RKClient *)clientWithBaseURL:(NSString *)baseURL username:(NSString *)username password:(NSString *)password {
	RKClient *client = [RKClient clientWithBaseURL:baseURL];
    client.authenticationType = RKRequestAuthenticationTypeHTTPBasic;
	client.username = username;
	client.password = password;
	return client;
}

- (id)init {
    self = [super init];
	if (self) {
		_HTTPHeaders = [[NSMutableDictionary alloc] init];
        _additionalRootCertificates = [[NSMutableSet alloc] init];
		self.serviceUnavailableAlertEnabled = NO;
		self.serviceUnavailableAlertTitle = NSLocalizedString(@"Service Unavailable", nil);
		self.serviceUnavailableAlertMessage = NSLocalizedString(@"The remote resource is unavailable. Please try again later.", nil);
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(serviceDidBecomeUnavailableNotification:) 
                                                     name:RKServiceDidBecomeUnavailableNotification 
                                                   object:nil];
        
        // Configure reachability and queue
        [self addObserver:self forKeyPath:@"reachabilityObserver" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
        self.requestQueue = [RKRequestQueue requestQueue];
        
        [self addObserver:self forKeyPath:@"baseURL" options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self forKeyPath:@"requestQueue" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
	}

	return self;
}

- (id)initWithBaseURL:(NSString *)baseURL {
    self = [self init];
    if (self) {        
        self.cachePolicy = RKRequestCachePolicyDefault;
        self.baseURL = baseURL;
        
        if (sharedClient == nil) {
            [RKClient setSharedClient:self];
            
            // Initialize Logging as soon as a client is created
            RKLogInitialize();
        }
    }
    
    return self;
}

- (void)dealloc {    
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
    [_HTTPHeaders release];
    [_additionalRootCertificates release];

    if (sharedClient == self) sharedClient = nil;
    
    [super dealloc];
}

- (NSString *)cachePath {
    NSString *cacheDirForClient = [NSString stringWithFormat:@"RKClientRequestCache-%@",
                                   [[NSURL URLWithString:self.baseURL] host]];
    NSString *cachePath = [[RKDirectory cachesDirectory]
                           stringByAppendingPathComponent:cacheDirForClient];
    return cachePath;
}

- (BOOL)isNetworkReachable {
	BOOL isNetworkReachable = YES;
	if (self.reachabilityObserver) {
		isNetworkReachable = [self.reachabilityObserver isNetworkReachable];
	}
    
	return isNetworkReachable;
}

- (NSString *)resourcePath:(NSString *)resourcePath withQueryParams:(NSDictionary *)queryParams {
	return RKPathAppendQueryParams(resourcePath, queryParams);
}

- (NSURL *)URLForResourcePath:(NSString *)resourcePath {
	return [RKURL URLWithBaseURLString:self.baseURL resourcePath:resourcePath];
}

- (NSString *)URLPathForResourcePath:(NSString *)resourcePath {
	return [[self URLForResourcePath:resourcePath] absoluteString];
}

- (NSURL *)URLForResourcePath:(NSString *)resourcePath queryParams:(NSDictionary *)queryParams {
	return [RKURL URLWithBaseURLString:self.baseURL resourcePath:resourcePath queryParams:queryParams];
}

- (void)setupRequest:(RKRequest *)request {
	request.additionalHTTPHeaders = _HTTPHeaders;
    request.authenticationType = self.authenticationType;
	request.username = self.username;
	request.password = self.password;
	request.cachePolicy = self.cachePolicy;
    request.cache = self.requestCache;
    request.queue = self.requestQueue;
    request.reachabilityObserver = self.reachabilityObserver;
    
    // OAuth 1 Parameters
    request.OAuth1AccessToken = self.OAuth1AccessToken;
    request.OAuth1AccessTokenSecret = self.OAuth1AccessTokenSecret;
    request.OAuth1ConsumerKey = self.OAuth1ConsumerKey;
    request.OAuth1ConsumerSecret = self.OAuth1ConsumerSecret;

    // OAuth2 Parameters
    request.OAuth2AccessToken = self.OAuth2AccessToken;
    request.OAuth2RefreshToken = self.OAuth2RefreshToken;
}

- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)header {
	[_HTTPHeaders setValue:value forKey:header];
}

- (void)addRootCertificate:(SecCertificateRef)cert {
    [_additionalRootCertificates addObject:(id)cert];
}

- (void)reachabilityObserverDidChange:(NSDictionary *)change {
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

- (void)baseURLDidChange:(NSDictionary *)change {
    NSString *newBaseURLString = [change objectForKey:NSKeyValueChangeNewKey];
    
    // Don't crash if baseURL is nil'd out (i.e. dealloc)
    if (! [newBaseURLString isEqual:[NSNull null]]) {
        // Configure a cache for the new base URL
        [_requestCache release];
        _requestCache = [[RKRequestCache alloc] initWithCachePath:[self cachePath]
                                                    storagePolicy:RKRequestCacheStoragePolicyPermanently];
    
        // Determine reachability strategy (if user has not already done so)
        if (self.reachabilityObserver == nil) {
            NSURL *newBaseURL = [NSURL URLWithString:newBaseURLString];
            NSString *hostName = [newBaseURL host];
            if ([newBaseURLString isEqualToString:@"localhost"] || [hostName isIPAddress]) {
                self.reachabilityObserver = [RKReachabilityObserver reachabilityObserverForHost:hostName];
            } else {
                self.reachabilityObserver = [RKReachabilityObserver reachabilityObserverForInternet];
            }
        }
    }
}

- (void)requestQueueDidChange:(NSDictionary *)change {
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"baseURL"]) {
        [self baseURLDidChange:change];
    } else if ([keyPath isEqualToString:@"requestQueue"]) {
        [self requestQueueDidChange:change];
    } else if ([keyPath isEqualToString:@"reachabilityObserver"]) {
        [self reachabilityObserverDidChange:change];
    }
}

- (RKRequest *)requestWithResourcePath:(NSString *)resourcePath delegate:(NSObject<RKRequestDelegate> *)delegate {
	RKRequest *request = [[RKRequest alloc] initWithURL:[self URLForResourcePath:resourcePath] delegate:delegate];
	[self setupRequest:request];
	[request autorelease];

	return request;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// Asynchronous Requests
///////////////////////////////////////////////////////////////////////////////////////////////////////////

- (RKRequest *)load:(NSString *)resourcePath method:(RKRequestMethod)method params:(NSObject<RKRequestSerializable> *)params delegate:(id)delegate {
	NSURL* resourcePathURL = nil;
	if (method == RKRequestMethodGET) {
		resourcePathURL = [self URLForResourcePath:resourcePath queryParams:(NSDictionary*)params];
	} else {
		resourcePathURL = [self URLForResourcePath:resourcePath];
	}
	RKRequest *request = [[RKRequest alloc] initWithURL:resourcePathURL delegate:delegate];
	[self setupRequest:request];
	[request autorelease];
	request.method = method;
	if (method != RKRequestMethodGET) {
		request.params = params;
	}
    
    [request send];

	return request;
}

- (RKRequest *)get:(NSString *)resourcePath delegate:(id)delegate {
	return [self load:resourcePath method:RKRequestMethodGET params:nil delegate:delegate];
}

- (RKRequest *)get:(NSString *)resourcePath queryParams:(NSDictionary *)queryParams delegate:(id)delegate {
	return [self load:resourcePath method:RKRequestMethodGET params:queryParams delegate:delegate];
}

- (RKRequest *)post:(NSString *)resourcePath params:(NSObject<RKRequestSerializable> *)params delegate:(id)delegate {
	return [self load:resourcePath method:RKRequestMethodPOST params:params delegate:delegate];
}

- (RKRequest *)put:(NSString *)resourcePath params:(NSObject<RKRequestSerializable> *)params delegate:(id)delegate {
	return [self load:resourcePath method:RKRequestMethodPUT params:params delegate:delegate];
}

- (RKRequest *)delete:(NSString *)resourcePath delegate:(id)delegate {
	return [self load:resourcePath method:RKRequestMethodDELETE params:nil delegate:delegate];
}

- (void)serviceDidBecomeUnavailableNotification:(NSNotification *)notification {
    if (self.serviceUnavailableAlertEnabled) {
        RKAlertWithTitle(self.serviceUnavailableAlertMessage, self.serviceUnavailableAlertTitle);
    }
}

- (void)reachabilityWasDetermined:(NSNotification *)notification {
    RKReachabilityObserver *observer = (RKReachabilityObserver *) [notification object];
    NSAssert(observer == self.reachabilityObserver, @"Received unexpected reachability notification from inappropriate reachability observer");
    
    RKLogDebug(@"Reachability to host '%@' determined for client %@, unsuspending queue %@", observer.host, self, self.requestQueue);
    _awaitingReachabilityDetermination = NO;
    self.requestQueue.suspended = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RKReachabilityWasDeterminedNotification object:observer];
}

// deprecated
- (RKRequestCache *)cache {
    return _requestCache;
}

// deprecated
- (void)setCache:(RKRequestCache *)requestCache {
    self.requestCache = requestCache;
}

// deprecated
- (BOOL)isNetworkAvailable {
    return [self isNetworkReachable];
}

@end
