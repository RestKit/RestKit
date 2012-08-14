//
//  RKSearchIndexerTest.m
//  RestKit
//
//  Created by Blake Watters on 7/30/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKSearchIndexer.h"
#import "RKSearchWordEntity.h"

@interface RKSearchIndexerTest : RKTestCase

@end

@implementation RKSearchIndexerTest

- (void)testAddingSearchIndexingToEntity
{
    NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:[NSBundle allBundles]];
    NSEntityDescription *entity = [[managedObjectModel entitiesByName] objectForKey:@"RKHuman"];
    NSEntityDescription *searchWordEntity = [managedObjectModel.entitiesByName objectForKey:@"RKSearchWord"];
    assertThat(searchWordEntity, is(nilValue()));
    [RKSearchIndexer addSearchIndexingToEntity:entity onAttributes:@[ @"name", @"nickName" ]];
    
    // Check that the entity now exists
    searchWordEntity = [managedObjectModel.entitiesByName objectForKey:@"RKSearchWord"];
    assertThat(searchWordEntity, is(notNilValue()));
    
    // Check that Human now has a searchWords relationship
    NSRelationshipDescription *searchWordsRelationship = [[entity relationshipsByName] objectForKey:@"searchWords"];
    assertThat(searchWordsRelationship, is(notNilValue()));
    
    // Check that RKSearchWord now has a RKHuman inverse
    NSRelationshipDescription *humanInverse = [[searchWordEntity relationshipsByName] objectForKey:@"RKHuman"];
    assertThat(humanInverse, is(notNilValue()));
    assertThat([humanInverse inverseRelationship], is(equalTo(searchWordsRelationship)));
    assertThat([searchWordsRelationship inverseRelationship], is(equalTo(humanInverse)));
    
    // Check the userInfo of the Human entity for the searchable attributes
    NSArray *attributes = [entity.userInfo objectForKey:RKSearchableAttributeNamesUserInfoKey];
    assertThat(attributes, is(equalTo(@[ @"name", @"nickName" ])));
}

- (void)testAddingSearchIndexingToEntityWithMixtureOfNSAttributeDescriptionAndStringNames
{
    NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:[NSBundle allBundles]];
    NSEntityDescription *entity = [[managedObjectModel entitiesByName] objectForKey:@"RKHuman"];
    NSEntityDescription *searchWordEntity = [managedObjectModel.entitiesByName objectForKey:@"RKSearchWord"];
    assertThat(searchWordEntity, is(nilValue()));
    NSAttributeDescription *nickNameAttribute = [entity.attributesByName objectForKey:@"nickName"];
    [RKSearchIndexer addSearchIndexingToEntity:entity onAttributes:@[ @"name", nickNameAttribute ]];
    
    // Check that the entity now exists
    searchWordEntity = [managedObjectModel.entitiesByName objectForKey:@"RKSearchWord"];
    assertThat(searchWordEntity, is(notNilValue()));
    
    // Check that Human now has a searchWords relationship
    NSRelationshipDescription *searchWordsRelationship = [[entity relationshipsByName] objectForKey:@"searchWords"];
    assertThat(searchWordsRelationship, is(notNilValue()));
    
    // Check that RKSearchWord now has a RKHuman inverse
    NSRelationshipDescription *humanInverse = [[searchWordEntity relationshipsByName] objectForKey:@"RKHuman"];
    assertThat(humanInverse, is(notNilValue()));
    assertThat([humanInverse inverseRelationship], is(equalTo(searchWordsRelationship)));
    assertThat([searchWordsRelationship inverseRelationship], is(equalTo(humanInverse)));
    
    // Check the userInfo of the Human entity for the searchable attributes
    NSArray *attributes = [entity.userInfo objectForKey:RKSearchableAttributeNamesUserInfoKey];
    assertThat(attributes, is(equalTo(@[ @"name", @"nickName" ])));
}

- (void)testAddingSearchIndexingToNonStringAttributeTypeRaisesException
{
    NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:[NSBundle allBundles]];
    NSEntityDescription *entity = [[managedObjectModel entitiesByName] objectForKey:@"RKHuman"];
    NSEntityDescription *searchWordEntity = [managedObjectModel.entitiesByName objectForKey:@"RKSearchWord"];
    assertThat(searchWordEntity, is(nilValue()));
    
    NSException *exception = nil;
    @try {
        [RKSearchIndexer addSearchIndexingToEntity:entity onAttributes:@[ @"name", @"railsID" ]];
    }
    @catch (NSException *e) {
        exception = e;
    }
    @finally {
        assertThat(exception, is(notNilValue()));
        assertThat(exception.reason, containsString(@"Invalid attribute identifier given: Expected an attribute of type NSStringAttributeType, got 200."));
    }
}

