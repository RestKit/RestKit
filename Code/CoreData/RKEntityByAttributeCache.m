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

#import "RKEntityByAttributeCache.h"
#import "RKLog.h"
#import "RKPropertyInspector.h"
#import "RKPropertyInspector+CoreData.h"
#import "NSManagedObject+RKAdditions.h"
#import "RKObjectUtilities.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent RKlcl_cRestKitCoreDataCache

static id RKCacheKeyValueForEntityAttributeWithValue(NSEntityDescription *entity, NSString *attribute, id value)
{
    if ([value isKindOfClass:[NSString class]] || [value isEqual:[NSNull null]]) {
        return value;
    }
    
    Class attributeType = [[RKPropertyInspector sharedInspector] classForPropertyNamed:attribute ofEntity:entity];
    return [attributeType instancesRespondToSelector:@selector(stringValue)] ? [value stringValue] : value;
}

static NSString *RKCacheKeyForEntityWithAttributeValues(NSEntityDescription *entity, NSDictionary *attributeValues)
{
    NSArray *sortedAttributes = [[attributeValues allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    NSMutableArray *sortedValues = [NSMutableArray arrayWithCapacity:[sortedAttributes count]];
    [sortedAttributes enumerateObjectsUsingBlock:^(NSString *attributeName, NSUInteger idx, BOOL *stop) {
        id cacheKeyValue = RKCacheKeyValueForEntityAttributeWithValue(entity, attributeName, [attributeValues objectForKey:attributeName]);
        [sortedValues addObject:cacheKeyValue];
    }];
    
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
            id attributeValue = [attributeValues objectForKey:attributeName];
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
@property (nonatomic, strong) NSRecursiveLock *lock;
@end

@implementation RKEntityByAttributeCache

- (id)initWithEntity:(NSEntityDescription *)entity attributes:(NSArray *)attributeNames managedObjectContext:(NSManagedObjectContext *)context
{
    NSParameterAssert(entity);
    NSParameterAssert(attributeNames);
    NSParameterAssert(context);

    self = [self init];
    if (self) {
        _entity = entity;
        _attributes = attributeNames;
        _managedObjectContext = context;
        _monitorsContextForChanges = YES;
        _lock = [NSRecursiveLock new];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(managedObjectContextDidChange:)
                                                     name:NSManagedObjectContextObjectsDidChangeNotification
                                                   object:context];

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
}

- (NSUInteger)count
{
    [self.lock lock];
    NSUInteger count = [[[self.cacheKeysToObjectIDs allValues] valueForKeyPath:@"@sum.@count"] integerValue];
    [self.lock unlock];
    return count;
}

- (NSUInteger)countOfAttributeValues
{
    [self.lock lock];
    NSUInteger count = [self.cacheKeysToObjectIDs count];
    [self.lock unlock];
    return count;
}

- (NSUInteger)countWithAttributeValues:(NSDictionary *)attributeValues
{
    [self.lock lock];
    NSUInteger count = [[self objectsWithAttributeValues:attributeValues inContext:self.managedObjectContext] count];
    [self.lock unlock];
    return count;
}

- (void)load
{
    [self.lock lock];
    RKLogDebug(@"Loading entity cache for Entity '%@' by attributes '%@' in managed object context %@ (concurrencyType = %ld)",
               self.entity.name, self.attributes, self.managedObjectContext, (unsigned long)self.managedObjectContext.concurrencyType);
    self.cacheKeysToObjectIDs = [NSMutableDictionary dictionary];

    NSExpressionDescription* objectIDExpression = [NSExpressionDescription new];
    objectIDExpression.name = @"objectID";
    objectIDExpression.expression = [NSExpression expressionForEvaluatedObject];
    objectIDExpression.expressionResultType = NSObjectIDAttributeType;

    // NOTE: `NSDictionaryResultType` does NOT support fetching pending changes. Pending objects must be manually added to the cache via `addObject:`.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = self.entity;
    fetchRequest.resultType = NSDictionaryResultType;
    fetchRequest.propertiesToFetch = [self.attributes arrayByAddingObject:objectIDExpression];

    [self.managedObjectContext performBlockAndWait:^{
        NSError *error = nil;
        NSArray *dictionaries = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (dictionaries) {
            RKLogDebug(@"Retrieved %ld dictionaries for cachable `NSManagedObjectID` objects with fetch request: %@", (long) [dictionaries count], fetchRequest);
        } else {
            RKLogWarning(@"Failed to load entity cache. Failed to execute fetch request: %@", fetchRequest);
            RKLogCoreDataError(error);
        }

        for (NSDictionary *dictionary in dictionaries) {
            NSManagedObjectID *objectID = [dictionary objectForKey:@"objectID"];
            NSDictionary *attributeValues = [dictionary dictionaryWithValuesForKeys:self.attributes];
            [self setObjectID:objectID forAttributeValues:attributeValues];
        }
     }];
    [self.lock unlock];
}

- (void)flush
{
    [self.lock lock];
    RKLogDebug(@"Flushing entity cache for Entity '%@' by attributes '%@'", self.entity.name, self.attributes);
    self.cacheKeysToObjectIDs = nil;
    [self.lock unlock];
}

- (void)reload
{
    [self.lock lock];
    [self flush];
    [self load];
    [self.lock unlock];
}

- (BOOL)isLoaded
{
    [self.lock lock];
    BOOL isLoaded = (self.cacheKeysToObjectIDs != nil);
    [self.lock unlock];
    return isLoaded;
}

- (NSManagedObject *)objectForObjectID:(NSManagedObjectID *)objectID inContext:(NSManagedObjectContext *)context
{
    /**
     NOTE:

     We use `existingObjectWithID:` as opposed to `objectWithID:` as `objectWithID:` can return us a fault
     that will raise an exception when fired. `existingObjectWithID:error:` will return nil if the ID has been
     deleted. `objectRegisteredForID:` is also an acceptable approach.
     */
    __block NSError *error = nil;
    __block NSManagedObject *object;
    [self.lock lock];
    [context performBlockAndWait:^{
        object = [context existingObjectWithID:objectID error:&error];
    }];
    if (! object) {
        // Referential integrity errors often indicates that the temporary objectID does not exist in the specified context
        if (error && !([objectID isTemporaryID] && [error code] == NSManagedObjectReferentialIntegrityError)) {
            RKLogError(@"Failed to retrieve managed object with ID %@. Error %@\n%@", objectID, [error localizedDescription], [error userInfo]);
        }
    }
    [self.lock unlock];
    return object;
}

- (NSManagedObject *)objectWithAttributeValues:(NSDictionary *)attributeValues inContext:(NSManagedObjectContext *)context
{
    [self.lock lock];
    NSSet *objects = [self objectsWithAttributeValues:attributeValues inContext:context];
    [self.lock unlock];
    return ([objects count] > 0) ? [objects anyObject] : nil;
}

- (NSSet *)objectsWithAttributeValues:(NSDictionary *)attributeValues inContext:(NSManagedObjectContext *)context
{
    [self.lock lock];
    NSMutableSet *objects = [NSMutableSet set];
    NSArray *cacheKeys = RKCacheKeysForEntityFromAttributeValues(self.entity, attributeValues);
    for (NSString *cacheKey in cacheKeys) {
        NSArray *objectIDs = nil;
        @synchronized(self.cacheKeysToObjectIDs) {
            objectIDs = [[NSArray alloc] initWithArray:[self.cacheKeysToObjectIDs objectForKey:cacheKey] copyItems:YES];
        }
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
                    [self removeObjectID:objectID forAttributeValues:attributeValues];
                }
            }
        }
    }
    [self.lock unlock];
    return objects;
}

