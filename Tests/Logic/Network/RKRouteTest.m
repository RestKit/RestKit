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
    STAssertNoThrowSpecificNamed([RKRoute routeWithName:@"test_router" URITemplateString:@"/routes" method:RKHTTPMethodGET], NSException, NSInvalidArgumentException, @"Cannot create a route with a bitmask request method value.");
}

- (void)testCannotCreateNamedRouteWithRequestMethodAny
{
    STAssertThrowsSpecificNamed([RKRoute routeWithName:@"test_router" URITemplateString:@"/routes" method:RKHTTPMethodAny], NSException, NSInvalidArgumentException, @"Cannot create a route with a bitmask request method value.");
}

- (void)testCannotCreateRouteWithNameAndBitmaskRequestMethod
{
    STAssertThrowsSpecificNamed([RKRoute routeWithName:@"test_router" URITemplateString:@"/routes" method:(RKHTTPMethodPOST | RKHTTPMethodDELETE)], NSException, NSInvalidArgumentException, @"Cannot create a route with a bitmask request method value.");
}

- (void)testCanCreateRouteForAnObjectExistingClassAndBitmaskRequestMethod
{
    STAssertNoThrowSpecificNamed([RKRoute routeWithClass:[RKTestUser class] URITemplateString:@"/routes" method:(RKHTTPMethodPOST | RKHTTPMethodDELETE)], NSException, NSInvalidArgumentException, @"Cannot create a route with a bitmask request method value.");
}

- (void)testCanCreateRouteForAnExistingRelationshipNamendABitmaskRequestMethod
{
    STAssertNoThrowSpecificNamed([RKRoute routeWithRelationshipName:@"friends" objectClass:[RKTestUser class] URITemplateString:@"/friends" method:(RKHTTPMethodPOST | RKHTTPMethodDELETE)], NSException, NSInvalidArgumentException, @"Cannot create a route with a bitmask request method value.");
}

@end
