//
//  RKManagedObjectThreadSafeInvocationTest.h
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

#import "RKTestEnvironment.h"
#import "RKHuman.h"
#import "RKManagedObjectThreadSafeInvocation.h"

@interface RKManagedObjectThreadSafeInvocationTest : RKTestCase {
    NSMutableDictionary *_dictionary;
    RKManagedObjectStore *_objectStore;
    id _results;
    BOOL _waiting;
}

@end

@implementation RKManagedObjectThreadSafeInvocationTest

- (void)testShouldSerializeOneManagedObjectToManagedObjectID
{
    RKManagedObjectStore *objectStore = [RKTestFactory managedObjectStore];
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    objectManager.objectStore = objectStore;
    RKHuman *human = [RKHuman object];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithObject:human forKey:@"human"];
    NSMethodSignature *signature = [self methodSignatureForSelector:@selector(informDelegateWithDictionary:)];
    RKManagedObjectThreadSafeInvocation *invocation = [RKManagedObjectThreadSafeInvocation invocationWithMethodSignature:signature];
    [invocation serializeManagedObjectsForArgument:dictionary withKeyPaths:[NSSet setWithObject:@"human"]];
    assertThat([dictionary valueForKeyPath:@"human"], is(instanceOf([NSManagedObjectID class])));
}

- (void)testShouldSerializeOneManagedObjectWithKeyPathToManagedObjectID
{
    NSString *testKey = @"data.human";
    RKManagedObjectStore *objectStore = [RKTestFactory managedObjectStore];
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    objectManager.objectStore = objectStore;
    RKHuman *human = [RKHuman object];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithObject:human forKey:testKey];
    NSMethodSignature *signature = [self methodSignatureForSelector:@selector(informDelegateWithDictionary:)];
    RKManagedObjectThreadSafeInvocation *invocation = [RKManagedObjectThreadSafeInvocation invocationWithMethodSignature:signature];
    [invocation serializeManagedObjectsForArgument:dictionary withKeyPaths:[NSSet setWithObject:testKey]];
    assertThat([dictionary valueForKeyPath:testKey], is(instanceOf([NSManagedObjectID class])));
}


- (void)testShouldSerializeCollectionOfManagedObjectsToManagedObjectIDs
{
    RKManagedObjectStore *objectStore = [RKTestFactory managedObjectStore];
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    objectManager.objectStore = objectStore;
    RKHuman *human1 = [RKHuman object];
    RKHuman *human2 = [RKHuman object];
    NSArray *humans = [NSArray arrayWithObjects:human1, human2, nil];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithObject:humans forKey:@"humans"];
    NSMethodSignature *signature = [self methodSignatureForSelector:@selector(informDelegateWithDictionary:)];
    RKManagedObjectThreadSafeInvocation *invocation = [RKManagedObjectThreadSafeInvocation invocationWithMethodSignature:signature];
    [invocation serializeManagedObjectsForArgument:dictionary withKeyPaths:[NSSet setWithObject:@"humans"]];
    assertThat([dictionary valueForKeyPath:@"humans"], is(instanceOf([NSArray class])));
    assertThat([[dictionary valueForKeyPath:@"humans"] lastObject], is(instanceOf([NSManagedObjectID class])));
}

- (void)testShouldDeserializeOneManagedObjectIDToManagedObject
{
    RKManagedObjectStore *objectStore = [RKTestFactory managedObjectStore];
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    objectManager.objectStore = objectStore;
    RKHuman *human = [RKHuman object];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithObject:[human objectID] forKey:@"human"];
    NSMethodSignature *signature = [self methodSignatureForSelector:@selector(informDelegateWithDictionary:)];
    RKManagedObjectThreadSafeInvocation *invocation = [RKManagedObjectThreadSafeInvocation invocationWithMethodSignature:signature];
    invocation.objectStore = objectStore;
    [invocation deserializeManagedObjectIDsForArgument:dictionary withKeyPaths:[NSSet setWithObject:@"human"]];
    assertThat([dictionary valueForKeyPath:@"human"], is(instanceOf([NSManagedObject class])));
    assertThat([dictionary valueForKeyPath:@"human"], is(equalTo(human)));
}

- (void)testShouldDeserializeCollectionOfManagedObjectIDToManagedObjects
{
    RKManagedObjectStore *objectStore = [RKTestFactory managedObjectStore];
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    objectManager.objectStore = objectStore;
    RKHuman *human1 = [RKHuman object];
    RKHuman *human2 = [RKHuman object];
    NSArray *humanIDs = [NSArray arrayWithObjects:[human1 objectID], [human2 objectID], nil];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithObject:humanIDs forKey:@"humans"];
    NSMethodSignature *signature = [self methodSignatureForSelector:@selector(informDelegateWithDictionary:)];
    RKManagedObjectThreadSafeInvocation *invocation = [RKManagedObjectThreadSafeInvocation invocationWithMethodSignature:signature];
    invocation.objectStore = objectStore;
    [invocation deserializeManagedObjectIDsForArgument:dictionary withKeyPaths:[NSSet setWithObject:@"humans"]];
    assertThat([dictionary valueForKeyPath:@"humans"], is(instanceOf([NSArray class])));
    NSArray *humans = [NSArray arrayWithObjects:human1, human2, nil];
    assertThat([dictionary valueForKeyPath:@"humans"], is(equalTo(humans)));
}

- (void)informDelegateWithDictionary:(NSDictionary *)results
{
    assertThatBool([NSThread isMainThread], equalToBool(YES));
    assertThat(results, isNot(nilValue()));
    assertThat(results, isNot(empty()));
    assertThat([[results objectForKey:@"humans"] lastObject], is(instanceOf([NSManagedObject class])));
    _waiting = NO;
}

- (void)createBackgroundObjects
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    assertThatBool([NSThread isMainThread], equalToBool(NO));

    // Assert this is not the main thread
    // Create a new array of objects in the background
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    objectManager.objectStore = [RKTestFactory managedObjectStore];
    NSArray *humans = [NSArray arrayWithObject:[RKHuman object]];
    _dictionary = [[NSMutableDictionary dictionaryWithObject:humans forKey:@"humans"] retain];
    NSMethodSignature *signature = [self methodSignatureForSelector:@selector(informDelegateWithDictionary:)];
    RKManagedObjectThreadSafeInvocation *invocation = [RKManagedObjectThreadSafeInvocation invocationWithMethodSignature:signature];
    invocation.objectStore = _objectStore;
    [invocation retain];
    [invocation setTarget:self];
    [invocation setSelector:@selector(informDelegateWithDictionary:)];
    [invocation setArgument:&_dictionary atIndex:2]; // NOTE: _cmd and self are 0 and 1
    [invocation setManagedObjectKeyPaths:[NSSet setWithObject:@"humans"] forArgument:2];
    [invocation invokeOnMainThread];

    [pool drain];
}

- (void)testShouldSerializeAndDeserializeManagedObjectsAcrossAThreadInvocation
{
    _objectStore = [[RKTestFactory managedObjectStore] retain];
    _waiting = YES;
    [self performSelectorInBackground:@selector(createBackgroundObjects) withObject:nil];

    while (_waiting) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
}

@end
