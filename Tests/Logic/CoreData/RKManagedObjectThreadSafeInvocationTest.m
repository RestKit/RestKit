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

@interface RKManagedObjectThreadSafeInvocation (Private)
- (void)serializeManagedObjectsForArgument:(id)argument withKeyPaths:(NSSet *)keyPaths;
- (void)deserializeManagedObjectIDsForArgument:(id)argument withKeyPaths:(NSSet *)keyPaths;
@end

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
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    objectManager.managedObjectStore = managedObjectStore;
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithObject:human forKey:@"human"];
    NSMethodSignature *signature = [self methodSignatureForSelector:@selector(informDelegateWithDictionary:)];
    RKManagedObjectThreadSafeInvocation *invocation = [RKManagedObjectThreadSafeInvocation invocationWithMethodSignature:signature];
    [invocation serializeManagedObjectsForArgument:dictionary withKeyPaths:[NSSet setWithObject:@"human"]];
    assertThat([dictionary valueForKeyPath:@"human"], is(instanceOf([NSManagedObjectID class])));
}

- (void)testShouldSerializeOneManagedObjectWithKeyPathToManagedObjectID
{
    NSString *testKey = @"data.human";
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    objectManager.managedObjectStore = managedObjectStore;
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithObject:human forKey:testKey];
    NSMethodSignature *signature = [self methodSignatureForSelector:@selector(informDelegateWithDictionary:)];
    RKManagedObjectThreadSafeInvocation *invocation = [RKManagedObjectThreadSafeInvocation invocationWithMethodSignature:signature];
    [invocation serializeManagedObjectsForArgument:dictionary withKeyPaths:[NSSet setWithObject:testKey]];
    assertThat([dictionary valueForKeyPath:testKey], is(instanceOf([NSManagedObjectID class])));
}


- (void)testShouldSerializeCollectionOfManagedObjectsToManagedObjectIDs
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    objectManager.managedObjectStore = managedObjectStore;
    RKHuman *human1 = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    RKHuman *human2 = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
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
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    objectManager.managedObjectStore = managedObjectStore;

    NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    __block NSError *error;
    __block NSManagedObjectID *objectID;
    __block NSMutableDictionary *dictionary;
    [managedObjectContext performBlockAndWait:^{
        managedObjectContext.parentContext = managedObjectStore.primaryManagedObjectContext;
        RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectContext];
        BOOL success = [managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObject:human] error:&error];

        success = [managedObjectContext save:&error];
        [managedObjectContext.parentContext performBlockAndWait:^{
            [managedObjectContext.parentContext save:&error];
        }];
        assertThatBool(success, is(equalToBool(YES)));

        dictionary = [NSMutableDictionary dictionaryWithObject:[human objectID] forKey:@"human"];
        objectID = human.objectID;
    }];

    [managedObjectStore.mainQueueManagedObjectContext reset];
    NSMethodSignature *signature = [self methodSignatureForSelector:@selector(informDelegateWithDictionary:)];
    RKManagedObjectThreadSafeInvocation* invocation = [RKManagedObjectThreadSafeInvocation invocationWithMethodSignature:signature];
    invocation.privateQueueManagedObjectContext = managedObjectContext;
    invocation.mainQueueManagedObjectContext = managedObjectStore.mainQueueManagedObjectContext;
    [invocation deserializeManagedObjectIDsForArgument:dictionary withKeyPaths:[NSSet setWithObject:@"human"]];
    assertThat([dictionary valueForKeyPath:@"human"], is(instanceOf([NSManagedObject class])));
    assertThat([[dictionary valueForKeyPath:@"human"] objectID], is(equalTo(objectID)));
}

- (void)testShouldDeserializeCollectionOfManagedObjectIDToManagedObjects
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    objectManager.managedObjectStore = managedObjectStore;
    __block NSArray *humanIDs;
    [managedObjectStore.primaryManagedObjectContext performBlockAndWait:^{
        RKHuman *human1 = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
        RKHuman *human2 = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
        NSError *error;
        BOOL success = [managedObjectStore.primaryManagedObjectContext save:&error];
        assertThatBool(success, is(equalToBool(YES)));

        humanIDs = [NSArray arrayWithObjects:[human1 objectID], [human2 objectID], nil];
    }];

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithObject:humanIDs forKey:@"humans"];
    NSMethodSignature *signature = [self methodSignatureForSelector:@selector(informDelegateWithDictionary:)];
    RKManagedObjectThreadSafeInvocation *invocation = [RKManagedObjectThreadSafeInvocation invocationWithMethodSignature:signature];
    invocation.privateQueueManagedObjectContext = managedObjectStore.primaryManagedObjectContext;
    invocation.mainQueueManagedObjectContext = managedObjectStore.mainQueueManagedObjectContext;
    [invocation deserializeManagedObjectIDsForArgument:dictionary withKeyPaths:[NSSet setWithObject:@"humans"]];
    assertThat([dictionary valueForKeyPath:@"humans"], is(instanceOf([NSArray class])));
    assertThat([dictionary valueForKeyPath:@"humans.objectID"], is(equalTo(humanIDs)));
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
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    objectManager.managedObjectStore = managedObjectStore;
    NSArray *humans = [NSArray arrayWithObject:[NSEntityDescription entityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext]];
    _dictionary = [[NSMutableDictionary dictionaryWithObject:humans forKey:@"humans"] retain];
    NSMethodSignature *signature = [self methodSignatureForSelector:@selector(informDelegateWithDictionary:)];
    RKManagedObjectThreadSafeInvocation *invocation = [RKManagedObjectThreadSafeInvocation invocationWithMethodSignature:signature];
    invocation.privateQueueManagedObjectContext = _objectStore.primaryManagedObjectContext;
    invocation.mainQueueManagedObjectContext = _objectStore.mainQueueManagedObjectContext;
    [invocation retain];
    [invocation setTarget:self];
    [invocation setSelector:@selector(informDelegateWithDictionary:)];
    [invocation setArgument:&_dictionary atIndex:2]; // NOTE: _cmd and self are 0 and 1
    [invocation setManagedObjectKeyPaths:[NSSet setWithObject:@"humans"] forArgument:2];
    [invocation invokeOnMainThread];

    [pool drain];
}

@end
