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

@class RKManagedObjectStore;

/**
 RKEntityMapping objects model on object mapping with a Core Data destination entity.
 */
@interface RKEntityMapping : RKObjectMapping

+ (id)mappingForEntityWithName:(NSString *)entityName inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
+ (id)mappingForEntity:(NSEntityDescription *)entity;
- (id)initWithEntity:(NSEntityDescription *)entity;

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
@property (nonatomic, readonly) NSArray *connections;

/**
 Returns the RKObjectRelationshipMapping connection for the specified relationship.
 */
- (RKConnectionMapping *)connectionMappingForRelationshipWithName:(NSString *)relationshipName;

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

 [mapping connectRelationship:@"project" withMapping:projectMapping fromKeyPath:@"id" toKeyPath:@"userId"];

 In effect, this approach allows foreign key relationships between managed objects
 to be automatically maintained from the server to the underlying Core Data object graph.
 */
- (void)connectRelationship:(NSString *)relationshipName withMapping:(RKMapping *)objectOrDynamicMapping fromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath;

/**
 Conditionally connect a relationship of the object being mapped when the object being mapped has
 keyPath equal to a specified value.

 For example, given a Project object associated with a User, where the 'admin' relationship is
 specified by a adminID property on the managed object:

 [mapping connectRelationship:@"admin" withMapping:userMapping fromKeyPath:@"adminId" toKeyPath:@"id" whenValueOfKeyPath:@"userType" isEqualTo:@"Admin"];

 Will hydrate the 'admin' association on the managed object with the object
 in the local object graph having the primary key specified in the managed object's
 userID property.  Note that this connection will only occur when the Product's 'userType'
 property equals 'Admin'. In cases where no match occurs, the relationship connection is skipped.

 @see connectRelationship:withObjectForPrimaryKeyAttribute:
 */
- (void)connectRelationship:(NSString *)relationshipName withMapping:(RKMapping *)objectOrDynamicMapping fromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath whenValueOfKeyPath:(NSString *)keyPath isEqualTo:(id)value;

/**
 Conditionally connect a relationship of the object being mapped when the object being mapped has
 block evaluate to YES. This variant is useful in cases where you want to execute an arbitrary
 block to determine whether or not to connect a relationship.

 For example, given a Project object associated with a User, where the 'admin' relationship is
 specified by a adminID property on the managed object:

 [mapping connectRelationship:@"admin" withMapping:userMapping fromKeyPath:@"adminId" toKeyPath:@"adminID" usingEvaluationBlock:^(id data) {
    return [User isAuthenticated];
 }];

 Will hydrate the 'admin' association on the managed object with the object
 in the local object graph having the primary key specified in the managed object's
 userID property.  Note that this connection will only occur when the provided block evalutes to YES.
 In cases where no match occurs, the relationship connection is skipped.

 @see connectRelationship:withObjectForPrimaryKeyAttribute:
 */
- (void)connectRelationship:(NSString *)relationshipName withMapping:(RKMapping *)objectOrDynamicMapping fromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath usingEvaluationBlock:(BOOL (^)(id data))block;

/**
 Returns the default value for the specified attribute as expressed in the Core Data entity definition. This value will
 be assigned if the object mapping is applied and a value for a missing attribute is not present in the payload.
 */
- (id)defaultValueForMissingAttribute:(NSString *)attributeName;

@end

@interface RKEntityMapping (Deprecations)

/* Deprecated Initialization API's */
+ (id)mappingForClass:(Class)objectClass inManagedObjectStore:(RKManagedObjectStore *)objectStore DEPRECATED_ATTRIBUTE;
+ (RKEntityMapping *)mappingForEntity:(NSEntityDescription *)entity inManagedObjectStore:(RKManagedObjectStore *)objectStore DEPRECATED_ATTRIBUTE;
+ (RKEntityMapping *)mappingForEntityWithName:(NSString *)entityName inManagedObjectStore:(RKManagedObjectStore *)objectStore DEPRECATED_ATTRIBUTE;
- (id)initWithEntity:(NSEntityDescription *)entity inManagedObjectStore:(RKManagedObjectStore *)objectStore DEPRECATED_ATTRIBUTE;

/* Deprecated Connection API's */
- (void)connectRelationship:(NSString *)relationshipName withObjectForPrimaryKeyAttribute:(NSString *)primaryKeyAttribute DEPRECATED_ATTRIBUTE;
- (void)connectRelationship:(NSString *)relationshipName withObjectForPrimaryKeyAttribute:(NSString *)primaryKeyAttribute whenValueOfKeyPath:(NSString *)keyPath isEqualTo:(id)value DEPRECATED_ATTRIBUTE;
- (void)connectRelationshipsWithObjectsForPrimaryKeyAttributes:(NSString *)firstRelationshipName, ... NS_REQUIRES_NIL_TERMINATION DEPRECATED_ATTRIBUTE;
- (void)connectRelationship:(NSString *)relationshipName withObjectForPrimaryKeyAttribute:(NSString *)primaryKeyAttribute usingEvaluationBlock:(BOOL (^)(id data))block DEPRECATED_ATTRIBUTE;

@end
