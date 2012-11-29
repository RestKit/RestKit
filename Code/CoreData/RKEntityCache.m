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


- (void)cacheObjectsForEntity:(NSEntityDescription *)entity byAttributes:(NSArray *)attributeNames
{
    NSParameterAssert(entity);
    NSParameterAssert(attributeNames);
    RKEntityByAttributeCache *attributeCache = [self attributeCacheForEntity:entity attributes:attributeNames];
    if (attributeCache && !attributeCache.isLoaded) {
        [attributeCache load];
    } else {
        attributeCache = [[RKEntityByAttributeCache alloc] initWithEntity:entity attributes:attributeNames managedObjectContext:self.managedObjectContext];
        [attributeCache load];
        [self.attributeCaches addObject:attributeCache];
    }
}

- (BOOL)isEntity:(NSEntityDescription *)entity cachedByAttributes:(NSArray *)attributeNames
{
    NSParameterAssert(entity);
    NSParameterAssert(attributeNames);
    RKEntityByAttributeCache *attributeCache = [self attributeCacheForEntity:entity attributes:attributeNames];
    return (attributeCache && attributeCache.isLoaded);
}

- (NSManagedObject *)objectForEntity:(NSEntityDescription *)entity withAttributeValues:(NSDictionary *)attributeValues inContext:(NSManagedObjectContext *)context
{
    NSParameterAssert(entity);
    NSParameterAssert(attributeValues);
    NSParameterAssert(context);
    RKEntityByAttributeCache *attributeCache = [self attributeCacheForEntity:entity attributes:[attributeValues allKeys]];
    if (attributeCache) {
        return [attributeCache objectWithAttributeValues:attributeValues inContext:context];
    }

    return nil;
}

- (NSArray *)objectsForEntity:(NSEntityDescription *)entity withAttributeValues:(NSDictionary *)attributeValues inContext:(NSManagedObjectContext *)context
{
    NSParameterAssert(entity);
    NSParameterAssert(attributeValues);
    NSParameterAssert(context);
    RKEntityByAttributeCache *attributeCache = [self attributeCacheForEntity:entity attributes:[attributeValues allKeys]];
    if (attributeCache) {
        return [attributeCache objectsWithAttributeValues:attributeValues inContext:context];
    }

    return [NSSet set];
}

- (RKEntityByAttributeCache *)attributeCacheForEntity:(NSEntityDescription *)entity attributes:(NSArray *)attributeNames
{
    NSParameterAssert(entity);
    NSParameterAssert(attributeNames);
    for (RKEntityByAttributeCache *cache in self.attributeCaches) {
        if ([cache.entity isEqual:entity] && [cache.attributes isEqualToArray:attributeNames]) {
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
