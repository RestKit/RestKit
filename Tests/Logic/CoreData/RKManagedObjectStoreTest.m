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

#import "CoreData.h"
#import "RKTestEnvironment.h"
#import "RKHuman.h"
#import "RKPathUtilities.h"
#import "RKSearchIndexer.h"
#import "RKManagedObjectStore_Private.h"

// TODO: Does this become `RKManagedObjectStore managedObjectModelWithName:version:inBundle:` ??? URLForManagedObjectModel
static NSURL *RKURLForManagedObjectModelWithNameAtVersion(NSString *modelName, NSUInteger version)
{
    NSString *modelNameAndVersion = (version == 1) ? modelName : [NSString stringWithFormat:@"%@ %ld", modelName, (unsigned long) version];
    return [[RKTestFixture fixtureBundle] URLForResource:[NSString stringWithFormat:@"%@.momd/%@", modelName, modelNameAndVersion] withExtension:@"mom"];
}

static NSManagedObjectModel *RKManagedObjectModelWithNameAtVersion(NSString *modelName, NSUInteger version)
{
    NSURL *URL = RKURLForManagedObjectModelWithNameAtVersion(modelName, version);
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:URL];
    return model;
}

static NSManagedObjectModel *RKManagedObjectModel()
{
    NSURL *modelURL = [[RKTestFixture fixtureBundle] URLForResource:@"Data Model" withExtension:@"mom"];
    return [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
}

@interface RKManagedObjectStoreTest : RKTestCase
@property (nonatomic, strong) id observerReference;
@end

@implementation RKManagedObjectStoreTest

- (void)setUp
{
    [RKTestFactory setUp];
    
    // Delete any sqlite files in the app data directory
    NSError *error;
    NSArray *paths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:RKApplicationDataDirectory() error:&error];
    NSArray *pathExtensions = @[ @"sqlite", @"sqlite-shm", @"sqlite-wal" ];
    for (NSString *path in paths) {
        if ([pathExtensions containsObject:[path pathExtension]]) {
            NSString *fullPath = [RKApplicationDataDirectory() stringByAppendingPathComponent:path];
            BOOL success = [[NSFileManager defaultManager] removeItemAtPath:fullPath error:&error];
            NSAssert(success, @"Failed to remove SQLite file at path: %@", fullPath);
        }
    }
}

- (void)tearDown
{
    if (self.observerReference) [[NSNotificationCenter defaultCenter] removeObserver:self.observerReference];
    [RKTestFactory tearDown];
}

- (void)testAdditionOfSQLiteStoreRetainsPathOfSeedDatabase
{
    // Create a store with a SQLite database to use as our store
    NSURL *modelURL = [[RKTestFixture fixtureBundle] URLForResource:@"Data Model" withExtension:@"mom"];
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    RKManagedObjectStore *seedStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:model];
    NSString *seedPath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"Seed.sqlite"];
    NSError *error;
    NSPersistentStore *persistentStore = [seedStore addSQLitePersistentStoreAtPath:seedPath fromSeedDatabaseAtPath:nil withConfiguration:nil options:nil error:&error];
    expect(persistentStore).notTo.beNil();
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:seedPath];
    expect(fileExists).to.beTruthy();

    // Create a secondary store using the seed
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:model];
    NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"Test.sqlite"];    
    persistentStore = [managedObjectStore addSQLitePersistentStoreAtPath:storePath fromSeedDatabaseAtPath:seedPath withConfiguration:nil options:nil error:&error];
    expect(persistentStore).notTo.beNil();

    fileExists = [[NSFileManager defaultManager] fileExistsAtPath:storePath];
    expect(fileExists).to.beTruthy();

    // Check that the store has a reference to the seed file option
    NSString *seedDatabasePath = [[persistentStore options] valueForKey:RKSQLitePersistentStoreSeedDatabasePathOption];
    expect(seedDatabasePath).to.equal(seedPath);
}

