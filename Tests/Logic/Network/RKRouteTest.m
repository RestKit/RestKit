//
//  RKRouteTest.m
//  RestKit
//
//  Created by Pierre Dulac on 01/07/13.
//  Copyright (c) 2013 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKRoute.h"

@interface RKRouteTest : RKTestCase
@end

@implementation RKRouteTest

- (void)testCanCreateRouteWithAnExactRequestMethod
{
    STAssertNoThrowSpecificNamed([RKRoute routeWithName:@"test_router" pathPattern:@"/routes" method:RKRequestMethodGET], NSException, NSInvalidArgumentException, @"Cannot create a route with a bitmask request method value.");
}

- (void)testCannotCreateRouteWithABitmaskRequestMethod
{
    STAssertThrowsSpecificNamed([RKRoute routeWithName:@"test_router" pathPattern:@"/routes" method:(RKRequestMethodPOST | RKRequestMethodDELETE)], NSException, NSInvalidArgumentException, @"Cannot create a route with a bitmask request method value.");
}

@end
