//
//  RKManagedObjectMappingOperationDataSourceTest.m
//  RestKit
//
//  Created by Blake Watters on 7/12/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
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
    mapping.entityIdentifier = [RKEntityIdentifier identifierWithEntityName:@"Human" attributes:@[ @"railsID" ] inManagedObjectStore:managedObjectStore];
    
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
    mapping.entityIdentifier = [RKEntityIdentifier identifierWithEntityName:@"Human" attributes:@[ @"railsID" ] inManagedObjectStore:managedObjectStore];
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
    mapping.entityIdentifier = [RKEntityIdentifier identifierWithEntityName:@"Human" attributes:@[ @"railsID" ] inManagedObjectStore:managedObjectStore];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"railsID"]];
    
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    human.railsID = [NSNumber numberWithInt:123];
    [managedObjectStore.persistentStoreManagedObjectContext save:nil];

    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    NSUInteger count = [managedObjectStore.persistentStoreManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    expect(count).to.beGreaterThan(0);
    
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    NSDictionary *data = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:123] forKey:@"id"];
    id object = [dataSource mappingOperation:nil targetObjectForRepresentation:data withMapping:mapping];
    expect(object).notTo.beNil();
    expect(object).to.equal(human);
}

- (void)testShouldFindExistingManagedObjectsByPrimaryKeyPathWithFetchedResultsCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    mapping.entityIdentifier = [RKEntityIdentifier identifierWithEntityName:@"Human" attributes:@[ @"railsID" ] inManagedObjectStore:managedObjectStore];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"monkey.id" toKeyPath:@"railsID"]];
    
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    human.railsID = [NSNumber numberWithInt:123];
    [managedObjectStore.persistentStoreManagedObjectContext save:nil];

    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    NSUInteger count = [managedObjectStore.persistentStoreManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    expect(count).to.beGreaterThan(0);
    
    NSDictionary *data = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:123] forKey:@"id"];
    NSDictionary *nestedDictionary = [NSDictionary dictionaryWithObject:data forKey:@"monkey"];
    
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    id object = [dataSource mappingOperation:nil targetObjectForRepresentation:nestedDictionary withMapping:mapping];
    expect(object).notTo.beNil();
    expect(object).to.equal(human);
}

- (void)testUsingDateAsIdentifierAttributeWithFetchRequestCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    mapping.entityIdentifier = [RKEntityIdentifier identifierWithEntityName:@"Human" attributes:@[ @"createdAt" ] inManagedObjectStore:managedObjectStore];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"monkey.created_at" toKeyPath:@"createdAt"]];
    
    NSString *createdAtString = @"2012-03-22T11:05:42Z";
    NSDate *createdAtDate = RKDateFromString(createdAtString);
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    human.createdAt = createdAtDate;
    [managedObjectStore.persistentStoreManagedObjectContext save:nil];
    
    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    NSUInteger count = [managedObjectStore.persistentStoreManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    expect(count).to.beGreaterThan(0);
    
    NSDictionary *representation = @{ @"monkey": @{ @"created_at": createdAtString } };
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    id object = [dataSource mappingOperation:nil targetObjectForRepresentation:representation withMapping:mapping];
    expect(object).notTo.beNil();
    expect(object).to.equal(human);
}

#pragma mark - In Memory Cache

- (void)testShouldFindExistingManagedObjectsByPrimaryKeyWithInMemoryCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    mapping.entityIdentifier = [RKEntityIdentifier identifierWithEntityName:@"Human" attributes:@[ @"railsID" ] inManagedObjectStore:managedObjectStore];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"railsID"]];
    
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    human.railsID = [NSNumber numberWithInt:123];
    [managedObjectStore.persistentStoreManagedObjectContext save:nil];

    // Check the count
    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    NSUInteger count = [managedObjectStore.persistentStoreManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    expect(count).to.beGreaterThan(0);
    
    NSDictionary *data = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:123] forKey:@"id"];    
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];    
    NSManagedObject *object = [dataSource mappingOperation:nil targetObjectForRepresentation:data withMapping:mapping];
    expect([object managedObjectContext]).to.equal(managedObjectStore.persistentStoreManagedObjectContext);
    expect(object).notTo.beNil();
    expect(object).to.equal(human);
}