- (void)testAddingPersistentSQLiteStoreFromSeedDatabase
{
    // Create a store with an object to serve as our seed database
    NSURL *modelURL = [[RKTestFixture fixtureBundle] URLForResource:@"Data Model" withExtension:@"mom"];
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    RKManagedObjectStore *seedStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:model];
    NSError *error;
    NSString *seedPath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"Seed.sqlite"];
    NSPersistentStore *seedPersistentStore = [seedStore addSQLitePersistentStoreAtPath:seedPath fromSeedDatabaseAtPath:nil withConfiguration:nil options:nil error:&error];
    assertThat(seedPersistentStore, is(notNilValue()));
    [seedStore createManagedObjectContexts];
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:seedStore.persistentStoreManagedObjectContext];
    human.name = @"Blake";
    BOOL success = [seedStore.mainQueueManagedObjectContext saveToPersistentStore:&error];
    assertThatBool(success, is(equalToBool(YES)));
    NSManagedObjectID *seedObjectID = human.objectID;

    // Create a secondary store using the first store as the seed
    NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"SeededStore.sqlite"];
    RKManagedObjectStore *seededStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:model];
    NSPersistentStore *persistentStore = [seededStore addSQLitePersistentStoreAtPath:storePath fromSeedDatabaseAtPath:seedPath withConfiguration:nil options:nil error:&error];
    assertThat(persistentStore, is(notNilValue()));
    [seededStore createManagedObjectContexts];

    // Get back the seeded object
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"name = %@", @"Blake"];
    NSArray *array = [seededStore.persistentStoreManagedObjectContext executeFetchRequest:fetchRequest error:&error];
    assertThat(array, isNot(isEmpty()));
    RKHuman *seededHuman = array[0];
    assertThat([[seededHuman.objectID URIRepresentation] URLByDeletingLastPathComponent], is(equalTo([[seedObjectID URIRepresentation] URLByDeletingLastPathComponent])));
}

- (void)testResetPersistentStoresRecreatesInMemoryStoreThusDeletingAllManagedObjects
{
    NSURL *modelURL = [[RKTestFixture fixtureBundle] URLForResource:@"Data Model" withExtension:@"mom"];
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:model];
    NSError *error;
    NSPersistentStore *persistentStore = [managedObjectStore addInMemoryPersistentStore:&error];
    assertThat(persistentStore, is(notNilValue()));
    [managedObjectStore createManagedObjectContexts];
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    human.name = @"Blake";
    BOOL success = [managedObjectStore.mainQueueManagedObjectContext saveToPersistentStore:&error];
    assertThatBool(success, is(equalToBool(YES)));
    
    // Spin the run loop to allow the did save notifications to propogate
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];

    success = [managedObjectStore resetPersistentStores:&error];
    assertThatBool(success, is(equalToBool(YES)));

    // Check that the persistent store has changed
    NSPersistentStore *newPersistentStore = (managedObjectStore.persistentStoreCoordinator.persistentStores)[0];
    assertThat(newPersistentStore, isNot(equalTo(persistentStore)));

    // Check that the object is gone
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"name = %@", @"Blake"];
    NSArray *array = [managedObjectStore.mainQueueManagedObjectContext executeFetchRequest:fetchRequest error:&error];
    assertThat(array, isEmpty());
}

- (void)testResetPersistentStoresRecreatesSQLiteStoreThusDeletingAllManagedObjects
{
    NSURL *modelURL = [[RKTestFixture fixtureBundle] URLForResource:@"Data Model" withExtension:@"mom"];
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:model];
    NSError *error;
    NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"Test.sqlite"];
    NSPersistentStore *persistentStore = [managedObjectStore addSQLitePersistentStoreAtPath:storePath fromSeedDatabaseAtPath:nil withConfiguration:nil options:nil error:&error];
    assertThat(persistentStore, is(notNilValue()));
    [managedObjectStore createManagedObjectContexts];
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    human.name = @"Blake";
    BOOL success = [managedObjectStore.mainQueueManagedObjectContext saveToPersistentStore:&error];
    assertThatBool(success, is(equalToBool(YES)));

    // Spin the run loop to allow the did save notifications to propogate
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    
    success = [managedObjectStore resetPersistentStores:&error];
    assertThatBool(success, is(equalToBool(YES)));

    // Check that the object is gone
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"name = %@", @"Blake"];
    NSArray *array = [managedObjectStore.mainQueueManagedObjectContext executeFetchRequest:fetchRequest error:&error];
    assertThat(array, isEmpty());
}


