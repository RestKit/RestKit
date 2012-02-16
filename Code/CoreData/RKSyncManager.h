//
//  RKSyncManager.h
//  RestKit
//
//  Created by Evan Cordell on 2/16/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKObjectManager.h"
#import "RKManagedObjectSyncQueue.h"

typedef enum {
    RKSyncStatusNone,
    RKSyncStatusPost,
    RKSyncStatusPut,
    RKSyncStatusDelete
} RKSyncStatus;

@interface RKSyncManager : NSObject

@property (nonatomic, readonly) RKObjectManager* objectManager;

- (id)initWithObjectManager:(RKObjectManager*)objectManager;
- (void)contextDidSave:(NSNotification*)notification;
- (int)highestQueuePosition;

@end
