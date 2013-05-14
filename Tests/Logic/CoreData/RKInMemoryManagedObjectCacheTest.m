//
//  RKInMemoryManagedObjectCacheTest.m
//  RestKit
//
//  Created by Blake Watters on 4/30/13.
//  Copyright (c) 2013 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKInMemoryManagedObjectCache.h"
#import "RKHuman.h"
#import "RKEntityCache.h"

@interface RKInMemoryManagedObjectCache ()
@property (nonatomic, readonly) RKEntityCache *entityCache;
@end

@interface RKInMemoryManagedObjectCacheTest : RKTestCase
@property (nonatomic, strong) RKManagedObjectStore *managedObjectStore;
@property (nonatomic, strong) RKInMemoryManagedObjectCache *managedObjectCache;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSEntityDescription *humanEntity;
@end

@implementation RKInMemoryManagedObjectCacheTest

- (void)setUp
{
    [RKTestFactory setUp];
    self.managedObjectStore = [RKTestFactory managedObjectStore];
    self.managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    
    self.managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [self.managedObjectContext setParentContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    self.humanEntity = [self.managedObjectStore.managedObjectModel entitiesByName][@"Human"];
    NSSet __unused *objects = [self.managedObjectCache managedObjectsWithEntity:self.humanEntity attributeValues:@{ @"railsID": @12345 } inManagedObjectContext:self.managedObjectContext];
}

- (void)tearDown
{
    [RKTestFactory tearDown];
}

- (void)waitForPendingChangesToProcess
{
    [self.managedObjectStore.persistentStoreManagedObjectContext processPendingChanges];
    __block BOOL processingComplete = NO;
    [self.managedObjectStore.persistentStoreManagedObjectContext performBlock:^{
        // As soon as we make it onto the context, the notification has been processed
        processingComplete = YES;
    }];
    expect(processingComplete).will.beTruthy();
}

- (void)testManagedObjectContextProcessPendingChangesAddsNewObjectsToCache
{
    RKHuman *human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    [self waitForPendingChangesToProcess];
    NSSet *objects = [self.managedObjectCache managedObjectsWithEntity:self.humanEntity attributeValues:@{ @"railsID": @12345 } inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    expect([objects containsObject:human1]).will.equal(YES);
}

- (void)testManagedObjectContextProcessPendingChangesIgnoresObjectsOfDifferentEntityTypes
{
    RKHuman *human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Cloud" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    NSManagedObject *cloud = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    [cloud setValue:@"Cumulus" forKey:@"name"];
    
    [self waitForPendingChangesToProcess];
    expect([self.managedObjectCache.entityCache containsObject:human1]).will.equal(YES);
    expect([self.managedObjectCache.entityCache containsObject:cloud]).will.equal(NO);
}

- (void)testManagedObjectContextProcessPendingChangesAddsUpdatedObjectsToCache
{
    RKHuman *human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    [self waitForPendingChangesToProcess];
    
    expect([self.managedObjectCache.entityCache containsObject:human1]).will.equal(YES);
    __block BOOL done = NO;
    [self.managedObjectCache.entityCache removeObjects:[NSSet setWithObject:human1] completion:^{
        done = YES;
    }];
    expect(done).will.equal(YES);
    human1.name = @"Modified Name";
    expect([self.managedObjectCache.entityCache containsObject:human1]).will.equal(NO);
    [self waitForPendingChangesToProcess];
    expect([self.managedObjectCache.entityCache containsObject:human1]).will.equal(YES);
}

- (void)testManagedObjectContextProcessPendingChangesRemovesExistingObjectsFromCache
{
    // PENDING: This test is brittle when run in the full suite
    return;
    RKHuman *human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    [self waitForPendingChangesToProcess];
    expect([self.managedObjectCache.entityCache containsObject:human1]).will.beTruthy();
    [self.managedObjectStore.persistentStoreManagedObjectContext deleteObject:human1];
    [self waitForPendingChangesToProcess];
    [self.managedObjectStore.persistentStoreManagedObjectContext performBlockAndWait:^{
        // Nothing
    }];
    expect([self.managedObjectCache.entityCache containsObject:human1]).will.beFalsy();
}

- (void)testCreatingProcessingAndDeletingObjectsWorksAsExpected
{
    RKHuman *human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    RKHuman *human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human2.railsID = [NSNumber numberWithInteger:12345];
    [self waitForPendingChangesToProcess];
    
    expect([self.managedObjectCache.entityCache containsObject:human1]).will.equal(YES);
    expect([self.managedObjectCache.entityCache containsObject:human2]).will.equal(YES);
    [self.managedObjectStore.persistentStoreManagedObjectContext deleteObject:human2];
    
    // Save and reload the cache. This will result in the cached temporary
    // object ID's being released during the cache flush.
    [self.managedObjectStore.persistentStoreManagedObjectContext save:nil];
    [self waitForPendingChangesToProcess];
    [self.managedObjectCache.entityCache cacheObjectsForEntity:self.humanEntity byAttributes:@[ @"railsID" ] completion:^{
        expect([self.managedObjectCache.entityCache containsObject:human1]).will.equal(YES);
        expect([self.managedObjectCache.entityCache containsObject:human2]).will.equal(NO);
    }];
}

@end