- (void)testResetPersistentStoreRecreatesSQLiteStoreThusRecreatingTheStoreFileOnDisk
{
    NSURL *modelURL = [[RKTestFixture fixtureBundle] URLForResource:@"Data Model" withExtension:@"mom"];
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:model];
    NSError *error;
    NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"Test.sqlite"];
    NSPersistentStore *persistentStore = [managedObjectStore addSQLitePersistentStoreAtPath:storePath fromSeedDatabaseAtPath:nil withConfiguration:nil options:nil error:&error];
    assertThat(persistentStore, is(notNilValue()));
    [managedObjectStore createManagedObjectContexts];

    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:storePath error:&error];
    assertThat(attributes, is(notNilValue()));
    NSDate *modificationDate = attributes[NSFileModificationDate];

    BOOL success = [managedObjectStore resetPersistentStores:&error];
    assertThatBool(success, is(equalToBool(YES)));

    // Check that the persistent store has changed
    NSPersistentStore *newPersistentStore = (managedObjectStore.persistentStoreCoordinator.persistentStores)[0];
    assertThat(newPersistentStore, isNot(equalTo(persistentStore)));

    attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:storePath error:&error];
    assertThat(attributes, is(notNilValue()));
    NSDate *newModificationDate = attributes[NSFileModificationDate];

    NSDate *laterDate = [modificationDate laterDate:newModificationDate];
    assertThat(laterDate, is(equalTo(newModificationDate)));
}

- (void)testResetPersistentStoreForSQLiteStoreSeededWithDatabaseReclonesTheSeedDatabaseToTheStoreLocation
{
    // Create a store with an object to serve as our seed database
    NSURL *modelURL = [[RKTestFixture fixtureBundle] URLForResource:@"Data Model" withExtension:@"mom"];
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    RKManagedObjectStore *seedStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:model];
    NSError *error;
    NSString *seedPath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"Seed.sqlite"];
    NSPersistentStore *seedPersistentStore = [seedStore addSQLitePersistentStoreAtPath:seedPath fromSeedDatabaseAtPath:nil withConfiguration:nil options:nil error:&error];
    assertThat(seedPersistentStore, is(notNilValue()));
    [seedStore createManagedObjectContexts];
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:seedStore.persistentStoreManagedObjectContext];
    human.name = @"Blake";
    BOOL success = [seedStore.mainQueueManagedObjectContext saveToPersistentStore:&error];
    assertThatBool(success, is(equalToBool(YES)));
    NSManagedObjectID *seedObjectID = human.objectID;

    // Create a secondary store using the first store as the seed
    NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"SeededStore.sqlite"];
    RKManagedObjectStore *seededStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:model];
    NSPersistentStore *persistentStore = [seededStore addSQLitePersistentStoreAtPath:storePath fromSeedDatabaseAtPath:seedPath withConfiguration:nil options:nil error:&error];
    assertThat(persistentStore, is(notNilValue()));
    [seededStore createManagedObjectContexts];

    // Create a second object in the seeded store
    RKHuman *human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:seedStore.persistentStoreManagedObjectContext];
    human2.name = @"Sarah";
    success = [seededStore.mainQueueManagedObjectContext saveToPersistentStore:&error];
    assertThatBool(success, is(equalToBool(YES)));

    // Reset the persistent stores, causing the seed database to be recopied and orphaning the second object
    success = [seededStore resetPersistentStores:&error];
    assertThatBool(success, is(equalToBool(YES)));

    // Get back the seeded object and check against the seeded object ID
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"name = %@", @"Blake"];
    NSArray *array = [seededStore.persistentStoreManagedObjectContext executeFetchRequest:fetchRequest error:&error];
    assertThat(array, isNot(isEmpty()));
    RKHuman *seededHuman = array[0];
    assertThat([[seededHuman.objectID URIRepresentation] URLByDeletingLastPathComponent], is(equalTo([[seedObjectID URIRepresentation] URLByDeletingLastPathComponent])));

    // Check that the secondary object does not exist
    fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"name = %@", @"Sarah"];
    array = [seededStore.persistentStoreManagedObjectContext executeFetchRequest:fetchRequest error:&error];
    assertThat(array, isEmpty());
}

- (void)testResetPersistentStoreThatNeedsMigration
{
    NSError *error = nil;
    
    // Create a seed Store with model version 1
    NSManagedObjectModel *model_v1 = RKManagedObjectModelWithNameAtVersion(@"VersionedModel", 1);
    RKManagedObjectStore *managedObjectStoreModel_v1 = [[RKManagedObjectStore alloc] initWithManagedObjectModel:model_v1];
    NSString *seedPath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"SeedV1.sqlite"];
    [managedObjectStoreModel_v1 addSQLitePersistentStoreAtPath:seedPath fromSeedDatabaseAtPath:nil withConfiguration:nil options:nil error:nil];
    
    // Adding persistent store for model version 2
    NSManagedObjectModel *model_v2 = RKManagedObjectModelWithNameAtVersion(@"VersionedModel", 2);
    NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"SeededStore.sqlite"];
    RKManagedObjectStore *managedObjectStoreModel_v2 = [[RKManagedObjectStore alloc] initWithManagedObjectModel:model_v2];
    [managedObjectStoreModel_v2 addSQLitePersistentStoreAtPath:storePath fromSeedDatabaseAtPath:seedPath withConfiguration:nil options:nil error:&error];
    [managedObjectStoreModel_v2 createManagedObjectContexts];
    
    BOOL success = [managedObjectStoreModel_v2 resetPersistentStores:&error];
    assertThatBool(success, is(equalToBool(YES)));
    expect(error).to.beNil();
}

