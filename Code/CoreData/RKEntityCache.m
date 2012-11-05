//
//  RKEntityCache.m
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

#import "RKEntityCache.h"
#import "RKEntityByAttributeCache.h"

@interface RKEntityCache ()
@property (nonatomic, strong) NSMutableSet *attributeCaches;
@end

@implementation RKEntityCache


- (id)initWithManagedObjectContext:(NSManagedObjectContext *)context
{
    NSAssert(context, @"Cannot initialize entity cache with a nil context");
    self = [super init];
    if (self) {
        _managedObjectContext = context;
        _attributeCaches = [[NSMutableSet alloc] init];
    }

    return self;
}

- (id)init
{
    return [self initWithManagedObjectContext:nil];
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
    }
}

- (BOOL)isEntity:(NSEntityDescription *)entity cachedByAttribute:(NSString *)attributeName
{
    NSAssert(entity, @"Cannot check cache status for a nil entity");
    NSAssert(attributeName, @"Cannot check cache status for a nil attribute");
    RKEntityByAttributeCache *attributeCache = [self attributeCacheForEntity:entity attribute:attributeName];
    return (attributeCache && attributeCache.isLoaded);
}

- (NSManagedObject *)objectForEntity:(NSEntityDescription *)entity withAttribute:(NSString *)attributeName value:(id)attributeValue inContext:(NSManagedObjectContext *)context
{
    NSAssert(entity, @"Cannot retrieve cached objects with a nil entity");
    NSAssert(attributeName, @"Cannot retrieve cached objects by a nil entity");
    RKEntityByAttributeCache *attributeCache = [self attributeCacheForEntity:entity attribute:attributeName];
    if (attributeCache) {
        return [attributeCache objectWithAttributeValue:attributeValue inContext:context];
    }

    return nil;
}

- (NSArray *)objectsForEntity:(NSEntityDescription *)entity withAttribute:(NSString *)attributeName value:(id)attributeValue inContext:(NSManagedObjectContext *)context
{
    NSAssert(entity, @"Cannot retrieve cached objects with a nil entity");
    NSAssert(attributeName, @"Cannot retrieve cached objects by a nil entity");
    RKEntityByAttributeCache *attributeCache = [self attributeCacheForEntity:entity attribute:attributeName];
    if (attributeCache) {
        return [attributeCache objectsWithAttributeValue:attributeValue inContext:context];
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
