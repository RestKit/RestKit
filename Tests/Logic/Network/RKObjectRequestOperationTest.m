//
//  RKObjectRequestOperationTest.m
//  RestKit
//
//  Created by Blake Watters on 10/14/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKErrorMessage.h"

// Models
#import "RKObjectLoaderTestResultModel.h"

@interface RKTestComplexUser : NSObject

@property (nonatomic, retain) NSNumber *userID;
@property (nonatomic, retain) NSString *firstname;
@property (nonatomic, retain) NSString *lastname;
@property (nonatomic, retain) NSString *email;
@property (nonatomic, retain) NSString *phone;

@end

@interface RKMapperTestObjectRequestOperation : RKObjectRequestOperation
@end

@implementation RKMapperTestObjectRequestOperation

- (void)mapperWillStartMapping:(RKMapperOperation *)mapper
{
    // Used for stubbing
}

@end

@implementation RKTestComplexUser
@end

@interface RKObjectRequestOperationTest : RKTestCase
@end

@implementation RKObjectRequestOperationTest

- (void)setUp
{
    [RKTestFactory setUp];
}

- (void)tearDown
{
    [RKTestFactory tearDown];
}

- (RKResponseDescriptor *)responseDescriptorForComplexUser
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [userMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"firstname" toKeyPath:@"firstname"]];

    return [RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"data.STUser" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
}

- (RKResponseDescriptor *)errorResponseDescriptor
{
    RKObjectMapping *errorMapping = [RKObjectMapping mappingForClass:[RKErrorMessage class]];
    [errorMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:nil toKeyPath:@"errorMessage"]];

    NSMutableIndexSet *errorCodes = [NSMutableIndexSet indexSet];
    [errorCodes addIndexes:RKStatusCodeIndexSetForClass(RKStatusCodeClassClientError)];
    [errorCodes addIndexes:RKStatusCodeIndexSetForClass(RKStatusCodeClassServerError)];
    return [RKResponseDescriptor responseDescriptorWithMapping:errorMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"errors" statusCodes:errorCodes];
}

- (void)testThatObjectRequestOperationResultsInRefreshedPropertiesAfterMapping
{

}

- (void)testCancellationOfObjectRequestOperationCancelsMapping
{

}

- (void)testShouldReturnSuccessWhenTheStatusCodeIs200AndTheResponseBodyOnlyContainsWhitespaceCharacters
{
    RKTestComplexUser *user = [RKTestComplexUser new];
    user.firstname = @"Blake";
    user.lastname = @"Watters";
    user.email = @"blake@restkit.org";

    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [userMapping addAttributeMappingsFromArray:@[ @"userMapping" ]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:nil];
    NSMutableURLRequest *request = [NSMutableURLRequest  requestWithURL:[NSURL URLWithString:@"/humans/1234/whitespace" relativeToURL:[RKTestFactory baseURL]]];
    request.HTTPMethod = @"DELETE";
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    requestOperation.targetObject = user;
    [requestOperation start];
    [requestOperation waitUntilFinished];
    expect(requestOperation.error).to.beNil();
    expect(requestOperation.mappingResult).notTo.beNil();
}

- (void)testSendingAnObjectRequestOperationToAnInvalidHostname
{
    NSMutableURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://invalid.is"]];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ [self responseDescriptorForComplexUser] ]];
    [requestOperation start];
    expect([requestOperation isFinished]).will.beTruthy();
    
    // NOTE: If your ISP provides a redirect page for unknown hosts, you'll get a `NSURLErrorCannotDecodeContentData`
    NSArray *validErrorCodes = @[ @(NSURLErrorCannotDecodeContentData), @(NSURLErrorCannotFindHost) ];
    assertThat(validErrorCodes, hasItem(@([requestOperation.error code])));
}

- (void)testSendingAnObjectRequestOperationToAnBrokenURL
{
    NSMutableURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://invalid••™¡.is"]];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ [self responseDescriptorForComplexUser] ]];
    [requestOperation start];
    expect([requestOperation isFinished]).will.beTruthy();
    
    expect([requestOperation.error code]).to.equal(NSURLErrorBadURL);
}

#pragma mark - Complex JSON