- (void)testShouldFindExistingManagedObjectsByPrimaryKeyPathWithInMemoryCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    mapping.entityIdentifier = [RKEntityIdentifier identifierWithEntityName:@"Human" attributes:@[ @"railsID" ] inManagedObjectStore:managedObjectStore];
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

- (void)testUsingDateAsIdentifierAttributeWithInMemoryCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    mapping.entityIdentifier = [RKEntityIdentifier identifierWithEntityName:@"Human" attributes:@[ @"createdAt" ] inManagedObjectStore:managedObjectStore];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"monkey.created_at" toKeyPath:@"createdAt"]];
    
    NSString *createdAtString = @"2012-03-22T11:05:42Z";
    NSDate *createdAtDate = RKDateFromString(createdAtString);
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    human.createdAt = createdAtDate;
    [managedObjectStore.persistentStoreManagedObjectContext save:nil];
    
    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    NSUInteger count = [managedObjectStore.persistentStoreManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    expect(count).to.beGreaterThan(0);
    
    NSDictionary *representation = @{ @"monkey": @{ @"created_at": createdAtString } };
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    id object = [dataSource mappingOperation:nil targetObjectForRepresentation:representation withMapping:mapping];
    expect(object).notTo.beNil();
    expect(object).to.equal(human);
}

- (void)testThatCreationOfNewObjectWithIncorrectTypeValueForPrimaryKeyAddsToCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:entity];
    mapping.entityIdentifier = [RKEntityIdentifier identifierWithEntityName:@"Human" attributes:@[ @"railsID" ] inManagedObjectStore:managedObjectStore];
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
    RKConnectionDescription *connection = [[RKConnectionDescription alloc] initWithRelationship:entity.relationshipsByName[@"favoriteCat"] attributes:@{ @"railsID": @"railsID" }];
    [mapping addConnection:connection];
    
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

#pragma mark - Rearrange Me

- (void)testCompoundEntityIdentifierWithFetchRequestCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    mapping.entityIdentifier = [RKEntityIdentifier identifierWithEntityName:@"Human" attributes:@[ @"railsID", @"name", @"createdAt" ] inManagedObjectStore:managedObjectStore];
    [mapping addAttributeMappingsFromDictionary:@{ @"monkey.id": @"railsID", @"monkey.name": @"name", @"monkey.created_at": @"createdAt" }];
    
    NSString *createdAtString = @"2012-03-22T11:05:42Z";
    NSDate *createdAtDate = RKDateFromString(createdAtString);
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    human.railsID = @(12345);
    human.createdAt = createdAtDate;
    human.name = @"Reginald";
    [managedObjectStore.persistentStoreManagedObjectContext save:nil];
    
    // Check the count
    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    NSUInteger count = [managedObjectStore.persistentStoreManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    assertThat([NSNumber numberWithInteger:count], is(greaterThan([NSNumber numberWithInteger:0])));
    
    NSDictionary *representation = @{ @"monkey": @{ @"id": @"12345", @"name": @"Reginald", @"created_at": createdAtString } };
    
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    id object = [dataSource mappingOperation:nil targetObjectForRepresentation:representation withMapping:mapping];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(equalTo(human)));
}

- (void)testCompoundEntityIdentifierWithInMemoryCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    mapping.entityIdentifier = [RKEntityIdentifier identifierWithEntityName:@"Human" attributes:@[ @"railsID", @"name", @"createdAt" ] inManagedObjectStore:managedObjectStore];
    [mapping addAttributeMappingsFromDictionary:@{ @"monkey.id": @"railsID", @"monkey.name": @"name", @"monkey.created_at": @"createdAt" }];
    
    NSString *createdAtString = @"2012-03-22T11:05:42Z";
    NSDate *createdAtDate = RKDateFromString(createdAtString);
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    human.railsID = @(12345);
    human.createdAt = createdAtDate;
    human.name = @"Reginald";
    [managedObjectStore.persistentStoreManagedObjectContext save:nil];
    
    // Check the count
    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    NSUInteger count = [managedObjectStore.persistentStoreManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    assertThat([NSNumber numberWithInteger:count], is(greaterThan([NSNumber numberWithInteger:0])));
    
    NSDictionary *representation = @{ @"monkey": @{ @"id": @"12345", @"name": @"Reginald", @"created_at": createdAtString } };
    
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    id object = [dataSource mappingOperation:nil targetObjectForRepresentation:representation withMapping:mapping];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(equalTo(human)));
}

