//
//  RKManagedObjectRequestOperation.h
//  GateGuru
//
//  Created by Blake Watters on 8/9/12.
//  Copyright (c) 2012 GateGuru, Inc. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "RKObjectRequestOperation.h"
#import "RKManagedObjectCaching.h"

typedef NSFetchRequest * (^RKFetchRequestBlock)(NSURL *URL);

@interface RKManagedObjectRequestOperation : RKObjectRequestOperation

///-----------------------------------------------------------------------------
/// @name Core Data
///-----------------------------------------------------------------------------

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, weak) id<RKManagedObjectCaching> managedObjectCache;

/**
 The managed object context from which managed objects will be fetched when
 populating the mapping result.

 If nil, the mapping result will contain instances of NSManagedObjectID
 instead of NSManagedObject.
 */
@property (nonatomic, strong) NSManagedObjectContext *callbackContext;

// TODO: May want BOOL autosavesContext | autosavesToPersistentStore
// TODO: May want BOOL cleanupOrphanedObject option

@property (nonatomic, copy) NSArray *fetchRequestBlocks;

/**
 A Boolean value that determines if the receiver will delete orphaned objects upon
 completion of the operation.

 **Default**: NO
 */
@property (nonatomic, assign) BOOL deletesOrphanedObjects;

@end
