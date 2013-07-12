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

@interface RKServerError : NSObject
@property (nonatomic, copy) NSString *message;
@property (nonatomic, assign) NSInteger code;
@end

@implementation RKServerError

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ (%ld)", self.message, (long) self.code];
}

@end

@interface RKTestObjectMappingOperationDataSource : NSObject <RKMappingOperationDataSource>
@end
@implementation RKTestObjectMappingOperationDataSource

- (id)mappingOperation:(RKMappingOperation *)mappingOperation targetObjectForRepresentation:(NSDictionary *)representation withMapping:(RKObjectMapping *)mapping inRelationship:(RKRelationshipMapping *)relationshipMapping
{
    return nil;
}

@end

@interface RKTestManagedObjectMappingOperationDataSource : RKManagedObjectMappingOperationDataSource
@end
@implementation RKTestManagedObjectMappingOperationDataSource

- (id)mappingOperation:(RKMappingOperation *)mappingOperation targetObjectForRepresentation:(NSDictionary *)representation withMapping:(RKObjectMapping *)mapping inRelationship:(RKRelationshipMapping *)relationshipMapping
{
    return nil;
}

@end

@interface RKObjectResponseMapperOperationTest : RKTestCase
@end

@interface RKResponseMapperOperation ()
@property (nonatomic, strong) RKMapperOperation *mapperOperation; // For testing data source registration
@end

@implementation RKObjectResponseMapperOperationTest

- (void)tearDown
{
    [RKObjectResponseMapperOperation registerMappingOperationDataSourceClass:nil];
    [RKManagedObjectResponseMapperOperation registerMappingOperationDataSourceClass:nil];
}

#pragma mark - Successful Empty Responses

- (void)testMappingResponseDataThatIsASingleSpace
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    NSURL *URL = [NSURL URLWithString:@"http://restkit.org"];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:200 HTTPVersion:@"1.1" headerFields:nil];
    NSData *data = [@" " dataUsingEncoding:NSUTF8StringEncoding];
    RKObjectResponseMapperOperation *mapper = [[RKObjectResponseMapperOperation alloc] initWithRequest:request response:response data:data responseDescriptors:@[responseDescriptor]];
    mapper.treatsEmptyResponseAsSuccess = YES;
    [mapper start];
    expect(mapper.error).to.beNil();
}

- (void)testMappingAZeroLengthDataIsSucessful
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    NSURL *URL = [NSURL URLWithString:@"http://restkit.org"];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:200 HTTPVersion:@"1.1" headerFields:nil];
    NSData *data = [@"" dataUsingEncoding:NSUTF8StringEncoding];
    RKObjectResponseMapperOperation *mapper = [[RKObjectResponseMapperOperation alloc] initWithRequest:request response:response data:data responseDescriptors:@[responseDescriptor]];
    mapper.treatsEmptyResponseAsSuccess = YES;
    [mapper start];
    expect(mapper.error).to.beNil();
}

- (void)testMappingANilDataIsSucessful
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    NSURL *URL = [NSURL URLWithString:@"http://restkit.org"];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:200 HTTPVersion:@"1.1" headerFields:nil];
    RKObjectResponseMapperOperation *mapper = [[RKObjectResponseMapperOperation alloc] initWithRequest:request response:response data:nil responseDescriptors:@[responseDescriptor]];
    mapper.treatsEmptyResponseAsSuccess = YES;
    [mapper start];
    expect(mapper.error).to.beNil();
}

#pragma mark - Error Status Codes

// 422, no content
- (void)testThatMappingZeroLengthClientErrorResponseReturnsError
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    NSURL *URL = [NSURL URLWithString:@"http://restkit.org"];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:422 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/json"}];
    NSData *data = [@"" dataUsingEncoding:NSUTF8StringEncoding];
    RKObjectResponseMapperOperation *mapper = [[RKObjectResponseMapperOperation alloc] initWithRequest:request response:response data:data responseDescriptors:@[responseDescriptor]];
    [mapper start];
    expect(mapper.error).notTo.beNil();
    expect(mapper.error.code).to.equal(NSURLErrorBadServerResponse);
    expect([mapper.error localizedDescription]).to.equal(@"Loaded an unprocessable error response (422)");
}

