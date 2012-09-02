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
#import "RKConnectionMapping.h"
#import "RKMacros.h"

@class RKManagedObjectStore;

/**
 RKEntityMapping objects model an object mapping with a Core Data destination entity.
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
@property (nonatomic, strong, readonly) NSEntityDescription *entity;

/**
 The name of the attribute on the destination entity that acts as the primary key for instances
 of the entity in the remote backend system. Used to uniquely identify objects within the store
 so that existing objects are updated rather than creating new ones.

 @warning Note that primaryKeyAttribute defaults to the primaryKeyAttribute configured
 on the NSEntityDescription for the entity targetted by the receiving mapping. This provides
 flexibility in cases where a single entity is the target of many mappings with differing
 primary key definitions.

 If the primaryKeyAttribute is set on an RKManagedObjectMapping that targets an entity with a
 nil primaryKeyAttribute, then the primaryKeyAttribute will be set on the entity as well for
 convenience and backwards compatibility. This may change in the future.

 @see [NSEntityDescription primaryKeyAttribute]
 */
// TODO: Make me readonly
@property (nonatomic, strong) NSString *primaryKeyAttribute;

/**
 Retrieves an array of RKConnectionMapping objects for connecting the receiver's relationships
 by primary key.

 @see RKConnectionMapping
 */
@property (weak, nonatomic, readonly) NSArray *connectionMappings;

/**
 Adds a connection mapping to the receiver.

 @param connectionMapping The connection mapping to be added.
 */
- (void)addConnectionMapping:(RKConnectionMapping *)connectionMapping;
- (void)addConnectionMappingsFromArray:(NSArray *)arrayOfConnectionMappings;

// Convenience method.
- (RKConnectionMapping *)addConnectionMappingForRelationshipForName:(NSString *)relationshipName
                                                  fromSourceKeyPath:(NSString *)sourceKeyPath
                                                          toKeyPath:(NSString *)destinationKeyPath
                                                            matcher:(RKDynamicMappingMatcher *)matcher;

/**
 Removes a connection mapping from the receiver.

 @param connectionMapping The connection mapping to be added.
 */
- (void)removeConnectionMapping:(RKConnectionMapping *)connectionMapping;

/**
 Returns the default value for the specified attribute as expressed in the Core Data entity definition. This value will
 be assigned if the object mapping is applied and a value for a missing attribute is not present in the payload.
 */
- (id)defaultValueForMissingAttribute:(NSString *)attributeName;

@end
