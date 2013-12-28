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
    assertThat([router allRoutes], isEmpty());
}

- (void)testAddingRoute
{
    RKRouteSet *router = [RKRouteSet new];
    RKRoute *route = [RKRoute routeWithName:@"test_router" URITemplateString:@"/routes" method:RKHTTPMethodGET];
    [router addRoute:route];
    assertThat([router allRoutes], hasCountOf(1));
}

- (void)testRemovingRoute
{
    RKRouteSet *router = [RKRouteSet new];
    RKRoute *route = [RKRoute routeWithName:@"test_router" URITemplateString:@"/routes" method:RKHTTPMethodGET];
    [router addRoute:route];
    assertThat([router allRoutes], hasCountOf(1));
    [router removeRoute:route];
    assertThat([router allRoutes], hasCountOf(0));
}

- (void)testCannotAddARouteThatIsAlreadyAdded
{
    RKRouteSet *router = [RKRouteSet new];
    RKRoute *route = [RKRoute routeWithName:@"test_router" URITemplateString:@"/routes" method:RKHTTPMethodGET];
    [router addRoute:route];
    STAssertThrowsSpecificNamed([router addRoute:route], NSException, NSInternalInconsistencyException, @"Cannot add a route that is already added to the router.");
}

- (void)testCannotAddARouteWithAnExistingName
{
    RKRouteSet *router = [RKRouteSet new];
    RKRoute *route1 = [RKRoute routeWithName:@"test_router" URITemplateString:@"/routes" method:RKHTTPMethodGET];
    [router addRoute:route1];
    RKRoute *route2 = [RKRoute routeWithName:@"test_router" URITemplateString:@"/routes2" method:RKHTTPMethodGET];
    STAssertThrowsSpecificNamed([router addRoute:route2], NSException, NSInternalInconsistencyException, @"Cannot add a route with the same name as an existing route.");
}

- (void)testCanAddARouteWithAnExistingResourcePathPattern
{
    RKRouteSet *router = [RKRouteSet new];
    RKRoute *route1 = [RKRoute routeWithName:@"test_router" URITemplateString:@"/routes" method:RKHTTPMethodGET];
    [router addRoute:route1];
    RKRoute *route2 = [RKRoute routeWithName:@"test_router2" URITemplateString:@"/routes" method:RKHTTPMethodGET];
    STAssertNoThrowSpecificNamed([router addRoute:route2], NSException, NSInternalInconsistencyException, @"Cannot add a route with the same path pattern as an existing route.");
}

- (void)testCannotAddARouteWithAnExistingObjectClassAndMethod
{
    RKRouteSet *router = [RKRouteSet new];
    RKRoute *routeWithObjectClassAndMethod = [RKRoute routeWithClass:[RKTestUser class] URITemplateString:@"/routes" method:RKHTTPMethodGET];
    RKRoute *routeWithObjectClassAndDifferentMethod = [RKRoute routeWithClass:[RKTestUser class] URITemplateString:@"/routes" method:RKHTTPMethodPOST];
    RKRoute *routeWithObjectClassAndDifferentPath = [RKRoute routeWithClass:[RKTestUser class] URITemplateString:@"/routes2" method:RKHTTPMethodPOST];

    [router addRoute:routeWithObjectClassAndMethod];
    STAssertNoThrowSpecificNamed([router addRoute:routeWithObjectClassAndDifferentMethod], NSException, NSInternalInconsistencyException, @"Cannot add a route with the same class and method as an existing route.");

    STAssertThrowsSpecificNamed([router addRoute:routeWithObjectClassAndDifferentPath], NSException, NSInternalInconsistencyException, @"Cannot add a route with the same class and method as an existing route.");
}

- (void)testCannotAddARouteForAnExistingRelationshipNameAndMethod
{
    RKRouteSet *router = [RKRouteSet new];
    RKRoute *routeWithObjectClassAndMethod = [RKRoute routeWithRelationshipName:@"friends" objectClass:[RKTestUser class] URITemplateString:@"/friends" method:RKHTTPMethodGET];
    RKRoute *routeWithObjectClassAndDifferentMethod = [RKRoute routeWithRelationshipName:@"friends" objectClass:[RKTestUser class] URITemplateString:@"/friends" method:RKHTTPMethodPOST];
    RKRoute *routeWithIdenticalClassAndMethod = [RKRoute routeWithRelationshipName:@"friends" objectClass:[RKTestUser class] URITemplateString:@"/friends" method:RKHTTPMethodGET];

    [router addRoute:routeWithObjectClassAndMethod];
    STAssertNoThrowSpecificNamed([router addRoute:routeWithObjectClassAndDifferentMethod], NSException, NSInternalInconsistencyException, @"Cannot add a relationship route with the same name and class as an existing route.");

    STAssertThrowsSpecificNamed([router addRoute:routeWithIdenticalClassAndMethod], NSException, NSInternalInconsistencyException, @"Cannot add a relationship route with the same name and class as an existing route.");
}