// 422, with mappable error payload
- (void)testThatMappingMappableErrorPayloadClientErrorResponseReturnsError
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKErrorMessage class]];
    [mapping addAttributeMappingsFromDictionary:@{@"message": @"errorMessage"}];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:422]];
    NSURL *URL = [NSURL URLWithString:@"http://restkit.org"];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:422 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/json"}];
    NSData *data = [@"{\"message\": \"Failure\"}" dataUsingEncoding:NSUTF8StringEncoding];
    RKObjectResponseMapperOperation *mapper = [[RKObjectResponseMapperOperation alloc] initWithRequest:request response:response data:data responseDescriptors:@[responseDescriptor]];
    [mapper start];
    expect(mapper.error).notTo.beNil();
    expect(mapper.error.code).to.equal(RKMappingErrorFromMappingResult);
    expect([mapper.error localizedDescription]).to.equal(@"Failure");
}

// 422, empty JSON dictionary
- (void)testThatMappingEmptyJSONDictionaryClientErrorResponseReturnsError
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    NSURL *URL = [NSURL URLWithString:@"http://restkit.org"];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:422 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/json"}];
    NSData *data = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];
    RKObjectResponseMapperOperation *mapper = [[RKObjectResponseMapperOperation alloc] initWithRequest:request response:response data:data responseDescriptors:@[responseDescriptor]];
    [mapper start];
    expect(mapper.error).notTo.beNil();
    expect(mapper.error.code).to.equal(NSURLErrorBadServerResponse);
    expect([mapper.error localizedDescription]).to.equal(@"Loaded an unprocessable error response (422)");
}

// 422, empty JSON dictionary, no response descriptors
- (void)testThatMappingEmptyJSONDictionaryClientErrorResponseReturnsErrorNoDescriptors
{
    NSURL *URL = [NSURL URLWithString:@"http://restkit.org"];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:422 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/json"}];
    NSData *data = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];
    RKObjectResponseMapperOperation *mapper = [[RKObjectResponseMapperOperation alloc] initWithRequest:request response:response data:data responseDescriptors:@[]];
    [mapper start];
    expect(mapper.error).notTo.beNil();
    expect(mapper.error.code).to.equal(NSURLErrorBadServerResponse);
    expect([mapper.error localizedDescription]).to.equal(@"Loaded an unprocessable error response (422)");
}

- (void)testMappingServerErrorToCustomErrorClass
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKServerError class]];
    [mapping addAttributeMappingsFromArray:@[ @"code", @"message" ]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:422]];
    NSURL *URL = [NSURL URLWithString:@"http://restkit.org"];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:URL statusCode:422 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/json"}];
    NSData *data = [@"{\"code\": 12345, \"message\": \"This is the error message\"}" dataUsingEncoding:NSUTF8StringEncoding];
    RKObjectResponseMapperOperation *mapper = [[RKObjectResponseMapperOperation alloc] initWithRequest:request response:response data:data responseDescriptors:@[responseDescriptor]];
    [mapper start];
    expect(mapper.error).notTo.beNil();
    expect(mapper.error.code).to.equal(RKMappingErrorFromMappingResult);
    expect([mapper.error localizedDescription]).to.equal(@"This is the error message (12345)");
}

#pragma mark - Response Descriptor Matching

