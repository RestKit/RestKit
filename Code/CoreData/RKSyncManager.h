//
//  RKSyncManager.h
//  RestKit
//
//  Created by Evan Cordell on 2/16/12.
//  Copyright (c) 2012 RestKit.
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

#import "RKObjectManager.h"
#import "RKManagedObjectSyncQueue.h"
#import "RKManagedObjectMapping.h"
#import "RKLog.h"

/**
 Sync status types indicating HTTP method
 */
typedef enum {
    RKSyncStatusNone,
    RKSyncStatusPost,
    RKSyncStatusPut,
    RKSyncStatusDelete
} RKSyncStatus;

@class RKSyncManager;

/**
 * Notified of sync events for RKSyncManager
 */
@protocol RKSyncManagerDelegate <NSObject>
@required

/**
 * Sent when there is an error syncing. 
 */
- (void)syncManager:(RKSyncManager *)syncManager didFailSyncingWithError:(NSError*)error;

@optional

/**
 * When implemented, sent when the syncing process begins.
 */
- (void)syncManager:(RKSyncManager *)syncManager willSyncWithSyncMode:(RKSyncMode)syncMode andClass:(Class)objectClass;

/**
 * When implemented, sent when the syncing process completes successfully.
 */
- (void)syncManager:(RKSyncManager *)syncManager didSyncWithSyncMode:(RKSyncMode)syncMode andClass:(Class)objectClass;

/**
 * When implemented, sent before objects are pushed to the server. Objects in queue are of type RKManagedObjectSyncQueue. 
 @see RKManagedObjectSyncQueue
 */
- (void)syncManager:(RKSyncManager *)syncManager willPushObjectsInQueue:(NSArray *)queue withSyncMode:(RKSyncMode)syncMode andClass:(Class)objectClass;


/**
 * When implemented, sent before updates are pulled from ther server.
 */
- (void)syncManager:(RKSyncManager *)syncManager willPullWithSyncMode:(RKSyncMode)syncMode andClass:(Class)objectClass;

/**
 * When implemented, sent when all push requests have been added to the request queue.
 */
- (void)syncManager:(RKSyncManager *)syncManager didPushObjectsWithSyncMode:(RKSyncMode)syncMode andClass:(Class)objectClass;

/**
 * When implemented, sent when all pull requests have been added to the request queue.
 */
- (void)syncManager:(RKSyncManager *)syncManager didPullWithSyncMode:(RKSyncMode)syncMode andClass:(Class)objectClass;

@end

/**
 `RKSyncManager` handles the observation of Core Data changes and the syncronization of a local store with a remote server. This object is created automatically when an RKManagedObjectStore is initialized, and is associated with the objectStore's related `objectManager`.  
 */
@interface RKSyncManager : NSObject <RKObjectLoaderDelegate> {
    NSMutableArray *_queue;
}

/**
 The objectManager that this syncManager is associated with.
 @see RKObjectManager
 */
@property (nonatomic, readonly) RKObjectManager* objectManager;

/**
 The object that receives the RKManagedObjectSyncDelegate messages. 
 @see RKManagedObjectSyncDelegate
 */
@property (nonatomic, assign) id<RKSyncManagerDelegate> delegate;

/**
 Creates an RKSyncManager and associates it with an RKObjectManager. This happens automatically on objectStore initialization, or one can be created seperately to handle different syncing tasks. Once initialized the `objectManager` is `readonly`.
 */

- (id)initWithObjectManager:(RKObjectManager*)objectManager;

/**
 Syncs (push followed by pull) all objects with a given syncMode and class. If syncMode is nil, it syncs all objects of type `objectClass`. If `objectClass` is nil, it syncs all objects with the specified `syncMode` regardless of the class. Both values cannot be nil.
 */
- (void)syncObjectsWithSyncMode:(RKSyncMode)syncMode andClass:(Class)objectClass;

/**
 Pushes all objects with a given syncMode and class to a remote server. If syncMode is nil, it pushes all objects of type `objectClass`. If `objectClass` is nil, it pushes all objects with the specified `syncMode` regardless of the class. Both values cannot be nil.
 */
- (void)pushObjectsWithSyncMode:(RKSyncMode)syncMode andClass:(Class)objectClass;

/**
 Pulls all objects with a given syncMode and class. If syncMode is nil, it pulls all objects of type `objectClass`. If `objectClass` is nil, it pulls all objects with the specified `syncMode` regardless of the class. Both values cannot be nil.
 */
- (void)pullObjectsWithSyncMode:(RKSyncMode)syncMode andClass:(Class)objectClass;


/**
 Conveniance method for syncing objects with `syncMode = RKSyncModeManual`
 */
- (void)sync;

/**
 Conveniance method for pushing objects with `syncMode = RKSyncModeManual`
 */
- (void)push;

/**
 Conveniance method for pulling objects with `syncMode = RKSyncModeManual`
 */
- (void)pull;

@end
