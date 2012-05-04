//
//  RKSyncManagerTest.m
//  RestKit
//
//  Created by Mark Makdad on 5/4/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKSyncManager.h"

// For model testing
#import "RKHuman.h"

@interface RKSyncManagerTest : RKTestCase
@property (strong) RKManagedObjectStore *store;
@property (strong) RKObjectManager *manager;
@property (strong) RKHuman *seededHuman;
@property (strong) RKManagedObjectMapping *transparentSyncMapping;
@property (strong) RKManagedObjectMapping *noSyncMapping;
@end

@implementation RKSyncManagerTest
@synthesize store, manager, seededHuman;
@synthesize noSyncMapping, transparentSyncMapping;

- (void)setUp {
    [RKTestFactory setUp];
    self.store = [RKTestFactory managedObjectStore];
    self.manager = [RKTestFactory objectManager];
    self.manager.objectStore = self.store;
  
    // Make an RKHuman entity in Core Data that we can update/delete
    RKHuman *human = [RKHuman object];
    human.name = @"Mark Makdad";
    human.railsID = [NSNumber numberWithInt:1];
    [self.manager.objectStore save:nil];
    self.seededHuman = human;
  
    // Transparent sync mapping for RKHuman
    self.transparentSyncMapping = [RKManagedObjectMapping mappingForClass:[RKHuman class] inManagedObjectStore:store];
    self.transparentSyncMapping.syncMode = RKSyncModeTransparent;
  
    // Regular mapping w/ no sync
    self.noSyncMapping = [RKManagedObjectMapping mappingForClass:[RKHuman class] inManagedObjectStore:store];
  
    // Most of these test methods use this mapping - the test will need to switch explicitly otherwise
    [self.manager.mappingProvider setMapping:self.transparentSyncMapping forKeyPath:@"/human"];
}

- (void)tearDown {
    [RKTestFactory tearDown];
}

#pragma mark - Sync Queue Management Tests

- (void)testSyncQueueEntityExistsWhenObjectStoreCreated {
    NSArray *entityNames = [self.store.managedObjectModel.entitiesByName allKeys];
    assertThat(entityNames, hasItem(@"RKManagedObjectSyncQueue"));
}

- (void)testSyncQueueStartsEmpty {
    NSArray *queueItems = [RKManagedObjectSyncQueue findAll];
    assertThat(queueItems, hasCountOf(0));
}

- (void)testSyncQueueIgnoredWhenSyncModeNotSet {
    // We are NOT setting the sync mode here on this mapping, so this should have no effect on the queue
    [self.manager.mappingProvider setMapping:self.noSyncMapping forKeyPath:@"/human"];
    
    // Create a new human
    RKHuman *human = [RKHuman object];
    human.name = @"Eric Cordell";
    human.railsID = [NSNumber numberWithInt:2];
    [self.manager.objectStore save:nil];
    
    // We should now have a queue item of that human's request
    NSArray *queueItems = [RKManagedObjectSyncQueue findAll];
    assertThat(queueItems,hasCountOf(0));
}

- (void)testSyncQueuePOSTItemCreatedWhenCoreDataObjectCreated {
    // Create a new human - we have a mapping w/ syncMode set so we expect sync behavior
    RKHuman *human = [RKHuman object];
    human.name = @"Eric Cordell";
    human.railsID = [NSNumber numberWithInt:2];
    [self.manager.objectStore save:nil];
    
    // We should now have a queue item of that human's request
    NSArray *queueItems = [RKManagedObjectSyncQueue findAll];
    assertThat(queueItems,hasCountOf(1));
    
    // Which should be a POST request
    RKManagedObjectSyncQueue *item = [queueItems objectAtIndex:0];
    assertThat(item.syncMethod,is(equalTo([NSNumber numberWithInteger:RKRequestMethodPOST])));
}

