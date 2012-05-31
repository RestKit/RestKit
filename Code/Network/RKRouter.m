//
//  RKRouter.m
//  RestKit
//
//  Created by Blake Watters on 5/31/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKRouter.h"
#import "RKPathMatcher.h"

RKRequestMethod const RKRequestMethodAny = RKRequestMethodInvalid;

@interface RKRouter ()

@property (nonatomic, retain) NSMutableArray *routes;

@end

@implementation RKRouter

@synthesize routes = _routes;

- (id)init
{
    self = [super init];
    if (self) {
        _routes = [NSMutableArray new];
    }

    return self;
}

- (NSArray *)allRoutes
{
    return [NSArray arrayWithArray:self.routes];
}

- (NSArray *)namedRoutes
{
    NSMutableArray *routes = [NSMutableArray array];
    for (RKRoute *route in self.routes) {
        if ([route isNamedRoute]) [routes addObject:route];
    }

    return [NSArray arrayWithArray:routes];
}

- (NSArray *)classRoutes
{
    NSMutableArray *routes = [NSMutableArray array];
    for (RKRoute *route in self.routes) {
        if ([route isClassRoute]) [routes addObject:route];
    }

    return [NSArray arrayWithArray:routes];
}

- (void)addRoute:(RKRoute *)route
{
    NSAssert([route isNamedRoute] || [route isClassRoute], @"A route must have either a name or a target class.");
    NSAssert([route.resourcePathPattern length] > 0, @"A route must have a resource path pattern.");
    NSAssert(![self containsRoute:route], @"Cannot add a route that is already added to the router.");
    NSAssert(![route isNamedRoute] || ![self containsRouteForName:route.name], @"Cannot add a route with the same name as an existing route.");
    if ([route isClassRoute]) {
        RKRoute *existingRoute = [self routeForClass:route.objectClass method:route.method];
        NSAssert(existingRoute == nil || (existingRoute.method == RKRequestMethodAny && route.method != RKRequestMethodAny), @"Cannot add a route with the same class and method as an existing route.");
    }
    [self.routes addObject:route];
}

- (void)removeRoute:(RKRoute *)route
{
    NSAssert([self containsRoute:route], @"Cannot remove a route that is not added to the router.");
    [self.routes removeObject:route];
}

- (BOOL)containsRoute:(RKRoute *)route
{
    return [self.routes containsObject:route];
}

- (BOOL)containsRouteForName:(NSString *)name
{
    return [[self.routes valueForKey:@"name"] containsObject:name];
}

- (BOOL)containsRouteForResourcePathPattern:(NSString *)resourcePathPattern
{
    return [[self.routes valueForKey:@"resourcePathPattern"] containsObject:resourcePathPattern];
}

- (BOOL)containsRouteForClass:(Class)objectClass method:(RKRequestMethod)method
{
    return [self routeForClass:objectClass method:method] != nil;
}

- (RKRoute *)routeForName:(NSString *)name
{
    for (RKRoute *route in [self namedRoutes]) {
        if ([route.name isEqualToString:name]) {
            return route;
        }
    }

    return nil;
}

- (RKRoute *)routeForClass:(Class)objectClass method:(RKRequestMethod)method
{
    // Check for an exact match
    for (RKRoute *route in [self classRoutes]) {
        if ([route.objectClass isEqual:objectClass] && route.method == method) {
            return route;
        }
    }

    // Check for wildcard match
    for (RKRoute *route in [self classRoutes]) {
        if ([route.objectClass isEqual:objectClass] && route.method == RKRequestMethodAny) {
            return route;
        }
    }

    return nil;
}

- (NSArray *)routesForClass:(Class)objectClass
{
    NSMutableArray *routes = [NSMutableArray new];
    for (RKRoute *route in [self classRoutes]) {
        if ([route.objectClass isEqual:objectClass]) {
            [routes addObject:route];
        }
    }

    return [NSArray arrayWithArray:routes];
}

- (NSArray *)routesForObject:(id)object
{
    NSMutableArray *routes = [NSMutableArray new];
    for (RKRoute *route in [self classRoutes]) {
        if ([object isKindOfClass:route.objectClass]) {
            [routes addObject:route];
        }
    }

    return [NSArray arrayWithArray:routes];
}

- (RKRoute *)routeForObject:(id)object method:(RKRequestMethod)method
{
    NSArray *routesForObject = [self routesForObject:object];
    RKRoute *bestMatch = nil;
    for (RKRoute *route in routesForObject) {
        if ([object isMemberOfClass:[route objectClass]] && route.method == method) {
            // Exact match
            return route;
        } else if ([object isMemberOfClass:[route objectClass]] && route.method == RKRequestMethodAny) {
            bestMatch = route;
        }
    }

    if (bestMatch) return bestMatch;

    for (RKRoute *route in routesForObject) {
        if ([object isKindOfClass:[route objectClass]] && route.method == method) {
            // Superclass match with exact route
            return route;
        } else if ([object isKindOfClass:[route objectClass]] && route.method == RKRequestMethodAny) {
            bestMatch = route;
        }
    }

    return bestMatch;
}

- (NSArray *)routesForResourcePathPattern:(NSString *)resourcePathPattern
{
    NSMutableArray *routes = [NSMutableArray array];
    for (RKRoute *route in self.routes) {
        if ([route.resourcePathPattern isEqualToString:resourcePathPattern]) {
            [routes addObject:route];
        }
    }

    return [NSArray arrayWithArray:routes];
}

- (void)addRouteWithName:(NSString *)name resourcePathPattern:(NSString *)resourcePathPattern
{
    RKRoute *route = [[RKRoute new] autorelease];
    route.name = name;
    route.resourcePathPattern = resourcePathPattern;
    [self addRoute:route];
}

- (void)addRouteWithClass:(Class)objectClass resourcePathPattern:(NSString *)resourcePathPattern method:(RKRequestMethod)method
{
    RKRoute *route = [[RKRoute new] autorelease];
    route.objectClass = objectClass;
    route.resourcePathPattern = resourcePathPattern;
    route.method = method;
    [self addRoute:route];
}

- (void)addRouteWithClass:(Class)objectClass resourcePathPattern:(NSString *)resourcePathPattern
{
    [self addRouteWithClass:objectClass resourcePathPattern:resourcePathPattern method:RKRequestMethodAny];
}

- (NSString *)resourcePathForObject:(id)object method:(RKRequestMethod)method
{
    RKRoute *route = [self routeForObject:object method:method];
    RKPathMatcher *matcher = [RKPathMatcher matcherWithPattern:route.resourcePathPattern];
    return [matcher pathFromObject:object addingEscapes:route.shouldEscapeResourcePath];
}

- (NSString *)resourcePathForRouteNamed:(NSString *)routeName
{
    return [self resourcePathForRouteNamed:routeName interpolatedWithObject:nil];
}

- (NSString *)resourcePathForRouteNamed:(NSString *)routeName interpolatedWithObject:(id)object
{
    RKRoute *route = [self routeForName:routeName];
    if (object) {
        RKPathMatcher *matcher = [RKPathMatcher matcherWithPattern:route.resourcePathPattern];
        return [matcher pathFromObject:object addingEscapes:route.shouldEscapeResourcePath];
    }

    return route.resourcePathPattern;
}

@end
