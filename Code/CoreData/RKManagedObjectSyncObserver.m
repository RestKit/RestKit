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

- (id)init {
    self = [super init];
    if (self) {
        _registeredClasses = [[NSMutableArray alloc] init];
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

- (void)registerClassForSyncing:(Class)someClass {
    [_registeredClasses addObject: someClass];
}

- (void)unregisterClassForSyncing:(Class)someClass {
    [_registeredClasses removeObject:someClass];
}

@end