- (void)testCanAddARouteWithAnExistingObjectClassIfMethodIsAny
{
    RKRouteSet *router = [RKRouteSet new];
    RKRoute *route1 = [RKRoute routeWithClass:[RKTestUser class] URITemplateString:@"/routes" method:RKHTTPMethodAny];
    [router addRoute:route1];

    RKRoute *route2 = [RKRoute routeWithClass:[RKTestUser class] URITemplateString:@"/routes" method:RKHTTPMethodPOST];
    STAssertNoThrowSpecificNamed([router addRoute:route2], NSException, NSInternalInconsistencyException, @"Cannot add a route with the same class and method as an existing route.");
}

- (void)testCannotRemoveARouteThatDoesNotExistInRouter
{
    RKRouteSet *router = [RKRouteSet new];
    RKRoute *route = [RKRoute routeWithName:@"fake" URITemplateString:@"whatever" method:RKHTTPMethodGET];
    STAssertThrowsSpecificNamed([router removeRoute:route], NSException, NSInternalInconsistencyException, @"Cannot remove a route that is not added to the router.");
}

- (void)testAllRoutes
{
    RKRouteSet *router = [RKRouteSet new];
    RKRoute *route1 = [RKRoute routeWithName:@"test_router" URITemplateString:@"/routes" method:RKHTTPMethodGET];
    [router addRoute:route1];
    RKRoute *route2 = [RKRoute routeWithName:@"test_router2" URITemplateString:@"/routes2" method:RKHTTPMethodGET];
    [router addRoute:route2];
    assertThat([router allRoutes], contains(route1, route2, nil));
}

- (void)testNamedRoutes
{
    RKRouteSet *router = [RKRouteSet new];
    RKRoute *route1 = [RKRoute routeWithName:@"test_router" URITemplateString:@"/routes" method:RKHTTPMethodGET];
    [router addRoute:route1];
    RKRoute *route2 = [RKRoute routeWithName:@"test_router2" URITemplateString:@"/routes2" method:RKHTTPMethodGET];
    [router addRoute:route2];
    RKRoute *route3 = [RKRoute routeWithClass:[RKTestUser class] URITemplateString:@"/routes2" method:RKHTTPMethodPUT];
    [router addRoute:route3];
    assertThat([router namedRoutes], contains(route1, route2, nil));
}

- (void)testClassRoutes
{
    RKRouteSet *router = [RKRouteSet new];
    RKRoute *route1 = [RKRoute routeWithName:@"test_router" URITemplateString:@"/routes" method:RKHTTPMethodGET];
    [router addRoute:route1];
    RKRoute *route2 = [RKRoute routeWithName:@"test_router2" URITemplateString:@"/routes2" method:RKHTTPMethodGET];
    [router addRoute:route2];
    RKRoute *route3 = [RKRoute routeWithClass:[RKTestUser class] URITemplateString:@"/routes2" method:RKHTTPMethodPUT];
    [router addRoute:route3];
    assertThat([router classRoutes], contains(route3, nil));
}

- (void)testHasRouteForName
{
    RKRouteSet *router = [RKRouteSet new];
    RKRoute *route = [RKRoute routeWithName:@"test_router" URITemplateString:@"/routes" method:RKHTTPMethodGET];
    [router addRoute:route];
    assertThat([router routeForName:@"test_router"], is(notNilValue()));
    assertThat([router routeForName:@"test_router2"], is(nilValue()));
}

- (void)testRouteForName
{
    RKRouteSet *router = [RKRouteSet new];
    RKRoute *route = [RKRoute routeWithName:@"test_router" URITemplateString:@"/routes" method:RKHTTPMethodGET];
    [router addRoute:route];
    assertThat([router routeForName:@"test_router"], is(equalTo(route)));
}

