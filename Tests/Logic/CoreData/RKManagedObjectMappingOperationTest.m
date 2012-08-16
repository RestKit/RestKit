//
//  RKObjectMappingOperationTest.m
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
#import "RKEntityMapping.h"
#import "RKManagedObjectMappingOperationDataSource.h"
#import "RKCat.h"
#import "RKHuman.h"
#import "RKChild.h"
#import "RKParent.h"
#import "RKBenchmark.h"

@interface RKManagedObjectMappingOperationTest : RKTestCase
@end

@implementation RKManagedObjectMappingOperationTest

- (void)setUp
{
    [RKTestFactory setUp];
}

- (void)tearDown
{
    [RKTestFactory tearDown];
}

- (void)testMappingInPrivateQueue
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSManagedObjectContext *managedObjectContext = [[[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType] autorelease];
    managedObjectContext.parentContext = managedObjectStore.primaryManagedObjectContext;
    managedObjectContext.mergePolicy  = NSMergeByPropertyStoreTrumpMergePolicy;
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    
    __block BOOL success;
    __block NSError *error;
    NSDictionary *sourceObject = @{ @"name" : @"Blake Watters" };
    [managedObjectContext performBlockAndWait:^{
        RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:managedObjectStore];
        humanMapping.primaryKeyAttribute = @"railsID";
        [humanMapping mapAttributes:@"name", @"favoriteCatID", nil];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"RKHuman" inManagedObjectContext:managedObjectContext];
        RKHuman *human = [[RKHuman alloc] initWithEntity:entity insertIntoManagedObjectContext:managedObjectContext];
        RKMappingOperation *mappingOperation = [RKMappingOperation mappingOperationFromObject:sourceObject toObject:human withMapping:humanMapping];
        mappingOperation.dataSource = mappingOperationDataSource;
        success = [mappingOperation performMapping:&error];
        
        assertThatBool(success, is(equalToBool(YES)));
        assertThat(human.name, is(equalTo(@"Blake Watters")));
    }];
}

- (void)testShouldConnectRelationshipsByPrimaryKey
{
    /* Connect a new human to a cat */
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];

    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"RKCat" inManagedObjectStore:managedObjectStore];
    catMapping.primaryKeyAttribute = @"railsID";
    [catMapping mapAttributes:@"name", nil];

    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:managedObjectStore];
    humanMapping.primaryKeyAttribute = @"railsID";
    [humanMapping mapAttributes:@"name", @"favoriteCatID", nil];
    [humanMapping connectRelationship:@"favoriteCat" fromKeyPath:@"favoriteCatID" toKeyPath:@"railsID" withMapping:catMapping];

    // Create a cat to connect
    RKCat *cat = [NSEntityDescription insertNewObjectForEntityForName:@"RKCat" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    cat.name = @"Asia";
    cat.railsID = [NSNumber numberWithInt:31337];
    [managedObjectStore.primaryManagedObjectContext save:nil];

    NSDictionary *mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Blake", @"favoriteCatID", [NSNumber numberWithInt:31337], nil];
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    operation.dataSource = mappingOperationDataSource;
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(human.favoriteCat, isNot(nilValue()));
    assertThat(human.favoriteCat.name, is(equalTo(@"Asia")));
}

- (void)testShouldConnectRelationshipsByPrimaryKeyReverse
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSManagedObjectContext *managedObjectContext = managedObjectStore.primaryManagedObjectContext;
    
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:managedObjectStore];
    humanMapping.primaryKeyAttribute = @"railsID";
    [humanMapping mapAttributes:@"name", @"favoriteCatID", nil];

    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"RKCat" inManagedObjectStore:managedObjectStore];
    catMapping.primaryKeyAttribute = @"railsID";
    [catMapping mapAttributes:@"name", @"railsID", nil];
    [catMapping connectRelationship:@"favoriteOfHumans" fromKeyPath:@"railsID" toKeyPath:@"favoriteCatID" withMapping:humanMapping];

    // Create some humans to connect
    RKHuman *blake = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    blake.name = @"Blake";
    blake.favoriteCatID = [NSNumber numberWithInt:31340];

    RKHuman *jeremy = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    jeremy.name = @"Jeremy";
    jeremy.favoriteCatID = [NSNumber numberWithInt:31340];

    [managedObjectStore.primaryManagedObjectContext save:nil];

    NSDictionary *mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Asia", @"railsID", [NSNumber numberWithInt:31340], nil];
    RKCat *cat = [NSEntityDescription insertNewObjectForEntityForName:@"RKCat" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    NSOperationQueue *operationQueue = [NSOperationQueue new];
    [operationQueue setSuspended:YES];
    mappingOperationDataSource.operationQueue = operationQueue;
    __block BOOL success;
    [managedObjectContext performBlockAndWait:^{
        RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:mappableData destinationObject:cat mapping:catMapping];
        operation.dataSource = mappingOperationDataSource;
        NSError *error = nil;
        success = [operation performMapping:&error];
    }];
    
    [operationQueue setSuspended:NO];
    [operationQueue waitUntilAllOperationsAreFinished];
    
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(cat.favoriteOfHumans, isNot(nilValue()));
    assertThat([cat.favoriteOfHumans valueForKeyPath:@"name"], containsInAnyOrder(blake.name, jeremy.name, nil));
}