- (void)testShouldLoadAComplexUserObjectWithTargetObject
{
    RKTestComplexUser *user = [RKTestComplexUser new];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/ComplexNestedUser.json" relativeToURL:[RKTestFactory baseURL]]];
    NSString *authString = [NSString stringWithFormat:@"TRUEREST username=%@&password=%@&apikey=123456&class=iphone", @"username", @"password"];
    [request addValue:authString forHTTPHeaderField:@"Authorization"];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ [self responseDescriptorForComplexUser] ]];
    requestOperation.targetObject = user;
    [requestOperation start];
    expect([requestOperation isFinished]).will.beTruthy();

    expect(user.firstname).to.equal(@"Diego");
}

- (void)testShouldLoadAComplexUserObjectWithoutTargetObject
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/ComplexNestedUser.json" relativeToURL:[RKTestFactory baseURL]]];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ [self responseDescriptorForComplexUser] ]];
    [requestOperation start];
    expect([requestOperation isFinished]).will.beTruthy();
    expect([requestOperation.mappingResult array]).to.haveCountOf(1);
    RKTestComplexUser *user = [[requestOperation.mappingResult array] lastObject];
    expect(user.firstname).to.equal(@"Diego");
}

- (void)testShouldHandleTheErrorCaseAppropriately
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/errors.json" relativeToURL:[RKTestFactory baseURL]]];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ [self errorResponseDescriptor] ]];
    [requestOperation start];
    expect([requestOperation isFinished]).will.beTruthy();

    expect(requestOperation.error).notTo.beNil();
    expect([requestOperation.error localizedDescription]).to.equal(@"error1, error2");

    NSArray *objects = [[requestOperation.error userInfo] objectForKey:RKObjectMapperErrorObjectsKey];
    RKErrorMessage *error1 = [objects objectAtIndex:0];
    RKErrorMessage *error2 = [objects lastObject];

    expect(error1.errorMessage).to.equal(@"error1");
    expect(error2.errorMessage).to.equal(@"error2");
}

- (void)testShouldNotCrashWhenLoadingAnErrorResponseWithAnUnmappableMIMEType
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/404" relativeToURL:[RKTestFactory baseURL]]];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ [self errorResponseDescriptor] ]];
    [requestOperation start];
    expect([requestOperation isFinished]).will.beTruthy();
    expect(requestOperation.error).notTo.beNil();
}

- (void)testShouldLoadResultsNestedAtAKeyPath
{
    RKObjectMapping *objectMapping = [RKObjectMapping mappingForClass:[RKObjectLoaderTestResultModel class]];
    [objectMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"ID"]];
    [objectMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"ends_at" toKeyPath:@"endsAt"]];
    [objectMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"photo_url" toKeyPath:@"photoURL"]];

    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:objectMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"results" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/ArrayOfResults.json" relativeToURL:[RKTestFactory baseURL]]];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    [requestOperation start];
    expect([requestOperation isFinished]).will.beTruthy();

    NSArray *objects = [requestOperation.mappingResult array];
    expect(objects).to.haveCountOf(2);
    expect([objects[0] ID]).to.equal(226);
    expect([objects[0] photoURL]).to.equal(@"1308262872.jpg");
    expect([objects[1] ID]).to.equal(235);
    expect([objects[1] photoURL]).to.equal(@"1308634984.jpg");
}

- (void)testShouldAllowYouToPostAnObjectAndHandleAnEmpty204Response
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [mapping addAttributeMappingsFromArray:@[@"firstname", @"lastname", @"email"]];
    RKObjectMapping *serializationMapping = [mapping inverseMapping];
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:serializationMapping objectClass:[RKTestComplexUser class] rootKeyPath:nil method:RKRequestMethodAny];

    RKTestComplexUser *user = [RKTestComplexUser new];
    user.firstname = @"Blake";
    user.lastname = @"Watters";
    user.email = @"blake@restkit.org";

    NSError *error = nil;
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:user requestDescriptor:requestDescriptor error:&error];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/204" relativeToURL:[RKTestFactory baseURL]]];
    request.HTTPMethod = @"POST";
    NSData *requestBody = [RKMIMETypeSerialization dataFromObject:parameters MIMEType:RKMIMETypeFormURLEncoded error:&error];
    [request setHTTPBody:requestBody];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[]];
    requestOperation.targetObject = user;
    [requestOperation start];
    expect([requestOperation isFinished]).will.beTruthy();

    expect(requestOperation.HTTPRequestOperation.response.statusCode).to.equal(204);
    expect(requestOperation.error).to.beNil();
    expect(requestOperation.mappingResult).notTo.beNil();
    expect([requestOperation.mappingResult array]).to.contain(user);
    expect(user.email).to.equal(@"blake@restkit.org");
}

