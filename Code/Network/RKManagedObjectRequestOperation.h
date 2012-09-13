//
//  RKManagedObjectRequestOperation.h
//  RestKit
//
//  Created by Blake Watters on 8/9/12.
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