- (void)testConnectRelationshipsDoesNotLeakMemory
{
    RKManagedObjectStore* managedObjectStore = [RKTestFactory managedObjectStore];

    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"RKCat" inManagedObjectStore:managedObjectStore];
    catMapping.primaryKeyAttribute = @"railsID";
    [catMapping mapAttributes:@"name", nil];

    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:managedObjectStore];
    humanMapping.primaryKeyAttribute = @"railsID";
    [humanMapping mapAttributes:@"name", @"favoriteCatID", nil];
    [humanMapping connectRelationship:@"favoriteCat" fromKeyPath:@"favoriteCatID" toKeyPath:@"railsID" withMapping:catMapping];

    // Create a cat to connect
    RKCat *cat = [NSEntityDescription insertNewObjectForEntityForName:@"RKCat" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    cat.name = @"Asia";
    cat.railsID = [NSNumber numberWithInt:31337];
    [managedObjectStore.primaryManagedObjectContext save:nil];

    NSDictionary *mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Blake", @"favoriteCatID", [NSNumber numberWithInt:31337], nil];
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    mappingOperationDataSource.operationQueue = [[NSOperationQueue new] autorelease];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    operation.dataSource = mappingOperationDataSource;
    NSError *error = nil;
    [operation performMapping:&error];

    assertThatInteger([operation retainCount], is(equalToInteger(1)));
}

- (void)testConnectionOfHasManyRelationshipsByPrimaryKey
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];

    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"RKCat" inManagedObjectStore:managedObjectStore];
    catMapping.primaryKeyAttribute = @"railsID";
    [catMapping mapAttributes:@"name", nil];

    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:managedObjectStore];
    humanMapping.primaryKeyAttribute = @"railsID";
    [humanMapping mapAttributes:@"name", @"favoriteCatID", nil];
    [humanMapping connectRelationship:@"favoriteCat" fromKeyPath:@"favoriteCatID" toKeyPath:@"railsID" withMapping:catMapping];

    // Create a cat to connect
    RKCat *cat = [NSEntityDescription insertNewObjectForEntityForName:@"RKCat" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    cat.name = @"Asia";
    cat.railsID = [NSNumber numberWithInt:31337];
    [managedObjectStore.primaryManagedObjectContext save:nil];

    NSDictionary *mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Blake", @"favoriteCatID", [NSNumber numberWithInt:31337], nil];
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    operation.dataSource = mappingOperationDataSource;
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(human.favoriteCat, isNot(nilValue()));
    assertThat(human.favoriteCat.name, is(equalTo(@"Asia")));
}

- (void)testShouldConnectRelationshipsByPrimaryKeyWithDifferentSourceAndDestinationKeyPaths
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];

    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"RKCat" inManagedObjectStore:managedObjectStore];
    catMapping.primaryKeyAttribute = @"railsID";
    [catMapping mapAttributes:@"name", nil];

    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:managedObjectStore];
    humanMapping.primaryKeyAttribute = @"railsID";
    [humanMapping mapAttributes:@"name", @"catIDs", nil];
    [humanMapping connectRelationship:@"cats" fromKeyPath:@"catIDs" toKeyPath:@"railsID" withMapping:catMapping];

    // Create a couple of cats to connect
    RKCat *asia = [NSEntityDescription insertNewObjectForEntityForName:@"RKCat" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    asia.name = @"Asia";
    asia.railsID = [NSNumber numberWithInt:31337];

    RKCat *roy = [NSEntityDescription insertNewObjectForEntityForName:@"RKCat" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    roy.name = @"Reginald Royford Williams III";
    roy.railsID = [NSNumber numberWithInt:31338];

    [managedObjectStore.primaryManagedObjectContext save:nil];

    NSArray *catIDs = [NSArray arrayWithObjects:[NSNumber numberWithInt:31337], [NSNumber numberWithInt:31338], nil];
    NSDictionary *mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Blake", @"catIDs", catIDs, nil];
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];

    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    operation.dataSource = mappingOperationDataSource;
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(human.cats, isNot(nilValue()));
    assertThat([human.cats valueForKeyPath:@"name"], containsInAnyOrder(@"Asia", @"Reginald Royford Williams III", nil));
}