- (void)testShouldAllowYouToPOSTAnObjectAndMapBackNonNestedContent
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [mapping addAttributeMappingsFromArray:@[@"firstname", @"lastname", @"email"]];
    RKObjectMapping *serializationMapping = [mapping inverseMapping];
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:serializationMapping objectClass:[RKTestComplexUser class] rootKeyPath:nil method:RKRequestMethodAny];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];

    RKTestComplexUser *user = [RKTestComplexUser new];
    user.firstname = @"Blake";
    user.lastname = @"Watters";
    user.email = @"blake@restkit.org";

    NSError *error = nil;
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:user requestDescriptor:requestDescriptor error:&error];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/notNestedUser" relativeToURL:[RKTestFactory baseURL]]];
    request.HTTPMethod = @"POST";
    NSData *requestBody = [RKMIMETypeSerialization dataFromObject:parameters MIMEType:RKMIMETypeFormURLEncoded error:&error];
    [request setHTTPBody:requestBody];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    requestOperation.targetObject = user;
    [requestOperation start];
    expect([requestOperation isFinished]).will.beTruthy();

    expect(requestOperation.error).to.beNil();
    expect(requestOperation.mappingResult).notTo.beNil();
    expect(user.email).to.equal(@"changed");
}

- (void)testShouldAllowYouToPOSTAnObjectOfOneTypeAndGetBackAnother
{
    RKObjectMapping *sourceMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [sourceMapping addAttributeMappingsFromArray:@[@"firstname", @"lastname", @"email"]];
    RKObjectMapping *serializationMapping = [sourceMapping inverseMapping];

    RKObjectMapping *targetMapping = [RKObjectMapping mappingForClass:[RKObjectLoaderTestResultModel class]];
    [targetMapping addAttributeMappingsFromArray:@[@"ID"]];

    RKTestComplexUser *user = [RKTestComplexUser new];
    user.firstname = @"Blake";
    user.lastname = @"Watters";
    user.email = @"blake@restkit.org";

    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:serializationMapping objectClass:[RKTestComplexUser class] rootKeyPath:nil method:RKRequestMethodAny];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:targetMapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];

    NSError *error = nil;
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:user requestDescriptor:requestDescriptor error:&error];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/notNestedUser" relativeToURL:[RKTestFactory baseURL]]];
    request.HTTPMethod = @"POST";
    NSData *requestBody = [RKMIMETypeSerialization dataFromObject:parameters MIMEType:RKMIMETypeFormURLEncoded error:&error];
    [request setHTTPBody:requestBody];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    [requestOperation start];
    expect([requestOperation isFinished]).will.beTruthy();

    expect(requestOperation.error).to.beNil();
    expect(requestOperation.mappingResult).notTo.beNil();

    // Our original object should not have changed
    expect(user.email).to.equal(@"blake@restkit.org");

    // And we should have a new one
    RKObjectLoaderTestResultModel *newObject = [[requestOperation.mappingResult array] lastObject];
    expect(newObject).to.beInstanceOf([RKObjectLoaderTestResultModel class]);
    expect(newObject.ID).to.equal(31337);
}