- (void)testAddingSearchIndexingToNonExistantAttributeRaisesException
{
    NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:[NSBundle allBundles]];
    NSEntityDescription *entity = [[managedObjectModel entitiesByName] objectForKey:@"RKHuman"];
    NSEntityDescription *searchWordEntity = [managedObjectModel.entitiesByName objectForKey:@"RKSearchWord"];
    assertThat(searchWordEntity, is(nilValue()));
    
    NSException *exception = nil;
    @try {
        [RKSearchIndexer addSearchIndexingToEntity:entity onAttributes:@[ @"name", @"doesNotExist" ]];
    }
    @catch (NSException *e) {
        exception = e;
    }
    @finally {
        assertThat(exception, is(notNilValue()));
        assertThat(exception.reason, containsString(@"Invalid attribute identifier given: No attribute with the name 'doesNotExist' found in the 'RKHuman' entity."));
    }
}

- (void)testAddingSearchIndexingToTwoEntitiesManipulatesTheSameSearchWordEntity
{
    NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:[NSBundle allBundles]];
    NSEntityDescription *humanEntity = [[managedObjectModel entitiesByName] objectForKey:@"RKHuman"];
    NSEntityDescription *catEntity = [[managedObjectModel entitiesByName] objectForKey:@"RKCat"];

    [RKSearchIndexer addSearchIndexingToEntity:humanEntity
                      onAttributes:@[ @"name", @"nickName" ]];
    [RKSearchIndexer addSearchIndexingToEntity:catEntity
                      onAttributes:@[ @"name", @"nickName" ]];

    NSEntityDescription *searchWordEntity = [[managedObjectModel entitiesByName] objectForKey:RKSearchWordEntityName];
    
    NSRelationshipDescription *humanRelationship = [[searchWordEntity relationshipsByName] objectForKey:@"RKHuman"];
    assertThat(humanRelationship, is(notNilValue()));
    NSRelationshipDescription *catRelationship = [[searchWordEntity relationshipsByName] objectForKey:@"RKCat"];
    assertThat(catRelationship, is(notNilValue()));
}

- (void)testIndexingManagedObject
{
    NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:[NSBundle allBundles]];
    NSEntityDescription *entity = [[managedObjectModel entitiesByName] objectForKey:@"RKHuman"];
    [RKSearchIndexer addSearchIndexingToEntity:entity onAttributes:@[ @"name", @"nickName" ]];
    
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
    NSError *error;
    [persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:&error];
    NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator;
        
    RKSearchIndexer *indexer = [RKSearchIndexer new];
    indexer.stopWords = [NSSet setWithObject:@"is"];
    NSManagedObject *human = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectContext];
    [human setValue:@"This is my name" forKey:@"name"];
    
    NSUInteger count = [indexer indexManagedObject:human];
    assertThatInteger(count, is(equalToInteger(3)));
    NSSet *searchWords = [human valueForKey:RKSearchWordsRelationshipName];
    
    assertThat([searchWords valueForKey:@"word"],
               is(equalTo([NSSet setWithArray:@[ @"this", @"my", @"name" ]])));
}

- (void)testIndexingOnManagedObjectContextSave
{
    NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:[NSBundle allBundles]];
    NSEntityDescription *entity = [[managedObjectModel entitiesByName] objectForKey:@"RKHuman"];
    [RKSearchIndexer addSearchIndexingToEntity:entity onAttributes:@[ @"name", @"nickName" ]];
    
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
    NSError *error;
    [persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:&error];
    NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator;
    
    RKSearchIndexer *indexer = [RKSearchIndexer new];
    indexer.stopWords = [NSSet setWithObject:@"is"];
    NSManagedObject *human = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectContext];
    [human setValue:@"This is my name" forKey:@"name"];
    
    // Index on save
    [indexer startObservingManagedObjectContext:managedObjectContext];
    [managedObjectContext save:&error];
    
    NSSet *searchWords = [human valueForKey:RKSearchWordsRelationshipName];
    assertThat([searchWords valueForKey:@"word"],
               is(equalTo([NSSet setWithArray:@[ @"this", @"my", @"name" ]])));
    
    [indexer stopObservingManagedObjectContext:managedObjectContext];
    [indexer release];
    [managedObjectContext release];
    [persistentStoreCoordinator release];
}

- (void)testIndexingChangesInManagedObjectContextWithoutSave
{
    NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:[NSBundle allBundles]];
    NSEntityDescription *entity = [[managedObjectModel entitiesByName] objectForKey:@"RKHuman"];
    [RKSearchIndexer addSearchIndexingToEntity:entity onAttributes:@[ @"name", @"nickName" ]];
    
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
    NSError *error;
    [persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:&error];
    NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator;
    
    RKSearchIndexer *indexer = [RKSearchIndexer new];
    indexer.stopWords = [NSSet setWithObject:@"is"];
    NSManagedObject *human = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectContext];
    [human setValue:@"This is my name" forKey:@"name"];
    
    // Index the current changes
    [indexer indexChangedObjectsInManagedObjectContext:managedObjectContext];
    
    NSSet *searchWords = [human valueForKey:RKSearchWordsRelationshipName];
    assertThat([searchWords valueForKey:@"word"],
               is(equalTo([NSSet setWithArray:@[ @"this", @"my", @"name" ]])));
    
    [indexer release];
    [managedObjectContext release];
    [persistentStoreCoordinator release];
}

@end