- (void)setObjectID:(NSManagedObjectID *)objectID forAttributeValues:(NSDictionary *)attributeValues
{
    [self.lock lock];
    if (attributeValues && [attributeValues count]) {
        NSString *cacheKey = RKCacheKeyForEntityWithAttributeValues(self.entity, attributeValues);
        NSMutableArray *objectIDs = [self.cacheKeysToObjectIDs objectForKey:cacheKey];
        if (objectIDs) {
            if (! [objectIDs containsObject:objectID]) {
                [objectIDs addObject:objectID];
            }
        } else {
            objectIDs = [NSMutableArray arrayWithObject:objectID];
        }

        if (nil == self.cacheKeysToObjectIDs) self.cacheKeysToObjectIDs = [NSMutableDictionary dictionary];
        [self.cacheKeysToObjectIDs setValue:objectIDs forKey:cacheKey];
    } else {
        RKLogWarning(@"Unable to add object for object ID %@: empty values dictionary for attributes '%@'", objectID, self.attributes);
    }
    [self.lock unlock];
}

- (void)removeObjectID:(NSManagedObjectID *)objectID forAttributeValues:(NSDictionary *)attributeValues
{
    [self.lock lock];
    if (attributeValues && [attributeValues count]) {
        NSArray *cacheKeys = RKCacheKeysForEntityFromAttributeValues(self.entity, attributeValues);
        for (NSString *cacheKey in cacheKeys) {
            NSMutableArray *objectIDs = [self.cacheKeysToObjectIDs objectForKey:cacheKey];
            if (objectIDs && [objectIDs containsObject:objectID]) {
                [objectIDs removeObject:objectID];
            }
        }
    } else {
        RKLogWarning(@"Unable to remove object for object ID %@: empty values dictionary for attributes '%@'", objectID, self.attributes);
    }
    [self.lock unlock];
}

