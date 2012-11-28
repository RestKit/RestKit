//
//  RKRelationshipConnectionOperation.h
//  RestKit
//
//  Created by Blake Watters on 7/12/12.
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

#import <Foundation/Foundation.h>

@class RKConnectionDescription;
@protocol RKManagedObjectCaching;

/**
 The `RKRelationshipConnectionOperation` class is a subclass of `NSOperation` that manages the connection of `NSManagedObject` relationships as described by an `RKConnectionDescription` object. When executed, the operation will find related objects by searching the associated managed object cache for objects matching the connection description and setting them as the value for the relationship being connected.

 For example, given a managed object for the `Employee` entity with a one-to-one relationship to a `Company` named `company` (with an inverse relationship one-to-many relationship named `employees`) and a connection mapping specifying that the relationship can be connected by finding the `Company` managed object whose `companyID` attribute matches the `companyID` of the `Employee`, the operation would find the Company that employs the Employee by primary key and set the Core Data relationship to reflect the relationship appropriately.

 @see `RKConnectionDescription`
 */
@interface RKRelationshipConnectionOperation : NSOperation

///-------------------------------------------------------
/// @name Initializing a Relationship Connection Operation
///-------------------------------------------------------

/**
 Initializes the receiver with a given managed object, connection mapping, and managed object cache.

 @param managedObject The object to attempt to connect a relationship to.
 @param connectionMapping A mapping describing the relationship and attributes necessary to perform the connection.
 @param managedObjectCache The managed object cache from which to attempt to fetch a matching object to satisfy the connection.
 @return The receiver, initialized with the given managed object, connection mapping, and managed object cache.
 */
- (id)initWithManagedObject:(NSManagedObject *)managedObject
                 connection:(RKConnectionDescription *)connection
         managedObjectCache:(id<RKManagedObjectCaching>)managedObjectCache;

///--------------------------------------------
/// @name Accessing Details About the Operation
///--------------------------------------------

/**
 The managed object the receiver will attempt to connect a relationship for.
 */
@property (nonatomic, strong, readonly) NSManagedObject *managedObject;

/**
 The connection mapping describing the relationship connection the receiver will attempt to connect.
 */
@property (nonatomic, strong, readonly) RKConnectionDescription *connection;

/**
 The managed object cache the receiver will use to fetch a related object satisfying the connection mapping.
 */
@property (nonatomic, strong, readonly) id<RKManagedObjectCaching> managedObjectCache;

/**
 The object or collection of objects that was connected by the operation.
 */
@property (nonatomic, strong, readonly) id connectedValue;

@end