- (void)testSyncQueueItemCreatedWhenCoreDataObjectUpdated {
    // Make the change to the RKHuman object & save, we should now have a sync item.
    self.seededHuman.name = @"Blake Watters";
    [self.manager.objectStore save:nil];

    NSArray *queueItems = [RKManagedObjectSyncQueue findAll];
    assertThat(queueItems,hasCountOf(1));
    
    // Which should be a PUT request
    RKManagedObjectSyncQueue *item = [queueItems objectAtIndex:0];
    assertThat(item.syncMethod,is(equalTo([NSNumber numberWithInteger:RKRequestMethodPUT])));  
}

- (void)testSyncQueueItemCreatedWhenCoreDataObjectDeleted {
    // Delete, now we should have a DELETE request
    [self.seededHuman deleteEntity];
    [self.manager.objectStore save:nil];
  
    NSArray *queueItems = [RKManagedObjectSyncQueue findAll];
    assertThat(queueItems,hasCountOf(1));
    
    // Which should be a PUT request
    RKManagedObjectSyncQueue *item = [queueItems objectAtIndex:0];
    assertThat(item.syncMethod,is(equalTo([NSNumber numberWithInteger:RKRequestMethodDELETE])));
}

- (void)testSyncManagerBatchStrategyPrunesExtraUpdates {
    // First update
    self.seededHuman.name = @"Maaku Makudaddo";
    [self.manager.objectStore save:nil];
    assertThat([RKManagedObjectSyncQueue findAll],hasCountOf(1));
    
    // Second update - we should still only have 1 item in the queue as the manager realized there were 2 updates
    self.seededHuman.name = @"Mark Makdad";
    [self.manager.objectStore save:nil];
    assertThat([RKManagedObjectSyncQueue findAll],hasCountOf(1));
}

- (void)testSyncManagerProxyStrategyForMultipleUpdates {
    // Tell the RKSyncManager not to prune theoretically unnecessary UPDATE requests
    [self.manager.syncManager setDefaultSyncStrategy:RKSyncStrategyProxyOnly];
    
    // First update
    self.seededHuman.name = @"Maaku Makudaddo";
    [self.manager.objectStore save:nil];
    assertThat([RKManagedObjectSyncQueue findAll],hasCountOf(1));
    
    // Second update - we should now have 2 items in the queue
    self.seededHuman.name = @"Mark Makdad";
    [self.manager.objectStore save:nil];
    assertThat([RKManagedObjectSyncQueue findAll],hasCountOf(2));
}

- (void)testSyncManagerBatchStrategyPrunesLocalOnlyObjects {
    // Create a new human - we have a mapping w/ syncMode set so we expect sync behavior
    RKHuman *human = [RKHuman object];
    human.name = @"Eric Cordell";
    human.railsID = [NSNumber numberWithInt:2];
    [self.manager.objectStore save:nil];
    assertThat([RKManagedObjectSyncQueue findAll],hasCountOf(1));
  
    // Never mind, we wanted to delete this guy.  Don't bother sending anything with batch strategy
    [human deleteEntity];
    [self.manager.objectStore save:nil];
    assertThat([RKManagedObjectSyncQueue findAll],hasCountOf(0));
}

- (void)testSyncManagerProxyStrategyDoesNotPruneLocalOnlyObjects {
    // Tell the RKSyncManager not to prune theoretically unnecessary UPDATE/POST requests
    [self.manager.syncManager setDefaultSyncStrategy:RKSyncStrategyProxyOnly];
  
    // Create a new human - we have a mapping w/ syncMode set so we expect sync behavior
    RKHuman *human = [RKHuman object];
    human.name = @"Eric Cordell";
    human.railsID = [NSNumber numberWithInt:2];
    [self.manager.objectStore save:nil];
    assertThat([RKManagedObjectSyncQueue findAll],hasCountOf(1));
    
    // Never mind, we wanted to delete this guy.  The queue should now contain both items - POST & DELETE.
    [human deleteEntity];
    [self.manager.objectStore save:nil];
    assertThat([RKManagedObjectSyncQueue findAll],hasCountOf(2));
}

@end