- (void)testAddRouteWithName
{
    RKRouteSet *router = [RKRouteSet new];
    [router addRoute:[RKRoute routeWithName:@"testing" URITemplateString:@"/route" method:RKHTTPMethodGET]];
    RKRoute *route = [router routeForName:@"testing"];
    assertThat(route.name, is(equalTo(@"testing")));
    assertThat(route.URITemplate.templateString, is(equalTo(@"/route")));
    assertThatInteger(route.method, is(equalToInteger(RKHTTPMethodGET)));
}

- (void)testAddRouteWithClassAndMethod
{
    RKRouteSet *router = [RKRouteSet new];
    [router addRoute:[RKRoute routeWithClass:[RKTestUser class] URITemplateString:@"/users/{userID}" method:RKHTTPMethodGET]];
    RKRoute *route = [router routeForClass:[RKTestUser class] method:RKHTTPMethodGET];
    assertThat(route.objectClass, is(equalTo([RKTestUser class])));
    assertThatInteger(route.method, is(equalToInteger(RKHTTPMethodGET)));
}

- (void)testAddRouteWithClass
{
    RKRouteSet *router = [RKRouteSet new];
    [router addRoute:[RKRoute routeWithClass:[RKTestUser class] URITemplateString:@"/users/{userID}" method:RKHTTPMethodAny]];
    RKRoute *route = [router routeForClass:[RKTestUser class] method:RKHTTPMethodGET];
    assertThat(route.objectClass, is(equalTo([RKTestUser class])));
    assertThatInteger(route.method, is(equalToInteger(RKHTTPMethodAny)));
}

- (void)testRetrievingRouteForClassAndMethodWithBitmaskMatch
{
    RKRouteSet *router = [RKRouteSet new];
    [router addRoute:[RKRoute routeWithClass:[RKTestUser class] URITemplateString:@"/users/{userID}" method:RKHTTPMethodHEAD | RKHTTPMethodGET]];
    RKRoute *route = [router routeForClass:[RKTestUser class] method:RKHTTPMethodGET];
    assertThat(route.objectClass, is(equalTo([RKTestUser class])));
    assertThatInteger(route.method, is(equalToInteger(RKHTTPMethodHEAD | RKHTTPMethodGET)));
}

- (void)testRetrievingRouteForClassAndMethodFavorsBitmaskMatchOverWildcard
{
    RKRouteSet *router = [RKRouteSet new];
    [router addRoute:[RKRoute routeWithClass:[RKTestUser class] URITemplateString:@"/users/{userID}/whatever" method:RKHTTPMethodAny]];
    [router addRoute:[RKRoute routeWithClass:[RKTestUser class] URITemplateString:@"/users/{userID}" method:RKHTTPMethodHEAD | RKHTTPMethodGET]];
    RKRoute *route = [router routeForClass:[RKTestUser class] method:RKHTTPMethodGET];
    assertThat(route.objectClass, is(equalTo([RKTestUser class])));
    assertThatInteger(route.method, is(equalToInteger(RKHTTPMethodHEAD | RKHTTPMethodGET)));
}

- (void)testRetrievingRouteForClassAndMethodFavorsExactMatchOverLessSpecificBitmaskMatch
{
    RKRouteSet *router = [RKRouteSet new];
    [router addRoute:[RKRoute routeWithClass:[RKTestUser class] URITemplateString:@"/users/{userID}/whatever" method:RKHTTPMethodAny]];
    RKRoute *expectedRoute = [RKRoute routeWithClass:[RKTestUser class] URITemplateString:@"/users/{userID}" method:RKHTTPMethodPOST];
    [router addRoute:expectedRoute];
    RKRoute *route = [router routeForClass:[RKTestUser class] method:RKHTTPMethodPOST];
    assertThat(route, is(equalTo(expectedRoute)));
}

- (void)testRouteForObjectAndMethodWithExactMatch
{
    RKRouteSet *router = [RKRouteSet new];
    [router addRoute:[RKRoute routeWithClass:[RKTestUser class] URITemplateString:@"/users/{userID}" method:RKHTTPMethodGET]];
    RKTestUser *user = [RKTestUser new];
    RKRoute *route = [router routeForObject:user method:RKHTTPMethodGET];
    assertThat(route, is(notNilValue()));
    assertThat(route.URITemplate.templateString, is(equalTo(@"/users/{userID}")));
    assertThatInteger(route.method, is(equalToInteger(RKHTTPMethodGET)));
}

