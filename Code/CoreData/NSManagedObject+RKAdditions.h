//
//  NSManagedObject+RKAdditions.h
//  RestKit
//
//  Created by Blake Watters on 3/14/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <CoreData/CoreData.h>

@class RKManagedObjectStore, RKEntityMapping;

/**
 Provides extensions to NSManagedObject for various common tasks.
 */
@interface NSManagedObject (RKAdditions)

///--------------------------------------
/// @name Inspecting Managed Object State
///--------------------------------------

/**
 Determines if the receiver has been deleted from the persistent store
 and removed from the object graph.

 Unlike isDeleted, will return YES after a save event or if the managed object was deleted
 in another managed object context that was then merged to the persistent store.

 @return YES if the object has been deleted from the persistent store, else NO.
 */
@property (nonatomic, readonly) BOOL hasBeenDeleted;

/**
 * Returns YES when an object has not been saved to the managed object context yet
 */
@property (nonatomic, readonly) BOOL isNew;

@end