- (void)testShouldConnectRelationshipsByPrimaryKeyWithDifferentSourceAndDestinationKeyPathsReverse
{
    /* Connect a new cat to a human */
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];

    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:managedObjectStore];
    humanMapping.primaryKeyAttribute = @"railsID";
    [humanMapping mapAttributes:@"name", @"railsID", nil];

    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"RKCat" inManagedObjectStore:managedObjectStore];
    catMapping.primaryKeyAttribute = @"railsID";
    [catMapping mapAttributes:@"name", @"humanId", nil];
    [catMapping connectRelationship:@"human" fromKeyPath:@"humanId" toKeyPath:@"railsID" withMapping:humanMapping];

    // Create a human to connect
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    human.name = @"Blake";
    human.railsID = [NSNumber numberWithInt:31337];
    [managedObjectStore.primaryManagedObjectContext save:nil];

    NSDictionary *mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Asia", @"humanId", [NSNumber numberWithInt:31337], nil];
    RKCat *cat = [NSEntityDescription insertNewObjectForEntityForName:@"RKCat" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    RKMappingOperation* operation = [[RKMappingOperation alloc] initWithSourceObject:mappableData destinationObject:cat mapping:catMapping];
    operation.dataSource = mappingOperationDataSource;
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(cat.human, isNot(nilValue()));
    assertThat(cat.human.name, is(equalTo(@"Blake")));
}

- (void)testShouldLoadNestedHasManyRelationship
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"RKCat" inManagedObjectStore:managedObjectStore];
    catMapping.primaryKeyAttribute = @"railsID";
    [catMapping mapAttributes:@"name", nil];

    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:managedObjectStore];
    humanMapping.primaryKeyAttribute = @"railsID";
    [humanMapping mapAttributes:@"name", @"favoriteCatID", nil];
    [humanMapping hasMany:@"cats" withMapping:catMapping];

    NSArray *catsData = [NSArray arrayWithObject:[NSDictionary dictionaryWithObject:@"Asia" forKey:@"name"]];
    NSDictionary *mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Blake", @"favoriteCatID", [NSNumber numberWithInt:31337], @"cats", catsData, nil];
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    operation.dataSource = mappingOperationDataSource;
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
}

- (void)testShouldLoadOrderedHasManyRelationship
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"RKCat" inManagedObjectStore:managedObjectStore];
    catMapping.primaryKeyAttribute = @"railsID";
    [catMapping mapAttributes:@"name", nil];

    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:managedObjectStore];
    humanMapping.primaryKeyAttribute = @"railsID";
    [humanMapping mapAttributes:@"name", @"favoriteCatID", nil];
    [humanMapping mapKeyPath:@"cats" toRelationship:@"catsInOrderByAge" withMapping:catMapping];

    NSArray *catsData = [NSArray arrayWithObject:[NSDictionary dictionaryWithObject:@"Asia" forKey:@"name"]];
    NSDictionary *mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Blake", @"favoriteCatID", [NSNumber numberWithInt:31337], @"cats", catsData, nil];
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    operation.dataSource = mappingOperationDataSource;
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat([human catsInOrderByAge], isNot(empty()));
}

- (void)testShouldMapNullToAHasManyRelationship
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"RKCat" inManagedObjectStore:managedObjectStore];
    [catMapping mapAttributes:@"name", nil];

    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:managedObjectStore];
    [humanMapping mapAttributes:@"name", @"favoriteCatID", nil];
    [humanMapping hasMany:@"cats" withMapping:catMapping];

    NSDictionary *mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Blake", @"cats", [NSNull null], nil];
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    operation.dataSource = mappingOperationDataSource;
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(human.cats, is(empty()));
}

- (void)testShouldLoadNestedHasManyRelationshipWithoutABackingClass
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *cloudMapping = [RKEntityMapping mappingForEntityForName:@"RKCloud" inManagedObjectStore:managedObjectStore];
    [cloudMapping mapAttributes:@"name", nil];

    RKEntityMapping *stormMapping = [RKEntityMapping mappingForEntityForName:@"RKStorm" inManagedObjectStore:managedObjectStore];
    [stormMapping mapAttributes:@"name", @"favoriteCatID", nil];
    [stormMapping hasMany:@"clouds" withMapping:cloudMapping];

    NSArray *cloudsData = [NSArray arrayWithObject:[NSDictionary dictionaryWithObject:@"Nimbus" forKey:@"name"]];
    NSDictionary *mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Hurricane", @"clouds", cloudsData, nil];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RKStorm" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    NSManagedObject *storm = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:mappableData destinationObject:storm mapping:stormMapping];
    operation.dataSource = mappingOperationDataSource;
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
}

- (void)testShouldDynamicallyConnectRelationshipsByPrimaryKeyWhenMatchingSucceeds
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];

    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"RKCat" inManagedObjectStore:managedObjectStore];
    catMapping.primaryKeyAttribute = @"railsID";
    [catMapping mapAttributes:@"name", nil];

    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:managedObjectStore];
    humanMapping.primaryKeyAttribute = @"railsID";
    [humanMapping mapAttributes:@"name", @"favoriteCatID", nil];
    [humanMapping connectRelationship:@"favoriteCat" fromKeyPath:@"favoriteCatID" toKeyPath:@"railsID" withMapping:catMapping whenValueOfKeyPath:@"name" isEqualTo:@"Blake"];

    // Create a cat to connect
    RKCat *cat = [NSEntityDescription insertNewObjectForEntityForName:@"RKCat" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    cat.name = @"Asia";
    cat.railsID = [NSNumber numberWithInt:31337];
    [managedObjectStore.primaryManagedObjectContext save:nil];

    NSDictionary *mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Blake", @"favoriteCatID", [NSNumber numberWithInt:31337], nil];
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    operation.dataSource = mappingOperationDataSource;
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(human.favoriteCat, isNot(nilValue()));
    assertThat(human.favoriteCat.name, is(equalTo(@"Asia")));
}

