//
//  RKRouteSet.h
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
