//
//  RKManagedObjectStoreTest.m
//  RestKit
//
//  Created by Blake Watters on 7/2/11.
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
#import "RKDirectoryUtilities.h"

@interface RKManagedObjectStoreTest : RKTestCase

@end

@implementation RKManagedObjectStoreTest

- (void)setUp
{
    [RKTestFactory setUp];
    
    // Delete any sqlite files in the app data directory
    NSError *error;
    NSArray *paths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:RKApplicationDataDirectory() error:&error];
    for (NSString *path in paths) {
        if ([[path pathExtension] isEqualToString:@"sqlite"]) {
            NSString *fullPath = [RKApplicationDataDirectory() stringByAppendingPathComponent:path];
            BOOL success = [[NSFileManager defaultManager] removeItemAtPath:fullPath error:&error];
            NSAssert(success, @"Failed to remove SQLite file at path: %@", fullPath);
        }
    }
}

- (void)tearDown
{
    [RKTestFactory tearDown];
}

- (void)testInstantiationOfNewManagedObjectContextAssociatesWithObjectStore
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSManagedObjectContext *context = [managedObjectStore newChildManagedObjectContextWithConcurrencyType:NSMainQueueConcurrencyType];
    assertThat([context managedObjectStore], is(equalTo(managedObjectStore)));
}

- (void)testAdditionOfSQLiteStoreRetainsPathOfSeedDatabase
{
    // Create a store with a SQLite database to use as our store
    RKManagedObjectStore *seedStore = [[RKManagedObjectStore alloc] init];
    NSString *seedPath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"Seed.sqlite"];
    NSError *error;
    NSPersistentStore *persistentStore = [seedStore addSQLitePersistentStoreAtPath:seedPath fromSeedDatabaseAtPath:nil error:&error];
    assertThat(persistentStore, is(notNilValue()));
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:seedPath];
    assertThatBool(fileExists, is(equalToBool(YES)));
    [seedStore release];

    // Create a secondary store using the seed
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] init];
    NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"Test.sqlite"];
    persistentStore = [managedObjectStore addSQLitePersistentStoreAtPath:storePath fromSeedDatabaseAtPath:seedPath error:&error];
    assertThat(persistentStore, is(notNilValue()));

    fileExists = [[NSFileManager defaultManager] fileExistsAtPath:storePath];
    assertThatBool(fileExists, is(equalToBool(YES)));

    // Check that the store has a reference to the seed file option
    NSString *seedDatabasePath = [[persistentStore options] valueForKey:RKSQLitePersistentStoreSeedDatabasePathOption];
    assertThat(seedDatabasePath, is(equalTo(seedPath)));
    [managedObjectStore release];
}

- (void)testAddingPersistentSQLiteStoreFromSeedDatabase
{
    // Create a store with an object to serve as our seed database
    RKManagedObjectStore *seedStore = [[RKManagedObjectStore alloc] init];
    NSError *error;
    NSString *seedPath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"Seed.sqlite"];
    NSPersistentStore *seedPersistentStore = [seedStore addSQLitePersistentStoreAtPath:seedPath fromSeedDatabaseAtPath:nil error:&error];
    assertThat(seedPersistentStore, is(notNilValue()));
    [seedStore createManagedObjectContexts];
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:seedStore.primaryManagedObjectContext];
    human.name = @"Blake";
    BOOL success = [seedStore.mainQueueManagedObjectContext saveToPersistentStore:&error];
    assertThatBool(success, is(equalToBool(YES)));
    NSManagedObjectID *seedObjectID = human.objectID;
    [seedStore release];

    // Create a secondary store using the first store as the seed
    NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"SeededStore.sqlite"];
    RKManagedObjectStore *seededStore = [[RKManagedObjectStore alloc] init];
    NSPersistentStore *persistentStore = [seededStore addSQLitePersistentStoreAtPath:storePath fromSeedDatabaseAtPath:seedPath error:&error];
    assertThat(persistentStore, is(notNilValue()));
    [seededStore createManagedObjectContexts];

    // Get back the seeded object
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"RKHuman"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"name = %@", @"Blake"];
    NSArray *array = [seededStore.primaryManagedObjectContext executeFetchRequest:fetchRequest error:&error];
    assertThat(array, isNot(empty()));
    RKHuman *seededHuman = [array objectAtIndex:0];
    assertThat([[seededHuman.objectID URIRepresentation] URLByDeletingLastPathComponent], is(equalTo([[seedObjectID URIRepresentation] URLByDeletingLastPathComponent])));
    [seededStore release];
}

- (void)testResetPersistentStoresRecreatesInMemoryStoreThusDeletingAllManagedObjects
{
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] init];
    NSError *error;
    NSPersistentStore *persistentStore = [managedObjectStore addInMemoryPersistentStore:&error];
    assertThat(persistentStore, is(notNilValue()));
    [managedObjectStore createManagedObjectContexts];
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    human.name = @"Blake";
    BOOL success = [managedObjectStore.mainQueueManagedObjectContext saveToPersistentStore:&error];
    assertThatBool(success, is(equalToBool(YES)));
    
    // Spin the run loop to allow the did save notifications to propogate
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]];

    success = [managedObjectStore resetPersistentStores:&error];
    assertThatBool(success, is(equalToBool(YES)));

    // Check that the persistent store has changed
    NSPersistentStore *newPersistentStore = [managedObjectStore.persistentStoreCoordinator.persistentStores objectAtIndex:0];
    assertThat(newPersistentStore, isNot(equalTo(persistentStore)));

    // Check that the object is gone
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"RKHuman"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"name = %@", @"Blake"];
    NSArray *array = [managedObjectStore.mainQueueManagedObjectContext executeFetchRequest:fetchRequest error:&error];
    assertThat(array, is(empty()));
    [managedObjectStore release];
}