- (void)testRouteForObjectAndMethodWithSuperclassMatch
{
    RKRouteSet *router = [RKRouteSet new];
    [router addRoute:[RKRoute routeWithClass:[RKTestObject class] URITemplateString:@"/users/{userID}" method:RKHTTPMethodGET]];
    RKTestSubclassedObject *subclassedObject = [RKTestSubclassedObject new];
    RKRoute *route = [router routeForObject:subclassedObject method:RKHTTPMethodGET];
    assertThat(route, is(notNilValue()));
    assertThat(route.URITemplate.templateString, is(equalTo(@"/users/{userID}")));
    assertThat(route.objectClass, is(equalTo([RKTestObject class])));
    assertThatInteger(route.method, is(equalToInteger(RKHTTPMethodGET)));
}

- (void)testRouteForObjectFindsNearestSuperclassMatch
{
    RKRouteSet *router = [RKRouteSet new];
    [router addRoute:[RKRoute routeWithClass:[RKTestObject class] URITemplateString:@"/users/{userID}" method:RKHTTPMethodGET]];
    [router addRoute:[RKRoute routeWithClass:[RKTestSubclassedObject class] URITemplateString:@"/subclasses/users/{userID}" method:RKHTTPMethodGET]];
    [router addRoute:[RKRoute routeWithClass:[RKTestDeeplySubclassedObject class] URITemplateString:@"/deeply/subclassed/users/{userID}" method:RKHTTPMethodGET]];
    RKTestDeeplySubclassedObject *deeplySubclassedObject = [RKTestDeeplySubclassedObject new];
    RKRoute *route = [router routeForObject:deeplySubclassedObject method:RKHTTPMethodGET];
    assertThat(route, is(notNilValue()));
    assertThat(route.URITemplate.templateString, is(equalTo(@"/deeply/subclassed/users/{userID}")));
    assertThat(route.objectClass, is(equalTo([RKTestDeeplySubclassedObject class])));
    assertThatInteger(route.method, is(equalToInteger(RKHTTPMethodGET)));
}

- (void)testRouteForObjectPrefersSuperclassAnyMatchOverDistantParentMethodMatch
{
    RKRouteSet *router = [RKRouteSet new];
    [router addRoute:[RKRoute routeWithClass:[RKTestObject class] URITemplateString:@"/users/{userID}" method:RKHTTPMethodPOST]];
    [router addRoute:[RKRoute routeWithClass:[RKTestSubclassedObject class] URITemplateString:@"/subclasses/users/{userID}" method:RKHTTPMethodAny]];
    [router addRoute:[RKRoute routeWithClass:[RKTestDeeplySubclassedObject class] URITemplateString:@"/deeply/subclassed/users/{userID}" method:RKHTTPMethodGET]];
    RKTestDeeplySubclassedObject *deeplySubclassedObject = [RKTestDeeplySubclassedObject new];
    RKRoute *route = [router routeForObject:deeplySubclassedObject method:RKHTTPMethodPOST];
    assertThat(route, is(notNilValue()));
    assertThat(route.URITemplate.templateString, is(equalTo(@"/subclasses/users/{userID}")));
    assertThat(route.objectClass, is(equalTo([RKTestSubclassedObject class])));
    assertThatInteger(route.method, is(equalToInteger(RKHTTPMethodAny)));
}

- (void)testRetrievingRouteForObjectAndMethodFavorsExactMatchOverLessSpecificBitmaskMatch
{
    RKRouteSet *router = [RKRouteSet new];
    [router addRoute:[RKRoute routeWithClass:[RKTestUser class] URITemplateString:@"/users/{userID}/whatever" method:RKHTTPMethodAny]];
    RKRoute *expectedRoute = [RKRoute routeWithClass:[RKTestUser class] URITemplateString:@"/users/{userID}" method:RKHTTPMethodPOST];
    [router addRoute:expectedRoute];
    RKTestUser *user = [RKTestUser new];
    RKRoute *route = [router routeForObject:user method:RKHTTPMethodPOST];
    assertThat(route, is(equalTo(expectedRoute)));
}

