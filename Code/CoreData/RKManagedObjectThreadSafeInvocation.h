//
//  RKManagedObjectThreadSafeInvocation.h
//  RestKit
//
//  Created by Blake Watters on 5/12/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKManagedObjectStore.h"

@interface RKManagedObjectThreadSafeInvocation : NSInvocation {
    NSMutableDictionary* _argumentKeyPaths;
    RKManagedObjectStore* _objectStore;
}

@property (nonatomic, retain) RKManagedObjectStore* objectStore;

+ (RKManagedObjectThreadSafeInvocation*)invocationWithMethodSignature:(NSMethodSignature*)methodSignature;
- (void)setManagedObjectKeyPaths:(NSSet*)keyPaths forArgument:(NSInteger)index;
- (void)invokeOnMainThread;

// Private
- (void)serializeManagedObjectsForArgument:(id)argument withKeyPaths:(NSSet*)keyPaths;
- (void)deserializeManagedObjectIDsForArgument:(id)argument withKeyPaths:(NSSet*)keyPaths;

@end
