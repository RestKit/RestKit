//
//  RKManagedObjectThreadSafeInvocation.h
//  RestKit
//
//  Created by Blake Watters on 5/12/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
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