- (void)testRoutesForClassReturnsAllRoutesForClass
{
    RKRouteSet *router = [RKRouteSet new];
    [router addRoute:[RKRoute routeWithClass:[RKTestObject class] URITemplateString:@"/users/{userID}" method:RKHTTPMethodGET]];
    [router addRoute:[RKRoute routeWithClass:[RKTestObject class] URITemplateString:@"/users/{userID}" method:RKHTTPMethodPOST]];
    [router addRoute:[RKRoute routeWithClass:[RKTestSubclassedObject class] URITemplateString:@"/users/{userID}" method:RKHTTPMethodGET]];
    NSArray *routes = [router routesForClass:[RKTestObject class]];
    assertThat(routes, hasCountOf(2));
}

- (void)testRouteForObjectReturnsAllRoutesForClassAndSuperclasses
{
    RKRouteSet *router = [RKRouteSet new];
    [router addRoute:[RKRoute routeWithClass:[RKTestObject class] URITemplateString:@"/users/{userID}" method:RKHTTPMethodGET]];
    [router addRoute:[RKRoute routeWithClass:[RKTestObject class] URITemplateString:@"/users/{userID}" method:RKHTTPMethodPOST]];
    [router addRoute:[RKRoute routeWithClass:[RKTestSubclassedObject class] URITemplateString:@"/users/{userID}" method:RKHTTPMethodGET]];

    RKTestSubclassedObject *subclassed = [RKTestSubclassedObject new];
    NSArray *routes = [router routesForObject:subclassed];
    assertThat(routes, hasCountOf(3));
}

- (void)testRouteForObjectAndMethodFavorsExactMatchOverSuperclass
{
    RKRouteSet *router = [RKRouteSet new];
    [router addRoute:[RKRoute routeWithClass:[RKTestObject class] URITemplateString:@"/users/{userID}/1" method:RKHTTPMethodGET]];
    [router addRoute:[RKRoute routeWithClass:[RKTestObject class] URITemplateString:@"/users/{userID}/2" method:RKHTTPMethodPOST]];
    [router addRoute:[RKRoute routeWithClass:[RKTestSubclassedObject class] URITemplateString:@"/users/{userID}/3" method:RKHTTPMethodGET]];

    RKTestSubclassedObject *subclassed = [RKTestSubclassedObject new];
    RKRoute *route = [router routeForObject:subclassed method:RKHTTPMethodGET];
    assertThat(route.objectClass, is(equalTo([RKTestSubclassedObject class])));
    assertThatInteger(route.method, is(equalToInteger(RKHTTPMethodGET)));
    assertThat(route.URITemplate.templateString, is(equalTo(@"/users/{userID}/3")));
}

- (void)testRouteForObjectAndMethodFavorsWildcardMatchOnExactClassOverSuperclass
{
    RKRouteSet *router = [RKRouteSet new];
    [router addRoute:[RKRoute routeWithClass:[RKTestObject class] URITemplateString:@"/users/{userID}/1" method:RKHTTPMethodGET]];
    [router addRoute:[RKRoute routeWithClass:[RKTestObject class] URITemplateString:@"/users/{userID}/2" method:RKHTTPMethodPOST]];
    [router addRoute:[RKRoute routeWithClass:[RKTestSubclassedObject class] URITemplateString:@"/users/{userID}/3" method:RKHTTPMethodAny]];

    RKTestSubclassedObject *subclassed = [RKTestSubclassedObject new];
    RKRoute *route = [router routeForObject:subclassed method:RKHTTPMethodGET];
    assertThat(route.objectClass, is(equalTo([RKTestSubclassedObject class])));
    assertThatInteger(route.method, is(equalToInteger(RKHTTPMethodAny)));
    assertThat(route.URITemplate.templateString, is(equalTo(@"/users/{userID}/3")));
}

- (void)testRouteForObjectAndMethodFavorsExactSuperclassMethodMatchOverWildcard
{
    RKRouteSet *router = [RKRouteSet new];
    [router addRoute:[RKRoute routeWithClass:[RKTestObject class] URITemplateString:@"/users/{userID}/1" method:RKHTTPMethodGET]];
    [router addRoute:[RKRoute routeWithClass:[RKTestObject class] URITemplateString:@"/users/{userID}/2" method:RKHTTPMethodAny]];

    RKTestSubclassedObject *subclassed = [RKTestSubclassedObject new];
    RKRoute *route = [router routeForObject:subclassed method:RKHTTPMethodGET];
    assertThat(route.objectClass, is(equalTo([RKTestObject class])));
    assertThatInteger(route.method, is(equalToInteger(RKHTTPMethodGET)));
    assertThat(route.URITemplate.templateString, is(equalTo(@"/users/{userID}/1")));
}

