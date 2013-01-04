//
//  RKEntityByAttributeCache.h
//  RestKit
//
//  Created by Blake Watters on 5/1/12.
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

/**
 The `RKEntityByAttributeCache` class provides an in-memory caching mechanism for managed objects instances of an entity in a managed object context with the value of one of the object's attributes acting as the cache key. When loaded, the cache will retrieve all instances of an entity from the store and build a dictionary mapping values for the given cache key attribute to the managed object ID for all objects matching the value. The cache can then be used to quickly retrieve objects by attribute value for the cache key without executing another fetch request against the managed object context. This can provide a large performance improvement when a large number of objects are being retrieved using a particular attribute as the key.

 `RKEntityByAttributeCache` instances are used by the `RKEntityCache` to provide caching for multiple entities at once.

 @bug Please note that the `RKEntityByAttribute` cache is implemented using a `NSFetchRequest` with a result type of `NSDictionaryResultType`. This means that the cache **cannot** load pending object instances via a fetch from the `load` method. Pending objects must be manually added to the cache via `addObject:` if it is desirable for the pending objects to be retrieved by subsequent invocations of `objectWithAttributeValue:inContext:` and `objectsWithAttributeValue:inContext:` prior to a save.

 This is a limitation imposed by Core Data. The dictionary result type implementation is leveraged instead a normal fetch request because it offers very large performance and memory utilization improvements by avoiding construction of managed object instances and faulting.

 @see `RKEntityCache`
 */
@interface RKEntityByAttributeCache : NSObject

///-----------------------
/// @name Creating a Cache
///-----------------------

/**
 Initializes the receiver with a given entity, attribute, and managed object context.

 @param entity The Core Data entity description for the managed objects being cached.
 @param attributeNames An array of attribute names used as the cache keys.
 @param context The managed object context the cache retrieves the cached objects from.
 @return The receiver, initialized with the given entity, attribute, and managed object
    context.
 */
- (id)initWithEntity:(NSEntityDescription *)entity attributes:(NSArray *)attributeNames managedObjectContext:(NSManagedObjectContext *)context;

///-----------------------------
/// @name Getting Cache Identity
///-----------------------------

/**
 The Core Data entity description for the managed objects being cached.
 */
@property (nonatomic, readonly) NSEntityDescription *entity;

/**
 An array of attribute names specifying attributes of the cached entity that act as the cache key.
 */
@property (nonatomic, readonly) NSArray *attributes;

/**
 The managed object context the receiver fetches cached objects from.
 */
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;

/**
 A Boolean value determining if the receiever monitors the managed object context
 for changes and updates the cache entries using the notifications emitted.
 */
@property (nonatomic, assign) BOOL monitorsContextForChanges;

///-------------------------------------
/// @name Loading and Flushing the Cache
///-------------------------------------

/**
 Loads the cache by finding all instances of the configured entity and building
 an association between the value of the cached attribute's value and the
 managed object ID for the object.
 */
- (void)load;

/**
 Flushes the cache by releasing all cache attribute value to managed object ID
 associations.
 */
- (void)flush;

///-----------------------------
/// @name Inspecting Cache State
///-----------------------------

/**
 A Boolean value indicating if the cache has loaded associations between cache attribute values and managed object ID's.
 */
- (BOOL)isLoaded;

/**
 Returns a count of the total number of cached objects.
 */
- (NSUInteger)count;

/**
 Returns the total number of cached objects whose attributes match the values in the given dictionary of attribute values.

 @param attributeValues The value for the cache key attribute to retrieve a count of the objects with a matching value.
 @return The number of objects in the cache with the given value for the cache attribute of the receiver.
 */
- (NSUInteger)countWithAttributeValues:(NSDictionary *)attributeValues;

/**
 Returns the number of unique attribute values contained within the receiver.

 @return The number of unique attribute values within the receiver.
 */
- (NSUInteger)countOfAttributeValues;

/**
 Returns a Boolean value that indicates whether a given object is present
 in the cache.

 @param object An object.
 @return YES if object is present in the cache, otherwise NO.
 */
- (BOOL)containsObject:(NSManagedObject *)object;

/**
 Returns a Boolean value that indicates whether one of more objects is present
 in the cache with a given value of the cache key attribute.

 @param attributeValue The value with which to check the cache for objects with a matching value.
 @return YES if one or more objects with the given value for the cache key attribute is present in the cache, otherwise NO.
 */
- (BOOL)containsObjectWithAttributeValues:(NSDictionary *)attributeValues;

/**
 Returns the first object with a matching value for the cache key attributes in a given managed object context.

 @param attributeValues A value for the cache key attribute.
 @param context The managed object context to retrieve the object from.
 @return An object with the value of attribute matching attributeValue or nil.
 */
- (NSManagedObject *)objectWithAttributeValues:(NSDictionary *)attributeValues inContext:(NSManagedObjectContext *)context;

/**
 Returns the collection of objects with a matching value for the cache key attribute in a given managed object context.

 @param attributeValue A value for the cache key attribute.
 @param context The managed object context to retrieve the objects from.
 @return An array of objects with the value of attribute matching attributeValue or an empty array.
 */
- (NSSet *)objectsWithAttributeValues:(NSDictionary *)attributeValues inContext:(NSManagedObjectContext *)context;

///------------------------------
/// @name Managing Cached Objects
///------------------------------

/**
 Adds a managed object to the cache.

 The object must be an instance of the cached entity.

 @param object The managed object to add to the cache.
 */
- (void)addObject:(NSManagedObject *)object;

/**
 Removes a managed object from the cache.

 The object must be an instance of the cached entity.

 @param object The managed object to remove from the cache.
 */
- (void)removeObject:(NSManagedObject *)object;

@end
