//
//  RKResponse.m
//  RKFramework
//
//  Created by Blake Watters on 7/28/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "RKResponse.h"
#import "RKNotifications.h"
#import "SBJSON.h"

@implementation RKResponse

@synthesize payload = _payload, request = _request, failureError = _failureError;

- (id)init {
	if (self = [super init]) {
		_payload = [[NSMutableData alloc] init];
		_failureError = nil;
		_loading = NO;
	}
	
	return self;
}

- (id)initWithRestRequest:(RKRequest*)request {
	if (self = [self init]) {
		_request = [request retain];
	}
	
	return self;
}

- (id)initWithSynchronousRequest:(RKRequest*)request URLResponse:(NSURLResponse*)URLResponse payload:(NSData*)payload error:(NSError*)error {
	if (self = [super init]) {
		_request = [request retain];		
		_httpURLResponse = [URLResponse retain];
		_failureError = [error retain];
		_payload = [payload retain];
		_failureError = [error retain];
		_loading = NO;
	}
	
	return self;
}

- (void)dealloc {
	[_httpURLResponse release];
	[_payload release];
	[_request release];
	[_failureError release];
	[super dealloc];
}

// Handle basic auth
-(void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    if ([challenge previousFailureCount] == 0) {
        NSURLCredential *newCredential;
        newCredential=[NSURLCredential credentialWithUser:[NSString stringWithFormat:@"%@", _request.username]
                                                 password:[NSString stringWithFormat:@"%@", _request.password]
                                              persistence:NSURLCredentialPersistenceNone];
        [[challenge sender] useCredential:newCredential
               forAuthenticationChallenge:challenge];
    } else {
        [[challenge sender] cancelAuthenticationChallenge:challenge];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	if (NO == _loading) {
		_loading = YES;
		if ([[_request delegate] respondsToSelector:@selector(requestDidStartLoad:)]) {
			[[_request delegate] requestDidStartLoad:_request];
		}
	}
	
	[_payload appendData:data];		
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
	_httpURLResponse = [response retain];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	[connection release];
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

- (NSString*)localizedStatusCodeString {
	return [NSHTTPURLResponse localizedStringForStatusCode:[self statusCode]];
}

- (NSString*)payloadString {
	return [[[NSString alloc] initWithData:_payload encoding:NSUTF8StringEncoding] autorelease];
}

- (DocumentRoot*)payloadXMLDocument {
	return [DocumentRoot parseXML:[self payloadString]];
}

- (NSDictionary*)payloadJSONDictionary {
	return [[[[SBJSON alloc] init] autorelease] objectWithString:[self payloadString]];
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

- (BOOL)isXML {
	return [[self contentType] isEqualToString:@"application/xml"];
}

- (BOOL)isJSON {
	return [[self contentType] isEqualToString:@"application/json"];
}

@end