- (void)testThatResponseMapperMatchesBaseURLWithoutPathAppropriately
{
    NSURL *baseURL = [NSURL URLWithString:@"http://restkit.org"];
    NSURL *responseURL = [NSURL URLWithString:@"http://restkit.org/api/v1/organizations/"];
    NSURLRequest *request = [NSURLRequest requestWithURL:responseURL];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:responseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/json"}];
    NSData *data = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];

    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:@"/api/v1/organizations/" keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    responseDescriptor.baseURL = baseURL;
    RKObjectResponseMapperOperation *mapper = [[RKObjectResponseMapperOperation alloc] initWithRequest:request response:response data:data responseDescriptors:@[responseDescriptor]];
    [mapper start];
    expect(mapper.error).to.beNil();

    NSDictionary *expectedMappingsDictionary = @{ [NSNull null] : mapping };
    expect(mapper.responseMappingsDictionary).to.equal(expectedMappingsDictionary);
}

- (void)testThatResponseMapperMatchesBaseURLWithJustASingleSlashAsThePathAppropriately
{
    NSURL *baseURL = [NSURL URLWithString:@"http://restkit.org/"];
    NSURL *responseURL = [NSURL URLWithString:@"http://restkit.org/api/v1/organizations/"];
    NSURLRequest *request = [NSURLRequest requestWithURL:responseURL];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:responseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/json"}];
    NSData *data = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];

    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:@"api/v1/organizations/" keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    responseDescriptor.baseURL = baseURL;
    RKObjectResponseMapperOperation *mapper = [[RKObjectResponseMapperOperation alloc] initWithRequest:request response:response data:data responseDescriptors:@[responseDescriptor]];
    [mapper start];
    expect(mapper.error).to.beNil();

    NSDictionary *expectedMappingsDictionary = @{ [NSNull null] : mapping };
    expect(mapper.responseMappingsDictionary).to.equal(expectedMappingsDictionary);
}

- (void)testThatResponseMapperMatchesBaseURLWithPathWithoutATrailingSlashAppropriately
{
    NSURL *baseURL = [NSURL URLWithString:@"http://restkit.org/api/v1"];
    NSURL *responseURL = [NSURL URLWithString:@"http://restkit.org/api/v1/organizations/"];
    NSURLRequest *request = [NSURLRequest requestWithURL:responseURL];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:responseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/json"}];
    NSData *data = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];

    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:@"/organizations/" keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    responseDescriptor.baseURL = baseURL;
    RKObjectResponseMapperOperation *mapper = [[RKObjectResponseMapperOperation alloc] initWithRequest:request response:response data:data responseDescriptors:@[responseDescriptor]];
    [mapper start];
    expect(mapper.error).to.beNil();

    NSDictionary *expectedMappingsDictionary = @{ [NSNull null] : mapping };
    expect(mapper.responseMappingsDictionary).to.equal(expectedMappingsDictionary);
}

- (void)testThatResponseMapperMatchesBaseURLWithPathWithATrailingSlashAppropriately
{
    NSURL *baseURL = [NSURL URLWithString:@"http://restkit.org/api/v1/"];
    NSURL *responseURL = [NSURL URLWithString:@"http://restkit.org/api/v1/organizations/"];
    NSURLRequest *request = [NSURLRequest requestWithURL:responseURL];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:responseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/json"}];
    NSData *data = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];

    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:@"organizations/" keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    responseDescriptor.baseURL = baseURL;
    RKObjectResponseMapperOperation *mapper = [[RKObjectResponseMapperOperation alloc] initWithRequest:request response:response data:data responseDescriptors:@[responseDescriptor]];
    [mapper start];
    expect(mapper.error).to.beNil();

    NSDictionary *expectedMappingsDictionary = @{ [NSNull null] : mapping };
    expect(mapper.responseMappingsDictionary).to.equal(expectedMappingsDictionary);
}