- (void)testRetrievalOfTargetObjectInWhichIdentifierAttributeIsDynamicNestingKey
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    mapping.entityIdentifier = [RKEntityIdentifier identifierWithEntityName:@"Human" attributes:@[ @"name" ] inManagedObjectStore:managedObjectStore];
    [mapping addAttributeMappingFromKeyOfRepresentationToAttribute:@"name"];
    [mapping addAttributeMappingsFromDictionary:@{ @"(name).id": @"railsID" }];
    
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    human.name = @"Blake";
    human.railsID = @(12345);
    [managedObjectStore.persistentStoreManagedObjectContext save:nil];
    
    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    NSUInteger count = [managedObjectStore.persistentStoreManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    expect(count).to.beGreaterThan(0);
    
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    NSDictionary *representation = @{ @"Blake": @{ @"id": @"12345" } };
    id object = [dataSource mappingOperation:nil targetObjectForRepresentation:representation withMapping:mapping];
    expect(object).notTo.beNil();
    expect(object).to.equal(human);
}

- (void)testRetrievalOfTargetObjectInWhichIdentifierAttributeIsCompoundAndOneAttributeIsTheDynamicNestingKey
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    mapping.entityIdentifier = [RKEntityIdentifier identifierWithEntityName:@"Human" attributes:@[ @"name", @"railsID" ] inManagedObjectStore:managedObjectStore];
    [mapping addAttributeMappingFromKeyOfRepresentationToAttribute:@"name"];
    [mapping addAttributeMappingsFromDictionary:@{ @"(name).id": @"railsID" }];
    
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    human.name = @"Blake";
    human.railsID = @(12345);
    [managedObjectStore.persistentStoreManagedObjectContext save:nil];
    
    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    NSUInteger count = [managedObjectStore.persistentStoreManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    expect(count).to.beGreaterThan(0);
    
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    NSDictionary *representation = @{ @"Blake": @{ @"id": @"12345" } };
    id object = [dataSource mappingOperation:nil targetObjectForRepresentation:representation withMapping:mapping];
    expect(object).notTo.beNil();
    expect(object).to.equal(human);
}

- (void)testRetrievalOfTargetObjectInWhichIdentifierAttributeIsCompoundAndOneAttributeIsTheDynamicNestingKeyAndItIsNotTheFirstIdentifierAttribute
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    mapping.entityIdentifier = [RKEntityIdentifier identifierWithEntityName:@"Human" attributes:@[ @"railsID", @"name" ] inManagedObjectStore:managedObjectStore];
    [mapping addAttributeMappingFromKeyOfRepresentationToAttribute:@"name"];
    [mapping addAttributeMappingsFromDictionary:@{ @"(name).id": @"railsID" }];
    
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    human.name = @"Blake";
    human.railsID = @(12345);
    [managedObjectStore.persistentStoreManagedObjectContext save:nil];
    
    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    NSUInteger count = [managedObjectStore.persistentStoreManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    expect(count).to.beGreaterThan(0);
    
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    NSDictionary *representation = @{ @"Blake": @{ @"id": @"12345" } };
    id object = [dataSource mappingOperation:nil targetObjectForRepresentation:representation withMapping:mapping];
    expect(object).notTo.beNil();
    expect(object).to.equal(human);
}

- (void)testEntityIdentifierWithPredicate
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    mapping.entityIdentifier = [RKEntityIdentifier identifierWithEntityName:@"Human" attributes:@[ @"railsID" ] inManagedObjectStore:managedObjectStore];
    mapping.entityIdentifier.predicate = [NSPredicate predicateWithFormat:@"age < 30"];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"railsID"]];
    
    // Create two humans matching the identifier, but differ in matching the 
    RKHuman *human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    human1.name = @"Colin";
    human1.railsID = [NSNumber numberWithInt:123];
    human1.age = @28;
    
    RKHuman *human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    human2.name = @"Blake";
    human2.railsID = [NSNumber numberWithInt:123];
    human2.age = @30;
    [managedObjectStore.persistentStoreManagedObjectContext save:nil];
    
    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    NSUInteger count = [managedObjectStore.persistentStoreManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    expect(count).to.beGreaterThan(0);
    
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    NSDictionary *data = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:123] forKey:@"id"];
    id object = [dataSource mappingOperation:nil targetObjectForRepresentation:data withMapping:mapping];
    expect(object).notTo.beNil();
    expect(object).to.equal(human1);
}

@end
