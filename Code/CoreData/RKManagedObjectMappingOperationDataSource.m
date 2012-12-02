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

#import "RKManagedObjectMappingOperationDataSource.h"
#import "RKObjectMapping.h"
#import "RKEntityMapping.h"
#import "RKLog.h"
#import "RKManagedObjectStore.h"
#import "RKMappingOperation.h"
#import "RKDynamicMappingMatcher.h"
#import "RKManagedObjectCaching.h"
#import "RKRelationshipConnectionOperation.h"
#import "RKMappingErrors.h"
#import "RKValueTransformers.h"

extern NSString * const RKObjectMappingNestingAttributeKeyName;

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

// We always need to map the dynamic nesting attribute first so that sub-key attribute mappings apply cleanly
static NSArray *RKEntityIdentificationAttributesInMappingOrder(RKEntityMapping *entityMapping)
{
    NSMutableArray *orderedAttributes = [NSMutableArray arrayWithCapacity:[[entityMapping identificationAttributes] count]];
    for (NSAttributeDescription *attribute in [entityMapping identificationAttributes]) {
        RKAttributeMapping *attributeMapping = [[entityMapping propertyMappingsByDestinationKeyPath] objectForKey:[attribute name]];
        if ([attributeMapping.sourceKeyPath isEqualToString:RKObjectMappingNestingAttributeKeyName]) {
            // We want to map the nesting attribute first
            [orderedAttributes insertObject:attribute atIndex:0];
        } else {
            [orderedAttributes addObject:attribute];
        }
    }
    
    return orderedAttributes;
}

static id RKValueForAttributeMappingInRepresentation(RKAttributeMapping *attributeMapping, NSDictionary *representation)
{
    if ([attributeMapping.sourceKeyPath isEqualToString:RKObjectMappingNestingAttributeKeyName]) {
        return [[representation allKeys] lastObject];
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
    RKDateToStringValueTransformer *dateToStringTransformer = [[RKDateToStringValueTransformer alloc] initWithDateToStringFormatter:entityMapping.preferredDateFormatter
                                                                                                             stringToDateFormatters:entityMapping.dateFormatters];
    NSArray *orderedAttributes = RKEntityIdentificationAttributesInMappingOrder(entityMapping);
    BOOL containsNestingAttribute = RKEntityMappingIsIdentifiedByNestingAttribute(entityMapping);
    __block NSArray *attributeMappings = entityMapping.attributeMappings;
    if (containsNestingAttribute) RKLogDebug(@"Detected use of nested dictionary key as identifying attribute");

    NSMutableDictionary *entityIdentifierAttributes = [NSMutableDictionary dictionaryWithCapacity:[orderedAttributes count]];
    [orderedAttributes enumerateObjectsUsingBlock:^(NSAttributeDescription *attribute, NSUInteger idx, BOOL *stop) {
        RKAttributeMapping *attributeMapping = RKAttributeMappingForNameInMappings([attribute name], attributeMappings);
        Class attributeClass = [entityMapping classForProperty:[attribute name]];
        id attributeValue = nil;
        if (containsNestingAttribute && idx == 0) {
            // This is the nesting attribute
            attributeValue = RKTransformedValueWithClass([[representation allKeys] lastObject], attributeClass, dateToStringTransformer);
            attributeMappings = RKApplyNestingAttributeValueToMappings([attribute name], attributeValue, attributeMappings);
        } else {
            id sourceValue = RKValueForAttributeMappingInRepresentation(attributeMapping, representation);
            attributeValue = RKTransformedValueWithClass(sourceValue, attributeClass, dateToStringTransformer);
        }
        
        [entityIdentifierAttributes setObject:attributeValue ?: [NSNull null] forKey:[attribute name]];
    }];
    
    return entityIdentifierAttributes;
}

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent RKlcl_cRestKitCoreData

extern NSString * const RKObjectMappingNestingAttributeKeyName;

@interface RKManagedObjectMappingOperationDataSource ()
@property (nonatomic, strong, readwrite) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong, readwrite) id<RKManagedObjectCaching> managedObjectCache;
@end

@implementation RKManagedObjectMappingOperationDataSource

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext cache:(id<RKManagedObjectCaching>)managedObjectCache
{
    NSParameterAssert(managedObjectContext);

    self = [self init];
    if (self) {
        self.managedObjectContext = managedObjectContext;
        self.managedObjectCache = managedObjectCache;
    }

    return self;
}

- (id)mappingOperation:(RKMappingOperation *)mappingOperation targetObjectForRepresentation:(NSDictionary *)representation withMapping:(RKObjectMapping *)mapping
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
                      "Unable to update existing object instances by primary key. Duplicate objects may be created.");
    }

    // If we have found the entity identifier attributes, try to find an existing instance to update
    NSEntityDescription *entity = [entityMapping entity];
    NSManagedObject *managedObject = nil;
    if ([entityIdentifierAttributes count]) {
        NSArray *objects = [self.managedObjectCache managedObjectsWithEntity:entity
                                                             attributeValues:entityIdentifierAttributes
                                                      inManagedObjectContext:self.managedObjectContext];
        if (entityMapping.identificationPredicate) objects = [objects filteredArrayUsingPredicate:entityMapping.identificationPredicate];
        if ([objects count] > 0) {
            managedObject = objects[0];
            if ([objects count] > 1) RKLogWarning(@"Managed object cache returned %ld objects for the identifier configured for the '%@' entity, expected 1.", (long) [objects count], [entity name]);
        }
        if (managedObject && [self.managedObjectCache respondsToSelector:@selector(didFetchObject:)]) {
            [self.managedObjectCache didFetchObject:managedObject];
        }
    }

    if (managedObject == nil) {
        managedObject = [[NSManagedObject alloc] initWithEntity:entity
                           insertIntoManagedObjectContext:self.managedObjectContext];
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

        for (RKConnectionDescription *connection in connections) {
            RKRelationshipConnectionOperation *operation = [[RKRelationshipConnectionOperation alloc] initWithManagedObject:mappingOperation.destinationObject connection:connection managedObjectCache:self.managedObjectCache];
            __weak RKRelationshipConnectionOperation *weakOperation = operation;
            [operation setCompletionBlock:^{
                if (weakOperation.connectedValue) {
                    if ([mappingOperation.delegate respondsToSelector:@selector(mappingOperation:didConnectRelationship:withValue:usingMapping:)]) {
                        [mappingOperation.delegate mappingOperation:mappingOperation didConnectRelationship:connection.relationship toValue:weakOperation.connectedValue usingConnection:connection];
                    }
                } else {
                    if ([mappingOperation.delegate respondsToSelector:@selector(mappingOperation:didFailToConnectRelationship:usingMapping:)]) {
                        [mappingOperation.delegate mappingOperation:mappingOperation didFailToConnectRelationship:connection.relationship usingConnection:connection];
                    }
                }
            }];
            if (self.parentOperation) [operation addDependency:self.parentOperation];
            NSOperationQueue *operationQueue = self.operationQueue ?: [NSOperationQueue currentQueue];
            [operationQueue addOperation:operation];
            RKLogTrace(@"Enqueued %@ dependent upon parent operation %@ to operation queue %@", operation, self.parentOperation, operationQueue);
        }
    }
    
    return YES;
}

@end
