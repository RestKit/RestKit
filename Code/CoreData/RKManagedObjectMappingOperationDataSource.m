//
//  RKManagedObjectMappingOperationDataSource.m
//  RestKit
//
//  Created by Blake Watters on 7/3/12.
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

#import <RKValueTransformers/RKValueTransformers.h>
#import <RestKit/CoreData/NSManagedObject+RKAdditions.h>
#import <RestKit/CoreData/RKEntityMapping.h>
#import <RestKit/CoreData/RKManagedObjectCaching.h>
#import <RestKit/CoreData/RKManagedObjectMappingOperationDataSource.h>
#import <RestKit/CoreData/RKManagedObjectStore.h>
#import <RestKit/CoreData/RKRelationshipConnectionOperation.h>
#import <RestKit/ObjectMapping/RKMappingErrors.h>
#import <RestKit/ObjectMapping/RKMappingOperation.h>
#import <RestKit/ObjectMapping/RKObjectMapping.h>
#import <RestKit/ObjectMapping/RKObjectMappingMatcher.h>
#import <RestKit/ObjectMapping/RKObjectUtilities.h>
#import <RestKit/ObjectMapping/RKRelationshipMapping.h>
#import <RestKit/Support/RKLog.h>
#import <objc/runtime.h>

extern NSString * const RKObjectMappingNestingAttributeKeyName;

static void *RKManagedObjectMappingOperationDataSourceAssociatedObjectKey = &RKManagedObjectMappingOperationDataSourceAssociatedObjectKey;

NSArray *RKApplyNestingAttributeValueToMappings(NSString *attributeName, id value, NSArray *propertyMappings);

static id RKValueForAttributeMappingInRepresentation(RKAttributeMapping *attributeMapping, NSDictionary *representation)
{
    if ([attributeMapping.sourceKeyPath isEqualToString:RKObjectMappingNestingAttributeKeyName]) {
        return [[representation allKeys] lastObject];
    } else if (attributeMapping.sourceKeyPath == nil){
        return representation[[NSNull null]];
    } else {
        return [representation valueForKeyPath:attributeMapping.sourceKeyPath];
    }
}

static RKAttributeMapping *RKAttributeMappingForNameInMappings(NSString *name, NSArray *attributeMappings)
{
    for (RKAttributeMapping *attributeMapping in attributeMappings) {
        if ([[attributeMapping destinationKeyPath] isEqualToString:name]) return attributeMapping;
    }
    
    return nil;
}

/**
 This function is the workhorse for extracting entity identifier attributes from a dictionary representation. It supports type transformations, compound entity identifier attributes, and dynamic nesting keys within the representation. 
 */
static NSDictionary *RKEntityIdentificationAttributesForEntityMappingWithRepresentation(RKEntityMapping *entityMapping, NSDictionary *representation)
{
    NSCParameterAssert(entityMapping);
    NSCAssert([representation isKindOfClass:[NSDictionary class]], @"Expected a dictionary representation");
    NSArray *attributeMappings = entityMapping.attributeMappings;
    __block NSError *error = nil;

    // If the representation is mapped with a nesting attribute, we must apply the nesting value to the representation before constructing the identification attributes
    RKAttributeMapping *nestingAttributeMapping = [entityMapping mappingForSourceKeyPath:RKObjectMappingNestingAttributeKeyName];
    if (nestingAttributeMapping) {
        Class attributeClass = [entityMapping classForProperty:nestingAttributeMapping.destinationKeyPath];
        id attributeValue = nil;
        id<RKValueTransforming> valueTransformer = nestingAttributeMapping.valueTransformer ?: entityMapping.valueTransformer;
        [valueTransformer transformValue:[[representation allKeys] lastObject] toValue:&attributeValue ofClass:attributeClass error:&error];
        attributeMappings = RKApplyNestingAttributeValueToMappings(nestingAttributeMapping.destinationKeyPath, attributeValue, attributeMappings);
    }
    
    // Map the identification attributes
    NSMutableDictionary *entityIdentifierAttributes = [NSMutableDictionary dictionaryWithCapacity:[entityMapping.identificationAttributes count]];
    [entityMapping.identificationAttributes enumerateObjectsUsingBlock:^(NSAttributeDescription *attribute, NSUInteger idx, BOOL *stop) {
        RKAttributeMapping *attributeMapping = RKAttributeMappingForNameInMappings([attribute name], attributeMappings);
        Class attributeClass = [entityMapping classForProperty:[attribute name]];
        id sourceValue = RKValueForAttributeMappingInRepresentation(attributeMapping, representation);
        id attributeValue = nil;
        id<RKValueTransforming> valueTransformer = attributeMapping.valueTransformer ?: entityMapping.valueTransformer;

        if (sourceValue) [valueTransformer transformValue:sourceValue toValue:&attributeValue ofClass:attributeClass error:&error];
        entityIdentifierAttributes[[attribute name]] = attributeValue ?: [NSNull null];
    }];
    
    return entityIdentifierAttributes;
}

