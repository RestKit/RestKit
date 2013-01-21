//
//  RKEntityByAttributeCacheTest.m
//  RestKit
//
//  Created by Blake Watters on 5/1/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKEntityByAttributeCache.h"
#import "RKHuman.h"
#import "RKChild.h"

@interface RKEntityByAttributeCacheTest : RKTestCase
@property (nonatomic, strong) RKManagedObjectStore *managedObjectStore;
@property (weak, nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) RKEntityByAttributeCache *cache;
@end

@implementation RKEntityByAttributeCacheTest

@synthesize managedObjectStore = _managedObjectStore;
@synthesize cache = _cache;

- (void)setUp
{
    [RKTestFactory setUp];
    self.managedObjectStore = [RKTestFactory managedObjectStore];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Human" inManagedObjectContext:self.managedObjectContext];
    self.cache = [[RKEntityByAttributeCache alloc] initWithEntity:entity
                                                       attributes:@[ @"railsID" ]
                                                   managedObjectContext:self.managedObjectContext];
    // Disable cache monitoring. Tested in specific cases.
    self.cache.monitorsContextForChanges = NO;
}

- (void)tearDown
{
    self.managedObjectStore = nil;
    [RKTestFactory tearDown];
}

- (NSManagedObjectContext *)managedObjectContext
{
    return self.managedObjectStore.persistentStoreManagedObjectContext;
}

#pragma mark - Identity Tests

- (void)testEntityIsAssigned
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Human" inManagedObjectContext:self.managedObjectContext];
    assertThat(self.cache.entity, is(equalTo(entity)));
}

- (void)testManagedObjectContextIsAssigned
{
    assertThat(self.cache.managedObjectContext, is(equalTo(self.managedObjectContext)));
}

- (void)testAttributeNameIsAssigned
{
    assertThat(self.cache.attributes, is(equalTo(@[ @"railsID" ])));
}

#pragma mark - Loading and Flushing

- (void)testLoadSetsLoadedToYes
{
    [self.cache load];
    assertThatBool(self.cache.isLoaded, is(equalToBool(YES)));
}

- (void)testLoadSetsCountAppropriately
{
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectContext];
    human.railsID = [NSNumber numberWithInteger:12345];
    NSError *error = nil;
    [self.managedObjectContext save:&error];

    assertThat(error, is(nilValue()));
    [self.cache load];
    assertThatInteger([self.cache count], is(equalToInteger(1)));
}

- (void)testFlushCacheRemovesObjects
{
    RKHuman *human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    RKHuman *human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human2.railsID = [NSNumber numberWithInteger:12345];
    [self.managedObjectStore.persistentStoreManagedObjectContext save:nil];

    [self.cache addObject:human1];
    [self.cache addObject:human2];
    [self.cache flush];
    assertThatBool([self.cache containsObject:human1], is(equalToBool(NO)));
    assertThatBool([self.cache containsObject:human2], is(equalToBool(NO)));
}

- (void)testFlushCacheReturnsCountToZero
{
    RKHuman *human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    RKHuman *human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human2.railsID = [NSNumber numberWithInteger:12345];
    [self.managedObjectStore.persistentStoreManagedObjectContext save:nil];

    [self.cache addObject:human1];
    [self.cache addObject:human2];
    [self.cache flush];
    assertThatInteger([self.cache count], is(equalToInteger(0)));
}

#pragma mark - Retrieving Objects

- (void)testRetrievalByNumericValue
{
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human.railsID = [NSNumber numberWithInteger:12345];
    [self.managedObjectStore.persistentStoreManagedObjectContext save:nil];
    [self.cache load];

    NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    childContext.parentContext = self.managedObjectContext;
    NSManagedObject *object = [self.cache objectWithAttributeValues:@{ @"railsID": @12345 } inContext:childContext];
    assertThat(object.objectID, is(equalTo(human.objectID)));
}

- (void)testRetrievalOfNumericPropertyByStringValue
{
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human.railsID = [NSNumber numberWithInteger:12345];
    [self.managedObjectStore.persistentStoreManagedObjectContext save:nil];
    [self.cache load];

    NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    childContext.parentContext = self.managedObjectContext;
    NSManagedObject *object = [self.cache objectWithAttributeValues:@{ @"railsID": @"12345" } inContext:childContext];
    assertThat(object, is(notNilValue()));
    assertThat(object.objectID, is(equalTo(human.objectID)));
}

