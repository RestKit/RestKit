//
//  RKInMemoryManagedObjectCache.m
//  RestKit
//
//  Created by Jeff Arena on 1/24/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKInMemoryManagedObjectCache.h"
#import "NSEntityDescription+RKAdditions.h"
#import "RKEntityCache.h"
#import "RKLog.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitCoreData

static NSString * const RKInMemoryObjectManagedObjectCacheThreadDictionaryKey = @"RKInMemoryObjectManagedObjectCacheThreadDictionaryKey";

@implementation RKInMemoryManagedObjectCache

- (RKEntityCache *)cacheForEntity:(NSEntityDescription *)entity inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    NSAssert(entity, @"Cannot find existing managed object without a target class");
    NSAssert(managedObjectContext, @"Cannot find existing managed object with a context");
    NSMutableDictionary *contextDictionary = [[[NSThread currentThread] threadDictionary] objectForKey:RKInMemoryObjectManagedObjectCacheThreadDictionaryKey];
    if (! contextDictionary) {
        contextDictionary = [NSMutableDictionary dictionaryWithCapacity:1];
        [[[NSThread currentThread] threadDictionary] setObject:contextDictionary forKey:RKInMemoryObjectManagedObjectCacheThreadDictionaryKey];
    }
    NSNumber *hashNumber = [NSNumber numberWithUnsignedInteger:[managedObjectContext hash]];
    RKEntityCache *entityCache = [contextDictionary objectForKey:hashNumber];
    if (! entityCache) {
        RKLogInfo(@"Creating thread-local entity cache for managed object context: %@", managedObjectContext);
        entityCache = [[RKEntityCache alloc] initWithManagedObjectContext:managedObjectContext];
        [contextDictionary setObject:entityCache forKey:hashNumber];
        [entityCache release];
    }

    return entityCache;
}

- (NSManagedObject *)findInstanceOfEntity:(NSEntityDescription *)entity
                  withPrimaryKeyAttribute:(NSString *)primaryKeyAttribute
                                    value:(id)primaryKeyValue
                   inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    RKEntityCache *entityCache = [self cacheForEntity:entity inManagedObjectContext:managedObjectContext];
    if (! [entityCache isEntity:entity cachedByAttribute:primaryKeyAttribute]) {
        RKLogInfo(@"Caching instances of Entity '%@' by primary key attribute '%@'", entity.name, primaryKeyAttribute);
        [entityCache cacheObjectsForEntity:entity byAttribute:primaryKeyAttribute];
        RKEntityByAttributeCache *attributeCache = [entityCache attributeCacheForEntity:entity attribute:primaryKeyAttribute];
        RKLogTrace(@"Cached %ld objects", (long)[attributeCache count]);
    }

    return [entityCache objectForEntity:entity withAttribute:primaryKeyAttribute value:primaryKeyValue];
}

- (void)didFetchObject:(NSManagedObject *)object
{
    RKEntityCache *entityCache = [self cacheForEntity:object.entity inManagedObjectContext:object.managedObjectContext];
    [entityCache addObject:object];
}

- (void)didCreateObject:(NSManagedObject *)object
{
    RKEntityCache *entityCache = [self cacheForEntity:object.entity inManagedObjectContext:object.managedObjectContext];
    [entityCache addObject:object];
}

- (void)didDeleteObject:(NSManagedObject *)object
{
    RKEntityCache *entityCache = [self cacheForEntity:object.entity inManagedObjectContext:object.managedObjectContext];
    [entityCache removeObject:object];
}

@end
