//
//  NSManagedObjectContext+RKAdditionsTest.m
//  RestKit
//
//  Created by Blake Watters on 3/22/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "NSManagedObjectContext+RKAdditions.h"
#import "NSEntityDescription+RKAdditions.h"
#import "RKHuman.h"

@interface NSManagedObjectContext_RKAdditionsTest : SenTestCase

@end

@implementation NSManagedObjectContext_RKAdditionsTest

- (void)testFetchObjectForEntityWithValueForPrimaryKeyAttribute
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    entity.primaryKeyAttributeName = @"railsID";

    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    human.railsID = [NSNumber numberWithInt:12345];
    [managedObjectStore.primaryManagedObjectContext save:nil];

    RKHuman *foundHuman = [managedObjectStore.primaryManagedObjectContext fetchObjectForEntity:entity withValueForPrimaryKeyAttribute:[NSNumber numberWithInt:12345]];
    assertThat(foundHuman, is(equalTo(human)));
}

- (void)testFetchObjectForEntityForNameWithValueForPrimaryKeyAttribute
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSManagedObjectContext *context = [[[RKTestFactory managedObjectStore] newChildManagedObjectContextWithConcurrencyType:NSMainQueueConcurrencyType] autorelease];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    entity.primaryKeyAttributeName = @"railsID";

    NSEntityDescription *childEntity = [NSEntityDescription entityForName:@"RKHuman" inManagedObjectContext:context];
    childEntity.primaryKeyAttributeName = @"railsID";
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:context];
    human.railsID = [NSNumber numberWithInt:12345];
    NSError *error = nil;
    BOOL success = [context save:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(error, is(nilValue()));

    NSUInteger count = [context countForEntityForName:@"RKHuman" predicate:nil error:nil];
    assertThatInteger(count, is(equalToInteger(1)));

    RKHuman *foundHuman = [managedObjectStore.primaryManagedObjectContext fetchObjectForEntityForName:@"RKHuman" withValueForPrimaryKeyAttribute:[NSNumber numberWithInt:12345]];
    assertThat(foundHuman, is(nilValue()));

    foundHuman = [context fetchObjectForEntityForName:@"RKHuman" withValueForPrimaryKeyAttribute:[NSNumber numberWithInt:12345]];
    assertThat(foundHuman, is(equalTo(human)));
}

- (void)testFetchObjectForEntityByPrimaryKeyWithStringValueForNumericProperty
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    entity.primaryKeyAttributeName = @"railsID";

    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    human.railsID = [NSNumber numberWithInt:12345];
    [managedObjectStore.primaryManagedObjectContext save:nil];

    RKHuman *foundHuman = [managedObjectStore.primaryManagedObjectContext fetchObjectForEntity:entity withValueForPrimaryKeyAttribute:@"12345"];
    assertThat(foundHuman, is(equalTo(human)));
}

- (void)testSaveToPersistentStore
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    human.name = @"Test";
    assertThatBool([human.objectID isTemporaryID], is(equalToBool(YES)));

    NSError *error;
    BOOL success = [human.managedObjectContext saveToPersistentStore:&error];
    assertThatBool(success, is(equalToBool(YES)));
    [managedObjectStore.mainQueueManagedObjectContext refreshObject:human mergeChanges:YES];
    assertThatBool([human isNew], is(equalToBool(NO)));

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"RKHuman"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"name = %@", @"Test"];
    NSArray *objects = [managedObjectStore.primaryManagedObjectContext executeFetchRequest:fetchRequest error:&error];
    assertThat(objects, hasCountOf(1));
    RKHuman *fetchedHuman = [objects objectAtIndex:0];
    assertThatBool([fetchedHuman.objectID isTemporaryID], is(equalToBool(NO)));
}

@end