#if __IPHONE_OS_VERSION_MIN_REQUIRED
- (void)testThatAddingASQLiteStoreExcludesThePathFromiCloudBackups
{
    NSURL *modelURL = [[RKTestFixture fixtureBundle] URLForResource:@"Data Model" withExtension:@"mom"];
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:model];
    NSError *error;
    NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"TestBackupExclusion.sqlite"];
    [managedObjectStore addSQLitePersistentStoreAtPath:storePath fromSeedDatabaseAtPath:nil withConfiguration:nil options:nil error:&error];    
    NSURL *storeURL = [NSURL fileURLWithPath:storePath];
    id resourceValue = nil;
    BOOL success = [storeURL getResourceValue:&resourceValue forKey:NSURLIsExcludedFromBackupKey error:&error];
    expect(success).to.beTruthy();
    expect(resourceValue).to.equal(@(YES));
}


- (void)testResetPersistentStoresDoesNotTriggerDeadlock
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSManagedObject *managedObject1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    NSManagedObject *managedObject2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    [fetchRequest setSortDescriptors:@[ [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES] ]];
    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:managedObjectStore.mainQueueManagedObjectContext sectionNameKeyPath:nil cacheName:nil];
    NSError *error = nil;
    [fetchedResultsController performFetch:&error];
    BOOL success = [managedObjectStore resetPersistentStores:&error];
    expect(success).to.equal(YES);
    expect(error).to.beNil();
    [fetchedResultsController performFetch:&error];
    [managedObject1 setValue:@"Blake" forKey:@"name"];
    [managedObject2.managedObjectContext performBlockAndWait:^{
        [managedObject2 setValue:@"Blake" forKey:@"name"];
    }];
}
#endif

- (void)testCleanupOfExternalStorageDirectoryOnReset
{
    NSURL *modelURL = [[RKTestFixture fixtureBundle] URLForResource:@"Data Model" withExtension:@"mom"];
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:model];
    NSEntityDescription *humanEntity = [managedObjectStore.managedObjectModel entitiesByName][@"Human"];
    NSAttributeDescription *photoAttribute = [[NSAttributeDescription alloc] init];
    [photoAttribute setName:@"photo"];
    [photoAttribute setAttributeType:NSTransformableAttributeType];
    [photoAttribute setAllowsExternalBinaryDataStorage:YES];
    NSArray *newProperties = [[humanEntity properties] arrayByAddingObject:photoAttribute];
    [humanEntity setProperties:newProperties];
    NSError *error = nil;
    NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"RKTestsStore.sqlite"];
    NSPersistentStore *persistentStore = [managedObjectStore addSQLitePersistentStoreAtPath:storePath fromSeedDatabaseAtPath:nil withConfiguration:nil options:nil error:&error];
    assertThat(persistentStore, is(notNilValue()));
    [managedObjectStore createManagedObjectContexts];

    // Check for a SQLite write-ahead log
    NSString *writeAheadLogFile = [storePath stringByAppendingString:@"-wal"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:writeAheadLogFile]) {
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:writeAheadLogFile error:&error];
        NSDate *creationDate = attributes[NSFileCreationDate];

        BOOL success = [managedObjectStore resetPersistentStores:&error];
        expect(success).to.equal(YES);

        attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:writeAheadLogFile error:&error];
        NSDate *newCreationDate = attributes[NSFileCreationDate];

        expect([creationDate laterDate:newCreationDate]).to.equal(newCreationDate);
    } else {
        // Fall back to support directory
        NSString *supportDirectoryName = [NSString stringWithFormat:@".%@_SUPPORT", [[persistentStore.URL lastPathComponent] stringByDeletingPathExtension]];
        NSURL *supportDirectoryFileURL = [NSURL URLWithString:supportDirectoryName relativeToURL:[persistentStore.URL URLByDeletingLastPathComponent]];

        BOOL isDirectory = NO;
        BOOL supportDirectoryExists = [[NSFileManager defaultManager] fileExistsAtPath:[supportDirectoryFileURL path] isDirectory:&isDirectory];
        expect(supportDirectoryExists).to.equal(YES);
        expect(isDirectory).to.equal(YES);
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[supportDirectoryFileURL path] error:&error];
        NSDate *creationDate = attributes[NSFileCreationDate];
        
        BOOL success = [managedObjectStore resetPersistentStores:&error];
        expect(success).to.equal(YES);
        
        attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[supportDirectoryFileURL path] error:&error];
        NSDate *newCreationDate = attributes[NSFileCreationDate];
        
        expect([creationDate laterDate:newCreationDate]).to.equal(newCreationDate);
    }
}

