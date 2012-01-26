//
//  RKInMemoryEntityCacheSpec.m
//  RestKit
//
//  Created by Jeff Arena on 1/25/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
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

#import "RKSpecEnvironment.h"
#import "RKHuman.h"

@interface RKInMemoryEntityCacheSpec : RKSpec

@end

@implementation RKInMemoryEntityCacheSpec

- (void)testShouldCoercePrimaryKeysToStringsForLookup {
    RKManagedObjectStore* objectStore = RKSpecNewManagedObjectStore();    
    RKHuman* human = [RKHuman createEntity];
    human.railsID = [NSNumber numberWithInt:1234];
    [objectStore save];

    RKInMemoryEntityCache *entityCache = [[[RKInMemoryEntityCache alloc] init] autorelease];
    assertThatBool([entityCache shouldCoerceAttributeToString:@"railsID" forEntity:human.entity], is(equalToBool(YES)));
}

- (void)testShouldCacheAllObjectsForEntityWhenAccessingEntityCache {
    RKManagedObjectStore* objectStore = RKSpecNewManagedObjectStore();
    RKHuman* human = [RKHuman createEntity];
    human.railsID = [NSNumber numberWithInt:1234];
    [objectStore save];
    
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[RKHuman class]];
    mapping.primaryKeyAttribute = @"railsID";
    
    RKInMemoryEntityCache *entityCache = [[[RKInMemoryEntityCache alloc] init] autorelease];
    NSMutableDictionary *humanCache = [entityCache cachedObjectsForEntity:human.entity
                                                              withMapping:mapping
                                                                inContext:objectStore.managedObjectContext];
    assertThatInteger([humanCache count], is(equalToInt(1)));
}

- (void)testShouldCacheAllObjectsForEntityWhenAsked {
    RKManagedObjectStore* objectStore = RKSpecNewManagedObjectStore();
    RKHuman* human = [RKHuman createEntity];
    human.railsID = [NSNumber numberWithInt:1234];
    [objectStore save];
    
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[RKHuman class]];
    mapping.primaryKeyAttribute = @"railsID";
    
    RKInMemoryEntityCache *entityCache = [[[RKInMemoryEntityCache alloc] init] autorelease];
    NSMutableDictionary *humanCache = [entityCache cacheObjectsForEntity:human.entity
                                                             withMapping:mapping
                                                               inContext:objectStore.managedObjectContext];
    assertThatInteger([humanCache count], is(equalToInt(1)));
}

- (void)testShouldRetrieveObjectsProperlyFromTheEntityCache {
    RKManagedObjectStore* objectStore = RKSpecNewManagedObjectStore();
    RKHuman* human = [RKHuman createEntity];
    human.railsID = [NSNumber numberWithInt:1234];
    [objectStore save];
    
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[RKHuman class]];
    mapping.primaryKeyAttribute = @"railsID";
    
    RKInMemoryEntityCache *entityCache = [[[RKInMemoryEntityCache alloc] init] autorelease];
    NSManagedObject *cachedInstance = [entityCache cachedObjectForEntity:human.entity
                                                             withMapping:mapping
                                                      andPrimaryKeyValue:[NSNumber numberWithInt:1234]                                                                inContext:objectStore.managedObjectContext];
    assertThat(cachedInstance, is(equalTo(human)));
}

- (void)testShouldCacheAnIndividualObjectWhenAsked {
    RKManagedObjectStore* objectStore = RKSpecNewManagedObjectStore();
    RKHuman* human = [RKHuman createEntity];
    human.railsID = [NSNumber numberWithInt:1234];
    [objectStore save];
    
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[RKHuman class]];
    mapping.primaryKeyAttribute = @"railsID";
    
    RKInMemoryEntityCache *entityCache = [[[RKInMemoryEntityCache alloc] init] autorelease];
    NSMutableDictionary *humanCache = [entityCache cachedObjectsForEntity:human.entity
                                                              withMapping:mapping
                                                                inContext:objectStore.managedObjectContext];
    assertThatInteger([humanCache count], is(equalToInt(1)));

    RKHuman* newHuman = [RKHuman createEntity];
    newHuman.railsID = [NSNumber numberWithInt:5678];

    [entityCache cacheObject:newHuman withMapping:mapping inContext:objectStore.managedObjectContext];    
    humanCache = [entityCache cacheObjectsForEntity:human.entity
                                        withMapping:mapping
                                          inContext:objectStore.managedObjectContext];
    assertThatInteger([humanCache count], is(equalToInt(2)));
}

- (void)testShouldCacheAnIndividualObjectByPrimaryKeyValueWhenAsked {
    RKManagedObjectStore* objectStore = RKSpecNewManagedObjectStore();
    RKHuman* human = [RKHuman createEntity];
    human.railsID = [NSNumber numberWithInt:1234];
    [objectStore save];
    
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[RKHuman class]];
    mapping.primaryKeyAttribute = @"railsID";
    
    RKInMemoryEntityCache *entityCache = [[[RKInMemoryEntityCache alloc] init] autorelease];
    NSMutableDictionary *humanCache = [entityCache cachedObjectsForEntity:human.entity
                                                              withMapping:mapping
                                                                inContext:objectStore.managedObjectContext];
    assertThatInteger([humanCache count], is(equalToInt(1)));
    
    RKHuman* newHuman = [RKHuman createEntity];
    newHuman.railsID = [NSNumber numberWithInt:5678];
    [objectStore save];
    
    [entityCache cacheObject:newHuman.entity
                 withMapping:mapping
          andPrimaryKeyValue:[NSNumber numberWithInt:5678]
                   inContext:objectStore.managedObjectContext];    
    humanCache = [entityCache cacheObjectsForEntity:human.entity
                                        withMapping:mapping
                                          inContext:objectStore.managedObjectContext];
    assertThatInteger([humanCache count], is(equalToInt(2)));
}