- (void)testShouldAllowYouToPOSTAnObjectOfOneTypeAndGetBackAnotherViaURLConfiguration
{
    RKObjectMapping *sourceMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [sourceMapping addAttributeMappingsFromArray:@[@"firstname", @"lastname", @"email"]];
    RKObjectMapping *serializationMapping = [sourceMapping inverseMapping];

    RKObjectMapping *targetMapping = [RKObjectMapping mappingForClass:[RKObjectLoaderTestResultModel class]];
    [targetMapping addAttributeMappingsFromArray:@[@"ID"]];

    RKTestComplexUser *user = [RKTestComplexUser new];
    user.firstname = @"Blake";
    user.lastname = @"Watters";
    user.email = @"blake@restkit.org";

    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:serializationMapping objectClass:[RKTestComplexUser class] rootKeyPath:nil method:RKRequestMethodAny];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:targetMapping method:RKRequestMethodAny pathPattern:@"/notNestedUser" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];

    NSError *error = nil;
    NSDictionary *parameters = [RKObjectParameterization parametersWithObject:user requestDescriptor:requestDescriptor error:&error];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/notNestedUser" relativeToURL:[RKTestFactory baseURL]]];
    request.HTTPMethod = @"POST";
    NSData *requestBody = [RKMIMETypeSerialization dataFromObject:parameters MIMEType:RKMIMETypeFormURLEncoded error:&error];
    [request setHTTPBody:requestBody];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    [requestOperation start];
    expect([requestOperation isFinished]).will.beTruthy();

    expect(requestOperation.error).to.beNil();
    expect(requestOperation.mappingResult).notTo.beNil();

    // Our original object should not have changed
    expect(user.email).to.equal(@"blake@restkit.org");

    // And we should have a new one
    RKObjectLoaderTestResultModel *newObject = [[requestOperation.mappingResult array] lastObject];
    expect(newObject).to.beInstanceOf([RKObjectLoaderTestResultModel class]);
    expect(newObject.ID).to.equal(31337);
}

- (void)testMappingResponseWithExactMatchForResponseDescriptorPathPattern
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [userMapping addAttributeMappingsFromArray:@[@"firstname"]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:@"/JSON/ComplexNestedUser.json" keyPath:@"data.STUser" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];

    RKTestComplexUser *user = [RKTestComplexUser new];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/ComplexNestedUser.json" relativeToURL:[RKTestFactory baseURL]]];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    requestOperation.targetObject = user;
    [requestOperation start];
    expect([requestOperation isFinished]).will.beTruthy();

    expect(requestOperation.error).to.beNil();
    expect(requestOperation.mappingResult).notTo.beNil();

    expect(user.firstname).to.equal(@"Diego");
}

- (void)testMappingResponseWithDynamicMatchForResponseDescriptorPathPattern
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [userMapping addAttributeMappingsFromArray:@[@"firstname"]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:@"/JSON/:name\\.json" keyPath:@"data.STUser" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];

    RKTestComplexUser *user = [RKTestComplexUser new];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/ComplexNestedUser.json" relativeToURL:[RKTestFactory baseURL]]];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    requestOperation.targetObject = user;
    [requestOperation start];
    expect([requestOperation isFinished]).will.beTruthy();

    expect(requestOperation.error).to.beNil();
    expect(requestOperation.mappingResult).notTo.beNil();

    expect(user.firstname).to.equal(@"Diego");
}

- (void)testThatAResponseWithA2xxStatusCodeAnEmptyResponseBodyIsConsideredASuccessfulExecution
{
    RKTestComplexUser *user = [RKTestComplexUser new];
    user.firstname = @"Blake";
    user.lastname = @"Watters";
    user.email = @"blake@restkit.org";

    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [userMapping addAttributeMappingsFromArray:@[@"firstname"]];

    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"data.STUser" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/humans/1234" relativeToURL:[RKTestFactory baseURL]]];
    request.HTTPMethod = @"DELETE";
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    requestOperation.targetObject = user;
    [requestOperation start];
    expect([requestOperation isFinished]).will.beTruthy();

    expect(requestOperation.mappingResult).notTo.beNil();
}

- (void)testThatAResponseWithA2xxStatusCodeAnEmptyResponseBodyLoadsAMappingResultContainingTheTargetObject
{
    RKTestComplexUser *user = [RKTestComplexUser new];
    user.firstname = @"Blake";
    user.lastname = @"Watters";
    user.email = @"blake@restkit.org";

    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [userMapping addAttributeMappingsFromArray:@[@"firstname"]];

    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"data.STUser" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/humans/1234" relativeToURL:[RKTestFactory baseURL]]];
    request.HTTPMethod = @"DELETE";
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    requestOperation.targetObject = user;
    [requestOperation start];
    expect([requestOperation isFinished]).will.beTruthy();

    expect([requestOperation.mappingResult array]).to.contain(user);
}

