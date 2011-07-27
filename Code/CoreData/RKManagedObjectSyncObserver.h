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

/**
 * Notified of sync events for RKManagedObjectSyncObserver
 */
@protocol RKManagedObjectSyncDelegate
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

/**
 * Handles synchronization of local Core Data objects with a remote server. 
 * 
 * A singleton RKManagedObjectSyncObserver is created on objectStore initialization. 
 * Classes (subclasses of NSManagedObject) are registered to sync by calling 
 * registerClassForSyncing: on the singleton class. For example, 
 *  `[[RKManagedObjectSyncObserver sharedSyncObserver] registerClassForSyncing:[Record class]] `
 * will register the Record class for syncing.
 *
 * Once a class is registered, instances of that class can be created/modified with shouldPostObject, shouldPutObject, and
 * shouldDeleteObject. These methods take the place of calls to postObject, putObject, and deleteObject that would normally
 * be sent to the ObjectManager.
 *
 * Syncing can occur manually or automatically, as determined by the shouldAutoSync property.
 * Syncing can be initiated at any time by calling syncWithDelegate:, but if autosyncing,
 * the SyncObserver will watch the network for reachability changes. If network access is available,
 * it will pass requests directly to the ObjectManager as normal, but if unavailable, it will set the
 * _rkManagedObjectSyncStatus property on the object. When network access is available again,
 * the observer will find all unsynced objects and perform the appropriate operations, notifying
 * the delegate as needed. 
 */

@interface RKManagedObjectSyncObserver : NSObject <RKObjectLoaderDelegate> {
    NSMutableArray *_registeredClasses; 
    BOOL _isOnline;
    BOOL _shouldAutoSync;
    NSInteger _totalUnsynced;
    NSObject<RKManagedObjectSyncDelegate> *_delegate;
}

/**
 * An array containing the classes that should be synced
 */
@property (nonatomic, retain) NSMutableArray *registeredClasses;

/**
 * Default value is YES. Determines whether or not the observer should sync automatically or manually.
 */
@property (nonatomic, assign) BOOL shouldAutoSync;

/**
 * Returns the global syncObserver
 */
+ (RKManagedObjectSyncObserver*)sharedSyncObserver;

/**
 * Sets the global syncObserver. This should not be used.
 * @param observer the RKManagedObjectSyncObserver to set as the sharedSyncObserver
 */
+ (void)setSharedSyncObserver:(RKManagedObjectSyncObserver*)observer;

/**
 * Registers a class for syncing with the syncObserver
 * @param someClass The class to register for syncing
 */
- (void)registerClassForSyncing:(Class<RKObjectSync>)someClass;

/**
 * Stops observing a class. The class will no longer be synced.
 * @param someClass The class to stop syncing
 */
- (void)unregisterClassForSyncing:(Class<RKObjectSync>)someClass;

/**
 * Fires when the syncObserver sees that the network is available.
 */
- (void)enteredOnlineMode;

/**
 * Fires when the syncObserver sees that the network is unavailable.
 */
- (void)enteredOfflineMode;

/**
 * Starts the syncing operation and passes a delegate to notify 
 * about the syncing lifecycle.
 * @see RKManagedObjectSyncDelegate
 * @param delegate An object implementing the RKManagedObjectSyncDelegate protocol
 * that will recieve lifecycle notifications.
 */
- (void)syncWithDelegate:(NSObject<RKManagedObjectSyncDelegate>*)delegate; 

/**
 * Sets the _rkManagedObjectSyncStatus on the object to RKSyncStatusShouldNotSync
 * @param object The NSManagedObject to modify
 * @param error An error reference to pass back saving errors
 */
- (void)shouldNotSyncObject:(NSManagedObject*)object;

/**
 * Sets the _rkManagedObjectSyncStatus on the object to RKSyncStatusShouldPost
 * If autosyncing, and network access is available, passes object directly to the objectManager
 * @param object The NSManagedObject to modify
 * @param error An error reference to pass back saving errors
 */
- (void)shouldPostObject:(NSManagedObject*)object;

/**
 * Sets the _rkManagedObjectSyncStatus on the object to RKSyncStatusShouldPut
 * If autosyncing, and network access is available, passes object directly to the objectManager
 * @param object The NSManagedObject to modify
 * @param error An error reference to pass back saving errors
 */
- (void)shouldPutObject:(NSManagedObject*)object;

/**
 * Sets the _rkManagedObjectSyncStatus on the object to RKSyncStatusShouldDelete
 * If autosyncing, and network access is available, passes object directly to the objectManager
 * @param object The NSManagedObject to modify
 * @param error An error reference to pass back saving errors
 */
- (void)shouldDeleteObject:(NSManagedObject*)object;


@end
