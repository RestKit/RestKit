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
#import "RKMappingErrors.h"

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
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKMappableObject class]];
    id object = [dataSource mappingOperation:nil targetObjectForRepresentation:[NSDictionary dictionary] withMapping:mapping];
    assertThat(object, isNot(nilValue()));
    assertThat([object class], is(equalTo([RKMappableObject class])));
}

- (void)testShouldCreateNewManagedObjectInstancesWhenThereIsNoPrimaryKeyInTheData
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    mapping.entityIdentifier = [RKEntityIdentifier entityIdentifierWithEntityName:@" attributes:<#(NSArray *)#> inManagedObjectStore:<#(RKManagedObjectStore *)#>]
    [mapping setEntityIdentifierWithAttributes:@"railsID"];
    
    NSDictionary *data = [NSDictionary dictionary];
    id object = [dataSource mappingOperation:nil targetObjectForRepresentation:data withMapping:mapping];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(instanceOf([RKHuman class])));
}

- (void)testShouldCreateNewManagedObjectInstancesWhenThereIsNoPrimaryKeyAttribute
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    
    NSDictionary *data = [NSDictionary dictionary];    
    id object = [dataSource mappingOperation:nil targetObjectForRepresentation:data withMapping:mapping];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(instanceOf([RKHuman class])));
}

- (void)testShouldCreateANewManagedObjectWhenThePrimaryKeyValueIsNSNull
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [mapping setEntityIdentifierWithAttributes:@"railsID"];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"railsID"]];
    
    NSDictionary *data = [NSDictionary dictionaryWithObject:[NSNull null] forKey:@"id"];    
    id object = [dataSource mappingOperation:nil targetObjectForRepresentation:data withMapping:mapping];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(instanceOf([RKHuman class])));
}

#pragma mark - Fetched Results Cache

- (void)testShouldFindExistingManagedObjectsByPrimaryKeyWithFetchedResultsCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [mapping setEntityIdentifierWithAttributes:@"railsID"];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"railsID"]];
    
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    human.railsID = [NSNumber numberWithInt:123];
    [managedObjectStore.persistentStoreManagedObjectContext save:nil];

    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    NSUInteger count = [managedObjectStore.persistentStoreManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    assertThat([NSNumber numberWithInteger:count], is(greaterThan([NSNumber numberWithInteger:0])));
    
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    NSDictionary *data = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:123] forKey:@"id"];
    id object = [dataSource mappingOperation:nil targetObjectForRepresentation:data withMapping:mapping];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(equalTo(human)));
}

- (void)testShouldFindExistingManagedObjectsByPrimaryKeyPathWithFetchedResultsCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [mapping setEntityIdentifierWithAttributes:@"railsID"];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"monkey.id" toKeyPath:@"railsID"]];
    
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    human.railsID = [NSNumber numberWithInt:123];
    [managedObjectStore.persistentStoreManagedObjectContext save:nil];

    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    NSUInteger count = [managedObjectStore.persistentStoreManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    assertThat([NSNumber numberWithInteger:count], is(greaterThan([NSNumber numberWithInteger:0])));
    
    NSDictionary *data = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:123] forKey:@"id"];
    NSDictionary *nestedDictionary = [NSDictionary dictionaryWithObject:data forKey:@"monkey"];
    
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    id object = [dataSource mappingOperation:nil targetObjectForRepresentation:nestedDictionary withMapping:mapping];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(equalTo(human)));
}

#pragma mark - In Memory Cache

- (void)testShouldFindExistingManagedObjectsByPrimaryKeyWithInMemoryCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [mapping setEntityIdentifierWithAttributes:@"railsID"];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"railsID"]];
    
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    human.railsID = [NSNumber numberWithInt:123];
    [managedObjectStore.persistentStoreManagedObjectContext save:nil];

    // Check the count
    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    NSUInteger count = [managedObjectStore.persistentStoreManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    assertThat([NSNumber numberWithInteger:count], is(greaterThan([NSNumber numberWithInteger:0])));
    
    NSDictionary *data = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:123] forKey:@"id"];    
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];    
    NSManagedObject *object = [dataSource mappingOperation:nil targetObjectForRepresentation:data withMapping:mapping];
    assertThat([object managedObjectContext], is(equalTo(managedObjectStore.persistentStoreManagedObjectContext)));
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(equalTo(human)));
}

- (void)testShouldFindExistingManagedObjectsByPrimaryKeyPathWithInMemoryCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [mapping setEntityIdentifierWithAttributes:@"railsID"];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"monkey.id" toKeyPath:@"railsID"]];
    
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    human.railsID = [NSNumber numberWithInt:123];
    [managedObjectStore.persistentStoreManagedObjectContext save:nil];

    // Check the count
    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    NSUInteger count = [managedObjectStore.persistentStoreManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    assertThat([NSNumber numberWithInteger:count], is(greaterThan([NSNumber numberWithInteger:0])));
    
    NSDictionary *data = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:123] forKey:@"id"];
    NSDictionary *nestedDictionary = [NSDictionary dictionaryWithObject:data forKey:@"monkey"];
    
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    id object = [dataSource mappingOperation:nil targetObjectForRepresentation:nestedDictionary withMapping:mapping];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(equalTo(human)));
}