- (void)testShouldConsiderTheLoadOfEmptyObjectsWithoutAnyMappableAttributesAsSuccess
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [userMapping addAttributeMappingsFromArray:@[@"firstname"]];

    RKResponseDescriptor *responseDescriptor1 = [RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"firstUser" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    RKResponseDescriptor *responseDescriptor2 = [RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"secondUser" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/users/empty" relativeToURL:[RKTestFactory baseURL]]];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor1, responseDescriptor2 ]];
    [requestOperation start];
    expect([requestOperation isFinished]).will.beTruthy();
    expect(requestOperation.mappingResult).notTo.beNil();
}

- (void)testThatAnEmptyArrayResponseBodyResultsInANilMappingResultAndNilError
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/empty/array" relativeToURL:[RKTestFactory baseURL]]];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ ]];
    [requestOperation start];
    expect([requestOperation isFinished]).will.beTruthy();
    expect(requestOperation.mappingResult).to.beNil();
    expect(requestOperation.error).to.beNil();
}

- (void)testThatAnEmptyDictionaryResponseBodyResultsInANilMappingResultAndNilError
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/empty/dictionary" relativeToURL:[RKTestFactory baseURL]]];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ ]];
    [requestOperation start];
    expect([requestOperation isFinished]).will.beTruthy();
    expect(requestOperation.mappingResult).to.beNil();
    expect(requestOperation.error).to.beNil();
}

// NOTE: This is for supporting Rails `render :nothing => true`
- (void)testThatAnEmptyStringResponseBodyResultsInANilMappingResultAndNilError
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/empty/string" relativeToURL:[RKTestFactory baseURL]]];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ ]];
    [requestOperation start];
    expect([requestOperation isFinished]).will.beTruthy();
    expect(requestOperation.mappingResult).to.beNil();
    expect(requestOperation.error).to.beNil();
}

// NOTE: This is a bit of a curveball case. To support Rails returning an empty string, if there's a target object you get back a mapping result
- (void)testThatAnEmptyStringResponseBodyForAnObjectRequestOperationWithATargetObjectReturnsAMappingResultContainingTheObject
{
    NSObject *targetObject = [NSObject new];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/empty/string" relativeToURL:[RKTestFactory baseURL]]];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ ]];
    requestOperation.targetObject = targetObject;
    [requestOperation start];
    expect([requestOperation isFinished]).will.beTruthy();
    expect(requestOperation.mappingResult).notTo.beNil();
    expect(requestOperation.error).to.beNil();
    expect([requestOperation.mappingResult array]).to.contain(targetObject);
}

- (void)testErrorReportingForPathPatternMismatch
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [userMapping addAttributeMappingsFromArray:@[@"firstname"]];
    
    NSURL *baseURL = [NSURL URLWithString:@"http://restkit.org/api/v1"];
    RKResponseDescriptor *responseDescriptor1 = [RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:@"/users/empty" keyPath:@"firstUser" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    responseDescriptor1.baseURL = baseURL;
    RKResponseDescriptor *responseDescriptor2 = [RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:@"/users/empty" keyPath:@"secondUser" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    responseDescriptor2.baseURL = baseURL;
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/users/empty" relativeToURL:[RKTestFactory baseURL]]];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor1, responseDescriptor2 ]];
    [requestOperation start];
    expect([requestOperation isFinished]).will.beTruthy();
    expect(requestOperation.error).notTo.beNil();    
    NSString *failureReason = [[requestOperation.error userInfo] valueForKey:NSLocalizedFailureReasonErrorKey];
    assertThat(failureReason, containsString(@"A 200 response was loaded from the URL 'http://127.0.0.1:4567/users/empty', which failed to match all (2) response descriptors:"));
    assertThat(failureReason, containsString(@"failed to match: response URL 'http://127.0.0.1:4567/users/empty' is not relative to the baseURL 'http://restkit.org/api/v1'."));
    assertThat(failureReason, containsString(@"failed to match: response URL 'http://127.0.0.1:4567/users/empty' is not relative to the baseURL 'http://restkit.org/api/v1'."));
}

// Test trailing slash on the baseURL

#pragma mark - Block Tests

- (void)testInvocationOfSuccessBlock
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/empty/array" relativeToURL:[RKTestFactory baseURL]]];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ ]];

    __block BOOL invoked = NO;
    [requestOperation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        invoked = YES;
    } failure:nil];

    [requestOperation start];
    expect(invoked).will.beTruthy();
}

