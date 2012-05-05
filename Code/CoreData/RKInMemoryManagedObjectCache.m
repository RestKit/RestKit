//
//  RKInMemoryManagedObjectCache.m
//  RestKit
//
//  Created by Jeff Arena on 1/24/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKInMemoryManagedObjectCache.h"
#import "RKEntityCache.h"
#import "RKLog.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitCoreData

static NSString * const RKInMemoryObjectManagedObjectCacheThreadDictionaryKey = @"RKInMemoryObjectManagedObjectCacheThreadDictionaryKey";

@implementation RKInMemoryManagedObjectCache

- (NSManagedObject *)findInstanceOfEntity:(NSEntityDescription *)entity
                  withPrimaryKeyAttribute:(NSString *)primaryKeyAttribute
                                    value:(id)primaryKeyValue
                   inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSAssert(entity, @"Cannot find existing managed object without a target class");
    NSAssert(primaryKeyAttribute, @"Cannot find existing managed object instance without mapping");
    NSAssert(primaryKeyValue, @"Cannot find existing managed object by primary key without a value");
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
    
    if (! [entityCache isEntity:entity cachedByAttribute:primaryKeyAttribute]) {
        RKLogInfo(@"Cacheing instances of Entity '%@' by attribute '%@'", entity.name, primaryKeyAttribute);
        [entityCache cacheObjectsForEntity:entity byAttribute:primaryKeyAttribute];
        RKEntityByAttributeCache *attributeCache = [entityCache attributeCacheForEntity:entity attribute:primaryKeyAttribute];
        RKLogTrace(@"Cached %d objects", [attributeCache count]);
    }
    
    return [entityCache objectForEntity:entity withAttribute:primaryKeyAttribute value:primaryKeyValue];
}

@end
