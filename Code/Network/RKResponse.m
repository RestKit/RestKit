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
#import "RKNetwork.h"

@implementation RKResponse

@synthesize body = _body, request = _request, failureError = _failureError;

- (id)init {
    self = [super init];
	if (self) {
		_body = [[NSMutableData alloc] init];
		_failureError = nil;
	}

	return self;
}

- (id)initWithRequest:(RKRequest*)request {
    self = [self init];
	if (self) {
		// We don't retain here as we're letting RKRequestQueue manage
		// request ownership
		_request = request;
	}

	return self;
}

- (id)initWithSynchronousRequest:(RKRequest*)request URLResponse:(NSURLResponse*)URLResponse body:(NSData*)body error:(NSError*)error {
    self = [super init];
	if (self) {
		// TODO: Does the lack of retain here cause problems with synchronous requests, since they
		// are not being retained by the RKRequestQueue??
		_request = request;
		_httpURLResponse = [URLResponse retain];
		_failureError = [error retain];
		_body = [body retain];
	}

	return self;
}

- (void)dealloc {
	[_httpURLResponse release];
	[_body release];
	[_failureError release];
	[super dealloc];
}

// Handle basic auth
- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    if ([challenge previousFailureCount] == 0) {
        NSURLCredential *newCredential;
        newCredential = [NSURLCredential credentialWithUser:[NSString stringWithFormat:@"%@", _request.username]
                                                   password:[NSString stringWithFormat:@"%@", _request.password]
                                                persistence:RKNetworkGetGlobalCredentialPersistence()];
        [[challenge sender] useCredential:newCredential
               forAuthenticationChallenge:challenge];
    } else {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[_body appendData:data];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {	
	_httpURLResponse = [response retain];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	[_request didFinishLoad:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	_failureError = [error retain];
	[_request didFailLoadWithError:_failureError];
}

// In the event that the url request is a post, this delegate method will be called before
// either connection:didReceiveData: or connection:didReceiveResponse:
// However this method is only called if there is payload data to be sent.
// Therefore, we ensure the delegate recieves the did start loading here and
// in connection:didReceiveResponse: to ensure that the RKRequestDelegate
// callbacks get called in the correct order.
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

- (NSArray*)cookies {
	return [NSHTTPCookie cookiesWithResponseHeaderFields:self.allHeaderFields forURL:self.URL];
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

- (BOOL)isUnauthorized {
	return ([self statusCode] == 401);
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

- (BOOL)isServiceUnavailable {
	return ([self statusCode] == 503);
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
	NSString* contentType = [self contentType];
	return contentType && ([contentType rangeOfString:@"text/html" options:NSCaseInsensitiveSearch|NSAnchoredSearch].length > 0 ||
						   [self isXHTML]);
}

- (BOOL)isXHTML {
	NSString* contentType = [self contentType];
	return contentType && [contentType rangeOfString:@"application/xhtml+xml" options:NSCaseInsensitiveSearch|NSAnchoredSearch].length > 0;
}

- (BOOL)isXML {
	NSString* contentType = [self contentType];
	return contentType && [contentType rangeOfString:@"application/xml" options:NSCaseInsensitiveSearch|NSAnchoredSearch].length > 0;
}

- (BOOL)isJSON {
	NSString* contentType = [self contentType];
	return contentType && [contentType rangeOfString:@"application/json" options:NSCaseInsensitiveSearch|NSAnchoredSearch].length > 0;
}

@end
