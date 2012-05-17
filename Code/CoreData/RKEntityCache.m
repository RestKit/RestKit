//
//  RKEntityCache.m
//  RestKit
//
//  Created by Blake Watters on 5/2/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKEntityCache.h"
#import "RKEntityByAttributeCache.h"

@interface RKEntityCache ()
@property (nonatomic, retain) NSMutableSet *attributeCaches;
@end

@implementation RKEntityCache

@synthesize managedObjectContext = _managedObjectContext;
@synthesize attributeCaches = _attributeCaches;

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context
{
    NSAssert(context, @"Cannot initialize entity cache with a nil context");
    self = [super init];
    if (self) {
        _managedObjectContext = [context retain];
        _attributeCaches = [[NSMutableSet alloc] init];
    }

    return self;
}

- (id)init
{
    return [self initWithManagedObjectContext:nil];
}

- (void)dealloc
{
    [_managedObjectContext release];
    [_attributeCaches release];
    [super dealloc];
}

- (void)cacheObjectsForEntity:(NSEntityDescription *)entity byAttribute:(NSString *)attributeName
{
    NSAssert(entity, @"Cannot cache objects for a nil entity");
    NSAssert(attributeName, @"Cannot cache objects without an attribute");
    RKEntityByAttributeCache *attributeCache = [self attributeCacheForEntity:entity attribute:attributeName];
    if (attributeCache && !attributeCache.isLoaded) {
        [attributeCache load];
    } else {
        attributeCache = [[RKEntityByAttributeCache alloc] initWithEntity:entity attribute:attributeName managedObjectContext:self.managedObjectContext];
        [attributeCache load];
        [self.attributeCaches addObject:attributeCache];
        [attributeCache release];
    }
}

- (BOOL)isEntity:(NSEntityDescription *)entity cachedByAttribute:(NSString *)attributeName
{
    NSAssert(entity, @"Cannot check cache status for a nil entity");
    NSAssert(attributeName, @"Cannot check cache status for a nil attribute");
    RKEntityByAttributeCache *attributeCache = [self attributeCacheForEntity:entity attribute:attributeName];
    return (attributeCache && attributeCache.isLoaded);
}

- (NSManagedObject *)objectForEntity:(NSEntityDescription *)entity withAttribute:(NSString *)attributeName value:(id)attributeValue
{
    NSAssert(entity, @"Cannot retrieve cached objects with a nil entity");
    NSAssert(attributeName, @"Cannot retrieve cached objects by a nil entity");
    RKEntityByAttributeCache *attributeCache = [self attributeCacheForEntity:entity attribute:attributeName];
    if (attributeCache) {
        return [attributeCache objectWithAttributeValue:attributeValue];
    }

    return nil;
}

- (NSArray *)objectsForEntity:(NSEntityDescription *)entity withAttribute:(NSString *)attributeName value:(id)attributeValue
{
    NSAssert(entity, @"Cannot retrieve cached objects with a nil entity");
    NSAssert(attributeName, @"Cannot retrieve cached objects by a nil entity");
    RKEntityByAttributeCache *attributeCache = [self attributeCacheForEntity:entity attribute:attributeName];
    if (attributeCache) {
        return [attributeCache objectsWithAttributeValue:attributeValue];
    }

    return [NSSet set];
}

- (RKEntityByAttributeCache *)attributeCacheForEntity:(NSEntityDescription *)entity attribute:(NSString *)attributeName
{
    NSAssert(entity, @"Cannot retrieve attribute cache for a nil entity");
    NSAssert(attributeName, @"Cannot retrieve attribute cache for a nil attribute");
    for (RKEntityByAttributeCache *cache in self.attributeCaches) {
        if ([cache.entity isEqual:entity] && [cache.attribute isEqualToString:attributeName]) {
            return cache;
        }
    }

    return nil;
}

- (NSSet *)attributeCachesForEntity:(NSEntityDescription *)entity
{
    NSAssert(entity, @"Cannot retrieve attribute caches for a nil entity");
    NSMutableSet *set = [NSMutableSet set];
    for (RKEntityByAttributeCache *cache in self.attributeCaches) {
        if ([cache.entity isEqual:entity]) {
            [set addObject:cache];
        }
    }

    return [NSSet setWithSet:set];
}

- (void)flush
{
    [self.attributeCaches makeObjectsPerformSelector:@selector(flush)];
}

- (void)addObject:(NSManagedObject *)object
{
    NSAssert(object, @"Cannot add a nil object to the cache");
    NSArray *attributeCaches = [self attributeCachesForEntity:object.entity];
    for (RKEntityByAttributeCache *cache in attributeCaches) {
        [cache addObject:object];
    }
}

- (void)removeObject:(NSManagedObject *)object
{
    NSAssert(object, @"Cannot remove a nil object from the cache");
    NSArray *attributeCaches = [self attributeCachesForEntity:object.entity];
    for (RKEntityByAttributeCache *cache in attributeCaches) {
        [cache removeObject:object];
    }
}

@end
