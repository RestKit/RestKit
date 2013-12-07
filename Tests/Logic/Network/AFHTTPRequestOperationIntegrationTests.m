//
//  AFHTTPRequestOperationIntegrationTests.m
//  RestKit
//
//  Created by Blake Watters on 11/21/13.
//  Copyright (c) 2013 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "AFHTTPRequestOperation.h"
#import "RKObjectResponseSerializer.h"
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

    return [RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKHTTPMethodAny pathPattern:nil keyPath:@"data.STUser" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
}

- (RKResponseDescriptor *)errorResponseDescriptor
{
    RKObjectMapping *errorMapping = [RKObjectMapping mappingForClass:[RKErrorMessage class]];
    [errorMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:nil toKeyPath:@"errorMessage"]];

    NSMutableIndexSet *errorCodes = [NSMutableIndexSet indexSet];
    [errorCodes addIndexes:RKStatusCodeIndexSetForClass(RKStatusCodeClassClientError)];
    [errorCodes addIndexes:RKStatusCodeIndexSetForClass(RKStatusCodeClassServerError)];
    return [RKResponseDescriptor responseDescriptorWithMapping:errorMapping method:RKHTTPMethodAny pathPattern:nil keyPath:@"errors" statusCodes:errorCodes];
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
    RKObjectResponseSerializer *serializer = [RKObjectResponseSerializer serializer];
    [serializer addResponseDescriptor:[self responseDescriptorForComplexUser]];
    serializer.targetObject = user;
    requestOperation.responseSerializer = serializer;
    [requestOperation start];
    expect([requestOperation isFinished]).will.beTruthy();

    requestOperation.responseObject;

    expect(user.firstname).to.equal(@"Diego");
}

@end
