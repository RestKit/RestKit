//
//  RKEntityMapping.h
//  RestKit
//
//  Created by Blake Watters on 5/31/11.
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

#import <CoreData/CoreData.h>
#import "RKObjectMapping.h"
#import "RKConnectionDescription.h"
#import "RKMacros.h"
#import "RKEntityIdentifier.h"

@class RKManagedObjectStore;

/**
 RKEntityMapping objects model an object mapping with a Core Data destination entity.
 
 ## Entity Identification
 
 TBD
 
 ### Inferring Entity Identifiers
 
 TBD
 
 ## Connecting Relationships
 
 TBD
 */
@interface RKEntityMapping : RKObjectMapping

///-----------------------------------------------------------------------------
/// @name Initializing an Entity Mapping
///-----------------------------------------------------------------------------

/**
 Initializes the receiver with a given entity.

 @param entity An entity with which to initialize the receiver.
 @returns The receiver, initialized with the given entity.
 */
- (id)initWithEntity:(NSEntityDescription *)entity;

/**
 A convenience initializer that creates and returns an entity mapping for the entity with the given name in
 the managed object model of the given managed object store.

 This method is functionally equivalent to the following example code:

     NSEntityDescription *entity = [[managedObjectStore.managedObjectModel entitiesByName] objectForKey:entityName];
     return [RKEntityMapping mappingForEntity:entity];

 @param entityName The name of the entity in the managed object model for which an entity mapping is to be created.
 @param managedObjectStore A managed object store containing the managed object model in which an entity with the given name is defined.
 @return A new entity mapping for the entity with the given name in the managed object model of the given managed object store.
 */
+ (id)mappingForEntityForName:(NSString *)entityName inManagedObjectStore:(RKManagedObjectStore *)managedObjectStore;

/**
 The Core Data entity description used for this object mapping
 */
@property (nonatomic, strong) NSEntityDescription *entity;

// The index for finding existing objects. Can be compound.
@property (nonatomic, copy) RKEntityIdentifier *entityIdentifier;

// Setting an existing entity identifier replaces it...
- (void)setEntityIdentifier:(RKEntityIdentifier *)entityIdentifier forRelationship:(NSString *)relationshipName;

// NOTE: This returns explicitly set value, then the entityIdentifier for the relationship mapping
- (RKEntityIdentifier *)entityIdentifierForRelationship:(NSString *)relationshipName;

///**
// The name of the attribute on the destination entity that acts as the primary key for instances
// of the entity in the remote backend system. Used to uniquely identify objects within the store
// so that existing objects are updated rather than creating new ones.
//
// @warning Note that primaryKeyAttribute defaults to the primaryKeyAttribute configured
// on the NSEntityDescription for the entity targetted by the receiving mapping. This provides
// flexibility in cases where a single entity is the target of many mappings with differing
// primary key definitions.
//
// If the `primaryKeyAttribute` is set on an `RKEntityMapping` that targets an entity with a
// nil primaryKeyAttribute, then the primaryKeyAttribute will be set on the entity as well for
// convenience and backwards compatibility. This may change in the future.
//
// @see `[NSEntityDescription primaryKeyAttribute]`
// */
//// TODO: Make me readonly
//@property (nonatomic, strong) NSString *primaryKeyAttribute;

@property (weak, nonatomic, readonly) NSArray *connections;

/**
 Adds a connection mapping to the receiver.

 @param connectionMapping The connection mapping to be added.
 */
- (void)addConnection:(RKConnectionDescription *)connection;
- (void)removeConnection:(RKConnectionDescription *)connection;
- (void)addConnectionForRelationship:(id)relationshipOrName connectedBy:(id)connectionSpecifier;
- (RKConnectionDescription *)connectionForRelationship:(id)relationshipOrName;

///------------------------------------------
/// @name Retrieving Default Attribute Values
///------------------------------------------

/**
 Returns the default value for the specified attribute as expressed in the Core Data entity definition. This value will
 be assigned if the object mapping is applied and a value for a missing attribute is not present in the payload.
 */
- (id)defaultValueForAttribute:(NSString *)attributeName;

///----------------------------------------------
/// @name Configuring Entity Identifier Inference
///----------------------------------------------

// setInfersEntityIdentifiers:(BOOL) | setShouldInferEntityIdentifiers:
// setEntityIdentificationInferenceEnabled: | :
+ (void)setEntityIdentifierInferenceEnabled:(BOOL)enabled; // Default YES
+ (BOOL)isEntityIdentifierInferenceEnabled;

@end
