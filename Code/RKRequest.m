//
//  RKRequest.m
//  RestKit
//
//  Created by Jeremy Ellison on 7/27/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "RestKit/RKRequest.h"
#import "RestKit/RKResponse.h"
#import "RestKit/NSDictionary+RKRequestSerialization.h"
#import "RestKit/RKNotifications.h"

@implementation RKRequest

@synthesize URL = _URL, URLRequest = _URLRequest, delegate = _delegate, callback = _callback, additionalHTTPHeaders = _additionalHTTPHeaders,
			params = _params, userData = _userData, username = _username, password = _password, method = _method;

+ (RKRequest*)requestWithURL:(NSURL*)URL delegate:(id)delegate callback:(SEL)callback {
	RKRequest* request = [[RKRequest alloc] initWithURL:URL delegate:delegate callback:callback];
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

- (id)initWithURL:(NSURL*)URL delegate:(id)delegate callback:(SEL)callback {
	if (self = [self initWithURL:URL]) {
		_delegate = [delegate retain];
		_callback = callback;		
	}
	
	return self;
}

- (void)dealloc {
	[_userData release];
	[_URL release];
	[_URLRequest release];
	[_delegate release];
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
		[_URLRequest setValue:[_params ContentTypeHTTPHeader] forHTTPHeaderField:@"Content-Type"];
	}	
	NSLog(@"Headers: %@", [_URLRequest allHTTPHeaderFields]);
}

- (void)setMethod:(RKRequestMethod)method {
	_method = method;
	[_URLRequest setHTTPMethod:[self HTTPMethod]];
}

- (void)setParams:(NSObject<RKRequestSerializable>*)params {
	_params = [params retain];
	[_URLRequest setHTTPBody:[_params HTTPBody]];
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
	[self addHeadersToRequest];
	NSString* body = [[NSString alloc] initWithData:[_URLRequest HTTPBody] encoding:NSUTF8StringEncoding];
	NSLog(@"Sending %@ request to URL %@. HTTP Body: %@", [self HTTPMethod], [[self URL] absoluteString], body);
	[body release];
	NSDate* sentAt = [NSDate date];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[self HTTPMethod], @"HTTPMethod", [self URL], @"URL", sentAt, @"sentAt", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:kRKRequestSentNotification object:self userInfo:userInfo];
	RKResponse* response = [[[RKResponse alloc] initWithRestRequest:self] autorelease];
	_connection = [[NSURLConnection connectionWithRequest:_URLRequest delegate:response] retain];
}

- (RKResponse*)sendSynchronously {
	[self addHeadersToRequest];
	NSString* body = [[NSString alloc] initWithData:[_URLRequest HTTPBody] encoding:NSUTF8StringEncoding];
	NSLog(@"Sending synchronous %@ request to URL %@. HTTP Body: %@", [self HTTPMethod], [[self URL] absoluteString], body);
	[body release];
	NSDate* sentAt = [NSDate date];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[self HTTPMethod], @"HTTPMethod", [self URL], @"URL", sentAt, @"sentAt", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:kRKRequestSentNotification object:self userInfo:userInfo];	
	NSURLResponse *URLResponse;
	NSError *error;
	NSData* payload = [NSURLConnection sendSynchronousRequest:_URLRequest returningResponse:&URLResponse error:&error];
	return [[[RKResponse alloc] initWithSynchronousRequest:self URLResponse:URLResponse body:payload error:error] autorelease];
}

- (void)sendWithMethod:(RKRequestMethod)method {
	self.method = method;
	[self send];
}

- (RKResponse*)sendSynchronouslyWithMethod:(RKRequestMethod)method {
	self.method = method;
	return [self sendSynchronously];
}

- (void)cancel {
	[_connection cancel];
	[_connection release];
	_connection = nil;
	if ([_delegate respondsToSelector:@selector(requestDidCancelLoad:)]) {
		[_delegate requestDidCancelLoad:self];
	}
}

@end