- (void)testShouldNotDynamicallyConnectRelationshipsByPrimaryKeyWhenMatchingFails
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];

    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"RKCat" inManagedObjectStore:managedObjectStore];
    catMapping.primaryKeyAttribute = @"railsID";
    [catMapping mapAttributes:@"name", nil];

    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:managedObjectStore];
    humanMapping.primaryKeyAttribute = @"railsID";
    [humanMapping mapAttributes:@"name", @"favoriteCatID", nil];
    [humanMapping connectRelationship:@"favoriteCat" fromKeyPath:@"favoriteCatID" toKeyPath:@"railsID" withMapping:catMapping whenValueOfKeyPath:@"name" isEqualTo:@"Jeff"];

    // Create a cat to connect
    RKCat *cat = [NSEntityDescription insertNewObjectForEntityForName:@"RKCat" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    cat.name = @"Asia";
    cat.railsID = [NSNumber numberWithInt:31337];
    [managedObjectStore.primaryManagedObjectContext save:nil];

    NSDictionary *mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Blake", @"favoriteCatID", [NSNumber numberWithInt:31337], nil];
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    operation.dataSource = mappingOperationDataSource;
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(human.favoriteCat, is(nilValue()));
}

- (void)testShouldConnectManyToManyRelationships
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *childMapping = [RKEntityMapping mappingForEntityForName:@"RKChild" inManagedObjectStore:managedObjectStore];
    childMapping.primaryKeyAttribute = @"railsID";
    [childMapping mapAttributes:@"name", nil];

    RKEntityMapping *parentMapping = [RKEntityMapping mappingForEntityForName:@"RKParent" inManagedObjectStore:managedObjectStore];
    parentMapping.primaryKeyAttribute = @"railsID";
    [parentMapping mapAttributes:@"name", @"age", nil];
    [parentMapping hasMany:@"children" withMapping:childMapping];

    NSArray *childMappableData = [NSArray arrayWithObjects:[NSDictionary dictionaryWithKeysAndObjects:@"name", @"Maya", nil],
                                  [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Brady", nil], nil];
    NSDictionary *parentMappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Win",
                                        @"age", [NSNumber numberWithInt:34],
                                        @"children", childMappableData, nil];
    RKParent *parent = [NSEntityDescription insertNewObjectForEntityForName:@"RKParent" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:parentMappableData destinationObject:parent mapping:parentMapping];
    operation.dataSource = mappingOperationDataSource;
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
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSManagedObjectContext *managedObjectContext = managedObjectStore.primaryManagedObjectContext;
    
    RKEntityMapping *parentMapping = [RKEntityMapping mappingForEntityForName:@"RKParent" inManagedObjectStore:managedObjectStore];
    [parentMapping mapAttributes:@"parentID", nil];
    parentMapping.primaryKeyAttribute = @"parentID";

    RKEntityMapping *childMapping = [RKEntityMapping mappingForEntityForName:@"RKChild" inManagedObjectStore:managedObjectStore];
    [childMapping mapAttributes:@"fatherID", nil];
    [childMapping connectRelationship:@"father" fromKeyPath:@"fatherID" toKeyPath:@"parentID" withMapping:parentMapping];

    RKObjectMappingProvider *mappingProvider = [RKObjectMappingProvider new];
    // NOTE: This may be fragile. Reverse order seems to trigger them to be mapped parent first. NSDictionary
    // keys are not guaranteed to return in any particular order
    [mappingProvider setMapping:parentMapping forKeyPath:@"parents"];
    [mappingProvider setMapping:childMapping  forKeyPath:@"children"];

    NSDictionary *JSON = [RKTestFixture parsedObjectWithContentsOfFixture:@"ConnectingParents.json"];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    NSOperationQueue *operationQueue = [NSOperationQueue new];
    [operationQueue setSuspended:YES];
    mappingOperationDataSource.operationQueue = operationQueue;
    [managedObjectContext performBlockAndWait:^{
        RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:JSON mappingProvider:mappingProvider];
        mapper.mappingOperationDataSource = mappingOperationDataSource;
        [mapper performMapping];
    }];

    [operationQueue setSuspended:NO];
    [operationQueue waitUntilAllOperationsAreFinished];
    
    [managedObjectContext performBlockAndWait:^{
        NSError *error;
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"RKParent"];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"parentID = %@", @1];
        fetchRequest.fetchLimit = 1;
        NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
        RKParent *parent = [results lastObject];
        assertThat(parent, is(notNilValue()));
        NSSet *children = [parent fatheredChildren];
        assertThat(children, hasCountOf(1));
        RKChild *child = [children anyObject];
        assertThat(child.father, is(notNilValue()));
    }];
}

