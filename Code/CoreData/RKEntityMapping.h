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
 Creates and returns an entity mapping with a given Core Data entity description.
 
 @param entity The entity the new mapping is for.
 @returns A new entity mapping for the given entity.
 */
+ (id)mappingForEntity:(NSEntityDescription *)entity;

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
@property (nonatomic, retain, readonly) NSEntityDescription *entity;

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
@property (nonatomic, retain) NSString *primaryKeyAttribute;

/**
 Retrieves an array of RKConnectionMapping objects for connecting the receiver's relationships
 by primary key.
 
 @see RKConnectionMapping
 */
@property (nonatomic, readonly) NSArray *connectionMappings;

/**
 Adds a connection mapping to the receiver.
 
 @param connectionMapping The connection mapping to be added.
 */
- (void)addConnectionMapping:(RKConnectionMapping *)connectionMapping;

/**
 Removes a connection mapping from the receiver.
 
 @param connectionMapping The connection mapping to be added.
 */
- (void)removeConnectionMapping:(RKConnectionMapping *)connectionMapping;

/**
 Instructs RestKit to connect a relationship of the object being mapped to the
 appropriate target object(s).  It does this by using the value of the object's
 fromKeyPath attribute to query instances of the target entity that have the
 same value in their toKeyPath attribute.

 Note that connectRelationship runs *after* an object's attributes have been
 mapped and is dependent upon the results of those mappings.  Also, connectRelationship
 will never create a new object - it simply looks up existing objects.   In effect,
 connectRelationship allows foreign key relationships between managed objects
 to be automatically maintained from the server to the underlying Core Data object graph.

 For example, given a Project object associated with a User, where the 'user' relationship is
 specified by a userID property on the managed object:

 [mapping connectRelationship:@"user" withMapping:userMapping fromKeyPath:@"userId" toKeyPath:@"id"];

 Will hydrate the 'user' association on the managed object with the object
 in the local object graph having the primary key specified in the managed object's
 userID property.

 You can also do the reverse. Given a User object associated with a Project, with a
 'project' relationship:

 [mapping connectRelationship:@"project" fromKeyPath:@"id" toKeyPath:@"userId" withMapping:projectMapping];
 */
- (void)connectRelationship:(NSString *)relationshipName fromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath withMapping:(RKMapping *)objectOrDynamicMapping;

/**
 Conditionally connect a relationship of the object being mapped when the object being mapped has
 keyPath equal to a specified value.

 For example, given a Project object associated with a User, where the 'admin' relationship is
 specified by a adminID property on the managed object:

 [mapping connectRelationship:@"admin" fromKeyPath:@"adminId" toKeyPath:@"id" withMapping:userMapping whenValueOfKeyPath:@"userType" isEqualTo:@"Admin"];

 Will hydrate the 'admin' association on the managed object with the object
 in the local object graph having the primary key specified in the managed object's
 userID property.  Note that this connection will only occur when the Product's 'userType'
 property equals 'Admin'. In cases where no match occurs, the relationship connection is skipped.

 @see connectRelationship:withObjectForPrimaryKeyAttribute:
 */
- (void)connectRelationship:(NSString *)relationshipName fromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath withMapping:(RKMapping *)objectOrDynamicMapping whenValueOfKeyPath:(NSString *)keyPath isEqualTo:(id)value;

/**
 Conditionally connect a relationship of the object being mapped when the object being mapped has
 block evaluate to YES. This variant is useful in cases where you want to execute an arbitrary
 block to determine whether or not to connect a relationship.

 For example, given a Project object associated with a User, where the 'admin' relationship is
 specified by a adminID property on the managed object:

 [mapping connectRelationship:@"admin" fromKeyPath:@"adminId" toKeyPath:@"adminID" withMapping:userMapping usingEvaluationBlock:^(id data) {
    return [User isAuthenticated];
 }];

 Will hydrate the 'admin' association on the managed object with the object
 in the local object graph having the primary key specified in the managed object's
 userID property.  Note that this connection will only occur when the provided block evalutes to YES.
 In cases where no match occurs, the relationship connection is skipped.

 @see connectRelationship:withObjectForPrimaryKeyAttribute:
 */
- (void)connectRelationship:(NSString *)relationshipName fromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath withMapping:(RKMapping *)objectOrDynamicMapping usingEvaluationBlock:(BOOL (^)(id data))block;

/**
 Returns the default value for the specified attribute as expressed in the Core Data entity definition. This value will
 be assigned if the object mapping is applied and a value for a missing attribute is not present in the payload.
 */
- (id)defaultValueForMissingAttribute:(NSString *)attributeName;

@end

@interface RKEntityMapping (Deprecations)

/* Deprecated Initialization API's */
+ (id)mappingForClass:(Class)objectClass inManagedObjectStore:(RKManagedObjectStore *)objectStore DEPRECATED_ATTRIBUTE_MESSAGE("Use mappingForEntityForName:inManagedObjectStore:");
+ (RKEntityMapping *)mappingForEntity:(NSEntityDescription *)entity inManagedObjectStore:(RKManagedObjectStore *)objectStore DEPRECATED_ATTRIBUTE_MESSAGE("Use mappingForEntityForName:inManagedObjectStore:");
+ (RKEntityMapping *)mappingForEntityWithName:(NSString *)entityName inManagedObjectStore:(RKManagedObjectStore *)objectStore DEPRECATED_ATTRIBUTE_MESSAGE("Use mappingForEntityForName:inManagedObjectStore:");
- (id)initWithEntity:(NSEntityDescription *)entity inManagedObjectStore:(RKManagedObjectStore *)objectStore DEPRECATED_ATTRIBUTE_MESSAGE("Use mappingForEntity:");

/* Deprecated Connection API's */
- (void)connectRelationship:(NSString *)relationshipName withObjectForPrimaryKeyAttribute:(NSString *)primaryKeyAttribute DEPRECATED_ATTRIBUTE_MESSAGE("Use connectRelationship:withMapping:fromKeyPath:toKeyPath:");
- (void)connectRelationship:(NSString *)relationshipName withObjectForPrimaryKeyAttribute:(NSString *)primaryKeyAttribute whenValueOfKeyPath:(NSString *)keyPath isEqualTo:(id)value DEPRECATED_ATTRIBUTE_MESSAGE("Use connectRelationship:withMapping:fromKeyPath:toKeyPath:whenValueOfKeyPath:isEqualTo:");
- (void)connectRelationshipsWithObjectsForPrimaryKeyAttributes:(NSString *)firstRelationshipName, ... NS_REQUIRES_NIL_TERMINATION DEPRECATED_ATTRIBUTE_MESSAGE("Use connectRelationship:withMapping:fromKeyPath:toKeyPath:");
- (void)connectRelationship:(NSString *)relationshipName withObjectForPrimaryKeyAttribute:(NSString *)primaryKeyAttribute usingEvaluationBlock:(BOOL (^)(id data))block DEPRECATED_ATTRIBUTE_MESSAGE("Use connectRelationship:withMapping:fromKeyPath:toKeyPath:usingEvaluationBlock:");

@end