static id RKMutableCollectionValueWithObjectForKeyPath(id object, NSString *keyPath)
{
    id value = [object valueForKeyPath:keyPath];
    if ([value isKindOfClass:[NSArray class]]) {
        return [object mutableArrayValueForKeyPath:keyPath];
    } else if ([value isKindOfClass:[NSSet class]]) {
        return [object mutableSetValueForKeyPath:keyPath];
    } else if ([value isKindOfClass:[NSOrderedSet class]]) {
        return [object mutableOrderedSetValueForKeyPath:keyPath];
    } else if (value) {
        return [NSMutableArray arrayWithObject:value];
    }
    
    return nil;
}

// Pre-condition: invoked from the managed object context of the given object
static BOOL RKDeleteInvalidNewManagedObject(NSManagedObject *managedObject)
{
    if ([managedObject isKindOfClass:[NSManagedObject class]] && [managedObject managedObjectContext] && [managedObject isNew]) {
        NSError *validationError = nil;
        if (! [managedObject validateForInsert:&validationError]) {
            RKLogDebug(@"Unsaved NSManagedObject failed `validateForInsert:` - Deleting object from context: %@", validationError);
            [managedObject.managedObjectContext deleteObject:managedObject];
            return YES;
        }
    }
    
    return NO;
}

@interface RKManagedObjectDeletionOperation : NSOperation

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
- (void)addEntityMapping:(RKEntityMapping *)entityMapping;
@end

@interface RKManagedObjectDeletionOperation ()
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSMutableSet *entityMappings;
@end

@implementation RKManagedObjectDeletionOperation

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    self = [self init];
    if (self) {
        self.managedObjectContext = managedObjectContext;
        self.entityMappings = [NSMutableSet new];
    }
    return self;
}

- (void)addEntityMapping:(RKEntityMapping *)entityMapping
{
    if (! entityMapping.deletionPredicate) return;
    [self.entityMappings addObject:entityMapping];
}

- (void)main
{
    [self.managedObjectContext performBlockAndWait:^{
        NSMutableSet *objectsToDelete = [NSMutableSet set];
        for (RKEntityMapping *entityMapping in self.entityMappings) {
            NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[entityMapping.entity name]];
            [fetchRequest setPredicate:entityMapping.deletionPredicate];
            NSError *error = nil;
            NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
            if (fetchedObjects) {
                [objectsToDelete addObjectsFromArray:fetchedObjects];
            }
        }

        for (NSManagedObject *managedObject in objectsToDelete) {
            [self.managedObjectContext deleteObject:managedObject];
        }
    }];

    self.entityMappings = nil;
}

@end

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent RKlcl_cRestKitCoreData

extern NSString * const RKObjectMappingNestingAttributeKeyName;

@interface RKManagedObjectMappingOperationDataSource ()
@property (nonatomic, strong, readwrite) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong, readwrite) id<RKManagedObjectCaching> managedObjectCache;
@property (nonatomic, strong) NSMutableArray *deletionPredicates;
@end

