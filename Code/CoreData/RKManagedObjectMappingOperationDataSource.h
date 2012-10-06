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

/**
 The operation queue in which instances of `RKRelationshipConnectionOperation` will be enqueued to connect the relationships of mapped objects.
 */
@property (nonatomic, strong) NSOperationQueue *operationQueue;

/**
 Initializes the receiver with a given managed object context and managed object cache.

 @param managedObjectContext The managed object context with which to associate the receiver. Cannot be nil.
 @param managedObjectCache The managed object cache used by the receiver to find existing object instances by primary key.
 @return The receiver, initialized with the given managed object context and managed objet cache.
 */
- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext cache:(id<RKManagedObjectCaching>)managedObjectCache;

@end
