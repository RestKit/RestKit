//
//  RKManagedObjectSyncObserver.h
//  RestKit
//
//  Created by Evan Cordell on 6/29/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "../Network/Network.h"
#import "../ObjectMapping/RKObjectManager.h"
#import "NSManagedObject+ActiveRecord.h"
#import "RKManagedObjectStore.h"

// Notifications
extern NSString* const RKAutoSyncDidSync;

typedef enum {
	RKSyncStatusShouldNotSync,
	RKSyncStatusShouldPost,
	RKSyncStatusShouldPut,
	RKSyncStatusShouldDelete
} RKSyncStatus;

@protocol RKManagedObjectSyncDelegate

@optional
//don't pass the observer since we use a singleton
- (void)didStartSyncing;
- (void)didFinishSyncing;
- (void)didFailSyncingWithError:(NSError*)error;
- (void)didSyncNothing;

@end

@interface RKManagedObjectSyncObserver : NSObject <RKObjectLoaderDelegate> {
    NSMutableArray *_registeredClasses; 
    BOOL _isOnline;
    BOOL _shouldAutoSync;
    NSInteger _totalUnsynced;
    NSObject<RKManagedObjectSyncDelegate> *_delegate;
}

@property (nonatomic, retain) NSMutableArray *registeredClasses;
@property (nonatomic, assign) BOOL isOnline;
@property (nonatomic, assign) BOOL shouldAutoSync;
@property (nonatomic, assign) NSInteger totalUnsynced;
@property (nonatomic, retain) NSObject<RKManagedObjectSyncDelegate> *delegate;

+ (RKManagedObjectSyncObserver*)sharedSyncObserver;
+ (void)setSharedSyncObserver:(RKManagedObjectSyncObserver*)observer;

- (void)registerClassForSyncing:(Class<RKObjectSync>)someClass;
- (void)unregisterClassForSyncing:(Class<RKObjectSync>)someClass;

- (void)enteredOnlineMode;
- (void)enteredOfflineMode;

- (void)syncWithDelegate:(NSObject<RKManagedObjectSyncDelegate>*)delegate; 

- (void)shouldNotSyncObject:(NSManagedObject*)object error:(NSError**)error;
- (void)shouldPostObject:(NSManagedObject*)object error:(NSError**)error;
- (void)shouldPutObject:(NSManagedObject*)object error:(NSError**)error;
- (void)shouldDeleteObject:(NSManagedObject*)object error:(NSError**)error;


@end
