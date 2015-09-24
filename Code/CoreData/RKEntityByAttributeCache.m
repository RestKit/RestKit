//
//  RKEntityByAttributeCache.m
//  RestKit
//
//  Created by Blake Watters on 5/1/12.
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

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#import <RestKit/CoreData/NSManagedObject+RKAdditions.h>
#import <RestKit/CoreData/RKEntityByAttributeCache.h>
#import <RestKit/CoreData/RKPropertyInspector+CoreData.h>
#import <RestKit/ObjectMapping/RKObjectUtilities.h>
#import <RestKit/ObjectMapping/RKPropertyInspector.h>
#import <RestKit/Support/RKLog.h>

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent RKlcl_cRestKitCoreDataCache

static id RKCacheKeyValueForEntityAttributeWithValue(NSEntityDescription *entity, NSString *attribute, id value)
{
    if ([value isKindOfClass:[NSString class]] || [value isEqual:[NSNull null]]) {
        return value;
    }
    return [value respondsToSelector:@selector(stringValue)] ? [value stringValue] : value;
}

static NSString *RKCacheKeyForEntityWithAttributeValues(NSEntityDescription *entity, NSDictionary *attributeValues)
{
    // Performance optimization
    if ([attributeValues count] == 1) return [[[attributeValues allValues] lastObject] description];
    NSArray *sortedAttributes = [[attributeValues allKeys] sortedArrayUsingSelector:@selector(compare:)];
    NSMutableArray *sortedValues = [NSMutableArray arrayWithCapacity:[sortedAttributes count]];
    for (NSString *attributeName in sortedAttributes) {
        id cacheKeyValue = RKCacheKeyValueForEntityAttributeWithValue(entity, attributeName, attributeValues[attributeName]);
        [sortedValues addObject:cacheKeyValue];
    };
    
    return [sortedValues componentsJoinedByString:@":"];
}

/*
 This function recursively calculates a set of cache keys given a dictionary of attribute values. The basic premise is that we wish to decompose all arrays of values within the dictionary into a distinct cache key, as each object within the cache will appear for only one key.
 */
static NSArray *RKCacheKeysForEntityFromAttributeValues(NSEntityDescription *entity, NSDictionary *attributeValues)
{
    NSMutableArray *cacheKeys = [NSMutableArray array];
    NSSet *collectionKeys = [attributeValues keysOfEntriesPassingTest:^BOOL(id key, id obj, BOOL *stop) {
        return RKObjectIsCollection(obj);
    }];

    if ([collectionKeys count] > 0) {
        for (NSString *attributeName in collectionKeys) {
            id attributeValue = attributeValues[attributeName];
            for (id value in attributeValue) {
                NSMutableDictionary *mutableAttributeValues = [attributeValues mutableCopy];
                [mutableAttributeValues setValue:value forKey:attributeName];
                [cacheKeys addObjectsFromArray:RKCacheKeysForEntityFromAttributeValues(entity, mutableAttributeValues)];
            }
        }
    } else {
        [cacheKeys addObject:RKCacheKeyForEntityWithAttributeValues(entity, attributeValues)];
    }

    return cacheKeys;
}

@interface RKEntityByAttributeCache ()
@property (nonatomic, strong) NSMutableDictionary *cacheKeysToObjectIDs;
#if OS_OBJECT_USE_OBJC
@property (nonatomic, strong) dispatch_queue_t queue;
#else
@property (nonatomic, assign) dispatch_queue_t queue;
#endif
@end

@implementation RKEntityByAttributeCache

- (instancetype)initWithEntity:(NSEntityDescription *)entity attributes:(NSArray *)attributeNames managedObjectContext:(NSManagedObjectContext *)context
{
    NSParameterAssert(entity);
    NSParameterAssert(attributeNames);
    NSParameterAssert(context);

    self = [self init];
    if (self) {
        _entity = entity;
        _attributes = attributeNames;
        _managedObjectContext = context;
        NSString *queueName = [[NSString alloc] initWithFormat:@"%@.%p", @"org.restkit.core-data.entity-by-attribute-cache", self];
        self.queue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_CONCURRENT);        

#if TARGET_OS_IPHONE
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveMemoryWarning:)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
#endif
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
#if !OS_OBJECT_USE_OBJC
    dispatch_release(_queue);
    _queue = NULL;
#endif
    _callbackQueue = NULL;
}