- (void)testInvocationOfFailureBlock
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/errors.json" relativeToURL:[RKTestFactory baseURL]]];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ ]];

    __block NSError *blockError = nil;
    [requestOperation setCompletionBlockWithSuccess:nil failure:^(RKObjectRequestOperation *operation, NSError *error) {
        blockError = error;
    }];

    [requestOperation start];
    expect([requestOperation isFinished]).will.beTruthy();
    expect(blockError).willNot.beNil();
}

#pragma mark - Will Map Data Block

- (void)testShouldAllowMutationOfTheParsedDataInWillMapData
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [mapping addAttributeMappingsFromArray:@[@"firstname", @"lastname", @"email"]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:nil keyPath:@"user" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/ComplexNestedUser.json" relativeToURL:[RKTestFactory baseURL]]];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    [requestOperation setWillMapDeserializedResponseBlock:^id(id deserializedResponseBody) {
        return @{ @"user": @{ @"email": @"blake@restkit.org" } };
    }];
    [requestOperation start];
    expect([requestOperation isFinished]).will.beTruthy();
    RKTestComplexUser *user = [requestOperation.mappingResult firstObject];
    expect(user).notTo.beNil();
    expect(user.email).to.equal(@"blake@restkit.org");
}

- (void)testThatLoadingAnUnexpectedContentTypeReturnsCorrectErrorMessage
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [userMapping addAttributeMappingsFromArray:@[@"firstname"]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:@"/JSON/ComplexNestedUser.json" keyPath:@"data.STUser" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/XML/channels.xml" relativeToURL:[RKTestFactory baseURL]]];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    [requestOperation start];
    expect([requestOperation isFinished]).will.beTruthy();
    
    expect(requestOperation.error).notTo.beNil();
    expect([requestOperation.error localizedDescription]).to.equal(@"Expected content type {(\n    \"application/json\",\n    \"application/x-www-form-urlencoded\"\n)}, got application/xml");
}

- (void)testThatLoadingAnUnexpectedStatusCodeReturnsCorrectErrorMessage
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [userMapping addAttributeMappingsFromArray:@[@"firstname"]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:@"/JSON/ComplexNestedUser.json" keyPath:@"data.STUser" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/503" relativeToURL:[RKTestFactory baseURL]]];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    [requestOperation start];
    expect([requestOperation isFinished]).will.beTruthy();
    
    expect(requestOperation.error).notTo.beNil();
    expect([requestOperation.error localizedDescription]).to.equal(@"Expected status code in (200-299), got 503");
}

- (void)testThatMapperOperationDelegateIsPassedThroughToUnderlyingMapperOperation
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/ComplexNestedUser.json" relativeToURL:[RKTestFactory baseURL]]];
    RKMapperTestObjectRequestOperation *requestOperation = [[RKMapperTestObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ [self responseDescriptorForComplexUser] ]];
    id mockOperation = [OCMockObject partialMockForObject:requestOperation];
    [[mockOperation expect] mapperWillStartMapping:OCMOCK_ANY];
    [requestOperation start];
    expect([requestOperation isFinished]).will.beTruthy();
    [mockOperation verify];
}

- (void)testMappingErrorsFromFiveHundredStatusCodeRange
{
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassServerError);
    RKObjectMapping *errorResponseMapping = [RKObjectMapping mappingForClass:[RKErrorMessage class]];
    [errorResponseMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:nil toKeyPath:@"errorMessage"]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:errorResponseMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"errors" statusCodes:statusCodes];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/fail" relativeToURL:[RKTestFactory baseURL]]];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    [requestOperation start];
    expect([requestOperation isFinished]).will.beTruthy();
    
    expect(requestOperation.error).willNot.beNil();
    expect([requestOperation.error localizedDescription]).to.equal(@"error1, error2");
}

