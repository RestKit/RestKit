//
//  OTRestResponseSpec.m
//  OTRestFramework
//
//  Created by Blake Watters on 1/15/10.
//  Copyright 2010 Objective 3. All rights reserved.
//

#import "OTRestSpecEnvironment.h"
#import "OTRestResponse.h"

@interface OTRestResponseSpec : NSObject <UISpec> {
	OTRestResponse* _response;
}

@end

@implementation OTRestResponseSpec

- (void)before {
	_response = [[OTRestResponse alloc] init];
}

- (void)itShouldConsiderResponsesLessThanOneHudredOrGreaterThanSixHundredInvalid {
	OTRestResponse* response = [[[OTRestResponse alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:response];
	NSInteger statusCode = 99;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
	[expectThat([mock isInvalid]) should:be(YES)];
	statusCode = 601;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
	[expectThat([mock isInvalid]) should:be(YES)];
}

- (void)itShouldConsiderResponsesInTheOneHudredsInformational {
	OTRestResponse* response = [[[OTRestResponse alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:response];
	NSInteger statusCode = 100;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
	[expectThat([mock isInformational]) should:be(YES)];
	statusCode = 199;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
	[expectThat([mock isInformational]) should:be(YES)];
}

- (void)itShouldConsiderResponsesInTheTwoHundredsSuccessful {
	OTRestResponse* response = [[[OTRestResponse alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:response];
	NSInteger twoHundred = 200;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(twoHundred)] statusCode];
	[expectThat([mock isSuccessful]) should:be(YES)];
	twoHundred = 299;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(twoHundred)] statusCode];
	[expectThat([mock isSuccessful]) should:be(YES)];
}

- (void)itShouldConsiderResponsesInTheThreeHundredsRedirects {
	OTRestResponse* response = [[[OTRestResponse alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:response];
	NSInteger statusCode = 300;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
	[expectThat([mock isRedirection]) should:be(YES)];
	statusCode = 399;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
	[expectThat([mock isRedirection]) should:be(YES)];
}

- (void)itShouldConsiderResponsesInTheFourHundredsClientErrors {
	OTRestResponse* response = [[[OTRestResponse alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:response];
	NSInteger statusCode = 400;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
	[expectThat([mock isClientError]) should:be(YES)];
	statusCode = 499;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
	[expectThat([mock isClientError]) should:be(YES)];
}

- (void)itShouldConsiderResponsesInTheFiveHundredsServerErrors {
	OTRestResponse* response = [[[OTRestResponse alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:response];
	NSInteger statusCode = 500;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
	[expectThat([mock isServerError]) should:be(YES)];
	statusCode = 599;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
	[expectThat([mock isServerError]) should:be(YES)];
}

- (void)itShouldConsiderATwoHundredResponseOK {
	OTRestResponse* response = [[[OTRestResponse alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:response];
	NSInteger statusCode = 200;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
	[expectThat([mock isOK]) should:be(YES)];
}

- (void)itShouldConsiderATwoHundredAndOneResponseCreated {
	OTRestResponse* response = [[[OTRestResponse alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:response];
	NSInteger statusCode = 201;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
	[expectThat([mock isCreated]) should:be(YES)];
}

- (void)itShouldConsiderAFourOhThreeResponseForbidden {
	OTRestResponse* response = [[[OTRestResponse alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:response];
	NSInteger statusCode = 403;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
	[expectThat([mock isForbidden]) should:be(YES)];
}

- (void)itShouldConsiderAFourOhFourResponseNotFound {
	OTRestResponse* response = [[[OTRestResponse alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:response];
	NSInteger statusCode = 404;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
	[expectThat([mock isNotFound]) should:be(YES)];
}

- (void)itShouldConsiderVariousThreeHundredResponsesRedirect {
	OTRestResponse* response = [[[OTRestResponse alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:response];
	NSInteger statusCode = 301;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
	[expectThat([mock isRedirect]) should:be(YES)];
	statusCode = 302;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
	[expectThat([mock isRedirect]) should:be(YES)];
	statusCode = 303;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
	[expectThat([mock isRedirect]) should:be(YES)];
	statusCode = 307;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
	[expectThat([mock isRedirect]) should:be(YES)];
}

- (void)itShouldConsiderVariousResponsesEmpty {
	OTRestResponse* response = [[[OTRestResponse alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:response];
	NSInteger statusCode = 201;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
	[expectThat([mock isEmpty]) should:be(YES)];
	statusCode = 204;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
	[expectThat([mock isEmpty]) should:be(YES)];
	statusCode = 304;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
	[expectThat([mock isEmpty]) should:be(YES)];
}

- (void)itShouldMakeTheContentTypeHeaderAccessible {
	OTRestResponse* response = [[[OTRestResponse alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:response];
	NSDictionary* headers = [NSDictionary dictionaryWithObject:@"application/xml" forKey:@"Content-Type"];
	[[[mock stub] andReturn:headers] allHeaderFields];
	[expectThat([mock contentType]) should:be(@"application/xml")];
}

// Should this return a string???
- (void)itShouldMakeTheContentLengthHeaderAccessible {
	OTRestResponse* response = [[[OTRestResponse alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:response];
	NSDictionary* headers = [NSDictionary dictionaryWithObject:@"12345" forKey:@"Content-Length"];
	[[[mock stub] andReturn:headers] allHeaderFields];
	[expectThat([mock contentLength]) should:be(@"12345")];
}

- (void)itShouldMakeTheLocationHeaderAccessible {
	OTRestResponse* response = [[[OTRestResponse alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:response];
	NSDictionary* headers = [NSDictionary dictionaryWithObject:@"/foo/bar" forKey:@"Location"];
	[[[mock stub] andReturn:headers] allHeaderFields];
	[expectThat([mock location]) should:be(@"/foo/bar")];
}

- (void)itShouldKnowIfItIsAnXMLResponse {
	OTRestResponse* response = [[[OTRestResponse alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:response];
	NSDictionary* headers = [NSDictionary dictionaryWithObject:@"application/xml" forKey:@"Content-Type"];
	[[[mock stub] andReturn:headers] allHeaderFields];
	[expectThat([mock isXML]) should:be(YES)];
}

- (void)itShouldKnowIfItIsAnJSONResponse {
	OTRestResponse* response = [[[OTRestResponse alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:response];
	NSDictionary* headers = [NSDictionary dictionaryWithObject:@"application/json" forKey:@"Content-Type"];
	[[[mock stub] andReturn:headers] allHeaderFields];
	[expectThat([mock isJSON]) should:be(YES)];
}

@end
