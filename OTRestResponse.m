//
//  OTRestResponse.m
//  gateguru
//
//  Created by Blake Watters on 7/28/09.
//  Copyright 2009 Objective 3. All rights reserved.
//

#import "OTRestResponse.h"
#import "OTRestNotifications.h"

@implementation OTRestResponse

@synthesize payload = _payload, request = _request, error = _error;

- (id)init {
	if (self = [super init]) {
		_payload = [[NSMutableData alloc] init];
		_error = nil;
	}
	
	return self;
}
- (id)initWithRestRequest:(OTRestRequest*)request {
	if (self = [self init]) {
		_request = [request retain];
	}
	
	return self;
}

- (void)dealloc {
	[_httpURLResponse release];
	[_payload release];
	[_request release];
	[_error release];
	[super dealloc];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[_payload appendData:data];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
	_httpURLResponse = [response retain];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	[connection release];
	NSDate* receivedAt = [NSDate date];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObjectsAndKeys:[_request HTTPMethod], @"HTTPMethod", [_request URL], @"URL", receivedAt, @"receivedAt", nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:kOTRestResponseReceivedNotification object:self userInfo:userInfo];
	[[_request delegate] performSelector:[_request callback] withObject:self];	
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	_error = [error retain];
	[[_request delegate] performSelector:[_request callback] withObject:self];
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

- (NSString*)errorDescription {
	NSString* desc;
	if (_error != nil) {
		desc = [_error localizedDescription];
	} else {
		NSString* contentsText = [[(Element*)[self payloadXMLDocument] selectElement:@"error"] contentsText];
		if (contentsText == nil) {
			contentsText = @"";
		}
		desc = [NSString stringWithFormat:@"#%d  %@", [self statusCode], contentsText];
	}
	return desc;
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

@end
