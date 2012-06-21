//
//  RKRouteSet.h
//  RestKit
//
//  Created by Blake Watters on 5/31/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKRoute.h"

// Wildcard matches on objects
extern RKRequestMethod const RKRequestMethodAny;

@interface RKRouteSet : NSObject

- (NSArray *)allRoutes;
- (NSArray *)namedRoutes;
- (NSArray *)classRoutes;
- (NSArray *)relationshipRoutes;

- (void)addRoute:(RKRoute *)route;
- (void)removeRoute:(RKRoute *)route;
- (BOOL)containsRoute:(RKRoute *)route;

- (RKRoute *)routeForName:(NSString *)name;
- (RKRoute *)routeForClass:(Class)objectClass method:(RKRequestMethod)method;
- (RKRoute *)routeForRelationship:(NSString *)relationship ofClass:(Class)objectClass method:(RKRequestMethod)method;

- (NSArray *)routesForClass:(Class)objectClass; // routes specifically for the class
- (NSArray *)routesForObject:(id)object; // routes for class and superclasses
- (NSArray *)routesForRelationship:(NSString *)relationshipName ofClass:(Class)objectClass;

// NOTE: Will return an exact match for the object class and then
// search for a superclass match
- (RKRoute *)routeForObject:(id)object method:(RKRequestMethod)method;
- (NSArray *)routesWithResourcePathPattern:(NSString *)resourcePathPattern;

@end
