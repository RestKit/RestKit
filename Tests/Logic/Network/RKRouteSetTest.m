//
//  RKRouteSetTest.m
//  RestKit
//
//  Created by Blake Watters on 5/31/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKRouteSet.h"
#import "RKTestUser.h"

@interface RKTestObject : NSObject
@end

@implementation RKTestObject
@end

@interface RKTestSubclassedObject : RKTestObject
@end
@implementation RKTestSubclassedObject
@end

@interface RKTestDeeplySubclassedObject : RKTestSubclassedObject
@end
@implementation RKTestDeeplySubclassedObject
@end

@interface RKRouteSetTest : RKTestCase
@end

@implementation RKRouteSetTest

- (void)testNewRouterInitializesEmptyRoutesCollection
{
    RKRouteSet *router = [RKRouteSet new];
    assertThat([router allRoutes], is(notNilValue()));
    assertThat([router allRoutes], is(empty()));
}

- (void)testAddingRoute
{
    RKRouteSet *router = [RKRouteSet new];
    RKRoute *route = [RKRoute routeWithName:@"test_router" pathPattern:@"/routes" method:RKRequestMethodAny];
    [router addRoute:route];
    assertThat([router allRoutes], hasCountOf(1));
}

- (void)testRemovingRoute
{
    RKRouteSet *router = [RKRouteSet new];
    RKRoute *route = [RKRoute routeWithName:@"test_router" pathPattern:@"/routes" method:RKRequestMethodAny];
    [router addRoute:route];
    assertThat([router allRoutes], hasCountOf(1));
    [router removeRoute:route];
    assertThat([router allRoutes], hasCountOf(0));
}

- (void)testCannotAddARouteThatIsAlreadyAdded
{
    RKRouteSet *router = [RKRouteSet new];
    RKRoute *route = [RKRoute routeWithName:@"test_router" pathPattern:@"/routes" method:RKRequestMethodAny];
    [router addRoute:route];
    STAssertThrowsSpecificNamed([router addRoute:route], NSException, NSInternalInconsistencyException, @"Cannot add a route that is already added to the router.");
}

- (void)testCannotAddARouteWithAnExistingName
{
    RKRouteSet *router = [RKRouteSet new];
    RKRoute *route1 = [RKRoute routeWithName:@"test_router" pathPattern:@"/routes" method:RKRequestMethodAny];
    [router addRoute:route1];
    RKRoute *route2 = [RKRoute routeWithName:@"test_router" pathPattern:@"/routes2" method:RKRequestMethodAny];
    STAssertThrowsSpecificNamed([router addRoute:route2], NSException, NSInternalInconsistencyException, @"Cannot add a route with the same name as an existing route.");
}

- (void)testCanAddARouteWithAnExistingResourcePathPattern
{
    RKRouteSet *router = [RKRouteSet new];
    RKRoute *route1 = [RKRoute routeWithName:@"test_router" pathPattern:@"/routes" method:RKRequestMethodAny];
    [router addRoute:route1];
    RKRoute *route2 = [RKRoute routeWithName:@"test_router2" pathPattern:@"/routes" method:RKRequestMethodAny];
    STAssertNoThrowSpecificNamed([router addRoute:route2], NSException, NSInternalInconsistencyException, @"Cannot add a route with the same path pattern as an existing route.");
}

- (void)testCannotAddARouteWithAnExistingObjectClassAndMethod
{
    RKRouteSet *router = [RKRouteSet new];
    RKRoute *routeWithObjectClassAndMethod = [RKRoute routeWithClass:[RKTestUser class] pathPattern:@"/routes" method:RKRequestMethodGET];
    RKRoute *routeWithObjectClassAndDifferentMethod = [RKRoute routeWithClass:[RKTestUser class] pathPattern:@"/routes" method:RKRequestMethodPOST];
    RKRoute *routeWithObjectClassAndDifferentPath = [RKRoute routeWithClass:[RKTestUser class] pathPattern:@"/routes2" method:RKRequestMethodPOST];

    [router addRoute:routeWithObjectClassAndMethod];
    STAssertNoThrowSpecificNamed([router addRoute:routeWithObjectClassAndDifferentMethod], NSException, NSInternalInconsistencyException, @"Cannot add a route with the same class and method as an existing route.");

    STAssertThrowsSpecificNamed([router addRoute:routeWithObjectClassAndDifferentPath], NSException, NSInternalInconsistencyException, @"Cannot add a route with the same class and method as an existing route.");
}

