//
//  RKTestHelpers.h
//  RestKit
//
//  Created by Blake Watters on 10/2/12.
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

#import <Foundation/Foundation.h>
#import "RKHTTPUtilities.h"

@class RKRoute, RKObjectManager;

/**
 The `RKTestHelpers` class provides a number of helpful utility methods for use in unit or integration tests for RestKit applications.
 */
@interface RKTestHelpers : NSObject

///----------------------
/// @name Stubbing Routes
///----------------------

/**
 Stubs the route with the given class and method with a given path pattern.
 
 @param objectClass The class of the route to stub.
 @param method The method of the route to stub.
 @param pathPattern The path pattern to return instead in place of the current route's value.
 @param nilOrObjectManager The object manager to stub the route on. If `nil`, the shared object manager be be used.
 @return The new stubbed route object that was added to the route set of the target object manager.
 */
+ (RKRoute *)stubRouteForClass:(Class)objectClass
                        method:(RKRequestMethod)method
               withPathPattern:(NSString *)pathPattern
               onObjectManager:(RKObjectManager *)nilOrObjectManager;

/**
 Stubs the route with the given name with a given path pattern.
 
 @param routeName The name of the route to stub.
 @param pathPattern The path pattern to return instead in place of the current route's value.
 @param nilOrObjectManager The object manager to stub the route on. If `nil`, the shared object manager be be used.
 @return The new stubbed route object that was added to the route set of the target object manager.
 */
+ (RKRoute *)stubRouteNamed:(NSString *)routeName
            withPathPattern:(NSString *)pathPattern
            onObjectManager:(RKObjectManager *)nilOrObjectManager;

/**
 Stubs the relationship route for a given class with a given path pattern.
 
 @param relationshipName The name of the relationship to stub the route of.
 @param objectClass The class of the route to stub.
 @param pathPattern The path pattern to return instead in place of the current route's value.
 @param nilOrObjectManager The object manager to stub the route on. If `nil`, the shared object manager be be used.
 @return The new stubbed route object that was added to the route set of the target object manager.
 */
+ (RKRoute *)stubRouteForRelationship:(NSString *)relationshipName
                              ofClass:(Class)objectClass
                          pathPattern:(NSString *)pathPattern
                      onObjectManager:(RKObjectManager *)nilOrObjectManager;

/**
 Finds all registered fetch request blocks matching the given path pattern and adds a new fetch request block that returns the same value as the origin block that matches the given relative string portion of a URL object.
 
 @param pathPattern The path pattern that matches the fetch request blocks to be copied.
 @param relativeString The relative string portion of the NSURL objects that the new blocks will match exactly.
 @param nilOrObjectManager The object manager to stub the route on. If `nil`, the shared object manager be be used.
 */
+ (void)copyFetchRequestBlocksMatchingPathPattern:(NSString *)pathPattern
                   toBlocksMatchingRelativeString:(NSString *)relativeString
                      onObjectManager:(RKObjectManager *)nilOrObjectManager;

///-------------------------------
/// @name Clearing the NSURL Cache
///-------------------------------

/**
 Clears the contents of the cache directory by removing the directory and recreating it.
 
 This has the effect of clearing any `NSCachedURLResponse` objects stored by `NSURLCache` as well as any application specific cache data.
 
 @see `RKCachesDirectory()`
 */
+ (void)clearCacheDirectory;

@end
