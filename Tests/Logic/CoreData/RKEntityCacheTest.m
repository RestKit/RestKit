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
    __block BOOL done = NO;
    [_cache cacheObjectsForEntity:self.entity byAttributes:@[ @"railsID" ] completion:^{
        done = YES;
    }];
    expect(done).will.equal(YES);
    assertThatBool([_cache isEntity:self.entity cachedByAttributes:@[ @"railsID" ]], is(equalToBool(YES)));
}

- (void)testRetrievalOfUnderlyingEntityAttributeCache
{
    __block BOOL done = NO;
    [_cache cacheObjectsForEntity:self.entity byAttributes:@[ @"railsID" ] completion:^{
        done = YES;
    }];
    expect(done).will.equal(YES);
    RKEntityByAttributeCache *attributeCache = [_cache attributeCacheForEntity:self.entity attributes:@[  @"railsID" ]];
    assertThat(attributeCache, is(notNilValue()));
}

- (void)testRetrievalOfUnderlyingEntityAttributeCaches
{
    __block BOOL done = NO;
    [_cache cacheObjectsForEntity:self.entity byAttributes:@[ @"railsID" ] completion:^{
        done = YES;
    }];
    expect(done).will.equal(YES);
    NSArray *caches = [_cache attributeCachesForEntity:self.entity];
    assertThat(caches, is(notNilValue()));
    assertThatInteger([caches count], is(equalToInteger(1)));
}

- (void)testRetrievalOfObjectForEntityWithAttributeValue
{
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human.railsID = @12345;
    NSError *error = nil;
    [self.managedObjectStore.persistentStoreManagedObjectContext save:&error];

    __block BOOL done = NO;
    [_cache cacheObjectsForEntity:self.entity byAttributes:@[ @"railsID" ] completion:^{
        done = YES;
    }];
    expect(done).will.equal(YES);
    NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    childContext.parentContext = self.managedObjectStore.persistentStoreManagedObjectContext;
    NSManagedObject *fetchedObject = [self.cache objectForEntity:self.entity withAttributeValues:@{ @"railsID": @(12345) } inContext:childContext];
    assertThat(fetchedObject, is(notNilValue()));
}

- (void)testRetrievalOfObjectsForEntityWithAttributeValue
{
    RKHuman *human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human1.railsID = @12345;
    RKHuman *human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human2.railsID = @12345;
    NSError *error = nil;
    [self.managedObjectStore.persistentStoreManagedObjectContext save:&error];

    __block BOOL done = NO;
    [_cache cacheObjectsForEntity:self.entity byAttributes:@[ @"railsID" ] completion:^{
        done = YES;
    }];
    expect(done).will.equal(YES);
    NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    childContext.parentContext = self.managedObjectStore.persistentStoreManagedObjectContext;
    NSSet *objects = [self.cache objectsForEntity:self.entity withAttributeValues:@{ @"railsID": @(12345) } inContext:childContext];
    assertThat(objects, hasCountOf(2));
    assertThat([objects valueForKey:@"objectID"], containsInAnyOrder(human1.objectID, human2.objectID, nil));
}

- (void)testThatFlushEmptiesAllUnderlyingAttributeCaches
{
    RKHuman *human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human1.railsID = @12345;
    human1.name = @"Blake";
    RKHuman *human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human2.railsID = @12345;
    human2.name = @"Sarah";

    __block BOOL done = NO;
    [self.managedObjectStore.persistentStoreManagedObjectContext save:nil];
    [_cache cacheObjectsForEntity:self.entity byAttributes:@[ @"railsID" ] completion:nil];
    [_cache cacheObjectsForEntity:self.entity byAttributes:@[ @"name" ] completion:^{
        done = YES;
    }];
    expect(done).will.equal(YES);
    
    NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    childContext.parentContext = self.managedObjectStore.persistentStoreManagedObjectContext;

    NSSet *objects = [self.cache objectsForEntity:self.entity withAttributeValues:@{ @"railsID": @(12345) } inContext:childContext];
    assertThat(objects, hasCountOf(2));
    assertThat([objects valueForKey:@"objectID"], containsInAnyOrder(human1.objectID, human2.objectID, nil));

    objects = [self.cache objectsForEntity:self.entity withAttributeValues:@{ @"name": @"Blake" } inContext:childContext];
    assertThat(objects, hasCountOf(1));
    assertThat([objects valueForKey:@"objectID"], contains(human1.objectID, nil));

    done = NO;
    [self.cache flush:^{
        done = YES;
    }];
    expect(done).will.equal(YES);
    objects = [self.cache objectsForEntity:self.entity withAttributeValues:@{ @"railsID": @(12345) } inContext:childContext];
    assertThat(objects, isEmpty());
    objects = [self.cache objectsForEntity:self.entity withAttributeValues:@{ @"name": @"Blake" } inContext:childContext];
    assertThat(objects, isEmpty());
}