- (void)testMappingAPayloadContainingRepeatedObjectsDoesNotYieldDuplicatesWithFetchRequestMappingCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    managedObjectStore.managedObjectCache = managedObjectCache;

    RKEntityMapping *childMapping = [RKEntityMapping mappingForEntityForName:@"RKChild" inManagedObjectStore:managedObjectStore];
    childMapping.primaryKeyAttribute = @"childID";
    [childMapping mapAttributes:@"name", @"childID", nil];

    RKEntityMapping *parentMapping = [RKEntityMapping mappingForEntityForName:@"RKParent" inManagedObjectStore:managedObjectStore];
    [parentMapping mapAttributes:@"parentID", @"name", nil];
    parentMapping.primaryKeyAttribute = @"parentID";
    [parentMapping mapRelationship:@"children" withMapping:childMapping];

    RKObjectMappingProvider *mappingProvider = [RKObjectMappingProvider new];
    // NOTE: This may be fragile. Reverse order seems to trigger them to be mapped parent first. NSDictionary
    // keys are not guaranteed to return in any particular order
    [mappingProvider setObjectMapping:parentMapping forKeyPath:@"parents"];

    NSDictionary *JSON = [RKTestFixture parsedObjectWithContentsOfFixture:@"parents_and_children.json"];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:JSON mappingProvider:mappingProvider];
    mapper.mappingOperationDataSource = mappingOperationDataSource;
    [mapper performMapping];

    NSUInteger parentCount = [managedObjectStore.primaryManagedObjectContext countForEntityForName:@"RKParent" predicate:nil error:nil];
    NSUInteger childrenCount = [managedObjectStore.primaryManagedObjectContext countForEntityForName:@"RKChild" predicate:nil error:nil];
    assertThatInteger(parentCount, is(equalToInteger(2)));
    assertThatInteger(childrenCount, is(equalToInteger(4)));
}

- (void)testMappingAPayloadContainingRepeatedObjectsDoesNotYieldDuplicatesWithInMemoryMappingCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKInMemoryManagedObjectCache *managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    managedObjectStore.managedObjectCache = managedObjectCache;

    RKEntityMapping *childMapping = [RKEntityMapping mappingForEntityForName:@"RKChild" inManagedObjectStore:managedObjectStore];
    childMapping.primaryKeyAttribute = @"childID";
    [childMapping mapAttributes:@"name", @"childID", nil];

    RKEntityMapping *parentMapping = [RKEntityMapping mappingForEntityForName:@"RKParent" inManagedObjectStore:managedObjectStore];
    [parentMapping mapAttributes:@"parentID", @"name", nil];
    parentMapping.primaryKeyAttribute = @"parentID";
    [parentMapping mapRelationship:@"children" withMapping:childMapping];

    RKObjectMappingProvider *mappingProvider = [RKObjectMappingProvider new];
    // NOTE: This may be fragile. Reverse order seems to trigger them to be mapped parent first. NSDictionary
    // keys are not guaranteed to return in any particular order
    [mappingProvider setObjectMapping:parentMapping forKeyPath:@"parents"];

    NSDictionary *JSON = [RKTestFixture parsedObjectWithContentsOfFixture:@"parents_and_children.json"];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:JSON mappingProvider:mappingProvider];
    mapper.mappingOperationDataSource = mappingOperationDataSource;
    [mapper performMapping];
    
    NSError *error = nil;
    BOOL success = [managedObjectStore.primaryManagedObjectContext save:&error];
    assertThatBool(success, is(equalToBool(YES)));
    NSLog(@"Failed to save MOC: %@", error);
    assertThat(error, is(nilValue()));

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"RKParent"];
    NSUInteger parentCount = [managedObjectStore.primaryManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    NSUInteger childrenCount = [managedObjectStore.primaryManagedObjectContext countForEntityForName:@"RKChild" predicate:nil error:nil];
    assertThatInteger(parentCount, is(equalToInteger(2)));
    assertThatInteger(childrenCount, is(equalToInteger(4)));
}

