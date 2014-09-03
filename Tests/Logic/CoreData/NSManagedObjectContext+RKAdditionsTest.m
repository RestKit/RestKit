//
//  NSManagedObjectContext+RKAdditionsTest.m
//  RestKit
//
//  Created by Blake Watters on 3/22/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "NSManagedObjectContext+RKAdditions.h"
#import "RKHuman.h"

@interface NSManagedObjectContext_RKAdditionsTest : XCTestCase

@end

@implementation NSManagedObjectContext_RKAdditionsTest

- (void)setUp
{
    [RKTestFactory setUp];
}

- (void)tearDown
{
    [RKTestFactory tearDown];
}

- (void)testSaveToPersistentStore
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    human.name = @"Test";
    assertThatBool([human.objectID isTemporaryID], is(equalToBool(YES)));

    NSError *error;
    BOOL success = [human.managedObjectContext saveToPersistentStore:&error];
    assertThatBool(success, is(equalToBool(YES)));
    [managedObjectStore.mainQueueManagedObjectContext refreshObject:human mergeChanges:YES];
    assertThatBool([human isNew], is(equalToBool(NO)));

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"name = %@", @"Test"];
    NSArray *objects = [managedObjectStore.persistentStoreManagedObjectContext executeFetchRequest:fetchRequest error:&error];
    assertThat(objects, hasCountOf(1));
    RKHuman *fetchedHuman = [objects objectAtIndex:0];
    assertThatBool([fetchedHuman.objectID isTemporaryID], is(equalToBool(NO)));
}

@end