- (void)testCannotAddARouteForAnExistingRelationshipNameAndMethod
{
    RKRouteSet *router = [RKRouteSet new];
    RKRoute *routeWithObjectClassAndMethod = [RKRoute routeWithRelationshipName:@"friends" objectClass:[RKTestUser class] pathPattern:@"/friends" method:RKRequestMethodGET];
    RKRoute *routeWithObjectClassAndDifferentMethod = [RKRoute routeWithRelationshipName:@"friends" objectClass:[RKTestUser class] pathPattern:@"/friends" method:RKRequestMethodPOST];
    RKRoute *routeWithIdenticalClassAndMethod = [RKRoute routeWithRelationshipName:@"friends" objectClass:[RKTestUser class] pathPattern:@"/friends" method:RKRequestMethodGET];

    [router addRoute:routeWithObjectClassAndMethod];
    STAssertNoThrowSpecificNamed([router addRoute:routeWithObjectClassAndDifferentMethod], NSException, NSInternalInconsistencyException, @"Cannot add a relationship route with the same name and class as an existing route.");

    STAssertThrowsSpecificNamed([router addRoute:routeWithIdenticalClassAndMethod], NSException, NSInternalInconsistencyException, @"Cannot add a relationship route with the same name and class as an existing route.");
}

- (void)testCanAddARouteWithAnExistingObjectClassIfMethodIsAny
{
    RKRouteSet *router = [RKRouteSet new];
    RKRoute *route1 = [RKRoute routeWithClass:[RKTestUser class] pathPattern:@"/routes" method:RKRequestMethodAny];
    [router addRoute:route1];

    RKRoute *route2 = [RKRoute routeWithClass:[RKTestUser class] pathPattern:@"/routes" method:RKRequestMethodPOST];
    STAssertNoThrowSpecificNamed([router addRoute:route2], NSException, NSInternalInconsistencyException, @"Cannot add a route with the same class and method as an existing route.");
}

- (void)testCannotRemoveARouteThatDoesNotExistInRouter
{
    RKRouteSet *router = [RKRouteSet new];
    RKRoute *route = [RKRoute routeWithName:@"fake" pathPattern:@"whatever" method:RKRequestMethodGET];
    STAssertThrowsSpecificNamed([router removeRoute:route], NSException, NSInternalInconsistencyException, @"Cannot remove a route that is not added to the router.");
}

- (void)testAllRoutes
{
    RKRouteSet *router = [RKRouteSet new];
    RKRoute *route1 = [RKRoute routeWithName:@"test_router" pathPattern:@"/routes" method:RKRequestMethodAny];
    [router addRoute:route1];
    RKRoute *route2 = [RKRoute routeWithName:@"test_router2" pathPattern:@"/routes2" method:RKRequestMethodAny];
    [router addRoute:route2];
    assertThat([router allRoutes], contains(route1, route2, nil));
}

- (void)testNamedRoutes
{
    RKRouteSet *router = [RKRouteSet new];
    RKRoute *route1 = [RKRoute routeWithName:@"test_router" pathPattern:@"/routes" method:RKRequestMethodAny];
    [router addRoute:route1];
    RKRoute *route2 = [RKRoute routeWithName:@"test_router2" pathPattern:@"/routes2" method:RKRequestMethodAny];
    [router addRoute:route2];
    RKRoute *route3 = [RKRoute routeWithClass:[RKTestUser class] pathPattern:@"/routes2" method:RKRequestMethodPUT];
    [router addRoute:route3];
    assertThat([router namedRoutes], contains(route1, route2, nil));
}

