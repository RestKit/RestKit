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

- (void)setUp
{
    [RKTestFactory setUp];
}

- (void)tearDown
{
    [RKTestFactory tearDown];
}

- (void)testShouldCreateNewInstancesOfUnmanagedObjects
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKMappableObject class]];
    id object = [dataSource objectForMappableContent:[NSDictionary dictionary] mapping:mapping];
    assertThat(object, isNot(nilValue()));
    assertThat([object class], is(equalTo([RKMappableObject class])));
}

- (void)testShouldCreateNewManagedObjectInstancesWhenThereIsNoPrimaryKeyInTheData
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:managedObjectStore];
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
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:managedObjectStore];
    
    NSDictionary *data = [NSDictionary dictionary];
    id object = [dataSource objectForMappableContent:data mapping:mapping];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(instanceOf([RKHuman class])));
}

- (void)testShouldCreateANewManagedObjectWhenThePrimaryKeyValueIsNSNull
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:managedObjectStore];
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
    managedObjectStore.managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:managedObjectStore];
    mapping.primaryKeyAttribute = @"railsID";
    [mapping addAttributeMapping:[RKAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"railsID"]];
    
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    human.railsID = [NSNumber numberWithInt:123];
    [managedObjectStore.primaryManagedObjectContext save:nil];

    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"RKHuman"];
    NSUInteger count = [managedObjectStore.primaryManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    assertThat([NSNumber numberWithInteger:count], is(greaterThan([NSNumber numberWithInteger:0])));
    
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    NSDictionary *data = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:123] forKey:@"id"];
    id object = [dataSource objectForMappableContent:data mapping:mapping];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(equalTo(human)));
}

- (void)testShouldFindExistingManagedObjectsByPrimaryKeyPathWithFetchedResultsCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:managedObjectStore];
    mapping.primaryKeyAttribute = @"railsID";
    [mapping addAttributeMapping:[RKAttributeMapping mappingFromKeyPath:@"monkey.id" toKeyPath:@"railsID"]];
    
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    human.railsID = [NSNumber numberWithInt:123];
    [managedObjectStore.primaryManagedObjectContext save:nil];

    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"RKHuman"];
    NSUInteger count = [managedObjectStore.primaryManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    assertThat([NSNumber numberWithInteger:count], is(greaterThan([NSNumber numberWithInteger:0])));
    
    NSDictionary *data = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:123] forKey:@"id"];
    NSDictionary *nestedDictionary = [NSDictionary dictionaryWithObject:data forKey:@"monkey"];
    
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    id object = [dataSource objectForMappableContent:nestedDictionary mapping:mapping];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(equalTo(human)));
}

#pragma mark - In Memory Cache

- (void)testShouldFindExistingManagedObjectsByPrimaryKeyWithInMemoryCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:managedObjectStore];
    mapping.primaryKeyAttribute = @"railsID";
    [mapping addAttributeMapping:[RKAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"railsID"]];
    
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    human.railsID = [NSNumber numberWithInt:123];
    [managedObjectStore.primaryManagedObjectContext save:nil];

    // Check the count
    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"RKHuman"];
    NSUInteger count = [managedObjectStore.primaryManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    assertThat([NSNumber numberWithInteger:count], is(greaterThan([NSNumber numberWithInteger:0])));
    
    NSDictionary *data = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:123] forKey:@"id"];    
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    NSManagedObject *object = [dataSource objectForMappableContent:data mapping:mapping];
    assertThat([object managedObjectContext], is(equalTo(managedObjectStore.primaryManagedObjectContext)));
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(equalTo(human)));
}

- (void)testShouldFindExistingManagedObjectsByPrimaryKeyPathWithInMemoryCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:managedObjectStore];
    mapping.primaryKeyAttribute = @"railsID";
    [mapping addAttributeMapping:[RKAttributeMapping mappingFromKeyPath:@"monkey.id" toKeyPath:@"railsID"]];
    
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    human.railsID = [NSNumber numberWithInt:123];
    [managedObjectStore.primaryManagedObjectContext save:nil];

    // Check the count
    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"RKHuman"];
    NSUInteger count = [managedObjectStore.primaryManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    assertThat([NSNumber numberWithInteger:count], is(greaterThan([NSNumber numberWithInteger:0])));
    
    NSDictionary *data = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:123] forKey:@"id"];
    NSDictionary *nestedDictionary = [NSDictionary dictionaryWithObject:data forKey:@"monkey"];
    
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    id object = [dataSource objectForMappableContent:nestedDictionary mapping:mapping];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(equalTo(human)));
}