- (void)testThatPersistentStoreWithLongNameHasExternalStorageResetCorrectly
{
    // Create a store with an object to serve as our seed database
    NSURL *modelURL = [[RKTestFixture fixtureBundle] URLForResource:@"Data Model" withExtension:@"mom"];
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:model];
    NSEntityDescription *humanEntity = [managedObjectStore.managedObjectModel entitiesByName][@"Human"];
    NSAttributeDescription *photoAttribute = [[NSAttributeDescription alloc] init];
    [photoAttribute setName:@"photo"];
    [photoAttribute setAttributeType:NSTransformableAttributeType];
    [photoAttribute setAllowsExternalBinaryDataStorage:YES];
    NSArray *newProperties = [[humanEntity properties] arrayByAddingObject:photoAttribute];
    [humanEntity setProperties:newProperties];
    NSError *error = nil;
    NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"This is the Store.sqlite"];
    NSPersistentStore *persistentStore = [managedObjectStore addSQLitePersistentStoreAtPath:storePath fromSeedDatabaseAtPath:nil withConfiguration:nil options:nil error:&error];
    assertThat(persistentStore, is(notNilValue()));
    [managedObjectStore createManagedObjectContexts];

    // Check for a SQLite write-ahead log
    NSString *writeAheadLogFile = [storePath stringByAppendingString:@"-wal"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:writeAheadLogFile]) {
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:writeAheadLogFile error:&error];
        NSDate *creationDate = attributes[NSFileCreationDate];

        BOOL success = [managedObjectStore resetPersistentStores:&error];
        expect(success).to.equal(YES);

        attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:writeAheadLogFile error:&error];
        NSDate *newCreationDate = attributes[NSFileCreationDate];

        expect([creationDate laterDate:newCreationDate]).to.equal(newCreationDate);
    } else {
        // Check that there is a support directory
        NSString *supportDirectoryName = [NSString stringWithFormat:@".%@_SUPPORT", [[persistentStore.URL lastPathComponent] stringByDeletingPathExtension]];
        NSString *supportDirectoryPath = [[[[persistentStore URL] path] stringByDeletingLastPathComponent] stringByAppendingPathComponent:supportDirectoryName];
        
        BOOL isDirectory = NO;
        BOOL supportDirectoryExists = [[NSFileManager defaultManager] fileExistsAtPath:supportDirectoryPath isDirectory:&isDirectory];
        expect(supportDirectoryExists).to.equal(YES);
        expect(isDirectory).to.equal(YES);
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:supportDirectoryPath error:&error];
        NSDate *creationDate = attributes[NSFileCreationDate];
        
        BOOL success = [managedObjectStore resetPersistentStores:&error];
        expect(success).to.equal(YES);
        
        attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:supportDirectoryPath error:&error];
        NSDate *newCreationDate = attributes[NSFileCreationDate];
        
        expect([creationDate laterDate:newCreationDate]).to.equal(newCreationDate);
    }
}

#pragma mark - Versioning Tests

- (void)testThatAttemptToMigrateStoreAtNonExistantFileURLReturnsError
{
    NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"NonExistantStore.sqlite"];
    NSURL *storeURL = [NSURL fileURLWithPath:storePath];
    NSError *error = nil;
    NSURL *modelURL = RKURLForManagedObjectModelWithNameAtVersion(@"VersionedModel", 1);
    BOOL success = [RKManagedObjectStore migratePersistentStoreOfType:NSSQLiteStoreType atURL:storeURL toModelAtURL:modelURL error:&error configuringModelsWithBlock:nil];
    expect(success).to.equal(NO);

    // Under iOS 7+ we get a NSFileReadNoSuchFileError
    expect(error.code == 0 || error.code == NSFileReadNoSuchFileError).to.beTruthy();
}

