//
//  RKEntityCacheTest.m
//  RestKit
//
//  Created by Blake Watters on 5/2/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKEntityCache.h"
#import "RKEntityByAttributeCache.h"
#import "RKHuman.h"

@interface RKEntityCacheTest : RKTestCase
@property (nonatomic, strong) RKManagedObjectStore *managedObjectStore;
@property (nonatomic, strong) RKEntityCache *cache;
@property (nonatomic, strong) NSEntityDescription *entity;
@end

@implementation RKEntityCacheTest

@synthesize managedObjectStore = _managedObjectStore;
@synthesize cache = _cache;
@synthesize entity = _entity;

- (void)setUp
{
    [RKTestFactory setUp];

    self.managedObjectStore = [RKTestFactory managedObjectStore];
    _cache = [[RKEntityCache alloc] initWithManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    self.entity = [NSEntityDescription entityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
}

- (void)tearDown
{
    self.managedObjectStore = nil;
    self.cache = nil;

    [RKTestFactory tearDown];
}

- (void)testInitializationSetsManagedObjectContext
{
    assertThat(_cache.managedObjectContext, is(equalTo(self.managedObjectStore.persistentStoreManagedObjectContext)));
}

- (void)testIsEntityCachedByAttribute
{
    assertThatBool([_cache isEntity:self.entity cachedByAttributes:@[ @"railsID" ]], is(equalToBool(NO)));
    [_cache cacheObjectsForEntity:self.entity byAttributes:@[ @"railsID" ]];
    assertThatBool([_cache isEntity:self.entity cachedByAttributes:@[ @"railsID" ]], is(equalToBool(YES)));
}

- (void)testRetrievalOfUnderlyingEntityAttributeCache
{
    [_cache cacheObjectsForEntity:self.entity byAttributes:@[ @"railsID" ]];
    RKEntityByAttributeCache *attributeCache = [_cache attributeCacheForEntity:self.entity attributes:@[  @"railsID" ]];
    assertThat(attributeCache, is(notNilValue()));
}

- (void)testRetrievalOfUnderlyingEntityAttributeCaches
{
    [_cache cacheObjectsForEntity:self.entity byAttributes:@[ @"railsID" ]];
    NSArray *caches = [_cache attributeCachesForEntity:self.entity];
    assertThat(caches, is(notNilValue()));
    assertThatInteger([caches count], is(equalToInteger(1)));
}

- (void)testRetrievalOfObjectForEntityWithAttributeValue
{
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human.railsID = [NSNumber numberWithInteger:12345];
    NSError *error = nil;
    [self.managedObjectStore.persistentStoreManagedObjectContext save:&error];

    [_cache cacheObjectsForEntity:self.entity byAttributes:@[ @"railsID" ]];
    NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    childContext.parentContext = self.managedObjectStore.persistentStoreManagedObjectContext;
    NSManagedObject *fetchedObject = [self.cache objectForEntity:self.entity withAttributeValues:@{ @"railsID": @(12345) } inContext:childContext];
    assertThat(fetchedObject, is(notNilValue()));
}

- (void)testRetrievalOfObjectsForEntityWithAttributeValue
{
    RKHuman *human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    RKHuman *human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human2.railsID = [NSNumber numberWithInteger:12345];
    NSError *error = nil;
    [self.managedObjectStore.persistentStoreManagedObjectContext save:&error];

    [_cache cacheObjectsForEntity:self.entity byAttributes:@[ @"railsID" ]];
    NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    childContext.parentContext = self.managedObjectStore.persistentStoreManagedObjectContext;
    NSSet *objects = [self.cache objectsForEntity:self.entity withAttributeValues:@{ @"railsID": @(12345) } inContext:childContext];
    assertThat(objects, hasCountOf(2));
    assertThat([objects valueForKey:@"objectID"], containsInAnyOrder(human1.objectID, human2.objectID, nil));
}

- (void)testThatFlushEmptiesAllUnderlyingAttributeCaches
{
    RKHuman *human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    human1.name = @"Blake";
    RKHuman *human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human2.railsID = [NSNumber numberWithInteger:12345];
    human2.name = @"Sarah";

    [self.managedObjectStore.persistentStoreManagedObjectContext save:nil];
    [_cache cacheObjectsForEntity:self.entity byAttributes:@[ @"railsID" ]];
    [_cache cacheObjectsForEntity:self.entity byAttributes:@[ @"name" ]];
    
    NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    childContext.parentContext = self.managedObjectStore.persistentStoreManagedObjectContext;

    NSSet *objects = [self.cache objectsForEntity:self.entity withAttributeValues:@{ @"railsID": @(12345) } inContext:childContext];
    assertThat(objects, hasCountOf(2));
    assertThat([objects valueForKey:@"objectID"], containsInAnyOrder(human1.objectID, human2.objectID, nil));

    objects = [self.cache objectsForEntity:self.entity withAttributeValues:@{ @"name": @"Blake" } inContext:childContext];
    assertThat(objects, hasCountOf(1));
    assertThat([objects valueForKey:@"objectID"], contains(human1.objectID, nil));

    [self.cache flush];
    objects = [self.cache objectsForEntity:self.entity withAttributeValues:@{ @"railsID": @(12345) } inContext:childContext];
    assertThat(objects, is(empty()));
    objects = [self.cache objectsForEntity:self.entity withAttributeValues:@{ @"name": @"Blake" } inContext:childContext];
    assertThat(objects, is(empty()));
}

- (void)testAddingObjectAddsToEachUnderlyingEntityAttributeCaches
{
    [_cache cacheObjectsForEntity:self.entity byAttributes:@[ @"railsID" ]];
    [_cache cacheObjectsForEntity:self.entity byAttributes:@[ @"name" ]];

    RKHuman *human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    human1.name = @"Blake";
    RKHuman *human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human2.railsID = [NSNumber numberWithInteger:12345];
    human2.name = @"Sarah";
    
    __block NSError *error;
    __block BOOL success;
    [self.managedObjectStore.persistentStoreManagedObjectContext performBlockAndWait:^{
        success = [self.managedObjectStore.persistentStoreManagedObjectContext save:&error];
    }];
    assertThatBool(success, is(equalToBool(YES)));
    
    [_cache addObject:human1];
    [_cache addObject:human2];
    
    NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    childContext.parentContext = self.managedObjectStore.persistentStoreManagedObjectContext;

    NSSet *objects = [self.cache objectsForEntity:self.entity withAttributeValues:@{ @"railsID": @(12345) } inContext:childContext];
    assertThat(objects, hasCountOf(2));
    assertThat([objects valueForKey:@"objectID"], containsInAnyOrder(human1.objectID, human2.objectID, nil));

    objects = [self.cache objectsForEntity:self.entity withAttributeValues:@{ @"name": @"Blake" } inContext:childContext];
    assertThat(objects, hasCountOf(1));
    assertThat([objects  valueForKey:@"objectID"], contains(human1.objectID, nil));
}

- (void)testRemovingObjectRemovesFromUnderlyingEntityAttributeCaches
{
    [_cache cacheObjectsForEntity:self.entity byAttributes:@[ @"railsID" ]];
    [_cache cacheObjectsForEntity:self.entity byAttributes:@[ @"name" ]];

    RKHuman *human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human1.railsID = [NSNumber numberWithInteger:12345];
    human1.name = @"Blake";
    RKHuman *human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human2.railsID = [NSNumber numberWithInteger:12345];
    human2.name = @"Sarah";
    
    __block NSError *error;
    __block BOOL success;
    [self.managedObjectStore.persistentStoreManagedObjectContext performBlockAndWait:^{
        success = [self.managedObjectStore.persistentStoreManagedObjectContext save:&error];
    }];
    assertThatBool(success, is(equalToBool(YES)));
    
    [_cache addObject:human1];
    [_cache addObject:human2];
    
    NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    childContext.parentContext = self.managedObjectStore.persistentStoreManagedObjectContext;

    NSSet *objects = [self.cache objectsForEntity:self.entity withAttributeValues:@{ @"railsID": @(12345) } inContext:childContext];
    assertThat(objects, hasCountOf(2));
    assertThat([objects valueForKey:@"objectID"], containsInAnyOrder(human1.objectID, human2.objectID, nil));

    RKEntityByAttributeCache *entityAttributeCache = [self.cache attributeCacheForEntity:self.entity attributes:@[ @"railsID" ]];
    assertThatBool([entityAttributeCache containsObject:human1], is(equalToBool(YES)));
    [self.cache removeObject:human1];
    assertThatBool([entityAttributeCache containsObject:human1], is(equalToBool(NO)));
}

@end
