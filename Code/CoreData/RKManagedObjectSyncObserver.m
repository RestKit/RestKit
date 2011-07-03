//
//  RKManagedObjectSyncObserver.m
//  RestKit
//
//  Created by Evan Cordell on 6/29/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKManagedObjectSyncObserver.h"
#import "RKLog.h"

//////////////////////////////////
// Shared Instance

static RKManagedObjectSyncObserver* sharedSyncObserver = nil;

///////////////////////////////////

@implementation RKManagedObjectSyncObserver
@synthesize registeredClasses = _registeredClasses;
@synthesize delegate = _delegate;
@synthesize isOnline = _isOnline;
@synthesize shouldAutoSync = _shouldAutoSync;
@synthesize totalUnsynced = _totalUnsynced;

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
    [[RKRequestQueue sharedQueue] cancelAllRequests];
    [[RKRequestQueue sharedQueue] setSuspended:NO];
    if (_shouldAutoSync) {
        [self sync];
    }
}

- (void) enteredOfflineMode {
    RKLogInfo(@"Entered offline mode.");
    _isOnline = NO;
    [[RKRequestQueue sharedQueue] cancelAllRequests];
    [[RKRequestQueue sharedQueue] setSuspended:YES];
}

- (void) sync {
    _totalUnsynced = 0;
    for (Class cls in _registeredClasses) {
        _totalUnsynced += [[cls unsyncedObjects] count];
        for (NSManagedObject *object in [cls unsyncedObjects]) {
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
}

#pragma mark - Sync Management

- (void)shouldNotSyncObject:(NSManagedObject*)object error:(NSError**)error {
    object._rkManagedObjectSyncStatus = [NSNumber numberWithInt:RKSyncStatusShouldNotSync];
    *error = [[[RKObjectManager sharedManager] objectStore] save];
}

- (void)shouldPostObject:(NSManagedObject*)object error:(NSError**)error {
    if (_isOnline) {
        [[RKObjectManager sharedManager] postObject:object delegate:self];
    } else {
        object._rkManagedObjectSyncStatus = [NSNumber numberWithInt:RKSyncStatusShouldPost];
        *error = [[[RKObjectManager sharedManager] objectStore] save];
    }
}

- (void)shouldPutObject:(NSManagedObject*)object error:(NSError**)error {
    if (_isOnline) {
        [[RKObjectManager sharedManager] putObject:object delegate:self];
    } else {
        object._rkManagedObjectSyncStatus = [NSNumber numberWithInt:RKSyncStatusShouldPut];
        *error = [[[RKObjectManager sharedManager] objectStore] save];
    }
}

- (void)shouldDeleteObject:(NSManagedObject*)object error:(NSError**)error {
    if (_isOnline) {
        [[RKObjectManager sharedManager] deleteObject:object delegate:self];
    } else {
        object._rkManagedObjectSyncStatus = [NSNumber numberWithInt:RKSyncStatusShouldDelete];
        *error = [[[RKObjectManager sharedManager] objectStore] save];
    }
}

#pragma mark RKObjectLoaderDelegate methods

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObject:(id)object {
    if (((NSManagedObject*)object)._rkManagedObjectSyncStatus != [NSNumber numberWithInt:RKSyncStatusShouldNotSync]) {
        //These are being synced from the cache and not newly added
        ((NSManagedObject*)object)._rkManagedObjectSyncStatus = [NSNumber numberWithInt:RKSyncStatusShouldNotSync];
        [[[RKObjectManager sharedManager] objectStore] save];
        _totalUnsynced -= 1;
        RKLogTrace(@"Total unsynced objects: %i", _totalUnsynced);
        if (_totalUnsynced == 0)
        {
            //finished a sync
            //should be on the main thread already so no need to invoke specially
            if (_delegate && [_delegate respondsToSelector:@selector(didFinishSyncing)]) {
                [(NSObject<RKManagedObjectSyncDelegate>*)_delegate didFinishSyncing];
            }
        }
    } else {
        //These are being synced directly
        //notify the delegate
        if (_delegate && [_delegate respondsToSelector:@selector(didFinishSyncing)]) {
            [(NSObject<RKManagedObjectSyncDelegate>*)_delegate didFinishSyncing];
        }
    }
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray*)objects {
	
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error {
	
}

@end
