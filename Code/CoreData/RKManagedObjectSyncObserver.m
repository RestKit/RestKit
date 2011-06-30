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
@synthesize client = _client;

- (id)init {
    self = [super init];
    if (self) {
        _registeredClasses = [[NSMutableArray alloc] init];
        
        //defaulting to a shared client, since this can only exist once there's an objectmanager.
        //added accessors in case this needs to be different from the base client
        _client = [[RKObjectManager sharedManager] client];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(reachabilityChanged:)
													 name:RKReachabilityStateChangedNotification
												   object:_client.baseURLReachabilityObserver];
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
    
    [super dealloc];
}

- (void)registerClassForSyncing:(Class<RKObjectSync>)someClass {
    [_registeredClasses addObject: someClass];
}

- (void)unregisterClassForSyncing:(Class<RKObjectSync>)someClass {
    [_registeredClasses removeObject:someClass];
}

- (void)reachabilityChanged:(NSNotification*)notification {
	BOOL isHostReachable = [self.client.baseURLReachabilityObserver isNetworkReachable];
	if (isHostReachable) {
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
        }
    }
}

#pragma mark - Sync Management

- (void)shouldNotSyncObject:(NSManagedObject*)object error:(NSError**)error {
    object._rkManagedObjectSyncStatus = [NSNumber numberWithInt:RKSyncStatusShouldNotSync];
    *error = [[[RKObjectManager sharedManager] objectStore] save];
}

- (void)shouldPostObject:(NSManagedObject*)object error:(NSError**)error {
    BOOL isHostReachable = [self.client.baseURLReachabilityObserver isNetworkReachable];
    if (isHostReachable) {
        NSLog(@"HOST IS REACHABLE");
        [[RKObjectManager sharedManager] postObject:object delegate:self];
    } else {
        object._rkManagedObjectSyncStatus = [NSNumber numberWithInt:RKSyncStatusShouldPost];
        *error = [[[RKObjectManager sharedManager] objectStore] save];
    }
}

- (void)shouldPutObject:(NSManagedObject*)object error:(NSError**)error {
    BOOL isHostReachable = [self.client.baseURLReachabilityObserver isNetworkReachable];
    if (isHostReachable) {
        [[RKObjectManager sharedManager] putObject:object delegate:self];
    } else {
        object._rkManagedObjectSyncStatus = [NSNumber numberWithInt:RKSyncStatusShouldPut];
        *error = [[[RKObjectManager sharedManager] objectStore] save];
    }
}

- (void)shouldDeleteObject:(NSManagedObject*)object error:(NSError**)error {
    BOOL isHostReachable = [self.client.baseURLReachabilityObserver isNetworkReachable];
    if (isHostReachable) {
        [[RKObjectManager sharedManager] deleteObject:object delegate:self];
    } else {
        object._rkManagedObjectSyncStatus = [NSNumber numberWithInt:RKSyncStatusShouldDelete];
        *error = [[[RKObjectManager sharedManager] objectStore] save];
    }
}

#pragma mark RKObjectLoaderDelegate methods

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObject:(id)object {
    //Synced, so we can reset sync value
    ((NSManagedObject*)object)._rkManagedObjectSyncStatus = [NSNumber numberWithInt:RKSyncStatusShouldNotSync];
    [[[RKObjectManager sharedManager] objectStore] save];

}

- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray*)objects {
	
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error {
	
}

@end
