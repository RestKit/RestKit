//
//  RKRoute.h
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

#import "RKRequest.h"

/**
 The RKRoute class models a single routable resource path pattern in use by the application. A route
 can be combined with an RKURL base URL and interpolated with an object to produce a new fully hydrated
 URL object. Routes are always instantiated with a resource path pattern and metadata to provide for
 the subsequent identification of the defined route.

 There are three types of routes modeled by the RKRoute class:

    1. Named Routes: A named route represents a single resource path and optional request method within
        the application. The route is not affiliated with any particular class. For example, one might
        define a route with the name `@"airlines_list"` as a GET to /airlines.json
    1. Class Routes: An class route represents a single resource path that is identified by object class
        and request method for which it is appropriate. For example, one might define a route for the class
        `RKArticle` for a POST to /articles.json.
    1. Relationship Routes: A relationship route represents a single resource path through which the relationship
        of a parent object can be manipulated. For example, given an `RKArticle` and `RKComment` class, one
        might define a relationship route for the `RKArticle` class's `@"comments"` relationship as pointing to
        a GET to `@"/articles/:articleID/comments".

 The RKRoute class is internally implemented as a class cluster and is not to be directly instantiated via alloc and
 init.

 @see RKRouter
 @see RKRouteSet
 */
@interface RKRoute : NSObject

/**
 The name of the receiver.

 The name is used to identify named and relationship routes and is nil for object routes.
 */
@property (nonatomic, retain, readonly) NSString *name;

/**
 The object class of the receiver.

 Defines the class for which the route is appropriate. Nil for named routes.
 */
@property (nonatomic, retain, readonly) Class objectClass;

/**
 The request method of the receiver.

 Appropriate for all route types. If the route is appropriate for any HTTP request method,
 then the value RKRequestMethodAny is used.
 */
@property (nonatomic, assign, readonly) RKRequestMethod method;

/**
 The resource path pattern of the receiver.

 A SOCKit pattern that describes the resource path of the route. Required and used by all route types.

 @see SOCPattern
 */
@property (nonatomic, retain, readonly) NSString *resourcePathPattern;

/**
 A Boolean value that determines if the resource path pattern should be escaped when evaluated.

 *Default*: NO
 */
@property (nonatomic, assign) BOOL shouldEscapeResourcePath;

///-----------------------------------------------------------------------------
/// @name Instantiating Routes
///-----------------------------------------------------------------------------

/**
 Creates and returns a new named route object with the given name, resource path pattern and method.

 @param name A unique identifying name for the route.
 @param resourcePathPattern A SOCKit pattern describing the resource path represented by the route.
 @param method The request method of the route.
 @return A new named route object with the given name, resource path pattern and request method.
 */
+ (id)routeWithName:(NSString *)name resourcePathPattern:(NSString *)resourcePathPattern method:(RKRequestMethod)method;

/**
 Creates and returns a new class route object with the given object class, resource path pattern and method.

 @param objectClass The class that is represented by the route.
 @param resourcePathPattern A SOCKit pattern describing the resource path represented by the route.
 @param method The request method of the route.
 @return A new class route object with the given object class, resource path pattern and request method.
 */
+ (id)routeWithClass:(Class)objectClass resourcePathPattern:(NSString *)resourcePathPattern method:(RKRequestMethod)method;

/**
 Creates and returns a new relationship route object with the given relationship name, object class, resource path pattern and method.

 @param relationshipName The name of the relationship represented by the route.
 @param objectClass The class containing the relationship represented by the route.
 @param resourcePathPattern A SOCKit pattern describing the resource path represented by the route.
 @param method The request method of the route.
 @return A new class route object with the given object class, resource path pattern and request method.
 */
+ (id)routeWithRelationshipName:(NSString *)name objectClass:(Class)objectClass resourcePathPattern:(NSString *)resourcePathPattern method:(RKRequestMethod)method;

///-----------------------------------------------------------------------------
/// @name Inspecting Route Types
///-----------------------------------------------------------------------------

/**
 Determines if the receiver is a named route.

 @return YES if the receiver is a named route, else NO.
 */
- (BOOL)isNamedRoute;

/**
 Determines if the receiver is a class route.

 @return YES if the receiver is a class route, else NO.
 */
- (BOOL)isClassRoute;

/**
 Determines if the receiver is a relationship route.

 @return YES if the receiver is a relationship route, else NO.
 */
- (BOOL)isRelationshipRoute;

@end
