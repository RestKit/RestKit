//
//  RKInMemoryEntityCacheTest.m
//  RestKit
//
//  Created by Jeff Arena on 1/25/12.
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

@interface RKInMemoryEntityCache ()
@property(nonatomic, retain) NSMutableDictionary *entityCache;

- (BOOL)shouldCoerceAttributeToString:(NSString *)attribute forEntity:(NSEntityDescription *)entity;
- (NSManagedObject *)objectWithID:(NSManagedObjectID *)objectID inContext:(NSManagedObjectContext *)managedObjectContext;
@end

@interface RKInMemoryEntityCacheTest : RKTestCase

@end

@implementation RKInMemoryEntityCacheTest

- (void)testInitializationWithManagedObjectContext
{
    RKManagedObjectStore *objectStore = [RKTestFactory managedObjectStore];
    RKInMemoryEntityCache *cache = [[RKInMemoryEntityCache alloc] initWithManagedObjectContext:objectStore.primaryManagedObjectContext];
    assertThat(cache.managedObjectContext, is(equalTo(objectStore.primaryManagedObjectContext)));
}

- (void)testShouldCoercePrimaryKeysToStringsForLookup {
    RKManagedObjectStore* objectStore = [RKTestFactory managedObjectStore];
    RKHuman* human = [RKHuman createEntity];
    human.railsID = [NSNumber numberWithInt:1234];
    [objectStore save:nil];

    RKInMemoryEntityCache *entityCache = [[[RKInMemoryEntityCache alloc] init] autorelease];
    assertThatBool([entityCache shouldCoerceAttributeToString:@"railsID" forEntity:human.entity], is(equalToBool(YES)));
}

- (void)testShouldCacheAllObjectsForEntityWhenAccessingEntityCache {
    RKManagedObjectStore* objectStore = [RKTestFactory managedObjectStore];
    RKHuman* human = [RKHuman createEntity];
    human.railsID = [NSNumber numberWithInt:1234];
    [objectStore save:nil];

    RKInMemoryEntityCache *entityCache = [[[RKInMemoryEntityCache alloc] init] autorelease];
    NSMutableDictionary *humanCache = [entityCache cachedObjectsForEntity:human.entity
                                                              byAttribute:@"railsID"
                                                                inContext:objectStore.primaryManagedObjectContext];
    assertThatInteger([humanCache count], is(equalToInt(1)));
}

- (void)testShouldCacheAllObjectsForEntityWhenAsked {
    RKManagedObjectStore* objectStore = [RKTestFactory managedObjectStore];
    RKHuman* human = [RKHuman createEntity];
    human.railsID = [NSNumber numberWithInt:1234];
    [objectStore save:nil];

    RKInMemoryEntityCache *entityCache = [[[RKInMemoryEntityCache alloc] init] autorelease];
    [entityCache cacheObjectsForEntity:human.entity byAttribute:@"railsID" inContext:objectStore.primaryManagedObjectContext];
    NSMutableDictionary *humanCache = [entityCache cachedObjectsForEntity:human.entity
                                                              byAttribute:@"railsID"
                                                                inContext:objectStore.primaryManagedObjectContext];
    assertThatInteger([humanCache count], is(equalToInt(1)));
}

- (void)testShouldRetrieveObjectsProperlyFromTheEntityCache {
    RKManagedObjectStore* objectStore = [RKTestFactory managedObjectStore];
    RKHuman* human = [RKHuman createEntity];
    human.railsID = [NSNumber numberWithInt:1234];
    [objectStore save:nil];

    RKInMemoryEntityCache *entityCache = [[[RKInMemoryEntityCache alloc] init] autorelease];
    NSManagedObject *cachedInstance = [entityCache cachedObjectForEntity:human.entity
                                                           withAttribute:@"railsID"
                                                                   value:[NSNumber numberWithInt:1234]
                                                               inContext:objectStore.primaryManagedObjectContext];
    assertThat(cachedInstance, is(equalTo(human)));
}

- (void)testShouldCacheAnIndividualObjectWhenAsked {
    RKManagedObjectStore* objectStore = [RKTestFactory managedObjectStore];
    RKHuman* human = [RKHuman createEntity];
    human.railsID = [NSNumber numberWithInt:1234];
    [objectStore save:nil];

    RKInMemoryEntityCache *entityCache = [[[RKInMemoryEntityCache alloc] init] autorelease];
    NSMutableDictionary *humanCache = [entityCache cachedObjectsForEntity:human.entity
                                                              byAttribute:@"railsID"
                                                                inContext:objectStore.primaryManagedObjectContext];
    assertThatInteger([humanCache count], is(equalToInt(1)));

    RKHuman* newHuman = [RKHuman createEntity];
    newHuman.railsID = [NSNumber numberWithInt:5678];

    [entityCache cacheObject:newHuman byAttribute:@"railsID" inContext:objectStore.primaryManagedObjectContext];
    [entityCache cacheObjectsForEntity:human.entity byAttribute:@"railsID" inContext:objectStore.primaryManagedObjectContext];
    humanCache = [entityCache cachedObjectsForEntity:human.entity
                                         byAttribute:@"railsID"
                                           inContext:objectStore.primaryManagedObjectContext];
    assertThatInteger([humanCache count], is(equalToInt(2)));
}

