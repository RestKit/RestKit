//
//  RKClient.m
//  RestKit
//
//  Created by Blake Watters on 7/28/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import <SystemConfiguration/SCNetworkReachability.h>
#import "RKClient.h"
#import "RKObjectLoader.h"
#import "RKURL.h"
#import "RKNotifications.h"
#import "RKAlert.h"
#import "RKLog.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitNetwork

///////////////////////////////////////////////////////////////////////////////////////////////////
// Global

static RKClient* sharedClient = nil;

///////////////////////////////////////////////////////////////////////////////////////////////////
// URL Conveniences functions

NSURL* RKMakeURL(NSString* resourcePath) {
	return [[RKClient sharedClient] URLForResourcePath:resourcePath];
}

NSString* RKMakeURLPath(NSString* resourcePath) {
	return [[RKClient sharedClient] URLPathForResourcePath:resourcePath];
}

NSString* RKMakePathWithObject(NSString* path, id object) {
	NSMutableDictionary* substitutions = [NSMutableDictionary dictionary];
	NSScanner* scanner = [NSScanner scannerWithString:path];

	BOOL startsWithParentheses = [[path substringToIndex:1] isEqualToString:@"("];
	while ([scanner isAtEnd] == NO) {
		NSString* keyPath = nil;
		if (startsWithParentheses || [scanner scanUpToString:@"(" intoString:nil]) {
			// Advance beyond the opening parentheses
			if (NO == [scanner isAtEnd]) {
				[scanner setScanLocation:[scanner scanLocation] + 1];
			}
			if ([scanner scanUpToString:@")" intoString:&keyPath]) {
				NSString* searchString = [NSString stringWithFormat:@"(%@)", keyPath];
                // TODO: Add warning when the value generated a nil? Only for paths values (i.e. contaning '.')?
				NSString* propertyStringValue = [NSString stringWithFormat:@"%@", [object valueForKeyPath:keyPath]];
				[substitutions setObject:propertyStringValue forKey:searchString];
			}
		}
	}

	if (0 == [substitutions count]) {
		return path;
	}

	NSMutableString* interpolatedPath = [[path mutableCopy] autorelease];
	for (NSString* find in substitutions) {
		NSString* replace = [substitutions valueForKey:find];
		[interpolatedPath replaceOccurrencesOfString:find
										  withString:replace
											 options:NSLiteralSearch
											   range:NSMakeRange(0, [interpolatedPath length])];
	}

	return [NSString stringWithString:interpolatedPath];
}

NSString* RKPathAppendQueryParams(NSString* resourcePath, NSDictionary* queryParams) {
	if ([queryParams count] > 0) {
		return [NSString stringWithFormat:@"%@?%@", resourcePath, [queryParams URLEncodedString]];
	} else {
		return resourcePath;
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation RKClient

@synthesize baseURL = _baseURL;
@synthesize username = _username;
@synthesize password = _password;
@synthesize forceBasicAuthentication = _forceBasicAuthentication;
@synthesize HTTPHeaders = _HTTPHeaders;
#ifdef RESTKIT_SSL_VALIDATION
@synthesize additionalRootCertificates = _additionalRootCertificates;
#endif
@synthesize disableCertificateValidation = _disableCertificateValidation;
@synthesize baseURLReachabilityObserver = _baseURLReachabilityObserver;
@synthesize serviceUnavailableAlertTitle = _serviceUnavailableAlertTitle;
@synthesize serviceUnavailableAlertMessage = _serviceUnavailableAlertMessage;
@synthesize serviceUnavailableAlertEnabled = _serviceUnavailableAlertEnabled;
@synthesize cache = _cache;
@synthesize cachePolicy = _cachePolicy;

+ (RKClient*)sharedClient {
	return sharedClient;
}

+ (void)setSharedClient:(RKClient*)client {
	[sharedClient release];
	sharedClient = [client retain];
}

+ (RKClient*)clientWithBaseURL:(NSString*)baseURL {
	RKClient* client = [[[self alloc] initWithBaseURL:baseURL] autorelease];
	return client;
}

+ (RKClient*)clientWithBaseURL:(NSString*)baseURL username:(NSString*)username password:(NSString*)password {
	RKClient* client = [RKClient clientWithBaseURL:baseURL];
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
	}

	return self;
}

- (id)initWithBaseURL:(NSString*)baseURL {
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
    self.baseURL = nil;
    self.username = nil;
    self.password = nil;
    self.serviceUnavailableAlertTitle = nil;
    self.serviceUnavailableAlertMessage = nil;
    self.cache = nil;
    [_HTTPHeaders release];
    [_additionalRootCertificates release];
    [_baseURLReachabilityObserver release];

    [super dealloc];
}

- (NSString*)cachePath {
    NSString* cacheDirForClient = [NSString stringWithFormat:@"RKClientRequestCache-%@",
                                   [[NSURL URLWithString:self.baseURL] host]];
    NSString* cachePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0]
                           stringByAppendingPathComponent:cacheDirForClient];
    return cachePath;
}

- (BOOL)isNetworkAvailable {
	BOOL isNetworkAvailable = NO;
	if (self.baseURLReachabilityObserver) {
		isNetworkAvailable = [self.baseURLReachabilityObserver isNetworkReachable];
	}
    
	return isNetworkAvailable;
}

- (NSString*)resourcePath:(NSString*)resourcePath withQueryParams:(NSDictionary*)queryParams {
	return RKPathAppendQueryParams(resourcePath, queryParams);
}

