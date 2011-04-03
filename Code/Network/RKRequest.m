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
#import <UIKit/UIKit.h>

@implementation RKRequest

@synthesize URL = _URL, URLRequest = _URLRequest, delegate = _delegate, additionalHTTPHeaders = _additionalHTTPHeaders,
			params = _params, userData = _userData, username = _username, password = _password, method = _method;

+ (RKRequest*)requestWithURL:(NSURL*)URL delegate:(id)delegate {
	return [[[RKRequest alloc] initWithURL:URL delegate:delegate] autorelease];
}

- (id)initWithURL:(NSURL*)URL {
    self = [self init];
	if (self) {
		_URL = [URL retain];
		_URLRequest = [[NSMutableURLRequest alloc] initWithURL:_URL];
		_connection = nil;
		_isLoading = NO;
		_isLoaded = NO;
	}
	return self;
}

- (id)initWithURL:(NSURL*)URL delegate:(id)delegate {
    self = [self initWithURL:URL];
	if (self) {
		_delegate = delegate;
	}
	return self;
}

- (void)dealloc {
	self.delegate = nil;
	[_connection cancel];
	[_connection release];
	_connection = nil;
	[_userData release];
	_userData = nil;
	[_URL release];
	_URL = nil;
	[_URLRequest release];
	_URLRequest = nil;
	[_params release];
	_params = nil;
	[_additionalHTTPHeaders release];
	_additionalHTTPHeaders = nil;
	[_username release];
	_username = nil;
	[_password release];
	_password = nil;
	[super dealloc];
}

- (void)setRequestBody {
	if (_params && (_method != RKRequestMethodGET)) {
		// Prefer the use of a stream over a raw body
		if ([_params respondsToSelector:@selector(HTTPBodyStream)]) {
			[_URLRequest setHTTPBodyStream:[_params HTTPBodyStream]];
		} else {
			[_URLRequest setHTTPBody:[_params HTTPBody]];
		}
	}
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
}

// Setup the NSURLRequest. The request must be prepared right before dispatching
- (void)prepareURLRequest {
	[_URLRequest setHTTPMethod:[self HTTPMethod]];
	[self setRequestBody];
	[self addHeadersToRequest];
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
		[self prepareURLRequest];
		NSString* body = [[NSString alloc] initWithData:[_URLRequest HTTPBody] encoding:NSUTF8StringEncoding];
		NSLog(@"Sending %@ request to URL %@. HTTP Body: %@", [self HTTPMethod], [[self URL] absoluteString], body);
		[body release];
		NSDate* sentAt = [NSDate date];
		NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[self HTTPMethod], @"HTTPMethod", [self URL], @"URL", sentAt, @"sentAt", nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:RKRequestSentNotification object:self userInfo:userInfo];

		_isLoading = YES;
		RKResponse* response = [[[RKResponse alloc] initWithRequest:self] autorelease];
		_connection = [[NSURLConnection connectionWithRequest:_URLRequest delegate:response] retain];
	} else {
		NSString* errorMessage = [NSString stringWithFormat:@"The client is unable to contact the resource at %@", [[self URL] absoluteString]];
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
								  errorMessage, NSLocalizedDescriptionKey,
								  nil];
		NSError* error = [NSError errorWithDomain:RKRestKitErrorDomain code:RKRequestBaseURLOfflineError userInfo:userInfo];
		[self didFailLoadWithError:error];
	}
}

- (RKResponse*)sendSynchronously {
	NSURLResponse* URLResponse = nil;
	NSError* error = nil;
	NSData* payload = nil;
	RKResponse* response = nil;

	if ([[RKClient sharedClient] isNetworkAvailable]) {
		[self prepareURLRequest];
		NSString* body = [[NSString alloc] initWithData:[_URLRequest HTTPBody] encoding:NSUTF8StringEncoding];
		NSLog(@"Sending synchronous %@ request to URL %@. HTTP Body: %@", [self HTTPMethod], [[self URL] absoluteString], body);
		[body release];
		NSDate* sentAt = [NSDate date];
		NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[self HTTPMethod], @"HTTPMethod", [self URL], @"URL", sentAt, @"sentAt", nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:RKRequestSentNotification object:self userInfo:userInfo];

		_isLoading = YES;
		payload = [NSURLConnection sendSynchronousRequest:_URLRequest returningResponse:&URLResponse error:&error];
		response = [[[RKResponse alloc] initWithSynchronousRequest:self URLResponse:URLResponse body:payload error:error] autorelease];
        
        if (error) {
            [self didFailLoadWithError:error];
        } else {
            [self didFinishLoad:response];
        }
	} else {
		NSString* errorMessage = [NSString stringWithFormat:@"The client is unable to contact the resource at %@", [[self URL] absoluteString]];
		NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
								  errorMessage, NSLocalizedDescriptionKey,
								  nil];
		error = [NSError errorWithDomain:RKRestKitErrorDomain code:RKRequestBaseURLOfflineError userInfo:userInfo];
		[self didFailLoadWithError:error];

		// TODO: Is this needed here?  Or can we just return a nil response and everyone will be happy??
		response = [[[RKResponse alloc] initWithSynchronousRequest:self URLResponse:URLResponse body:payload error:error] autorelease];
	}

	return response;
}

- (void)cancel {
	[_connection cancel];
	[_connection release];
	_connection = nil;
	_isLoading = NO;
}

- (void)didFailLoadWithError:(NSError*)error {
	_isLoading = NO;

	if ([_delegate respondsToSelector:@selector(request:didFailLoadWithError:)]) {
		[_delegate request:self didFailLoadWithError:error];
	}

	NSDate* receivedAt = [NSDate date];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[self HTTPMethod], @"HTTPMethod",
							  [self URL], @"URL", receivedAt, @"receivedAt", error, @"error", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:RKRequestFailedWithErrorNotification object:self userInfo:userInfo];
}

- (void)didFinishLoad:(RKResponse*)response {
	_isLoading = NO;
	_isLoaded = YES;

	if ([_delegate respondsToSelector:@selector(request:didLoadResponse:)]) {
		[_delegate request:self didLoadResponse:response];
	}

    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:response forKey:@"response"];
	[[NSNotificationCenter defaultCenter] postNotificationName:RKRequestDidLoadResponseNotification object:self userInfo:userInfo];
	[[NSNotificationCenter defaultCenter] postNotificationName:RKResponseReceivedNotification object:response userInfo:nil];    

	if ([response isServiceUnavailable] && [[RKClient sharedClient] serviceUnavailableAlertEnabled]) {
		UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:[[RKClient sharedClient] serviceUnavailableAlertTitle]
															message:[[RKClient sharedClient] serviceUnavailableAlertMessage]
														   delegate:nil
												  cancelButtonTitle:NSLocalizedString(@"OK", nil)
												  otherButtonTitles:nil];
		[alertView show];
		[alertView release];

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

- (BOOL)isLoading {
	return _isLoading;
}

- (BOOL)isLoaded {
	return _isLoaded;
}

- (NSString*)resourcePath {
	NSString* resourcePath = nil;
	if ([self.URL isKindOfClass:[RKURL class]]) {
		RKURL* url = (RKURL*)self.URL;
		resourcePath = url.resourcePath;
	}
	return resourcePath;
}

- (BOOL)wasSentToResourcePath:(NSString*)resourcePath {
	return [[self resourcePath] isEqualToString:resourcePath];
}

@end
