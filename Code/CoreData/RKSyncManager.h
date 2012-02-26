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

/**
 * Notified of sync events for RKManagedObjectSyncObserver
 */
@protocol RKManagedObjectSyncDelegate <NSObject>
@required

/**
 * Sent when there is an error syncing. 
 */
- (void)didFailSyncingWithError:(NSError*)error;

@optional

/**
 * When implemented, sent when the syncing process begins.
 */
- (void)didStartSyncing;

/**
 * When implemented, sent when the syncing process completes successfully.
 */
- (void)didFinishSyncing;

/**
 * When implemented, sent when the syncing completes successfully, but there were no objects that needed syncing.
 */
- (void)didSyncNothing;

@end

@interface RKSyncManager : NSObject <RKObjectLoaderDelegate> {
    NSMutableArray *_queue;
}

@property (nonatomic, readonly) RKObjectManager* objectManager;
@property (nonatomic, assign) id<RKManagedObjectSyncDelegate> delegate;

- (id)initWithObjectManager:(RKObjectManager*)objectManager;
- (void)contextDidSave:(NSNotification*)notification;
- (int)highestQueuePosition;

- (void)sync;
- (void)transparentSync;
- (void)pushObjects;
- (void)pullObjectsWithSyncMode:(NSNumber *)syncMode;

@end
