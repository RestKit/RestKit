//
//  RKInMemoryManagedObjectCache.m
//  RestKit
//
//  Created by Jeff Arena on 1/24/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
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

#import "RKInMemoryManagedObjectCache.h"
#import "RKEntityCache.h"
#import "RKLog.h"
#import "RKEntityByAttributeCache.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent RKlcl_cRestKitCoreData

static NSPersistentStoreCoordinator *RKPersistentStoreCoordinatorFromManagedObjectContext(NSManagedObjectContext *managedObjectContext)
{
    NSManagedObjectContext *currentContext = managedObjectContext;
    do {
        if ([currentContext persistentStoreCoordinator]) return [currentContext persistentStoreCoordinator];
        currentContext = [currentContext parentContext];
    } while (currentContext);
    return nil;
}

static dispatch_queue_t RKInMemoryManagedObjectCacheCallbackQueue(void)
{
    static dispatch_once_t onceToken;
    static dispatch_queue_t callbackQueue;
    dispatch_once(&onceToken, ^{
        callbackQueue = dispatch_queue_create("org.restkit.core-data.in-memory-cache.callback-queue", DISPATCH_QUEUE_CONCURRENT);
    });
    return callbackQueue;
}

@interface RKInMemoryManagedObjectCache ()
@property (nonatomic, strong, readwrite) RKEntityCache *entityCache;
@property (nonatomic, assign) dispatch_queue_t callbackQueue;
@end

@implementation RKInMemoryManagedObjectCache

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    self = [super init];
    if (self) {
        NSManagedObjectContext *cacheContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [cacheContext setPersistentStoreCoordinator:RKPersistentStoreCoordinatorFromManagedObjectContext(managedObjectContext)];
        self.entityCache = [[RKEntityCache alloc] initWithManagedObjectContext:cacheContext];
        self.entityCache.callbackQueue = RKInMemoryManagedObjectCacheCallbackQueue();
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleManagedObjectContextDidChangeNotification:) name:NSManagedObjectContextObjectsDidChangeNotification object:managedObjectContext];
    }
    return self;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"%@ Failed to call designated initializer. Invoke initWithManagedObjectContext: instead.",
                                           NSStringFromClass([self class])]
                                 userInfo:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSSet *)managedObjectsWithEntity:(NSEntityDescription *)entity
                    attributeValues:(NSDictionary *)attributeValues
             inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    NSParameterAssert(entity);
    NSParameterAssert(attributeValues);
    NSParameterAssert(managedObjectContext);
    
    NSArray *attributes = [attributeValues allKeys];
    [self.entityCache beginAccessing];
    if (! [self.entityCache isEntity:entity cachedByAttributes:attributes]) {
        RKLogInfo(@"Caching instances of Entity '%@' by attributes '%@'", entity.name, [attributes componentsJoinedByString:@", "]);
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [self.entityCache cacheObjectsForEntity:entity byAttributes:attributes completion:^{
            dispatch_semaphore_signal(semaphore);
        }];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        RKEntityByAttributeCache *attributeCache = [self.entityCache attributeCacheForEntity:entity attributes:attributes];
        
        // Fetch any pending objects and add them to the cache
        NSFetchRequest *fetchRequest = [NSFetchRequest new];
        fetchRequest.entity = entity;
        fetchRequest.includesPendingChanges = YES;
        
        [managedObjectContext performBlockAndWait:^{
            NSError *error = nil;
            NSArray *objects = nil;
            objects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
            if (objects) {
                [attributeCache addObjects:[NSSet setWithArray:objects] completion:^{
                    dispatch_semaphore_signal(semaphore);
                }];
            } else {
                RKLogError(@"Fetched pre-loading existing managed objects with error: %@", error);
                dispatch_semaphore_signal(semaphore);
            }
        }];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
#if !OS_OBJECT_USE_OBJC
        dispatch_release(semaphore);
#endif
        
        RKLogTrace(@"Cached %ld objects", (long)[attributeCache count]);
    }
    
    NSSet *result = [self.entityCache objectsForEntity:entity withAttributeValues:attributeValues inContext:managedObjectContext];
    [self.entityCache endAccessing];
    return result;
}

- (void)didFetchObject:(NSManagedObject *)object
{
    [self.entityCache addObjects:[NSSet setWithObject:object] completion:nil];
}

- (void)didCreateObject:(NSManagedObject *)object
{
    [self.entityCache addObjects:[NSSet setWithObject:object] completion:nil];
}

- (void)didDeleteObject:(NSManagedObject *)object
{
    [self.entityCache removeObjects:[NSSet setWithObject:object] completion:nil];
}

- (void)handleManagedObjectContextDidChangeNotification:(NSNotification *)notification
{
    // Observe the parent context for changes and update the caches
    NSDictionary *userInfo = notification.userInfo;
    NSSet *insertedObjects = userInfo[NSInsertedObjectsKey];
    NSSet *updatedObjects = userInfo[NSUpdatedObjectsKey];
    NSSet *deletedObjects = userInfo[NSDeletedObjectsKey];
    RKLogTrace(@"insertedObjects=%@, updatedObjects=%@, deletedObjects=%@", insertedObjects, updatedObjects, deletedObjects);
    
    NSMutableSet *objectsToAdd = [NSMutableSet setWithSet:insertedObjects];
    [objectsToAdd unionSet:updatedObjects];
    
    [self.entityCache addObjects:objectsToAdd completion:nil];
    [self.entityCache removeObjects:deletedObjects completion:nil];
}

@end