- (void)testRetrievalOfObjectsWithAttributeValue
{
    RKHuman *human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    RKHuman *human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human2.railsID = [NSNumber numberWithInteger:12345];
    [self.managedObjectStore.persistentStoreManagedObjectContext save:nil];

    [self.cache addObject:human1];
    [self.cache addObject:human2];

    NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    childContext.parentContext = self.managedObjectContext;
    NSSet *objects = [self.cache objectsWithAttributeValues:@{ @"railsID": @(12345) } inContext:childContext];
    assertThat(objects, hasCountOf(2));
    assertThat([objects anyObject], is(instanceOf([NSManagedObject class])));
}

- (void)testRetrievalOfObjectsWithCollectionAttributeValue
{
    RKHuman *human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    RKHuman *human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human2.railsID = [NSNumber numberWithInteger:5678];
    [self.managedObjectStore.persistentStoreManagedObjectContext save:nil];

    [self.cache addObject:human1];
    [self.cache addObject:human2];

    NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    childContext.parentContext = self.managedObjectContext;
    NSSet *objects = [self.cache objectsWithAttributeValues:@{ @"railsID": @[ @(12345), @(5678) ] } inContext:childContext];
    assertThat(objects, hasCountOf(2));
    assertThat([objects anyObject], is(instanceOf([NSManagedObject class])));
}

- (void)testRetrievalOfObjectsWithMoreThanOneCollectionAttributeValue
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Human" inManagedObjectContext:self.managedObjectContext];
    self.cache = [[RKEntityByAttributeCache alloc] initWithEntity:entity
                                                       attributes:@[ @"railsID", @"name" ]
                                             managedObjectContext:self.managedObjectContext];
    // Disable cache monitoring. Tested in specific cases.
    self.cache.monitorsContextForChanges = NO;

    RKHuman *human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    human1.name = @"Blake";
    RKHuman *human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human2.railsID = [NSNumber numberWithInteger:5678];
    human2.name = @"Jeff";
    RKHuman *human3 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human3.railsID = [NSNumber numberWithInteger:9999];
    human3.name = @"Blake";
    [self.managedObjectStore.persistentStoreManagedObjectContext save:nil];

    [self.cache addObject:human1];
    [self.cache addObject:human2];
    [self.cache addObject:human3];

    NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    childContext.parentContext = self.managedObjectContext;
    NSSet *objects = [self.cache objectsWithAttributeValues:@{ @"railsID": @[ @(12345), @(5678) ], @"name": @"Blake" } inContext:childContext];
    // should find human1
    assertThat(objects, hasCountOf(1));
    assertThat([objects anyObject], is(instanceOf([NSManagedObject class])));
    assertThat([[objects anyObject] objectID], equalTo([human1 objectID]));

    objects = [self.cache objectsWithAttributeValues:@{ @"railsID": @[ @(12345), @(9999) ], @"name": @"Blake" } inContext:childContext];
    // should be human1 and human3
    assertThat(objects, hasCountOf(2));
    assertThat([objects valueForKey:@"objectID"], hasItems([human1 objectID], [human3 objectID], nil));

    objects = [self.cache objectsWithAttributeValues:@{ @"railsID": @[ @(12345), @(9999) ], @"name": @[ @"Blake", @"Jeff" ] } inContext:childContext];
    // should be human1, human2 and human3
    assertThat(objects, hasCountOf(2));
    assertThat([objects valueForKey:@"objectID"], hasItems([human1 objectID], [human3 objectID], nil));

    objects = [self.cache objectsWithAttributeValues:@{ @"railsID": @[ @(31337), @(8888) ], @"name": @[ @"Blake", @"Jeff" ] } inContext:childContext];
    // should be none
    assertThat(objects, hasCountOf(0));
}

// Do this with 3 attributes, 2 that are arrays and 1 that is not
// check
// Test blowing up if you request objects without enough cache keys

