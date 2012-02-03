//
//  RKInMemoryMappingCache.m
//  RestKit
//
//  Created by Jeff Arena on 1/24/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKInMemoryMappingCache.h"
#import "RKLog.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitCoreData

static NSString* const RKManagedObjectStoreThreadDictionaryEntityCacheKey = @"RKManagedObjectStoreThreadDictionaryEntityCacheKey";

@implementation RKInMemoryMappingCache

@synthesize cache = _cache;

- (id)init {
    self = [super init];
    if (self) {
        _cache = [[RKInMemoryEntityCache alloc] init];
    }
    return self;
}

- (void)dealloc {
    [_cache release];
    _cache = nil;
    [super dealloc];
}

- (NSManagedObject *)findInstanceOfEntity:(NSEntityDescription *)entity
                              withMapping:(RKManagedObjectMapping *)mapping
                       andPrimaryKeyValue:(id)primaryKeyValue
                   inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSAssert(entity, @"Cannot find existing managed object without a target class");
    NSAssert(mapping, @"Cannot find existing managed object instance without mapping");
    NSAssert(mapping.primaryKeyAttribute, @"Cannot find existing managed object instance without mapping that defines a primaryKeyAttribute");
    NSAssert(primaryKeyValue, @"Cannot find existing managed object by primary key without a value");
    NSAssert(managedObjectContext, @"Cannot find existing managed object with a context");
    return [_cache cachedObjectForEntity:entity withMapping:mapping andPrimaryKeyValue:primaryKeyValue inContext:managedObjectContext];
}

@end
