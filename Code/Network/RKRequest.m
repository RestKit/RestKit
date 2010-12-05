//
//  RKRequest.m
//  RestKit
//
//  Created by Jeremy Ellison on 7/27/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "RKRequest.h"
#import "RKResponse.h"
#import "NSDictionary+RKRequestSerialization.h"
#import "RKNotifications.h"

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
		_delegate = delegate;
		_callback = callback;		
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
    if (_username != nil) {
        // Add authentication headers so we don't have to deal with an extra cycle for each message requiring basic auth.
        CFHTTPMessageRef dummyRequest = CFHTTPMessageCreateRequest(kCFAllocatorDefault, (CFStringRef)[self HTTPMethod], (CFURLRef)[self URL], kCFHTTPVersion1_1);
        CFHTTPMessageAddAuthentication(dummyRequest, nil, (CFStringRef)_username, (CFStringRef)_password, kCFHTTPAuthenticationSchemeBasic, FALSE);
        CFStringRef authorizationString = CFHTTPMessageCopyHeaderFieldValue(dummyRequest, CFSTR("Authorization"));
        
        [_URLRequest setValue:(NSString *)authorizationString forHTTPHeaderField:@"Authorization"];
        
        CFRelease(dummyRequest);
        CFRelease(authorizationString);
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
	[self addHeadersToRequest];
	NSString* body = [[NSString alloc] initWithData:[_URLRequest HTTPBody] encoding:NSUTF8StringEncoding];
	NSLog(@"Sending %@ request to URL %@. HTTP Body: %@", [self HTTPMethod], [[self URL] absoluteString], body);
	[body release];
	NSDate* sentAt = [NSDate date];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[self HTTPMethod], @"HTTPMethod", [self URL], @"URL", sentAt, @"sentAt", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:kRKRequestSentNotification object:self userInfo:userInfo];
	RKResponse* response = [[[RKResponse alloc] initWithRequest:self] autorelease];
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
	NSURLResponse* URLResponse = nil;
	NSError* error = nil;
	NSData* payload = [NSURLConnection sendSynchronousRequest:_URLRequest returningResponse:&URLResponse error:&error];
	return [[[RKResponse alloc] initWithSynchronousRequest:self URLResponse:URLResponse body:payload error:error] autorelease];
}

- (void)cancel {
	[_connection cancel];
	[_connection release];
	_connection = nil;
	if ([_delegate respondsToSelector:@selector(requestDidCancelLoad:)]) {
		[_delegate requestDidCancelLoad:self];
	}
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

@end
