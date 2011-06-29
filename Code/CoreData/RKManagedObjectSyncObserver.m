//
//  RKManagedObjectSyncObserver.m
//  RestKit
//
//  Created by Evan Cordell on 6/29/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKManagedObjectSyncObserver.h"


@implementation RKManagedObjectSyncObserver
@synthesize registeredClasses = _registeredClasses;

- (id)init {
    self = [super init];
    if (self) {
        _registeredClasses = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [_registeredClasses release];
    
    [super dealloc];
}

- (void)registerClassForSyncing:(Class)someClass {
    [_registeredClasses addObject: someClass];
}

@end