- (void)testClassRoutes
{
    RKRouteSet *router = [RKRouteSet new];
    RKRoute *route1 = [RKRoute routeWithName:@"test_router" pathPattern:@"/routes" method:RKRequestMethodAny];
    [router addRoute:route1];
    RKRoute *route2 = [RKRoute routeWithName:@"test_router2" pathPattern:@"/routes2" method:RKRequestMethodAny];
    [router addRoute:route2];
    RKRoute *route3 = [RKRoute routeWithClass:[RKTestUser class] pathPattern:@"/routes2" method:RKRequestMethodPUT];
    [router addRoute:route3];
    assertThat([router classRoutes], contains(route3, nil));
}

- (void)testHasRouteForName
{
    RKRouteSet *router = [RKRouteSet new];
    RKRoute *route = [RKRoute routeWithName:@"test_router" pathPattern:@"/routes" method:RKRequestMethodAny];
    [router addRoute:route];
    assertThat([router routeForName:@"test_router"], is(notNilValue()));
    assertThat([router routeForName:@"test_router2"], is(nilValue()));
}

- (void)testRouteForName
{
    RKRouteSet *router = [RKRouteSet new];
    RKRoute *route = [RKRoute routeWithName:@"test_router" pathPattern:@"/routes" method:RKRequestMethodAny];
    [router addRoute:route];
    assertThat([router routeForName:@"test_router"], is(equalTo(route)));
}

- (void)testAddRouteWithName
{
    RKRouteSet *router = [RKRouteSet new];
    [router addRoute:[RKRoute routeWithName:@"testing" pathPattern:@"/route" method:RKRequestMethodGET]];
    RKRoute *route = [router routeForName:@"testing"];
    assertThat(route.name, is(equalTo(@"testing")));
    assertThat(route.pathPattern, is(equalTo(@"/route")));
    assertThatInteger(route.method, is(equalToInteger(RKRequestMethodGET)));
}

- (void)testAddRouteWithClassAndMethod
{
    RKRouteSet *router = [RKRouteSet new];
    [router addRoute:[RKRoute routeWithClass:[RKTestUser class] pathPattern:@"/users/:userID" method:RKRequestMethodGET]];
    RKRoute *route = [router routeForClass:[RKTestUser class] method:RKRequestMethodGET];
    assertThat(route.objectClass, is(equalTo([RKTestUser class])));
    assertThatInteger(route.method, is(equalToInteger(RKRequestMethodGET)));
}

- (void)testAddRouteWithClass
{
    RKRouteSet *router = [RKRouteSet new];
    [router addRoute:[RKRoute routeWithClass:[RKTestUser class] pathPattern:@"/users/:userID" method:RKRequestMethodAny]];
    RKRoute *route = [router routeForClass:[RKTestUser class] method:RKRequestMethodGET];
    assertThat(route.objectClass, is(equalTo([RKTestUser class])));
    assertThatInteger(route.method, is(equalToInteger(RKRequestMethodAny)));
}

- (void)testRouteForObjectAndMethodWithExactMatch
{
    RKRouteSet *router = [RKRouteSet new];
    [router addRoute:[RKRoute routeWithClass:[RKTestUser class] pathPattern:@"/users/:userID" method:RKRequestMethodGET]];
    RKTestUser *user = [RKTestUser new];
    RKRoute *route = [router routeForObject:user method:RKRequestMethodGET];
    assertThat(route, is(notNilValue()));
    assertThat(route.pathPattern, is(equalTo(@"/users/:userID")));
    assertThatInteger(route.method, is(equalToInteger(RKRequestMethodGET)));
}

