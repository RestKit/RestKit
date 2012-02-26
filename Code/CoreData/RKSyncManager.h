//
//  RKSyncManager.h
//  RestKit
//
//  Created by Evan Cordell on 2/16/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKObjectManager.h"
#import "RKManagedObjectSyncQueue.h"
#import "RKDeletedObject.h"
#import "RKManagedObjectMapping.h"
#import "RKManagedObjectMappingOperation.h"

typedef enum {
    RKSyncStatusNone,
    RKSyncStatusPost,
    RKSyncStatusPut,
    RKSyncStatusDelete
} RKSyncStatus;

@class RKSyncManager;

/**
 * Notified of sync events for RKManagedObjectSyncObserver
 */
@protocol RKManagedObjectSyncDelegate <NSObject>
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

@interface RKSyncManager : NSObject <RKObjectLoaderDelegate> {
    NSMutableArray *_queue;
}

@property (nonatomic, readonly) RKObjectManager* objectManager;
@property (nonatomic, assign) id<RKManagedObjectSyncDelegate> delegate;

- (id)initWithObjectManager:(RKObjectManager*)objectManager;

- (void)syncObjectsWithSyncMode:(RKSyncMode)syncMode andClass:(Class)objectClass;
- (void)pushObjectsWithSyncMode:(RKSyncMode)syncMode andClass:(Class)objectClass;
- (void)pullObjectsWithSyncMode:(RKSyncMode)syncMode andClass:(Class)objectClass;


//Shortcuts for syncing all classes set to RKSyncModeManual
- (void)sync;
- (void)push;
- (void)pull;

@end
