//
//  RKEntityByAttributeCacheTest.m
//  RestKit
//
//  Created by Blake Watters on 5/1/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "NSEntityDescription+RKAdditions.h"
#import "RKEntityByAttributeCache.h"
#import "RKHuman.h"
#import "RKChild.h"

@interface RKEntityByAttributeCacheTest : RKTestCase
@property (nonatomic, retain) RKManagedObjectStore *objectStore;
@property (nonatomic, retain) RKEntityByAttributeCache *cache;
@end

@implementation RKEntityByAttributeCacheTest

@synthesize objectStore = _objectStore;
@synthesize cache = _cache;

- (void)setUp
{
    [RKTestFactory setUp];
    self.objectStore = [RKTestFactory managedObjectStore];

    NSEntityDescription *entity = [RKHuman entityDescriptionInContext:self.objectStore.primaryManagedObjectContext];
    self.cache = [[RKEntityByAttributeCache alloc] initWithEntity:entity
                                                              attribute:@"railsID"
                                                   managedObjectContext:self.objectStore.primaryManagedObjectContext];
    // Disable cache monitoring. Tested in specific cases.
    self.cache.monitorsContextForChanges = NO;
}

- (void)tearDown
{
    self.objectStore = nil;
    [RKTestFactory tearDown];
}

#pragma mark - Identity Tests

- (void)testEntityIsAssigned
{
    NSEntityDescription *entity = [RKHuman entityDescriptionInContext:self.objectStore.primaryManagedObjectContext];
    assertThat(self.cache.entity, is(equalTo(entity)));
}

- (void)testManagedObjectContextIsAssigned
{
    NSManagedObjectContext *context = self.objectStore.primaryManagedObjectContext;
    assertThat(self.cache.managedObjectContext, is(equalTo(context)));
}

- (void)testAttributeNameIsAssigned
{
    assertThat(self.cache.attribute, is(equalTo(@"railsID")));
}

#pragma mark - Loading and Flushing

- (void)testLoadSetsLoadedToYes
{
    [self.cache load];
    assertThatBool(self.cache.isLoaded, is(equalToBool(YES)));
}

