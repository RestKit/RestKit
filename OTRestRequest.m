//
//  OTRestRequest.m
//  gateguru
//
//  Created by Jeremy Ellison on 7/27/09.
//  Copyright 2009 Objective3. All rights reserved.
//

#import "OTRestRequest.h"
#import "OTRestResponse.h"
#import "NSDictionary+OTRestRequestSerialization.h"

@implementation OTRestRequest

@synthesize URL = _URL, URLRequest = _URLRequest, delegate = _delegate, callback = _callback, additionalHTTPHeaders = _additionalHTTPHeaders,
			params = _params;

+ (OTRestRequest*)requestWithURL:(NSURL*)URL delegate:(id)delegate callback:(SEL)callback {
	OTRestRequest* request = [[OTRestRequest alloc] initWithURL:URL delegate:delegate callback:callback];
	[request autorelease];
	
	return request;
}

- (id)initWithURL:(NSURL*)URL delegate:(id)delegate callback:(SEL)callback {
	if (self = [self init]) {
		_URL = [URL retain];
		_URLRequest = [[NSMutableURLRequest alloc] initWithURL:_URL];
		_delegate = [delegate retain];
		_callback = callback;		
	}
	
	return self;
}

- (void)dealloc {
	[_URL release];
	[_URLRequest release];
	[_delegate release];
	[_params release];
	[_additionalHTTPHeaders release];
	[super dealloc];
}

- (NSString*)HTTPMethod {
	return [_URLRequest HTTPMethod];
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

- (void)send {
	NSString* body = [[NSString alloc] initWithData:[_URLRequest HTTPBody] encoding:NSUTF8StringEncoding];
	NSLog(@"Sending %@ request to URL %@. HTTP Body: %@", [self HTTPMethod], [[self URL] absoluteString], body);
	[body release];
	OTRestResponse* response = [[OTRestResponse alloc] initWithRestRequest:self];
	[[NSURLConnection connectionWithRequest:_URLRequest delegate:response] retain];
}

- (void)get {
	[_URLRequest setHTTPMethod:@"GET"];
	[self addHeadersToRequest];
	[self send];
}

- (void)postParams:(NSObject<OTRestRequestSerializable>*)params {	
	[_URLRequest setHTTPMethod:@"POST"];
	_params = [params retain];
	[_URLRequest setHTTPBody:[_params HTTPBody]];
	[self addHeadersToRequest];	
	[self send];
}

- (void)putParams:(NSObject<OTRestRequestSerializable>*)params {
	[_URLRequest setHTTPMethod:@"PUT"];
	_params = [params retain];
	[_URLRequest setHTTPBody:[_params HTTPBody]];
	[self addHeadersToRequest];	
	[self send];
}

- (void)delete {
	[_URLRequest setHTTPMethod:@"DELETE"];
	[self addHeadersToRequest];
	[self send];
}

@end
