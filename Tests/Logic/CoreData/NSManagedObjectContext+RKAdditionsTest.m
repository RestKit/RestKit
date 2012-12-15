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

@interface NSManagedObjectContext_RKAdditionsTest : SenTestCase

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

//- (void)testFetchObjectForEntityWithValueForPrimaryKeyAttribute
//{
//    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
//    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
//    entity.primaryKeyAttributeName = @"railsID";
//
//    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
//    human.railsID = [NSNumber numberWithInt:12345];
//    [managedObjectStore.persistentStoreManagedObjectContext save:nil];
//
//    RKHuman *foundHuman = [managedObjectStore.persistentStoreManagedObjectContext fetchObjectForEntity:entity withValueForPrimaryKeyAttribute:[NSNumber numberWithInt:12345]];
//    assertThat(foundHuman, is(equalTo(human)));
//}
//
//- (void)testFetchObjectForEntityForNameWithValueForPrimaryKeyAttribute
//{
//    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
//    NSManagedObjectContext *context = [[RKTestFactory managedObjectStore] newChildManagedObjectContextWithConcurrencyType:NSMainQueueConcurrencyType];
//    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
//    entity.primaryKeyAttributeName = @"railsID";
//
//    NSEntityDescription *childEntity = [NSEntityDescription entityForName:@"Human" inManagedObjectContext:context];
//    childEntity.primaryKeyAttributeName = @"railsID";
//    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:context];
//    human.railsID = [NSNumber numberWithInt:12345];
//    NSError *error = nil;
//    BOOL success = [context save:&error];
//    assertThatBool(success, is(equalToBool(YES)));
//    assertThat(error, is(nilValue()));
//
//    NSUInteger count = [context countForEntityForName:@"Human" predicate:nil error:nil];
//    assertThatInteger(count, is(equalToInteger(1)));
//
//    RKHuman *foundHuman = [managedObjectStore.persistentStoreManagedObjectContext fetchObjectForEntityForName:@"Human" withValueForPrimaryKeyAttribute:[NSNumber numberWithInt:12345]];
//    assertThat(foundHuman, is(notNilValue()));
//
//    foundHuman = [context fetchObjectForEntityForName:@"Human" withValueForPrimaryKeyAttribute:[NSNumber numberWithInt:12345]];
//    assertThat(foundHuman, is(equalTo(human)));
//}
//
//- (void)testFetchObjectForEntityByPrimaryKeyWithStringValueForNumericProperty
//{
//    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
//    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
//    entity.primaryKeyAttributeName = @"railsID";
//
//    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
//    human.railsID = [NSNumber numberWithInt:12345];
//    [managedObjectStore.persistentStoreManagedObjectContext save:nil];
//
//    RKHuman *foundHuman = [managedObjectStore.persistentStoreManagedObjectContext fetchObjectForEntity:entity withValueForPrimaryKeyAttribute:@"12345"];
//    assertThat(foundHuman, is(equalTo(human)));
//}

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
