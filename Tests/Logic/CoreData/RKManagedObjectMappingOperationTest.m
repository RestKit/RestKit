//
//  RKManagedObjectMappingOperationTest.m
//  RestKit
//
//  Created by Blake Watters on 5/31/11.
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
#import "RKManagedObjectMapping.h"
#import "RKManagedObjectMappingOperation.h"
#import "RKCat.h"
#import "RKHuman.h"
#import "RKChild.h"
#import "RKParent.h"
#import "RKBenchmark.h"

@interface RKManagedObjectMappingOperationTest : RKTestCase {

}

@end

@implementation RKManagedObjectMappingOperationTest

- (void)testShouldOverloadInitializationOfRKObjectMappingOperationToReturnInstancesOfRKManagedObjectMappingOperationWhenAppropriate
{
    RKManagedObjectStore *store = [RKTestFactory managedObjectStore];
    RKManagedObjectMapping *managedMapping = [RKManagedObjectMapping mappingForClass:[RKHuman class] inManagedObjectStore:store];
    NSDictionary *sourceObject = [NSDictionary dictionary];
    RKHuman *human = [RKHuman createEntity];
    RKObjectMappingOperation *operation = [RKObjectMappingOperation mappingOperationFromObject:sourceObject toObject:human withMapping:managedMapping];
    assertThat(operation, is(instanceOf([RKManagedObjectMappingOperation class])));
}

- (void)testShouldOverloadInitializationOfRKObjectMappingOperationButReturnUnmanagedMappingOperationWhenAppropriate
{
    RKObjectMapping *vanillaMapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    NSDictionary *sourceObject = [NSDictionary dictionary];
    NSMutableDictionary *destinationObject = [NSMutableDictionary dictionary];
    RKObjectMappingOperation *operation = [RKObjectMappingOperation mappingOperationFromObject:sourceObject toObject:destinationObject withMapping:vanillaMapping];
    assertThat(operation, is(instanceOf([RKObjectMappingOperation class])));
}

