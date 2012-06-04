//
//  NSManagedObject+ActiveRecordTest.m
//  RestKit
//
//  Created by Blake Watters on 3/22/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "NSEntityDescription+RKAdditions.h"
#import "RKHuman.h"

@interface NSManagedObject_ActiveRecordTest : SenTestCase

@end

@implementation NSManagedObject_ActiveRecordTest

- (void)testFindByPrimaryKey
{
    RKManagedObjectStore *store = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [RKHuman entityDescription];
    entity.primaryKeyAttributeName = @"railsID";

    RKHuman *human = [RKHuman createEntity];
    human.railsID = [NSNumber numberWithInt:12345];
    [store save:nil];

    RKHuman *foundHuman = [RKHuman findByPrimaryKey:[NSNumber numberWithInt:12345] inContext:store.primaryManagedObjectContext];
    assertThat(foundHuman, is(equalTo(human)));
}

- (void)testFindByPrimaryKeyInContext
{
    RKManagedObjectStore *store = [RKTestFactory managedObjectStore];
    NSManagedObjectContext *context = [[RKTestFactory managedObjectStore] newManagedObjectContext];
    NSEntityDescription *entity = [RKHuman entityDescription];
    entity.primaryKeyAttributeName = @"railsID";

    RKHuman *human = [RKHuman createInContext:context];
    human.railsID = [NSNumber numberWithInt:12345];
    [context save:nil];

    RKHuman *foundHuman = [RKHuman findByPrimaryKey:[NSNumber numberWithInt:12345] inContext:store.primaryManagedObjectContext];
    assertThat(foundHuman, is(nilValue()));

    foundHuman = [RKHuman findByPrimaryKey:[NSNumber numberWithInt:12345] inContext:context];
    assertThat(foundHuman, is(equalTo(human)));
}

- (void)testFindByPrimaryKeyWithStringValueForNumericProperty
{
    RKManagedObjectStore *store = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [RKHuman entityDescription];
    entity.primaryKeyAttributeName = @"railsID";

    RKHuman *human = [RKHuman createEntity];
    human.railsID = [NSNumber numberWithInt:12345];
    [store save:nil];

    RKHuman *foundHuman = [RKHuman findByPrimaryKey:@"12345" inContext:store.primaryManagedObjectContext];
    assertThat(foundHuman, is(equalTo(human)));
}

@end