- (void)testThatAttemptingToMigrateToANonVersionedModelReturnsError
{
    NSURL *modelURL = [[RKTestFixture fixtureBundle] URLForResource:@"Data Model" withExtension:@"mom"];
    NSManagedObjectModel *model_v1 = RKManagedObjectModelWithNameAtVersion(@"VersionedModel", 1);
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:model_v1];
    NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"TestStore.sqlite"];
    NSError *error = nil;
    NSDictionary *options = @{ NSMigratePersistentStoresAutomaticallyOption: @(NO), NSInferMappingModelAutomaticallyOption: @(NO) };
    [managedObjectStore addSQLitePersistentStoreAtPath:storePath fromSeedDatabaseAtPath:nil withConfiguration:nil options:options error:&error];
    [managedObjectStore createManagedObjectContexts];
    managedObjectStore = nil;
    
    // Attempting to update to `modelURL` will fail because this is an unversioned model
    NSURL *storeURL = [NSURL fileURLWithPath:storePath];
    BOOL success = [RKManagedObjectStore migratePersistentStoreOfType:NSSQLiteStoreType atURL:storeURL toModelAtURL:modelURL error:&error configuringModelsWithBlock:nil];
    expect(success).to.equal(NO);
    expect(error).notTo.beNil();
    expect(error.code).to.equal(NSMigrationError);
    assertThat([error localizedDescription], startsWith(@"Migration failed: Migrations can only be performed to versioned destination models contained in a .momd package. Incompatible destination model given at path"));
}

- (void)testThatAttemptingToMigrateFromAnUnidentifiableSourceModelReturnsError
{
    NSManagedObjectModel *model_v1 = RKManagedObjectModelWithNameAtVersion(@"VersionedModel", 1);
    NSEntityDescription *extraEntity = [NSEntityDescription new];
    [extraEntity setName:@"Extra"];
    [model_v1 setEntities:[[model_v1 entities] arrayByAddingObject:extraEntity]];
    
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:model_v1];
    NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"TestStore.sqlite"];
    NSError *error = nil;
    NSDictionary *options = @{ NSMigratePersistentStoresAutomaticallyOption: @(NO), NSInferMappingModelAutomaticallyOption: @(NO) };
    [managedObjectStore addSQLitePersistentStoreAtPath:storePath fromSeedDatabaseAtPath:nil withConfiguration:nil options:options error:&error];
    [managedObjectStore createManagedObjectContexts];
    managedObjectStore = nil;
    
    // Attempting to upgrade to v2 returns NO, because it can't find the source model (due to the added entity)
    NSURL *storeURL = [NSURL fileURLWithPath:storePath];
    NSURL *modelURL = RKURLForManagedObjectModelWithNameAtVersion(@"VersionedModel", 2);
    BOOL success = [RKManagedObjectStore migratePersistentStoreOfType:NSSQLiteStoreType atURL:storeURL toModelAtURL:modelURL error:&error configuringModelsWithBlock:nil];
    expect(success).to.equal(NO);
    expect(error).notTo.beNil();
    expect(error.code).to.equal(NSMigrationMissingSourceModelError);    
    assertThat([error localizedDescription], startsWith(@"Migration failed: Unable to find the source managed object model used to create the SQLite store at path"));
}

- (void)testMigrationToCompatibleVersionReturnsYes
{
    NSManagedObjectModel *model_v1 = RKManagedObjectModelWithNameAtVersion(@"VersionedModel", 1);
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:model_v1];
    NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"TestStore.sqlite"];
    NSError *error = nil;
    NSDictionary *options = @{ NSMigratePersistentStoresAutomaticallyOption: @(NO), NSInferMappingModelAutomaticallyOption: @(NO) };
    [managedObjectStore addSQLitePersistentStoreAtPath:storePath fromSeedDatabaseAtPath:nil withConfiguration:nil options:options error:&error];
    [managedObjectStore createManagedObjectContexts];
    managedObjectStore = nil;
    
    // Attempting to upgrade to v1 returns YES, because its already compatible
    NSURL *storeURL = [NSURL fileURLWithPath:storePath];
    NSURL *modelURL = RKURLForManagedObjectModelWithNameAtVersion(@"VersionedModel", 1);
    BOOL success = [RKManagedObjectStore migratePersistentStoreOfType:NSSQLiteStoreType atURL:storeURL toModelAtURL:modelURL error:&error configuringModelsWithBlock:nil];
    expect(success).to.equal(YES);
    expect(error).to.beNil();
}

