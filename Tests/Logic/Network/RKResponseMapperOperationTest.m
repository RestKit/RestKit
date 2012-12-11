//
//  RKResponseMapperOperationTest.m
//  RestKit
//
//  Created by Blake Watters on 10/5/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKResponseMapperOperation.h"
#import "RKErrorMessage.h"
#import "RKMappingErrors.h"
#import "RKTestUser.h"

NSString *RKPathAndQueryStringFromURLRelativeToURL(NSURL *URL, NSURL *baseURL);

@interface RKObjectResponseMapperOperationTest : RKTestCase

@end

@implementation RKObjectResponseMapperOperationTest

#pragma mark - Successful Empty Responses

- (void)testMappingResponseDataThatIsASingleSpace
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping pathPattern:nil keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    NSURL *URL = [NSURL URLWithString:@"http://restkit.org"];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:200 HTTPVersion:@"1.1" headerFields:nil];
    NSData *data = [@" " dataUsingEncoding:NSUTF8StringEncoding];
    RKObjectResponseMapperOperation *mapper = [[RKObjectResponseMapperOperation alloc] initWithResponse:response data:data responseDescriptors:@[responseDescriptor]];
    mapper.treatsEmptyResponseAsSuccess = YES;
    [mapper start];
    expect(mapper.error).to.beNil();
}

- (void)testMappingAZeroLengthDataIsSucessful
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping pathPattern:nil keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    NSURL *URL = [NSURL URLWithString:@"http://restkit.org"];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:200 HTTPVersion:@"1.1" headerFields:nil];
    NSData *data = [@"" dataUsingEncoding:NSUTF8StringEncoding];
    RKObjectResponseMapperOperation *mapper = [[RKObjectResponseMapperOperation alloc] initWithResponse:response data:data responseDescriptors:@[responseDescriptor]];
    mapper.treatsEmptyResponseAsSuccess = YES;
    [mapper start];
    expect(mapper.error).to.beNil();
}

- (void)testMappingANilDataIsSucessful
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping pathPattern:nil keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    NSURL *URL = [NSURL URLWithString:@"http://restkit.org"];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:200 HTTPVersion:@"1.1" headerFields:nil];
    RKObjectResponseMapperOperation *mapper = [[RKObjectResponseMapperOperation alloc] initWithResponse:response data:nil responseDescriptors:@[responseDescriptor]];
    mapper.treatsEmptyResponseAsSuccess = YES;
    [mapper start];
    expect(mapper.error).to.beNil();
}

#pragma mark - Error Status Codes

// 422, no content
- (void)testThatMappingZeroLengthClientErrorResponseReturnsError
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping pathPattern:nil keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    NSURL *URL = [NSURL URLWithString:@"http://restkit.org"];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:422 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/json"}];
    NSData *data = [@"" dataUsingEncoding:NSUTF8StringEncoding];
    RKObjectResponseMapperOperation *mapper = [[RKObjectResponseMapperOperation alloc] initWithResponse:response data:data responseDescriptors:@[responseDescriptor]];
    [mapper start];
    expect(mapper.error).notTo.beNil();
    expect(mapper.error.code).to.equal(NSURLErrorBadServerResponse);
    expect([mapper.error localizedDescription]).to.equal(@"Loaded an unprocessable client error response (422)");
}

// 422, with mappable error payload
- (void)testThatMappingMappableErrorPayloadClientErrorResponseReturnsError
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKErrorMessage class]];
    [mapping addAttributeMappingsFromDictionary:@{@"message": @"errorMessage"}];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping pathPattern:nil keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:422]];
    NSURL *URL = [NSURL URLWithString:@"http://restkit.org"];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:422 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/json"}];
    NSData *data = [@"{\"message\": \"Failure\"}" dataUsingEncoding:NSUTF8StringEncoding];
    RKObjectResponseMapperOperation *mapper = [[RKObjectResponseMapperOperation alloc] initWithResponse:response data:data responseDescriptors:@[responseDescriptor]];
    [mapper start];
    expect(mapper.error).notTo.beNil();
    expect(mapper.error.code).to.equal(RKMappingErrorFromMappingResult);
    expect([mapper.error localizedDescription]).to.equal(@"Failure");
}

// 422, empty JSON dictionary
- (void)testThatMappingEmptyJSONDictionaryClientErrorResponseReturnsError
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping pathPattern:nil keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    NSURL *URL = [NSURL URLWithString:@"http://restkit.org"];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:422 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/json"}];
    NSData *data = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];
    RKObjectResponseMapperOperation *mapper = [[RKObjectResponseMapperOperation alloc] initWithResponse:response data:data responseDescriptors:@[responseDescriptor]];
    [mapper start];
    expect(mapper.error).notTo.beNil();
    expect(mapper.error.code).to.equal(NSURLErrorBadServerResponse);
    expect([mapper.error localizedDescription]).to.equal(@"Loaded an unprocessable client error response (422)");
}