@implementation RKManagedObjectMappingOperationDataSource

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext cache:(id<RKManagedObjectCaching>)managedObjectCache
{
    NSParameterAssert(managedObjectContext);

    self = [self init];
    if (self) {
        self.managedObjectContext = managedObjectContext;
        self.managedObjectCache = managedObjectCache;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateCacheWithChangesFromContextWillSaveNotification:)
                                                     name:NSManagedObjectContextWillSaveNotification
                                                   object:managedObjectContext];
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)mappingOperation:(RKMappingOperation *)mappingOperation targetObjectForMapping:(RKObjectMapping *)mapping inRelationship:(RKRelationshipMapping *)relationship
{
    if (! [mapping isKindOfClass:[RKEntityMapping class]]) {
        return [mapping.objectClass new];
    }

    return nil;
}

- (id)mappingOperation:(RKMappingOperation *)mappingOperation targetObjectForRepresentation:(NSDictionary *)representation withMapping:(RKObjectMapping *)mapping inRelationship:(RKRelationshipMapping *)relationship
{
    NSAssert(representation, @"Mappable data cannot be nil");
    NSAssert(self.managedObjectContext, @"%@ must be initialized with a managed object context.", [self class]);

    if (! [mapping isKindOfClass:[RKEntityMapping class]]) {
        return [mapping.objectClass new];
    }

    RKEntityMapping *entityMapping = (RKEntityMapping *)mapping;
    NSDictionary *entityIdentifierAttributes = RKEntityIdentificationAttributesForEntityMappingWithRepresentation(entityMapping, representation);
    if (! self.managedObjectCache) {
        RKLogWarning(@"Performing managed object mapping with a nil managed object cache:\n"
                      "Unable to update existing object instances by identification attributes. Duplicate objects may be created.");
    }
    
    NSEntityDescription *entity = [entityMapping entity];
    NSManagedObject *managedObject = nil;
    
    // If we are mapping within a relationship, try to find an existing object without identifying attributes
    // NOTE: We avoid doing the mutable(Array|Set|OrderedSet)ValueForKey if there are identification attributes for performance (see issue GH-1232)
    if (relationship) {
        NSArray *identificationAttributes = [entityMapping.identificationAttributes valueForKey:@"name"];
        id existingObjectsOfRelationship = identificationAttributes ? [mappingOperation.destinationObject valueForKeyPath:relationship.destinationKeyPath] : RKMutableCollectionValueWithObjectForKeyPath(mappingOperation.destinationObject, relationship.destinationKeyPath);
        if (existingObjectsOfRelationship && !RKObjectIsCollection(existingObjectsOfRelationship)) existingObjectsOfRelationship = @[ existingObjectsOfRelationship ];
        NSSet *setWithNull = [NSSet setWithObject:[NSNull null]];
        for (NSManagedObject *existingObject in existingObjectsOfRelationship) {
            if(existingObject.isDeleted) {
                continue;
            }
            
            if (!identificationAttributes) {
                managedObject = existingObject;
                [existingObjectsOfRelationship removeObject:managedObject];
                break;
            }
            
            NSDictionary *identificationAttributeValues = [existingObject dictionaryWithValuesForKeys:identificationAttributes];
            if ([[NSSet setWithArray:[identificationAttributeValues allValues]] isEqualToSet:setWithNull]) {
                managedObject = existingObject;
                break;
            }
        }
    }
    
    // If we have found the entity identification attributes, try to find an existing instance to update
    if ([entityIdentifierAttributes count]) {
        NSSet *objects = [self.managedObjectCache managedObjectsWithEntity:entity
                                                           attributeValues:entityIdentifierAttributes
                                                    inManagedObjectContext:self.managedObjectContext];
        if (entityMapping.identificationPredicate) objects = [objects filteredSetUsingPredicate:entityMapping.identificationPredicate];
        if (entityMapping.identificationPredicateBlock) {
            NSPredicate *predicate = entityMapping.identificationPredicateBlock(representation, self.managedObjectContext);
            if (predicate) objects = [objects filteredSetUsingPredicate:predicate];
        }
        if ([objects count] > 0) {
            managedObject = [objects anyObject];
            if ([objects count] > 1) RKLogWarning(@"Managed object cache returned %ld objects for the identifier configured for the '%@' entity, expected 1.", (long) [objects count], [entity name]);
        }
        if (managedObject && [self.managedObjectCache respondsToSelector:@selector(didFetchObject:)]) {
            [self.managedObjectCache didFetchObject:managedObject];
        }
    }

    if (managedObject == nil) {
        NSEntityDescription *localEntity = [NSEntityDescription entityForName:[entity name] inManagedObjectContext:self.managedObjectContext];
        managedObject = [[NSManagedObject alloc] initWithEntity:localEntity insertIntoManagedObjectContext:self.managedObjectContext];
        [managedObject setValuesForKeysWithDictionary:entityIdentifierAttributes];        
        if (entityMapping.persistentStore) [self.managedObjectContext assignObject:managedObject toPersistentStore:entityMapping.persistentStore];

        if ([self.managedObjectCache respondsToSelector:@selector(didCreateObject:)]) {
            [self.managedObjectCache didCreateObject:managedObject];
        }
    }

    return managedObject;
}

