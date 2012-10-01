//
//  RKSearchTest.m
//  RestKit
//
//  Created by Blake Watters on 7/31/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "Search.h"
#import "RKCat.h"

@interface RKSearchTest : RKTestCase

@end

@implementation RKSearchTest

- (void)testSearchingForManagedObjects
{
    __block NSError *error;
    NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:[NSBundle allBundles]];
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:managedObjectModel];
    [managedObjectStore addSearchIndexingToEntityForName:@"RKCat" onAttributes:@[ @"name" ]];
    [managedObjectStore addInMemoryPersistentStore:&error];
    [managedObjectStore createManagedObjectContexts];
    [managedObjectStore startIndexingPrimaryManagedObjectContext];
    
    // Get some content into the index
    RKCat *cat1 = [NSEntityDescription insertNewObjectForEntityForName:@"RKCat" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    cat1.name = @"Asia Penelope Watters";
    RKCat *cat2 = [NSEntityDescription insertNewObjectForEntityForName:@"RKCat" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    cat2.name = @"Reginald Royford Williams, III";
    
    [managedObjectStore.mainQueueManagedObjectContext obtainPermanentIDsForObjects:@[cat1, cat2] error:&error];
    [managedObjectStore.mainQueueManagedObjectContext saveToPersistentStore:&error];
    
    // Execute fetches to verify
    [managedObjectStore.primaryManagedObjectContext performBlockAndWait:^{
        NSPredicate *predicate = [RKSearchPredicate searchPredicateWithText:@"Asia" type:NSAndPredicateType];
        
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"RKCat"];
        fetchRequest.predicate = predicate;
        NSArray *objects = [managedObjectStore.primaryManagedObjectContext executeFetchRequest:fetchRequest error:&error];
        assertThat(objects, hasCountOf(1));
        assertThat([objects[0] objectID], is(equalTo(cat1.objectID)));
    }];
    
    [managedObjectStore.primaryManagedObjectContext performBlockAndWait:^{
        NSPredicate *predicate = [RKSearchPredicate searchPredicateWithText:@"Asia Roy" type:NSOrPredicateType];
        
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"RKCat"];
        fetchRequest.predicate = predicate;
        fetchRequest.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES] ];
        NSArray *objects = [managedObjectStore.primaryManagedObjectContext executeFetchRequest:fetchRequest error:&error];
        assertThat(objects, hasCountOf(2));
        assertThat([objects[0] objectID], is(equalTo(cat1.objectID))); // Asia
        assertThat([objects[1] objectID], is(equalTo(cat2.objectID))); // Roy
    }];
}

@end