- (void)testRouteForObjectAndMethodWithSuperclassMatch
{
    RKRouteSet *router = [RKRouteSet new];
    [router addRoute:[RKRoute routeWithClass:[RKTestObject class] pathPattern:@"/users/:userID" method:RKRequestMethodGET]];
    RKTestSubclassedObject *subclassedObject = [RKTestSubclassedObject new];
    RKRoute *route = [router routeForObject:subclassedObject method:RKRequestMethodGET];
    assertThat(route, is(notNilValue()));
    assertThat(route.pathPattern, is(equalTo(@"/users/:userID")));
    assertThat(route.objectClass, is(equalTo([RKTestObject class])));
    assertThatInteger(route.method, is(equalToInteger(RKRequestMethodGET)));
}

- (void)testRouteForObjectFindsNearestSuperclassMatch
{
    RKRouteSet *router = [RKRouteSet new];
    [router addRoute:[RKRoute routeWithClass:[RKTestObject class] pathPattern:@"/users/:userID" method:RKRequestMethodGET]];
    [router addRoute:[RKRoute routeWithClass:[RKTestSubclassedObject class] pathPattern:@"/subclasses/users/:userID" method:RKRequestMethodGET]];
    [router addRoute:[RKRoute routeWithClass:[RKTestDeeplySubclassedObject class] pathPattern:@"/deeply/subclassed/users/:userID" method:RKRequestMethodGET]];
    RKTestDeeplySubclassedObject *deeplySubclassedObject = [RKTestDeeplySubclassedObject new];
    RKRoute *route = [router routeForObject:deeplySubclassedObject method:RKRequestMethodGET];
    assertThat(route, is(notNilValue()));
    assertThat(route.pathPattern, is(equalTo(@"/deeply/subclassed/users/:userID")));
    assertThat(route.objectClass, is(equalTo([RKTestDeeplySubclassedObject class])));
    assertThatInteger(route.method, is(equalToInteger(RKRequestMethodGET)));
}

- (void)testRouteForObjectPrefersSuperclassAnyMatchOverDistantParentMethodMatch
{
    RKRouteSet *router = [RKRouteSet new];
    [router addRoute:[RKRoute routeWithClass:[RKTestObject class] pathPattern:@"/users/:userID" method:RKRequestMethodPOST]];
    [router addRoute:[RKRoute routeWithClass:[RKTestSubclassedObject class] pathPattern:@"/subclasses/users/:userID" method:RKRequestMethodAny]];
    [router addRoute:[RKRoute routeWithClass:[RKTestDeeplySubclassedObject class] pathPattern:@"/deeply/subclassed/users/:userID" method:RKRequestMethodGET]];
    RKTestDeeplySubclassedObject *deeplySubclassedObject = [RKTestDeeplySubclassedObject new];
    RKRoute *route = [router routeForObject:deeplySubclassedObject method:RKRequestMethodPOST];
    assertThat(route, is(notNilValue()));
    assertThat(route.pathPattern, is(equalTo(@"/subclasses/users/:userID")));
    assertThat(route.objectClass, is(equalTo([RKTestSubclassedObject class])));
    assertThatInteger(route.method, is(equalToInteger(RKRequestMethodAny)));
}

- (void)testRoutesForClassReturnsAllRoutesForClass
{
    RKRouteSet *router = [RKRouteSet new];
    [router addRoute:[RKRoute routeWithClass:[RKTestObject class] pathPattern:@"/users/:userID" method:RKRequestMethodGET]];
    [router addRoute:[RKRoute routeWithClass:[RKTestObject class] pathPattern:@"/users/:userID" method:RKRequestMethodPOST]];
    [router addRoute:[RKRoute routeWithClass:[RKTestSubclassedObject class] pathPattern:@"/users/:userID" method:RKRequestMethodGET]];
    NSArray *routes = [router routesForClass:[RKTestObject class]];
    assertThat(routes, hasCountOf(2));
}

