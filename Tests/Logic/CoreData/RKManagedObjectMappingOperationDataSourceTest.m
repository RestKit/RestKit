//
//  RKManagedObjectMappingOperationDataSourceTest.m
//  RestKit
//
//  Created by Blake Watters on 7/12/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "NSEntityDescription+RKAdditions.h"
#import "RKEntityCache.h"
#import "RKEntityByAttributeCache.h"
#import "RKHuman.h"
#import "RKManagedObjectMappingOperationDataSource.h"
#import "RKMappableObject.h"

@interface RKManagedObjectMappingOperationDataSourceTest : RKTestCase

@end

@implementation RKManagedObjectMappingOperationDataSourceTest

- (void)testShouldCreateNewInstancesOfUnmanagedObjects
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                      cache:managedObjectStore.cacheStrategy];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKMappableObject class]];
    id object = [dataSource objectForMappableContent:[NSDictionary dictionary] mapping:mapping];
    assertThat(object, isNot(nilValue()));
    assertThat([object class], is(equalTo([RKMappableObject class])));
}

- (void)testShouldCreateNewManagedObjectInstancesWhenThereIsNoPrimaryKeyInTheData
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                      cache:managedObjectStore.cacheStrategy];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityWithName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    mapping.primaryKeyAttribute = @"railsID";
    
    NSDictionary *data = [NSDictionary dictionary];
    id object = [dataSource objectForMappableContent:data mapping:mapping];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(instanceOf([RKHuman class])));
}

- (void)testShouldCreateNewManagedObjectInstancesWhenThereIsNoPrimaryKeyAttribute
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                      cache:managedObjectStore.cacheStrategy];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityWithName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    
    NSDictionary *data = [NSDictionary dictionary];
    id object = [dataSource objectForMappableContent:data mapping:mapping];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(instanceOf([RKHuman class])));
}

- (void)testShouldCreateANewManagedObjectWhenThePrimaryKeyValueIsNSNull
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                      cache:managedObjectStore.cacheStrategy];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityWithName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    mapping.primaryKeyAttribute = @"railsID";
    [mapping addAttributeMapping:[RKAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"railsID"]];
    
    NSDictionary *data = [NSDictionary dictionaryWithObject:[NSNull null] forKey:@"id"];
    id object = [dataSource objectForMappableContent:data mapping:mapping];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(instanceOf([RKHuman class])));
}

#pragma mark - Fetched Results Cache

- (void)testShouldFindExistingManagedObjectsByPrimaryKeyWithFetchedResultsCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.cacheStrategy = [RKFetchRequestManagedObjectCache new];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityWithName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    mapping.primaryKeyAttribute = @"railsID";
    [mapping addAttributeMapping:[RKAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"railsID"]];
    
    RKHuman *human = [RKHuman object];
    human.railsID = [NSNumber numberWithInt:123];
    [managedObjectStore save:nil];
    assertThatBool([RKHuman hasAtLeastOneEntity], is(equalToBool(YES)));
    
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                      cache:managedObjectStore.cacheStrategy];
    NSDictionary *data = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:123] forKey:@"id"];
    id object = [dataSource objectForMappableContent:data mapping:mapping];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(equalTo(human)));
}

- (void)testShouldFindExistingManagedObjectsByPrimaryKeyPathWithFetchedResultsCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.cacheStrategy = [RKFetchRequestManagedObjectCache new];
    [RKHuman truncateAll];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityWithName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    mapping.primaryKeyAttribute = @"railsID";
    [mapping addAttributeMapping:[RKAttributeMapping mappingFromKeyPath:@"monkey.id" toKeyPath:@"railsID"]];
    
    [RKHuman truncateAll];
    RKHuman *human = [RKHuman object];
    human.railsID = [NSNumber numberWithInt:123];
    [managedObjectStore save:nil];
    assertThatBool([RKHuman hasAtLeastOneEntity], is(equalToBool(YES)));
    
    NSDictionary *data = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:123] forKey:@"id"];
    NSDictionary *nestedDictionary = [NSDictionary dictionaryWithObject:data forKey:@"monkey"];
    
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                      cache:managedObjectStore.cacheStrategy];
    id object = [dataSource objectForMappableContent:nestedDictionary mapping:mapping];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(equalTo(human)));
}

#pragma mark - In Memory Cache

- (void)testShouldFindExistingManagedObjectsByPrimaryKeyWithInMemoryCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    [RKHuman truncateAllInContext:managedObjectStore.primaryManagedObjectContext];
    managedObjectStore.cacheStrategy = [RKInMemoryManagedObjectCache new];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityWithName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    mapping.primaryKeyAttribute = @"railsID";
    [mapping addAttributeMapping:[RKAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"railsID"]];
    
    RKHuman *human = [RKHuman createInContext:managedObjectStore.primaryManagedObjectContext];
    human.railsID = [NSNumber numberWithInt:123];
    [managedObjectStore save:nil];
    assertThatBool([RKHuman hasAtLeastOneEntity], is(equalToBool(YES)));
    
    NSDictionary *data = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:123] forKey:@"id"];    
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                      cache:managedObjectStore.cacheStrategy];
    NSManagedObject *object = [dataSource objectForMappableContent:data mapping:mapping];
    assertThat([object managedObjectContext], is(equalTo(managedObjectStore.primaryManagedObjectContext)));
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(equalTo(human)));
}

