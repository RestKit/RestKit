//
//  RKResponse.m
//  RKFramework
//
//  Created by Blake Watters on 7/28/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "RKResponse.h"
#import "RKNotifications.h"
#import "RKJSONParser.h"

@implementation RKResponse

@synthesize body = _body, request = _request, failureError = _failureError;

- (id)init {
	if (self = [super init]) {
		_body = [[NSMutableData alloc] init];
		_failureError = nil;
		_loading = NO;
	}
	
	return self;
}

- (id)initWithRequest:(RKRequest*)request {
	if (self = [self init]) {
		_request = [request retain];
	}
	
	return self;
}

- (id)initWithSynchronousRequest:(RKRequest*)request URLResponse:(NSURLResponse*)URLResponse body:(NSData*)body error:(NSError*)error {
	if (self = [super init]) {
		_request = [request retain];		
		_httpURLResponse = [URLResponse retain];
		_failureError = [error retain];
		_body = [body retain];
		_loading = NO;
	}
	
	return self;
}

- (void)dealloc {
	[_httpURLResponse release];
	[_body release];
	[_request release];
	[_failureError release];
	[super dealloc];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	if (NO == _loading) {
		_loading = YES;
		if ([[_request delegate] respondsToSelector:@selector(requestDidStartLoad:)]) {
			[[_request delegate] requestDidStartLoad:_request];
		}
	}
	
	[_body appendData:data];		
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
	_httpURLResponse = [response retain];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {	
	NSDate* receivedAt = [NSDate date]; // TODO - Carry around this timestamp on the response or request?
	NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[_request HTTPMethod], @"HTTPMethod", [_request URL], @"URL", receivedAt, @"receivedAt", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:kRKResponseReceivedNotification object:self userInfo:userInfo];	
	
	[[_request delegate] performSelector:[_request callback] withObject:self];
	
	if ([[_request delegate] respondsToSelector:@selector(requestDidFinishLoad:)]) {
		[[_request delegate] requestDidFinishLoad:_request];
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	_failureError = [error retain];
	[[_request delegate] performSelector:[_request callback] withObject:self];
	
	if ([[_request delegate] respondsToSelector:@selector(request:didFailLoadWithError:)]) {
		[[_request delegate] request:_request didFailLoadWithError:error];
	}
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {	
	if ([[_request delegate] respondsToSelector:@selector(request:didSendBodyData:totalBytesWritten:totalBytesExpectedToWrite:)]) {
		[[_request delegate] request:_request didSendBodyData:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
	}
}


- (NSString*)localizedStatusCodeString {
	return [NSHTTPURLResponse localizedStringForStatusCode:[self statusCode]];
}

- (NSString*)bodyAsString {
	return [[[NSString alloc] initWithData:self.body encoding:NSUTF8StringEncoding] autorelease];
}

- (id)bodyAsJSON {
	return [[[[RKJSONParser alloc] init] autorelease] objectFromString:[self bodyAsString]];
}

- (NSString*)failureErrorDescription {
	if ([self isFailure]) {
		return [_failureError localizedDescription];
	} else {
		return nil;				
	}
}

- (NSURL*)URL {
	return [_httpURLResponse URL];
}

- (NSString*)MIMEType {
	return [_httpURLResponse MIMEType];
}

- (NSInteger)statusCode {
	return [_httpURLResponse statusCode];
}

- (NSDictionary*)allHeaderFields {
	return [_httpURLResponse allHeaderFields];
}

- (BOOL)isFailure {
	return (nil != _failureError);
}

- (BOOL)isInvalid {
	return ([self statusCode] < 100 || [self statusCode] > 600);
}

- (BOOL)isInformational {
	return ([self statusCode] >= 100 && [self statusCode] < 200);
}

- (BOOL)isSuccessful {
	return ([self statusCode] >= 200 && [self statusCode] < 300);
}

- (BOOL)isRedirection {
	return ([self statusCode] >= 300 && [self statusCode] < 400);
}

- (BOOL)isClientError {
	return ([self statusCode] >= 400 && [self statusCode] < 500);
}

- (BOOL)isServerError {
	return ([self statusCode] >= 500 && [self statusCode] < 600);
}

- (BOOL)isError {
	return ([self isClientError] || [self isServerError]);
}

- (BOOL)isOK {
	return ([self statusCode] == 200);
}

- (BOOL)isCreated {
	return ([self statusCode] == 201);
}

- (BOOL)isForbidden {
	return ([self statusCode] == 403);
}

- (BOOL)isNotFound {
	return ([self statusCode] == 404);
}

- (BOOL)isUnprocessableEntity {
	return ([self statusCode] == 422);
}

- (BOOL)isRedirect {
	return ([self statusCode] == 301 || [self statusCode] == 302 || [self statusCode] == 303 || [self statusCode] == 307);
}

- (BOOL)isEmpty {
	return ([self statusCode] == 201 || [self statusCode] == 204 || [self statusCode] == 304);
}

- (NSString*)contentType {
	return ([[self allHeaderFields] objectForKey:@"Content-Type"]);
}

- (NSString*)contentLength {
	return ([[self allHeaderFields] objectForKey:@"Content-Length"]);
}

- (NSString*)location {
	return ([[self allHeaderFields] objectForKey:@"Location"]);
}

- (BOOL)isHTML {
	return [[self contentType] rangeOfString:@"text/html" options:NSCaseInsensitiveSearch|NSAnchoredSearch].length > 0 ||
			[self isXHTML];
}

- (BOOL)isXHTML {
	return [[self contentType] rangeOfString:@"application/xhtml+xml" options:NSCaseInsensitiveSearch|NSAnchoredSearch].length > 0;
}

- (BOOL)isXML {
	return [[self contentType] rangeOfString:@"application/xml" options:NSCaseInsensitiveSearch|NSAnchoredSearch].length > 0;
}

- (BOOL)isJSON {
	return [[self contentType] rangeOfString:@"application/json" options:NSCaseInsensitiveSearch|NSAnchoredSearch].length > 0;
}

@end