- (void)testMappingAPayloadContainingRepeatedObjectsPerformsAcceptablyWithFetchRequestMappingCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    managedObjectStore.managedObjectCache = managedObjectCache;

    RKEntityMapping *childMapping = [RKEntityMapping mappingForEntityForName:@"RKChild" inManagedObjectStore:managedObjectStore];
    childMapping.primaryKeyAttribute = @"childID";
    [childMapping mapAttributes:@"name", @"childID", nil];

    RKEntityMapping *parentMapping = [RKEntityMapping mappingForEntityForName:@"RKParent" inManagedObjectStore:managedObjectStore];
    [parentMapping mapAttributes:@"parentID", @"name", nil];
    parentMapping.primaryKeyAttribute = @"parentID";
    [parentMapping mapRelationship:@"children" withMapping:childMapping];

    RKObjectMappingProvider *mappingProvider = [RKObjectMappingProvider new];
    // NOTE: This may be fragile. Reverse order seems to trigger them to be mapped parent first. NSDictionary
    // keys are not guaranteed to return in any particular order
    [mappingProvider setObjectMapping:parentMapping forKeyPath:@"parents"];

    NSDictionary *JSON = [RKTestFixture parsedObjectWithContentsOfFixture:@"benchmark_parents_and_children.json"];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:JSON mappingProvider:mappingProvider];
    mapper.mappingOperationDataSource = mappingOperationDataSource;
    
    RKLogConfigureByName("RestKit/ObjectMapping", RKLogLevelOff);
    RKLogConfigureByName("RestKit/CoreData", RKLogLevelOff);

    [RKBenchmark report:@"Mapping with Fetch Request Cache" executionBlock:^{
        for (NSUInteger i = 0; i < 50; i++) {
            [mapper performMapping];
        }
    }];
    NSUInteger parentCount = [managedObjectStore.primaryManagedObjectContext countForEntityForName:@"RKParent" predicate:nil error:nil];
    NSUInteger childrenCount = [managedObjectStore.primaryManagedObjectContext countForEntityForName:@"RKChild" predicate:nil error:nil];
    assertThatInteger(parentCount, is(equalToInteger(25)));
    assertThatInteger(childrenCount, is(equalToInteger(51)));
}

- (void)testMappingAPayloadContainingRepeatedObjectsPerformsAcceptablyWithInMemoryMappingCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKInMemoryManagedObjectCache *managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    managedObjectStore.managedObjectCache = managedObjectCache;

    RKEntityMapping *childMapping = [RKEntityMapping mappingForEntityForName:@"RKChild" inManagedObjectStore:managedObjectStore];
    childMapping.primaryKeyAttribute = @"childID";
    [childMapping mapAttributes:@"name", @"childID", nil];

    RKEntityMapping *parentMapping = [RKEntityMapping mappingForEntityForName:@"RKParent" inManagedObjectStore:managedObjectStore];
    [parentMapping mapAttributes:@"parentID", @"name", nil];
    parentMapping.primaryKeyAttribute = @"parentID";
    [parentMapping mapRelationship:@"children" withMapping:childMapping];

    RKObjectMappingProvider *mappingProvider = [RKObjectMappingProvider new];
    // NOTE: This may be fragile. Reverse order seems to trigger them to be mapped parent first. NSDictionary
    // keys are not guaranteed to return in any particular order
    [mappingProvider setObjectMapping:parentMapping forKeyPath:@"parents"];

    NSDictionary *JSON = [RKTestFixture parsedObjectWithContentsOfFixture:@"benchmark_parents_and_children.json"];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:JSON mappingProvider:mappingProvider];
    mapper.mappingOperationDataSource = mappingOperationDataSource;
    RKLogConfigureByName("RestKit/ObjectMapping", RKLogLevelOff);
    RKLogConfigureByName("RestKit/CoreData", RKLogLevelOff);

    [RKBenchmark report:@"Mapping with In Memory Cache" executionBlock:^{
        for (NSUInteger i = 0; i < 50; i++) {
            [mapper performMapping];
        }
    }];
    NSUInteger parentCount = [managedObjectStore.primaryManagedObjectContext countForEntityForName:@"RKParent" predicate:nil error:nil];
    NSUInteger childrenCount = [managedObjectStore.primaryManagedObjectContext countForEntityForName:@"RKChild" predicate:nil error:nil];
    assertThatInteger(parentCount, is(equalToInteger(25)));
    assertThatInteger(childrenCount, is(equalToInteger(51)));
}

