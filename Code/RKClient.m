//
//  RKClient.m
//  RestKit
//
//  Created by Blake Watters on 7/28/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "RKClient.h"
#import "RKResourceLoader.h"
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

- (RKRequest*)load:(NSString*)resourcePath method:(RKRequestMethod)method delegate:(id)delegate callback:(SEL)callback {
	RKRequest* request = [[RKRequest alloc] initWithURL:[self URLForResourcePath:resourcePath] delegate:delegate callback:callback];
	[self setupRequest:request];
	[request sendWithMethod:method];
	return request;
}

- (RKRequest*)load:(NSString*)resourcePath method:(RKRequestMethod)method params:(NSObject<RKRequestSerializable>*)params delegate:(id)delegate callback:(SEL)callback {
	RKRequest* request = [[RKRequest alloc] initWithURL:[self URLForResourcePath:resourcePath] delegate:delegate callback:callback];
	[self setupRequest:request];
	request.params = params;
	[request sendWithMethod:method];
	return request;
}

- (RKRequest*)load:(NSString*)resourcePath fetchRequest:(NSFetchRequest*)fetchRequest method:(RKRequestMethod)method params:(NSObject<RKRequestSerializable>*)params delegate:(id)delegate callback:(SEL)callback {
	RKRequest* request = [[RKRequest alloc] initWithURL:[self URLForResourcePath:resourcePath] delegate:delegate callback:callback];
	[self setupRequest:request];
	request.params = params;
	request.fetchRequest = fetchRequest;
	[request sendWithMethod:method];
	return request;
}

- (RKRequest*)get:(NSString*)resourcePath delegate:(id)delegate callback:(SEL)callback {
	return [self load:resourcePath method:RKRequestMethodGET delegate:delegate callback:callback];
}

- (RKRequest*)get:(NSString*)resourcePath params:(NSDictionary*)params delegate:(id)delegate callback:(SEL)callback {
	NSString* resourcePathWithQueryString = [NSString stringWithFormat:@"%@?%@", resourcePath, [params URLEncodedString]];
	return [self load:resourcePathWithQueryString method:RKRequestMethodGET delegate:delegate callback:callback];
}

- (RKRequest*)post:(NSString*)resourcePath params:(NSObject<RKRequestSerializable>*)params delegate:(id)delegate callback:(SEL)callback {
	return [self load:resourcePath method:RKRequestMethodPOST params:params delegate:delegate callback:callback];
}

- (RKRequest*)put:(NSString*)resourcePath params:(NSObject<RKRequestSerializable>*)params delegate:(id)delegate callback:(SEL)callback {
	return [self load:resourcePath method:RKRequestMethodPUT params:params delegate:delegate callback:callback];
}

- (RKRequest*)delete:(NSString*)resourcePath delegate:(id)delegate callback:(SEL)callback {
	return [self load:resourcePath method:RKRequestMethodDELETE delegate:delegate callback:callback];
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// Synchronous Requests
///////////////////////////////////////////////////////////////////////////////////////////////////////////

- (RKResponse*)loadSynchronously:(NSString*)resourcePath method:(RKRequestMethod)method {
	RKRequest* request = [[[RKRequest alloc] initWithURL:[self URLForResourcePath:resourcePath]] autorelease];
	[self setupRequest:request];	
	return [request sendSynchronouslyWithMethod:method];;
}

- (RKResponse*)loadSynchronously:(NSString*)resourcePath method:(RKRequestMethod)method params:(NSObject<RKRequestSerializable>*)params {
	RKRequest* request = [[[RKRequest alloc] initWithURL:[self URLForResourcePath:resourcePath]] autorelease];
	[self setupRequest:request];
	request.params = params;	
	return [request sendSynchronouslyWithMethod:method];;
}

- (RKResponse*)getSynchronously:(NSString*)resourcePath {
	return [self loadSynchronously:resourcePath method:RKRequestMethodGET];
}

- (RKResponse*)getSynchronously:(NSString*)resourcePath params:(NSDictionary*)params {
	NSString* resourcePathWithQueryString = [NSString stringWithFormat:@"%@?%@", resourcePath, [params URLEncodedString]];
	return [self loadSynchronously:resourcePathWithQueryString method:RKRequestMethodGET];
}

- (RKResponse*)postSynchronously:(NSString*)resourcePath params:(NSObject<RKRequestSerializable>*)params {
	return [self loadSynchronously:resourcePath method:RKRequestMethodPOST params:params];
}

- (RKResponse*)putSynchronously:(NSString*)resourcePath params:(NSObject<RKRequestSerializable>*)params {
	return [self loadSynchronously:resourcePath method:RKRequestMethodPUT params:params];
}

- (RKResponse*)deleteSynchronously:(NSString*)resourcePath {
	return [self loadSynchronously:resourcePath method:RKRequestMethodDELETE];
}

@end