- (void)testShouldCacheAnIndividualObjectByPrimaryKeyValueWhenAsked {
    RKManagedObjectStore* objectStore = [RKTestFactory managedObjectStore];
    RKHuman* human = [RKHuman createEntity];
    human.railsID = [NSNumber numberWithInt:1234];
    [objectStore save:nil];

    RKInMemoryEntityCache *entityCache = [[[RKInMemoryEntityCache alloc] init] autorelease];
    NSMutableDictionary *humanCache = [entityCache cachedObjectsForEntity:human.entity
                                                              byAttribute:@"railsID"
                                                                inContext:objectStore.primaryManagedObjectContext];
    assertThatInteger([humanCache count], is(equalToInt(1)));

    RKHuman* newHuman = [RKHuman createEntity];
    newHuman.railsID = [NSNumber numberWithInt:5678];
    [objectStore save:nil];

    [entityCache cacheObject:newHuman.entity
                 byAttribute:@"railsID"
                       value:[NSNumber numberWithInt:5678]
                   inContext:objectStore.primaryManagedObjectContext];
    [entityCache cacheObjectsForEntity:human.entity byAttribute:@"railsID" inContext:objectStore.primaryManagedObjectContext];

    humanCache = [entityCache cachedObjectsForEntity:human.entity byAttribute:@"railsID" inContext:objectStore.primaryManagedObjectContext];
    assertThatInteger([humanCache count], is(equalToInt(2)));
}

- (void)testShouldExpireACacheEntryForAnObjectWhenAsked {
    RKManagedObjectStore* objectStore = [RKTestFactory managedObjectStore];
    RKHuman* human = [RKHuman createEntity];
    human.railsID = [NSNumber numberWithInt:1234];
    [objectStore save:nil];

    RKInMemoryEntityCache *entityCache = [[[RKInMemoryEntityCache alloc] init] autorelease];
    NSMutableDictionary *humanCache = [entityCache cachedObjectsForEntity:human.entity
                                                              byAttribute:@"railsID"
                                                                inContext:objectStore.primaryManagedObjectContext];
    assertThatInteger([humanCache count], is(equalToInt(1)));

    [entityCache expireCacheEntryForObject:human byAttribute:@"railsID" inContext:objectStore.primaryManagedObjectContext];
    assertThatInteger([entityCache.entityCache count], is(equalToInt(0)));
}

- (void)testShouldExpireEntityCacheWhenAsked {
    RKManagedObjectStore* objectStore = [RKTestFactory managedObjectStore];
    RKHuman* human = [RKHuman createEntity];
    human.railsID = [NSNumber numberWithInt:1234];
    [objectStore save:nil];

    RKInMemoryEntityCache *entityCache = [[[RKInMemoryEntityCache alloc] init] autorelease];
    NSMutableDictionary *humanCache = [entityCache cachedObjectsForEntity:human.entity
                                                              byAttribute:@"railsID"
                                                                inContext:objectStore.primaryManagedObjectContext];
    assertThatInteger([humanCache count], is(equalToInt(1)));

    [entityCache expireCacheEntriesForEntity:human.entity];
    assertThatInteger([entityCache.entityCache count], is(equalToInt(0)));
}

#if TARGET_OS_IPHONE
- (void)testShouldExpireEntityCacheInResponseToMemoryWarning {
    RKManagedObjectStore* objectStore = [RKTestFactory managedObjectStore];
    RKHuman* human = [RKHuman createEntity];
    human.railsID = [NSNumber numberWithInt:1234];
    [objectStore save:nil];

    RKInMemoryEntityCache *entityCache = [[[RKInMemoryEntityCache alloc] init] autorelease];
    NSMutableDictionary *humanCache = [entityCache cachedObjectsForEntity:human.entity
                                                              byAttribute:@"railsID"
                                                                inContext:objectStore.primaryManagedObjectContext];
    assertThatInteger([humanCache count], is(equalToInt(1)));

    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    assertThatInteger([entityCache.entityCache count], is(equalToInt(0)));
}
#endif

