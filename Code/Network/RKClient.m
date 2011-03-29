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

///////////////////////////////////////////////////////////////////////////////////////////////////

@implementation RKClient

@synthesize baseURL = _baseURL;
@synthesize username = _username;
@synthesize password = _password;
@synthesize HTTPHeaders = _HTTPHeaders;
@synthesize baseURLReachabilityObserver = _baseURLReachabilityObserver;
@synthesize serviceUnavailableAlertTitle = _serviceUnavailableAlertTitle;
@synthesize serviceUnavailableAlertMessage = _serviceUnavailableAlertMessage;
@synthesize serviceUnavailableAlertEnabled = _serviceUnavailableAlertEnabled;

+ (RKClient*)sharedClient {
	return sharedClient;
}

+ (void)setSharedClient:(RKClient*)client {
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
    self = [super init];
	if (self) {
		_HTTPHeaders = [[NSMutableDictionary alloc] init];
		self.serviceUnavailableAlertEnabled = NO;
		self.serviceUnavailableAlertTitle = NSLocalizedString(@"Service Unavailable", nil);
		self.serviceUnavailableAlertMessage = NSLocalizedString(@"The remote resource is unavailable. Please try again later.", nil);
	}

	return self;
}

- (void)dealloc {
	self.baseURL = nil;
	self.username = nil;
	self.password = nil;
	self.serviceUnavailableAlertTitle = nil;
	self.serviceUnavailableAlertMessage = nil;
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

- (NSString*)URLPathForResourcePath:(NSString*)resourcePath {
	return [[self URLForResourcePath:resourcePath] absoluteString];
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
    
    // Don't crash if baseURL is nil'd out (i.e. dealloc)
    if (baseURL) {
        NSURL* URL = [NSURL URLWithString:baseURL];
        _baseURLReachabilityObserver = [[RKReachabilityObserver reachabilityObserverWithHostName:[URL host]] retain];
    }
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
	request.method = method;
	request.params = params;
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