- (void)testShouldConnectRelationshipsByPrimaryKey
{
    RKManagedObjectStore *objectStore = [RKTestFactory managedObjectStore];

    RKManagedObjectMapping *catMapping = [RKManagedObjectMapping mappingForClass:[RKCat class] inManagedObjectStore:objectStore];
    catMapping.primaryKeyAttribute = @"railsID";
    [catMapping mapAttributes:@"name", nil];

    RKManagedObjectMapping *humanMapping = [RKManagedObjectMapping mappingForClass:[RKHuman class] inManagedObjectStore:objectStore];
    humanMapping.primaryKeyAttribute = @"railsID";
    [humanMapping mapAttributes:@"name", @"favoriteCatID", nil];
    [humanMapping hasOne:@"favoriteCat" withMapping:catMapping];
    [humanMapping connectRelationship:@"favoriteCat" withObjectForPrimaryKeyAttribute:@"favoriteCatID"];

    // Create a cat to connect
    RKCat *cat = [RKCat object];
    cat.name = @"Asia";
    cat.railsID = [NSNumber numberWithInt:31337];
    [objectStore save:nil];

    NSDictionary *mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Blake", @"favoriteCatID", [NSNumber numberWithInt:31337], nil];
    RKHuman *human = [RKHuman object];
    RKManagedObjectMappingOperation *operation = [[RKManagedObjectMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(human.favoriteCat, isNot(nilValue()));
    assertThat(human.favoriteCat.name, is(equalTo(@"Asia")));
}

- (void)testConnectRelationshipsDoesNotLeakMemory
{
    RKManagedObjectStore *objectStore = [RKTestFactory managedObjectStore];

    RKManagedObjectMapping *catMapping = [RKManagedObjectMapping mappingForClass:[RKCat class] inManagedObjectStore:objectStore];
    catMapping.primaryKeyAttribute = @"railsID";
    [catMapping mapAttributes:@"name", nil];

    RKManagedObjectMapping *humanMapping = [RKManagedObjectMapping mappingForClass:[RKHuman class] inManagedObjectStore:objectStore];
    humanMapping.primaryKeyAttribute = @"railsID";
    [humanMapping mapAttributes:@"name", @"favoriteCatID", nil];
    [humanMapping hasOne:@"favoriteCat" withMapping:catMapping];
    [humanMapping connectRelationship:@"favoriteCat" withObjectForPrimaryKeyAttribute:@"favoriteCatID"];

    // Create a cat to connect
    RKCat *cat = [RKCat object];
    cat.name = @"Asia";
    cat.railsID = [NSNumber numberWithInt:31337];
    [objectStore save:nil];

    NSDictionary *mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Blake", @"favoriteCatID", [NSNumber numberWithInt:31337], nil];
    RKHuman *human = [RKHuman object];
    RKManagedObjectMappingOperation *operation = [[RKManagedObjectMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    operation.queue = [RKMappingOperationQueue new];
    NSError *error = nil;
    [operation performMapping:&error];

    assertThatInteger([operation retainCount], is(equalToInteger(1)));
}

- (void)testConnectionOfHasManyRelationshipsByPrimaryKey
{
    RKManagedObjectStore *objectStore = [RKTestFactory managedObjectStore];

    RKManagedObjectMapping *catMapping = [RKManagedObjectMapping mappingForClass:[RKCat class] inManagedObjectStore:objectStore];
    catMapping.primaryKeyAttribute = @"railsID";
    [catMapping mapAttributes:@"name", nil];

    RKManagedObjectMapping *humanMapping = [RKManagedObjectMapping mappingForClass:[RKHuman class] inManagedObjectStore:objectStore];
    humanMapping.primaryKeyAttribute = @"railsID";
    [humanMapping mapAttributes:@"name", @"favoriteCatID", nil];
    [humanMapping hasOne:@"favoriteCat" withMapping:catMapping];
    [humanMapping connectRelationship:@"favoriteCat" withObjectForPrimaryKeyAttribute:@"favoriteCatID"];

    // Create a cat to connect
    RKCat *cat = [RKCat object];
    cat.name = @"Asia";
    cat.railsID = [NSNumber numberWithInt:31337];
    [objectStore save:nil];

    NSDictionary *mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Blake", @"favoriteCatID", [NSNumber numberWithInt:31337], nil];
    RKHuman *human = [RKHuman object];
    RKManagedObjectMappingOperation *operation = [[RKManagedObjectMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(human.favoriteCat, isNot(nilValue()));
    assertThat(human.favoriteCat.name, is(equalTo(@"Asia")));
}

- (void)testShouldConnectRelationshipsByPrimaryKeyWithDifferentSourceAndDestinationKeyPaths
{
    RKManagedObjectStore *objectStore = [RKTestFactory managedObjectStore];

    RKManagedObjectMapping *catMapping = [RKManagedObjectMapping mappingForClass:[RKCat class] inManagedObjectStore:objectStore];
    catMapping.primaryKeyAttribute = @"railsID";
    [catMapping mapAttributes:@"name", nil];

    RKManagedObjectMapping *humanMapping = [RKManagedObjectMapping mappingForClass:[RKHuman class] inManagedObjectStore:objectStore];
    humanMapping.primaryKeyAttribute = @"railsID";
    [humanMapping mapAttributes:@"name", @"favoriteCatID", @"catIDs", nil];
    [humanMapping mapRelationship:@"cats" withMapping:catMapping];
    [humanMapping connectRelationship:@"cats" withObjectForPrimaryKeyAttribute:@"catIDs"];

    // Create a couple of cats to connect
    RKCat *asia = [RKCat object];
    asia.name = @"Asia";
    asia.railsID = [NSNumber numberWithInt:31337];

    RKCat *roy = [RKCat object];
    roy.name = @"Reginald Royford Williams III";
    roy.railsID = [NSNumber numberWithInt:31338];

    [objectStore save:nil];

    NSArray *catIDs = [NSArray arrayWithObjects:[NSNumber numberWithInt:31337], [NSNumber numberWithInt:31338], nil];
    NSDictionary *mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Blake", @"catIDs", catIDs, nil];
    RKHuman *human = [RKHuman object];

    RKManagedObjectMappingOperation *operation = [[RKManagedObjectMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(human.cats, isNot(nilValue()));
    assertThat([human.cats valueForKeyPath:@"name"], containsInAnyOrder(@"Asia", @"Reginald Royford Williams III", nil));
}

- (void)testShouldLoadNestedHasManyRelationship
{
    RKManagedObjectStore *objectStore = [RKTestFactory managedObjectStore];
    RKManagedObjectMapping *catMapping = [RKManagedObjectMapping mappingForClass:[RKCat class] inManagedObjectStore:objectStore];
    catMapping.primaryKeyAttribute = @"railsID";
    [catMapping mapAttributes:@"name", nil];

    RKManagedObjectMapping *humanMapping = [RKManagedObjectMapping mappingForClass:[RKHuman class] inManagedObjectStore:objectStore];
    humanMapping.primaryKeyAttribute = @"railsID";
    [humanMapping mapAttributes:@"name", @"favoriteCatID", nil];
    [humanMapping hasMany:@"cats" withMapping:catMapping];

    NSArray *catsData = [NSArray arrayWithObject:[NSDictionary dictionaryWithObject:@"Asia" forKey:@"name"]];
    NSDictionary *mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Blake", @"favoriteCatID", [NSNumber numberWithInt:31337], @"cats", catsData, nil];
    RKHuman *human = [RKHuman object];
    RKManagedObjectMappingOperation *operation = [[RKManagedObjectMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
}

- (void)testShouldLoadOrderedHasManyRelationship
{
    RKManagedObjectStore *objectStore = [RKTestFactory managedObjectStore];
    RKManagedObjectMapping *catMapping = [RKManagedObjectMapping mappingForClass:[RKCat class] inManagedObjectStore:objectStore];
    catMapping.primaryKeyAttribute = @"railsID";
    [catMapping mapAttributes:@"name", nil];

    RKManagedObjectMapping *humanMapping = [RKManagedObjectMapping mappingForClass:[RKHuman class] inManagedObjectStore:objectStore];
    humanMapping.primaryKeyAttribute = @"railsID";
    [humanMapping mapAttributes:@"name", @"favoriteCatID", nil];
    [humanMapping mapKeyPath:@"cats" toRelationship:@"catsInOrderByAge" withMapping:catMapping];

    NSArray *catsData = [NSArray arrayWithObject:[NSDictionary dictionaryWithObject:@"Asia" forKey:@"name"]];
    NSDictionary *mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Blake", @"favoriteCatID", [NSNumber numberWithInt:31337], @"cats", catsData, nil];
    RKHuman *human = [RKHuman object];
    RKManagedObjectMappingOperation *operation = [[RKManagedObjectMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat([human catsInOrderByAge], isNot(empty()));
}

- (void)testShouldMapNullToAHasManyRelationship
{
    RKManagedObjectStore *objectStore = [RKTestFactory managedObjectStore];
    RKManagedObjectMapping *catMapping = [RKManagedObjectMapping mappingForClass:[RKCat class] inManagedObjectStore:objectStore];
    [catMapping mapAttributes:@"name", nil];

    RKManagedObjectMapping *humanMapping = [RKManagedObjectMapping mappingForClass:[RKHuman class] inManagedObjectStore:objectStore];
    [humanMapping mapAttributes:@"name", @"favoriteCatID", nil];
    [humanMapping hasMany:@"cats" withMapping:catMapping];

    NSDictionary *mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Blake", @"cats", [NSNull null], nil];
    RKHuman *human = [RKHuman object];
    RKManagedObjectMappingOperation *operation = [[RKManagedObjectMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(human.cats, is(empty()));
}

- (void)testShouldLoadNestedHasManyRelationshipWithoutABackingClass
{
    RKManagedObjectStore *objectStore = [RKTestFactory managedObjectStore];
    RKManagedObjectMapping *cloudMapping = [RKManagedObjectMapping mappingForEntityWithName:@"RKCloud" inManagedObjectStore:objectStore];
    [cloudMapping mapAttributes:@"name", nil];

    RKManagedObjectMapping *stormMapping = [RKManagedObjectMapping mappingForEntityWithName:@"RKStorm" inManagedObjectStore:objectStore];
    [stormMapping mapAttributes:@"name", @"favoriteCatID", nil];
    [stormMapping hasMany:@"clouds" withMapping:cloudMapping];

    NSArray *cloudsData = [NSArray arrayWithObject:[NSDictionary dictionaryWithObject:@"Nimbus" forKey:@"name"]];
    NSDictionary *mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Hurricane", @"clouds", cloudsData, nil];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RKStorm" inManagedObjectContext:objectStore.primaryManagedObjectContext];
    NSManagedObject *storm = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:objectStore.primaryManagedObjectContext];
    RKManagedObjectMappingOperation *operation = [[RKManagedObjectMappingOperation alloc] initWithSourceObject:mappableData destinationObject:storm mapping:stormMapping];
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
}

- (void)testShouldDynamicallyConnectRelationshipsByPrimaryKeyWhenMatchingSucceeds
{
    RKManagedObjectStore *objectStore = [RKTestFactory managedObjectStore];

    RKManagedObjectMapping *catMapping = [RKManagedObjectMapping mappingForClass:[RKCat class] inManagedObjectStore:objectStore];
    catMapping.primaryKeyAttribute = @"railsID";
    [catMapping mapAttributes:@"name", nil];

    RKManagedObjectMapping *humanMapping = [RKManagedObjectMapping mappingForClass:[RKHuman class] inManagedObjectStore:objectStore];
    humanMapping.primaryKeyAttribute = @"railsID";
    [humanMapping mapAttributes:@"name", @"favoriteCatID", nil];
    [humanMapping hasOne:@"favoriteCat" withMapping:catMapping];
    [humanMapping connectRelationship:@"favoriteCat" withObjectForPrimaryKeyAttribute:@"favoriteCatID" whenValueOfKeyPath:@"name" isEqualTo:@"Blake"];

    // Create a cat to connect
    RKCat *cat = [RKCat object];
    cat.name = @"Asia";
    cat.railsID = [NSNumber numberWithInt:31337];
    [objectStore save:nil];

    NSDictionary *mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Blake", @"favoriteCatID", [NSNumber numberWithInt:31337], nil];
    RKHuman *human = [RKHuman object];
    RKManagedObjectMappingOperation *operation = [[RKManagedObjectMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(human.favoriteCat, isNot(nilValue()));
    assertThat(human.favoriteCat.name, is(equalTo(@"Asia")));
}

- (void)testShouldNotDynamicallyConnectRelationshipsByPrimaryKeyWhenMatchingFails
{
    RKManagedObjectStore *objectStore = [RKTestFactory managedObjectStore];

    RKManagedObjectMapping *catMapping = [RKManagedObjectMapping mappingForClass:[RKCat class] inManagedObjectStore:objectStore];
    catMapping.primaryKeyAttribute = @"railsID";
    [catMapping mapAttributes:@"name", nil];

    RKManagedObjectMapping *humanMapping = [RKManagedObjectMapping mappingForClass:[RKHuman class] inManagedObjectStore:objectStore];
    humanMapping.primaryKeyAttribute = @"railsID";
    [humanMapping mapAttributes:@"name", @"favoriteCatID", nil];
    [humanMapping hasOne:@"favoriteCat" withMapping:catMapping];
    [humanMapping connectRelationship:@"favoriteCat" withObjectForPrimaryKeyAttribute:@"favoriteCatID" whenValueOfKeyPath:@"name" isEqualTo:@"Jeff"];

    // Create a cat to connect
    RKCat *cat = [RKCat object];
    cat.name = @"Asia";
    cat.railsID = [NSNumber numberWithInt:31337];
    [objectStore save:nil];

    NSDictionary *mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Blake", @"favoriteCatID", [NSNumber numberWithInt:31337], nil];
    RKHuman *human = [RKHuman object];
    RKManagedObjectMappingOperation *operation = [[RKManagedObjectMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(human.favoriteCat, is(nilValue()));
}

- (void)testShouldConnectManyToManyRelationships
{
    RKManagedObjectStore *store = [RKTestFactory managedObjectStore];
    RKManagedObjectMapping *childMapping = [RKManagedObjectMapping mappingForClass:[RKChild class] inManagedObjectStore:store];
    childMapping.primaryKeyAttribute = @"railsID";
    [childMapping mapAttributes:@"name", nil];

    RKManagedObjectMapping *parentMapping = [RKManagedObjectMapping mappingForClass:[RKParent class] inManagedObjectStore:store];
    parentMapping.primaryKeyAttribute = @"railsID";
    [parentMapping mapAttributes:@"name", @"age", nil];
    [parentMapping hasMany:@"children" withMapping:childMapping];

    NSArray *childMappableData = [NSArray arrayWithObjects:[NSDictionary dictionaryWithKeysAndObjects:@"name", @"Maya", nil],
                                  [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Brady", nil], nil];
    NSDictionary *parentMappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Win",
                                        @"age", [NSNumber numberWithInt:34],
                                        @"children", childMappableData, nil];
    RKParent *parent = [RKParent object];
    RKManagedObjectMappingOperation *operation = [[RKManagedObjectMappingOperation alloc] initWithSourceObject:parentMappableData destinationObject:parent mapping:parentMapping];
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(parent.children, isNot(nilValue()));
    assertThatUnsignedInteger([parent.children count], is(equalToInt(2)));
    assertThat([[parent.children anyObject] parents], isNot(nilValue()));
    assertThatBool([[[parent.children anyObject] parents] containsObject:parent], is(equalToBool(YES)));
    assertThatUnsignedInteger([[[parent.children anyObject] parents] count], is(equalToInt(1)));
}

- (void)testShouldConnectRelationshipsByPrimaryKeyRegardlessOfOrder
{
    RKManagedObjectStore *store = [RKTestFactory managedObjectStore];
    RKManagedObjectMapping *parentMapping = [RKManagedObjectMapping mappingForClass:[RKParent class] inManagedObjectStore:store];
    [parentMapping mapAttributes:@"parentID", nil];
    parentMapping.primaryKeyAttribute = @"parentID";

    RKManagedObjectMapping *childMapping = [RKManagedObjectMapping mappingForClass:[RKChild class] inManagedObjectStore:store];
    [childMapping mapAttributes:@"fatherID", nil];
    [childMapping mapRelationship:@"father" withMapping:parentMapping];
    [childMapping connectRelationship:@"father" withObjectForPrimaryKeyAttribute:@"fatherID"];

    RKObjectMappingProvider *mappingProvider = [RKObjectMappingProvider new];
    // NOTE: This may be fragile. Reverse order seems to trigger them to be mapped parent first. NSDictionary
    // keys are not guaranteed to return in any particular order
    [mappingProvider setMapping:parentMapping forKeyPath:@"parents"];
    [mappingProvider setMapping:childMapping  forKeyPath:@"children"];

    NSDictionary *JSON = [RKTestFixture parsedObjectWithContentsOfFixture:@"ConnectingParents.json"];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:JSON mappingProvider:mappingProvider];
    RKObjectMappingResult *result = [mapper performMapping];
    NSArray *children = [[result asDictionary] valueForKey:@"children"];
    assertThat(children, hasCountOf(1));
    RKChild *child = [children lastObject];
    assertThat(child.father, is(notNilValue()));
}

- (void)testMappingAPayloadContainingRepeatedObjectsDoesNotYieldDuplicatesWithFetchRequestMappingCache
{
    RKManagedObjectStore *store = [RKTestFactory managedObjectStore];
    store.cacheStrategy = [RKFetchRequestManagedObjectCache new];

    RKManagedObjectMapping *childMapping = [RKManagedObjectMapping mappingForClass:[RKChild class] inManagedObjectStore:store];
    childMapping.primaryKeyAttribute = @"childID";
    [childMapping mapAttributes:@"name", @"childID", nil];

    RKManagedObjectMapping *parentMapping = [RKManagedObjectMapping mappingForClass:[RKParent class] inManagedObjectStore:store];
    [parentMapping mapAttributes:@"parentID", @"name", nil];
    parentMapping.primaryKeyAttribute = @"parentID";
    [parentMapping mapRelationship:@"children" withMapping:childMapping];

    RKObjectMappingProvider *mappingProvider = [RKObjectMappingProvider new];
    // NOTE: This may be fragile. Reverse order seems to trigger them to be mapped parent first. NSDictionary
    // keys are not guaranteed to return in any particular order
    [mappingProvider setObjectMapping:parentMapping forKeyPath:@"parents"];

    NSDictionary *JSON = [RKTestFixture parsedObjectWithContentsOfFixture:@"parents_and_children.json"];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:JSON mappingProvider:mappingProvider];
    [mapper performMapping];

    NSUInteger parentCount = [RKParent count:nil];
    NSUInteger childrenCount = [RKChild count:nil];
    assertThatInteger(parentCount, is(equalToInteger(2)));
    assertThatInteger(childrenCount, is(equalToInteger(4)));
}

- (void)testMappingAPayloadContainingRepeatedObjectsDoesNotYieldDuplicatesWithInMemoryMappingCache
{
    RKManagedObjectStore *store = [RKTestFactory managedObjectStore];
    store.cacheStrategy = [RKInMemoryManagedObjectCache new];

    RKManagedObjectMapping *childMapping = [RKManagedObjectMapping mappingForClass:[RKChild class] inManagedObjectStore:store];
    childMapping.primaryKeyAttribute = @"childID";
    [childMapping mapAttributes:@"name", @"childID", nil];

    RKManagedObjectMapping *parentMapping = [RKManagedObjectMapping mappingForClass:[RKParent class] inManagedObjectStore:store];
    [parentMapping mapAttributes:@"parentID", @"name", nil];
    parentMapping.primaryKeyAttribute = @"parentID";
    [parentMapping mapRelationship:@"children" withMapping:childMapping];

    RKObjectMappingProvider *mappingProvider = [RKObjectMappingProvider new];
    // NOTE: This may be fragile. Reverse order seems to trigger them to be mapped parent first. NSDictionary
    // keys are not guaranteed to return in any particular order
    [mappingProvider setObjectMapping:parentMapping forKeyPath:@"parents"];

    NSDictionary *JSON = [RKTestFixture parsedObjectWithContentsOfFixture:@"parents_and_children.json"];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:JSON mappingProvider:mappingProvider];
    [mapper performMapping];

    NSUInteger parentCount = [RKParent count:nil];
    NSUInteger childrenCount = [RKChild count:nil];
    assertThatInteger(parentCount, is(equalToInteger(2)));
    assertThatInteger(childrenCount, is(equalToInteger(4)));
}

- (void)testMappingAPayloadContainingRepeatedObjectsPerformsAcceptablyWithFetchRequestMappingCache
{
    RKManagedObjectStore *store = [RKTestFactory managedObjectStore];
    store.cacheStrategy = [RKFetchRequestManagedObjectCache new];

    RKManagedObjectMapping *childMapping = [RKManagedObjectMapping mappingForClass:[RKChild class] inManagedObjectStore:store];
    childMapping.primaryKeyAttribute = @"childID";
    [childMapping mapAttributes:@"name", @"childID", nil];

    RKManagedObjectMapping *parentMapping = [RKManagedObjectMapping mappingForClass:[RKParent class] inManagedObjectStore:store];
    [parentMapping mapAttributes:@"parentID", @"name", nil];
    parentMapping.primaryKeyAttribute = @"parentID";
    [parentMapping mapRelationship:@"children" withMapping:childMapping];

    RKObjectMappingProvider *mappingProvider = [RKObjectMappingProvider new];
    // NOTE: This may be fragile. Reverse order seems to trigger them to be mapped parent first. NSDictionary
    // keys are not guaranteed to return in any particular order
    [mappingProvider setObjectMapping:parentMapping forKeyPath:@"parents"];

    NSDictionary *JSON = [RKTestFixture parsedObjectWithContentsOfFixture:@"benchmark_parents_and_children.json"];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:JSON mappingProvider:mappingProvider];

    RKLogConfigureByName("RestKit/ObjectMapping", RKLogLevelOff);
    RKLogConfigureByName("RestKit/CoreData", RKLogLevelOff);

    [RKBenchmark report:@"Mapping with Fetch Request Cache" executionBlock:^{
        for (NSUInteger i = 0; i < 50; i++) {
            [mapper performMapping];
        }
    }];
    NSUInteger parentCount = [RKParent count:nil];
    NSUInteger childrenCount = [RKChild count:nil];
    assertThatInteger(parentCount, is(equalToInteger(25)));
    assertThatInteger(childrenCount, is(equalToInteger(51)));
}

- (void)testMappingAPayloadContainingRepeatedObjectsPerformsAcceptablyWithInMemoryMappingCache
{
    RKManagedObjectStore *store = [RKTestFactory managedObjectStore];
    store.cacheStrategy = [RKInMemoryManagedObjectCache new];

    RKManagedObjectMapping *childMapping = [RKManagedObjectMapping mappingForClass:[RKChild class] inManagedObjectStore:store];
    childMapping.primaryKeyAttribute = @"childID";
    [childMapping mapAttributes:@"name", @"childID", nil];

    RKManagedObjectMapping *parentMapping = [RKManagedObjectMapping mappingForClass:[RKParent class] inManagedObjectStore:store];
    [parentMapping mapAttributes:@"parentID", @"name", nil];
    parentMapping.primaryKeyAttribute = @"parentID";
    [parentMapping mapRelationship:@"children" withMapping:childMapping];

    RKObjectMappingProvider *mappingProvider = [RKObjectMappingProvider new];
    // NOTE: This may be fragile. Reverse order seems to trigger them to be mapped parent first. NSDictionary
    // keys are not guaranteed to return in any particular order
    [mappingProvider setObjectMapping:parentMapping forKeyPath:@"parents"];

    NSDictionary *JSON = [RKTestFixture parsedObjectWithContentsOfFixture:@"benchmark_parents_and_children.json"];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:JSON mappingProvider:mappingProvider];

    RKLogConfigureByName("RestKit/ObjectMapping", RKLogLevelOff);
    RKLogConfigureByName("RestKit/CoreData", RKLogLevelOff);

    [RKBenchmark report:@"Mapping with In Memory Cache" executionBlock:^{
        for (NSUInteger i = 0; i < 50; i++) {
            [mapper performMapping];
        }
    }];
    NSUInteger parentCount = [RKParent count:nil];
    NSUInteger childrenCount = [RKChild count:nil];
    assertThatInteger(parentCount, is(equalToInteger(25)));
    assertThatInteger(childrenCount, is(equalToInteger(51)));
}

@end
