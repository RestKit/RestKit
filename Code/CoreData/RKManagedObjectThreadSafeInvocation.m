//
//  RKManagedObjectThreadSafeInvocation.m
//  RestKit
//
//  Created by Blake Watters on 5/12/11.
//  Copyright 2011 Two Toasters
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

#import "RKManagedObjectThreadSafeInvocation.h"

@implementation RKManagedObjectThreadSafeInvocation

@synthesize objectStore = _objectStore;

+ (RKManagedObjectThreadSafeInvocation*)invocationWithMethodSignature:(NSMethodSignature*)methodSignature {
    return (RKManagedObjectThreadSafeInvocation*) [super invocationWithMethodSignature:methodSignature];
}

- (void)setManagedObjectKeyPaths:(NSSet*)keyPaths forArgument:(NSInteger)index {
    if (nil == _argumentKeyPaths) {        
        _argumentKeyPaths = [[NSMutableDictionary alloc] init];
    }
    
    NSNumber* argumentIndex = [NSNumber numberWithInteger:index];
    [_argumentKeyPaths setObject:keyPaths forKey:argumentIndex];
}

- (void)serializeManagedObjectsForArgument:(id)argument withKeyPaths:(NSSet*)keyPaths {
    for (NSString* keyPath in keyPaths) {
        id value = [argument valueForKeyPath:keyPath];
        if ([value isKindOfClass:[NSManagedObject class]]) {
            [argument setValue:[(NSManagedObject*)value objectID] forKeyPath:keyPath];
        } else if ([value respondsToSelector:@selector(allObjects)]) {
            id collection = [[[[[value class] alloc] init] autorelease] mutableCopy];
            for (id subObject in value) {
                if ([subObject isKindOfClass:[NSManagedObject class]]) {
                    [collection addObject:[(NSManagedObject*)subObject objectID]];
                } else {
                    [collection addObject:subObject];
                }
            }
            
            [argument setValue:collection forKeyPath:keyPath];
            [collection release];
        }
    }
}

- (void)deserializeManagedObjectIDsForArgument:(id)argument withKeyPaths:(NSSet*)keyPaths {   
    for (NSString* keyPath in keyPaths) {
        id value = [argument valueForKeyPath:keyPath];
        if ([value isKindOfClass:[NSManagedObjectID class]]) {
            NSAssert(self.objectStore, @"Object store cannot be nil");
            NSManagedObject* managedObject = [self.objectStore objectWithID:(NSManagedObjectID*)value];
            NSAssert(managedObject, @"Expected managed object for ID %@, got nil", value);
            [argument setValue:managedObject forKeyPath:keyPath];
        } else if ([value respondsToSelector:@selector(allObjects)]) {
            id collection = [[[[[value class] alloc] init] autorelease] mutableCopy];
            for (id subObject in value) {
                if ([subObject isKindOfClass:[NSManagedObjectID class]]) {
                    NSManagedObject* managedObject = [self.objectStore objectWithID:(NSManagedObjectID*)subObject];
                    [collection addObject:managedObject];
                } else {
                    [collection addObject:subObject];
                }
            }
            
            [argument setValue:collection forKeyPath:keyPath];
            [collection release];
        }
    }
}

- (void)serializeManagedObjects {
    for (NSNumber* argumentIndex in _argumentKeyPaths) {        
        NSSet* managedKeyPaths = [_argumentKeyPaths objectForKey:argumentIndex];
        id argument = nil;
        [self getArgument:&argument atIndex:[argumentIndex intValue]];
        if (argument) {
            [self serializeManagedObjectsForArgument:argument withKeyPaths:managedKeyPaths];
        }
    }
}

- (void)deserializeManagedObjects {
    for (NSNumber* argumentIndex in _argumentKeyPaths) {        
        NSSet* managedKeyPaths = [_argumentKeyPaths objectForKey:argumentIndex];
        id argument = nil;
        [self getArgument:&argument atIndex:[argumentIndex intValue]];
        if (argument) {
            [self deserializeManagedObjectIDsForArgument:argument withKeyPaths:managedKeyPaths];
        }
    }
}

- (void)performInvocationOnMainThread {
    [self deserializeManagedObjects];
    [self invoke];
}

- (void)invokeOnMainThread {
    [self retain];
    [self serializeManagedObjects];
    [self performSelectorOnMainThread:@selector(performInvocationOnMainThread) withObject:nil waitUntilDone:YES];
    [self release];
}

- (void)dealloc {
    [_argumentKeyPaths release];
    [_objectStore release];
    [super dealloc];
}

@end