- (void)testShouldAddInstancesOfInsertedObjectsToCache {
    RKManagedObjectStore* objectStore = [RKTestFactory managedObjectStore];
    RKHuman* human = [RKHuman createEntity];
    human.railsID = [NSNumber numberWithInt:1234];
    [objectStore save:nil];

    RKInMemoryEntityCache *entityCache = [[[RKInMemoryEntityCache alloc] init] autorelease];
    NSMutableDictionary *humanCache = [entityCache cachedObjectsForEntity:human.entity
                                                              byAttribute:@"railsID"
                                                                inContext:objectStore.primaryManagedObjectContext];
    assertThatInteger([humanCache count], is(equalToInt(1)));

    RKHuman* newHuman = [RKHuman createEntity];
    newHuman.railsID = [NSNumber numberWithInt:5678];
    [objectStore save:nil];

    humanCache = [entityCache cachedObjectsForEntity:human.entity
                                         byAttribute:@"railsID"
                                           inContext:objectStore.primaryManagedObjectContext];
    assertThatInteger([humanCache count], is(equalToInt(2)));
}

- (void)testShouldRemoveInstancesOfDeletedObjectsToCache {
    RKManagedObjectStore* objectStore = [RKTestFactory managedObjectStore];
    RKHuman* humanOne = [RKHuman createEntity];
    humanOne.railsID = [NSNumber numberWithInt:1234];

    RKHuman* humanTwo = [RKHuman createEntity];
    humanTwo.railsID = [NSNumber numberWithInt:5678];
    [objectStore save:nil];

    RKInMemoryEntityCache *entityCache = [[[RKInMemoryEntityCache alloc] init] autorelease];
    NSMutableDictionary *humanCache = [entityCache cachedObjectsForEntity:humanOne.entity
                                                              byAttribute:@"railsID"
                                                                inContext:objectStore.primaryManagedObjectContext];
    assertThatInteger([humanCache count], is(equalToInt(2)));

    [humanTwo deleteEntity];
    [objectStore save:nil];

    humanCache = [entityCache cachedObjectsForEntity:humanOne.entity
                                         byAttribute:@"railsID"
                                           inContext:objectStore.primaryManagedObjectContext];
    assertThatInteger([humanCache count], is(equalToInt(1)));
}

- (void)testThatDeletionOfObjectsDoesNotPermitCreationOfDuplicates {
    RKManagedObjectStore* objectStore = [RKTestFactory managedObjectStore];
    RKHuman* humanOne = [RKHuman createEntity];
    humanOne.railsID = [NSNumber numberWithInt:1234];
    
    RKHuman* humanTwo = [RKHuman createEntity];
    humanTwo.railsID = [NSNumber numberWithInt:5678];
    [objectStore save:nil];
    
    RKInMemoryEntityCache *entityCache = [[[RKInMemoryEntityCache alloc] init] autorelease];
    NSMutableDictionary *humanCache = [entityCache cachedObjectsForEntity:humanOne.entity
                                                              byAttribute:@"railsID"
                                                                inContext:objectStore.primaryManagedObjectContext];
    assertThatInteger([humanCache count], is(equalToInt(2)));
    
    [humanTwo deleteEntity];
    [objectStore save:nil];
    
    RKHuman *existingReference = (RKHuman *)[entityCache cachedObjectForEntity:[RKHuman entity] withAttribute:@"railsID" value:[NSNumber numberWithInt:1234] inContext:objectStore.primaryManagedObjectContext];
    
    assertThat(existingReference, is(notNilValue()));
    assertThat(existingReference, is(equalTo(humanOne)));
}

- (void)testThatRepeatedInvocationsOfLoadObjectDoesNotDuplicateObjects {
    RKManagedObjectStore *objectStore = [RKTestFactory managedObjectStore];
    objectStore.cacheStrategy = [RKInMemoryManagedObjectCache new];
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    objectManager.objectStore = objectStore;
    RKManagedObjectMapping *humanMapping = [RKManagedObjectMapping mappingForClass:[RKHuman class] inManagedObjectStore:objectStore];
    humanMapping.primaryKeyAttribute = @"name";
    [humanMapping mapKeyPath:@"id" toAttribute:@"railsID"];
    [humanMapping mapAttributes:@"name", nil];
    [objectManager.mappingProvider setObjectMapping:humanMapping forKeyPath:@"human"];
    
    for (NSUInteger i = 0; i < 5; i++) {
        RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
        [objectManager loadObjectsAtResourcePath:@"/JSON/ArrayOfHumans.json" delegate:responseLoader];
        [responseLoader waitForResponse];
        for (RKHuman *object in [RKHuman allObjects]) {
            if ([object.railsID intValue] == 201) {
                [objectStore.managedObjectContextForCurrentThread deleteObject:object];
                [objectStore.managedObjectContextForCurrentThread save:nil];
            }
        }
        
        [objectStore save:nil];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
    }
    
    NSUInteger count = [RKHuman count:nil];
    assertThatInt(count, is(equalToInt(1)));
    NSArray *humans = [RKHuman allObjects];
    [humans makeObjectsPerformSelector:@selector(railsID)];
}

@end