- (NSUInteger)count
{
    __block NSUInteger count;
    dispatch_sync(self.queue, ^{
        count = [[[self.cacheKeysToObjectIDs allValues] valueForKeyPath:@"@sum.@count"] integerValue];
    });
    return count;
}

- (NSUInteger)countOfAttributeValues
{
    __block NSUInteger count;
    dispatch_sync(self.queue, ^{
        count = [self.cacheKeysToObjectIDs count];
    });
    return count;
}

- (NSUInteger)countWithAttributeValues:(NSDictionary *)attributeValues
{
    return [[self objectsWithAttributeValues:attributeValues inContext:self.managedObjectContext] count];
}

- (void)load:(void (^)(void))completion
{
    NSExpressionDescription* objectIDExpression = [NSExpressionDescription new];
    objectIDExpression.name = @"objectID";
    objectIDExpression.expression = [NSExpression expressionForEvaluatedObject];
    objectIDExpression.expressionResultType = NSObjectIDAttributeType;

    // NOTE: `NSDictionaryResultType` does NOT support fetching pending changes. Pending objects must be manually added to the cache via `addObject:`.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = self.entity;
    fetchRequest.resultType = NSDictionaryResultType;
    fetchRequest.propertiesToFetch = [self.attributes arrayByAddingObject:objectIDExpression];

    [self.managedObjectContext performBlock:^{
        NSError *error = nil;
        NSArray *dictionaries = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (dictionaries) {
            RKLogDebug(@"Retrieved %ld dictionaries for cachable `NSManagedObjectID` objects with fetch request: %@", (long) [dictionaries count], fetchRequest);
        } else {
            RKLogWarning(@"Failed to load entity cache. Failed to execute fetch request: %@", fetchRequest);
            RKLogCoreDataError(error);
        }
        
        dispatch_barrier_async(self.queue, ^{
            RKLogDebug(@"Loading entity cache for Entity '%@' by attributes '%@' in managed object context %@ (concurrencyType = %ld)",
                       self.entity.name, self.attributes, self.managedObjectContext, (unsigned long)self.managedObjectContext.concurrencyType);
            self.cacheKeysToObjectIDs = [NSMutableDictionary dictionary];
            for (NSDictionary *dictionary in dictionaries) {
                NSManagedObjectID *objectID = dictionary[@"objectID"];
                NSDictionary *attributeValues = [dictionary dictionaryWithValuesForKeys:self.attributes];
                [self cacheObjectID:objectID forAttributeValues:attributeValues];
            }
            
            if (completion) dispatch_async(self.callbackQueue ?: dispatch_get_main_queue(), completion);
        });
     }];
}

- (void)flush:(void (^)(void))completion
{
    dispatch_barrier_async(self.queue, ^{
        RKLogDebug(@"Flushing entity cache for Entity '%@' by attributes '%@'", self.entity.name, self.attributes);
        self.cacheKeysToObjectIDs = nil;
        if (completion) dispatch_async(self.callbackQueue ?: dispatch_get_main_queue(), completion);
    });
}

- (BOOL)isLoaded
{
    __block BOOL isLoaded;
    dispatch_sync(self.queue, ^{
        isLoaded = (self.cacheKeysToObjectIDs != nil);
    });
    return isLoaded;
}

- (NSManagedObject *)objectForObjectID:(NSManagedObjectID *)objectID inContext:(NSManagedObjectContext *)context
{
    /**
     NOTE:
     
     We use `existingObjectWithID:` as opposed to `objectWithID:` as `objectWithID:` can return us a fault
     that will raise an exception when fired. `objectRegisteredForID:` is also an acceptable approach.
     */
    __block NSError *error = nil;
    __block NSManagedObject *object;
    [context performBlockAndWait:^{
        object = [context existingObjectWithID:objectID error:&error];
    }];
    // Don't return the object if it has been deleted.
    if ([object isDeleted]) object = nil;
    if (! object) {
        // Referential integrity errors often indicates that the temporary objectID does not exist in the specified context
        if (error && !([objectID isTemporaryID] && [error code] == NSManagedObjectReferentialIntegrityError)) {
            RKLogError(@"Failed to retrieve managed object with ID %@. Error %@\n%@", objectID, [error localizedDescription], [error userInfo]);
        }
    }
    return object;
}

- (NSManagedObject *)objectWithAttributeValues:(NSDictionary *)attributeValues inContext:(NSManagedObjectContext *)context
{
    NSSet *objects = [self objectsWithAttributeValues:attributeValues inContext:context];
    return ([objects count] > 0) ? [objects anyObject] : nil;
}