// Mapping operations should be executed against managed object contexts with the `NSPrivateQueueConcurrencyType` concurrency type
- (BOOL)executingConnectionOperationsWouldDeadlock
{
    return [NSThread isMainThread] && [self.managedObjectContext concurrencyType] == NSMainQueueConcurrencyType && self.operationQueue;
}

- (void)emitDeadlockWarningIfNecessary
{
    if ([self executingConnectionOperationsWouldDeadlock]) {
        RKLogWarning(@"Mapping operation was configured with a managedObjectContext with the `NSMainQueueConcurrencyType` concurrency type"
                      " and given an operationQueue to perform background work. This configuration will lead to a deadlock with"
                      " the main queue waiting on the mapping to complete and the operationQueue waiting for access to the MOC."
                      " You should instead provide a managedObjectContext with the NSPrivateQueueConcurrencyType.");
    }
}

- (BOOL)commitChangesForMappingOperation:(RKMappingOperation *)mappingOperation error:(NSError **)error
{
    if ([mappingOperation.objectMapping isKindOfClass:[RKEntityMapping class]]) {
        [self emitDeadlockWarningIfNecessary];
        
        RKEntityMapping *entityMapping = (RKEntityMapping *)mappingOperation.objectMapping;
        NSArray *connections = [entityMapping connections];
        if ([connections count] > 0 && self.managedObjectCache == nil) {
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Cannot map an entity mapping that contains connection mappings with a data source whose managed object cache is nil." };
            NSError *localError = [NSError errorWithDomain:RKErrorDomain code:RKMappingErrorNilManagedObjectCache userInfo:userInfo];
            if (error) *error = localError;
            return NO;
        }
        
        /**
         Attempt to establish the connections and delete the object if its invalid once we are done
         
         NOTE: We obtain a weak reference to the MOC to avoid a potential crash under iOS 5 if the MOC is deallocated before the operation executes. Under iOS 6, the object returns a nil `managedObjectContext` and the `performBlockAndWait:` message is sent to nil.
         */
        NSOperationQueue *operationQueue = self.operationQueue ?: [NSOperationQueue currentQueue];
        __weak NSManagedObjectContext *weakContext = [(NSManagedObject *)mappingOperation.destinationObject managedObjectContext];
        NSBlockOperation *deletionOperation = entityMapping.discardsInvalidObjectsOnInsert ? [NSBlockOperation blockOperationWithBlock:^{
            [weakContext performBlockAndWait:^{
                RKDeleteInvalidNewManagedObject(mappingOperation.destinationObject);
            }];
        }] : nil;
        
        // Add a dependency on the parent operation. If we are being mapped as part of a relationship, then the assignment of the mapped object to a parent may well fulfill the validation requirements. This ensures that the relationship mapping has completed before we evaluate the object for deletion.
        if (self.parentOperation) [deletionOperation addDependency:self.parentOperation];

        RKRelationshipConnectionOperation *connectionOperation = nil;
        if ([connections count]) {
            connectionOperation = [[RKRelationshipConnectionOperation alloc] initWithManagedObject:mappingOperation.destinationObject connections:connections managedObjectCache:self.managedObjectCache];
            [connectionOperation setConnectionBlock:^(RKRelationshipConnectionOperation *operation, RKConnectionDescription *connection, id connectedValue) {
                if (connectedValue) {
                    if ([mappingOperation.delegate respondsToSelector:@selector(mappingOperation:didConnectRelationship:toValue:usingConnection:)]) {
                        [mappingOperation.delegate mappingOperation:mappingOperation didConnectRelationship:connection.relationship toValue:connectedValue usingConnection:connection];
                    }
                } else {
                    if ([mappingOperation.delegate respondsToSelector:@selector(mappingOperation:didFailToConnectRelationship:usingConnection:)]) {
                        [mappingOperation.delegate mappingOperation:mappingOperation didFailToConnectRelationship:connection.relationship usingConnection:connection];
                    }
                }
            }];
            
            if (self.parentOperation) [connectionOperation addDependency:self.parentOperation];
            [deletionOperation addDependency:connectionOperation];
            [operationQueue addOperation:connectionOperation];
            RKLogTrace(@"Enqueued %@ dependent upon parent operation %@ to operation queue %@", connectionOperation, self.parentOperation, operationQueue);
        }
        
        // Enqueue our deletion operation for execution after all the connections
        [operationQueue addOperation:deletionOperation];

        // Handle tombstone deletion by predicate
        if ([(RKEntityMapping *)mappingOperation.objectMapping deletionPredicate]) {
            RKManagedObjectDeletionOperation *predicateDeletionOperation = nil;
            // Attach a deletion operation for execution after the parent operation completes
            predicateDeletionOperation = (RKManagedObjectDeletionOperation *)objc_getAssociatedObject(self.parentOperation, RKManagedObjectMappingOperationDataSourceAssociatedObjectKey);
            if (! predicateDeletionOperation) {
                predicateDeletionOperation = [[RKManagedObjectDeletionOperation alloc] initWithManagedObjectContext:self.managedObjectContext];

                // Attach a deletion operation for execution after the parent operation completes
                if (self.parentOperation) {
                    objc_setAssociatedObject(self.parentOperation, RKManagedObjectMappingOperationDataSourceAssociatedObjectKey, predicateDeletionOperation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                    [predicateDeletionOperation addDependency:self.parentOperation];
                }

                // Ensure predicate deletion executes after any connections have been established
                if (connectionOperation) [predicateDeletionOperation addDependency:connectionOperation];

                [operationQueue addOperation:predicateDeletionOperation];
            }
            [predicateDeletionOperation addEntityMapping:(RKEntityMapping *)mappingOperation.objectMapping];
        }
    }
    
    return YES;
}

// NOTE: In theory we should be able to use the userInfo dictionary, but the dictionary was coming in empty (12/18/2012)
- (void)updateCacheWithChangesFromContextWillSaveNotification:(NSNotification *)notification
{
    NSSet *objectsToAdd = [[self.managedObjectContext insertedObjects] setByAddingObjectsFromSet:[self.managedObjectContext updatedObjects]];
    
    __block BOOL success;
    __block NSError *error = nil;
    [self.managedObjectContext performBlockAndWait:^{
        success = [self.managedObjectContext obtainPermanentIDsForObjects:[objectsToAdd allObjects] error:&error];
    }];
    
    if (! success) {
        RKLogWarning(@"Failed obtaining permanent managed object ID's for %ld objects: the managed object cache was not updated and duplicate objects may be created.", (long) [objectsToAdd count]);
        RKLogError(@"Obtaining permanent managed object IDs failed with error: %@", error);
        return;
    }
    
    // Update the cache
    if ([self.managedObjectCache respondsToSelector:@selector(didFetchObject:)]) {
        for (NSManagedObject *managedObject in objectsToAdd) {
            [self.managedObjectCache didFetchObject:managedObject];
        }
    }
    
    if ([self.managedObjectCache respondsToSelector:@selector(didDeleteObject:)]) {
        for (NSManagedObject *managedObject in [self.managedObjectContext deletedObjects]) {
            [self.managedObjectCache didDeleteObject:managedObject];
        }
    }
}

- (BOOL)mappingOperation:(RKMappingOperation *)mappingOperation deleteExistingValueOfRelationshipWithMapping:(RKRelationshipMapping *)relationshipMapping error:(NSError **)error
{
    // Validate the assignment policy
    if (relationshipMapping.assignmentPolicy != RKReplaceAssignmentPolicy) {
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Unable to satisfy deletion request: Relationship mapping was expected to have an assignment policy of `RKReplaceAssignmentPolicy`, but did not." };
        NSError *localError = [NSError errorWithDomain:RKErrorDomain code:RKMappingErrorInvalidAssignmentPolicy userInfo:userInfo];
        if (error) *error = localError;
        return NO;
    }
    
    // Delete any managed objects at the destination key path from the context
    id existingValue = [mappingOperation.destinationObject valueForKeyPath:relationshipMapping.destinationKeyPath];
    if ([existingValue isKindOfClass:[NSManagedObject class]]) {
        [self.managedObjectContext deleteObject:existingValue];
    } else {
        if (RKObjectIsCollection(existingValue)) {
            for (NSManagedObject *managedObject in existingValue) {
                if (! [managedObject isKindOfClass:[NSManagedObject class]]) continue;
                [self.managedObjectContext deleteObject:managedObject];
            }
        }
    }
    
    return YES;
}

- (BOOL)mappingOperationShouldSetUnchangedValues:(RKMappingOperation *)mappingOperation
{
    // Only new objects should have a temporary ID
    if ([mappingOperation.destinationObject isKindOfClass:[NSManagedObject class]]) {
        return [[(NSManagedObject *)mappingOperation.destinationObject objectID] isTemporaryID];
    }
    
    return [mappingOperation isNewDestinationObject];
}

- (BOOL)isDestinationObjectNotModifiedInMappingOperation:(RKMappingOperation *)mappingOperation {
    // Use concrete mapping or original mapping if not available
    RKMapping *checkedMapping = mappingOperation.objectMapping ?: mappingOperation.mapping;
    
    if (! [checkedMapping isKindOfClass:[RKEntityMapping class]]) return NO;
    RKEntityMapping *entityMapping = (RKEntityMapping *)checkedMapping;
    NSString *modificationKey = [entityMapping.modificationAttribute name];
    if (! modificationKey) return NO;
    id currentValue = [mappingOperation.destinationObject valueForKey:modificationKey];
    if (! currentValue) return NO;
    if (! [currentValue respondsToSelector:@selector(compare:)]) return NO;
    
    RKPropertyMapping *propertyMappingForModificationKey = [(RKEntityMapping *)checkedMapping mappingForDestinationKeyPath:modificationKey];
    id rawValue = [[mappingOperation sourceObject] valueForKeyPath:propertyMappingForModificationKey.sourceKeyPath];
    if (! rawValue) return NO;
    Class attributeClass = [entityMapping classForProperty:propertyMappingForModificationKey.destinationKeyPath];

    id transformedValue = nil;
    NSError *error = nil;
    id<RKValueTransforming> valueTransformer = propertyMappingForModificationKey.valueTransformer ?: entityMapping.valueTransformer;
    [valueTransformer transformValue:rawValue toValue:&transformedValue ofClass:attributeClass error:&error];
    if (! transformedValue) return NO;
    
    if ([currentValue isKindOfClass:[NSString class]]) {
        return [currentValue isEqualToString:transformedValue];
    } else {
        return [currentValue compare:transformedValue] != NSOrderedAscending;
    }
}

- (BOOL)mappingOperationShouldSkipAttributeMapping:(RKMappingOperation *)mappingOperation
{
    return [self isDestinationObjectNotModifiedInMappingOperation:mappingOperation];
}

- (BOOL)mappingOperationShouldSkipRelationshipMapping:(RKMappingOperation *)mappingOperation
{
    // Use concrete mapping or original mapping if not available
    RKMapping *checkedMapping = mappingOperation.objectMapping ?: mappingOperation.mapping;
    
    if (! [checkedMapping isKindOfClass:[RKEntityMapping class]]) return NO;
    RKEntityMapping *entityMapping = (id)checkedMapping;
    if (entityMapping.shouldMapRelationshipsIfObjectIsUnmodified) {
        return NO;
    } else {
        return [self isDestinationObjectNotModifiedInMappingOperation:mappingOperation];
    }
}

- (BOOL)mappingOperationShouldCollectMappingInfo:(RKMappingOperation *)mappingOperation
{
    return YES;
}

@end
