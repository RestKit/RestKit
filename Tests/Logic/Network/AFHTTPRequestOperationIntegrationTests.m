//
//  AFHTTPRequestOperationIntegrationTests.m
//  RestKit
//
//  Created by Blake Watters on 11/21/13.
//  Copyright (c) 2013 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "AFHTTPRequestOperation.h"
#import "RKResponseSerialization.h"
#import "RKObjectLoaderTestResultModel.h"

@interface RKTestComplexUser : NSObject

@property (nonatomic, retain) NSNumber *userID;
@property (nonatomic, retain) NSString *firstname;
@property (nonatomic, retain) NSString *lastname;
@property (nonatomic, retain) NSString *email;
@property (nonatomic, retain) NSString *phone;

@end

@implementation RKTestComplexUser
@end

// Tests the integration between RestKit and AFNetworking via AFHTTPRequestOperation
@interface AFHTTPRequestOperationIntegrationTests : SenTestCase

@end

@implementation AFHTTPRequestOperationIntegrationTests

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

    return [RKResponseDescriptor responseDescriptorWithMethods:RKHTTPMethodAny pathTemplateString:nil parameterConstraints:nil keyPath:@"data.STUser" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful) mapping:userMapping];
}

- (RKResponseDescriptor *)errorResponseDescriptor
{
    RKObjectMapping *errorMapping = [RKObjectMapping mappingForClass:[RKErrorMessage class]];
    [errorMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:nil toKeyPath:@"errorMessage"]];

    NSMutableIndexSet *errorCodes = [NSMutableIndexSet indexSet];
    [errorCodes addIndexes:RKStatusCodeIndexSetForClass(RKStatusCodeClassClientError)];
    [errorCodes addIndexes:RKStatusCodeIndexSetForClass(RKStatusCodeClassServerError)];
    return [RKResponseDescriptor responseDescriptorWithMethods:RKHTTPMethodAny pathTemplateString:nil parameterConstraints:nil keyPath:@"errors" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful) mapping:errorMapping];
}

- (void)testBasicMapping
{
//    NSURLRequest *request = [NSURLRequest ]
//    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:<#(NSURLRequest *)#>]
}

- (void)testShouldLoadAComplexUserObjectWithTargetObject
{
    RKTestComplexUser *user = [RKTestComplexUser new];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/ComplexNestedUser.json" relativeToURL:[RKTestFactory baseURL]]];
    NSString *authString = [NSString stringWithFormat:@"TRUEREST username=%@&password=%@&apikey=123456&class=iphone", @"username", @"password"];
    [request addValue:authString forHTTPHeaderField:@"Authorization"];
    AFHTTPRequestOperation *requestOperation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    AFJSONResponseSerializer *responseDataSerializer = [AFJSONResponseSerializer new];
    RKResponseSerializationManager *serializationManager = [RKResponseSerializationManager managerWithDataSerializer:responseDataSerializer];
    [serializationManager addResponseDescriptor:[self responseDescriptorForComplexUser]];
    RKObjectResponseSerializer *serializer = [serializationManager serializerWithRequest:request object:user];
    requestOperation.responseSerializer = serializer;
    [requestOperation start];
    expect([requestOperation isFinished]).will.beTruthy();

    expect(requestOperation.responseObject).notTo.beNil();

    expect(user.firstname).to.equal(@"Diego");
}

@end
