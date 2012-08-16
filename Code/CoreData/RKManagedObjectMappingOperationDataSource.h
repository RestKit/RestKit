//
//  RKManagedObjectMappingOperationDataSource.h
//  RestKit
//
//  Created by Blake Watters on 7/3/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "RKMappingOperationDataSource.h"

@protocol RKManagedObjectCaching;

/**
 The RKManagedObjectMappingOperationDataSource provides support for performing object mapping
 operations where the mapped objects exist within a Core Data managed object context. The class
 is responsible for finding exist managed object instances by primary key, instantiating new managed
 objects, and connecting relationships for mapped objects.
 
 @see RKMappingOperationDataSource
 @see RKConnectionMapping
 */
@interface RKManagedObjectMappingOperationDataSource : NSObject <RKMappingOperationDataSource>

/**
 The managed object context with which the receiver is associated.
 */
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

/**
 The managed object cache utilized by the receiver to find existing managed object instances
 by primary key. A nil managed object cache will result in the insertion of new managed objects for
 all mapped content.
 
 @see RKFetchRequestManagedObjectCache
 @see RKInMemoryManagedObjectCache
 */
@property (nonatomic, retain, readonly) id<RKManagedObjectCaching> managedObjectCache;

/**
 The operation queue in which instances of RKRelationshipConnectionOperation will be enqueued
 to connect the relationships of mapped objects.
 */
@property (nonatomic, retain) NSOperationQueue *operationQueue;

/**
 A Boolean value determing if the receiver keeps tracks of inserted objects.
 
 Tracking inserted objects is useful in mapping operations that are performed on a background thread
 but intend to return results to another thread. In these cases, it is necessary to obtain permanent object
 ID's for all inserted objects so that they may be reliably fetched across NSManagedObjectContext instances.
 Managed objects inserted into a context that is not directly related to the persistent store coordinator (i.e.
 child managed object contexts) do not have their managed object ID's updtated from temporary to persistent when
 saved to the persistent store through a parent context.
 
 **Default**: NO
 */
@property (nonatomic, assign) BOOL tracksInsertedObjects;

/**
 Returns the list of managed objects inserted into the receiver's managed object context during the course of
 a managed object mapping operation.
 */
@property (nonatomic, readonly) NSArray *insertedObjects;

/**
 Clears the list of inserted objects tracked by the receiver.
 */
- (void)clearInsertedObjects;

/**
 Initializes the receiver with a given managed object context and managed object cache.
 
 @param managedObjectContext The managed object context with which to associate the receiver. Cannot be nil.
 @param managedObjectCache The managed object cache used by the receiver to find existing object instances by primary key.
 @return The receiver, initialized with the given managed object context and managed objet cache.
 */
- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext cache:(id<RKManagedObjectCaching>)managedObjectCache;

@end