- (void)testMappingErrorsWithNilStatusCodesAndTwoHundredDescriptorRegistered
{
    RKObjectMapping *errorResponseMapping = [RKObjectMapping mappingForClass:[RKErrorMessage class]];
    [errorResponseMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:nil toKeyPath:@"errorMessage"]];
    RKResponseDescriptor *errorDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:errorResponseMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"errors" statusCodes:nil];
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    RKResponseDescriptor *userDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"user" statusCodes:[NSIndexSet indexSetWithIndex:200]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/fail" relativeToURL:[RKTestFactory baseURL]]];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ userDescriptor, errorDescriptor ]];
    [requestOperation start];
    expect([requestOperation isFinished]).will.beTruthy();
    
    expect(requestOperation.error).willNot.beNil();
    expect([requestOperation.error localizedDescription]).to.equal(@"error1, error2");
}

- (void)testFiveHundredErrorWithEmptyResponse
{
    RKObjectMapping *errorResponseMapping = [RKObjectMapping mappingForClass:[RKErrorMessage class]];
    [errorResponseMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:nil toKeyPath:@"errorMessage"]];
    RKResponseDescriptor *errorDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:errorResponseMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"errors" statusCodes:nil];
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    RKResponseDescriptor *userDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"user" statusCodes:[NSIndexSet indexSetWithIndex:200]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/500" relativeToURL:[RKTestFactory baseURL]]];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ userDescriptor, errorDescriptor ]];
    [requestOperation start];
    [requestOperation waitUntilFinished];
    
    expect(requestOperation.error).willNot.beNil();
    expect([requestOperation.error localizedDescription]).to.equal(@"Loaded an unprocessable response (500) with content type 'application/json'");
}

- (void)testThatAnObjectRequestOperationSentWithEmptyMappingInResponseDescriptorsIsConsideredSuccessful
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    RKTestComplexUser *user = [RKTestComplexUser new];
    user.firstname = @"Blake";
    user.lastname = @"Watters";
    user.email = @"blake@restkit.org";
    
    NSMutableURLRequest *request = [NSMutableURLRequest  requestWithURL:[NSURL URLWithString:@"/humans" relativeToURL:[RKTestFactory baseURL]]];
    request.HTTPMethod = @"POST";
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    requestOperation.targetObject = user;
    [requestOperation start];
    expect([requestOperation isFinished]).will.beTruthy();
    expect(requestOperation.error).to.beNil();
    expect(requestOperation.mappingResult).notTo.beNil();
}

- (void)testThatAnObjectRequestOperationSentWithEmptyMappingInResponseDescriptorsTo5xxEndpointIsConsideredSuccessful
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    RKTestComplexUser *user = [RKTestComplexUser new];
    user.firstname = @"Blake";
    user.lastname = @"Watters";
    user.email = @"blake@restkit.org";
    
    NSMutableURLRequest *request = [NSMutableURLRequest  requestWithURL:[NSURL URLWithString:@"/humans/fail" relativeToURL:[RKTestFactory baseURL]]];
    request.HTTPMethod = @"POST";
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    requestOperation.targetObject = user;
    [requestOperation start];
    expect([requestOperation isFinished]).will.beTruthy();
    expect(requestOperation.error).notTo.beNil();
    expect([requestOperation.error localizedDescription]).to.equal(@"Expected status code in (200-299), got 500");
}

- (void)testMappingMetadataConfiguredOnTheOperation
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [userMapping addAttributeMappingsFromDictionary:@{ @"@metadata.phoneNumber": @"phone" }];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];

    RKTestComplexUser *user = [RKTestComplexUser new];
    user.firstname = @"Blake";
    user.lastname = @"Watters";
    user.email = @"blake@restkit.org";

    NSMutableURLRequest *request = [NSMutableURLRequest  requestWithURL:[NSURL URLWithString:@"/humans" relativeToURL:[RKTestFactory baseURL]]];
    request.HTTPMethod = @"POST";
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    requestOperation.mappingMetadata = @{ @"phoneNumber": @"867-5309" };
    requestOperation.targetObject = user;
    [requestOperation start];
    expect([requestOperation isFinished]).will.beTruthy();
    expect(requestOperation.error).to.beNil();
    expect(requestOperation.mappingResult).notTo.beNil();
    expect(user.phone).to.equal(@"867-5309");
}

