//
//  RKRouter.h
//  RestKit
//
//  Created by Blake Watters on 5/31/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKRoute.h"

// Wildcard matches on objects
extern RKRequestMethod const RKRequestMethodAny;

@interface RKRouter : NSObject

- (NSArray *)allRoutes;
- (NSArray *)namedRoutes;
- (NSArray *)classRoutes;

- (void)addRoute:(RKRoute *)route;
- (void)removeRoute:(RKRoute *)route;

- (BOOL)containsRoute:(RKRoute *)route;
- (BOOL)containsRouteForName:(NSString *)name;
- (BOOL)containsRouteForResourcePathPattern:(NSString *)resourcePathPattern;
- (BOOL)containsRouteForClass:(Class)objectClass method:(RKRequestMethod)method;

- (RKRoute *)routeForName:(NSString *)name;
- (RKRoute *)routeForClass:(Class)objectClass method:(RKRequestMethod)method;

- (NSArray *)routesForClass:(Class)objectClass; // routes specifically for the class
- (NSArray *)routesForObject:(id)object; // routes for class and superclasses
// NOTE: Will return an exact match for the object class and then
// search for a superclass match
- (RKRoute *)routeForObject:(id)object method:(RKRequestMethod)method;
- (NSArray *)routesForResourcePathPattern:(NSString *)resourcePathPattern;

// Convenience methods

- (void)addRouteWithName:(NSString *)name resourcePathPattern:(NSString *)resourcePathPattern;
- (void)addRouteWithClass:(Class)objectClass resourcePathPattern:(NSString *)resourcePathPattern method:(RKRequestMethod)method;
- (void)addRouteWithClass:(Class)objectClass resourcePathPattern:(NSString *)resourcePathPattern;

- (NSString *)resourcePathForObject:(id)object method:(RKRequestMethod)method;
- (NSString *)resourcePathForRouteNamed:(NSString *)routeName;
- (NSString *)resourcePathForRouteNamed:(NSString *)routeName interpolatedWithObject:(id)object;

@end
