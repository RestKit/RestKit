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

#import <RestKit/CoreData/RKEntityByAttributeCache.h>
#import <RestKit/CoreData/RKEntityCache.h>

@interface RKEntityCache ()
@property (nonatomic, strong) NSMutableSet *attributeCaches;
@end

@implementation RKEntityCache

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)context
{
    NSAssert(context, @"Cannot initialize entity cache with a nil context");
    self = [super init];
    if (self) {
        _managedObjectContext = context;
        _attributeCaches = [[NSMutableSet alloc] init];
    }

    return self;
}

- (instancetype)init
{
    return [self initWithManagedObjectContext:nil];
}

- (void)cacheObjectsForEntity:(NSEntityDescription *)entity byAttributes:(NSArray *)attributeNames completion:(void (^)(void))completion
{
    NSParameterAssert(entity);
    NSParameterAssert(attributeNames);
    RKEntityByAttributeCache *attributeCache = [self attributeCacheForEntity:entity attributes:attributeNames];
    if (attributeCache && !attributeCache.isLoaded) {
        [attributeCache load:completion];
    } else {
        attributeCache = [[RKEntityByAttributeCache alloc] initWithEntity:entity attributes:attributeNames managedObjectContext:self.managedObjectContext];
        attributeCache.callbackQueue = self.callbackQueue;
        [attributeCache load:completion];
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

- (NSSet *)objectsForEntity:(NSEntityDescription *)entity withAttributeValues:(NSDictionary *)attributeValues inContext:(NSManagedObjectContext *)context
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
    for (RKEntityByAttributeCache *cache in [self.attributeCaches copy]) {
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
    for (RKEntityByAttributeCache *cache in [self.attributeCaches copy]) {
        if ([cache.entity isEqual:entity]) {
            [set addObject:cache];
        }
    }

    return [NSSet setWithSet:set];
}

- (void)waitForDispatchGroup:(dispatch_group_t)dispatchGroup withCompletionBlock:(void (^)(void))completion
{
    if (completion) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
            dispatch_group_wait(dispatchGroup, DISPATCH_TIME_FOREVER);
#if !OS_OBJECT_USE_OBJC
            dispatch_release(dispatchGroup);
#endif
            dispatch_async(self.callbackQueue ?: dispatch_get_main_queue(), completion);
        });
    }
}

- (void)flush:(void (^)(void))completion
{
    dispatch_group_t dispatchGroup = completion ? dispatch_group_create() : NULL;
    for (RKEntityByAttributeCache *cache in self.attributeCaches) {
        if (dispatchGroup) dispatch_group_enter(dispatchGroup);
        [cache flush:^{
            if (dispatchGroup) dispatch_group_leave(dispatchGroup);
        }];
    }
    if (dispatchGroup) [self waitForDispatchGroup:dispatchGroup withCompletionBlock:completion];
}

- (void)addObject:(NSManagedObject *)object completion:(void (^)(void))completion
{
    NSAssert(object, @"Cannot add a nil object to the cache");
    dispatch_group_t dispatchGroup = completion ? dispatch_group_create() : NULL;
    NSArray *attributeCaches = [self attributeCachesForEntity:object.entity];
    NSSet *objects = [NSSet setWithObject:object];
    for (RKEntityByAttributeCache *cache in attributeCaches) {
        if (dispatchGroup) dispatch_group_enter(dispatchGroup);
        [cache addObjects:objects completion:^{
            if (dispatchGroup) dispatch_group_leave(dispatchGroup);
        }];
    }    
    if (dispatchGroup) [self waitForDispatchGroup:dispatchGroup withCompletionBlock:completion];
}

- (void)removeObject:(NSManagedObject *)object completion:(void (^)(void))completion
{
    NSAssert(object, @"Cannot remove a nil object from the cache");
    NSArray *attributeCaches = [self attributeCachesForEntity:object.entity];
    NSSet *objects = [NSSet setWithObject:object];
    dispatch_group_t dispatchGroup = completion ? dispatch_group_create() : NULL;
    for (RKEntityByAttributeCache *cache in attributeCaches) {
        if (dispatchGroup) dispatch_group_enter(dispatchGroup);
        [cache removeObjects:objects completion:^{
            if (dispatchGroup) dispatch_group_leave(dispatchGroup);
        }];
    }
    if (dispatchGroup) [self waitForDispatchGroup:dispatchGroup withCompletionBlock:completion];
}

- (void)addObjects:(NSSet *)objects completion:(void (^)(void))completion
{
    dispatch_group_t dispatchGroup = completion ? dispatch_group_create() : NULL;
    NSSet *distinctEntities = [objects valueForKeyPath:@"entity"];
    for (NSEntityDescription *entity in distinctEntities) {
        NSArray *attributeCaches = [self attributeCachesForEntity:entity];
        if ([attributeCaches count]) {
            NSMutableSet *objectsToAdd = [NSMutableSet set];
            for (NSManagedObject *managedObject in objects) {
                if ([managedObject.entity isEqual:entity]) [objectsToAdd addObject:managedObject];
            }
            for (RKEntityByAttributeCache *cache in attributeCaches) {
                if (dispatchGroup) dispatch_group_enter(dispatchGroup);
                [cache addObjects:objectsToAdd completion:^{
                    if (dispatchGroup) dispatch_group_leave(dispatchGroup);
                }];
            }
        }
    }
    if (dispatchGroup) [self waitForDispatchGroup:dispatchGroup withCompletionBlock:completion];
}

- (void)removeObjects:(NSSet *)objects completion:(void (^)(void))completion
{
    dispatch_group_t dispatchGroup = completion ? dispatch_group_create() : NULL;
    NSSet *distinctEntities = [objects valueForKeyPath:@"entity"];
    for (NSEntityDescription *entity in distinctEntities) {
        NSArray *attributeCaches = [self attributeCachesForEntity:entity];
        if ([attributeCaches count]) {
            NSMutableSet *objectsToRemove = [NSMutableSet set];
            for (NSManagedObject *managedObject in objects) {
                if ([managedObject.entity isEqual:entity]) [objectsToRemove addObject:managedObject];
            }
            for (RKEntityByAttributeCache *cache in attributeCaches) {
                if (dispatchGroup) dispatch_group_enter(dispatchGroup);
                [cache removeObjects:objectsToRemove completion:^{
                    if (dispatchGroup) dispatch_group_leave(dispatchGroup);
                }];
            }
        }
    }
    if (dispatchGroup) [self waitForDispatchGroup:dispatchGroup withCompletionBlock:completion];
}

- (BOOL)containsObject:(NSManagedObject *)managedObject
{
    for (RKEntityByAttributeCache *attributeCache in [self attributeCachesForEntity:managedObject.entity]) {
        if ([attributeCache containsObject:managedObject]) return YES;
    }
    
    return NO;
}

@end