// 422, empty JSON dictionary, no response descriptors
- (void)testThatMappingEmptyJSONDictionaryClientErrorResponseReturnsErrorNoDescriptors
{
    NSURL *URL = [NSURL URLWithString:@"http://restkit.org"];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:422 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/json"}];
    NSData *data = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];
    RKObjectResponseMapperOperation *mapper = [[RKObjectResponseMapperOperation alloc] initWithResponse:response data:data responseDescriptors:@[]];
    [mapper start];
    expect(mapper.error).notTo.beNil();
    expect(mapper.error.code).to.equal(NSURLErrorBadServerResponse);
    expect([mapper.error localizedDescription]).to.equal(@"Loaded an unprocessable client error response (422)");
}

#pragma mark - Response Descriptor Matching

- (void)testThatResponseMapperMatchesBaseURLWithoutPathAppropriately
{
    NSURL *baseURL = [NSURL URLWithString:@"http://restkit.org"];
    NSURL *responseURL = [NSURL URLWithString:@"http://restkit.org/api/v1/organizations/"];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:responseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/json"}];
    NSData *data = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];

    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping pathPattern:@"/api/v1/organizations/" keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    responseDescriptor.baseURL = baseURL;
    RKObjectResponseMapperOperation *mapper = [[RKObjectResponseMapperOperation alloc] initWithResponse:response data:data responseDescriptors:@[responseDescriptor]];
    [mapper start];
    expect(mapper.error).to.beNil();

    NSDictionary *expectedMappingsDictionary = @{ [NSNull null] : mapping };
    expect(mapper.responseMappingsDictionary).to.equal(expectedMappingsDictionary);
}

- (void)testThatResponseMapperMatchesBaseURLWithJustASingleSlashAsThePathAppropriately
{
    NSURL *baseURL = [NSURL URLWithString:@"http://restkit.org/"];
    NSURL *responseURL = [NSURL URLWithString:@"http://restkit.org/api/v1/organizations/"];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:responseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/json"}];
    NSData *data = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];

    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping pathPattern:@"api/v1/organizations/" keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    responseDescriptor.baseURL = baseURL;
    RKObjectResponseMapperOperation *mapper = [[RKObjectResponseMapperOperation alloc] initWithResponse:response data:data responseDescriptors:@[responseDescriptor]];
    [mapper start];
    expect(mapper.error).to.beNil();

    NSDictionary *expectedMappingsDictionary = @{ [NSNull null] : mapping };
    expect(mapper.responseMappingsDictionary).to.equal(expectedMappingsDictionary);
}

- (void)testThatResponseMapperMatchesBaseURLWithPathWithoutATrailingSlashAppropriately
{
    NSURL *baseURL = [NSURL URLWithString:@"http://restkit.org/api/v1"];
    NSURL *responseURL = [NSURL URLWithString:@"http://restkit.org/api/v1/organizations/"];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:responseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/json"}];
    NSData *data = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];

    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping pathPattern:@"/organizations/" keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    responseDescriptor.baseURL = baseURL;
    RKObjectResponseMapperOperation *mapper = [[RKObjectResponseMapperOperation alloc] initWithResponse:response data:data responseDescriptors:@[responseDescriptor]];
    [mapper start];
    expect(mapper.error).to.beNil();

    NSDictionary *expectedMappingsDictionary = @{ [NSNull null] : mapping };
    expect(mapper.responseMappingsDictionary).to.equal(expectedMappingsDictionary);
}

- (void)testThatResponseMapperMatchesBaseURLWithPathWithATrailingSlashAppropriately
{
    NSURL *baseURL = [NSURL URLWithString:@"http://restkit.org/api/v1/"];
    NSURL *responseURL = [NSURL URLWithString:@"http://restkit.org/api/v1/organizations/"];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:responseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/json"}];
    NSData *data = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];

    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping pathPattern:@"organizations/" keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    responseDescriptor.baseURL = baseURL;
    RKObjectResponseMapperOperation *mapper = [[RKObjectResponseMapperOperation alloc] initWithResponse:response data:data responseDescriptors:@[responseDescriptor]];
    [mapper start];
    expect(mapper.error).to.beNil();

    NSDictionary *expectedMappingsDictionary = @{ [NSNull null] : mapping };
    expect(mapper.responseMappingsDictionary).to.equal(expectedMappingsDictionary);
}

