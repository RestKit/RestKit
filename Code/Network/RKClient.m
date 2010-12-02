//
//  RKClient.m
//  RestKit
//
//  Created by Blake Watters on 7/28/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "RKClient.h"
#import "RKObjectLoader.h"
#import "RKURL.h"
#import <SystemConfiguration/SCNetworkReachability.h>

///////////////////////////////////////////////////////////////////////////////////////////////////
// Global

static RKClient* sharedClient = nil;

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation RKClient

@synthesize baseURL = _baseURL;
@synthesize username = _username;
@synthesize password = _password;
@synthesize HTTPHeaders = _HTTPHeaders;
@synthesize baseURLReachabilityObserver = _baseURLReachabilityObserver;

+ (RKClient*)sharedClient {
	return sharedClient;
}

+ (void)setSharedClient:(RKClient*)client {
	[sharedClient release];
	sharedClient = [client retain];
}

// Deprecated
+ (RKClient*)client {
	return sharedClient;
}

// Deprecated
+ (void)setClient:(RKClient*)client {
	[sharedClient release];
	sharedClient = [client retain];
}

+ (RKClient*)clientWithBaseURL:(NSString*)baseURL {
	RKClient* client = [[[RKClient alloc] init] autorelease];
	client.baseURL = baseURL;
	if (sharedClient == nil) {
		[RKClient setSharedClient:client];
	}
	
	return client;
}

+ (RKClient*)clientWithBaseURL:(NSString*)baseURL username:(NSString*)username password:(NSString*)password {
	RKClient* client = [RKClient clientWithBaseURL:baseURL];
	client.username = username;
	client.password = password;
	
	return client;
}

- (id)init {
	if (self = [super init]) {
		_HTTPHeaders = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

- (void)dealloc {
	[_baseURL release];
	[_username release];
	[_password release];
	[_HTTPHeaders release];
	[super dealloc];
}

- (BOOL)isNetworkAvailable {
	BOOL isNetworkAvailable = NO;
	if (self.baseURLReachabilityObserver) {
		isNetworkAvailable = [self.baseURLReachabilityObserver isNetworkReachable];
	} else {
		RKReachabilityObserver* googleObserver = [RKReachabilityObserver reachabilityObserverWithHostName:@"google.com"];
		isNetworkAvailable = [googleObserver isNetworkReachable];
	}
	return isNetworkAvailable;
}

- (NSString*)resourcePath:(NSString*)resourcePath withQueryParams:(NSDictionary*)queryParams {
	return [NSString stringWithFormat:@"%@?%@", resourcePath, [queryParams URLEncodedString]];
}

- (NSURL*)URLForResourcePath:(NSString*)resourcePath {
	return [RKURL URLWithBaseURLString:self.baseURL resourcePath:resourcePath];
}

- (NSURL*)URLForResourcePath:(NSString *)resourcePath queryParams:(NSDictionary*)queryParams {
	return [self URLForResourcePath:[self resourcePath:resourcePath withQueryParams:queryParams]];
}

- (void)setupRequest:(RKRequest*)request {
	request.additionalHTTPHeaders = _HTTPHeaders;
	request.username = self.username;
	request.password = self.password;
}

- (void)setValue:(NSString*)value forHTTPHeaderField:(NSString*)header {
	[_HTTPHeaders setValue:value forKey:header];
}

- (void)setBaseURL:(NSString*)baseURL {
	[_baseURL release];
	_baseURL = nil;
	_baseURL = [baseURL retain];
	
	[_baseURLReachabilityObserver release];
	_baseURLReachabilityObserver = nil;
	_baseURLReachabilityObserver = [[RKReachabilityObserver reachabilityObserverWithHostName:baseURL] retain];
}

- (RKRequest*)requestWithResourcePath:(NSString*)resourcePath delegate:(id)delegate {
	RKRequest* request = [[RKRequest alloc] initWithURL:[self URLForResourcePath:resourcePath] delegate:delegate];
	[self setupRequest:request];
	[request autorelease];
	
	return request;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// Asynchronous Requests
///////////////////////////////////////////////////////////////////////////////////////////////////////////

- (RKRequest*)load:(NSString*)resourcePath method:(RKRequestMethod)method params:(NSObject<RKRequestSerializable>*)params delegate:(id)delegate {
	RKRequest* request = [[RKRequest alloc] initWithURL:[self URLForResourcePath:resourcePath] delegate:delegate];
	[self setupRequest:request];
	[request autorelease];
	request.params = params;
	request.method = method;
	[request send];
	
	return request;
}

- (RKRequest*)get:(NSString*)resourcePath delegate:(id)delegate {
	return [self load:resourcePath method:RKRequestMethodGET params:nil delegate:delegate];
}

- (RKRequest*)get:(NSString*)resourcePath queryParams:(NSDictionary*)queryParams delegate:(id)delegate {
	NSString* resourcePathWithQueryString = [NSString stringWithFormat:@"%@?%@", resourcePath, [queryParams URLEncodedString]];
	return [self load:resourcePathWithQueryString method:RKRequestMethodGET params:nil delegate:delegate];
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

@end
