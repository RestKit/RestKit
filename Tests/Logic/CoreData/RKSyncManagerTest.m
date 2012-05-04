//
//  RKSyncManagerTest.m
//  RestKit
//
//  Created by Mark Makdad on 5/4/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKSyncManager.h"

@interface RKSyncManagerTest : RKTestCase

@end

@implementation RKSyncManagerTest

- (void)testSyncQueueEntityExistsWhenObjectStoreCreated {
  RKManagedObjectStore *store = [RKTestFactory managedObjectStore];
  NSManagedObjectModel *model = store.managedObjectModel;
  NSArray *entityNames = [model.entitiesByName allKeys];
  assertThat(entityNames, hasItem(@"RKManagedObjectSyncQueue"));
}

//- (void)testTriggerSearchWordRegenerationForChagedSearchableValuesAtObjectContextSaveTime {
//  RKManagedObjectStore* store = [RKTestFactory managedObjectStore];
//  RKSearchable* searchable = [RKSearchable createEntity];
//  searchable.title = @"This is the title of my new object";
//  assertThat(searchable.searchWords, is(empty()));
//  [store save:nil];
//  assertThat(searchable.searchWords, isNot(empty()));
//  assertThat(searchable.searchWords, hasCountOf(8));
//}

@end
