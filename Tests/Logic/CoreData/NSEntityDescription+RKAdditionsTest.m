//
//  NSEntityDescription+RKAdditionsTest.m
//  RestKit
//
//  Created by Blake Watters on 3/22/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "NSEntityDescription+RKAdditions.h"

@interface NSEntityDescription_RKAdditionsTest : RKTestCase

@end

@implementation NSEntityDescription_RKAdditionsTest

- (void)testRetrievalOfPrimaryKeyFromXcdatamodel
{
    RKManagedObjectStore *objectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RKCat" inManagedObjectContext:objectStore.primaryManagedObjectContext];
    assertThat(entity.primaryKeyAttribute, is(equalTo(@"railsID")));
}

- (void)testRetrievalOfUnconfiguredPrimaryKeyAttributeReturnsNil
{
    RKManagedObjectStore *objectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RKHuman" inManagedObjectContext:objectStore.primaryManagedObjectContext];
    assertThat(entity.primaryKeyAttribute, is(nilValue()));
}

- (void)testSettingPrimaryKeyAttributeProgramatically
{
    RKManagedObjectStore *objectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RKHouse" inManagedObjectContext:objectStore.primaryManagedObjectContext];
    entity.primaryKeyAttribute = @"houseID";
    assertThat(entity.primaryKeyAttribute, is(equalTo(@"houseID")));
}

- (void)testSettingExistingPrimaryKeyAttributeProgramatically
{
    RKManagedObjectStore *objectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RKCat" inManagedObjectContext:objectStore.primaryManagedObjectContext];
    assertThat(entity.primaryKeyAttribute, is(equalTo(@"railsID")));
    entity.primaryKeyAttribute = @"catID";
    assertThat(entity.primaryKeyAttribute, is(equalTo(@"catID")));
}

@end
