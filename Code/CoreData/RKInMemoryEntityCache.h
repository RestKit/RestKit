//
//  RKInMemoryEntityCache.h
//  RestKit
//
//  Created by Jeff Arena on 1/24/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <CoreData/CoreData.h>

/**
 Instances of RKInMemoryEntityCache provide an in-memory caching mechanism for
 objects in a Core Data managed object context. Managed objects can be cached by
 attribute for fast retrieval without repeatedly hitting the Core Data persistent store.
 This can provide a substantial speed advantage over issuing fetch requests
 in cases where repeated look-ups of the same data are performed using a small set
 of attributes as the query key. Internally, the cache entries are maintained as
 references to the NSManagedObjectID of corresponding cached objects.
 */
@interface RKInMemoryEntityCache : NSObject

/**
 The managed object context from which objects will be cached.
 */
@property(nonatomic, readonly) NSManagedObjectContext *managedObjectContext;

/// @name Initializing the Cache

/**
 Initializes the receiver with a managed object context containing the entity instances to be cached.

 @param context The managed object context containing objects to be cached.
 @returns self, initialized with context.
 */
- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

/// @name Cacheing Objects by Attribute

/**
 Retrieves all objects within the cache
 */
- (NSMutableDictionary *)cachedObjectsForEntity:(NSEntityDescription *)entity
                                    byAttribute:(NSString *)attributeName
                                      inContext:(NSManagedObjectContext *)managedObjectContext;

/**
 */
- (NSManagedObject *)cachedObjectForEntity:(NSEntityDescription *)entity
                             withAttribute:(NSString *)attributeName
                                     value:(id)attributeValue
                                 inContext:(NSManagedObjectContext *)managedObjectContext;

/**
 Caches all instances of an entity in a given managed object context by the value
 */
- (void)cacheObjectsForEntity:(NSEntityDescription *)entity
                  byAttribute:(NSString *)attributeName
                    inContext:(NSManagedObjectContext *)managedObjectContext;

/**
 */
- (void)cacheObject:(NSManagedObject *)managedObject
        byAttribute:(NSString *)attributeName
          inContext:(NSManagedObjectContext *)managedObjectContext;

/**
 */
- (void)cacheObject:(NSEntityDescription *)entity
        byAttribute:(NSString *)attributeName
              value:(id)primaryKeyValue
          inContext:(NSManagedObjectContext *)managedObjectContext;

/**
 */
- (void)expireCacheEntryForObject:(NSManagedObject *)managedObject
                      byAttribute:(NSString *)attributeName
                        inContext:(NSManagedObjectContext *)managedObjectContext;

/**
 */
- (void)expireCacheEntriesForEntity:(NSEntityDescription *)entity;

@end