- (void)testAddingObjectToCache
{
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human.railsID = [NSNumber numberWithInteger:12345];
    [self.managedObjectStore.persistentStoreManagedObjectContext save:nil];

    [self.cache addObject:human];
    assertThatBool([self.cache containsObject:human], is(equalToBool(YES)));
}

- (void)testAddingObjectWithDuplicateAttributeValue
{
    RKHuman *human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    RKHuman *human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human2.railsID = [NSNumber numberWithInteger:12345];
    [self.managedObjectStore.persistentStoreManagedObjectContext save:nil];

    [self.cache addObject:human1];
    [self.cache addObject:human2];
    assertThatBool([self.cache containsObject:human1], is(equalToBool(YES)));
    assertThatBool([self.cache containsObject:human2], is(equalToBool(YES)));
}

- (void)testRemovingObjectFromCache
{
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human.railsID = [NSNumber numberWithInteger:12345];
    [self.managedObjectStore.persistentStoreManagedObjectContext save:nil];

    [self.cache addObject:human];
    assertThatBool([self.cache containsObject:human], is(equalToBool(YES)));
    [self.cache removeObject:human];
    assertThatBool([self.cache containsObject:human], is(equalToBool(NO)));
}

- (void)testRemovingObjectWithExistingAttributeValue
{
    RKHuman *human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    RKHuman *human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human2.railsID = [NSNumber numberWithInteger:12345];
    [self.managedObjectStore.persistentStoreManagedObjectContext save:nil];

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
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Cloud" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    NSManagedObject *cloud = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    assertThatBool([self.cache containsObject:cloud], is(equalToBool(NO)));
}

- (void)testContainsObjectReturnsNoForSubEntities
{
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human.railsID = [NSNumber numberWithInteger:12345];
    RKChild *child = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    child.railsID = [NSNumber numberWithInteger:12345];

    [self.cache addObject:human];
    assertThatBool([self.cache containsObject:human], is(equalToBool(YES)));
    assertThatBool([self.cache containsObject:child], is(equalToBool(NO)));
}

- (void)testContainsObjectWithAttributeValue
{
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human.railsID = [NSNumber numberWithInteger:12345];
    [self.managedObjectStore.persistentStoreManagedObjectContext save:nil];

    [self.cache addObject:human];
    assertThatBool([self.cache containsObjectWithAttributeValues:@{ @"railsID": @(12345) }], is(equalToBool(YES)));
}

- (void)testCount
{
    RKHuman *human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    RKHuman *human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human2.railsID = [NSNumber numberWithInteger:12345];
    RKHuman *human3 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human3.railsID = [NSNumber numberWithInteger:123456];
    [self.managedObjectStore.persistentStoreManagedObjectContext save:nil];

    [self.cache addObject:human1];
    [self.cache addObject:human2];
    [self.cache addObject:human3];
    assertThatInteger([self.cache count], is(equalToInteger(3)));
}

- (void)testCountOfAttributeValues
{
    RKHuman *human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    RKHuman *human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human2.railsID = [NSNumber numberWithInteger:12345];
    RKHuman *human3 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human3.railsID = [NSNumber numberWithInteger:123456];
    [self.managedObjectStore.persistentStoreManagedObjectContext save:nil];

    [self.cache addObject:human1];
    [self.cache addObject:human2];
    [self.cache addObject:human3];
    assertThatInteger([self.cache countOfAttributeValues], is(equalToInteger(2)));
}

- (void)testCountWithAttributeValue
{
    RKHuman *human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    RKHuman *human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human2.railsID = [NSNumber numberWithInteger:12345];
    [self.managedObjectStore.persistentStoreManagedObjectContext save:nil];

    [self.cache addObject:human1];
    [self.cache addObject:human2];
    assertThatInteger([self.cache countWithAttributeValues:@{ @"railsID": @(12345) }], is(equalToInteger(2)));
}

- (void)testThatUnloadedCacheReturnsCountOfZero
{
    assertThatInteger([self.cache count], is(equalToInteger(0)));
}

#pragma mark - Lifecycle Events

- (void)testManagedObjectContextProcessPendingChangesAddsNewObjectsToCache
{
    self.cache.monitorsContextForChanges = YES;
    RKHuman *human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    [self.managedObjectStore.persistentStoreManagedObjectContext processPendingChanges];
    assertThatBool([self.cache containsObject:human1], is(equalToBool(YES)));
}

