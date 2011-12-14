//
//  RKResponse.m
//  RestKit
//
//  Created by Blake Watters on 7/28/09.
//  Copyright 2009 RestKit
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//  http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "RKResponse.h"
#import "RKNotifications.h"
#import "RKLog.h"
#import "RKParserRegistry.h"
#import "RKClient.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitNetwork

extern NSString* cacheResponseCodeKey;
extern NSString* cacheMIMETypeKey;
extern NSString* cacheURLKey;

@implementation RKResponse

@synthesize body = _body, request = _request, failureError = _failureError;

- (id)init {
    self = [super init];
	if (self) {
		_body = [[NSMutableData alloc] init];
		_failureError = nil;
		_loading = NO;
		_responseHeaders = nil;
	}

	return self;
}

- (id)initWithRequest:(RKRequest*)request {
    self = [self init];
	if (self) {
		_request = [request retain];
	}

	return self;
}

- (id)initWithRequest:(RKRequest*)request body:(NSData*)body headers:(NSDictionary*)headers {
	self = [self initWithRequest:request];
	if (self) {
		[_body release];
        _body = [[NSMutableData dataWithData:body] retain];
		_responseHeaders = [headers retain];
	}

	return self;
}

- (id)initWithSynchronousRequest:(RKRequest*)request URLResponse:(NSHTTPURLResponse*)URLResponse body:(NSData*)body error:(NSError*)error {
    self = [super init];
	if (self) {
		_request = [request retain];
		_httpURLResponse = [URLResponse retain];
		_failureError = [error retain];
        _body = [[NSMutableData dataWithData:body] retain];
		_loading = NO;
	}

	return self;
}

- (void)dealloc {
	[_request release];
	_request = nil;
	[_httpURLResponse release];
	_httpURLResponse = nil;
	[_body release];
	_body = nil;
	[_failureError release];
	_failureError = nil;
	[_responseHeaders release];
	_responseHeaders = nil;
	[super dealloc];
}

- (BOOL)hasCredentials {
    return _request.username && _request.password;
}

- (BOOL)isServerTrusted:(SecTrustRef)trust {
    RKClient* client = [RKClient sharedClient];
    BOOL proceed = NO;
    
    if (client.disableCertificateValidation) {
        proceed = YES;
    } else if( [client.additionalRootCertificates count] > 0 ) {
        CFArrayRef rootCerts = (CFArrayRef)[client.additionalRootCertificates allObjects];
        SecTrustResultType result;
        OSStatus returnCode;
        
        if (rootCerts && CFArrayGetCount(rootCerts)) {
            // this could fail, but the trust evaluation will proceed (it's likely to fail, of course)
            SecTrustSetAnchorCertificates(trust, rootCerts);
        }
        
        returnCode = SecTrustEvaluate(trust, &result);
        
        if (returnCode == errSecSuccess) {
            proceed = (result == kSecTrustResultProceed || result == kSecTrustResultConfirm || result == kSecTrustResultUnspecified);
            if (result == kSecTrustResultRecoverableTrustFailure) {
                // TODO: should try to recover here
                // call SecTrustGetCssmResult() for more information about the failure
            }
        }
    }
    
    return proceed;
}

