//
//  RKClient.m
//  RestKit
//
//  Created by Blake Watters on 7/28/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "RKClient.h"
#import "RKModelLoader.h"
#import <SystemConfiguration/SCNetworkReachability.h>

///////////////////////////////////////////////////////////////////////////////////////////////////
// global

static RKClient* sharedClient = nil;

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation RKClient

@synthesize baseURL = _baseURL;
@synthesize username = _username;
@synthesize password = _password;
@synthesize HTTPHeaders = _HTTPHeaders;

+ (RKClient*)client {
	return sharedClient;
}

+ (void)setClient:(RKClient*)client {
	[sharedClient release];
	sharedClient = [client retain];
}

+ (RKClient*)clientWithBaseURL:(NSString*)baseURL {
	RKClient* client = [[[RKClient alloc] init] autorelease];
	client.baseURL = baseURL;
	if (sharedClient == nil) {
		[RKClient setClient:client];
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
	Boolean success;    
	
	const char *host_name = "google.com"; // your data source host name
	
	SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, host_name);
#ifdef TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
	SCNetworkReachabilityFlags flags;
#else
	SCNetworkConnectionFlags flags;
#endif
	success = SCNetworkReachabilityGetFlags(reachability, &flags);
	BOOL isNetworkAvailable = success && (flags & kSCNetworkFlagsReachable) && !(flags & kSCNetworkFlagsConnectionRequired);
	CFRelease(reachability);
	
	return isNetworkAvailable;
	
}

- (NSURL*)URLForResourcePath:(NSString*)resourcePath {
	NSString* urlString = [NSString stringWithFormat:@"%@%@", self.baseURL, resourcePath];
	return [NSURL URLWithString:urlString];
}

- (void)setupRequest:(RKRequest*)request {
	request.additionalHTTPHeaders = _HTTPHeaders;
	request.username = self.username;
	request.password = self.password;
}

- (void)setValue:(NSString*)value forHTTPHeaderField:(NSString*)header {
	[_HTTPHeaders setValue:value forKey:header];
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// Asynchronous Requests
///////////////////////////////////////////////////////////////////////////////////////////////////////////

- (RKRequest*)get:(NSString*)resourcePath delegate:(id)delegate callback:(SEL)callback {
	RKRequest* request = [[RKRequest alloc] initWithURL:[self URLForResourcePath:resourcePath] delegate:delegate callback:callback];
	[self setupRequest:request];
	[request get];
	return request;
}

- (RKRequest*)get:(NSString*)resourcePath params:(NSDictionary*)params delegate:(id)delegate callback:(SEL)callback {
	NSString* resourcePathWithQueryString = [NSString stringWithFormat:@"%@?%@", resourcePath, [params URLEncodedString]];
	RKRequest* request = [[RKRequest alloc] initWithURL:[self URLForResourcePath:resourcePathWithQueryString] delegate:delegate callback:callback];
	[self setupRequest:request];
	[request get];
	return request;
}

- (RKRequest*)post:(NSString*)resourcePath params:(NSObject<RKRequestSerializable>*)params delegate:(id)delegate callback:(SEL)callback {
	RKRequest* request = [[RKRequest alloc] initWithURL:[self URLForResourcePath:resourcePath] delegate:delegate callback:callback];
	[self setupRequest:request];
	[request postParams:params];
	return request;
}

- (RKRequest*)put:(NSString*)resourcePath params:(NSObject<RKRequestSerializable>*)params delegate:(id)delegate callback:(SEL)callback {
	RKRequest* request = [[RKRequest alloc] initWithURL:[self URLForResourcePath:resourcePath] delegate:delegate callback:callback];
	[self setupRequest:request];
	[request putParams:params];	
	return request;
}

- (RKRequest*)delete:(NSString*)resourcePath delegate:(id)delegate callback:(SEL)callback {
	RKRequest* request = [[RKRequest alloc] initWithURL:[self URLForResourcePath:resourcePath] delegate:delegate callback:callback];
	[self setupRequest:request];
	[request delete];
	return request;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// Synchronous Requests
///////////////////////////////////////////////////////////////////////////////////////////////////////////

- (RKResponse*)getSynchronously:(NSString*)resourcePath {
	RKRequest* request = [[RKRequest alloc] initWithURL:[self URLForResourcePath:resourcePath]];
	[self setupRequest:request];
	return [request getSynchronously];
}

- (RKResponse*)getSynchronously:(NSString*)resourcePath params:(NSDictionary*)params {
	NSString* resourcePathWithQueryString = [NSString stringWithFormat:@"%@?%@", resourcePath, [params URLEncodedString]];
	RKRequest* request = [[RKRequest alloc] initWithURL:[self URLForResourcePath:resourcePathWithQueryString]];
	[self setupRequest:request];
	return [request getSynchronously];
}

- (RKResponse*)postSynchronously:(NSString*)resourcePath params:(NSObject<RKRequestSerializable>*)params {
	RKRequest* request = [[RKRequest alloc] initWithURL:[self URLForResourcePath:resourcePath]];
	[self setupRequest:request];	
	return [request postParamsSynchronously:params];
}

- (RKResponse*)putSynchronously:(NSString*)resourcePath params:(NSObject<RKRequestSerializable>*)params {
	RKRequest* request = [[RKRequest alloc] initWithURL:[self URLForResourcePath:resourcePath]];
	[self setupRequest:request];
	return [request putParamsSynchronously:params];
}

- (RKResponse*)deleteSynchronously:(NSString*)resourcePath {
	RKRequest* request = [[RKRequest alloc] initWithURL:[self URLForResourcePath:resourcePath]];
	[self setupRequest:request];
	return [request deleteSynchronously];
}

@end