- (void)testRouteForObjectReturnsAllRoutesForClassAndSuperclasses
{
    RKRouteSet *router = [RKRouteSet new];
    [router addRoute:[RKRoute routeWithClass:[RKTestObject class] pathPattern:@"/users/:userID" method:RKRequestMethodGET]];
    [router addRoute:[RKRoute routeWithClass:[RKTestObject class] pathPattern:@"/users/:userID" method:RKRequestMethodPOST]];
    [router addRoute:[RKRoute routeWithClass:[RKTestSubclassedObject class] pathPattern:@"/users/:userID" method:RKRequestMethodGET]];

    RKTestSubclassedObject *subclassed = [RKTestSubclassedObject new];
    NSArray *routes = [router routesForObject:subclassed];
    assertThat(routes, hasCountOf(3));
}

- (void)testRouteForObjectAndMethodFavorsExactMatchOverSuperclass
{
    RKRouteSet *router = [RKRouteSet new];
    [router addRoute:[RKRoute routeWithClass:[RKTestObject class] pathPattern:@"/users/:userID/1" method:RKRequestMethodGET]];
    [router addRoute:[RKRoute routeWithClass:[RKTestObject class] pathPattern:@"/users/:userID/2" method:RKRequestMethodPOST]];
    [router addRoute:[RKRoute routeWithClass:[RKTestSubclassedObject class] pathPattern:@"/users/:userID/3" method:RKRequestMethodGET]];

    RKTestSubclassedObject *subclassed = [RKTestSubclassedObject new];
    RKRoute *route = [router routeForObject:subclassed method:RKRequestMethodGET];
    assertThat(route.objectClass, is(equalTo([RKTestSubclassedObject class])));
    assertThatInteger(route.method, is(equalToInteger(RKRequestMethodGET)));
    assertThat(route.pathPattern, is(equalTo(@"/users/:userID/3")));
}

- (void)testRouteForObjectAndMethodFavorsWildcardMatchOnExactClassOverSuperclass
{
    RKRouteSet *router = [RKRouteSet new];
    [router addRoute:[RKRoute routeWithClass:[RKTestObject class] pathPattern:@"/users/:userID/1" method:RKRequestMethodGET]];
    [router addRoute:[RKRoute routeWithClass:[RKTestObject class] pathPattern:@"/users/:userID/2" method:RKRequestMethodPOST]];
    [router addRoute:[RKRoute routeWithClass:[RKTestSubclassedObject class] pathPattern:@"/users/:userID/3" method:RKRequestMethodAny]];

    RKTestSubclassedObject *subclassed = [RKTestSubclassedObject new];
    RKRoute *route = [router routeForObject:subclassed method:RKRequestMethodGET];
    assertThat(route.objectClass, is(equalTo([RKTestSubclassedObject class])));
    assertThatInteger(route.method, is(equalToInteger(RKRequestMethodAny)));
    assertThat(route.pathPattern, is(equalTo(@"/users/:userID/3")));
}

- (void)testRouteForObjectAndMethodFavorsExactSuperclassMethodMatchOverWildcard
{
    RKRouteSet *router = [RKRouteSet new];
    [router addRoute:[RKRoute routeWithClass:[RKTestObject class] pathPattern:@"/users/:userID/1" method:RKRequestMethodGET]];
    [router addRoute:[RKRoute routeWithClass:[RKTestObject class] pathPattern:@"/users/:userID/2" method:RKRequestMethodAny]];

    RKTestSubclassedObject *subclassed = [RKTestSubclassedObject new];
    RKRoute *route = [router routeForObject:subclassed method:RKRequestMethodGET];
    assertThat(route.objectClass, is(equalTo([RKTestObject class])));
    assertThatInteger(route.method, is(equalToInteger(RKRequestMethodGET)));
    assertThat(route.pathPattern, is(equalTo(@"/users/:userID/1")));
}