// Handle basic auth & SSL certificate validation
- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    RKLogDebug(@"Received authentication challenge");
    
	if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
		SecTrustRef trust = [[challenge protectionSpace] serverTrust];
		if ([self isServerTrusted:trust]) {
			[challenge.sender useCredential:[NSURLCredential credentialForTrust:trust] forAuthenticationChallenge:challenge];
		} else {
			[[challenge sender] cancelAuthenticationChallenge:challenge];
		}
		return;
	}
	
	if ([challenge previousFailureCount] == 0) {
		NSURLCredential *newCredential;
		newCredential=[NSURLCredential credentialWithUser:[NSString stringWithFormat:@"%@", _request.username]
		                                         password:[NSString stringWithFormat:@"%@", _request.password]
                                              persistence:NSURLCredentialPersistenceNone];
		[[challenge sender] useCredential:newCredential
		       forAuthenticationChallenge:challenge];
	} else {
	    RKLogWarning(@"Failed authentication challenge after %ld failures", (long) [challenge previousFailureCount]);		
        if ([[_request delegate] respondsToSelector:@selector(request:didFailAuthenticationChallenge:)]) {
            [[_request delegate] request:_request didFailAuthenticationChallenge:challenge];
 		}
        [[challenge sender] cancelAuthenticationChallenge:challenge];
	}
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)space {
    RKLogDebug(@"Asked if canAuthenticateAgainstProtectionSpace: with authenticationMethod = %@", [space authenticationMethod]);
	if ([[space authenticationMethod] isEqualToString:NSURLAuthenticationMethodServerTrust]) {
		// server is using an SSL certificate that the OS can't validate
		// see whether the client settings allow validation here
		RKClient* client = [RKClient sharedClient];
		if (client.disableCertificateValidation || [client.additionalRootCertificates count] > 0) {
			return YES;
		} else { 
			return NO;
		} 
	}
	
    // Handle non-SSL challenges
    BOOL hasCredentials = [self hasCredentials];
    if (! hasCredentials) {
        RKLogWarning(@"Received an authentication challenge without any credentials to satisfy the request.");
    }
    
    return hasCredentials;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[_body appendData:data];
    if ([[_request delegate] respondsToSelector:@selector(request:didReceivedData:totalBytesReceived:totalBytesExectedToReceive:)]) {
        [[_request delegate] request:_request didReceivedData:[data length] totalBytesReceived:[_body length] totalBytesExectedToReceive:_httpURLResponse.expectedContentLength];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {	
    RKLogDebug(@"NSHTTPURLResponse Status Code: %ld", (long) [response statusCode]);
    RKLogDebug(@"Headers: %@", [response allHeaderFields]);
	_httpURLResponse = [response retain];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	RKLogTrace(@"Read response body: %@", [self bodyAsString]);
	[_request didFinishLoad:self];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	_failureError = [error retain];
	[_request didFailLoadWithError:_failureError];
}

- (NSInputStream *)connection:(NSURLConnection *)connection needNewBodyStream:(NSURLRequest *)request {
    RKLogWarning(@"RestKit was asked to retransmit a new body stream for a request. Possible connection error or authentication challenge?");
    return nil;
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

- (NSData *)body {
	return _body;
}

- (NSString *)bodyEncodingName {
    return [_httpURLResponse textEncodingName];    
}

- (NSStringEncoding)bodyEncoding {
    CFStringEncoding cfEncoding = kCFStringEncodingInvalidId;    
    NSString *textEncodingName = [self bodyEncodingName];
    if (textEncodingName) {
        cfEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef) textEncodingName);
    }
    return (cfEncoding ==  kCFStringEncodingInvalidId) ? NSUTF8StringEncoding : CFStringConvertEncodingToNSStringEncoding(cfEncoding);
}

- (NSString *)bodyAsString {
	return [[[NSString alloc] initWithData:self.body encoding:[self bodyEncoding]] autorelease];
}

- (id)bodyAsJSON {
    [NSException raise:nil format:@"Reimplemented as parsedBody"];
    return nil;
}

- (id)parsedBody:(NSError**)error {
    id<RKParser> parser = [[RKParserRegistry sharedRegistry] parserForMIMEType:[self MIMEType]];
    if (! parser) {
        RKLogWarning(@"Unable to parse response body: no parser registered for MIME Type '%@'", [self MIMEType]);
        return nil;
    }
    id object = [parser objectFromString:[self bodyAsString] error:error];
    if (object == nil) {
        if (error && *error) {
            RKLogError(@"Unable to parse response body: %@", [*error localizedDescription]);
        }
        return nil;
    }
    return object;
}

- (NSString*)failureErrorDescription {
	if ([self isFailure]) {
		return [_failureError localizedDescription];
	} else {
		return nil;
	}
}

- (BOOL)wasLoadedFromCache {
	return (_responseHeaders != nil);
}

- (NSURL*)URL {
    if ([self wasLoadedFromCache]) {
        return [NSURL URLWithString:[_responseHeaders valueForKey:cacheURLKey]];
    }
	return [_httpURLResponse URL];
}

- (NSString*)MIMEType {
    if ([self wasLoadedFromCache]) {
        return [_responseHeaders valueForKey:cacheMIMETypeKey];
    }
	return [_httpURLResponse MIMEType];
}

- (NSInteger)statusCode {
    if ([self wasLoadedFromCache]) {
        return [[_responseHeaders valueForKey:cacheResponseCodeKey] intValue];
    }
    return ([_httpURLResponse respondsToSelector:@selector(statusCode)] ? [_httpURLResponse statusCode] : 200);
}

- (NSDictionary*)allHeaderFields {
	if ([self wasLoadedFromCache]) {
		return _responseHeaders;
	}
    return ([_httpURLResponse respondsToSelector:@selector(allHeaderFields)] ? [_httpURLResponse allHeaderFields] : nil);
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
	return (([self statusCode] >= 200 && [self statusCode] < 300) || ([self wasLoadedFromCache]));
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

- (BOOL)isNoContent {
	return ([self statusCode] == 204);
}

- (BOOL)isNotModified {
	return ([self statusCode] == 304);
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

- (BOOL)isConflict {
    return ([self statusCode] == 409);
}

- (BOOL)isGone {
    return ([self statusCode] == 410);
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
	return (contentType && ([contentType rangeOfString:@"text/html"
											   options:NSCaseInsensitiveSearch|NSAnchoredSearch].length > 0 ||
						   [self isXHTML]));
}

- (BOOL)isXHTML {
	NSString* contentType = [self contentType];
	return (contentType &&
			[contentType rangeOfString:@"application/xhtml+xml"
							   options:NSCaseInsensitiveSearch|NSAnchoredSearch].length > 0);
}

- (BOOL)isXML {
	NSString* contentType = [self contentType];
	return (contentType &&
			[contentType rangeOfString:@"application/xml"
							   options:NSCaseInsensitiveSearch|NSAnchoredSearch].length > 0);
}

- (BOOL)isJSON {
	NSString* contentType = [self contentType];
	return (contentType &&
			[contentType rangeOfString:@"application/json"
							   options:NSCaseInsensitiveSearch|NSAnchoredSearch].length > 0);
}

@end
