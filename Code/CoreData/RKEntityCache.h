//
//  RKEntityCache.h
//  RestKit
//
//  Created by Blake Watters on 5/2/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <CoreData/CoreData.h>

@class RKEntityByAttributeCache;

/**
 Instances of RKInMemoryEntityCache provide an in-memory caching mechanism for
 objects in a Core Data managed object context. Managed objects can be cached by
 attribute for fast retrieval without repeatedly hitting the Core Data persistent store.
 This can provide a substantial speed advantage over issuing fetch requests
 in cases where repeated look-ups of the same data are performed using a small set
 of attributes as the query key. Internally, the cache entries are maintained as
 references to the NSManagedObjectID of corresponding cached objects.
 */
@interface RKEntityCache : NSObject

///-----------------------------------------------------------------------------
/// @name Initializing the Cache
///-----------------------------------------------------------------------------

/**
 Initializes the receiver with a managed object context containing the entity instances to be cached.

 @param context The managed object context containing objects to be cached.
 @returns self, initialized with context.
 */
- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context;

/**
 The managed object context with which the receiver is associated.
 */
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

///-----------------------------------------------------------------------------
/// @name Caching Objects by Attribute
///-----------------------------------------------------------------------------

/**
 Caches all instances of an entity using the value for an attribute as the cache key.

 @param entity The entity to cache all instances of.
 @param attributeName The attribute to cache the instances by.
 */
- (void)cacheObjectsForEntity:(NSEntityDescription *)entity byAttribute:(NSString *)attributeName;

/**
 Returns a Boolean value indicating if all instances of an entity have been cached by a given attribute name.

 @param entity The entity to check the cache status of.
 @param attributeName The attribute to check the cache status with.
 @return YES if the cache has been loaded with instances with the given attribute, else NO.
 */
- (BOOL)isEntity:(NSEntityDescription *)entity cachedByAttribute:(NSString *)attributeName;

/**
 Retrieves the first cached instance of a given entity where the specified attribute matches the given value.

 @param entity The entity to search the cache for instances of.
 @param attributeName The attribute to search the cache for matches with.
 @param attributeValue The value of the attribute to return a match for.
 @return A matching managed object instance or nil.
 @raise NSInvalidArgumentException Raised if instances of the entity and attribute have not been cached.
 */
- (NSManagedObject *)objectForEntity:(NSEntityDescription *)entity withAttribute:(NSString *)attributeName value:(id)attributeValue;

/**
 Retrieves all cached instances of a given entity where the specified attribute matches the given value.

 @param entity The entity to search the cache for instances of.
 @param attributeName The attribute to search the cache for matches with.
 @param attributeValue The value of the attribute to return a match for.
 @return All matching managed object instances or nil.
 @raise NSInvalidArgumentException Raised if instances of the entity and attribute have not been cached.
 */
- (NSArray *)objectsForEntity:(NSEntityDescription *)entity withAttribute:(NSString *)attributeName value:(id)attributeValue;

///-----------------------------------------------------------------------------
// @name Accessing Underlying Caches
///-----------------------------------------------------------------------------

/**
 Retrieves the underlying entity attribute cache for a given entity and attribute.

 @param entity The entity to retrieve the entity attribute cache object for.
 @param attributeName  The attribute to retrieve the entity attribute cache object for.
 @return The entity attribute cache for the given entity and attribute, or nil if none was found.
 */
- (RKEntityByAttributeCache *)attributeCacheForEntity:(NSEntityDescription *)entity attribute:(NSString *)attributeName;

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
 Flushes the entity cache by sending a flush message to each entity attribute cache
 contained within the receiver.

 @see [RKEntityByAttributeCache flush]
 */
- (void)flush;

/**
 Adds a given object to all entity attribute caches for the object's entity contained
 within the receiver.

 @param object The object to add to the appropriate entity attribute caches.
 */
- (void)addObject:(NSManagedObject *)object;

/**
 Removed a given object from all entity attribute caches for the object's entity contained
 within the receiver.

 @param object The object to remove from the appropriate entity attribute caches.
 */
- (void)removeObject:(NSManagedObject *)object;

@end