- (NSSet *)objectsWithAttributeValues:(NSDictionary *)attributeValues inContext:(NSManagedObjectContext *)context
{
    NSMutableSet *objects = [NSMutableSet set];
    NSArray *cacheKeys = RKCacheKeysForEntityFromAttributeValues(self.entity, attributeValues);
    for (NSString *cacheKey in cacheKeys) {
        __block NSSet *objectIDs = nil;
        dispatch_sync(self.queue, ^{
            objectIDs = [[NSSet alloc] initWithSet:(self.cacheKeysToObjectIDs)[cacheKey] copyItems:YES];
        });
        if ([objectIDs count]) {
            /**
             NOTE:
             In my benchmarking, retrieving the objects one at a time using existingObjectWithID: is significantly faster
             than issuing a single fetch request against all object ID's.
             */
            for (NSManagedObjectID *objectID in objectIDs) {
                NSManagedObject *object = [self objectForObjectID:objectID inContext:context];
                if (object) {
                    [objects addObject:object];
                } else {
                    RKLogDebug(@"Evicting objectID association for attributes %@ of Entity '%@': %@", attributeValues, self.entity.name, objectID);
                    [self evictObjectID:objectID forAttributeValues:attributeValues];
                }
            }
        }
    }
    return objects;
}

- (void)cacheObjectID:(NSManagedObjectID *)objectID forAttributeValues:(NSDictionary *)attributeValues
{
    NSParameterAssert(objectID);
    NSParameterAssert(attributeValues);
    NSString *cacheKey = RKCacheKeyForEntityWithAttributeValues(self.entity, attributeValues);
    NSMutableSet *objectIDs = (self.cacheKeysToObjectIDs)[cacheKey];
    if (objectIDs) {
        if (! [objectIDs containsObject:objectID]) {
            [objectIDs addObject:objectID];
        }
    } else {
        objectIDs = [NSMutableSet setWithObject:objectID];
    }
    
    if (nil == self.cacheKeysToObjectIDs) self.cacheKeysToObjectIDs = [NSMutableDictionary dictionary];
    [self.cacheKeysToObjectIDs setValue:objectIDs forKey:cacheKey];
}

- (void)deleteObjectID:(NSManagedObjectID *)objectID forAttributeValues:(NSDictionary *)attributeValues
{
    NSParameterAssert(objectID);
    NSParameterAssert(attributeValues);
    NSArray *cacheKeys = RKCacheKeysForEntityFromAttributeValues(self.entity, attributeValues);
    for (NSString *cacheKey in cacheKeys) {
        NSMutableSet *objectIDs = (self.cacheKeysToObjectIDs)[cacheKey];
        if (objectIDs && [objectIDs containsObject:objectID]) {
            [objectIDs removeObject:objectID];
        }
    }
}

- (void)evictObjectID:(NSManagedObjectID *)objectID forAttributeValues:(NSDictionary *)attributeValues
{
    if (attributeValues && [attributeValues count]) {
        NSArray *cacheKeys = RKCacheKeysForEntityFromAttributeValues(self.entity, attributeValues);
        dispatch_barrier_async(self.queue, ^{
            for (NSString *cacheKey in cacheKeys) {
                NSMutableSet *objectIDs = (self.cacheKeysToObjectIDs)[cacheKey];
                if (objectIDs && [objectIDs containsObject:objectID]) {
                    [objectIDs removeObject:objectID];
                }
            }
        });
    } else {
        RKLogWarning(@"Unable to remove object for object ID %@: empty values dictionary for attributes '%@'", objectID, self.attributes);
    }
}

