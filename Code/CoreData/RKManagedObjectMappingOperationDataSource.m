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

#import <objc/runtime.h>
#import "RKManagedObjectMappingOperationDataSource.h"
#import "RKObjectMapping.h"
#import "RKEntityMapping.h"
#import "RKLog.h"
#import "RKManagedObjectStore.h"
#import "RKMappingOperation.h"
#import "RKObjectMappingMatcher.h"
#import "RKManagedObjectCaching.h"
#import "RKRelationshipConnectionOperation.h"
#import "RKMappingErrors.h"
#import "RKValueTransformers.h"
#import "RKRelationshipMapping.h"
#import "RKObjectUtilities.h"
#import "NSManagedObject+RKAdditions.h"

extern NSString * const RKObjectMappingNestingAttributeKeyName;

static char kRKManagedObjectMappingOperationDataSourceAssociatedObjectKey;

id RKTransformedValueWithClass(id value, Class destinationType, NSValueTransformer *dateToStringValueTransformer);
NSArray *RKApplyNestingAttributeValueToMappings(NSString *attributeName, id value, NSArray *propertyMappings);

// Return YES if the entity is identified by an attribute that acts as the nesting key in the source representation
static BOOL RKEntityMappingIsIdentifiedByNestingAttribute(RKEntityMapping *entityMapping)
{
    for (NSAttributeDescription *attribute in [entityMapping identificationAttributes]) {
        RKAttributeMapping *attributeMapping = [[entityMapping propertyMappingsByDestinationKeyPath] objectForKey:[attribute name]];
        if ([attributeMapping.sourceKeyPath isEqualToString:RKObjectMappingNestingAttributeKeyName]) {
            return YES;
        }
    }
    
    return NO;
}