- (void)testLoadSetsCountAppropriately
{
    RKHuman *human = [RKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human.railsID = [NSNumber numberWithInteger:12345];
    NSError *error = nil;
    [self.objectStore save:&error];

    assertThat(error, is(nilValue()));
    [self.cache load];
    assertThatInteger([self.cache count], is(equalToInteger(1)));
}

- (void)testFlushCacheRemovesObjects
{
    RKHuman *human1 = [RKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    RKHuman *human2 = [RKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human2.railsID = [NSNumber numberWithInteger:12345];
    [self.objectStore save:nil];

    [self.cache addObject:human1];
    [self.cache addObject:human2];
    [self.cache flush];
    assertThatBool([self.cache containsObject:human1], is(equalToBool(NO)));
    assertThatBool([self.cache containsObject:human2], is(equalToBool(NO)));
}

- (void)testFlushCacheReturnsCountToZero
{
    RKHuman *human1 = [RKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    RKHuman *human2 = [RKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human2.railsID = [NSNumber numberWithInteger:12345];
    [self.objectStore save:nil];

    [self.cache addObject:human1];
    [self.cache addObject:human2];
    [self.cache flush];
    assertThatInteger([self.cache count], is(equalToInteger(0)));
}

#pragma mark - Retrieving Objects

- (void)testRetrievalByNumericValue
{
    RKHuman *human = [RKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human.railsID = [NSNumber numberWithInteger:12345];
    [self.objectStore save:nil];
    [self.cache load];

    NSManagedObject *object = [self.cache objectWithAttributeValue:[NSNumber numberWithInteger:12345]];
    assertThat(object, is(equalTo(human)));
}

- (void)testRetrievalOfNumericPropertyByStringValue
{
    RKHuman *human = [RKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human.railsID = [NSNumber numberWithInteger:12345];
    [self.objectStore save:nil];
    [self.cache load];

    NSManagedObject *object = [self.cache objectWithAttributeValue:@"12345"];
    assertThat(object, is(notNilValue()));
    assertThat(object, is(equalTo(human)));
}

- (void)testRetrievalOfObjectsWithAttributeValue
{
    RKHuman *human1 = [RKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    RKHuman *human2 = [RKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human2.railsID = [NSNumber numberWithInteger:12345];
    [self.objectStore save:nil];

    [self.cache addObject:human1];
    [self.cache addObject:human2];

    NSArray *objects = [self.cache objectsWithAttributeValue:[NSNumber numberWithInt:12345]];
    assertThat(objects, hasCountOf(2));
    assertThat([objects objectAtIndex:0], is(instanceOf([NSManagedObject class])));
}

- (void)testAddingObjectToCache
{
    RKHuman *human = [RKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human.railsID = [NSNumber numberWithInteger:12345];
    [self.objectStore save:nil];

    [self.cache addObject:human];
    assertThatBool([self.cache containsObject:human], is(equalToBool(YES)));
}

- (void)testAddingObjectWithDuplicateAttributeValue
{
    RKHuman *human1 = [RKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    RKHuman *human2 = [RKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human2.railsID = [NSNumber numberWithInteger:12345];
    [self.objectStore save:nil];

    [self.cache addObject:human1];
    [self.cache addObject:human2];
    assertThatBool([self.cache containsObject:human1], is(equalToBool(YES)));
    assertThatBool([self.cache containsObject:human2], is(equalToBool(YES)));
}

- (void)testRemovingObjectFromCache
{
    RKHuman *human = [RKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human.railsID = [NSNumber numberWithInteger:12345];
    [self.objectStore save:nil];

    [self.cache addObject:human];
    assertThatBool([self.cache containsObject:human], is(equalToBool(YES)));
    [self.cache removeObject:human];
    assertThatBool([self.cache containsObject:human], is(equalToBool(NO)));
}

- (void)testRemovingObjectWithExistingAttributeValue
{
    RKHuman *human1 = [RKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    RKHuman *human2 = [RKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human2.railsID = [NSNumber numberWithInteger:12345];
    [self.objectStore save:nil];

    [self.cache addObject:human1];
    [self.cache addObject:human2];
    assertThatBool([self.cache containsObject:human1], is(equalToBool(YES)));
    assertThatBool([self.cache containsObject:human2], is(equalToBool(YES)));
    [self.cache removeObject:human1];
    assertThatBool([self.cache containsObject:human1], is(equalToBool(NO)));
    assertThatBool([self.cache containsObject:human2], is(equalToBool(YES)));
}

#pragma mark - Inspecting Cache State

- (void)testContainsObjectReturnsNoForDifferingEntities
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RKCloud" inManagedObjectContext:self.objectStore.primaryManagedObjectContext];
    NSManagedObject *cloud = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:self.objectStore.primaryManagedObjectContext];
    assertThatBool([self.cache containsObject:cloud], is(equalToBool(NO)));
}

- (void)testContainsObjectReturnsNoForSubEntities
{
    RKHuman *human = [RKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human.railsID = [NSNumber numberWithInteger:12345];
    RKChild *child = [RKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    child.railsID = [NSNumber numberWithInteger:12345];

    [self.cache addObject:human];
    assertThatBool([self.cache containsObject:human], is(equalToBool(YES)));
    assertThatBool([self.cache containsObject:child], is(equalToBool(NO)));
}

- (void)testContainsObjectWithAttributeValue
{
    RKHuman *human = [RKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human.railsID = [NSNumber numberWithInteger:12345];
    [self.objectStore save:nil];

    [self.cache addObject:human];
    assertThatBool([self.cache containsObjectWithAttributeValue:[NSNumber numberWithInteger:12345]], is(equalToBool(YES)));
}

- (void)testCount
{
    RKHuman *human1 = [RKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    RKHuman *human2 = [RKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human2.railsID = [NSNumber numberWithInteger:12345];
    RKHuman *human3 = [RKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human3.railsID = [NSNumber numberWithInteger:123456];
    [self.objectStore save:nil];

    [self.cache addObject:human1];
    [self.cache addObject:human2];
    [self.cache addObject:human3];
    assertThatInteger([self.cache count], is(equalToInteger(3)));
}

- (void)testCountOfAttributeValues
{
    RKHuman *human1 = [RKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    RKHuman *human2 = [RKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human2.railsID = [NSNumber numberWithInteger:12345];
    RKHuman *human3 = [RKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human3.railsID = [NSNumber numberWithInteger:123456];
    [self.objectStore save:nil];

    [self.cache addObject:human1];
    [self.cache addObject:human2];
    [self.cache addObject:human3];
    assertThatInteger([self.cache countOfAttributeValues], is(equalToInteger(2)));
}

- (void)testCountWithAttributeValue
{
    RKHuman *human1 = [RKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    RKHuman *human2 = [RKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human2.railsID = [NSNumber numberWithInteger:12345];
    [self.objectStore save:nil];

    [self.cache addObject:human1];
    [self.cache addObject:human2];
    assertThatInteger([self.cache countWithAttributeValue:[NSNumber numberWithInteger:12345]], is(equalToInteger(2)));
}

- (void)testThatUnloadedCacheReturnsCountOfZero
{
    assertThatInteger([self.cache count], is(equalToInteger(0)));
}

#pragma mark - Lifecycle Events

- (void)testManagedObjectContextProcessPendingChangesAddsNewObjectsToCache
{
    self.cache.monitorsContextForChanges = YES;
    RKHuman *human1 = [RKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    [self.objectStore.primaryManagedObjectContext processPendingChanges];
    assertThatBool([self.cache containsObject:human1], is(equalToBool(YES)));
}

- (void)testManagedObjectContextProcessPendingChangesIgnoresObjectsOfDifferentEntityTypes
{
    self.cache.monitorsContextForChanges = YES;
    RKHuman *human1 = [RKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RKCloud" inManagedObjectContext:self.objectStore.primaryManagedObjectContext];
    NSManagedObject *cloud = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:self.objectStore.primaryManagedObjectContext];
    [cloud setValue:@"Cumulus" forKey:@"name"];

    [self.objectStore.primaryManagedObjectContext processPendingChanges];
    assertThatBool([self.cache containsObject:human1], is(equalToBool(YES)));
    assertThatBool([self.cache containsObject:cloud], is(equalToBool(NO)));
}

- (void)testManagedObjectContextProcessPendingChangesAddsUpdatedObjectsToCache
{
    self.cache.monitorsContextForChanges = YES;
    RKHuman *human1 = [RKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    [self.objectStore.primaryManagedObjectContext processPendingChanges];
    assertThatBool([self.cache containsObject:human1], is(equalToBool(YES)));
    [self.cache removeObject:human1];
    human1.name = @"Modified Name";
    assertThatBool([self.cache containsObject:human1], is(equalToBool(NO)));
    [self.objectStore.primaryManagedObjectContext processPendingChanges];
    assertThatBool([self.cache containsObject:human1], is(equalToBool(YES)));
}

- (void)testManagedObjectContextProcessPendingChangesRemovesExistingObjectsFromCache
{
    self.cache.monitorsContextForChanges = YES;
    RKHuman *human1 = [RKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    [self.objectStore.primaryManagedObjectContext processPendingChanges];
    assertThatBool([self.cache containsObject:human1], is(equalToBool(YES)));
    [self.objectStore.primaryManagedObjectContext deleteObject:human1];
    [self.objectStore.primaryManagedObjectContext processPendingChanges];
    assertThatBool([self.cache containsObject:human1], is(equalToBool(NO)));
}

#if TARGET_OS_IPHONE
- (void)testCacheIsFlushedOnMemoryWarning
{
    RKHuman *human1 = [RKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    RKHuman *human2 = [RKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human2.railsID = [NSNumber numberWithInteger:12345];
    [self.objectStore save:nil];

    [self.cache addObject:human1];
    [self.cache addObject:human2];
    assertThatBool([self.cache containsObject:human1], is(equalToBool(YES)));
    assertThatBool([self.cache containsObject:human2], is(equalToBool(YES)));
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidReceiveMemoryWarningNotification object:self];
}
#endif

- (void)testCreatingProcessingAndDeletingObjectsWorksAsExpected
{
    self.cache.monitorsContextForChanges = YES;

    RKHuman *human1 = [RKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    RKHuman *human2 = [RKHuman createInContext:self.objectStore.primaryManagedObjectContext];
    human2.railsID = [NSNumber numberWithInteger:12345];
    [self.objectStore.primaryManagedObjectContext processPendingChanges];

    assertThatBool([self.cache containsObject:human1], is(equalToBool(YES)));
    assertThatBool([self.cache containsObject:human2], is(equalToBool(YES)));
    [self.objectStore.primaryManagedObjectContext deleteObject:human2];

    // Save and reload the cache. This will result in the cached temporary
    // object ID's being released during the cache flush.
    [self.objectStore.primaryManagedObjectContext save:nil];
    [self.cache load];

    assertThatBool([self.cache containsObject:human1], is(equalToBool(YES)));
    assertThatBool([self.cache containsObject:human2], is(equalToBool(NO)));
}

@end
