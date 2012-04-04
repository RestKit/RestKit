//
//  RKInMemoryManagedObjectCache.m
//  RestKit
//
//  Created by Jeff Arena on 1/24/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKInMemoryManagedObjectCache.h"
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
    RKInMemoryEntityCache *cache = [contextDictionary objectForKey:hashNumber];
    if (! cache) {
        cache = [[RKInMemoryEntityCache alloc] initWithManagedObjectContext:managedObjectContext];
        [contextDictionary setObject:cache forKey:hashNumber];
        [cache release];
    }
    return [cache cachedObjectForEntity:entity withAttribute:primaryKeyAttribute value:primaryKeyValue inContext:managedObjectContext];
}

@end