- (void)testUpgradingFromVersionedModelAt1_0to2_0
{
    // Create a v1 Store
    NSManagedObjectModel *model_v1 = RKManagedObjectModelWithNameAtVersion(@"VersionedModel", 1);
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:model_v1];
    NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"TestStore.sqlite"];
    NSError *error = nil;
    NSDictionary *options = @{ NSMigratePersistentStoresAutomaticallyOption: @(NO), NSInferMappingModelAutomaticallyOption: @(NO) };
    [managedObjectStore addSQLitePersistentStoreAtPath:storePath fromSeedDatabaseAtPath:nil withConfiguration:nil options:options error:&error];
    [managedObjectStore createManagedObjectContexts];
    managedObjectStore = nil;
    
    // Now upgrade it to v2
    NSURL *storeURL = [NSURL fileURLWithPath:storePath];
    NSURL *modelURL = RKURLForManagedObjectModelWithNameAtVersion(@"VersionedModel", 2);
    BOOL success = [RKManagedObjectStore migratePersistentStoreOfType:NSSQLiteStoreType atURL:storeURL toModelAtURL:modelURL error:&error configuringModelsWithBlock:nil];
    expect(success).to.equal(YES);
    expect(error).to.beNil();
}

- (void)testUpgradingFromVersionedModelAt1_0to_4_0
{
    // Create a v1 Store
    NSManagedObjectModel *model_v1 = RKManagedObjectModelWithNameAtVersion(@"VersionedModel", 1);
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:model_v1];
    NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"TestStore.sqlite"];
    NSError *error = nil;
    NSDictionary *options = @{ NSMigratePersistentStoresAutomaticallyOption: @(NO), NSInferMappingModelAutomaticallyOption: @(NO) };
    [managedObjectStore addSQLitePersistentStoreAtPath:storePath fromSeedDatabaseAtPath:nil withConfiguration:nil options:options error:&error];
    [managedObjectStore createManagedObjectContexts];
    managedObjectStore = nil;
    
    // Now upgrade it to v4
    NSURL *storeURL = [NSURL fileURLWithPath:storePath];
    NSURL *modelURL = RKURLForManagedObjectModelWithNameAtVersion(@"VersionedModel", 4);
    BOOL success = [RKManagedObjectStore migratePersistentStoreOfType:NSSQLiteStoreType atURL:storeURL toModelAtURL:modelURL error:&error configuringModelsWithBlock:nil];
    expect(success).to.equal(YES);
    expect(error).to.beNil();
}

- (void)testUpgradingFromVersionedModelWithSearchAttributesAt2_0to_3_0
{
    // Create a v2 Store
    NSManagedObjectModel *model_v2 = RKManagedObjectModelWithNameAtVersion(@"VersionedModel", 2);
    
    // Add search indexing on the title attribute
    NSEntityDescription *articleEntity = [model_v2 entitiesByName][@"Article"];
    [RKSearchIndexer addSearchIndexingToEntity:articleEntity onAttributes:@[ @"title" ]];
     
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:model_v2];
    NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"TestStore.sqlite"];
    NSError *error = nil;
    NSDictionary *options = @{ NSMigratePersistentStoresAutomaticallyOption: @(NO), NSInferMappingModelAutomaticallyOption: @(NO) };
    [managedObjectStore addSQLitePersistentStoreAtPath:storePath fromSeedDatabaseAtPath:nil withConfiguration:nil options:options error:&error];
    [managedObjectStore createManagedObjectContexts];
    managedObjectStore = nil;
    
    // Now upgrade it to v3
    NSURL *storeURL = [NSURL fileURLWithPath:storePath];
    NSURL *modelURL = RKURLForManagedObjectModelWithNameAtVersion(@"VersionedModel", 4);
    BOOL success = [RKManagedObjectStore migratePersistentStoreOfType:NSSQLiteStoreType atURL:storeURL toModelAtURL:modelURL error:&error configuringModelsWithBlock:^(NSManagedObjectModel *model, NSURL *sourceURL) {
        if ([[model versionIdentifiers] isEqualToSet:[NSSet setWithObject:@"2.0"]]) {
            NSEntityDescription *articleEntity = [model entitiesByName][@"Article"];
            [RKSearchIndexer addSearchIndexingToEntity:articleEntity onAttributes:@[ @"title" ]];
        }
    }];
    expect(success).to.equal(YES);
    expect(error).to.beNil();
}

