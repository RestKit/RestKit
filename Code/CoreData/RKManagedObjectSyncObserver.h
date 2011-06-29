//
//  RKManagedObjectSyncObserver.h
//  RestKit
//
//  Created by Evan Cordell on 6/29/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//


@interface RKManagedObjectSyncObserver : NSObject {
    NSMutableArray *_registeredClasses; 
}

@property (nonatomic, retain) NSMutableArray *registeredClasses;

- (void)registerClassForSyncing:(Class)someClass;

@end