- (void)addObjects:(NSSet *)managedObjects completion:(void (^)(void))completion
{
    if ([managedObjects count] == 0) {
        if (completion) dispatch_async(self.callbackQueue ?: dispatch_get_main_queue(), completion);
        return;
    }
    __block NSEntityDescription *entity;
    __block NSDictionary *attributeValues;
    __block NSManagedObjectID *objectID;
    NSManagedObjectContext *managedObjectContext = [[managedObjects anyObject] managedObjectContext];
    [managedObjectContext performBlockAndWait:^{
        NSMutableDictionary *newObjectIDsToAttributeValues = [NSMutableDictionary dictionaryWithCapacity:[managedObjects count]];
        for (NSManagedObject *managedObject in managedObjects) {
            entity = managedObject.entity;
            objectID = [managedObject objectID];
            attributeValues = [managedObject dictionaryWithValuesForKeys:self.attributes];
            
            NSAssert([entity isKindOfEntity:self.entity], @"Cannot add object with entity '%@' to cache for entity of '%@'", [entity name], [self.entity name]);
            newObjectIDsToAttributeValues[objectID] = attributeValues;
        }
        
        if ([newObjectIDsToAttributeValues count]) {
            dispatch_barrier_async(self.queue, ^{
                [newObjectIDsToAttributeValues enumerateKeysAndObjectsUsingBlock:^(NSManagedObjectID *objectID, NSDictionary *attributeValues, BOOL *stop) {
                    [self cacheObjectID:objectID forAttributeValues:attributeValues];
                }];
                
                if (completion) dispatch_async(self.callbackQueue ?: dispatch_get_main_queue(), completion);
            });
        } else {
            if (completion) dispatch_async(self.callbackQueue ?: dispatch_get_main_queue(), completion);
        }
    }];
}

- (void)removeObjects:(NSSet *)managedObjects completion:(void (^)(void))completion
{
    if ([managedObjects count] == 0) {
        if (completion) dispatch_async(self.callbackQueue ?: dispatch_get_main_queue(), completion);
        return;
    }
    __block NSEntityDescription *entity;
    __block NSDictionary *attributeValues;
    __block NSManagedObjectID *objectID;
    NSManagedObjectContext *managedObjectContext = [[managedObjects anyObject] managedObjectContext];
    [managedObjectContext performBlock:^{
        NSMutableDictionary *deletedObjectIDsToAttributeValues = [NSMutableDictionary dictionaryWithCapacity:[managedObjects count]];
        for (NSManagedObject *managedObject in managedObjects) {
            entity = managedObject.entity;
            objectID = [managedObject objectID];
            attributeValues = [managedObject dictionaryWithValuesForKeys:self.attributes];
            
            NSAssert([entity isKindOfEntity:self.entity], @"Cannot remove object with entity '%@' from cache for entity of '%@'", [entity name], [self.entity name]);
            deletedObjectIDsToAttributeValues[objectID] = attributeValues;
        }
        
        if ([deletedObjectIDsToAttributeValues count]) {
            dispatch_barrier_async(self.queue, ^{
                [deletedObjectIDsToAttributeValues enumerateKeysAndObjectsUsingBlock:^(NSManagedObjectID *objectID, NSDictionary *attributeValues, BOOL *stop) {
                    [self deleteObjectID:objectID forAttributeValues:attributeValues];
                }];
                
                if (completion) dispatch_async(self.callbackQueue ?: dispatch_get_main_queue(), completion);
            });
        } else {
            if (completion) dispatch_async(self.callbackQueue ?: dispatch_get_main_queue(), completion);
        }
    }];
}

- (BOOL)containsObjectWithAttributeValues:(NSDictionary *)attributeValues
{
    return [[self objectsWithAttributeValues:attributeValues inContext:self.managedObjectContext] count] > 0;
}

- (BOOL)containsObject:(NSManagedObject *)object
{
    __block NSArray *allObjectIDs = nil;
    dispatch_sync(self.queue, ^{
        allObjectIDs = [[self.cacheKeysToObjectIDs allValues] valueForKeyPath:@"@distinctUnionOfSets.self"];
    });
    return [allObjectIDs containsObject:object.objectID];
}

- (void)didReceiveMemoryWarning:(NSNotification *)notification
{
    [self flush:nil];
}

@end

@implementation RKEntityByAttributeCache (Deprecations)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

- (void)load DEPRECATED_ATTRIBUTE
{
    [self load:nil];
}

- (void)flush DEPRECATED_ATTRIBUTE
{
    [self flush:nil];
}

- (void)addObject:(NSManagedObject *)object DEPRECATED_ATTRIBUTE
{
    [self addObjects:[NSSet setWithObject:object] completion:nil];
}

- (void)removeObject:(NSManagedObject *)object DEPRECATED_ATTRIBUTE
{
    [self removeObjects:[NSSet setWithObject:object] completion:nil];
}

- (void)setMonitorsContextForChanges:(BOOL)monitorsContextForChanges DEPRECATED_ATTRIBUTE
{}

- (BOOL)monitorsContextForChanges DEPRECATED_ATTRIBUTE
{
    return NO;
}

#pragma clang diagnostic pop

@end