- (void)testThatResponseMapperMatchesBaseURLWithPathAndQueryParametersAppropriately
{
    NSURL *baseURL = [NSURL URLWithString:@"http://restkit.org/api/v1/"];
    NSURL *responseURL = [NSURL URLWithString:@"http://restkit.org/api/v1/organizations/?client_search=s"];
    NSURLRequest *request = [NSURLRequest requestWithURL:responseURL];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:responseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/json"}];
    NSData *data = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];

    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:@"organizations/" keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    responseDescriptor.baseURL = baseURL;
    RKObjectResponseMapperOperation *mapper = [[RKObjectResponseMapperOperation alloc] initWithRequest:request response:response data:data responseDescriptors:@[responseDescriptor]];
    [mapper start];
    expect(mapper.error).to.beNil();

    NSDictionary *expectedMappingsDictionary = @{ [NSNull null] : mapping };
    expect(mapper.responseMappingsDictionary).to.equal(expectedMappingsDictionary);
}

- (void)testThatResponseDescriptorMismatchesIncludeHelpfulError
{
    NSURL *responseURL = [NSURL URLWithString:@"http://restkit.org/api/v1/users"];
    NSURLRequest *request = [NSURLRequest requestWithURL:responseURL];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:responseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/json"}];
    NSData *data = [@"{\"some\": \"Data\"}" dataUsingEncoding:NSUTF8StringEncoding];
    NSURL *baseURL =  [NSURL URLWithString:@"http://restkit.org/api/v1/"];
    
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKResponseDescriptor *responseDescriptor1 = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:@"/users" keyPath:@"this" statusCodes:[NSIndexSet indexSetWithIndex:200]];
    responseDescriptor1.baseURL = baseURL;
    RKResponseDescriptor *responseDescriptor2 = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:@"/users" keyPath:@"that" statusCodes:[NSIndexSet indexSetWithIndex:200]];
    responseDescriptor2.baseURL = [NSURL URLWithString:@"http://google.com"];
    RKResponseDescriptor *responseDescriptor3 = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:@"users" keyPath:@"that" statusCodes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(202, 5)]];
    responseDescriptor3.baseURL = baseURL;
    
    RKObjectResponseMapperOperation *mapper = [[RKObjectResponseMapperOperation alloc] initWithRequest:request response:response data:data responseDescriptors:@[ responseDescriptor1, responseDescriptor2, responseDescriptor3 ]];
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

- (void)testThatResponseDescriptorsDoNotMatchTooAggressively
{
    NSURL *responseURL = [NSURL URLWithString:@"http://restkit.org/categories/some-category-name/articles/the-article-name"];
    NSURLRequest *request = [NSURLRequest requestWithURL:responseURL];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:responseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/json"}];
    NSData *data = [@"{\"some\": \"Data\"}" dataUsingEncoding:NSUTF8StringEncoding];
    NSURL *baseURL =  [NSURL URLWithString:@"http://restkit.org"];
    
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKResponseDescriptor *responseDescriptor1 = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:@"/categories" keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    responseDescriptor1.baseURL = baseURL;
    RKResponseDescriptor *responseDescriptor2 = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:@"/categories/:categoryName" keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    responseDescriptor2.baseURL = baseURL;
    RKResponseDescriptor *responseDescriptor3 = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:@"/categories/:categorySlug/articles/:articleSlug" keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    responseDescriptor3.baseURL = baseURL;
    
    RKObjectResponseMapperOperation *mapper = [[RKObjectResponseMapperOperation alloc] initWithRequest:request response:response data:data responseDescriptors:@[ responseDescriptor1, responseDescriptor2, responseDescriptor3 ]];
    [mapper start];
    expect(mapper.matchingResponseDescriptors).to.haveCountOf(1);
    expect(mapper.matchingResponseDescriptors).to.equal(@[ responseDescriptor3 ]);
}

#pragma mark -

