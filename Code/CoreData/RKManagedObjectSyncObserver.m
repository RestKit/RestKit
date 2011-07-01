//
//  RKManagedObjectSyncObserver.m
//  RestKit
//
//  Created by Evan Cordell on 6/29/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKManagedObjectSyncObserver.h"

//////////////////////////////////
// Shared Instance

static RKManagedObjectSyncObserver* sharedSyncObserver = nil;

///////////////////////////////////

@implementation RKManagedObjectSyncObserver
@synthesize registeredClasses = _registeredClasses;
@synthesize isSyncing = _isSyncing;

- (id)init {
    self = [super init];
    if (self) {
        _registeredClasses = [[NSMutableArray alloc] init];
        _isSyncing = NO;
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
    NSLog(@"OMG REACH CHANGE");
    switch ([[[[RKObjectManager sharedManager] client] baseURLReachabilityObserver] networkStatus]) {
        case RKReachabilityIndeterminate:
        case RKReachabilityNotReachable:
            [self enteredOfflineMode];
            NSLog(@"We're offline!");
            break;
        case RKReachabilityReachableViaWiFi:
        case RKReachabilityReachableViaWWAN:
            NSLog(@"We're online!");
            [self enteredOnlineMode];
            break;
        default:
            break;
    }
    
}
- (void) enteredOnlineMode {
    _isSyncing = YES;
    [RKRequestQueue sharedQueue].suspended = NO;
    for (Class cls in _registeredClasses) {
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
        }
        //Need to handle if we lose connection during this loop
    }
}

- (void) enteredOfflineMode {
    _isSyncing = NO;
    [RKRequestQueue sharedQueue].suspended = YES;
}

#pragma mark - Sync Management

- (void)shouldNotSyncObject:(NSManagedObject*)object error:(NSError**)error {
    object._rkManagedObjectSyncStatus = [NSNumber numberWithInt:RKSyncStatusShouldNotSync];
    *error = [[[RKObjectManager sharedManager] objectStore] save];
}

- (void)shouldPostObject:(NSManagedObject*)object error:(NSError**)error {
    if (_isSyncing) {
        [[RKObjectManager sharedManager] postObject:object delegate:self];
    } else {
        object._rkManagedObjectSyncStatus = [NSNumber numberWithInt:RKSyncStatusShouldPost];
        *error = [[[RKObjectManager sharedManager] objectStore] save];
    }
}

- (void)shouldPutObject:(NSManagedObject*)object error:(NSError**)error {
    if (_isSyncing) {
        [[RKObjectManager sharedManager] putObject:object delegate:self];
    } else {
        object._rkManagedObjectSyncStatus = [NSNumber numberWithInt:RKSyncStatusShouldPut];
        *error = [[[RKObjectManager sharedManager] objectStore] save];
    }
}

- (void)shouldDeleteObject:(NSManagedObject*)object error:(NSError**)error {
    if (_isSyncing) {
        [[RKObjectManager sharedManager] deleteObject:object delegate:self];
    } else {
        object._rkManagedObjectSyncStatus = [NSNumber numberWithInt:RKSyncStatusShouldDelete];
        *error = [[[RKObjectManager sharedManager] objectStore] save];
    }
}

#pragma mark RKObjectLoaderDelegate methods

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObject:(id)object {
    //Synced, so we can reset sync value
    //((NSManagedObject*)object)._rkManagedObjectSyncStatus = [NSNumber numberWithInt:RKSyncStatusShouldNotSync];
    //[[[RKObjectManager sharedManager] objectStore] save];

}

- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray*)objects {
	
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error {
	
}

@end