- (void)testMappingWithFetchRequestCacheWherePrimaryKeyAttributeOfMappingDisagreesWithEntity
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:managedObjectStore];
    mapping.primaryKeyAttribute = @"name";
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    entity.primaryKeyAttributeName = @"railsID";
    [mapping addAttributeMapping:[RKAttributeMapping mappingFromKeyPath:@"monkey.name" toKeyPath:@"name"]];
    
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    human.name = @"Testing";
    [managedObjectStore.primaryManagedObjectContext save:nil];

    // Check the count
    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"RKHuman"];
    NSUInteger count = [managedObjectStore.primaryManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    assertThat([NSNumber numberWithInteger:count], is(greaterThan([NSNumber numberWithInteger:0])));
    
    NSDictionary *data = [NSDictionary dictionaryWithObject:@"Testing" forKey:@"name"];
    NSDictionary *nestedDictionary = [NSDictionary dictionaryWithObject:data forKey:@"monkey"];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    id object = [dataSource objectForMappableContent:nestedDictionary mapping:mapping];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(equalTo(human)));
    
    id cachedObject = [managedObjectStore.managedObjectCache findInstanceOfEntity:entity withPrimaryKeyAttribute:@"name" value:@"Testing" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    assertThat(cachedObject, is(equalTo(human)));
}

- (void)testMappingWithInMemoryCacheWherePrimaryKeyAttributeOfMappingDisagreesWithEntity
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntity:entity];
    mapping.primaryKeyAttribute = @"name";
    entity.primaryKeyAttributeName = @"railsID";
    [mapping addAttributeMapping:[RKAttributeMapping mappingFromKeyPath:@"monkey.name" toKeyPath:@"name"]];
    
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    human.name = @"Testing";
    [managedObjectStore.primaryManagedObjectContext save:nil];

    // Check the count
    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"RKHuman"];
    NSUInteger count = [managedObjectStore.primaryManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    assertThatInteger(count, is(greaterThan([NSNumber numberWithInteger:0])));
    
    NSDictionary *data = [NSDictionary dictionaryWithObject:@"Testing" forKey:@"name"];
    NSDictionary *nestedDictionary = [NSDictionary dictionaryWithObject:data forKey:@"monkey"];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    id object = [dataSource objectForMappableContent:nestedDictionary mapping:mapping];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(equalTo(human)));
    
    id cachedObject = [managedObjectStore.managedObjectCache findInstanceOfEntity:entity withPrimaryKeyAttribute:@"name" value:@"Testing" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    assertThat(cachedObject, is(equalTo(human)));
}

- (void)testThatCreationOfNewObjectWithIncorrectTypeValueForPrimaryKeyAddsToCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntity:entity];
    mapping.primaryKeyAttribute = @"railsID";
    entity.primaryKeyAttributeName = @"railsID";
    [mapping addAttributeMapping:[RKAttributeMapping mappingFromKeyPath:@"monkey.name" toKeyPath:@"name"]];
    [mapping addAttributeMapping:[RKAttributeMapping mappingFromKeyPath:@"monkey.railsID" toKeyPath:@"railsID"]];
    
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    human.name = @"Testing";
    human.railsID = [NSNumber numberWithInteger:12345];
    [managedObjectStore.primaryManagedObjectContext save:nil];

    // Check the count
    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"RKHuman"];
    NSUInteger count = [managedObjectStore.primaryManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    assertThatInteger(count, is(greaterThan([NSNumber numberWithInteger:0])));
    
    NSDictionary *data = [NSDictionary dictionaryWithObject:@"12345" forKey:@"railsID"];
    NSDictionary *nestedDictionary = [NSDictionary dictionaryWithObject:data forKey:@"monkey"];
    
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    RKHuman *object = [dataSource objectForMappableContent:nestedDictionary mapping:mapping];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(equalTo(human)));
    assertThatInteger([object.railsID integerValue], is(equalToInteger(12345)));
}

@end