- (void)testShouldExpireACacheEntryForAnObjectWhenAsked {
    RKManagedObjectStore* objectStore = RKSpecNewManagedObjectStore();
    RKHuman* human = [RKHuman createEntity];
    human.railsID = [NSNumber numberWithInt:1234];
    [objectStore save];
    
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[RKHuman class]];
    mapping.primaryKeyAttribute = @"railsID";
    
    RKInMemoryEntityCache *entityCache = [[[RKInMemoryEntityCache alloc] init] autorelease];
    NSMutableDictionary *humanCache = [entityCache cachedObjectsForEntity:human.entity
                                                              withMapping:mapping
                                                                inContext:objectStore.managedObjectContext];
    assertThatInteger([humanCache count], is(equalToInt(1)));
    
    [entityCache expireCacheEntryForObject:human withMapping:mapping inContext:objectStore.managedObjectContext];
    assertThatInteger([entityCache.entityCache count], is(equalToInt(0)));
}

- (void)testShouldExpireEntityCacheWhenAsked {
    RKManagedObjectStore* objectStore = RKSpecNewManagedObjectStore();
    RKHuman* human = [RKHuman createEntity];
    human.railsID = [NSNumber numberWithInt:1234];
    [objectStore save];
    
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[RKHuman class]];
    mapping.primaryKeyAttribute = @"railsID";
    
    RKInMemoryEntityCache *entityCache = [[[RKInMemoryEntityCache alloc] init] autorelease];
    NSMutableDictionary *humanCache = [entityCache cachedObjectsForEntity:human.entity
                                                              withMapping:mapping
                                                                inContext:objectStore.managedObjectContext];
    assertThatInteger([humanCache count], is(equalToInt(1)));
    
    [entityCache expireCacheEntryForEntity:human.entity];
    assertThatInteger([entityCache.entityCache count], is(equalToInt(0)));
}

- (void)testShouldExpireEntityCacheInResponseToMemoryWarning {
    RKManagedObjectStore* objectStore = RKSpecNewManagedObjectStore();
    RKHuman* human = [RKHuman createEntity];
    human.railsID = [NSNumber numberWithInt:1234];
    [objectStore save];
    
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[RKHuman class]];
    mapping.primaryKeyAttribute = @"railsID";
    
    RKInMemoryEntityCache *entityCache = [[[RKInMemoryEntityCache alloc] init] autorelease];
    NSMutableDictionary *humanCache = [entityCache cachedObjectsForEntity:human.entity
                                                              withMapping:mapping
                                                                inContext:objectStore.managedObjectContext];
    assertThatInteger([humanCache count], is(equalToInt(1)));
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidReceiveMemoryWarningNotification object:nil];    
    assertThatInteger([entityCache.entityCache count], is(equalToInt(0)));
}

- (void)testShouldAddInstancesOfInsertedObjectsToCache {
    RKManagedObjectStore* objectStore = RKSpecNewManagedObjectStore();
    RKHuman* human = [RKHuman createEntity];
    human.railsID = [NSNumber numberWithInt:1234];
    [objectStore save];
    
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[RKHuman class]];
    mapping.primaryKeyAttribute = @"railsID";
    
    RKInMemoryEntityCache *entityCache = [[[RKInMemoryEntityCache alloc] init] autorelease];
    NSMutableDictionary *humanCache = [entityCache cachedObjectsForEntity:human.entity
                                                              withMapping:mapping
                                                                inContext:objectStore.managedObjectContext];
    assertThatInteger([humanCache count], is(equalToInt(1)));
    
    RKHuman* newHuman = [RKHuman createEntity];
    newHuman.railsID = [NSNumber numberWithInt:5678];
    [objectStore save];
     
    humanCache = [entityCache cachedObjectsForEntity:human.entity
                                         withMapping:mapping
                                           inContext:objectStore.managedObjectContext];
    assertThatInteger([humanCache count], is(equalToInt(2)));
}

- (void)testShouldRemoveInstancesOfDeletedObjectsToCache {
    RKManagedObjectStore* objectStore = RKSpecNewManagedObjectStore();
    RKHuman* humanOne = [RKHuman createEntity];
    humanOne.railsID = [NSNumber numberWithInt:1234];
    
    RKHuman* humanTwo = [RKHuman createEntity];
    humanTwo.railsID = [NSNumber numberWithInt:5678];
    [objectStore save];
    
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[RKHuman class]];
    mapping.primaryKeyAttribute = @"railsID";
    
    RKInMemoryEntityCache *entityCache = [[[RKInMemoryEntityCache alloc] init] autorelease];
    NSMutableDictionary *humanCache = [entityCache cachedObjectsForEntity:humanOne.entity
                                                              withMapping:mapping
                                                                inContext:objectStore.managedObjectContext];
    assertThatInteger([humanCache count], is(equalToInt(2)));
    
    [humanTwo deleteEntity];
    [objectStore save];
    
    humanCache = [entityCache cachedObjectsForEntity:humanOne.entity
                                         withMapping:mapping
                                           inContext:objectStore.managedObjectContext];
    assertThatInteger([humanCache count], is(equalToInt(1)));
}

@end
