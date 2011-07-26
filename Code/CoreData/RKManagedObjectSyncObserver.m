//  RKManagedObjectSyncObserver.m
//  RestKit
//
//  Created by Evan Cordell on 6/29/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKManagedObjectSyncObserver.h"
#import "RKLog.h"

NSString* const RKAutoSyncDidSync = @"RKAutoSyncDidSync";

//////////////////////////////////
// Shared Instance

static RKManagedObjectSyncObserver* sharedSyncObserver = nil;

///////////////////////////////////

@implementation RKManagedObjectSyncObserver
@synthesize registeredClasses = _registeredClasses;
@synthesize shouldAutoSync = _shouldAutoSync;

- (id)init {
    self = [super init];
    if (self) {
        _registeredClasses = [[NSMutableArray alloc] init];
        _isOnline = NO;
        _shouldAutoSync = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(reachabilityChanged:)
													 name:RKReachabilityStateChangedNotification
												   object:nil];
    }
    return self;
}

+ (RKManagedObjectSyncObserver*)sharedSyncObserver {
    return sharedSyncObserver;
}

+ (void)setSharedSyncObserver:(RKManagedObjectSyncObserver*)observer {
	[observer retain];
	[sharedSyncObserver release];
	sharedSyncObserver = observer;
}

- (void)dealloc {
    //weak reference
    _delegate = nil;
    [_registeredClasses release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)registerClassForSyncing:(Class<RKObjectSync>)someClass {
    [_registeredClasses addObject: someClass];
}

- (void)unregisterClassForSyncing:(Class<RKObjectSync>)someClass {
    [_registeredClasses removeObject:someClass];
}
- (void) reachabilityChanged:(NSNotification*)notification {
    RKLogInfo(@"Recieved notification that reachability has changed.");
    switch ([[[[RKObjectManager sharedManager] client] baseURLReachabilityObserver] networkStatus]) {
        case RKReachabilityIndeterminate:
        case RKReachabilityNotReachable:
            [self enteredOfflineMode];
            break;
        case RKReachabilityReachableViaWiFi:
        case RKReachabilityReachableViaWWAN:
            [self enteredOnlineMode];
            break;
        default:
            break;
    }
    
}
- (void) enteredOnlineMode {
    RKLogInfo(@"Entered online mode.");
    _isOnline = YES;
    if (_shouldAutoSync) {
        [self syncWithDelegate:nil];
    }
}

- (void) enteredOfflineMode {
    RKLogInfo(@"Entered offline mode.");
    _isOnline = NO;
}

- (void) syncWithDelegate: (NSObject<RKManagedObjectSyncDelegate>*)delegate {
    /*  Should fail silently if there's no connection. 
     *  But maybe we should check for availability and not sync if there's no network?
     *  Or check in the loop, so that if we lose connection during a sync we exit early?
     */
    _delegate = delegate;
    
    if (_delegate && [_delegate respondsToSelector:@selector(didStartSyncing)]) {
        [_delegate didStartSyncing];
    }
    
    _totalUnsynced = 0;
    for (Class cls in _registeredClasses) {
        for (NSManagedObject *object in [cls unsyncedObjects]) {
            _totalUnsynced += 1;
            switch ([object._rkManagedObjectSyncStatus intValue]) {
                case RKSyncStatusShouldPost:
                    [[RKObjectManager sharedManager] postObject:object delegate:self];
                    break;
                case RKSyncStatusShouldPut:
                    [[RKObjectManager sharedManager] putObject:object delegate:self];
                    break;
                case RKSyncStatusShouldDelete:
                    [[RKObjectManager sharedManager] deleteObject:object delegate:self];
                    break;
                default:
                    break;
            }
            //If we lose connection here, the object loader delegate will get a fail notification
            //So the sync status won't be reset, and the object will get synced next time 
            //there is network access.
        }
    }
    //if we don't sync anything, still notify delegate so we can reload data if necessary
    if (_totalUnsynced == 0 && _delegate && [_delegate respondsToSelector:@selector(didSyncNothing)]) {
        [_delegate didSyncNothing];
    }
}

#pragma mark - Sync Management

- (void)shouldNotSyncObject:(NSManagedObject*)object error:(NSError**)error {
    object._rkManagedObjectSyncStatus = [NSNumber numberWithInt:RKSyncStatusShouldNotSync];
    *error = [[[RKObjectManager sharedManager] objectStore] save];
}

- (void)shouldPostObject:(NSManagedObject*)object error:(NSError**)error {
    if (_isOnline && _shouldAutoSync) {
        [[RKObjectManager sharedManager] postObject:object delegate:self];
    } else { 
        if ([object._rkManagedObjectSyncStatus intValue] == RKSyncStatusShouldNotSync ||
            [object._rkManagedObjectSyncStatus intValue] == RKSyncStatusShouldPost) {
            object._rkManagedObjectSyncStatus = [NSNumber numberWithInt:RKSyncStatusShouldPost];
            *error = [[[RKObjectManager sharedManager] objectStore] save];
        } else {
            RKLogError(@"Trying to post an object that exists on the server.");
        }
    }
}

- (void)shouldPutObject:(NSManagedObject*)object error:(NSError**)error {
    if (_isOnline && _shouldAutoSync) {
        [[RKObjectManager sharedManager] putObject:object delegate:self];
    } else {
        //if set to post already, we want to just change the data the will be posted, not switch to a put
        if ([object._rkManagedObjectSyncStatus intValue] != RKSyncStatusShouldPost) {
            object._rkManagedObjectSyncStatus = [NSNumber numberWithInt:RKSyncStatusShouldPut];
            *error = [[[RKObjectManager sharedManager] objectStore] save];
        }
    }
}

- (void)shouldDeleteObject:(NSManagedObject*)object error:(NSError**)error {
    if (_isOnline && _shouldAutoSync) {
        [[RKObjectManager sharedManager] deleteObject:object delegate:self];
    } else {
        if ([object._rkManagedObjectSyncStatus intValue] == RKSyncStatusShouldPost) {
            //if deleting an object that hasn't been posted yet, just delete it locally
            [object deleteEntity];
            *error = [[[RKObjectManager sharedManager] objectStore] save];
        } else {
            object._rkManagedObjectSyncStatus = [NSNumber numberWithInt:RKSyncStatusShouldDelete];
            *error = [[[RKObjectManager sharedManager] objectStore] save];
        }
    }
}

#pragma mark RKObjectLoaderDelegate (RKRequestDelegate) methods

- (void)objectLoaderDidFinishLoading:(RKObjectLoader *)objectLoader {
    NSManagedObject *object = (NSManagedObject*)(objectLoader.sourceObject);
    if ([objectLoader.response isSuccessful]) {
        if ([objectLoader isPOST] || [objectLoader isPUT]) {
            object._rkManagedObjectSyncStatus = [NSNumber numberWithInt:RKSyncStatusShouldNotSync];
            [[[RKObjectManager sharedManager] objectStore] save];
            _totalUnsynced -= 1;
        } else if ([objectLoader isDELETE]) {
            [[[[RKObjectManager sharedManager] objectStore] managedObjectContext] deleteObject:object];
            [[[RKObjectManager sharedManager] objectStore] save];
            _totalUnsynced -= 1;
        }
        RKLogTrace(@"Total unsynced objects: %i", _totalUnsynced);
        if (_totalUnsynced == 0)
        {
            //finished a sync, notify the delegate
            if (_delegate && [_delegate respondsToSelector:@selector(didFinishSyncing)]) {
                [_delegate didFinishSyncing];
            }
            //if we're autosyncing, we don't have a delegate, so we send notifications
            if (_shouldAutoSync) {
                [[NSNotificationCenter defaultCenter] postNotificationName:RKAutoSyncDidSync object:self];
            }
        }
    }
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error {
	if (_delegate && [_delegate respondsToSelector:@selector(didFailSyncingWithError:)]) {
        [_delegate didFailSyncingWithError:error];
    }
}

@end
