//
//  RKManagedObjectMapping.h
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
//#import "RKManagedObjectStore.h"

/**
 Mode that specifies how the object should be synchronized with the server.
 To use transparent syncing (i.e. calls are sent when network access is available
 and queued otherwise), set the mode to `RKSyncModeTransparent` on each object
 mapping for which you would like this behavior.
 */
typedef enum {
    RKSyncModeDefault,        /** RKSyncManager will use the default syncMode set on the syncManager */
    RKSyncModeNone,           /** RKSyncManager will ignore objects with this mode */
    RKSyncModeTransparent,    /** RKSyncManager will transparently sync objects with this mode */
    RKSyncModeInterval,       /** RKSyncManager will sync objects with this mode at an interval */
    RKSyncModeManual          /** RKSyncManager will queue requests until `[syncManager push]` is called */
} RKSyncMode;

/**
 Sync strategy sets the behavior of the RKSyncManager queue for a given mapping.
 */
typedef enum {
    RKSyncStrategyDefault,     /** RKSyncManager will use the default strategy set on the syncManager */
    RKSyncStrategyBatch,        /** RKSyncManager will try to reduce network requests by batching similar requests (where possible) & locally removing any objects that never were persisted remotely in the first place. */
    RKSyncStrategyProxyOnly,    /** RKSyncManager will not perform any batching; when network access is available, it will send all queued requests in the order it received them. */
} RKSyncStrategy;

/**
 Sync direction sets the behavior of the RKSyncManager queue for a given mapping.
 */
typedef enum {
    RKSyncDirectionDefault = 0x00, /** RKSyncManager will use the default direction set on the syncManager */
    RKSyncDirectionPush = 0x001,  /** RKSyncManager will push requests, but not pull anything. */
    RKSyncDirectionPull = 0x010,  /** RKSyncManager will pull requests, but not push anything. */
    RKSyncDirectionBoth = 0x011   /** RKSyncManager will push requests, and then pull those same routes (true syncing). */
} RKSyncDirection;

@class RKManagedObjectStore;

/**
 An RKManagedObjectMapping defines an object mapping with a Core Data destination
 entity.
 */
@interface RKManagedObjectMapping : RKObjectMapping {
    NSEntityDescription *_entity;
    NSString *_primaryKeyAttribute;
    NSMutableDictionary *_relationshipToPrimaryKeyMappings;
}

/**
 Creates a new object mapping targetting the Core Data entity represented by objectClass
 */
+ (id)mappingForClass:(Class)objectClass inManagedObjectStore:(RKManagedObjectStore *)objectStore;

/**
 Creates a new object mapping targetting the specified Core Data entity
 */
+ (RKManagedObjectMapping *)mappingForEntity:(NSEntityDescription *)entity inManagedObjectStore:(RKManagedObjectStore *)objectStore;

/**
 Creates a new object mapping targetting the Core Data entity with the specified name.
 The entity description is fetched from the managed object context associated with objectStore
 */
+ (RKManagedObjectMapping *)mappingForEntityWithName:(NSString *)entityName inManagedObjectStore:(RKManagedObjectStore *)objectStore;

/**
 The Core Data entity description used for this object mapping
 */
@property (nonatomic, readonly) NSEntityDescription *entity;

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
 Returns a dictionary containing Core Data relationships and attribute pairs containing
 the primary key for
 */
@property (nonatomic, readonly) NSDictionary *relationshipsAndPrimaryKeyAttributes;

/**
 The RKManagedObjectStore containing the Core Data entity being mapped
 */
@property (nonatomic, readonly) RKManagedObjectStore *objectStore;

/**
 The RKSyncMode specifies how objects should be synced, if at all. By default this is set to RKSyncModeNone, or whatever is specified in defaultSyncMode on RKSyncManager.
 
 If set to RKSyncModeNone, the objects will not be managed by `RKSyncManager`. 
 If set to RKSyncModeTransparent, the objects will be synced immediately if a connection is available, or saved for later and synced as soon as a connection is available. 
 If set to RKSyncModeInterval, the objects will be synced at a regular interval set by the syncManager.
 If set to RKSyncModeManual, the objects will be synced only when a call is made directly on the syncManager to do so.
 RKSyncInterval is for convenience - to sync with a set interval, create a timer that calls `[syncManager syncObjectsWithSyncMode:RKSyncModeInterval andClass:nil];` This could be done with any of the other types of syncMode, but setting to RKSyncInterval prevents those objects from being synced manually or transparently as well.
 @see RKSyncManager
 */
@property (nonatomic, assign) RKSyncMode syncMode;

