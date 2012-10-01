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

//static NSString * const RKInMemoryObjectManagedObjectCacheThreadDictionaryKey = @"RKInMemoryObjectManagedObjectCacheThreadDictionaryKey";

@interface RKInMemoryManagedObjectCache ()
@property (nonatomic, retain) RKEntityCache *entityCache;
@end

@implementation RKInMemoryManagedObjectCache

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    self = [super init];
    if (self) {
        self.entityCache = [[[RKEntityCache alloc] initWithManagedObjectContext:managedObjectContext] autorelease];
    }
    
    return self;
}

- (id)init
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"%@ Failed to call designated initializer. Invoke initWithManagedObjectContext: instead.",
                                           NSStringFromClass([self class])]
                                 userInfo:nil];
}

- (void)dealloc
{
    [_entityCache release];
    [super dealloc];
}

- (NSManagedObject *)findInstanceOfEntity:(NSEntityDescription *)entity
                  withPrimaryKeyAttribute:(NSString *)primaryKeyAttribute
                                    value:(id)primaryKeyValue
                   inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    NSAssert(self.entityCache, @"Entity cache cannot be nil.");
    if (! [self.entityCache isEntity:entity cachedByAttribute:primaryKeyAttribute]) {
        RKLogInfo(@"Caching instances of Entity '%@' by primary key attribute '%@'", entity.name, primaryKeyAttribute);
        [self.entityCache cacheObjectsForEntity:entity byAttribute:primaryKeyAttribute];
        RKEntityByAttributeCache *attributeCache = [self.entityCache attributeCacheForEntity:entity attribute:primaryKeyAttribute];
        RKLogTrace(@"Cached %ld objects", (long)[attributeCache count]);
    }

    return [self.entityCache objectForEntity:entity withAttribute:primaryKeyAttribute value:primaryKeyValue inContext:managedObjectContext];
}

- (NSArray *)findInstancesOfEntity:(NSEntityDescription *)entity
                   withPrimaryKeyAttribute:(NSString *)primaryKeyAttribute
                                     value:(id)primaryKeyValue
                    inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    NSAssert(self.entityCache, @"Entity cache cannot be nil.");
    
    if (! [self.entityCache isEntity:entity cachedByAttribute:primaryKeyAttribute]) {
        RKLogInfo(@"Caching instances of Entity '%@' by primary key attribute '%@'", entity.name, primaryKeyAttribute);
        [self.entityCache cacheObjectsForEntity:entity byAttribute:primaryKeyAttribute];
        RKEntityByAttributeCache *attributeCache = [self.entityCache attributeCacheForEntity:entity attribute:primaryKeyAttribute];
        RKLogTrace(@"Cached %ld objects", (long) [attributeCache count]);
    }

    return [self.entityCache objectsForEntity:entity withAttribute:primaryKeyAttribute value:primaryKeyValue inContext:managedObjectContext];
}

- (void)didFetchObject:(NSManagedObject *)object
{
    [self.entityCache addObject:object];
}

- (void)didCreateObject:(NSManagedObject *)object
{
    [self.entityCache addObject:object];
}

- (void)didDeleteObject:(NSManagedObject *)object
{
    [self.entityCache removeObject:object];
}

@end