- (NSURL*)URLForResourcePath:(NSString*)resourcePath {
	return [RKURL URLWithBaseURLString:self.baseURL resourcePath:resourcePath];
}

- (NSString*)URLPathForResourcePath:(NSString*)resourcePath {
	return [[self URLForResourcePath:resourcePath] absoluteString];
}

- (NSURL*)URLForResourcePath:(NSString *)resourcePath queryParams:(NSDictionary*)queryParams {
	return [RKURL URLWithBaseURLString:self.baseURL resourcePath:resourcePath queryParams:queryParams];
}

- (void)setupRequest:(RKRequest*)request {
	request.additionalHTTPHeaders = _HTTPHeaders;
	request.username = self.username;
	request.password = self.password;
    request.forceBasicAuthentication = self.forceBasicAuthentication;
	request.cachePolicy = self.cachePolicy;
    request.cache = self.cache;
}

- (void)setValue:(NSString*)value forHTTPHeaderField:(NSString*)header {
	[_HTTPHeaders setValue:value forKey:header];
}

#ifdef RESTKIT_SSL_VALIDATION
- (void)addRootCertificate:(SecCertificateRef)cert {
    [_additionalRootCertificates addObject:(id)cert];
}
#endif

- (void)setBaseURL:(NSString*)baseURL {
	[_baseURL release];
	_baseURL = nil;
	_baseURL = [baseURL retain];
    
	[_baseURLReachabilityObserver release];
	_baseURLReachabilityObserver = nil;

    // Don't crash if baseURL is nil'd out (i.e. dealloc)
    if (baseURL) {
        // Configure a cache for the new base URL
        [_cache release];
        _cache = [[RKRequestCache alloc] initWithCachePath:[self cachePath]
                                             storagePolicy:RKRequestCacheStoragePolicyPermanently];
        
        // Configure a new reachability observer
        NSURL* URL = [NSURL URLWithString:baseURL];
        _baseURLReachabilityObserver = [[RKReachabilityObserver alloc] initWithHostname:[URL host]];
        
        // Suspend the queue until reachability to our new hostname is established
        [RKRequestQueue sharedQueue].suspended = !_baseURLReachabilityObserver.reachabilityEstablished;
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(reachabilityWasDetermined:) 
                                                     name:RKReachabilityStateWasDeterminedNotification 
                                                   object:_baseURLReachabilityObserver];
        RKLogDebug(@"Base URL changed for client %@, suspending main queue until reachability to host '%@' can be determined", 
                   self, [URL host]);
    }
}

- (RKRequest*)requestWithResourcePath:(NSString*)resourcePath delegate:(NSObject<RKRequestDelegate>*)delegate {
	RKRequest* request = [[RKRequest alloc] initWithURL:[self URLForResourcePath:resourcePath] delegate:delegate];
	[self setupRequest:request];
	[request autorelease];

	return request;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// Asynchronous Requests
///////////////////////////////////////////////////////////////////////////////////////////////////////////

- (RKRequest*)load:(NSString*)resourcePath method:(RKRequestMethod)method params:(NSObject<RKRequestSerializable>*)params delegate:(id)delegate {
	NSURL* resourcePathURL = nil;
	if (method == RKRequestMethodGET) {
		resourcePathURL = [self URLForResourcePath:resourcePath queryParams:(NSDictionary*)params];
	} else {
		resourcePathURL = [self URLForResourcePath:resourcePath];
	}
	RKRequest* request = [[RKRequest alloc] initWithURL:resourcePathURL delegate:delegate];
	[self setupRequest:request];
	[request autorelease];
	request.method = method;
	if (method != RKRequestMethodGET) {
		request.params = params;
	}
	[request send];

	return request;
}

- (RKRequest*)get:(NSString*)resourcePath delegate:(id)delegate {
	return [self load:resourcePath method:RKRequestMethodGET params:nil delegate:delegate];
}

- (RKRequest*)get:(NSString*)resourcePath queryParams:(NSDictionary*)queryParams delegate:(id)delegate {
	return [self load:resourcePath method:RKRequestMethodGET params:queryParams delegate:delegate];
}

- (RKRequest*)post:(NSString*)resourcePath params:(NSObject<RKRequestSerializable>*)params delegate:(id)delegate {
	return [self load:resourcePath method:RKRequestMethodPOST params:params delegate:delegate];
}

- (RKRequest*)put:(NSString*)resourcePath params:(NSObject<RKRequestSerializable>*)params delegate:(id)delegate {
	return [self load:resourcePath method:RKRequestMethodPUT params:params delegate:delegate];
}

- (RKRequest*)delete:(NSString*)resourcePath delegate:(id)delegate {
	return [self load:resourcePath method:RKRequestMethodDELETE params:nil delegate:delegate];
}

- (void)serviceDidBecomeUnavailableNotification:(NSNotification*)notification {
    if (self.serviceUnavailableAlertEnabled) {
        RKAlertWithTitle(self.serviceUnavailableAlertMessage, self.serviceUnavailableAlertTitle);
    }
}

- (void)reachabilityWasDetermined:(NSNotification*)notification {
    RKReachabilityObserver* observer = (RKReachabilityObserver*) [notification object];
    NSAssert(observer == _baseURLReachabilityObserver, @"Received unexpected reachability notification from inappropriate reachability observer");
    
    RKLogDebug(@"Reachability to host '%@' determined for client %@, unsuspending main queue", observer.hostName, self);
    [RKRequestQueue sharedQueue].suspended = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RKReachabilityStateWasDeterminedNotification object:observer];
}

@end