- (void)testThatResponseMapperMatchesBaseURLWithPathAndQueryParametersAppropriately
{
    NSURL *baseURL = [NSURL URLWithString:@"http://restkit.org/api/v1/"];
    NSURL *responseURL = [NSURL URLWithString:@"http://restkit.org/api/v1/organizations/?client_search=s"];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:responseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/json"}];
    NSData *data = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];

    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping pathPattern:@"organizations/" keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    responseDescriptor.baseURL = baseURL;
    RKObjectResponseMapperOperation *mapper = [[RKObjectResponseMapperOperation alloc] initWithResponse:response data:data responseDescriptors:@[responseDescriptor]];
    [mapper start];
    expect(mapper.error).to.beNil();

    NSDictionary *expectedMappingsDictionary = @{ [NSNull null] : mapping };
    expect(mapper.responseMappingsDictionary).to.equal(expectedMappingsDictionary);
}

- (void)testThatResponseDescriptorMismatchesIncludeHelpfulError
{
    NSURL *responseURL = [NSURL URLWithString:@"http://restkit.org/api/v1/users"];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:responseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/json"}];
    NSData *data = [@"{\"some\": \"Data\"}" dataUsingEncoding:NSUTF8StringEncoding];
    NSURL *baseURL =  [NSURL URLWithString:@"http://restkit.org/api/v1/"];
    
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKResponseDescriptor *responseDescriptor1 = [RKResponseDescriptor responseDescriptorWithMapping:mapping pathPattern:@"/users" keyPath:@"this" statusCodes:[NSIndexSet indexSetWithIndex:200]];
    responseDescriptor1.baseURL = baseURL;
    RKResponseDescriptor *responseDescriptor2 = [RKResponseDescriptor responseDescriptorWithMapping:mapping pathPattern:@"/users" keyPath:@"that" statusCodes:[NSIndexSet indexSetWithIndex:200]];
    responseDescriptor2.baseURL = [NSURL URLWithString:@"http://google.com"];
    RKResponseDescriptor *responseDescriptor3 = [RKResponseDescriptor responseDescriptorWithMapping:mapping pathPattern:@"users" keyPath:@"that" statusCodes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(202, 5)]];
    responseDescriptor3.baseURL = baseURL;
    
    RKObjectResponseMapperOperation *mapper = [[RKObjectResponseMapperOperation alloc] initWithResponse:response data:data responseDescriptors:@[ responseDescriptor1, responseDescriptor2, responseDescriptor3 ]];
    [mapper start];
    expect(mapper.error).notTo.beNil();
    expect([mapper.error code]).to.equal(RKMappingErrorNotFound);
    NSString *failureReason = [[mapper.error userInfo] valueForKey:NSLocalizedFailureReasonErrorKey];
    assertThat(failureReason, containsString(@"A 200 response was loaded from the URL 'http://restkit.org/api/v1/users', which failed to match all (3) response descriptors"));
    assertThat(failureReason, containsString(@"failed to match: response path 'users' did not match the path pattern '/users'."));
    assertThat(failureReason, containsString(@"failed to match: response URL 'http://restkit.org/api/v1/users' is not relative to the baseURL 'http://google.com'."));
    assertThat(failureReason, containsString(@"failed to match: response status code 200 is not within the range 202-206"));
    
    NSDictionary *expectedMappingsDictionary = @{};
    expect(mapper.responseMappingsDictionary).to.equal(expectedMappingsDictionary);
}

#pragma mark -

- (void)testThatObjectResponseMapperOperationDoesNotMapWithTargetObjectForUnsuccessfulResponseStatusCode
{
    NSURL *responseURL = [NSURL URLWithString:@"http://restkit.org/api/v1/users"];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:responseURL statusCode:422 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/json"}];
    NSData *data = [@"{\"name\": \"Blake\"}" dataUsingEncoding:NSUTF8StringEncoding];
    
    RKTestUser *testUser = [RKTestUser new];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping addAttributeMappingsFromArray:@[ @"name" ]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping pathPattern:nil keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    RKObjectMapping *errorMapping = [RKObjectMapping mappingForClass:[RKErrorMessage class]];
    RKResponseDescriptor *errorDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:errorMapping pathPattern:nil keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:422]];
    
    RKObjectResponseMapperOperation *mapper = [[RKObjectResponseMapperOperation alloc] initWithResponse:response data:data responseDescriptors:@[ responseDescriptor, errorDescriptor ]];
    mapper.targetObject = testUser;
    [mapper start];
    expect(mapper.error).notTo.beNil();
    expect([mapper.error code]).notTo.equal(RKMappingErrorTypeMismatch);
}

@end
