//
//  RKRequest.m
//  RestKit
//
//  Created by Jeremy Ellison on 7/27/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "RKRequest.h"
#import "RKRequestQueue.h"
#import "RKResponse.h"
#import "NSDictionary+RKRequestSerialization.h"
#import "RKNotifications.h"
#import "RKClient.h"
#import "../Support/Support.h"
#import "RKURL.h"

@implementation RKRequest

@synthesize URL = _URL, URLRequest = _URLRequest, delegate = _delegate, additionalHTTPHeaders = _additionalHTTPHeaders,
			params = _params, userData = _userData, username = _username, password = _password, method = _method;

+ (RKRequest*)requestWithURL:(NSURL*)URL delegate:(id)delegate {
	RKRequest* request = [[RKRequest alloc] initWithURL:URL delegate:delegate];
	[request autorelease];
	
	return request;
}

- (id)initWithURL:(NSURL*)URL {
	if (self = [self init]) {
		_URL = [URL retain];
		_URLRequest = [[NSMutableURLRequest alloc] initWithURL:_URL];
		_connection = nil;
	}
	
	return self;
}

- (id)initWithURL:(NSURL*)URL delegate:(id)delegate {
	if (self = [self initWithURL:URL]) {
		_delegate = delegate;
	}
	
	return self;
}

- (void)dealloc {
	[_connection cancel];
	[_connection release];
	[_userData release];
	[_URL release];
	[_URLRequest release];
	[_params release];
	[_additionalHTTPHeaders release];
	[_username release];
	[_password release];
	[super dealloc];
}

- (void)addHeadersToRequest {
	NSString* header;
	for (header in _additionalHTTPHeaders) {
		[_URLRequest setValue:[_additionalHTTPHeaders valueForKey:header] forHTTPHeaderField:header];
	}
	if (_params != nil) {
		// Temporarily support older RKRequestSerializable implementations
		if ([_params respondsToSelector:@selector(HTTPHeaderValueForContentType)]) {
			[_URLRequest setValue:[_params HTTPHeaderValueForContentType] forHTTPHeaderField:@"Content-Type"];
		} else if ([_params respondsToSelector:@selector(ContentTypeHTTPHeader)]) {
			[_URLRequest setValue:[_params performSelector:@selector(ContentTypeHTTPHeader)] forHTTPHeaderField:@"Content-Type"];
		}		
		if ([_params respondsToSelector:@selector(HTTPHeaderValueForContentLength)]) {
			[_URLRequest setValue:[NSString stringWithFormat:@"%d", [_params HTTPHeaderValueForContentLength]] forHTTPHeaderField:@"Content-Length"];
		}
	}	
	NSLog(@"Headers: %@", [_URLRequest allHTTPHeaderFields]);
}

- (void)setMethod:(RKRequestMethod)method {
	_method = method;
	[_URLRequest setHTTPMethod:[self HTTPMethod]];
}

- (void)setParams:(NSObject<RKRequestSerializable>*)params {
	[params retain];
	[_params release];
	_params = params;
	
	if (params) {
		// Prefer the use of a stream over a raw body
		if ([_params respondsToSelector:@selector(HTTPBodyStream)]) {			
			[_URLRequest setHTTPBodyStream:[_params HTTPBodyStream]];			
		} else {
			[_URLRequest setHTTPBody:[_params HTTPBody]];
		}
	}
}

- (NSString*)HTTPMethod {
	switch (_method) {
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
		default:
			return nil;
			break;
	}
}

- (void)send {
	[[RKRequestQueue sharedQueue] sendRequest:self];
}

- (void)fireAsynchronousRequest {
	if ([[RKClient sharedClient] isNetworkAvailable]) {
		[self addHeadersToRequest];
		NSString* body = [[NSString alloc] initWithData:[_URLRequest HTTPBody] encoding:NSUTF8StringEncoding];
		NSLog(@"Sending %@ request to URL %@. HTTP Body: %@", [self HTTPMethod], [[self URL] absoluteString], body);
		[body release];
		NSDate* sentAt = [NSDate date];
		NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[self HTTPMethod], @"HTTPMethod", [self URL], @"URL", sentAt, @"sentAt", nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:kRKRequestSentNotification object:self userInfo:userInfo];
		
		RKResponse* response = [[[RKResponse alloc] initWithRequest:self] autorelease];
		_connection = [[NSURLConnection connectionWithRequest:_URLRequest delegate:response] retain];
	} else {
		NSString* errorMessage = [NSString stringWithFormat:@"The client is unable to contact the resource at %@", [[self URL] absoluteString]];
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
								  errorMessage, NSLocalizedDescriptionKey,
								  nil];
		NSError* error = [NSError errorWithDomain:RKRestKitErrorDomain code:RKRequestBaseURLOfflineError userInfo:userInfo];		
		RKResponse* response = [[[RKResponse alloc] initWithRequest:self error:error] autorelease];
	}
}

- (RKResponse*)sendSynchronously {
	NSURLResponse* URLResponse = nil;
	NSError* error = nil;
	NSData* payload = nil;
	RKResponse* response = nil;
	
	if ([[RKClient sharedClient] isNetworkAvailable]) {
		[self addHeadersToRequest];
		NSString* body = [[NSString alloc] initWithData:[_URLRequest HTTPBody] encoding:NSUTF8StringEncoding];
		NSLog(@"Sending synchronous %@ request to URL %@. HTTP Body: %@", [self HTTPMethod], [[self URL] absoluteString], body);
		[body release];
		NSDate* sentAt = [NSDate date];
		NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[self HTTPMethod], @"HTTPMethod", [self URL], @"URL", sentAt, @"sentAt", nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:kRKRequestSentNotification object:self userInfo:userInfo];
		
		payload = [NSURLConnection sendSynchronousRequest:_URLRequest returningResponse:&URLResponse error:&error];
		response = [[[RKResponse alloc] initWithSynchronousRequest:self URLResponse:URLResponse body:payload error:error] autorelease];
	} else {
		NSString* errorMessage = [NSString stringWithFormat:@"The client is unable to contact the resource at %@", [[self URL] absoluteString]];
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
								  errorMessage, NSLocalizedDescriptionKey,
								  nil];
		error = [NSError errorWithDomain:RKRestKitErrorDomain code:RKRequestBaseURLOfflineError userInfo:userInfo];
		response = [[[RKResponse alloc] initWithSynchronousRequest:self URLResponse:URLResponse body:payload error:error] autorelease];
	}
	
	return response;
}

- (void)cancel {
	[_connection cancel];
	[_connection release];
	_connection = nil;
}

- (BOOL)isGET {
	return _method == RKRequestMethodGET;
}

- (BOOL)isPOST {
	return _method == RKRequestMethodPOST;
}

- (BOOL)isPUT {
	return _method == RKRequestMethodPUT;
}

- (BOOL)isDELETE {
	return _method == RKRequestMethodDELETE;
}

- (NSString*)resourcePath {
	NSString* resourcePath = nil;
	if ([self.URL isKindOfClass:[RKURL class]]) {
		RKURL* url = (RKURL*)self.URL;
		resourcePath = url.resourcePath;
	}
	return resourcePath;
}

@end