- (void)addObject:(NSManagedObject *)object
{
    [self.lock lock];
    __block NSEntityDescription *entity;
    __block NSDictionary *attributeValues;
    __block NSManagedObjectID *objectID;
    [object.managedObjectContext performBlockAndWait:^{
        entity = object.entity;
        objectID = [object objectID];
        attributeValues = [object dictionaryWithValuesForKeys:self.attributes];
    }];
    NSAssert([entity isKindOfEntity:self.entity], @"Cannot add object with entity '%@' to cache for entity of '%@'", [entity name], [self.entity name]);
    [self setObjectID:objectID forAttributeValues:attributeValues];
    [self.lock unlock];
}

- (void)removeObject:(NSManagedObject *)object
{
    [self.lock lock];
    __block NSEntityDescription *entity;
    __block NSDictionary *attributeValues;
    __block NSManagedObjectID *objectID;
    [object.managedObjectContext performBlockAndWait:^{
        entity = object.entity;
        objectID = [object objectID];
        attributeValues = [object dictionaryWithValuesForKeys:self.attributes];
    }];
    NSAssert([entity isKindOfEntity:self.entity], @"Cannot remove object with entity '%@' from cache for entity of '%@'", [entity name], [self.entity name]);
    [self removeObjectID:objectID forAttributeValues:attributeValues];
    [self.lock unlock];
}

- (BOOL)containsObjectWithAttributeValues:(NSDictionary *)attributeValues
{
    [self.lock lock];
    BOOL containsObject = [[self objectsWithAttributeValues:attributeValues inContext:self.managedObjectContext] count] > 0;
    [self.lock unlock];
    return containsObject;
}

- (BOOL)containsObject:(NSManagedObject *)object
{
    [self.lock lock];
    NSArray *allObjectIDs = [[self.cacheKeysToObjectIDs allValues] valueForKeyPath:@"@distinctUnionOfArrays.self"];
    [self.lock unlock];
    return [allObjectIDs containsObject:object.objectID];
}

- (void)managedObjectContextDidChange:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    NSSet *insertedObjects = [userInfo objectForKey:NSInsertedObjectsKey];
    NSSet *updatedObjects = [userInfo objectForKey:NSUpdatedObjectsKey];
    NSSet *deletedObjects = [userInfo objectForKey:NSDeletedObjectsKey];
    RKLogTrace(@"insertedObjects=%@, updatedObjects=%@, deletedObjects=%@", insertedObjects, updatedObjects, deletedObjects);
    
    NSMutableSet *objectsToAdd = [NSMutableSet setWithSet:insertedObjects];
    [objectsToAdd unionSet:updatedObjects];
    
    /**
     We dispatch async here to avoid a deadlock situation if the notification is delivered while another thread has acquired the lock. This is problematic for changes to `NSMainQueueConcurrencyType` MOC's in particular. We pre-calculate the attribute values from the object rather than invoking `addObject:` or `removeObject:` as the deleted objects will be unreadable once execution resumes following the notification's delivery.
     */
    NSMutableDictionary *newObjectIDsToAttributeValues = [NSMutableDictionary dictionaryWithCapacity:[objectsToAdd count]];
    for (NSManagedObject *managedObject in objectsToAdd) {
        if ([managedObject.entity isKindOfEntity:self.entity]) {
            NSManagedObjectID *objectID = [managedObject objectID];
            NSDictionary *attributeValues = [managedObject dictionaryWithValuesForKeys:self.attributes];
            [newObjectIDsToAttributeValues setObject:attributeValues forKey:objectID];
        }
    }
    
    // Deleted objects
    NSMutableDictionary *deletedObjectIDsToAttributeValues = [NSMutableDictionary dictionaryWithCapacity:[deletedObjects count]];
    for (NSManagedObject *managedObject in deletedObjects) {
        if ([managedObject.entity isKindOfEntity:self.entity]) {
            NSManagedObjectID *objectID = [managedObject objectID];
            NSDictionary *attributeValues = [managedObject dictionaryWithValuesForKeys:self.attributes];
            [deletedObjectIDsToAttributeValues setObject:attributeValues forKey:objectID];
        }
    }
    
    if ([newObjectIDsToAttributeValues count] || [deletedObjectIDsToAttributeValues count]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.lock lock];
            [newObjectIDsToAttributeValues enumerateKeysAndObjectsUsingBlock:^(NSManagedObjectID *objectID, NSDictionary *attributeValues, BOOL *stop) {
                [self setObjectID:objectID forAttributeValues:attributeValues];
            }];
            [deletedObjectIDsToAttributeValues enumerateKeysAndObjectsUsingBlock:^(NSManagedObjectID *objectID, NSDictionary *attributeValues, BOOL *stop) {
                [self removeObjectID:objectID forAttributeValues:attributeValues];
            }];
            [self.lock unlock];
        });
    }
}

- (void)didReceiveMemoryWarning:(NSNotification *)notification
{
    [self flush];
}

@end