- (void)testRouteForObjectAndMethodFavorsExactSuperclassBitmaskMethodMatchOverWildcard
{
    RKRouteSet *router = [RKRouteSet new];
    [router addRoute:[RKRoute routeWithClass:[RKTestObject class] URITemplateString:@"/users/{userID}/1" method:RKHTTPMethodGET | RKHTTPMethodHEAD]];
    [router addRoute:[RKRoute routeWithClass:[RKTestObject class] URITemplateString:@"/users/{userID}/2" method:RKHTTPMethodAny]];
    
    RKTestSubclassedObject *subclassed = [RKTestSubclassedObject new];
    RKRoute *route = [router routeForObject:subclassed method:RKHTTPMethodGET];
    assertThat(route, is(notNilValue()));
    assertThat(route.objectClass, is(equalTo([RKTestObject class])));
    assertThatInteger(route.method, is(equalToInteger(RKHTTPMethodGET | RKHTTPMethodHEAD)));
    assertThat(route.URITemplate.templateString, is(equalTo(@"/users/{userID}/1")));
}

- (void)testRouteForObjectAndMethodFallsBackToSuperclassWildcardMatch
{
    RKRouteSet *router = [RKRouteSet new];
    [router addRoute:[RKRoute routeWithClass:[RKTestObject class] URITemplateString:@"/users/{userID}/1" method:RKHTTPMethodGET]];
    [router addRoute:[RKRoute routeWithClass:[RKTestObject class] URITemplateString:@"/users/{userID}/2" method:RKHTTPMethodAny]];

    RKTestSubclassedObject *subclassed = [RKTestSubclassedObject new];
    RKRoute *route = [router routeForObject:subclassed method:RKHTTPMethodPOST];
    assertThat(route.objectClass, is(equalTo([RKTestObject class])));
    assertThatInteger(route.method, is(equalToInteger(RKHTTPMethodAny)));
    assertThat(route.URITemplate.templateString, is(equalTo(@"/users/{userID}/2")));
}

// TODO: Add tests for superclass match in routeForObject:

- (void)testRouteForRelationshipOfClass
{
    RKRouteSet *router = [RKRouteSet new];
    [router addRoute:[RKRoute routeWithRelationshipName:@"friends" objectClass:[RKTestUser class] URITemplateString:@"/friends" method:RKHTTPMethodGET]];
    RKRoute *route = [router routeForRelationship:@"friends" ofClass:[RKTestUser class] method:RKHTTPMethodGET];
    assertThat(route, is(notNilValue()));
    assertThat(route.name, is(equalTo(@"friends")));
    assertThat(route.URITemplate.templateString, is(equalTo(@"/friends")));
    assertThatInteger(route.method, is(equalToInteger(RKHTTPMethodGET)));
}

- (void)testRouteForRelationshipOfClassWithAny
{
    RKRouteSet *router = [RKRouteSet new];
    [router addRoute:[RKRoute routeWithRelationshipName:@"friends" objectClass:[RKTestUser class] URITemplateString:@"/friends" method:RKHTTPMethodAny]];
    RKRoute *route = [router routeForRelationship:@"friends" ofClass:[RKTestUser class] method:RKHTTPMethodGET];
    assertThat(route, is(notNilValue()));
    assertThat(route.name, is(equalTo(@"friends")));
    assertThat(route.URITemplate.templateString, is(equalTo(@"/friends")));
    assertThatInteger(route.method, is(equalToInteger(RKHTTPMethodAny)));
}

- (void)testRoutesForRelationship
{
    RKRouteSet *router = [RKRouteSet new];
    [router addRoute:[RKRoute routeWithRelationshipName:@"friends" objectClass:[RKTestUser class] URITemplateString:@"/friends" method:RKHTTPMethodGET]];
    [router addRoute:[RKRoute routeWithRelationshipName:@"friends" objectClass:[RKTestUser class] URITemplateString:@"/friends" method:RKHTTPMethodPOST]];
    [router addRoute:[RKRoute routeWithRelationshipName:@"enemies" objectClass:[RKTestUser class] URITemplateString:@"/enemies" method:RKHTTPMethodGET]];

    NSArray *routes = [router routesForRelationship:@"friends" ofClass:[RKTestUser class]];
    assertThat(routes, hasCountOf(2));
}

@end
