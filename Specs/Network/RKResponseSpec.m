//
//  RKResponseSpec.m
//  RestKit
//
//  Created by Blake Watters on 1/15/10.
//  Copyright 2010 Two Toasters
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

#import "RKSpecEnvironment.h"
#import "RKResponse.h"

@interface RKResponseSpec : RKSpec {
	RKResponse* _response;
}

@end

@implementation RKResponseSpec

- (void)before {
	_response = [[RKResponse alloc] init];
}

- (void)itShouldConsiderResponsesLessThanOneHudredOrGreaterThanSixHundredInvalid {
	RKResponse* response = [[[RKResponse alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:response];
	NSInteger statusCode = 99;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
	[expectThat([mock isInvalid]) should:be(YES)];
	statusCode = 601;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
	[expectThat([mock isInvalid]) should:be(YES)];
}

- (void)itShouldConsiderResponsesInTheOneHudredsInformational {
	RKResponse* response = [[[RKResponse alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:response];
	NSInteger statusCode = 100;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
	[expectThat([mock isInformational]) should:be(YES)];
	statusCode = 199;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
	[expectThat([mock isInformational]) should:be(YES)];
}

- (void)itShouldConsiderResponsesInTheTwoHundredsSuccessful {
	RKResponse* response = [[[RKResponse alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:response];
	NSInteger twoHundred = 200;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(twoHundred)] statusCode];
	[expectThat([mock isSuccessful]) should:be(YES)];
	twoHundred = 299;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(twoHundred)] statusCode];
	[expectThat([mock isSuccessful]) should:be(YES)];
}

- (void)itShouldConsiderResponsesInTheThreeHundredsRedirects {
	RKResponse* response = [[[RKResponse alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:response];
	NSInteger statusCode = 300;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
	[expectThat([mock isRedirection]) should:be(YES)];
	statusCode = 399;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
	[expectThat([mock isRedirection]) should:be(YES)];
}

- (void)itShouldConsiderResponsesInTheFourHundredsClientErrors {
	RKResponse* response = [[[RKResponse alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:response];
	NSInteger statusCode = 400;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
	[expectThat([mock isClientError]) should:be(YES)];
	statusCode = 499;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
	[expectThat([mock isClientError]) should:be(YES)];
}

- (void)itShouldConsiderResponsesInTheFiveHundredsServerErrors {
	RKResponse* response = [[[RKResponse alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:response];
	NSInteger statusCode = 500;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
	[expectThat([mock isServerError]) should:be(YES)];
	statusCode = 599;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
	[expectThat([mock isServerError]) should:be(YES)];
}

- (void)itShouldConsiderATwoHundredResponseOK {
	RKResponse* response = [[[RKResponse alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:response];
	NSInteger statusCode = 200;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
	[expectThat([mock isOK]) should:be(YES)];
}

- (void)itShouldConsiderATwoHundredAndOneResponseCreated {
	RKResponse* response = [[[RKResponse alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:response];
	NSInteger statusCode = 201;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
	[expectThat([mock isCreated]) should:be(YES)];
}

- (void)itShouldConsiderAFourOhThreeResponseForbidden {
	RKResponse* response = [[[RKResponse alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:response];
	NSInteger statusCode = 403;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
	[expectThat([mock isForbidden]) should:be(YES)];
}

- (void)itShouldConsiderAFourOhFourResponseNotFound {
	RKResponse* response = [[[RKResponse alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:response];
	NSInteger statusCode = 404;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
	[expectThat([mock isNotFound]) should:be(YES)];
}

- (void)itShouldConsiderAFourOhNineResponseConflict {
	RKResponse* response = [[[RKResponse alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:response];
	NSInteger statusCode = 409;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
	[expectThat([mock isConflict]) should:be(YES)];
}

- (void)itShouldConsiderAFourHundredAndTenResponseConflict {
	RKResponse* response = [[[RKResponse alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:response];
	NSInteger statusCode = 410;
	[[[mock stub] andReturnValue:OCMOCK_VALUE(statusCode)] statusCode];
	[expectThat([mock isGone]) should:be(YES)];
}

- (void)itShouldConsiderVariousThreeHundredResponsesRedirect {
	RKResponse* response = [[[RKResponse alloc] init] autorelease];
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
	RKResponse* response = [[[RKResponse alloc] init] autorelease];
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
	RKResponse* response = [[[RKResponse alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:response];
	NSDictionary* headers = [NSDictionary dictionaryWithObject:@"application/xml" forKey:@"Content-Type"];
	[[[mock stub] andReturn:headers] allHeaderFields];
	[expectThat([mock contentType]) should:be(@"application/xml")];
}

// Should this return a string???
- (void)itShouldMakeTheContentLengthHeaderAccessible {
	RKResponse* response = [[[RKResponse alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:response];
	NSDictionary* headers = [NSDictionary dictionaryWithObject:@"12345" forKey:@"Content-Length"];
	[[[mock stub] andReturn:headers] allHeaderFields];
	[expectThat([mock contentLength]) should:be(@"12345")];
}

- (void)itShouldMakeTheLocationHeaderAccessible {
	RKResponse* response = [[[RKResponse alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:response];
	NSDictionary* headers = [NSDictionary dictionaryWithObject:@"/foo/bar" forKey:@"Location"];
	[[[mock stub] andReturn:headers] allHeaderFields];
	[expectThat([mock location]) should:be(@"/foo/bar")];
}

- (void)itShouldKnowIfItIsAnXMLResponse {
	RKResponse* response = [[[RKResponse alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:response];
	NSDictionary* headers = [NSDictionary dictionaryWithObject:@"application/xml" forKey:@"Content-Type"];
	[[[mock stub] andReturn:headers] allHeaderFields];
	[expectThat([mock isXML]) should:be(YES)];
}

- (void)itShouldKnowIfItIsAnJSONResponse {
	RKResponse* response = [[[RKResponse alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:response];
	NSDictionary* headers = [NSDictionary dictionaryWithObject:@"application/json" forKey:@"Content-Type"];
	[[[mock stub] andReturn:headers] allHeaderFields];
	[expectThat([mock isJSON]) should:be(YES)];
}

- (void)itShouldReturnParseErrorsWhenParsedBodyFails {
    RKResponse* response = [[[RKResponse alloc] init] autorelease];
	id mock = [OCMockObject partialMockForObject:response];
	[[[mock stub] andReturn:@"sad;sdvjnk;"] bodyAsString];
    [[[mock stub] andReturn:@"application/json"] MIMEType];
    NSError* error = nil;
    id object = [mock parsedBody:&error];
    assertThat(object, is(nilValue()));
    assertThat(error, isNot(nilValue()));
    assertThat([error localizedDescription], is(equalTo(@"Unexpected token, wanted '{', '}', '[', ']', ',', ':', 'true', 'false', 'null', '\"STRING\"', 'NUMBER'.")));
}

@end
