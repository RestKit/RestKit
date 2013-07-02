//
//  RKRouteTest.m
//  RestKit
//
//  Created by Pierre Dulac on 01/07/13.
//  Copyright (c) 2013 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKTestUser.h"
#import "RKRoute.h"

@interface RKRouteTest : RKTestCase
@end

@implementation RKRouteTest

- (void)testCanCreateRouteWithAnExactRequestMethod
{
    STAssertNoThrowSpecificNamed([RKRoute routeWithName:@"test_router" pathPattern:@"/routes" method:RKRequestMethodGET], NSException, NSInvalidArgumentException, @"Cannot create a route with a bitmask request method value.");
}

- (void)testCannotCreateNamedRouteWithRequestMethodAny
{
    STAssertThrowsSpecificNamed([RKRoute routeWithName:@"test_router" pathPattern:@"/routes" method:RKRequestMethodAny], NSException, NSInvalidArgumentException, @"Cannot create a route with a bitmask request method value.");
}

- (void)testCannotCreateRouteWithNameAndBitmaskRequestMethod
{
    STAssertThrowsSpecificNamed([RKRoute routeWithName:@"test_router" pathPattern:@"/routes" method:(RKRequestMethodPOST | RKRequestMethodDELETE)], NSException, NSInvalidArgumentException, @"Cannot create a route with a bitmask request method value.");
}

- (void)testCanCreateRouteForAnObjectExistingClassAndBitmaskRequestMethod
{
    STAssertNoThrowSpecificNamed([RKRoute routeWithClass:[RKTestUser class] pathPattern:@"/routes" method:(RKRequestMethodPOST | RKRequestMethodDELETE)], NSException, NSInvalidArgumentException, @"Cannot create a route with a bitmask request method value.");
}

- (void)testCanCreateRouteForAnExistingRelationshipNamendABitmaskRequestMethod
{
    STAssertNoThrowSpecificNamed([RKRoute routeWithRelationshipName:@"friends" objectClass:[RKTestUser class] pathPattern:@"/friends" method:(RKRequestMethodPOST | RKRequestMethodDELETE)], NSException, NSInvalidArgumentException, @"Cannot create a route with a bitmask request method value.");
}

@end
