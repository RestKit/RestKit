//
//  RKObjectDelegateNotifierSpec.h
//  RestKit
//
//  Created by Blake Watters on 5/12/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKHuman.h"
#import "RKManagedObjectThreadSafeInvocation.h"

@interface RKManagedObjectThreadSafeInvocationSpec : RKSpec {
    NSMutableDictionary* _dictionary;
    RKManagedObjectStore* _objectStore;
    id _results;
    BOOL _waiting;
}

@end

@implementation RKManagedObjectThreadSafeInvocationSpec

- (void)itShouldSerializeOneManagedObjectToManagedObjectID {
    RKSpecNewManagedObjectStore();
    RKHuman* human = [RKHuman object];
    NSMutableDictionary* dictionary = [NSMutableDictionary dictionaryWithObject:human forKey:@"human"];
    NSMethodSignature* signature = [self methodSignatureForSelector:@selector(informDelegateWithDictionary:)];
    RKManagedObjectThreadSafeInvocation* invocation = [RKManagedObjectThreadSafeInvocation invocationWithMethodSignature:signature];
    [invocation serializeManagedObjectsForArgument:dictionary withKeyPaths:[NSSet setWithObject:@"human"]];
    assertThat([dictionary valueForKeyPath:@"human"], is(instanceOf([NSManagedObjectID class])));
}

- (void)itShouldSerializeCollectionOfManagedObjectsToManagedObjectIDs {
    RKSpecNewManagedObjectStore();
    RKHuman* human1 = [RKHuman object];
    RKHuman* human2 = [RKHuman object];
    NSArray* humans = [NSArray arrayWithObjects:human1, human2, nil];
    NSMutableDictionary* dictionary = [NSMutableDictionary dictionaryWithObject:humans forKey:@"humans"];
    NSMethodSignature* signature = [self methodSignatureForSelector:@selector(informDelegateWithDictionary:)];
    RKManagedObjectThreadSafeInvocation* invocation = [RKManagedObjectThreadSafeInvocation invocationWithMethodSignature:signature];
    [invocation serializeManagedObjectsForArgument:dictionary withKeyPaths:[NSSet setWithObject:@"humans"]];
    assertThat([dictionary valueForKeyPath:@"humans"], is(instanceOf([NSArray class])));
    assertThat([[dictionary valueForKeyPath:@"humans"] lastObject], is(instanceOf([NSManagedObjectID class])));
}

- (void)itShouldDeserializeOneManagedObjectIDToManagedObject {
    RKManagedObjectStore* store = RKSpecNewManagedObjectStore();
    RKHuman* human = [RKHuman object];
    NSMutableDictionary* dictionary = [NSMutableDictionary dictionaryWithObject:[human objectID] forKey:@"human"];
    NSMethodSignature* signature = [self methodSignatureForSelector:@selector(informDelegateWithDictionary:)];
    RKManagedObjectThreadSafeInvocation* invocation = [RKManagedObjectThreadSafeInvocation invocationWithMethodSignature:signature];
    invocation.objectStore = store;
    [invocation deserializeManagedObjectIDsForArgument:dictionary withKeyPaths:[NSSet setWithObject:@"human"]];
    assertThat([dictionary valueForKeyPath:@"human"], is(instanceOf([NSManagedObject class])));
    assertThat([dictionary valueForKeyPath:@"human"], is(equalTo(human)));
}

- (void)itShouldDeserializeCollectionOfManagedObjectIDToManagedObjects {
    RKManagedObjectStore* store = RKSpecNewManagedObjectStore();
    RKHuman* human1 = [RKHuman object];
    RKHuman* human2 = [RKHuman object];
    NSArray* humanIDs = [NSArray arrayWithObjects:[human1 objectID], [human2 objectID], nil];
    NSMutableDictionary* dictionary = [NSMutableDictionary dictionaryWithObject:humanIDs forKey:@"humans"];
    NSMethodSignature* signature = [self methodSignatureForSelector:@selector(informDelegateWithDictionary:)];
    RKManagedObjectThreadSafeInvocation* invocation = [RKManagedObjectThreadSafeInvocation invocationWithMethodSignature:signature];
    invocation.objectStore = store;
    [invocation deserializeManagedObjectIDsForArgument:dictionary withKeyPaths:[NSSet setWithObject:@"humans"]];
    assertThat([dictionary valueForKeyPath:@"humans"], is(instanceOf([NSArray class])));
    NSArray* humans = [NSArray arrayWithObjects:human1, human2, nil];
    assertThat([dictionary valueForKeyPath:@"humans"], is(equalTo(humans)));
}

- (void)informDelegateWithDictionary:(NSDictionary*)results {
    assertThatBool([NSThread isMainThread], equalToBool(YES));
    assertThat(results, isNot(nilValue()));
    assertThat(results, isNot(empty()));
    assertThat([[results objectForKey:@"humans"] lastObject], is(instanceOf([NSManagedObject class])));
    _waiting = NO;
}

- (void)createBackgroundObjects {
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    assertThatBool([NSThread isMainThread], equalToBool(NO));
    
    // Assert this is not the main thread
    // Create a new array of objects in the background
    NSArray* humans = [NSArray arrayWithObject:[RKHuman object]];
    _dictionary = [[NSMutableDictionary dictionaryWithObject:humans forKey:@"humans"] retain];
    NSMethodSignature* signature = [self methodSignatureForSelector:@selector(informDelegateWithDictionary:)];
    RKManagedObjectThreadSafeInvocation* invocation = [RKManagedObjectThreadSafeInvocation invocationWithMethodSignature:signature];    
    invocation.objectStore = _objectStore;
    [invocation retain];
    [invocation setTarget:self];
    [invocation setSelector:@selector(informDelegateWithDictionary:)];
    [invocation setArgument:&_dictionary atIndex:2]; // NOTE: _cmd and self are 0 and 1
    [invocation setManagedObjectKeyPaths:[NSSet setWithObject:@"humans"] forArgument:2];
    [invocation invokeOnMainThread];
    
    [pool drain];
}

- (void)itShouldSerializeAndDeserializeManagedObjectsAcrossAThreadInvocation {
    _objectStore = [RKSpecNewManagedObjectStore() retain];
    _waiting = YES;
    [self performSelectorInBackground:@selector(createBackgroundObjects) withObject:nil];
    
    while (_waiting) {		
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
	}
}

@end
