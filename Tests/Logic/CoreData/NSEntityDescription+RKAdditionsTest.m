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

- (void)setUp
{
    [RKTestFactory setUp];
}

- (void)tearDown
{
    [RKTestFactory tearDown];
}

- (void)testRetrievalOfPrimaryKeyFromXcdatamodel
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Cat" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    assertThat(entity.primaryKeyAttributeName, is(equalTo(@"railsID")));
}

- (void)testRetrievalOfUnconfiguredPrimaryKeyAttributeReturnsNil
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    assertThat(entity.primaryKeyAttribute, is(nilValue()));
}

- (void)testSettingPrimaryKeyAttributeNameProgramatically
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"House" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    entity.primaryKeyAttributeName = @"houseID";
    assertThat(entity.primaryKeyAttributeName, is(equalTo(@"houseID")));
}

- (void)testSettingExistingPrimaryKeyAttributeNameProgramatically
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Cat" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    assertThat(entity.primaryKeyAttributeName, is(equalTo(@"railsID")));
    entity.primaryKeyAttributeName = @"catID";
    assertThat(entity.primaryKeyAttributeName, is(equalTo(@"catID")));
}

- (void)testSettingPrimaryKeyAttributeCreatesCachedPredicate
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Cat" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    assertThat(entity.primaryKeyAttributeName, is(equalTo(@"railsID")));
    assertThat([entity.predicateForPrimaryKeyAttribute predicateFormat], is(equalTo(@"railsID == $PRIMARY_KEY_VALUE")));
}

- (void)testThatPredicateForPrimaryKeyAttributeWithValueReturnsUsablePredicate
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Cat" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    assertThat(entity.primaryKeyAttributeName, is(equalTo(@"railsID")));
    NSNumber *primaryKeyValue = [NSNumber numberWithInt:12345];
    NSPredicate *predicate = [entity predicateForPrimaryKeyAttributeWithValue:primaryKeyValue];
    assertThat([predicate predicateFormat], is(equalTo(@"railsID == 12345")));
}

- (void)testThatPredicateForPrimaryKeyAttributeCastsStringValueToNumber
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Cat" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    assertThat(entity.primaryKeyAttributeName, is(equalTo(@"railsID")));
    NSPredicate *predicate = [entity predicateForPrimaryKeyAttributeWithValue:@"12345"];
    assertThat([predicate predicateFormat], is(equalTo(@"railsID == 12345")));
}

- (void)testThatPredicateForPrimaryKeyAttributeCastsNumberToString
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"House" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    entity.primaryKeyAttributeName = @"city";
    NSPredicate *predicate = [entity predicateForPrimaryKeyAttributeWithValue:[NSNumber numberWithInteger:12345]];
    assertThat([predicate predicateFormat], is(equalTo(@"city == \"12345\"")));
}

- (void)testThatPredicateForPrimaryKeyAttributeReturnsNilForEntityWithoutPrimaryKey
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"House" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
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
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Cat" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
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
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"House" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    entity.primaryKeyAttributeName = @"invalid";
    assertThat([entity primaryKeyAttributeClass], is(nilValue()));
}

- (void)testRetrievalOfPrimaryKeyAttributeClassForValidAttributeName
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"House" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    entity.primaryKeyAttributeName = @"railsID";
    assertThat([entity primaryKeyAttributeClass], is(equalTo([NSNumber class])));
}

@end
