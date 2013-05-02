//
//  RKEntityCache.h
//  RestKit
//
//  Created by Blake Watters on 5/2/12.
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

#import <CoreData/CoreData.h>

@class RKEntityByAttributeCache;

/**
 Instances of `RKEntityCache` provide an in-memory caching mechanism for objects in a Core Data managed object context. Managed objects can be cached by attribute for fast retrieval without repeatedly hitting the Core Data persistent store. This can provide a substantial speed advantage over issuing fetch requests in cases where repeated look-ups of the same data are performed using a small set of attributes as the query key. Internally, the cache entries are maintained as references to the `NSManagedObjectID` of corresponding cached objects.
 */
@interface RKEntityCache : NSObject

///-----------------------------
/// @name Initializing the Cache
///-----------------------------

/**
 Initializes the receiver with a managed object context containing the entity instances to be cached.

 @param context The managed object context containing objects to be cached.
 @returns The receiver, initialized with the given context.
 */
- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context;

/**
 The managed object context with which the receiver is associated.
 */
@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;

///-------------------------------------
/// @name Configuring the Callback Queue
///-------------------------------------

/**
 The queue on which to dispatch callbacks for asynchronous operations. When `nil`, the main queue is used.
 
 **Default**: `nil`
 */
@property (nonatomic, assign) dispatch_queue_t callbackQueue;

///------------------------------------
/// @name Caching Objects by Attributes
///------------------------------------

/**
 Caches all instances of an entity using the value for an attribute as the cache key.

 @param entity The entity to cache all instances of.
 @param attributeNames The attributes to cache the instances by.
 */
- (void)cacheObjectsForEntity:(NSEntityDescription *)entity byAttributes:(NSArray *)attributeNames completion:(void (^)(void))completion;

/**
 Returns a Boolean value indicating if all instances of an entity have been cached by a given attribute name.

 @param entity The entity to check the cache status of.
 @param attributeNames The attributes to check the cache status with.
 @return YES if the cache has been loaded with instances with the given attribute, else NO.
 */
- (BOOL)isEntity:(NSEntityDescription *)entity cachedByAttributes:(NSArray *)attributeNames;

/**
 Retrieves the first cached instance of a given entity where the specified attribute matches the given value.

 @param entity The entity to search the cache for instances of.
 @param attributeValues The attribute values return a match for.
 @param context The managed object from which to retrieve the cached results.
 @return A matching managed object instance or nil.
 @raise NSInvalidArgumentException Raised if instances of the entity and attribute have not been cached.
 */
- (NSManagedObject *)objectForEntity:(NSEntityDescription *)entity withAttributeValues:(NSDictionary *)attributeValues inContext:(NSManagedObjectContext *)context;

/**
 Retrieves all cached instances of a given entity where the specified attribute matches the given value.

 @param entity The entity to search the cache for instances of.
 @param attributeValues The attribute values return a match for.
 @param context The managed object from which to retrieve the cached results.
 @return All matching managed object instances or nil.
 @raise NSInvalidArgumentException Raised if instances of the entity and attribute have not been cached.
 */
- (NSSet *)objectsForEntity:(NSEntityDescription *)entity withAttributeValues:(NSDictionary *)attributeValues inContext:(NSManagedObjectContext *)context;

///-----------------------------------------------------------------------------
// @name Accessing Underlying Caches
///-----------------------------------------------------------------------------

/**
 Retrieves the underlying entity attribute cache for a given entity and attribute.

 @param entity The entity to retrieve the entity attribute cache object for.
 @param attributeName  The attribute to retrieve the entity attribute cache object for.
 @return The entity attribute cache for the given entity and attribute, or nil if none was found.
 */
- (RKEntityByAttributeCache *)attributeCacheForEntity:(NSEntityDescription *)entity attributes:(NSArray *)attributeNames;

/**
 Retrieves all entity attributes caches for a given entity.

 @param entity The entity to retrieve the collection of entity attribute caches for.
 @return An array of entity attribute cache objects for the given entity or an empty array if none were found.
 */
- (NSArray *)attributeCachesForEntity:(NSEntityDescription *)entity;

///-----------------------------------------------------------------------------
// @name Managing the Cache
///-----------------------------------------------------------------------------

/**
 Flushes the entity cache by sending a flush message to each entity attribute cache contained within the receiver.

 @param completion An optional block to be executed when the flush has completed.
 @see [RKEntityByAttributeCache flush]
 */
- (void)flush:(void (^)(void))completion;

/**
 Adds the given set of objects to all entity attribute caches for the object's entity contained within the receiver.

 @param objects The set of objects to add to the appropriate entity attribute caches.
 @param completion An optional block to be executed when the object addition has completed.
 */
- (void)addObjects:(NSSet *)objects completion:(void (^)(void))completion;

/**
 Removes the given set of objects from all entity attribute caches for the object's entity contained within the receiver.

 @param objects The set of objects to remove from the appropriate entity attribute caches.
 @param completion An optional block to be executed when the object removal has completed.
 */
- (void)removeObjects:(NSSet *)objects completion:(void (^)(void))completion;

/**
 Returns a Boolean value that indicates if the receiver contains the given object in any of its attribute caches.
 
 @param managedObject The object to check for.
 @return `YES` if the receiver contains the given object in one or more of its caches, else `NO`.
 */
- (BOOL)containsObject:(NSManagedObject *)managedObject;

@end

// Deprecated in v0.20.1
@interface RKEntityCache (Deprecations)
- (void)addObject:(NSManagedObject *)object DEPRECATED_ATTRIBUTE; // use `addObjects:completion:`
- (void)removeObject:(NSManagedObject *)object DEPRECATED_ATTRIBUTE; // use `removeObjects:completion:`
@end
