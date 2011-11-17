//
//  RKSearchWordObserverSpec.m
//  RestKit
//
//  Created by Blake Watters on 7/26/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKSearchWordObserver.h"
#import "RKSearchable.h"

@interface RKSearchWordObserverSpec : RKSpec

@end

@implementation RKSearchWordObserverSpec

- (void)itShouldInstantiateASearchWordObserverOnObjectStoreInit {
    RKSpecNewManagedObjectStore();
    assertThat([RKSearchWordObserver sharedObserver], isNot(nil));
}

- (void)itShouldTriggerSearchWordRegenerationForChagedSearchableValuesAtObjectContextSaveTime {
    RKManagedObjectStore* store = RKSpecNewManagedObjectStore();
    RKSearchable* searchable = [RKSearchable createEntity];
    searchable.title = @"This is the title of my new object";
    assertThat(searchable.searchWords, is(empty()));
    [store save];
    assertThat(searchable.searchWords, isNot(empty()));
    assertThat(searchable.searchWords, hasCountOf(8));
}

@end
