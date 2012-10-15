//
//  RKManagedObjectMappingOperationDataSource.h
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

#import <CoreData/CoreData.h>
#import "RKMappingOperationDataSource.h"

@protocol RKManagedObjectCaching;

/**
 The `RKManagedObjectMappingOperationDataSource` class provides support for performing object mapping operations where the mapped objects exist within a Core Data managed object context. The class is responsible for finding exist managed object instances by primary key, instantiating new managed objects, and connecting relationships for mapped objects.

 @see `RKMappingOperationDataSource`
 @see `RKConnectionMapping`
 */
@interface RKManagedObjectMappingOperationDataSource : NSObject <RKMappingOperationDataSource>

///------------------------------------------------------------------
/// @name Initializing a Managed Object Mapping Operation Data Source
///------------------------------------------------------------------

/**
 Initializes the receiver with a given managed object context and managed object cache.
 
 @param managedObjectContext The managed object context with which to associate the receiver. Cannot be nil.
 @param managedObjectCache The managed object cache used by the receiver to find existing object instances by primary key.
 @return The receiver, initialized with the given managed object context and managed objet cache.
 */
- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext cache:(id<RKManagedObjectCaching>)managedObjectCache;

///-----------------------------------------------------
/// @name Accessing the Managed Object Context and Cache
///-----------------------------------------------------

/**
 The managed object context with which the receiver is associated.
 */
@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;

/**
 The managed object cache utilized by the receiver to find existing managed object instances by primary key. A nil managed object cache will result in the insertion of new managed objects for all mapped content.

 @see `RKFetchRequestManagedObjectCache`
 @see `RKInMemoryManagedObjectCache`
 */
@property (nonatomic, strong, readonly) id<RKManagedObjectCaching> managedObjectCache;

///---------------------------------------------------
/// @name Configuring Relationship Connection Queueing
///---------------------------------------------------

/**
 The parent operation upon which instances of `RKRelationshipConnectionOperation` created by the data source are dependent upon.
 
 When connecting relationships as part of a managed object mapping operation, it is possible that the mapping operation itself will create managed objects that should be used to satisfy the connections mappings of representations being mapped. To support such cases, is is desirable to defer the execution of connection operations until the execution of the aggregate mapping operation is complete. The `parentOperation` property provides support for deferring the execution of the enqueued relationship connection operations by establishing a dependency between the connection operations and a parent operation, such as an instance of `RKMapperOperation` such that they will not be executed by the `operationQueue` until the parent operation has finished executing.
 */
@property (nonatomic, weak) NSOperation *parentOperation;

/**
 The operation queue in which instances of `RKRelationshipConnectionOperation` will be enqueued to connect the relationships of mapped objects.
 
 If `nil`, then current operation queue as returned from `[NSOperationQueue currentQueue]` will be used.
 
 Please see the documentation for `parentOperation` for a discussion of this property's function.
 */
@property (nonatomic, strong) NSOperationQueue *operationQueue;

@end