- (void)testUpgradingFromVersionedModelWithSearchAttributesAt_1_0toLatest
{
    // Create a v1 Store
    NSManagedObjectModel *model_v1 = RKManagedObjectModelWithNameAtVersion(@"VersionedModel", 1);
    
    // Add search indexing on the title attribute
    NSEntityDescription *articleEntity = [model_v1 entitiesByName][@"Article"];
    NSEntityDescription *tagEntity = [model_v1 entitiesByName][@"Tag"];
    [RKSearchIndexer addSearchIndexingToEntity:articleEntity onAttributes:@[ @"title" ]];
    [RKSearchIndexer addSearchIndexingToEntity:tagEntity onAttributes:@[ @"name" ]];
    
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:model_v1];
    NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"TestStore.sqlite"];
    NSError *error = nil;
    NSDictionary *options = @{ NSMigratePersistentStoresAutomaticallyOption: @(NO), NSInferMappingModelAutomaticallyOption: @(NO) };
    [managedObjectStore addSQLitePersistentStoreAtPath:storePath fromSeedDatabaseAtPath:nil withConfiguration:nil options:options error:&error];
    [managedObjectStore createManagedObjectContexts];
    managedObjectStore = nil;
    
    // Now upgrade it to the latest version
    NSURL *storeURL = [NSURL fileURLWithPath:storePath];
    NSURL *modelURL = [[RKTestFixture fixtureBundle] URLForResource:@"VersionedModel" withExtension:@"momd"];
    BOOL success = [RKManagedObjectStore migratePersistentStoreOfType:NSSQLiteStoreType atURL:storeURL toModelAtURL:modelURL error:&error configuringModelsWithBlock:^(NSManagedObjectModel *model, NSURL *sourceURL) {
        if ([[model versionIdentifiers] isEqualToSet:[NSSet setWithObject:@"1.0"]]) {
            NSEntityDescription *articleEntity = [model entitiesByName][@"Article"];
            NSEntityDescription *tagEntity = [model entitiesByName][@"Tag"];
            [RKSearchIndexer addSearchIndexingToEntity:articleEntity onAttributes:@[ @"title" ]];
            [RKSearchIndexer addSearchIndexingToEntity:tagEntity onAttributes:@[ @"name" ]];
        } else if ([[model versionIdentifiers] isEqualToSet:[NSSet setWithObject:@"2.0"]]) {
            NSEntityDescription *articleEntity = [model entitiesByName][@"Article"];
            NSEntityDescription *tagEntity = [model entitiesByName][@"Tag"];
            [RKSearchIndexer addSearchIndexingToEntity:articleEntity onAttributes:@[ @"title", @"body" ]];
            [RKSearchIndexer addSearchIndexingToEntity:tagEntity onAttributes:@[ @"name" ]];
        } else if ([[model versionIdentifiers] containsObject:@"3.0"] || [[model versionIdentifiers] containsObject:@"4.0"]) {
            // We index the same attributes on v3 and v4
            NSEntityDescription *articleEntity = [model entitiesByName][@"Article"];
            NSEntityDescription *tagEntity = [model entitiesByName][@"Tag"];
            [RKSearchIndexer addSearchIndexingToEntity:articleEntity onAttributes:@[ @"title", @"body", @"authorName" ]];
            [RKSearchIndexer addSearchIndexingToEntity:tagEntity onAttributes:@[ @"name" ]];
        }
    }];
    expect(success).to.equal(YES);
    expect(error).to.beNil();
}

- (void)testSetOfManagedObjectIDsFromManagedObjectContextDidSaveNotification {
    
    NSManagedObjectModel *managedObjectModel = RKManagedObjectModel();
    NSEntityDescription *entity = [managedObjectModel entitiesByName][@"Human"];
    
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
    NSError *error;
    [persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:&error];
    NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator;
    
    __block NSUInteger count = 0;
    
    NSManagedObject *human1 = [NSEntityDescription insertNewObjectForEntityForName:entity.name inManagedObjectContext:managedObjectContext];
    [managedObjectContext save:NULL];
    
    NSManagedObject *human2 = [NSEntityDescription insertNewObjectForEntityForName:entity.name inManagedObjectContext:managedObjectContext];
    [managedObjectContext save:NULL];
    
    self.observerReference = [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification object:managedObjectContext queue:nil usingBlock:^(NSNotification *notification) {
        NSSet *set = RKSetOfManagedObjectIDsFromManagedObjectContextDidSaveNotification(notification);
        count = set.count;
    }];
    
    [human1 setValue:@"Jane Doe" forKey:@"name"];
    [managedObjectContext deleteObject:human2];
    
    [NSEntityDescription insertNewObjectForEntityForName:entity.name inManagedObjectContext:managedObjectContext];
    [managedObjectContext save:NULL];
    
    // 1 inserted
    // 1 updated
    // 1 deleted
    expect(count).will.equal(3);
    
}

@end
