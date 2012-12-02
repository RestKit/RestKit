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
        id cacheKeyValue = RKCacheKeyValueForEntityAttributeWithValue(entity, attributeName, attributeValues[attributeName]);
        [sortedValues addObject:cacheKeyValue];
    }];
    
    return [sortedValues componentsJoinedByString:@":"];
}

@interface RKEntityByAttributeCache ()
@property (nonatomic, strong) NSMutableDictionary *cacheKeysToObjectIDs;
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
    return [[[self.cacheKeysToObjectIDs allValues] valueForKeyPath:@"@sum.@count"] integerValue];
}

- (NSUInteger)countOfAttributeValues
{
    return [self.cacheKeysToObjectIDs count];
}

- (NSUInteger)countWithAttributeValues:(NSDictionary *)attributeValues
{
    return [[self objectsWithAttributeValues:attributeValues inContext:self.managedObjectContext] count];
}

- (void)load
{
    RKLogDebug(@"Loading entity cache for Entity '%@' by attributes '%@' in managed object context %@ (concurrencyType = %ld)",
               self.entity.name, self.attributes, self.managedObjectContext, (unsigned long)self.managedObjectContext.concurrencyType);
    @synchronized(self.cacheKeysToObjectIDs) {
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
    }
}

- (void)flush
{
    @synchronized(self.cacheKeysToObjectIDs) {
        RKLogDebug(@"Flushing entity cache for Entity '%@' by attributes '%@'", self.entity.name, self.attributes);
        self.cacheKeysToObjectIDs = nil;
    }
}

- (void)reload
{
    [self flush];
    [self load];
}

- (BOOL)isLoaded
{
    return (self.cacheKeysToObjectIDs != nil);
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
    [context performBlockAndWait:^{
        object = [context existingObjectWithID:objectID error:&error];
    }];
    if (! object) {
        // Referential integrity errors often indicates that the temporary objectID does not exist in the specified context
        if (error && !([objectID isTemporaryID] && [error code] == NSManagedObjectReferentialIntegrityError)) {
            RKLogError(@"Failed to retrieve managed object with ID %@. Error %@\n%@", objectID, [error localizedDescription], [error userInfo]);
        }

        return nil;
    }

    return object;
}

- (NSManagedObject *)objectWithAttributeValues:(NSDictionary *)attributeValues inContext:(NSManagedObjectContext *)context
{
    NSArray *objects = [self objectsWithAttributeValues:attributeValues inContext:context];
    return ([objects count] > 0) ? [objects objectAtIndex:0] : nil;
}

- (NSArray *)objectsWithAttributeValues:(NSDictionary *)attributeValues inContext:(NSManagedObjectContext *)context
{
    // TODO: Assert that the attribute values contains all of the cache attributes!!!
    NSString *cacheKey = RKCacheKeyForEntityWithAttributeValues(self.entity, attributeValues);
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
        NSMutableArray *objects = [NSMutableArray arrayWithCapacity:[objectIDs count]];
        for (NSManagedObjectID *objectID in objectIDs) {
            NSManagedObject *object = [self objectForObjectID:objectID inContext:context];
            if (object) {
                [objects addObject:object];
            } else {
                RKLogDebug(@"Evicting objectID association for attributes %@ of Entity '%@': %@", attributeValues, self.entity.name, objectID);
                [self removeObjectID:objectID forAttributeValues:attributeValues];
            }
        }

        return objects;
    }

    return [NSArray array];
}

- (void)setObjectID:(NSManagedObjectID *)objectID forAttributeValues:(NSDictionary *)attributeValues
{
    @synchronized(self.cacheKeysToObjectIDs) {
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
    }
}

- (void)removeObjectID:(NSManagedObjectID *)objectID forAttributeValues:(NSDictionary *)attributeValues
{
    @synchronized(self.cacheKeysToObjectIDs) {
        if (attributeValues && [attributeValues count]) {
            NSString *cacheKey = RKCacheKeyForEntityWithAttributeValues(self.entity, attributeValues);
            NSMutableArray *objectIDs = [self.cacheKeysToObjectIDs objectForKey:cacheKey];
            if (objectIDs && [objectIDs containsObject:objectID]) {
                [objectIDs removeObject:objectID];
            }
        } else {
            RKLogWarning(@"Unable to remove object for object ID %@: empty values dictionary for attributes '%@'", objectID, self.attributes);
        }
    }
}

- (void)addObject:(NSManagedObject *)object
{
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
}

- (void)removeObject:(NSManagedObject *)object
{
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
}

- (BOOL)containsObjectWithAttributeValues:(NSDictionary *)attributeValues
{
    return [[self objectsWithAttributeValues:attributeValues inContext:self.managedObjectContext] count] > 0;
}

- (BOOL)containsObject:(NSManagedObject *)object
{
    NSArray *allObjectIDs = [[self.cacheKeysToObjectIDs allValues] valueForKeyPath:@"@distinctUnionOfArrays.self"];
    return [allObjectIDs containsObject:object.objectID];
}

- (void)managedObjectContextDidChange:(NSNotification *)notification
{
    if (self.monitorsContextForChanges == NO) return;

    NSDictionary *userInfo = notification.userInfo;
    NSSet *insertedObjects = [userInfo objectForKey:NSInsertedObjectsKey];
    NSSet *updatedObjects = [userInfo objectForKey:NSUpdatedObjectsKey];
    NSSet *deletedObjects = [userInfo objectForKey:NSDeletedObjectsKey];
    RKLogTrace(@"insertedObjects=%@, updatedObjects=%@, deletedObjects=%@", insertedObjects, updatedObjects, deletedObjects);

    NSMutableSet *objectsToAdd = [NSMutableSet setWithSet:insertedObjects];
    [objectsToAdd unionSet:updatedObjects];

    for (NSManagedObject *object in objectsToAdd) {
        if ([object.entity isKindOfEntity:self.entity]) {
            [self addObject:object];
        }
    }

    for (NSManagedObject *object in deletedObjects) {
        if ([object.entity isKindOfEntity:self.entity]) {
            [self removeObject:object];
        }
    }
}

- (void)didReceiveMemoryWarning:(NSNotification *)notification
{
    [self flush];
}

@end
