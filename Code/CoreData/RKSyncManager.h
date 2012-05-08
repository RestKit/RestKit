//
//  RKSyncManager.h
//  RestKit
//
//  Created by Evan Cordell, Mark Makdad.
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
 Sync strategy sets the behavior of the RKSyncManager queue for a given mapping.
 */
typedef enum {
  RKSyncStrategyBatch,        /** RKSyncManager will try to reduce network requests by batching similar requests (where possible) & locally removing any objects that never were persisted remotely in the first place. */
  RKSyncStrategyProxyOnly,    /** RKSyncManager will not perform any batching; when network access is available, it will send all queued requests in the order it received them. */
} RKSyncStrategy;

/**
 Sync direction sets the behavior of the RKSyncManager queue for a given mapping.
 */
typedef enum {
  RKSyncDirectionPush = 0x001,  /** RKSyncManager will push requests, but not pull anything. */
  RKSyncDirectionPull = 0x010,  /** RKSyncManager will pull requests, but not push anything. */
  RKSyncDirectionBoth = 0x011   /** RKSyncManager will push requests, and then pull those same routes (true syncing). */
} RKSyncDirection;

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
 * When implemented, sent before objects are pushed to the server.
 */
- (void)syncManager:(RKSyncManager *)syncManager willPushObjects:(NSSet *)objects withSyncMode:(RKSyncMode)syncMode;

/**
 * When implemented, sent when all push requests have been added to the request queue.
 */
- (void)syncManager:(RKSyncManager *)syncManager didPushObjects:(NSSet *)objects withSyncMode:(RKSyncMode)syncMode;

/**
 * When implemented, sent before updates are pulled from ther server.
 */
- (void)syncManager:(RKSyncManager *)syncManager willPullObjectsOfClass:(Class)objectClass withSyncMode:(RKSyncMode)syncMode;

/**
 * When implemented, sent when all pull requests have been added to the request queue.
 */
- (void)syncManager:(RKSyncManager *)syncManager didPullObjectsOfClass:(Class)objectClass withSyncMode:(RKSyncMode)syncMode;

@end

/**
 `RKSyncManager` handles the observation of Core Data changes and the syncronization of a local store with a remote server. This object is created automatically when an RKManagedObjectStore is initialized, and is associated with the objectStore's related `objectManager`.  
 */