- (void)testMappingWithFetchRequestCacheWherePrimaryKeyAttributeOfMappingDisagreesWithEntity
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    mapping.primaryKeyAttribute = @"name";
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    entity.primaryKeyAttributeName = @"railsID";
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"monkey.name" toKeyPath:@"name"]];
    
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    human.name = @"Testing";
    [managedObjectStore.persistentStoreManagedObjectContext save:nil];

    // Check the count
    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    NSUInteger count = [managedObjectStore.persistentStoreManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    assertThat([NSNumber numberWithInteger:count], is(greaterThan([NSNumber numberWithInteger:0])));
    
    NSDictionary *data = [NSDictionary dictionaryWithObject:@"Testing" forKey:@"name"];
    NSDictionary *nestedDictionary = [NSDictionary dictionaryWithObject:data forKey:@"monkey"];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    id object = [dataSource mappingOperation:nil targetObjectForRepresentation:nestedDictionary withMapping:mapping];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(equalTo(human)));
    
    id cachedObject = [managedObjectStore.managedObjectCache findInstanceOfEntity:entity withPrimaryKeyAttribute:@"name" value:@"Testing" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    assertThat(cachedObject, is(equalTo(human)));
}

- (void)testMappingWithInMemoryCacheWherePrimaryKeyAttributeOfMappingDisagreesWithEntity
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:entity];
    mapping.primaryKeyAttribute = @"name";
    entity.primaryKeyAttributeName = @"railsID";
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"monkey.name" toKeyPath:@"name"]];
    
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    human.name = @"Testing";
    [managedObjectStore.persistentStoreManagedObjectContext save:nil];

    // Check the count
    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    NSUInteger count = [managedObjectStore.persistentStoreManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    assertThatInteger(count, is(greaterThan([NSNumber numberWithInteger:0])));
    
    NSDictionary *data = [NSDictionary dictionaryWithObject:@"Testing" forKey:@"name"];
    NSDictionary *nestedDictionary = [NSDictionary dictionaryWithObject:data forKey:@"monkey"];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    id object = [dataSource mappingOperation:nil targetObjectForRepresentation:nestedDictionary withMapping:mapping];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(equalTo(human)));
    
    id cachedObject = [managedObjectStore.managedObjectCache findInstanceOfEntity:entity withPrimaryKeyAttribute:@"name" value:@"Testing" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    assertThat(cachedObject, is(equalTo(human)));
}

- (void)testThatCreationOfNewObjectWithIncorrectTypeValueForPrimaryKeyAddsToCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:entity];
    [mapping setEntityIdentifierWithAttributes:@"railsID"];
    entity.primaryKeyAttributeName = @"railsID";
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"monkey.name" toKeyPath:@"name"]];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"monkey.railsID" toKeyPath:@"railsID"]];
    
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    human.name = @"Testing";
    human.railsID = [NSNumber numberWithInteger:12345];
    [managedObjectStore.persistentStoreManagedObjectContext save:nil];

    // Check the count
    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    NSUInteger count = [managedObjectStore.persistentStoreManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    assertThatInteger(count, is(greaterThan([NSNumber numberWithInteger:0])));
    
    NSDictionary *data = [NSDictionary dictionaryWithObject:@"12345" forKey:@"railsID"];
    NSDictionary *nestedDictionary = [NSDictionary dictionaryWithObject:data forKey:@"monkey"];
    
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    RKHuman *object = [dataSource mappingOperation:nil targetObjectForRepresentation:nestedDictionary withMapping:mapping];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(equalTo(human)));
    assertThatInteger([object.railsID integerValue], is(equalToInteger(12345)));
}

- (void)testThatMappingAnEntityMappingContainingAConnectionMappingWithANilManagedObjectCacheTriggersError
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:entity];
    RKConnectionMapping *connectionMapping = [[RKConnectionMapping alloc] initWithRelationship:entity.relationshipsByName[@"favoriteCat"] sourceKeyPath:@"test" destinationKeyPath:@"test" matcher:nil];
    [mapping addConnectionMapping:connectionMapping];
    
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:nil];
    id mockOperation = [OCMockObject mockForClass:[RKMappingOperation class]];
    [[[mockOperation stub] andReturn:mapping] objectMapping];
    NSError *error = nil;
    BOOL success = [dataSource commitChangesForMappingOperation:mockOperation error:&error];
    expect(success).to.beFalsy();
    expect([error code]).to.equal(RKMappingErrorNilManagedObjectCache);
    expect([error localizedDescription]).to.equal(@"Cannot map an entity mapping that contains connection mappings with a data source whose managed object cache is nil.");
}

@end
