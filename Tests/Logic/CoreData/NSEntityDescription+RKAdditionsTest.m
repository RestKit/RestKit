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
    assertThat(entity.primaryKeyAttributeName, is(equalTo(@"railsID")));
}

- (void)testRetrievalOfUnconfiguredPrimaryKeyAttributeReturnsNil
{
    RKManagedObjectStore *objectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RKHuman" inManagedObjectContext:objectStore.primaryManagedObjectContext];
    assertThat(entity.primaryKeyAttribute, is(nilValue()));
}

- (void)testSettingPrimaryKeyAttributeNameProgramatically
{
    RKManagedObjectStore *objectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RKHouse" inManagedObjectContext:objectStore.primaryManagedObjectContext];
    entity.primaryKeyAttributeName = @"houseID";
    assertThat(entity.primaryKeyAttributeName, is(equalTo(@"houseID")));
}

- (void)testSettingExistingPrimaryKeyAttributeNameProgramatically
{
    RKManagedObjectStore *objectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RKCat" inManagedObjectContext:objectStore.primaryManagedObjectContext];
    assertThat(entity.primaryKeyAttributeName, is(equalTo(@"railsID")));
    entity.primaryKeyAttributeName = @"catID";
    assertThat(entity.primaryKeyAttributeName, is(equalTo(@"catID")));
}

- (void)testSettingPrimaryKeyAttributeCreatesCachedPredicate
{
    RKManagedObjectStore *objectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RKCat" inManagedObjectContext:objectStore.primaryManagedObjectContext];
    assertThat(entity.primaryKeyAttributeName, is(equalTo(@"railsID")));
    assertThat([entity.predicateForPrimaryKeyAttribute predicateFormat], is(equalTo(@"railsID == $PRIMARY_KEY_VALUE")));
}

- (void)testThatPredicateForPrimaryKeyAttributeWithValueReturnsUsablePredicate
{
    RKManagedObjectStore *objectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RKCat" inManagedObjectContext:objectStore.primaryManagedObjectContext];
    assertThat(entity.primaryKeyAttributeName, is(equalTo(@"railsID")));
    NSNumber *primaryKeyValue = [NSNumber numberWithInt:12345];
    NSPredicate *predicate = [entity predicateForPrimaryKeyAttributeWithValue:primaryKeyValue];
    assertThat([predicate predicateFormat], is(equalTo(@"railsID == 12345")));
}

- (void)testThatPredicateForPrimaryKeyAttributeCastsStringValueToNumber
{
    RKManagedObjectStore *objectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RKCat" inManagedObjectContext:objectStore.primaryManagedObjectContext];
    assertThat(entity.primaryKeyAttributeName, is(equalTo(@"railsID")));
    NSPredicate *predicate = [entity predicateForPrimaryKeyAttributeWithValue:@"12345"];
    assertThat([predicate predicateFormat], is(equalTo(@"railsID == 12345")));
}

- (void)testThatPredicateForPrimaryKeyAttributeCastsNumberToString
{
    RKManagedObjectStore *objectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RKHouse" inManagedObjectContext:objectStore.primaryManagedObjectContext];
    entity.primaryKeyAttributeName = @"city";
    NSPredicate *predicate = [entity predicateForPrimaryKeyAttributeWithValue:[NSNumber numberWithInteger:12345]];
    assertThat([predicate predicateFormat], is(equalTo(@"city == \"12345\"")));
}

- (void)testThatPredicateForPrimaryKeyAttributeReturnsNilForEntityWithoutPrimaryKey
{
    RKManagedObjectStore *objectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RKHouse" inManagedObjectContext:objectStore.primaryManagedObjectContext];
    entity.primaryKeyAttributeName = nil;
    NSPredicate *predicate = [entity predicateForPrimaryKeyAttributeWithValue:@"12345"];
    assertThat([predicate predicateFormat], is(nilValue()));
}

- (void)testRetrievalOfPrimaryKeyAttributeReturnsNilIfNotSet
{
    NSEntityDescription *entity = [NSEntityDescription new];
    assertThat(entity.primaryKeyAttribute, is(nilValue()));
}

- (void)testRetrievalOfPrimaryKeyAttributeReturnsNilWhenSetToInvalidAttributeName
{
    NSEntityDescription *entity = [NSEntityDescription new];
    entity.primaryKeyAttributeName = @"invalidName!";
    assertThat(entity.primaryKeyAttribute, is(nilValue()));
}

- (void)testRetrievalOfPrimaryKeyAttributeForValidAttributeName
{
    RKManagedObjectStore *objectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RKCat" inManagedObjectContext:objectStore.primaryManagedObjectContext];
    entity.primaryKeyAttributeName = @"railsID";
    NSAttributeDescription *attribute = entity.primaryKeyAttribute;
    assertThat(attribute, is(notNilValue()));
    assertThat(attribute.name, is(equalTo(@"railsID")));
    assertThat(attribute.attributeValueClassName, is(equalTo(@"NSNumber")));
}

- (void)testRetrievalOfPrimaryKeyAttributeClassReturnsNilIfNotSet
{
    NSEntityDescription *entity = [NSEntityDescription new];
    assertThat([entity primaryKeyAttributeClass], is(nilValue()));
}

- (void)testRetrievalOfPrimaryKeyAttributeClassReturnsNilWhenSetToInvalidAttributeName
{
    RKManagedObjectStore *objectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RKHouse" inManagedObjectContext:objectStore.primaryManagedObjectContext];
    entity.primaryKeyAttributeName = @"invalid";
    assertThat([entity primaryKeyAttributeClass], is(nilValue()));
}

- (void)testRetrievalOfPrimaryKeyAttributeClassForValidAttributeName
{
    RKManagedObjectStore *objectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RKHouse" inManagedObjectContext:objectStore.primaryManagedObjectContext];
    entity.primaryKeyAttributeName = @"railsID";
    assertThat([entity primaryKeyAttributeClass], is(equalTo([NSNumber class])));
}

@end
