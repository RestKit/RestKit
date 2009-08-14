//
//  OTRestClient.m
//  gateguru
//
//  Created by Blake Watters on 7/28/09.
//  Copyright 2009 Objective 3. All rights reserved.
//

#import "OTRestClient.h"
#import "OTRestModelLoader.h"

///////////////////////////////////////////////////////////////////////////////////////////////////
// global

static OTRestClient* sharedClient = nil;

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation OTRestClient

@synthesize baseURL = _baseURL;
@synthesize username = _username;
@synthesize password = _password;
@synthesize HTTPHeaders = _HTTPHeaders;

+ (OTRestClient*)client {
	return sharedClient;
}

+ (void)setClient:(OTRestClient*)client {
	[sharedClient release];
	sharedClient = [client retain];
}

+ (OTRestClient*)clientWithBaseURL:(NSString*)baseURL {
	OTRestClient* client = [[[OTRestClient alloc] init] autorelease];
	client.baseURL = baseURL;
	if (sharedClient == nil) {
		[OTRestClient setClient:client];
	}
	
	return client;
}

+ (OTRestClient*)clientWithBaseURL:(NSString*)baseURL username:(NSString*)username password:(NSString*)password {
	OTRestClient* client = [OTRestClient clientWithBaseURL:baseURL];
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

- (NSURL*)URLForResourcePath:(NSString*)resourcePath {
	NSString* urlString = [NSString stringWithFormat:@"%@%@", self.baseURL, resourcePath];
	return [NSURL URLWithString:urlString];
}

- (OTRestRequest*)get:(NSString*)resourcePath delegate:(id)delegate callback:(SEL)callback {
	OTRestRequest* request = [[OTRestRequest alloc] initWithURL:[self URLForResourcePath:resourcePath] delegate:delegate callback:callback];
	request.additionalHTTPHeaders = _HTTPHeaders;
	[request get];
	return request;
}

- (OTRestRequest*)post:(NSString*)resourcePath params:(NSObject<OTRestRequestSerializable>*)params delegate:(id)delegate callback:(SEL)callback {
	OTRestRequest* request = [[OTRestRequest alloc] initWithURL:[self URLForResourcePath:resourcePath] delegate:delegate callback:callback];
	request.additionalHTTPHeaders = _HTTPHeaders;
	[request postParams:params];
	return request;
}

- (OTRestRequest*)put:(NSString*)resourcePath params:(NSObject<OTRestRequestSerializable>*)params delegate:(id)delegate callback:(SEL)callback {
	OTRestRequest* request = [[OTRestRequest alloc] initWithURL:[self URLForResourcePath:resourcePath] delegate:delegate callback:callback];
	request.additionalHTTPHeaders = _HTTPHeaders;
	[request putParams:params];	
	return request;
}

- (OTRestRequest*)delete:(NSString*)resourcePath delegate:(id)delegate callback:(SEL)callback {
	OTRestRequest* request = [[OTRestRequest alloc] initWithURL:[self URLForResourcePath:resourcePath] delegate:delegate callback:callback];
	request.additionalHTTPHeaders = _HTTPHeaders;
	[request delete];
	return request;
}

- (void)setValue:(NSString*)value forHTTPHeaderField:(NSString*)header {
	[_HTTPHeaders setValue:value forKey:header];
}

@end