static id RKValueForAttributeMappingInRepresentation(RKAttributeMapping *attributeMapping, NSDictionary *representation)
{
    if ([attributeMapping.sourceKeyPath isEqualToString:RKObjectMappingNestingAttributeKeyName]) {
        return [[representation allKeys] lastObject];
    } else if (attributeMapping.sourceKeyPath == nil){
        return [representation objectForKey:[NSNull null]];
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
    
    RKDateToStringValueTransformer *dateToStringTransformer = [[RKDateToStringValueTransformer alloc] initWithDateToStringFormatter:entityMapping.preferredDateFormatter
                                                                                                             stringToDateFormatters:entityMapping.dateFormatters];
    NSArray *attributeMappings = entityMapping.attributeMappings;
    
    // If the representation is mapped with a nesting attribute, we must apply the nesting value to the representation before constructing the identification attributes
    RKAttributeMapping *nestingAttributeMapping = [[entityMapping propertyMappingsBySourceKeyPath] objectForKey:RKObjectMappingNestingAttributeKeyName];
    if (nestingAttributeMapping) {
        Class attributeClass = [entityMapping classForProperty:nestingAttributeMapping.destinationKeyPath];
        id attributeValue = RKTransformedValueWithClass([[representation allKeys] lastObject], attributeClass, dateToStringTransformer);
        attributeMappings = RKApplyNestingAttributeValueToMappings(nestingAttributeMapping.destinationKeyPath, attributeValue, attributeMappings);
    }
    
    // Map the identification attributes
    NSMutableDictionary *entityIdentifierAttributes = [NSMutableDictionary dictionaryWithCapacity:[entityMapping.identificationAttributes count]];
    [entityMapping.identificationAttributes enumerateObjectsUsingBlock:^(NSAttributeDescription *attribute, NSUInteger idx, BOOL *stop) {
        RKAttributeMapping *attributeMapping = RKAttributeMappingForNameInMappings([attribute name], attributeMappings);
        Class attributeClass = [entityMapping classForProperty:[attribute name]];
        id sourceValue = RKValueForAttributeMappingInRepresentation(attributeMapping, representation);
        id attributeValue = RKTransformedValueWithClass(sourceValue, attributeClass, dateToStringTransformer);
        [entityIdentifierAttributes setObject:attributeValue ?: [NSNull null] forKey:[attribute name]];
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

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
- (void)addEntityMapping:(RKEntityMapping *)entityMapping;
@end

@interface RKManagedObjectDeletionOperation ()
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSMutableSet *entityMappings;
@end

@implementation RKManagedObjectDeletionOperation

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
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
            NSFetchRequest *fetchRequest = [NSFetchRequest alloc];
            [fetchRequest setEntity:entityMapping.entity];
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

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext cache:(id<RKManagedObjectCaching>)managedObjectCache
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
    if (relationship) {
        id mutableArrayOrSetValueForExistingObjects = RKMutableCollectionValueWithObjectForKeyPath(mappingOperation.destinationObject, relationship.destinationKeyPath);
        NSArray *identificationAttributes = [entityMapping.identificationAttributes valueForKey:@"name"];
        for (NSManagedObject *existingObject in mutableArrayOrSetValueForExistingObjects) {
            if (! identificationAttributes) {
                managedObject = existingObject;
                [mutableArrayOrSetValueForExistingObjects removeObject:managedObject];
                break;
            }
            
            NSDictionary *identificationAttributeValues = [existingObject dictionaryWithValuesForKeys:identificationAttributes];
            if ([[NSSet setWithArray:[identificationAttributeValues allValues]] isEqualToSet:[NSSet setWithObject:[NSNull null]]]) {
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
        if ([objects count] > 0) {
            managedObject = [objects anyObject];
            if ([objects count] > 1) RKLogWarning(@"Managed object cache returned %ld objects for the identifier configured for the '%@' entity, expected 1.", (long) [objects count], [entity name]);
        }
        if (managedObject && [self.managedObjectCache respondsToSelector:@selector(didFetchObject:)]) {
            [self.managedObjectCache didFetchObject:managedObject];
        }
    }

    if (managedObject == nil) {
        managedObject = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:self.managedObjectContext];
        [managedObject setValuesForKeysWithDictionary:entityIdentifierAttributes];

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
        
        NSArray *connections = [(RKEntityMapping *)mappingOperation.objectMapping connections];
        if ([connections count] > 0 && self.managedObjectCache == nil) {
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Cannot map an entity mapping that contains connection mappings with a data source whose managed object cache is nil." };
            NSError *localError = [NSError errorWithDomain:RKErrorDomain code:RKMappingErrorNilManagedObjectCache userInfo:userInfo];
            if (error) *error = localError;
            return NO;
        }
        
        // Delete the object immediately if there are no connections that may make it valid
        if ([connections count] == 0 && RKDeleteInvalidNewManagedObject(mappingOperation.destinationObject)) return YES;
        
        // Attempt to establish the connections and delete the object if its invalid once we are done
        NSOperationQueue *operationQueue = self.operationQueue ?: [NSOperationQueue currentQueue];
        NSBlockOperation *deletionOperation = [NSBlockOperation blockOperationWithBlock:^{
            RKDeleteInvalidNewManagedObject(mappingOperation.destinationObject);
        }];
        
        for (RKConnectionDescription *connection in connections) {
            RKRelationshipConnectionOperation *operation = [[RKRelationshipConnectionOperation alloc] initWithManagedObject:mappingOperation.destinationObject connection:connection managedObjectCache:self.managedObjectCache];
            [operation setConnectionBlock:^(RKRelationshipConnectionOperation *operation, id connectedValue) {
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
            if (self.parentOperation) [operation addDependency:self.parentOperation];
            [deletionOperation addDependency:operation];
            [operationQueue addOperation:operation];
            RKLogTrace(@"Enqueued %@ dependent upon parent operation %@ to operation queue %@", operation, self.parentOperation, operationQueue);
        }
        
        // Enqueue our deletion operation for execution after all the connections
        [operationQueue addOperation:deletionOperation];

        // Handle tombstone deletion by predicate
        if ([(RKEntityMapping *)mappingOperation.objectMapping deletionPredicate]) {
            RKManagedObjectDeletionOperation *deletionOperation = nil;
            if (self.parentOperation) {
                // Attach a deletion operation for execution after the parent operation completes
                deletionOperation = (RKManagedObjectDeletionOperation *)objc_getAssociatedObject(self.parentOperation, &kRKManagedObjectMappingOperationDataSourceAssociatedObjectKey);
                if (! deletionOperation) {
                    deletionOperation = [[RKManagedObjectDeletionOperation alloc] initWithManagedObjectContext:self.managedObjectContext];
                    objc_setAssociatedObject(self.parentOperation, &kRKManagedObjectMappingOperationDataSourceAssociatedObjectKey, deletionOperation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                    [deletionOperation addDependency:self.parentOperation];
                    NSOperationQueue *operationQueue = self.operationQueue ?: [NSOperationQueue currentQueue];
                    [operationQueue addOperation:deletionOperation];
                }
                [deletionOperation addEntityMapping:(RKEntityMapping *)mappingOperation.objectMapping];
            } else {
                deletionOperation = [[RKManagedObjectDeletionOperation alloc] initWithManagedObjectContext:self.managedObjectContext];
                [deletionOperation addEntityMapping:(RKEntityMapping *)mappingOperation.objectMapping];
                [deletionOperation start];
            }
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
    
    if ([self.managedObjectCache respondsToSelector:@selector(didDeleteObject::)]) {
        for (NSManagedObject *managedObject in [self.managedObjectContext deletedObjects]) {
            [self.managedObjectCache didDeleteObject:managedObject];
        }
    }
}

- (BOOL)mappingOperation:(RKMappingOperation *)mappingOperation deleteExistingValueOfRelationshipWithMapping:(RKRelationshipMapping *)relationshipMapping error:(NSError **)error
{
    // Validate the assignment policy
    if (! relationshipMapping.assignmentPolicy == RKReplaceAssignmentPolicy) {
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

@end