- (void)testThatObjectResponseMapperOperationDoesNotMapWithTargetObjectForUnsuccessfulResponseStatusCode
{
    NSURL *responseURL = [NSURL URLWithString:@"http://restkit.org/api/v1/users"];
    NSURLRequest *request = [NSURLRequest requestWithURL:responseURL];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:responseURL statusCode:422 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/json"}];
    NSData *data = [@"{\"name\": \"Blake\"}" dataUsingEncoding:NSUTF8StringEncoding];
    
    RKTestUser *testUser = [RKTestUser new];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping addAttributeMappingsFromArray:@[ @"name" ]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    RKObjectMapping *errorMapping = [RKObjectMapping mappingForClass:[RKErrorMessage class]];
    RKResponseDescriptor *errorDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:errorMapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:422]];
    
    RKObjectResponseMapperOperation *mapper = [[RKObjectResponseMapperOperation alloc] initWithRequest:request response:response data:data responseDescriptors:@[ responseDescriptor, errorDescriptor ]];
    mapper.targetObject = testUser;
    [mapper start];
    expect(mapper.error).notTo.beNil();
    expect([mapper.error code]).notTo.equal(RKMappingErrorTypeMismatch);
}

- (void)testThatMapperOperationDelegateIsPassedThroughToUnderlyingMapperOperation
{
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKMapperOperationDelegate)];
    [[mockDelegate expect] mapperWillStartMapping:OCMOCK_ANY];
    
    NSURL *responseURL = [NSURL URLWithString:@"http://restkit.org/api/v1/users"];
    NSURLRequest *request = [NSURLRequest requestWithURL:responseURL];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:responseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/json"}];
    NSData *data = [@"{\"name\": \"Blake\"}" dataUsingEncoding:NSUTF8StringEncoding];
    
    RKTestUser *testUser = [RKTestUser new];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping addAttributeMappingsFromArray:@[ @"name" ]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    
    RKObjectResponseMapperOperation *mapper = [[RKObjectResponseMapperOperation alloc] initWithRequest:request response:response data:data responseDescriptors:@[ responseDescriptor ]];
    mapper.mapperDelegate = mockDelegate;
    mapper.targetObject = testUser;
    [mapper start];    
    [mockDelegate verify];
}

#pragma mark - HTTP Metadata

- (void)testThatResponseMapperMakesRequestMethodAvailableToMetadata
{
    NSURL *responseURL = [NSURL URLWithString:@"http://restkit.org/api/v1/users"];
    NSURLRequest *request = [NSURLRequest requestWithURL:responseURL];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:responseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/json"}];
    NSData *data = [@"{\"name\": \"Blake\"}" dataUsingEncoding:NSUTF8StringEncoding];

    RKTestUser *testUser = [RKTestUser new];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping addAttributeMappingsFromDictionary:@{ @"@metadata.HTTP.request.method": @"name" }];

    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    RKObjectResponseMapperOperation *mapper = [[RKObjectResponseMapperOperation alloc] initWithRequest:request response:response data:data responseDescriptors:@[ responseDescriptor ]];
    mapper.targetObject = testUser;
    [mapper start];
    expect(testUser.name).to.equal(@"GET");
}

- (void)testThatResponseMapperMakesRequestURLAvailableToMetadata
{
    NSURL *responseURL = [NSURL URLWithString:@"http://restkit.org/api/v1/users"];
    NSURLRequest *request = [NSURLRequest requestWithURL:responseURL];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:responseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/json"}];
    NSData *data = [@"{\"name\": \"Blake\"}" dataUsingEncoding:NSUTF8StringEncoding];

    RKTestUser *testUser = [RKTestUser new];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping addAttributeMappingsFromDictionary:@{ @"@metadata.HTTP.request.URL": @"website" }];

    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    RKObjectResponseMapperOperation *mapper = [[RKObjectResponseMapperOperation alloc] initWithRequest:request response:response data:data responseDescriptors:@[ responseDescriptor ]];
    mapper.targetObject = testUser;
    [mapper start];
    expect(testUser.website).to.equal(responseURL);
}