- (void)testAddingObjectAddsToEachUnderlyingEntityAttributeCaches
{
    __block BOOL done = NO;
    [_cache cacheObjectsForEntity:self.entity byAttributes:@[ @"railsID" ] completion:nil];
    [_cache cacheObjectsForEntity:self.entity byAttributes:@[ @"name" ] completion:^{
        done = YES;
    }];
    expect(done).will.equal(YES);

    RKHuman *human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human1.railsID = @12345;
    human1.name = @"Blake";
    RKHuman *human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human2.railsID = @12345;
    human2.name = @"Sarah";
    
    __block NSError *error;
    __block BOOL success;
    [self.managedObjectStore.persistentStoreManagedObjectContext performBlockAndWait:^{
        success = [self.managedObjectStore.persistentStoreManagedObjectContext save:&error];
    }];
    assertThatBool(success, is(equalToBool(YES)));
    
    done = NO;
    [_cache addObjects:[NSSet setWithObjects:human1, human2, nil] completion:^{
        done = YES;
    }];
    expect(done).will.equal(YES);
    
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
    __block BOOL done = NO;
    [_cache cacheObjectsForEntity:self.entity byAttributes:@[ @"railsID" ] completion:nil];
    [_cache cacheObjectsForEntity:self.entity byAttributes:@[ @"name" ] completion:^{
        done = YES;
    }];
    expect(done).will.equal(YES);

    RKHuman *human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human1.railsID = @12345;
    human1.name = @"Blake";
    RKHuman *human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human2.railsID = @12345;
    human2.name = @"Sarah";
    
    __block NSError *error;
    __block BOOL success;
    [self.managedObjectStore.persistentStoreManagedObjectContext performBlockAndWait:^{
        success = [self.managedObjectStore.persistentStoreManagedObjectContext save:&error];
    }];
    assertThatBool(success, is(equalToBool(YES)));
    
    done = NO;
    [_cache addObjects:[NSSet setWithObjects:human1, human2, nil] completion:^{
        done = YES;
    }];
    expect(done).will.equal(YES);
    
    NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    childContext.parentContext = self.managedObjectStore.persistentStoreManagedObjectContext;

    NSSet *objects = [self.cache objectsForEntity:self.entity withAttributeValues:@{ @"railsID": @(12345) } inContext:childContext];
    assertThat(objects, hasCountOf(2));
    assertThat([objects valueForKey:@"objectID"], containsInAnyOrder(human1.objectID, human2.objectID, nil));

    RKEntityByAttributeCache *entityAttributeCache = [self.cache attributeCacheForEntity:self.entity attributes:@[ @"railsID" ]];
    assertThatBool([entityAttributeCache containsObject:human1], is(equalToBool(YES)));
    done = NO;
    [self.cache removeObjects:[NSSet setWithObjects:human1, human2, nil] completion:^{
        done = YES;
    }];
    expect(done).will.equal(YES);
    assertThatBool([entityAttributeCache containsObject:human1], is(equalToBool(NO)));
}

#if TARGET_OS_IPHONE
- (void)testCacheIsFlushedOnMemoryWarning
{
    RKHuman *human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human1.railsID = @12345;
    RKHuman *human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human2.railsID = @12345;
    [self.managedObjectStore.persistentStoreManagedObjectContext save:nil];

    __block BOOL done = NO;
    [self.cache cacheObjectsForEntity:human1.entity byAttributes:@[ @"railsID" ]completion:^{
        done = YES;
        expect([self.cache containsObject:human1]).will.equal(YES);
        expect([self.cache containsObject:human2]).will.equal(YES);
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidReceiveMemoryWarningNotification object:self];
        expect([self.cache containsObject:human1]).will.equal(NO);
        expect([self.cache containsObject:human2]).will.equal(NO);
    }];
    expect(done).will.equal(YES);
}
#endif

@end
