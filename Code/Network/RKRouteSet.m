//
//  RKRouteSet.m
//  RestKit
//
//  Created by Blake Watters on 5/31/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "RKRouteSet.h"
#import "RKPathMatcher.h"

@interface RKRouteSet ()

@property (nonatomic, strong) NSMutableArray *routes;

@end

@implementation RKRouteSet


- (id)init
{
    self = [super init];
    if (self) {
        self.routes = [NSMutableArray array];
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

- (NSArray *)relationshipRoutes
{
    NSMutableArray *routes = [NSMutableArray array];
    for (RKRoute *route in self.routes) {
        if ([route isRelationshipRoute]) [routes addObject:route];
    }

    return [NSArray arrayWithArray:routes];
}

- (void)addRoute:(RKRoute *)route
{
    NSAssert(![self containsRoute:route], @"Cannot add a route that is already added to the router.");
    NSAssert(![route isNamedRoute] || [self routeForName:route.name] == nil, @"Cannot add a route with the same name as an existing route.");
    if ([route isClassRoute]) {
        RKRoute *existingRoute = [self routeForClass:route.objectClass method:route.method];
        NSAssert(existingRoute == nil || (existingRoute.method == RKRequestMethodAny && route.method != RKRequestMethodAny) || (route.method == RKRequestMethodAny && existingRoute.method != RKRequestMethodAny), @"Cannot add a route with the same class and method as an existing route.");
    } else if ([route isRelationshipRoute]) {
        NSArray *routes = [self routesForRelationship:route.name ofClass:route.objectClass];
        for (RKRoute *existingRoute in routes) {
            NSAssert(existingRoute.method != route.method, @"Cannot add a relationship route with the same name and class as an existing route.");
        }
    }
    [self.routes addObject:route];
}

- (void)addRoutes:(NSArray *)routes
{
    for (RKRoute *route in routes) {
        if (! [route isKindOfClass:[RKRoute class]]) [NSException raise:NSInvalidArgumentException format:@"Unexpected object of type `%@` encountered in array of routes.", [route class]];
        [self addRoute:route];
    }
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
        if ([route.objectClass isEqual:objectClass] && (route.method != RKRequestMethodAny && route.method & method)) {
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

- (RKRoute *)routeForRelationship:(NSString *)relationshipName ofClass:(Class)objectClass method:(RKRequestMethod)method
{
    for (RKRoute *route in [self relationshipRoutes]) {
        if ([route.name isEqualToString:relationshipName] && [route.objectClass isEqual:objectClass] && (route.method == method || route.method == RKRequestMethodAny)) {
            return route;
        }
    }

    return nil;
}

- (NSArray *)routesForClass:(Class)objectClass
{
    NSMutableArray *routes = [NSMutableArray array];
    for (RKRoute *route in [self classRoutes]) {
        if ([route.objectClass isEqual:objectClass]) {
            [routes addObject:route];
        }
    }

    return [NSArray arrayWithArray:routes];
}

- (NSArray *)routesForObject:(id)object
{
    NSMutableArray *routes = [NSMutableArray array];
    for (RKRoute *route in [self classRoutes]) {
        if ([object isKindOfClass:route.objectClass]) {
            [routes addObject:route];
        }
    }

    return [NSArray arrayWithArray:routes];
}

- (NSArray *)routesForRelationship:(NSString *)relationshipName ofClass:(Class)objectClass
{
    NSIndexSet *indexes = [self.relationshipRoutes indexesOfObjectsPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [[(RKRoute *)obj objectClass] isEqual:objectClass] && [[(RKRoute *)obj name] isEqualToString:relationshipName];
    }];

    return [self.relationshipRoutes objectsAtIndexes:indexes];
}

- (RKRoute *)routeForObject:(id)object method:(RKRequestMethod)method
{
    Class searchClass = [object class];
    while (searchClass) {
        NSArray *routes = [self routesForClass:searchClass];
        RKRoute *wildcardRoute = nil;
        for (RKRoute *route in routes) {
            if (route.method == RKRequestMethodAny) wildcardRoute = route;
            if (route.method & method) return route;
        }

        if (wildcardRoute) return wildcardRoute;
        searchClass = [searchClass superclass];
    }

    return nil;
}

@end