- (void)testThatResponseMapperMakesRequestHeadersAvailableToMetadata
{
    NSURL *responseURL = [NSURL URLWithString:@"http://restkit.org/api/v1/users"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:responseURL];
    [request setAllHTTPHeaderFields:@{ @"Content-Type": @"application/xml" }];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:responseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/json"}];
    NSData *data = [@"{\"name\": \"Blake\"}" dataUsingEncoding:NSUTF8StringEncoding];

    RKTestUser *testUser = [RKTestUser new];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping addAttributeMappingsFromDictionary:@{ @"@metadata.HTTP.request.headers.Content-Type": @"name" }];

    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    RKObjectResponseMapperOperation *mapper = [[RKObjectResponseMapperOperation alloc] initWithRequest:request response:response data:data responseDescriptors:@[ responseDescriptor ]];
    mapper.targetObject = testUser;
    [mapper start];
    expect(testUser.name).to.equal(@"application/xml");
}

- (void)testThatResponseMapperMakesResponseURLAvailableToMetadata
{
    NSURL *responseURL = [NSURL URLWithString:@"http://restkit.org/api/v1/users"];
    NSURLRequest *request = [NSURLRequest requestWithURL:responseURL];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:responseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/json"}];
    NSData *data = [@"{\"name\": \"Blake\"}" dataUsingEncoding:NSUTF8StringEncoding];

    RKTestUser *testUser = [RKTestUser new];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping addAttributeMappingsFromDictionary:@{ @"@metadata.HTTP.response.URL": @"website" }];

    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    RKObjectResponseMapperOperation *mapper = [[RKObjectResponseMapperOperation alloc] initWithRequest:request response:response data:data responseDescriptors:@[ responseDescriptor ]];
    mapper.targetObject = testUser;
    [mapper start];
    expect(testUser.website).to.equal(responseURL);
}

- (void)testThatResponseMapperMakesResponseHeadersAvailableToMetadata
{
    NSURL *responseURL = [NSURL URLWithString:@"http://restkit.org/api/v1/users"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:responseURL];
    [request setAllHTTPHeaderFields:@{ @"Content-Type": @"application/xml" }];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:responseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/json"}];
    NSData *data = [@"{\"name\": \"Blake\"}" dataUsingEncoding:NSUTF8StringEncoding];

    RKTestUser *testUser = [RKTestUser new];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping addAttributeMappingsFromDictionary:@{ @"@metadata.HTTP.response.headers.Content-Type": @"name" }];

    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    RKObjectResponseMapperOperation *mapper = [[RKObjectResponseMapperOperation alloc] initWithRequest:request response:response data:data responseDescriptors:@[ responseDescriptor ]];
    mapper.targetObject = testUser;
    [mapper start];
    expect(testUser.name).to.equal(@"application/json");
}

- (void)testThatResponseMapperMergesExistingMetadata
{
    NSURL *responseURL = [NSURL URLWithString:@"http://restkit.org/api/v1/users"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:responseURL];
    [request setAllHTTPHeaderFields:@{ @"Content-Type": @"application/xml" }];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:responseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/json"}];
    NSData *data = [@"{\"name\": \"Blake\"}" dataUsingEncoding:NSUTF8StringEncoding];

    RKTestUser *testUser = [RKTestUser new];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping addAttributeMappingsFromDictionary:@{ @"@metadata.customKey": @"name" }];

    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    RKObjectResponseMapperOperation *mapper = [[RKObjectResponseMapperOperation alloc] initWithRequest:request response:response data:data responseDescriptors:@[ responseDescriptor ]];
    mapper.mappingMetadata = @{ @"customKey": @"This is the value" };
    mapper.targetObject = testUser;
    [mapper start];
    expect(testUser.name).to.equal(@"This is the value");
}