- (void)testRouteForObjectAndMethodFallsBackToSuperclassWildcardMatch
{
    RKRouteSet *router = [RKRouteSet new];
    [router addRoute:[RKRoute routeWithClass:[RKTestObject class] pathPattern:@"/users/:userID/1" method:RKRequestMethodGET]];
    [router addRoute:[RKRoute routeWithClass:[RKTestObject class] pathPattern:@"/users/:userID/2" method:RKRequestMethodAny]];

    RKTestSubclassedObject *subclassed = [RKTestSubclassedObject new];
    RKRoute *route = [router routeForObject:subclassed method:RKRequestMethodPOST];
    assertThat(route.objectClass, is(equalTo([RKTestObject class])));
    assertThatInteger(route.method, is(equalToInteger(RKRequestMethodAny)));
    assertThat(route.pathPattern, is(equalTo(@"/users/:userID/2")));
}

//- (void)testResourcePathForObject
//{
//    RKRouter *router = [RKRouter new];
//    [router addRoute:[RKRoute routeWithClass:[RKTestUser class] pathPattern:@"/users/:userID" method:RKRequestMethodAny];
//    RKTestUser *user = [RKTestUser new];
//    user.userID = [NSNumber numberWithInteger:12345];
//    NSString *resourcePath = [router resourcePathForObject:user method:RKRequestMethodGET];
//    assertThat(resourcePath, is(equalTo(@"/users/12345")));
//}
//
//- (void)testResourcePathForRouteNamed
//{
//    RKRouter *router = [RKRouter new];
//    [router addRoute:[RKRoute routeWithName:@"airlines_list" pathPattern:@"/airlines.json"];
//    NSString *resourcePath = [router resourcePathForRouteNamed:@"airlines_list"];
//    assertThat(resourcePath, is(equalTo(@"/airlines.json")));
//}
//
//- (void)testResourcePathForRouteNamedInterpolatedWithObject
//{
//    RKRouter *router = [RKRouter new];
//    [router addRoute:[RKRoute routeWithName:@"user_bookmarks_path" pathPattern:@"/users/:userID/bookmarks"];
//    RKTestUser *user = [RKTestUser new];
//    user.userID = [NSNumber numberWithInteger:12345];
//    NSString *resourcePath = [router resourcePathForRouteNamed:@"user_bookmarks_path" interpolatedWithObject:user];
//    assertThat(resourcePath, is(equalTo(@"/users/12345/bookmarks")));
//}

// TODO: Add tests for superclass match in routeForObject:

- (void)testRouteForRelationshipOfClass
{
    RKRouteSet *router = [RKRouteSet new];
    [router addRoute:[RKRoute routeWithRelationshipName:@"friends" objectClass:[RKTestUser class] pathPattern:@"/friends" method:RKRequestMethodGET]];
    RKRoute *route = [router routeForRelationship:@"friends" ofClass:[RKTestUser class] method:RKRequestMethodGET];
    assertThat(route, is(notNilValue()));
    assertThat(route.name, is(equalTo(@"friends")));
    assertThat(route.pathPattern, is(equalTo(@"/friends")));
    assertThatInteger(route.method, is(equalToInteger(RKRequestMethodGET)));
}

- (void)testRoutesForRelationship
{
    RKRouteSet *router = [RKRouteSet new];
    [router addRoute:[RKRoute routeWithRelationshipName:@"friends" objectClass:[RKTestUser class] pathPattern:@"/friends" method:RKRequestMethodGET]];
    [router addRoute:[RKRoute routeWithRelationshipName:@"friends" objectClass:[RKTestUser class] pathPattern:@"/friends" method:RKRequestMethodPOST]];
    [router addRoute:[RKRoute routeWithRelationshipName:@"enemies" objectClass:[RKTestUser class] pathPattern:@"/enemies" method:RKRequestMethodGET]];

    NSArray *routes = [router routesForRelationship:@"friends" ofClass:[RKTestUser class]];
    assertThat(routes, hasCountOf(2));
}

@end
