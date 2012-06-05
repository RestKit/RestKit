//
//  RKSearchWordObserverTest.m
//  RestKit
//
//  Created by Blake Watters on 7/26/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKSearchWordObserver.h"
#import "RKSearchable.h"

@interface RKSearchWordObserverTest : RKTestCase

@end

@implementation RKSearchWordObserverTest

- (void)testInstantiateASearchWordObserverOnObjectStoreInit
{
    [RKTestFactory managedObjectStore];
    assertThat([RKSearchWordObserver sharedObserver], isNot(nil));
}

- (void)testTriggerSearchWordRegenerationForChagedSearchableValuesAtObjectContextSaveTime
{
    RKManagedObjectStore *store = [RKTestFactory managedObjectStore];
    RKSearchable *searchable = [RKSearchable createEntity];
    searchable.title = @"This is the title of my new object";
    assertThat(searchable.searchWords, is(empty()));
    [store save:nil];
    assertThat(searchable.searchWords, isNot(empty()));
    assertThat(searchable.searchWords, hasCountOf(8));
}

@end