/* Test deprecated connectionMapping API */
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
- (void)testShouldConnectRelationshipsByPrimaryKeyDeprecated {
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];

    RKEntityMapping* catMapping = [RKEntityMapping mappingForEntityForName:@"RKCat" inManagedObjectStore:managedObjectStore];
    catMapping.primaryKeyAttribute = @"railsID";
    [catMapping mapAttributes:@"name", nil];

    RKEntityMapping* humanMapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:managedObjectStore];
    humanMapping.primaryKeyAttribute = @"railsID";
    [humanMapping mapAttributes:@"name", @"favoriteCatID", nil];
    [humanMapping hasOne:@"favoriteCat" withMapping:catMapping];
    [humanMapping connectRelationship:@"favoriteCat" withObjectForPrimaryKeyAttribute:@"favoriteCatID"];

    // Create a cat to connect
    RKCat* cat = [NSEntityDescription insertNewObjectForEntityForName:@"RKCat" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    cat.name = @"Asia";
    cat.railsID = [NSNumber numberWithInt:31337];
    [managedObjectStore save:nil];

    NSDictionary* mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Blake", @"favoriteCatID", [NSNumber numberWithInt:31337], nil];
    RKHuman* human = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    RKMappingOperation* operation = [[RKMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    operation.dataSource = mappingOperationDataSource;
    NSError* error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(human.favoriteCat, isNot(nilValue()));
    assertThat(human.favoriteCat.name, is(equalTo(@"Asia")));
}

- (void)testConnectRelationshipsDoesNotLeakMemoryDeprecated {
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];

    RKEntityMapping* catMapping = [RKEntityMapping mappingForEntityForName:@"RKCat" inManagedObjectStore:managedObjectStore];
    catMapping.primaryKeyAttribute = @"railsID";
    [catMapping mapAttributes:@"name", nil];

    RKEntityMapping* humanMapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:managedObjectStore];
    humanMapping.primaryKeyAttribute = @"railsID";
    [humanMapping mapAttributes:@"name", @"favoriteCatID", nil];
    [humanMapping hasOne:@"favoriteCat" withMapping:catMapping];
    [humanMapping connectRelationship:@"favoriteCat" withObjectForPrimaryKeyAttribute:@"favoriteCatID"];

    // Create a cat to connect
    RKCat* cat = [NSEntityDescription insertNewObjectForEntityForName:@"RKCat" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    cat.name = @"Asia";
    cat.railsID = [NSNumber numberWithInt:31337];
    [managedObjectStore save:nil];

    NSDictionary* mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Blake", @"favoriteCatID", [NSNumber numberWithInt:31337], nil];
    RKHuman* human = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    mappingOperationDataSource.operationQueue = [[NSOperationQueue new] autorelease];
    RKMappingOperation* operation = [[RKMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    operation.dataSource = mappingOperationDataSource;
    NSError* error = nil;
    [operation performMapping:&error];

    assertThatInteger([operation retainCount], is(equalToInteger(1)));
}

- (void)testConnectionOfHasManyRelationshipsByPrimaryKeyDeprecated {
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];

    RKEntityMapping* catMapping = [RKEntityMapping mappingForEntityForName:@"RKCat" inManagedObjectStore:managedObjectStore];
    catMapping.primaryKeyAttribute = @"railsID";
    [catMapping mapAttributes:@"name", nil];

    RKEntityMapping* humanMapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:managedObjectStore];
    humanMapping.primaryKeyAttribute = @"railsID";
    [humanMapping mapAttributes:@"name", @"favoriteCatID", nil];
    [humanMapping hasOne:@"favoriteCat" withMapping:catMapping];
    [humanMapping connectRelationship:@"favoriteCat" withObjectForPrimaryKeyAttribute:@"favoriteCatID"];

    // Create a cat to connect
    RKCat* cat = [NSEntityDescription insertNewObjectForEntityForName:@"RKCat" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    cat.name = @"Asia";
    cat.railsID = [NSNumber numberWithInt:31337];
    [managedObjectStore save:nil];

    NSDictionary* mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Blake", @"favoriteCatID", [NSNumber numberWithInt:31337], nil];
    RKHuman* human = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    RKMappingOperation* operation = [[RKMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    NSError* error = nil;
    operation.dataSource = mappingOperationDataSource;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(human.favoriteCat, isNot(nilValue()));
    assertThat(human.favoriteCat.name, is(equalTo(@"Asia")));
}

- (void)testShouldConnectRelationshipsByPrimaryKeyWithDifferentSourceAndDestinationKeyPathsDeprecated {
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];

    RKEntityMapping* catMapping = [RKEntityMapping mappingForEntityForName:@"RKCat" inManagedObjectStore:managedObjectStore];
    catMapping.primaryKeyAttribute = @"railsID";
    [catMapping mapAttributes:@"name", nil];

    RKEntityMapping* humanMapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:managedObjectStore];
    humanMapping.primaryKeyAttribute = @"railsID";
    [humanMapping mapAttributes:@"name", @"favoriteCatID", @"catIDs", nil];
    [humanMapping mapRelationship:@"cats" withMapping:catMapping];
    [humanMapping connectRelationship:@"cats" withObjectForPrimaryKeyAttribute:@"catIDs"];

    // Create a couple of cats to connect
    RKCat* asia = [NSEntityDescription insertNewObjectForEntityForName:@"RKCat" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    asia.name = @"Asia";
    asia.railsID = [NSNumber numberWithInt:31337];

    RKCat* roy = [NSEntityDescription insertNewObjectForEntityForName:@"RKCat" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    roy.name = @"Reginald Royford Williams III";
    roy.railsID = [NSNumber numberWithInt:31338];

    [managedObjectStore save:nil];

    NSArray *catIDs = [NSArray arrayWithObjects:[NSNumber numberWithInt:31337], [NSNumber numberWithInt:31338], nil];
    NSDictionary* mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Blake", @"catIDs", catIDs, nil];
    RKHuman* human = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];

    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    RKMappingOperation* operation = [[RKMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    operation.dataSource = mappingOperationDataSource;
    NSError* error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(human.cats, isNot(nilValue()));
    assertThat([human.cats valueForKeyPath:@"name"], containsInAnyOrder(@"Asia", @"Reginald Royford Williams III", nil));
}

- (void)testShouldDynamicallyConnectRelationshipsByPrimaryKeyWhenMatchingSucceedsDeprecated {
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];

    RKEntityMapping* catMapping = [RKEntityMapping mappingForEntityForName:@"RKCat" inManagedObjectStore:managedObjectStore];
    catMapping.primaryKeyAttribute = @"railsID";
    [catMapping mapAttributes:@"name", nil];

    RKEntityMapping* humanMapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:managedObjectStore];
    humanMapping.primaryKeyAttribute = @"railsID";
    [humanMapping mapAttributes:@"name", @"favoriteCatID", nil];
    [humanMapping hasOne:@"favoriteCat" withMapping:catMapping];
    [humanMapping connectRelationship:@"favoriteCat" withObjectForPrimaryKeyAttribute:@"favoriteCatID" whenValueOfKeyPath:@"name" isEqualTo:@"Blake"];

    // Create a cat to connect
    RKCat* cat = [NSEntityDescription insertNewObjectForEntityForName:@"RKCat" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    cat.name = @"Asia";
    cat.railsID = [NSNumber numberWithInt:31337];
    [managedObjectStore save:nil];

    NSDictionary* mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Blake", @"favoriteCatID", [NSNumber numberWithInt:31337], nil];
    RKHuman* human = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    RKMappingOperation* operation = [[RKMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    operation.dataSource = mappingOperationDataSource;
    NSError* error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(human.favoriteCat, isNot(nilValue()));
    assertThat(human.favoriteCat.name, is(equalTo(@"Asia")));
}

- (void)testShouldNotDynamicallyConnectRelationshipsByPrimaryKeyWhenMatchingFailsDeprecated {
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];

    RKEntityMapping* catMapping = [RKEntityMapping mappingForEntityForName:@"RKCat" inManagedObjectStore:managedObjectStore];
    catMapping.primaryKeyAttribute = @"railsID";
    [catMapping mapAttributes:@"name", nil];

    RKEntityMapping* humanMapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:managedObjectStore];
    humanMapping.primaryKeyAttribute = @"railsID";
    [humanMapping mapAttributes:@"name", @"favoriteCatID", nil];
    [humanMapping hasOne:@"favoriteCat" withMapping:catMapping];
    [humanMapping connectRelationship:@"favoriteCat" withObjectForPrimaryKeyAttribute:@"favoriteCatID" whenValueOfKeyPath:@"name" isEqualTo:@"Jeff"];

    // Create a cat to connect
    RKCat* cat = [NSEntityDescription insertNewObjectForEntityForName:@"RKCat" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    cat.name = @"Asia";
    cat.railsID = [NSNumber numberWithInt:31337];
    [managedObjectStore save:nil];

    NSDictionary *mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Blake", @"favoriteCatID", [NSNumber numberWithInt:31337], nil];
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    RKMappingOperation* operation = [[RKMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    operation.dataSource = mappingOperationDataSource;
    NSError* error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(human.favoriteCat, is(nilValue()));
}

- (void)testShouldConnectRelationshipsByPrimaryKeyRegardlessOfOrderDeprecated {
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSManagedObjectContext *managedObjectContext = managedObjectStore.primaryManagedObjectContext;
    RKEntityMapping *parentMapping = [RKEntityMapping mappingForEntityForName:@"RKParent" inManagedObjectStore:managedObjectStore];
    [parentMapping mapAttributes:@"parentID", nil];
    parentMapping.primaryKeyAttribute = @"parentID";

    RKEntityMapping *childMapping = [RKEntityMapping mappingForEntityForName:@"RKChild" inManagedObjectStore:managedObjectStore];
    [childMapping mapAttributes:@"fatherID", nil];
    [childMapping mapRelationship:@"father" withMapping:parentMapping];
    [childMapping connectRelationship:@"father" withObjectForPrimaryKeyAttribute:@"fatherID"];

    RKObjectMappingProvider *mappingProvider = [RKObjectMappingProvider new];
    // NOTE: This may be fragile. Reverse order seems to trigger them to be mapped parent first. NSDictionary
    // keys are not guaranteed to return in any particular order
    [mappingProvider setMapping:parentMapping forKeyPath:@"parents"];
    [mappingProvider setMapping:childMapping  forKeyPath:@"children"];

    NSDictionary *JSON = [RKTestFixture parsedObjectWithContentsOfFixture:@"ConnectingParents.json"];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    
    NSOperationQueue *operationQueue = [NSOperationQueue new];
    [operationQueue setSuspended:YES];
    mappingOperationDataSource.operationQueue = operationQueue;
    
    __block RKMappingResult *result;
    [managedObjectContext performBlockAndWait:^{
        RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:JSON mappingProvider:mappingProvider];
        mapper.mappingOperationDataSource = mappingOperationDataSource;
        result = [mapper performMapping];
    }];
    
    [operationQueue setSuspended:NO];
    [operationQueue waitUntilAllOperationsAreFinished];
    
    NSArray *children = [[result asDictionary] valueForKey:@"children"];
    assertThat(children, hasCountOf(1));
    RKChild *child = [children lastObject];
    assertThat(child.father, is(notNilValue()));
}

#pragma GCC diagnostic pop

@end