/**
 Sync direction sets the behavior of the RKSyncManager queue for a given mapping. If set to Push, RKSyncManager will push requests, but not pull anything.  If set to Pull, RKSyncManager will pull requests, but not push anything. If set to Sync, RKSyncManager will push requests, and then pull those same routes (true syncing). 
 @see RKSyncManager
 */
@property (nonatomic, assign) RKSyncDirection syncDirection;


/**
 If syncMode != RKSyncModeNone, sync strategy sets the behavior of the RKSyncManager queue for a given mapping. If set to batch, RKSyncManager will try to reduce network requests by batching similar requests (where possible) & locally removing any objects that never were persisted remotely in the first place. If set to proxyOnly, RKSyncManager will not perform any batching; when network access is available, it will send all queued requests in the order it received them. 
 @see RKSyncManager
 */
@property (nonatomic, assign) RKSyncStrategy syncStrategy;

/**
 Instructs RestKit to automatically connect a relationship of the object being mapped by looking up 
 the related object by primary key.

 For example, given a Project object associated with a User, where the 'user' relationship is
 specified by a userID property on the managed object:

 [mapping connectRelationship:@"user" withObjectForPrimaryKeyAttribute:@"userID"];

 Will hydrate the 'user' association on the managed object with the object
 in the local object graph having the primary key specified in the managed object's
 userID property.

 In effect, this approach allows foreign key relationships between managed objects
 to be automatically maintained from the server to the underlying Core Data object graph.
 */
- (void)connectRelationship:(NSString *)relationshipName withObjectForPrimaryKeyAttribute:(NSString *)primaryKeyAttribute;

/**
 Connects relationships using the primary key values contained in the specified attribute. This method is
 a short-cut for repeated invocation of `connectRelationship:withObjectForPrimaryKeyAttribute:`.

 @see connectRelationship:withObjectForPrimaryKeyAttribute:
 */
- (void)connectRelationshipsWithObjectsForPrimaryKeyAttributes:(NSString *)firstRelationshipName, ... NS_REQUIRES_NIL_TERMINATION;

/**
 Conditionally connect a relationship of the object being mapped when the object being mapped has
 keyPath equal to a specified value.

 For example, given a Project object associated with a User, where the 'admin' relationship is
 specified by a adminID property on the managed object:

 [mapping connectRelationship:@"admin" withObjectForPrimaryKeyAttribute:@"adminID" whenValueOfKeyPath:@"userType" isEqualTo:@"Admin"];

 Will hydrate the 'admin' association on the managed object with the object
 in the local object graph having the primary key specified in the managed object's
 userID property.  Note that this connection will only occur when the Product's 'userType'
 property equals 'Admin'. In cases where no match occurs, the relationship connection is skipped.

 @see connectRelationship:withObjectForPrimaryKeyAttribute:
 */
- (void)connectRelationship:(NSString *)relationshipName withObjectForPrimaryKeyAttribute:(NSString *)primaryKeyAttribute whenValueOfKeyPath:(NSString *)keyPath isEqualTo:(id)value;

/**
 Conditionally connect a relationship of the object being mapped when the object being mapped has
 block evaluate to YES. This variant is useful in cases where you want to execute an arbitrary
 block to determine whether or not to connect a relationship.

 For example, given a Project object associated with a User, where the 'admin' relationship is
 specified by a adminID property on the managed object:

 [mapping connectRelationship:@"admin" withObjectForPrimaryKeyAttribute:@"adminID" usingEvaluationBlock:^(id data) {
    return [User isAuthenticated];
 }];

 Will hydrate the 'admin' association on the managed object with the object
 in the local object graph having the primary key specified in the managed object's
 userID property.  Note that this connection will only occur when the provided block evalutes to YES.
 In cases where no match occurs, the relationship connection is skipped.

 @see connectRelationship:withObjectForPrimaryKeyAttribute:
 */
- (void)connectRelationship:(NSString *)relationshipName withObjectForPrimaryKeyAttribute:(NSString *)primaryKeyAttribute usingEvaluationBlock:(BOOL (^)(id data))block;

/**
 Initialize a managed object mapping with a Core Data entity description and a RestKit managed object store
 */
- (id)initWithEntity:(NSEntityDescription *)entity inManagedObjectStore:(RKManagedObjectStore *)objectStore;

/**
 Returns the default value for the specified attribute as expressed in the Core Data entity definition. This value will
 be assigned if the object mapping is applied and a value for a missing attribute is not present in the payload.
 */
- (id)defaultValueForMissingAttribute:(NSString *)attributeName;

@end
