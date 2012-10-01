//
//  RKRelationshipConnectionOperation.h
//  RestKit
//
//  Created by Blake Watters on 7/12/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RKConnectionMapping;
@protocol RKManagedObjectCaching;

/**
 The RKRelationshipConnectionOperation class is a subclass of NSOperation that manages the connection
 of NSManagedObject relationships as described by an RKConnectionMapping object. When executed, the 
 operation will find related objects by searching the associated managed object cache for a matching object
 whose destination attribute value matches that of the associated managed object's source attribute.
 
 For example, given a managed object for the `Employee` entity with a one-to-one relationship to a `Company` named `company`
 (with an inverse relationship one-to-many relationship named `employees`) and a connection mapping specifying that
 the relationship can be connected by finding the `Company` managed object whose `companyID` attribute matches the 
 `companyID` of the `Employee`, the operation would find the Company that employs the Employee by primary key and set
 the Core Data relationship to reflect the relationship appropriately.
 
 @see RKConnectionMapping
 */
@interface RKRelationshipConnectionOperation : NSOperation

/**
 The managed object the receiver will attempt to connect a relationship for.
 */
@property (nonatomic, retain, readonly) NSManagedObject *managedObject;

/**
 The connection mapping describing the relationship connection the receiver will attempt to connect.
 */
@property (nonatomic, retain, readonly) RKConnectionMapping *connectionMapping;

/**
 The managed object cache the receiver will use to fetch a related object satisfying the connection
 mapping.
 */
@property (nonatomic, retain, readonly) id<RKManagedObjectCaching> managedObjectCache;

/**
 Initializes the receiver with a given managed object, connection mapping, and managed object cache.
 
 @param managedObject The object to attempt to connect a relationship to.
 @param connectionMapping A mapping describing the relationship and attributes necessary to perform the connection.
 @param managedObjectCache The managed object cache from which to attempt to fetch a matching object to satisfy the connection.
 @return The receiver, initialized with the given managed object, connection mapping, and managed object cache.
 */
- (id)initWithManagedObject:(NSManagedObject *)managedObject
          connectionMapping:(RKConnectionMapping *)connectionMapping
         managedObjectCache:(id<RKManagedObjectCaching>)managedObjectCache;

@end