@interface RKSyncManager : NSObject <RKObjectLoaderDelegate> {
    NSMutableDictionary *_strategies;
    NSMutableDictionary *_directions;
    NSInteger _requestCounter;
    NSMutableArray *_queues;
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
 If NO, the sync manager will take no actions for any inserted, updated, or deleted 
 objects (i.e. do nothing).  This is useful if you need to do some
 local Core Data management without affecting the status of those records on the server,
 such as logging a user out and deleting their associated data.
 */
@property (nonatomic) BOOL syncEnabled;

/**
 Creates an RKSyncManager and associates it with an RKObjectManager. This happens automatically on objectStore initialization, or one can be created seperately to handle different syncing tasks. Once initialized the `objectManager` is `readonly`.
 */
- (id)initWithObjectManager:(RKObjectManager*)objectManager;

#pragma mark - Manual Syncing Methods

/**
 Convenience method for syncing all pending objects with `syncMode = RKSyncModeManual`
 @see RKSyncMode
 */
- (void)sync;

/**
 Convenience method for syncing all pending objects with `syncMode = RKSyncModeInterval`.
 It is your responsibility to manage an NSTimer instance to automatically call this method.
 @param objectClass The Class pointer of the class you wish to sync.  To sync all classes, pass nil.
 @see RKSyncMode
 */
- (void)intervalSyncForClass:(Class)objectClass;

/**
 Convenience method for syncing all pending objects with `syncMode = RKSyncModeManual` of
 a certain class.  If `nil` is passed as the parameter, all objects will be synchronized.
 @see RKSyncMode
 */
- (void)syncObjectsOfClass:(Class)objectClass;

/**
 Convenience method for pushing objects with `syncMode = RKSyncModeManual`
 @see RKSyncMode
 */
- (void)push;

/**
 Convenience method for pulling objects with `syncMode = RKSyncModeManual`
 @see RKSyncMode
 */
- (void)pull;

/**
 Syncs (push followed by pull) all objects with a given syncMode and class. If syncMode is nil, it syncs
 all objects of type `objectClass`. If `objectClass` is nil, it syncs all objects with the specified
 `syncMode` regardless of the class. Both values cannot be nil.
 */
- (void)syncObjectsWithSyncMode:(RKSyncMode)syncMode andClass:(Class)objectClass;

/**
 Pushes all objects with a given syncMode and class to a remote server. If syncMode is nil, it pushes
 all objects of type `objectClass`. If `objectClass` is nil, it pushes all objects with the specified
 `syncMode` regardless of the class. Both values cannot be nil.
 */
- (void)pushObjectsWithSyncMode:(RKSyncMode)syncMode andClass:(Class)objectClass;

/**
 Pulls all objects with a given syncMode and class. If syncMode is nil, it pulls all objects of type
 `objectClass`. If `objectClass` is nil, it pulls all objects with the specified `syncMode` regardless
 of the class. Both values cannot be nil.
 */
- (void)pullObjectsWithSyncMode:(RKSyncMode)syncMode andClass:(Class)objectClass;

#pragma mark - Sync Direction

/**
 Sets the default RKSyncDirection.  The value will be applied to any class that has not been
 registered with `setSyncDirection:(RKSyncDirection)direction forClass:(Class)objectClass`.
 
 The default value if you do not call this method is `RKSyncDirectionBoth`.
 @see RKSyncDirection
 */
- (void)setDefaultSyncDirection:(RKSyncDirection)direction;

/**
 Returns the current default RKSyncDirection.  This will be applied to any class that has not been
 registered with `setSyncDirection:(RKSyncDirection)direction forClass:(Class)objectClass`.
 @see RKSyncDirection
 */
@property (readonly) RKSyncDirection defaultSyncDirection;

/**
 Sets the RKSyncDirection for a Class.  If Class is nil, this changes the default value RKSyncManager
 will use for all classes (same effect as `setDefaultSyncDirection:`).
 @see RKSyncDirection
 */
- (void)setSyncDirection:(RKSyncDirection)syncDirection forClass:(Class)objectClass;

/**
 Returns the current RKSyncDirection for a Class.  If no strategy has been set for this class, the 
 default value of will be returned (`RKSyncDirectionBoth`).
 @see RKSyncDirection
 */
- (RKSyncDirection) syncDirectionForClass:(Class)objectClass;

#pragma mark - Sync Strategy

/**
 Sets the default RKSyncStrategy to be used with all objects, unless they have been specifically
 registered with `setSyncStrategy:(RKSyncStrategy)syncStrategy forClass:(Class)objectClass`.
 @see RKSyncStrategy
 */
- (void)setDefaultSyncStrategy:(RKSyncStrategy)syncStrategy;

/**
 Returns the current default RKSyncStrategy.  This strategy will be applied to any class that has not
 been registered with `setSyncStrategy:(RKSyncStrategy)syncStrategy forClass:(Class)objectClass`.
 @see RKSyncStrategy
 */
@property (readonly) RKSyncStrategy defaultSyncStrategy;

/**
 Sets the RKSyncStrategy for a Class.  If Class is nil, this changes the default value RKSyncManager
 will use for all classes (same effect as `setDefaultSyncStrategy:`).
 @see RKSyncStrategy
 */
- (void)setSyncStrategy:(RKSyncStrategy)syncStrategy forClass:(Class)objectClass;

/**
 Returns the current RKSyncStrategy for a Class.  If no strategy has been set for this class, the 
 default value of will be returned (`RKSyncStrategyBatch`).
 @see RKSyncStrategy
 */
- (RKSyncStrategy) syncStrategyForClass:(Class)objectClass;

@end