- (void)testThatResponseMapperMergesExistingMetadataWithOverlappingKeys
{
    NSURL *responseURL = [NSURL URLWithString:@"http://restkit.org/api/v1/users"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:responseURL];
    [request setAllHTTPHeaderFields:@{ @"Content-Type": @"application/xml" }];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:responseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/json"}];
    NSData *data = [@"{\"name\": \"Blake\"}" dataUsingEncoding:NSUTF8StringEncoding];

    RKTestUser *testUser = [RKTestUser new];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping addAttributeMappingsFromDictionary:@{ @"@metadata.HTTP.customKey": @"name", @"@metadata.HTTP.request.URL": @"website" }];

    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    RKObjectResponseMapperOperation *mapper = [[RKObjectResponseMapperOperation alloc] initWithRequest:request response:response data:data responseDescriptors:@[ responseDescriptor ]];
    mapper.mappingMetadata = @{ @"HTTP": @{ @"customKey": @"This is the value" } };
    mapper.targetObject = testUser;
    [mapper start];
    expect(testUser.name).to.equal(@"This is the value");
    expect([testUser.website absoluteString]).to.equal(@"http://restkit.org/api/v1/users");
}

- (void)testRegisteringObjectMappingOperationDataSource
{
    [RKObjectResponseMapperOperation registerMappingOperationDataSourceClass:[RKTestObjectMappingOperationDataSource class]];
    
    NSURL *responseURL = [NSURL URLWithString:@"http://restkit.org/api/v1/users"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:responseURL];
    [request setAllHTTPHeaderFields:@{ @"Content-Type": @"application/xml" }];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:responseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/json"}];
    NSData *data = [@"{\"name\": \"Blake\"}" dataUsingEncoding:NSUTF8StringEncoding];
    
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    RKObjectResponseMapperOperation *mapper = [[RKObjectResponseMapperOperation alloc] initWithRequest:request response:response data:data responseDescriptors:@[ responseDescriptor ]];
    [mapper start];
    expect(mapper.mapperOperation.mappingOperationDataSource).to.beInstanceOf([RKTestObjectMappingOperationDataSource class]);
}

- (void)testRegisteringManagedObjectMappingOperationDataSource
{
    [RKManagedObjectResponseMapperOperation registerMappingOperationDataSourceClass:[RKTestManagedObjectMappingOperationDataSource class]];
    
    NSURL *responseURL = [NSURL URLWithString:@"http://restkit.org/api/v1/users"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:responseURL];
    [request setAllHTTPHeaderFields:@{ @"Content-Type": @"application/xml" }];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:responseURL statusCode:200 HTTPVersion:@"1.1" headerFields:@{@"Content-Type": @"application/json"}];
    NSData *data = [@"{\"name\": \"Blake\"}" dataUsingEncoding:NSUTF8StringEncoding];
    
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    RKManagedObjectResponseMapperOperation *mapper = [[RKManagedObjectResponseMapperOperation alloc] initWithRequest:request response:response data:data responseDescriptors:@[ responseDescriptor ]];
    mapper.managedObjectContext = [RKTestFactory managedObjectStore].mainQueueManagedObjectContext;
    [mapper start];
    expect(mapper.mapperOperation.mappingOperationDataSource).to.beInstanceOf([RKTestManagedObjectMappingOperationDataSource class]);
}

- (void)testThatAttemptingToRegisterNonConformantClassRaisesException
{
    expect(^{ [RKObjectResponseMapperOperation registerMappingOperationDataSourceClass:[NSString class]]; }).to.raiseWithReason(NSInvalidArgumentException, @"Registered data source class 'NSString' does not conform to the `RKMappingOperationDataSource` protocol.");
}

- (void)testThatAttemptingToRegisterNonSublassOfManagedObjectMappingOperationDataSourceRaisesException
{
    expect(^{ [RKManagedObjectResponseMapperOperation registerMappingOperationDataSourceClass:[RKTestObjectMappingOperationDataSource class]]; }).to.raiseWithReason(NSInvalidArgumentException, @"Registered data source class 'RKTestObjectMappingOperationDataSource' does not inherit from the `RKManagedObjectMappingOperationDataSource` class: You must subclass `RKManagedObjectMappingOperationDataSource` in order to register a data source class for `RKManagedObjectResponseMapperOperation`.");
}

@end