- (void)testManagedObjectContextProcessPendingChangesIgnoresObjectsOfDifferentEntityTypes
{
    self.cache.monitorsContextForChanges = YES;
    RKHuman *human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Cloud" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    NSManagedObject *cloud = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    [cloud setValue:@"Cumulus" forKey:@"name"];

    [self.managedObjectStore.persistentStoreManagedObjectContext processPendingChanges];
    assertThatBool([self.cache containsObject:human1], is(equalToBool(YES)));
    assertThatBool([self.cache containsObject:cloud], is(equalToBool(NO)));
}

- (void)testManagedObjectContextProcessPendingChangesAddsUpdatedObjectsToCache
{
    self.cache.monitorsContextForChanges = YES;
    RKHuman *human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    [self.managedObjectStore.persistentStoreManagedObjectContext processPendingChanges];
    assertThatBool([self.cache containsObject:human1], is(equalToBool(YES)));
    [self.cache removeObject:human1];
    human1.name = @"Modified Name";
    assertThatBool([self.cache containsObject:human1], is(equalToBool(NO)));
    [self.managedObjectStore.persistentStoreManagedObjectContext processPendingChanges];
    assertThatBool([self.cache containsObject:human1], is(equalToBool(YES)));
}

- (void)testManagedObjectContextProcessPendingChangesRemovesExistingObjectsFromCache
{
    self.cache.monitorsContextForChanges = YES;
    RKHuman *human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    [self.managedObjectStore.persistentStoreManagedObjectContext processPendingChanges];
    assertThatBool([self.cache containsObject:human1], is(equalToBool(YES)));
    [self.managedObjectStore.persistentStoreManagedObjectContext deleteObject:human1];
    [self.managedObjectStore.persistentStoreManagedObjectContext processPendingChanges];
    assertThatBool([self.cache containsObject:human1], is(equalToBool(NO)));
}

#if TARGET_OS_IPHONE
- (void)testCacheIsFlushedOnMemoryWarning
{
    RKHuman *human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    RKHuman *human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human2.railsID = [NSNumber numberWithInteger:12345];
    [self.managedObjectStore.persistentStoreManagedObjectContext save:nil];

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

    [self.managedObjectStore.persistentStoreManagedObjectContext performBlockAndWait:^{
        RKHuman *human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
        human1.railsID = [NSNumber numberWithInteger:12345];
        RKHuman *human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
        human2.railsID = [NSNumber numberWithInteger:12345];
        [self.managedObjectStore.persistentStoreManagedObjectContext processPendingChanges];

        assertThatBool([self.cache containsObject:human1], is(equalToBool(YES)));
        assertThatBool([self.cache containsObject:human2], is(equalToBool(YES)));
        [self.managedObjectStore.persistentStoreManagedObjectContext deleteObject:human2];

        // Save and reload the cache. This will result in the cached temporary
        // object ID's being released during the cache flush.
        [self.managedObjectStore.persistentStoreManagedObjectContext save:nil];
        [self.cache load];

        assertThatBool([self.cache containsObject:human1], is(equalToBool(YES)));
        assertThatBool([self.cache containsObject:human2], is(equalToBool(NO)));
    }];
}

#pragma mark - Compound Key Tests

// missing attributes
// padding nil
// trying to look-up by nil
// trying to lookup with empty dictionary
// using weird attribute types as cache keys

- (void)testEvictionOfArrayOfIdentifierAttributes
{
    // Put some objects into the cache
    // Delete them
    RKHuman *human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    RKHuman *human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectContext];
    human2.railsID = [NSNumber numberWithInteger:56789];
    [self.managedObjectContext save:nil];

    [self.cache addObject:human1];
    [self.cache addObject:human2];

    self.cache.monitorsContextForChanges = NO;

    NSDictionary *attributeValues = @{ @"railsID" : @[ human1.railsID, human2.railsID ] };

    [self.managedObjectContext deleteObject:human1];
    [self.managedObjectContext deleteObject:human2];
    [self.managedObjectContext save:nil];

    [self.cache objectsWithAttributeValues:attributeValues inContext:self.managedObjectContext];
}

@end