- (void)testShouldFindExistingManagedObjectsByPrimaryKeyPathWithInMemoryCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    [RKHuman truncateAllInContext:managedObjectStore.primaryManagedObjectContext];
    managedObjectStore.cacheStrategy = [RKInMemoryManagedObjectCache new];
    [RKHuman truncateAll];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityWithName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    mapping.primaryKeyAttribute = @"railsID";
    [mapping addAttributeMapping:[RKAttributeMapping mappingFromKeyPath:@"monkey.id" toKeyPath:@"railsID"]];
    
    [RKHuman truncateAll];
    RKHuman *human = [RKHuman object];
    human.railsID = [NSNumber numberWithInt:123];
    [managedObjectStore save:nil];
    assertThatBool([RKHuman hasAtLeastOneEntity], is(equalToBool(YES)));
    
    NSDictionary *data = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:123] forKey:@"id"];
    NSDictionary *nestedDictionary = [NSDictionary dictionaryWithObject:data forKey:@"monkey"];
    
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                      cache:managedObjectStore.cacheStrategy];
    id object = [dataSource objectForMappableContent:nestedDictionary mapping:mapping];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(equalTo(human)));
}

- (void)testMappingWithFetchRequestCacheWherePrimaryKeyAttributeOfMappingDisagreesWithEntity
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.cacheStrategy = [RKFetchRequestManagedObjectCache new];
    [RKHuman truncateAll];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityWithName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    mapping.primaryKeyAttribute = @"name";
    [RKHuman entity].primaryKeyAttributeName = @"railsID";
    [mapping addAttributeMapping:[RKAttributeMapping mappingFromKeyPath:@"monkey.name" toKeyPath:@"name"]];
    
    [RKHuman truncateAll];
    RKHuman *human = [RKHuman object];
    human.name = @"Testing";
    [managedObjectStore save:nil];
    assertThatBool([RKHuman hasAtLeastOneEntity], is(equalToBool(YES)));
    
    NSDictionary *data = [NSDictionary dictionaryWithObject:@"Testing" forKey:@"name"];
    NSDictionary *nestedDictionary = [NSDictionary dictionaryWithObject:data forKey:@"monkey"];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                      cache:managedObjectStore.cacheStrategy];
    id object = [dataSource objectForMappableContent:nestedDictionary mapping:mapping];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(equalTo(human)));
    
    id cachedObject = [managedObjectStore.cacheStrategy findInstanceOfEntity:[RKHuman entity] withPrimaryKeyAttribute:@"name" value:@"Testing" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    assertThat(cachedObject, is(equalTo(human)));
}

- (void)testMappingWithInMemoryCacheWherePrimaryKeyAttributeOfMappingDisagreesWithEntity
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.cacheStrategy = [RKInMemoryManagedObjectCache new];
    [RKHuman truncateAll];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityWithName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    mapping.primaryKeyAttribute = @"name";
    [RKHuman entity].primaryKeyAttributeName = @"railsID";
    [mapping addAttributeMapping:[RKAttributeMapping mappingFromKeyPath:@"monkey.name" toKeyPath:@"name"]];
    
    [RKHuman truncateAll];
    RKHuman *human = [RKHuman object];
    human.name = @"Testing";
    [managedObjectStore save:nil];
    assertThatBool([RKHuman hasAtLeastOneEntity], is(equalToBool(YES)));
    
    NSDictionary *data = [NSDictionary dictionaryWithObject:@"Testing" forKey:@"name"];
    NSDictionary *nestedDictionary = [NSDictionary dictionaryWithObject:data forKey:@"monkey"];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                      cache:managedObjectStore.cacheStrategy];
    id object = [dataSource objectForMappableContent:nestedDictionary mapping:mapping];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(equalTo(human)));
    
    id cachedObject = [managedObjectStore.cacheStrategy findInstanceOfEntity:[RKHuman entity] withPrimaryKeyAttribute:@"name" value:@"Testing" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    assertThat(cachedObject, is(equalTo(human)));
}

- (void)testThatCreationOfNewObjectWithIncorrectTypeValueForPrimaryKeyAddsToCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.cacheStrategy = [RKInMemoryManagedObjectCache new];
    [RKHuman truncateAll];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityWithName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    mapping.primaryKeyAttribute = @"railsID";
    [RKHuman entity].primaryKeyAttributeName = @"railsID";
    [mapping addAttributeMapping:[RKAttributeMapping mappingFromKeyPath:@"monkey.name" toKeyPath:@"name"]];
    [mapping addAttributeMapping:[RKAttributeMapping mappingFromKeyPath:@"monkey.railsID" toKeyPath:@"railsID"]];
    
    [RKHuman truncateAll];
    RKHuman *human = [RKHuman object];
    human.name = @"Testing";
    human.railsID = [NSNumber numberWithInteger:12345];
    [managedObjectStore save:nil];
    assertThatBool([RKHuman hasAtLeastOneEntity], is(equalToBool(YES)));
    
    NSDictionary *data = [NSDictionary dictionaryWithObject:@"12345" forKey:@"railsID"];
    NSDictionary *nestedDictionary = [NSDictionary dictionaryWithObject:data forKey:@"monkey"];
    
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                      cache:managedObjectStore.cacheStrategy];
    RKHuman *object = [dataSource objectForMappableContent:nestedDictionary mapping:mapping];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(equalTo(human)));
    assertThatInteger([object.railsID integerValue], is(equalToInteger(12345)));
}

@end