- (void)testResetPersistentStoresRecreatesSQLiteStoreThusDeletingAllManagedObjects
{
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] init];
    NSError *error;
    NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"Test.sqlite"];
    NSPersistentStore *persistentStore = [managedObjectStore addSQLitePersistentStoreAtPath:storePath fromSeedDatabaseAtPath:nil error:&error];
    assertThat(persistentStore, is(notNilValue()));
    [managedObjectStore createManagedObjectContexts];
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    human.name = @"Blake";
    BOOL success = [managedObjectStore.mainQueueManagedObjectContext saveToPersistentStore:&error];
    assertThatBool(success, is(equalToBool(YES)));

    // Spin the run loop to allow the did save notifications to propogate
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]];
    
    success = [managedObjectStore resetPersistentStores:&error];
    assertThatBool(success, is(equalToBool(YES)));

    // Check that the object is gone
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"RKHuman"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"name = %@", @"Blake"];
    NSArray *array = [managedObjectStore.mainQueueManagedObjectContext executeFetchRequest:fetchRequest error:&error];
    assertThat(array, is(empty()));
    [managedObjectStore release];
}


- (void)testResetPersistentStoreRecreatesSQLiteStoreThusRecreatingTheStoreFileOnDisk
{
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] init];
    NSError *error;
    NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"Test.sqlite"];
    NSPersistentStore *persistentStore = [managedObjectStore addSQLitePersistentStoreAtPath:storePath fromSeedDatabaseAtPath:nil error:&error];
    assertThat(persistentStore, is(notNilValue()));
    [managedObjectStore createManagedObjectContexts];

    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:storePath error:&error];
    assertThat(attributes, is(notNilValue()));
    NSDate *modificationDate = [attributes objectForKey:NSFileModificationDate];

    BOOL success = [managedObjectStore resetPersistentStores:&error];
    assertThatBool(success, is(equalToBool(YES)));

    // Check that the persistent store has changed
    NSPersistentStore *newPersistentStore = [managedObjectStore.persistentStoreCoordinator.persistentStores objectAtIndex:0];
    assertThat(newPersistentStore, isNot(equalTo(persistentStore)));

    attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:storePath error:&error];
    assertThat(attributes, is(notNilValue()));
    NSDate *newModificationDate = [attributes objectForKey:NSFileModificationDate];

    NSDate *laterDate = [modificationDate laterDate:newModificationDate];
    assertThat(laterDate, is(equalTo(newModificationDate)));
    [managedObjectStore release];
}

- (void)testResetPersistentStoreForSQLiteStoreSeededWithDatabaseReclonesTheSeedDatabaseToTheStoreLocation
{
    // Create a store with an object to serve as our seed database
    RKManagedObjectStore *seedStore = [[RKManagedObjectStore alloc] init];
    NSError *error;
    NSString *seedPath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"Seed.sqlite"];
    NSPersistentStore *seedPersistentStore = [seedStore addSQLitePersistentStoreAtPath:seedPath fromSeedDatabaseAtPath:nil error:&error];
    assertThat(seedPersistentStore, is(notNilValue()));
    [seedStore createManagedObjectContexts];
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:seedStore.primaryManagedObjectContext];
    human.name = @"Blake";
    BOOL success = [seedStore.mainQueueManagedObjectContext saveToPersistentStore:&error];
    assertThatBool(success, is(equalToBool(YES)));
    NSManagedObjectID *seedObjectID = human.objectID;
    [seedStore release];

    // Create a secondary store using the first store as the seed
    NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"SeededStore.sqlite"];
    RKManagedObjectStore *seededStore = [[RKManagedObjectStore alloc] init];
    NSPersistentStore *persistentStore = [seededStore addSQLitePersistentStoreAtPath:storePath fromSeedDatabaseAtPath:seedPath error:&error];
    assertThat(persistentStore, is(notNilValue()));
    [seededStore createManagedObjectContexts];

    // Create a second object in the seeded store
    RKHuman *human2 = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:seedStore.primaryManagedObjectContext];
    human2.name = @"Sarah";
    success = [seededStore.mainQueueManagedObjectContext saveToPersistentStore:&error];
    assertThatBool(success, is(equalToBool(YES)));

    // Reset the persistent stores, causing the seed database to be recopied and orphaning the second object
    success = [seededStore resetPersistentStores:&error];
    assertThatBool(success, is(equalToBool(YES)));

    // Get back the seeded object and check against the seeded object ID
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"RKHuman"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"name = %@", @"Blake"];
    NSArray *array = [seededStore.primaryManagedObjectContext executeFetchRequest:fetchRequest error:&error];
    assertThat(array, isNot(empty()));
    RKHuman *seededHuman = [array objectAtIndex:0];
    assertThat([[seededHuman.objectID URIRepresentation] URLByDeletingLastPathComponent], is(equalTo([[seedObjectID URIRepresentation] URLByDeletingLastPathComponent])));

    // Check that the secondary object does not exist
    fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"RKHuman"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"name = %@", @"Sarah"];
    array = [seededStore.primaryManagedObjectContext executeFetchRequest:fetchRequest error:&error];
    assertThat(array, is(empty()));
    [seededStore release];
}

@end
