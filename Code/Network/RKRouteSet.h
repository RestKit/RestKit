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

/**
 The `RKRouteSet` class provides for the storage and retrieval of `RKRoute` objects. Route objects are added and removed the route set to manipulate the routing table of the application.

 @see `RKRouter`
 */
@interface RKRouteSet : NSObject

///---------------------------------
/// @name Adding and Removing Routes
///---------------------------------

/**
 Adds a route to the receiver.

 @param route The route to be added.
 @raises NSInvalidArgumentException Raised if the route already exists in the receiver or overlaps an existing name.
 */
- (void)addRoute:(RKRoute *)route;

/**
 Removes a route from the receiver.

 @param route The route to be removed.
 @raises NSInvalidArgumentException Raised if the route does not exist in the receiver.
 */
- (void)removeRoute:(RKRoute *)route;

///---------------------------
/// @name Querying a Route Set
///---------------------------

/**
 Determines if a given route exists within the receiver.

 @param route The route to be tested for containement.
 @return `YES` if the route is contained within the route set, else `NO`.
 */
- (BOOL)containsRoute:(RKRoute *)route;

/**
 Returns all routes from the receiver in an array.

 @return An array containing all the routes in the receiver.
 */
- (NSArray *)allRoutes;

/**
 Returns all named routes from the receiver in an array.

 @return An array containing all the named routes in the receiver.
 */
- (NSArray *)namedRoutes;

/**
 Returns all class routes from the receiver in an array.

 @return An array containing all the class routes in the receiver.
 */
- (NSArray *)classRoutes;

/**
 Returns all relationship routes from the receiver in an array.

 @return An array containing all the relationship routes in the receiver.
 */
- (NSArray *)relationshipRoutes;

/**
 Retrieves a route with the given name.

 @param name The name of the named route to be found.
 @return A route with the given name or nil if none was found.
 */
- (RKRoute *)routeForName:(NSString *)name;

/**
 Retrieves a route for the given object class and request method.

 @param objectClass The object class of the route to be retrieved.
 @param method The request method of the route to be retrieved.
 @return A route with the given object class and method or nil if none was found.
 */
- (RKRoute *)routeForClass:(Class)objectClass method:(RKRequestMethod)method;

/**
 Retrieves a route for a given relationship of a class with a given request method.

 @param relationship The name of the relationship of the route to be retrieved.
 @param method The request method of the route to be retrieved.
 @return A route with the given relationship name, object class and method or nil if none was found.
 */
- (RKRoute *)routeForRelationship:(NSString *)relationship ofClass:(Class)objectClass method:(RKRequestMethod)method;

/**
 Retrieves all class routes with a given object class.

 Class matches are determined by direct comparison of the class objects. The inheritance hierarchy is not consulted.

 @param objectClass The object class of the routes to be retrieved.
 @return An array containing all class routes with the given class.
 */
- (NSArray *)routesForClass:(Class)objectClass;

/**
 Retrieves all object routes for a given object.

 All object routes are searched and returned if they target a class or superclass of the given object (using `- [NSObject isKindOfClass:]`).

 @param object An object for which all object routes are to be retrieved.
 @return An array containing all object routes where the target class is included in the given object's class hierarchy.
 */
- (NSArray *)routesForObject:(id)object;

/**
 Retrieves all routes for a given relationship name and object class.

 @param relationshipName The name of the relationship of the routes to be retrieved.
 @param objectClass The object class of the routes to be retrieved.
 @return An array containing all relationship routes with the given relationship name and object class.
 */
- (NSArray *)routesForRelationship:(NSString *)relationshipName ofClass:(Class)objectClass;

/**
 Retrieves a route for a given object and request method.

 The object routes are first searched for an exact match with the given object's class and request method. If no exact match is found for the given request method, but a route is found for the `RKRequestMethodAny` method, it is returned. If neither are found, the search process begins again and traverses up the inheritance hierarchy.
 */
- (RKRoute *)routeForObject:(id)object method:(RKRequestMethod)method;

@end
