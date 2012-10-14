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

@end