- (void)testCopyingOperation
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [userMapping addAttributeMappingsFromDictionary:@{ @"@metadata.phoneNumber": @"phone" }];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    RKTestComplexUser *user = [RKTestComplexUser new];
    user.firstname = @"Blake";
    user.lastname = @"Watters";
    user.email = @"blake@restkit.org";
    
    NSMutableURLRequest *request = [NSMutableURLRequest  requestWithURL:[NSURL URLWithString:@"/humans" relativeToURL:[RKTestFactory baseURL]]];
    request.HTTPMethod = @"POST";
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    [requestOperation start];
    expect([requestOperation isFinished]).will.beTruthy();
    
    RKObjectRequestOperation *copiedOperation = [requestOperation copy];
    copiedOperation.mappingMetadata = @{ @"phoneNumber": @"867-5309" };
    copiedOperation.targetObject = user;
    [copiedOperation start];
    [copiedOperation waitUntilFinished];
    expect(requestOperation.error).to.beNil();
    expect(requestOperation.mappingResult).notTo.beNil();
    expect(user.phone).to.equal(@"867-5309");
}

#pragma mark -

- (void)testThatCacheEntryIsFlaggedWhenMappingCompletes
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [userMapping addAttributeMappingsFromDictionary:@{ @"name": @"email" }];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"human" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/coredata/etag" relativeToURL:[RKTestFactory baseURL]]];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    [requestOperation start];
    expect([requestOperation isFinished]).will.beTruthy();
    expect(requestOperation.error).to.beNil();
    
    NSCachedURLResponse *response = [[NSURLCache sharedURLCache] cachedResponseForRequest:request];
    expect(response).notTo.beNil();
    expect([response.userInfo valueForKey:RKResponseHasBeenMappedCacheUserInfoKey]).to.beTruthy();
}

- (void)testThatCacheEntryIsNotFlaggedWhenMappingFails
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:@"/mismatch" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/coredata/etag" relativeToURL:[RKTestFactory baseURL]]];
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    [requestOperation start];
    expect([requestOperation isFinished]).will.beTruthy();
    expect(requestOperation.error).notTo.beNil();
    expect([requestOperation.error localizedDescription]).to.equal(@"No response descriptors match the response loaded.");
    
    NSCachedURLResponse *response = [[NSURLCache sharedURLCache] cachedResponseForRequest:request];
    expect(response).notTo.beNil();
    expect([response.userInfo valueForKey:RKResponseHasBeenMappedCacheUserInfoKey]).to.beFalsy();
}

- (void)testThatCancellationOfOperationReturnsCancelledCodeAndInvokesFailureBlock
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [userMapping addAttributeMappingsFromDictionary:@{ @"@metadata.phoneNumber": @"phone" }];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    NSMutableURLRequest *request = [NSMutableURLRequest  requestWithURL:[NSURL URLWithString:@"/humans" relativeToURL:[RKTestFactory baseURL]]];
    request.HTTPMethod = @"POST";
    RKObjectRequestOperation *requestOperation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    __block BOOL invoked = NO;
    [requestOperation setCompletionBlockWithSuccess:nil failure:^(RKObjectRequestOperation *operation, NSError *error) {
        invoked = YES;
    }];
    __weak __typeof(&*requestOperation)weakOperation = requestOperation;
    [requestOperation setWillMapDeserializedResponseBlock:^id(id deserializedResponseBody) {
        [weakOperation cancel];
        return deserializedResponseBody;
    }];
    [requestOperation start];
    expect([requestOperation isExecuting]).to.equal(YES);
    expect([requestOperation isFinished]).will.equal(YES);
    expect(invoked).will.equal(YES);
    expect(requestOperation.error).notTo.beNil();
    expect(requestOperation.error.code).to.equal(RKOperationCancelledError);
}

- (void)testThatOperationDependenciesAreRespected
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestComplexUser class]];
    [userMapping addAttributeMappingsFromArray:@[ @"name" ]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/humans" relativeToURL:[RKTestFactory baseURL]]];
    RKObjectRequestOperation *requestOperation1 = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    RKObjectRequestOperation *requestOperation2 = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    [requestOperation2 addDependency:requestOperation1];
    expect(requestOperation1.isReady).to.beTruthy();
    expect(requestOperation2.isReady).to.beFalsy();
    [requestOperation1 start];
    expect(requestOperation1.isFinished).will.beTruthy();
    expect(requestOperation2.isReady).will.beTruthy();
}

@end
