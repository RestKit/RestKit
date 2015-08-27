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
#import "RKCat.h"
#import "RKHuman.h"
#import "RKChild.h"
#import "RKParent.h"
#import "RKBenchmark.h"

@interface RKManagedObjectMappingOperationDataSourceTest : RKTestCase
@end

/**
 NOTE: You need to take care that you allow the operationQueue to finish before the next test begins execution, else the Core Data tear down can result in intermittent test crashes.
 */
@implementation RKManagedObjectMappingOperationDataSourceTest

- (void)setUp
{    
    [RKTestFactory setUp];
}

- (void)tearDown
{
    [RKTestFactory tearDown];
}

- (NSEntityDescription *)entityWithNameByLoadingModel:(NSString *)entityName
{
  // load the same compiled Core Data model, in the same fashion as the object store, and get its copy of the specified entity description
  NSURL *modelURL = [[RKTestFixture fixtureBundle] URLForResource:@"Data Model" withExtension:@"mom"];
  NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
  NSEntityDescription *loadedEntity = [model entitiesByName][@"Human"];
  return loadedEntity;
}

- (void)testShouldCreateNewInstancesOfUnmanagedObjects
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKMappableObject class]];
    id object = [dataSource mappingOperation:nil targetObjectForRepresentation:@{} withMapping:mapping inRelationship:nil];
    assertThat(object, isNot(nilValue()));
    assertThat([object class], is(equalTo([RKMappableObject class])));
}

- (void)testShouldCreateNewManagedObjectInstancesWhenThereIsNoPrimaryKeyInTheData
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    mapping.identificationAttributes = @[ @"railsID" ];
    
    NSDictionary *data = @{};
    id object = [dataSource mappingOperation:nil targetObjectForRepresentation:data withMapping:mapping inRelationship:nil];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(instanceOf([RKHuman class])));
}

- (void)testShouldCreateNewManagedObjectInstancesWhenThereIsNoPrimaryKeyAttribute
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    
    NSDictionary *data = @{};    
    id object = [dataSource mappingOperation:nil targetObjectForRepresentation:data withMapping:mapping inRelationship:nil];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(instanceOf([RKHuman class])));
}

- (void)testShouldCreateANewManagedObjectWhenThePrimaryKeyValueIsNSNull
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    mapping.identificationAttributes = @[ @"railsID" ];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"railsID"]];
    
    NSDictionary *data = @{@"id": [NSNull null]};    
    id object = [dataSource mappingOperation:nil targetObjectForRepresentation:data withMapping:mapping inRelationship:nil];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(instanceOf([RKHuman class])));
}

- (void)testShouldCreateANewManagedObjectWithAForeignEntityDescription
{
    // easiest way for this situation to arise in real life is running application tests,
    // with mappings that are created within the application code, but a Core Data stack
    // that's configured by the test code, leading to two different copies of the entities
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    NSEntityDescription *entity = [self entityWithNameByLoadingModel:@"Human"];
  
    assertThat(entity, is(notNilValue()));
  
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:entity];
    mapping.identificationAttributes = @[ @"railsID" ];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"railsID"]];
    
    NSDictionary *data = [NSDictionary dictionaryWithObject:[NSNull null] forKey:@"id"];    
    id object = [dataSource mappingOperation:nil targetObjectForRepresentation:data withMapping:mapping inRelationship:nil];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(instanceOf([RKHuman class])));
}

#pragma mark - Fetched Results Cache

- (void)testShouldFindExistingManagedObjectsByPrimaryKeyWithFetchedResultsCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    mapping.identificationAttributes = @[ @"railsID" ];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"railsID"]];
    
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    human.railsID = @123;
    [managedObjectStore.persistentStoreManagedObjectContext save:nil];

    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    NSUInteger count = [managedObjectStore.persistentStoreManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    expect(count).to.beGreaterThan(0);
    
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    NSDictionary *data = @{@"id": @123};
    id object = [dataSource mappingOperation:nil targetObjectForRepresentation:data withMapping:mapping inRelationship:nil];
    expect(object).notTo.beNil();
    expect(object).to.equal(human);
}

- (void)testShouldFindExistingManagedObjectsByPrimaryKeyPathWithFetchedResultsCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    mapping.identificationAttributes = @[ @"railsID" ];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"monkey.id" toKeyPath:@"railsID"]];
    
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    human.railsID = @123;
    [managedObjectStore.persistentStoreManagedObjectContext save:nil];

    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    NSUInteger count = [managedObjectStore.persistentStoreManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    expect(count).to.beGreaterThan(0);
    
    NSDictionary *data = @{@"id": @123};
    NSDictionary *nestedDictionary = @{@"monkey": data};
    
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    id object = [dataSource mappingOperation:nil targetObjectForRepresentation:nestedDictionary withMapping:mapping inRelationship:nil];
    expect(object).notTo.beNil();
    expect(object).to.equal(human);
}

- (void)testUsingDateAsIdentifierAttributeWithFetchRequestCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    mapping.identificationAttributes = @[ @"createdAt" ];
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
    id object = [dataSource mappingOperation:nil targetObjectForRepresentation:representation withMapping:mapping inRelationship:nil];
    expect(object).notTo.beNil();
    expect(object).to.equal(human);
}

#pragma mark - In Memory Cache

- (void)testShouldFindExistingManagedObjectsByPrimaryKeyWithInMemoryCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    mapping.identificationAttributes = @[ @"railsID" ];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"railsID"]];
    
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    human.railsID = @123;
    [managedObjectStore.persistentStoreManagedObjectContext save:nil];

    // Check the count
    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    NSUInteger count = [managedObjectStore.persistentStoreManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    expect(count).to.beGreaterThan(0);
    
    NSDictionary *data = @{@"id": @123};    
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];    
    NSManagedObject *object = [dataSource mappingOperation:nil targetObjectForRepresentation:data withMapping:mapping inRelationship:nil];
    expect([object managedObjectContext]).to.equal(managedObjectStore.persistentStoreManagedObjectContext);
    expect(object).notTo.beNil();
    expect(object).to.equal(human);
}

- (void)testShouldFindExistingManagedObjectsByPrimaryKeyPathWithInMemoryCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    mapping.identificationAttributes = @[ @"railsID" ];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"monkey.id" toKeyPath:@"railsID"]];
    
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    human.railsID = @123;
    [managedObjectStore.persistentStoreManagedObjectContext save:nil];

    // Check the count
    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    NSUInteger count = [managedObjectStore.persistentStoreManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    assertThat([NSNumber numberWithInteger:count], is(greaterThan(@0)));
    
    NSDictionary *data = @{@"id": @123};
    NSDictionary *nestedDictionary = @{@"monkey": data};
    
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    id object = [dataSource mappingOperation:nil targetObjectForRepresentation:nestedDictionary withMapping:mapping inRelationship:nil];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(equalTo(human)));
}

- (void)testUsingDateAsIdentifierAttributeWithInMemoryCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    mapping.identificationAttributes = @[ @"createdAt" ];
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
    id object = [dataSource mappingOperation:nil targetObjectForRepresentation:representation withMapping:mapping inRelationship:nil];
    expect(object).notTo.beNil();
    expect(object).to.equal(human);
}

- (void)testThatCreationOfNewObjectWithIncorrectTypeValueForPrimaryKeyAddsToCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:entity];
    mapping.identificationAttributes = @[ @"railsID" ];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"monkey.name" toKeyPath:@"name"]];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"monkey.railsID" toKeyPath:@"railsID"]];
    
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    human.name = @"Testing";
    human.railsID = @12345;
    [managedObjectStore.persistentStoreManagedObjectContext save:nil];

    // Check the count
    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    NSUInteger count = [managedObjectStore.persistentStoreManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    assertThatInteger(count, is(greaterThan(@0)));
    
    NSDictionary *data = @{@"railsID": @"12345"};
    NSDictionary *nestedDictionary = @{@"monkey": data};
    
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    RKHuman *object = [dataSource mappingOperation:nil targetObjectForRepresentation:nestedDictionary withMapping:mapping inRelationship:nil];
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
    [[mockOperation stub] destinationObject];
    [[[mockOperation stub] andReturn:mapping] objectMapping];
    NSError *error = nil;
    BOOL success = [dataSource commitChangesForMappingOperation:mockOperation error:&error];
    expect(success).to.beFalsy();
    expect([error code]).to.equal(RKMappingErrorNilManagedObjectCache);
    expect([error localizedDescription]).to.equal(@"Cannot map an entity mapping that contains connection mappings with a data source whose managed object cache is nil.");
}

#pragma mark - Value Transformers

- (void)testCustomAttributeMappingValueTransformer
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:entity];
    
    RKValueTransformer *valueTransformer = [RKBlockValueTransformer valueTransformerWithValidationBlock:^BOOL(__unsafe_unretained Class sourceClass, __unsafe_unretained Class destinationClass) {
       
        return ([sourceClass isSubclassOfClass:[NSString class]] && [destinationClass isSubclassOfClass:[NSString class]]);
    
    } transformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, Class outputValueClass, NSError *__autoreleasing *error) {
        
        RKValueTransformerTestInputValueIsKindOfClass(inputValue, [NSString class], error);
        RKValueTransformerTestOutputValueClassIsSubclassOfClass(outputValueClass, [NSString class], error);
        
        *outputValue = [(NSString *)inputValue uppercaseString];
        return YES;
    }];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    nameMapping.valueTransformer = valueTransformer;
    [mapping addAttributeMappingsFromArray:@[ nameMapping ]];
    mapping.identificationAttributes = @[ @"name" ];
    
    NSDictionary *representation = @{ @"name" : @"Blake Watters" };
    
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    id object = [dataSource mappingOperation:nil targetObjectForRepresentation:representation withMapping:mapping inRelationship:nil];
    
    RKHuman *human = (RKHuman *)object;
    assertThat(human, isNot(nilValue()));
    assertThat(human.name, is(equalTo(@"BLAKE WATTERS")));
}

#pragma mark - Rearrange Me

- (void)testCompoundEntityIdentifierWithFetchRequestCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    mapping.identificationAttributes = @[ @"railsID", @"name", @"createdAt" ];
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
    assertThat([NSNumber numberWithInteger:count], is(greaterThan(@0)));
    
    NSDictionary *representation = @{ @"monkey": @{ @"id": @"12345", @"name": @"Reginald", @"created_at": createdAtString } };
    
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    id object = [dataSource mappingOperation:nil targetObjectForRepresentation:representation withMapping:mapping inRelationship:nil];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(equalTo(human)));
}

- (void)testCompoundEntityIdentifierWithInMemoryCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    mapping.identificationAttributes = @[ @"railsID", @"name", @"createdAt" ];
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
    assertThat([NSNumber numberWithInteger:count], is(greaterThan(@0)));
    
    NSDictionary *representation = @{ @"monkey": @{ @"id": @"12345", @"name": @"Reginald", @"created_at": createdAtString } };
    
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    id object = [dataSource mappingOperation:nil targetObjectForRepresentation:representation withMapping:mapping inRelationship:nil];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(equalTo(human)));
}

- (void)testRetrievalOfTargetObjectInWhichIdentifierAttributeIsDynamicNestingKey
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    mapping.identificationAttributes = @[ @"name" ];
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
    id object = [dataSource mappingOperation:nil targetObjectForRepresentation:representation withMapping:mapping inRelationship:nil];
    expect(object).notTo.beNil();
    expect(object).to.equal(human);
}

- (void)testRetrievalOfTargetObjectWithDynamicNestingKeyMappingInWhichIdentifierAttributeIsNotTheDynamicNestingKey
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    mapping.identificationAttributes = @[ @"railsID" ];
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
    id object = [dataSource mappingOperation:nil targetObjectForRepresentation:representation withMapping:mapping inRelationship:nil];
    expect(object).notTo.beNil();
    expect(object).to.equal(human);
}

- (void)testRetrievalOfTargetObjectInWhichIdentifierAttributeIsCompoundAndOneAttributeIsTheDynamicNestingKey
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    mapping.identificationAttributes = @[ @"name", @"railsID" ];
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
    id object = [dataSource mappingOperation:nil targetObjectForRepresentation:representation withMapping:mapping inRelationship:nil];
    expect(object).notTo.beNil();
    expect(object).to.equal(human);
}

- (void)testRetrievalOfTargetObjectInWhichIdentifierAttributeIsCompoundAndOneAttributeIsTheDynamicNestingKeyAndItIsNotTheFirstIdentifierAttribute
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    mapping.identificationAttributes = @[ @"railsID", @"name" ];
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
    id object = [dataSource mappingOperation:nil targetObjectForRepresentation:representation withMapping:mapping inRelationship:nil];
    expect(object).notTo.beNil();
    expect(object).to.equal(human);
}

- (void)testEntityIdentifierWithPredicate
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    mapping.identificationAttributes = @[ @"railsID" ];
    mapping.identificationPredicate = [NSPredicate predicateWithFormat:@"age < 30"];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"railsID"]];
    
    // Create two humans matching the identifier, but differ in matching the 
    RKHuman *human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    human1.name = @"Colin";
    human1.railsID = @123;
    human1.age = @28;
    
    RKHuman *human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    human2.name = @"Blake";
    human2.railsID = @123;
    human2.age = @30;
    [managedObjectStore.persistentStoreManagedObjectContext save:nil];
    
    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    NSUInteger count = [managedObjectStore.persistentStoreManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    expect(count).to.beGreaterThan(0);
    
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    NSDictionary *data = @{@"id": @123};
    id object = [dataSource mappingOperation:nil targetObjectForRepresentation:data withMapping:mapping inRelationship:nil];
    expect(object).notTo.beNil();
    expect(object).to.equal(human1);
}

- (void)testEntityIdentifierWithPredicateBlock
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    mapping.identificationAttributes = @[ @"railsID" ];
    mapping.identificationPredicateBlock = ^(NSDictionary *representation, NSManagedObjectContext *context) {
        return [NSPredicate predicateWithFormat:@"age + 94 < %@", representation[@"id"]];
    };
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"railsID"]];
    
    // Create two humans matching the identifier, but differ in matching the
    RKHuman *human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    human1.name = @"Colin";
    human1.railsID = @123;
    human1.age = @28;
    
    RKHuman *human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    human2.name = @"Blake";
    human2.railsID = @123;
    human2.age = @30;
    [managedObjectStore.persistentStoreManagedObjectContext save:nil];
    
    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    NSUInteger count = [managedObjectStore.persistentStoreManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    expect(count).to.beGreaterThan(0);
    
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    NSDictionary *data = @{@"id": @123};
    id object = [dataSource mappingOperation:nil targetObjectForRepresentation:data withMapping:mapping inRelationship:nil];
    expect(object).notTo.beNil();
    expect(object).to.equal(human1);
}

- (void)testMappingInPrivateQueue
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    managedObjectContext.parentContext = managedObjectStore.persistentStoreManagedObjectContext;
    managedObjectContext.mergePolicy  = NSMergeByPropertyStoreTrumpMergePolicy;
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectContext
                                                                                                                                                      cache:managedObjectCache];

    __block BOOL success;
    __block NSError *error;
    NSDictionary *sourceObject = @{ @"name" : @"Blake Watters" };
    [managedObjectContext performBlockAndWait:^{
        RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
        humanMapping.identificationAttributes = @[ @"railsID" ];
        [humanMapping addAttributeMappingsFromArray:@[@"name", @"favoriteCatID"]];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Human" inManagedObjectContext:managedObjectContext];
        RKHuman *human = [[RKHuman alloc] initWithEntity:entity insertIntoManagedObjectContext:managedObjectContext];
        RKMappingOperation *mappingOperation = [[RKMappingOperation alloc] initWithSourceObject:sourceObject destinationObject:human mapping:humanMapping];
        mappingOperation.dataSource = mappingOperationDataSource;
        success = [mappingOperation performMapping:&error];

        assertThatBool(success, is(equalToBool(YES)));
        assertThat(human.name, is(equalTo(@"Blake Watters")));
    }];
}

- (void)testShouldConnectRelationshipsByPrimaryKey
{
    /* Connect a new human to a cat */
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];

    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"Cat" inManagedObjectStore:managedObjectStore];
    catMapping.identificationAttributes = @[ @"railsID" ];
    [catMapping addAttributeMappingsFromArray:@[@"name"]];

    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    humanMapping.identificationAttributes = @[ @"railsID" ];
    [humanMapping addAttributeMappingsFromArray:@[@"name", @"favoriteCatID"]];
    [humanMapping addConnectionForRelationship:@"favoriteCat" connectedBy:@{ @"favoriteCatID": @"railsID" }];

    // Create a cat to connect
    RKCat *cat = [NSEntityDescription insertNewObjectForEntityForName:@"Cat" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    cat.name = @"Asia";
    cat.railsID = @31337;
    [managedObjectStore.persistentStoreManagedObjectContext save:nil];

    NSDictionary *mappableData = @{ @"name": @"Blake", @"favoriteCatID": @31337 };
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    mappingOperationDataSource.operationQueue = [NSOperationQueue new];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    operation.dataSource = mappingOperationDataSource;
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    [mappingOperationDataSource.operationQueue waitUntilAllOperationsAreFinished];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(human.favoriteCat, isNot(nilValue()));
    assertThat(human.favoriteCat.name, is(equalTo(@"Asia")));
    
    [mappingOperationDataSource.operationQueue waitUntilAllOperationsAreFinished];
}

- (void)testShouldConnectRelationshipsByPrimaryKeyReverse
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSManagedObjectContext *managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;

    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    humanMapping.identificationAttributes = @[ @"railsID" ];
    [humanMapping addAttributeMappingsFromArray:@[@"name", @"favoriteCatID"]];

    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"Cat" inManagedObjectStore:managedObjectStore];
    catMapping.identificationAttributes = @[ @"railsID" ];
    [catMapping addAttributeMappingsFromArray:@[@"name", @"railsID"]];
    [catMapping addConnectionForRelationship:@"favoriteOfHumans" connectedBy:@{ @"railsID": @"favoriteCatID" }];

    // Create some humans to connect
    RKHuman *blake = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    blake.name = @"Blake";
    blake.favoriteCatID = @31340;

    RKHuman *jeremy = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    jeremy.name = @"Jeremy";
    jeremy.favoriteCatID = @31340;

    [managedObjectStore.persistentStoreManagedObjectContext save:nil];

    NSDictionary *mappableData = @{ @"name": @"Asia", @"railsID": @31340 };
    RKCat *cat = [NSEntityDescription insertNewObjectForEntityForName:@"Cat" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    NSOperationQueue *operationQueue = [NSOperationQueue new];
    [operationQueue setSuspended:YES];
    mappingOperationDataSource.operationQueue = operationQueue;
    __block BOOL success;
    [managedObjectContext performBlockAndWait:^{
        RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:mappableData destinationObject:cat mapping:catMapping];
        operation.dataSource = mappingOperationDataSource;
        NSError *error = nil;
        success = [operation performMapping:&error];
    }];

    [operationQueue setSuspended:NO];
    [operationQueue waitUntilAllOperationsAreFinished];

    assertThatBool(success, is(equalToBool(YES)));
    assertThat(cat.favoriteOfHumans, isNot(nilValue()));
    assertThat([cat.favoriteOfHumans valueForKeyPath:@"name"], containsInAnyOrder(blake.name, jeremy.name, nil));
}

- (void)testConnectionOfHasManyRelationshipsByPrimaryKey
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];

    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"Cat" inManagedObjectStore:managedObjectStore];
    catMapping.identificationAttributes = @[ @"railsID" ];
    [catMapping addAttributeMappingsFromArray:@[@"name"]];

    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    humanMapping.identificationAttributes = @[ @"railsID" ];
    [humanMapping addAttributeMappingsFromArray:@[@"name", @"favoriteCatID"]];
    [humanMapping addConnectionForRelationship:@"favoriteCat" connectedBy:@{ @"favoriteCatID": @"railsID" }];

    // Create a cat to connect
    RKCat *cat = [NSEntityDescription insertNewObjectForEntityForName:@"Cat" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    cat.name = @"Asia";
    cat.railsID = @31337;
    [managedObjectStore.persistentStoreManagedObjectContext save:nil];

    NSDictionary *mappableData = @{ @"name": @"Blake", @"favoriteCatID": @31337 };
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    mappingOperationDataSource.operationQueue = [NSOperationQueue new];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    operation.dataSource = mappingOperationDataSource;
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    [mappingOperationDataSource.operationQueue waitUntilAllOperationsAreFinished];
    assertThat(human.favoriteCat, isNot(nilValue()));
    assertThat(human.favoriteCat.name, is(equalTo(@"Asia")));
}

- (void)testConnectingARelationshipFromASourceAttributeWhoseValueIsACollectionWithFetchRequestCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];

    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"Cat" inManagedObjectStore:managedObjectStore];
    catMapping.identificationAttributes = @[ @"railsID" ];
    [catMapping addAttributeMappingsFromArray:@[@"name"]];

    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    humanMapping.identificationAttributes = @[ @"railsID" ];
    [humanMapping addAttributeMappingsFromArray:@[@"name", @"catIDs"]];
    [humanMapping addConnectionForRelationship:@"cats" connectedBy:@{ @"catIDs": @"railsID" }];

    // Create a couple of cats to connect
    RKCat *asia = [NSEntityDescription insertNewObjectForEntityForName:@"Cat" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    asia.name = @"Asia";
    asia.railsID = @31337;

    RKCat *roy = [NSEntityDescription insertNewObjectForEntityForName:@"Cat" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    roy.name = @"Reginald Royford Williams III";
    roy.railsID = @31338;

    [managedObjectStore.persistentStoreManagedObjectContext save:nil];

    NSArray *catIDs = @[@31337, @31338];
    NSDictionary *mappableData = @{ @"name": @"Blake", @"catIDs": catIDs };
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];

    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    mappingOperationDataSource.operationQueue = [NSOperationQueue new];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    operation.dataSource = mappingOperationDataSource;
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    [mappingOperationDataSource.operationQueue waitUntilAllOperationsAreFinished];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(human.cats, isNot(nilValue()));
    assertThat([human.cats valueForKeyPath:@"name"], containsInAnyOrder(@"Asia", @"Reginald Royford Williams III", nil));
}

- (void)testConnectingARelationshipFromASourceAttributeWhoseValueIsACollectionWithInMemoryCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];

    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"Cat" inManagedObjectStore:managedObjectStore];
    catMapping.identificationAttributes = @[ @"railsID" ];
    [catMapping addAttributeMappingsFromArray:@[@"name"]];

    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    humanMapping.identificationAttributes = @[ @"railsID" ];
    [humanMapping addAttributeMappingsFromArray:@[@"name", @"catIDs"]];
    [humanMapping addConnectionForRelationship:@"cats" connectedBy:@{ @"catIDs": @"railsID" }];

    // Create a couple of cats to connect
    RKCat *asia = [NSEntityDescription insertNewObjectForEntityForName:@"Cat" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    asia.name = @"Asia";
    asia.railsID = @31337;

    RKCat *roy = [NSEntityDescription insertNewObjectForEntityForName:@"Cat" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    roy.name = @"Reginald Royford Williams III";
    roy.railsID = @31338;

    [managedObjectStore.persistentStoreManagedObjectContext save:nil];

    NSArray *catIDs = @[@31337, @31338];
    NSDictionary *mappableData = @{ @"name": @"Blake", @"catIDs": catIDs };
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];

    RKInMemoryManagedObjectCache *managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    mappingOperationDataSource.operationQueue = [NSOperationQueue new];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    operation.dataSource = mappingOperationDataSource;
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
//    expect([mappingOperationDataSource.operationQueue operationCount]).will.equal(0);
    [mappingOperationDataSource.operationQueue waitUntilAllOperationsAreFinished];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(human.cats, isNot(nilValue()));
    assertThat([human.cats valueForKeyPath:@"name"], containsInAnyOrder(@"Asia", @"Reginald Royford Williams III", nil));
}

- (void)testShouldConnectRelationshipsByPrimaryKeyWithDifferentSourceAndDestinationKeyPathsReverse
{
    /* Connect a new cat to a human */
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];

    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    humanMapping.identificationAttributes = @[ @"railsID" ];
    [humanMapping addAttributeMappingsFromArray:@[@"name", @"railsID"]];

    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"Cat" inManagedObjectStore:managedObjectStore];
    catMapping.identificationAttributes = @[ @"railsID" ];
    [catMapping addAttributeMappingsFromArray:@[@"name", @"humanId"]];
    [catMapping addConnectionForRelationship:@"human" connectedBy:@{ @"humanId": @"railsID" }];

    // Create a human to connect
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    human.name = @"Blake";
    human.railsID = @31337;
    [managedObjectStore.persistentStoreManagedObjectContext save:nil];

    NSDictionary *mappableData = @{ @"name": @"Asia", @"humanId": @31337 };
    RKCat *cat = [NSEntityDescription insertNewObjectForEntityForName:@"Cat" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    mappingOperationDataSource.operationQueue = [NSOperationQueue new];
    RKMappingOperation* operation = [[RKMappingOperation alloc] initWithSourceObject:mappableData destinationObject:cat mapping:catMapping];
    operation.dataSource = mappingOperationDataSource;
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    [mappingOperationDataSource.operationQueue waitUntilAllOperationsAreFinished];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(cat.human, isNot(nilValue()));
    assertThat(cat.human.name, is(equalTo(@"Blake")));
}

- (void)testShouldLoadNestedHasManyRelationship
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"Cat" inManagedObjectStore:managedObjectStore];
    catMapping.identificationAttributes = @[ @"railsID" ];
    [catMapping addAttributeMappingsFromArray:@[@"name"]];

    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    humanMapping.identificationAttributes = @[ @"railsID" ];
    [humanMapping addAttributeMappingsFromArray:@[@"name", @"favoriteCatID"]];
    [humanMapping addRelationshipMappingWithSourceKeyPath:@"cats" mapping:catMapping];

    NSArray *catsData = @[@{@"name": @"Asia"}];
    NSDictionary *mappableData = @{ @"name": @"Blake", @"favoriteCatID": @31337, @"cats": catsData };
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    operation.dataSource = mappingOperationDataSource;
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
}

- (void)testShouldLoadOrderedHasManyRelationship
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"Cat" inManagedObjectStore:managedObjectStore];
    catMapping.identificationAttributes = @[ @"railsID" ];
    [catMapping addAttributeMappingsFromArray:@[@"name"]];

    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    humanMapping.identificationAttributes = @[ @"railsID" ];
    [humanMapping addAttributeMappingsFromArray:@[@"name", @"favoriteCatID"]];
    [humanMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"cats" toKeyPath:@"catsInOrderByAge" withMapping:catMapping]];;

    NSArray *catsData = @[@{@"name": @"Asia"}];
    NSDictionary *mappableData = @{ @"name": @"Blake", @"favoriteCatID": @31337, @"cats": catsData };
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    operation.dataSource = mappingOperationDataSource;
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat([human catsInOrderByAge], isNot(isEmpty()));
}

- (void)testShouldMapNullToAHasManyRelationship
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"Cat" inManagedObjectStore:managedObjectStore];
    [catMapping addAttributeMappingsFromArray:@[@"name"]];

    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [humanMapping addAttributeMappingsFromArray:@[@"name", @"favoriteCatID"]];
    [humanMapping addRelationshipMappingWithSourceKeyPath:@"cats" mapping:catMapping];

    NSDictionary *mappableData = @{ @"name": @"Blake", @"cats": [NSNull null] };
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    operation.dataSource = mappingOperationDataSource;
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(human.cats, isEmpty());
}

- (void)testShouldLoadNestedHasManyRelationshipWithoutABackingClass
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *cloudMapping = [RKEntityMapping mappingForEntityForName:@"Cloud" inManagedObjectStore:managedObjectStore];
    [cloudMapping addAttributeMappingsFromArray:@[@"name"]];

    RKEntityMapping *stormMapping = [RKEntityMapping mappingForEntityForName:@"Storm" inManagedObjectStore:managedObjectStore];
    [stormMapping addAttributeMappingsFromArray:@[@"name"]];
    [stormMapping addRelationshipMappingWithSourceKeyPath:@"clouds" mapping:cloudMapping];

    NSArray *cloudsData = @[@{@"name": @"Nimbus"}];
    NSDictionary *mappableData = @{ @"name": @"Hurricane", @"clouds": cloudsData };
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Storm" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    NSManagedObject *storm = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:mappableData destinationObject:storm mapping:stormMapping];
    operation.dataSource = mappingOperationDataSource;
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
}

- (void)testShouldConnectManyToManyRelationships
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *childMapping = [RKEntityMapping mappingForEntityForName:@"Child" inManagedObjectStore:managedObjectStore];
    childMapping.identificationAttributes = @[ @"name" ];
    [childMapping addAttributeMappingsFromArray:@[@"name"]];

    RKEntityMapping *parentMapping = [RKEntityMapping mappingForEntityForName:@"Parent" inManagedObjectStore:managedObjectStore];
    parentMapping.identificationAttributes = @[ @"railsID" ];
    [parentMapping addAttributeMappingsFromArray:@[@"name", @"age"]];
    [parentMapping addRelationshipMappingWithSourceKeyPath:@"children" mapping:childMapping];

    NSArray *childMappableData = @[ @{ @"name": @"Maya" }, @{ @"name": @"Brady" } ];
    NSDictionary *parentMappableData = @{ @"name": @"Win", @"age": @34, @"children": childMappableData };
    RKParent *parent = [NSEntityDescription insertNewObjectForEntityForName:@"Parent" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    mappingOperationDataSource.operationQueue = [NSOperationQueue new];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:parentMappableData destinationObject:parent mapping:parentMapping];
    operation.dataSource = mappingOperationDataSource;
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(parent.children, isNot(nilValue()));
    assertThatUnsignedInteger([parent.children count], is(equalToInt(2)));
    assertThat([[parent.children anyObject] parents], isNot(nilValue()));
    assertThatBool([[[parent.children anyObject] parents] containsObject:parent], is(equalToBool(YES)));
    assertThatUnsignedInteger([[[parent.children anyObject] parents] count], is(equalToInt(1)));
    
    [mappingOperationDataSource.operationQueue waitUntilAllOperationsAreFinished];
}

- (void)testShouldConnectRelationshipsByPrimaryKeyRegardlessOfOrder
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSManagedObjectContext *managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;

    RKEntityMapping *parentMapping = [RKEntityMapping mappingForEntityForName:@"Parent" inManagedObjectStore:managedObjectStore];
    [parentMapping addAttributeMappingsFromArray:@[@"parentID"]];
    parentMapping.identificationAttributes = @[ @"parentID" ];

    RKEntityMapping *childMapping = [RKEntityMapping mappingForEntityForName:@"Child" inManagedObjectStore:managedObjectStore];
    [childMapping addAttributeMappingsFromArray:@[@"fatherID"]];
    [childMapping addConnectionForRelationship:@"father" connectedBy:@{ @"fatherID": @"parentID" }];

    NSDictionary *mappingsDictionary = @{ @"parents": parentMapping, @"children": childMapping };
    NSDictionary *JSON = [RKTestFixture parsedObjectWithContentsOfFixture:@"ConnectingParents.json"];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    NSOperationQueue *operationQueue = [NSOperationQueue new];
    [operationQueue setSuspended:YES];
    mappingOperationDataSource.operationQueue = operationQueue;
    [managedObjectContext performBlockAndWait:^{
        RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:JSON mappingsDictionary:mappingsDictionary];
        mapper.mappingOperationDataSource = mappingOperationDataSource;
        [mapper start];
    }];

    [operationQueue setSuspended:NO];
    [operationQueue waitUntilAllOperationsAreFinished];

    [managedObjectContext performBlockAndWait:^{
        NSError *error;
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Parent"];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"parentID = %@", @1];
        fetchRequest.fetchLimit = 1;
        NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
        RKParent *parent = [results lastObject];
        assertThat(parent, is(notNilValue()));
        NSSet *children = [parent fatheredChildren];
        assertThat(children, hasCountOf(1));
        RKChild *child = [children anyObject];
        assertThat(child.father, is(notNilValue()));
    }];
}

- (void)testMappingAPayloadContainingRepeatedObjectsDoesNotYieldDuplicatesWithFetchRequestMappingCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    managedObjectStore.managedObjectCache = managedObjectCache;

    RKEntityMapping *childMapping = [RKEntityMapping mappingForEntityForName:@"Child" inManagedObjectStore:managedObjectStore];
    childMapping.identificationAttributes = @[ @"childID" ];
    [childMapping addAttributeMappingsFromArray:@[@"name", @"childID"]];

    RKEntityMapping *parentMapping = [RKEntityMapping mappingForEntityForName:@"Parent" inManagedObjectStore:managedObjectStore];
    [parentMapping addAttributeMappingsFromArray:@[@"parentID", @"name"]];
    parentMapping.identificationAttributes = @[ @"parentID" ];
    [parentMapping addRelationshipMappingWithSourceKeyPath:@"children" mapping:childMapping];

    NSDictionary *mappingsDictionary = @{ @"parents": parentMapping };

    NSDictionary *JSON = [RKTestFixture parsedObjectWithContentsOfFixture:@"parents_and_children.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:JSON mappingsDictionary:mappingsDictionary];
    mapper.mappingOperationDataSource = mappingOperationDataSource;
    [mapper start];

    NSUInteger parentCount = [managedObjectStore.persistentStoreManagedObjectContext countForEntityForName:@"Parent" predicate:nil error:nil];
    NSUInteger childrenCount = [managedObjectStore.persistentStoreManagedObjectContext countForEntityForName:@"Child" predicate:nil error:nil];
    assertThatInteger(parentCount, is(equalToInteger(2)));
    assertThatInteger(childrenCount, is(equalToInteger(4)));
}

- (void)testMappingAPayloadContainingRepeatedObjectsDoesNotYieldDuplicatesWithInMemoryMappingCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKInMemoryManagedObjectCache *managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    managedObjectStore.managedObjectCache = managedObjectCache;

    RKEntityMapping *childMapping = [RKEntityMapping mappingForEntityForName:@"Child" inManagedObjectStore:managedObjectStore];
    childMapping.identificationAttributes = @[ @"childID" ];
    [childMapping addAttributeMappingsFromArray:@[@"name", @"childID"]];

    RKEntityMapping *parentMapping = [RKEntityMapping mappingForEntityForName:@"Parent" inManagedObjectStore:managedObjectStore];
    [parentMapping addAttributeMappingsFromArray:@[@"parentID", @"name"]];
    parentMapping.identificationAttributes = @[ @"parentID" ];
    [parentMapping addRelationshipMappingWithSourceKeyPath:@"children" mapping:childMapping];

    // NOTE: This may be fragile. Reverse order seems to trigger them to be mapped parent first. NSDictionary
    // keys are not guaranteed to return in any particular order
    NSDictionary *mappingsDictionary = @{ @"parents": parentMapping };

    NSDictionary *JSON = [RKTestFixture parsedObjectWithContentsOfFixture:@"parents_and_children.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:JSON mappingsDictionary:mappingsDictionary];
    mapper.mappingOperationDataSource = mappingOperationDataSource;
    [mapper start];

    NSError *error = nil;
    BOOL success = [managedObjectStore.persistentStoreManagedObjectContext save:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(error, is(nilValue()));

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Parent"];
    NSUInteger parentCount = [managedObjectStore.persistentStoreManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    NSUInteger childrenCount = [managedObjectStore.persistentStoreManagedObjectContext countForEntityForName:@"Child" predicate:nil error:nil];
    assertThatInteger(parentCount, is(equalToInteger(2)));
    assertThatInteger(childrenCount, is(equalToInteger(4)));
}

- (void)testThatMappingObjectsWithTheSameIdentificationAttributesAcrossTwoContextsDoesNotCreateDuplicateObjects
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKInMemoryManagedObjectCache *inMemoryCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    managedObjectStore.managedObjectCache = inMemoryCache;
    NSEntityDescription *humanEntity = [NSEntityDescription entityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    mapping.identificationAttributes = @[ @"railsID" ];
    [mapping addAttributeMappingsFromArray:@[ @"name", @"railsID" ]];
    
    // Create two contexts with common parent
    NSManagedObjectContext *firstContext = [managedObjectStore newChildManagedObjectContextWithConcurrencyType:NSPrivateQueueConcurrencyType tracksChanges:NO];
    NSManagedObjectContext *secondContext = [managedObjectStore newChildManagedObjectContextWithConcurrencyType:NSPrivateQueueConcurrencyType tracksChanges:NO];
    
    // Map into the first context
    NSDictionary *objectRepresentation = @{ @"name": @"Blake", @"railsID": @(31337) };
    
    // Check that the cache contains a value for our identification attributes
    __block BOOL success;
    __block NSError *error;
    [firstContext performBlockAndWait:^{
        RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:firstContext
                                                                                                                                          cache:inMemoryCache];
        RKMapperOperation *mapperOperation = [[RKMapperOperation alloc] initWithRepresentation:objectRepresentation mappingsDictionary:@{ [NSNull null]: mapping }];
        mapperOperation.mappingOperationDataSource = dataSource;
        success = [mapperOperation execute:&error];
        expect(success).to.equal(YES);
        expect([mapperOperation.mappingResult count]).to.equal(1);
        
        [firstContext save:nil];
    }];
    
    // Check that there is an entry in the cache
    NSSet *objects = [inMemoryCache managedObjectsWithEntity:humanEntity attributeValues:@{ @"railsID": @(31337) } inManagedObjectContext:firstContext];
    expect(objects).to.haveCountOf(1);
    
    // Map into the second context
    [secondContext performBlockAndWait:^{
        RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:secondContext
                                                                                                                                          cache:inMemoryCache];
        RKMapperOperation *mapperOperation = [[RKMapperOperation alloc] initWithRepresentation:objectRepresentation mappingsDictionary:@{ [NSNull null]: mapping }];
        mapperOperation.mappingOperationDataSource = dataSource;
        success = [mapperOperation execute:&error];
        expect(success).to.equal(YES);
        expect([mapperOperation.mappingResult count]).to.equal(1);
        
        [secondContext save:nil];
    }];
    
    // Now check the count
    objects = [inMemoryCache managedObjectsWithEntity:humanEntity attributeValues:@{ @"railsID": @(31337) } inManagedObjectContext:secondContext];
    expect(objects).to.haveCountOf(1);
    
    // Now pull the count back from the parent context
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"railsID == 31337"];
    NSArray *fetchedObjects = [managedObjectStore.persistentStoreManagedObjectContext executeFetchRequest:fetchRequest error:nil];
    expect(fetchedObjects).to.haveCountOf(1);
}

- (void)testConnectingToSubentitiesByFetchRequestCache
{
    
}

- (void)testConnectingToSubentitiesByInMemoryCache
{
    
}

- (void)testDeletionOfTombstoneRecords
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:entity];
    [mapping addAttributeMappingsFromArray:@[ @"name" ]];
    mapping.deletionPredicate = [NSPredicate predicateWithFormat:@"sex = %@", @"female"];

    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    human.sex = @"female";

    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:nil];
    NSDictionary *representation = @{ @"name": @"Whatever" };
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:representation destinationObject:human mapping:mapping];
    operation.dataSource = dataSource;
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    expect([human isDeleted]).will.equal(YES);
}

- (void)testDeletionWithForeignEntityDescription
{
  // easiest way for this situation to arise in real life is running application tests,
  // with mappings that are created within the application code, but a Core Data stack
  // that's configured by the test code, leading to two different copies of the entities
  RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
  NSEntityDescription *contextEntity = [NSEntityDescription entityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
  NSEntityDescription *loadedEntity = [self entityWithNameByLoadingModel:@"Human"];
  
  assertThat(contextEntity, is(notNilValue()));
  assertThat(loadedEntity, is(notNilValue()));
  assertThat(loadedEntity, isNot(sameInstance(contextEntity)));
  
  RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:loadedEntity];
  [mapping addAttributeMappingsFromArray:@[ @"name" ]];
  mapping.deletionPredicate = [NSPredicate predicateWithFormat:@"sex = %@", @"female"];
  
  RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
  human.sex = @"female";
  
  RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                    cache:nil];
  NSDictionary *representation = @{ @"name": @"Whatever" };
  RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:representation destinationObject:human mapping:mapping];
  operation.dataSource = dataSource;
  NSError *error = nil;
  BOOL success = [operation performMapping:&error];
  assertThatBool(success, is(equalToBool(YES)));
  expect([human isDeleted]).will.equal(YES);
}

- (void)testDeletionOfTombstoneRecordsInMapperOperation
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:entity];
    [mapping addAttributeMappingsFromArray:@[ @"name" ]];
    mapping.deletionPredicate = [NSPredicate predicateWithFormat:@"sex = %@", @"female"];

    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    human.sex = @"female";

    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:nil];
    NSDictionary *representation = @{ @"name": @"Whatever" };
    NSError *error = nil;
    RKMapperOperation *mapperOperation = [[RKMapperOperation alloc] initWithRepresentation:representation mappingsDictionary:@{ [NSNull null]: mapping }];
    mapperOperation.mappingOperationDataSource = dataSource;
    BOOL success = [mapperOperation execute:&error];
    assertThatBool(success, is(equalToBool(YES)));
    expect([human isDeleted]).will.equal(YES);
}

- (void)testMappingAPayloadContainingRepeatedObjectsPerformsAcceptablyWithFetchRequestMappingCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    managedObjectStore.managedObjectCache = managedObjectCache;

    RKEntityMapping *childMapping = [RKEntityMapping mappingForEntityForName:@"Child" inManagedObjectStore:managedObjectStore];
    childMapping.identificationAttributes = @[ @"childID" ];
    [childMapping addAttributeMappingsFromArray:@[@"name", @"childID"]];

    RKEntityMapping *parentMapping = [RKEntityMapping mappingForEntityForName:@"Parent" inManagedObjectStore:managedObjectStore];
    [parentMapping addAttributeMappingsFromArray:@[@"parentID", @"name"]];
    parentMapping.identificationAttributes = @[ @"parentID" ];
    [parentMapping addRelationshipMappingWithSourceKeyPath:@"children" mapping:childMapping];


    NSDictionary *mappingsDictionary = @{ @"parents": parentMapping };
    NSDictionary *JSON = [RKTestFixture parsedObjectWithContentsOfFixture:@"benchmark_parents_and_children.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:JSON mappingsDictionary:mappingsDictionary];
    mapper.mappingOperationDataSource = mappingOperationDataSource;

    [RKBenchmark report:@"Mapping with Fetch Request Cache" executionBlock:^{
        for (NSUInteger i = 0; i < 50; i++) {
            [mapper start];
        }
    }];
    NSUInteger parentCount = [managedObjectStore.persistentStoreManagedObjectContext countForEntityForName:@"Parent" predicate:nil error:nil];
    NSUInteger childrenCount = [managedObjectStore.persistentStoreManagedObjectContext countForEntityForName:@"Child" predicate:nil error:nil];
    assertThatInteger(parentCount, is(equalToInteger(25)));
    assertThatInteger(childrenCount, is(equalToInteger(51)));
}

- (void)testMappingAPayloadContainingRepeatedObjectsPerformsAcceptablyWithInMemoryMappingCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKInMemoryManagedObjectCache *managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    managedObjectStore.managedObjectCache = managedObjectCache;

    RKEntityMapping *childMapping = [RKEntityMapping mappingForEntityForName:@"Child" inManagedObjectStore:managedObjectStore];
    childMapping.identificationAttributes = @[ @"childID" ];
    [childMapping addAttributeMappingsFromArray:@[@"name", @"childID"]];

    RKEntityMapping *parentMapping = [RKEntityMapping mappingForEntityForName:@"Parent" inManagedObjectStore:managedObjectStore];
    [parentMapping addAttributeMappingsFromArray:@[@"parentID", @"name"]];
    parentMapping.identificationAttributes = @[ @"parentID" ];
    [parentMapping addRelationshipMappingWithSourceKeyPath:@"children" mapping:childMapping];

    NSDictionary *mappingsDictionary = @{ @"parents": parentMapping };
    NSDictionary *JSON = [RKTestFixture parsedObjectWithContentsOfFixture:@"benchmark_parents_and_children.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:JSON mappingsDictionary:mappingsDictionary];
    mapper.mappingOperationDataSource = mappingOperationDataSource;

    [RKBenchmark report:@"Mapping with In Memory Cache" executionBlock:^{
        for (NSUInteger i = 0; i < 50; i++) {
            [mapper start];
        }
    }];
    NSUInteger parentCount = [managedObjectStore.persistentStoreManagedObjectContext countForEntityForName:@"Parent" predicate:nil error:nil];
    NSUInteger childrenCount = [managedObjectStore.persistentStoreManagedObjectContext countForEntityForName:@"Child" predicate:nil error:nil];
    assertThatInteger(parentCount, is(equalToInteger(25)));
    assertThatInteger(childrenCount, is(equalToInteger(51)));
}

- (void)testMappingIdentificationAttributesFromElementsOnAnArray
{
    NSDictionary *representation = @{
        @"userSessions": @{
            @"name": @"Mr. User",
            @"identification": @54321,
            @"catIDs": @[ @"418", @"419", @"431",@"441", @"457", @"486", @"504" ]
        }
    };
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"Cat" inManagedObjectStore:managedObjectStore];
    catMapping.identificationAttributes = @[ @"railsID" ];
    [catMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:nil toKeyPath:@"railsID"]];
     
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [humanMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"identification" toKeyPath:@"railsID"]];
    [humanMapping setIdentificationAttributes:@[ @"railsID" ]];
    [humanMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"catIDs" toKeyPath:@"cats" withMapping:catMapping]];
    
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:representation mappingsDictionary:@{ @"userSessions": humanMapping }];
    mapper.mappingOperationDataSource = mappingOperationDataSource;
    [mapper start];
    
    RKHuman *human = [mapper.mappingResult firstObject];
    expect(human).notTo.beNil();
    expect(human.railsID).to.equal(@54321);
    expect(human.cats).to.haveCountOf(7);
    NSSet *expectedIDs = [NSSet setWithArray:@[ @418, @419, @431, @441, @457, @486, @504 ]];
    expect([human.cats valueForKey:@"railsID"]).to.equal(expectedIDs);
}

- (void)testMappingIdentificationAttributesFromElementsOnAnArrayDoesNotDuplicateManagedObjects
{
    NSDictionary *representation = @{ @"userSessions": @{ @"name": @"Mr. User",
                                                          @"identification": @54321,
                                                          @"catIDs": @[ @"418", @"419", @"431",@"441", @"457", @"486", @"504" ] } };
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];

    NSManagedObject *cat1 = [NSEntityDescription insertNewObjectForEntityForName:@"Cat" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    [cat1 setValue:@(418) forKey:@"railsID"];
    NSManagedObject *cat2 = [NSEntityDescription insertNewObjectForEntityForName:@"Cat" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    [cat2 setValue:@(419) forKey:@"railsID"];

    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"Cat" inManagedObjectStore:managedObjectStore];
    catMapping.identificationAttributes = @[ @"railsID" ];
    [catMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:nil toKeyPath:@"railsID"]];

    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [humanMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"identification" toKeyPath:@"railsID"]];
    [humanMapping setIdentificationAttributes:@[ @"railsID" ]];
    [humanMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"catIDs" toKeyPath:@"cats" withMapping:catMapping]];

    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:representation mappingsDictionary:@{ @"userSessions": humanMapping }];
    mapper.mappingOperationDataSource = mappingOperationDataSource;
    [mapper start];

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Cat"];
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"railsID" ascending:YES]]];

    NSPredicate *catOnePredicate  = [NSPredicate predicateWithFormat:@"railsID == 418"];
    [fetchRequest setPredicate:catOnePredicate];
    NSArray *catsWithID418 = [managedObjectStore.persistentStoreManagedObjectContext executeFetchRequest:fetchRequest error:NULL];

    NSPredicate *catTwoPredicate = [NSPredicate predicateWithFormat:@"railsID == 419"];
    [fetchRequest setPredicate:catTwoPredicate];
    NSArray *catsWithID419 = [managedObjectStore.persistentStoreManagedObjectContext executeFetchRequest:fetchRequest error:NULL];

    expect(catsWithID418).to.haveCountOf(1);
    expect(catsWithID419).to.haveCountOf(1);
}

- (void)testMappingStringIdentificationAttributesFromElementsOnAnArrayDoesNotDuplicateManagedObjects
{
    NSDictionary *representation = @{ @"userSessions": @[@{ @"name": @"Mr. User",
                                                            @"identification": @54321,
                                                            @"catIDs": @[ @"418", @"419", @"431",@"441", @"457", @"486", @"504" ] },
                                                         @{ @"name": @"Miss User",
                                                            @"identification": @54322,
                                                            @"catIDs": @[ @"418", @"419", @"431",@"441", @"457", @"486", @"504" ] }] };
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    
    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"Cat" inManagedObjectStore:managedObjectStore];
    catMapping.identificationAttributes = @[ @"name" ];
    [catMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:nil toKeyPath:@"name"]];
    
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [humanMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"identification" toKeyPath:@"railsID"]];
    [humanMapping setIdentificationAttributes:@[ @"railsID" ]];
    [humanMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"catIDs" toKeyPath:@"cats" withMapping:catMapping]];
    
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:representation mappingsDictionary:@{ @"userSessions": humanMapping }];
    mapper.mappingOperationDataSource = mappingOperationDataSource;
    [mapper start];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Cat"];
    
    NSArray *allCats = [managedObjectStore.persistentStoreManagedObjectContext executeFetchRequest:fetchRequest error:NULL];
    
    NSPredicate *catOnePredicate  = [NSPredicate predicateWithFormat:@"name == %@", @"418"];
    [fetchRequest setPredicate:catOnePredicate];
    NSArray *catsWithID418 = [managedObjectStore.persistentStoreManagedObjectContext executeFetchRequest:fetchRequest error:NULL];
    
    NSPredicate *catTwoPredicate = [NSPredicate predicateWithFormat:@"name == %@", @"419"];
    [fetchRequest setPredicate:catTwoPredicate];
    NSArray *catsWithID419 = [managedObjectStore.persistentStoreManagedObjectContext executeFetchRequest:fetchRequest error:NULL];
    
    expect(catsWithID418).to.haveCountOf(1);
    expect(catsWithID419).to.haveCountOf(1);

    expect(allCats).to.haveCountOf(7);
}

- (void)testManagedObjectsMappedWithRequiredRelationshipsThatAreSetByConnectionsAreNotPrematurelyDeleted
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    mappingOperationDataSource.operationQueue = [NSOperationQueue new];
    
    NSManagedObject *cat = [NSEntityDescription insertNewObjectForEntityForName:@"Cat" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    [cat setValue:@(12345) forKey:@"railsID"];
    
    NSDictionary *representation = @{ @"name": @"Blake Watters", @"requiredCatID": @(12345) };
    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"Cat" inManagedObjectStore:managedObjectStore];
    catMapping.identificationAttributes = @[ @"railsID" ];
    
    RKEntityMapping *strictHumanMapping = [RKEntityMapping mappingForEntityForName:@"StrictHuman" inManagedObjectStore:managedObjectStore];
    [strictHumanMapping addAttributeMappingsFromDictionary:@{ @"name": @"name" }];
    [strictHumanMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"requiredCatID" toKeyPath:@"favoriteCatID"]];
    [strictHumanMapping addConnectionForRelationship:@"requiredCat" connectedBy:@{ @"favoriteCatID": @"railsID" }];
    
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:representation mappingsDictionary:@{ [NSNull null]: strictHumanMapping }];
    mapper.mappingOperationDataSource = mappingOperationDataSource;
    [mapper start];
    [mappingOperationDataSource.operationQueue waitUntilAllOperationsAreFinished];
    
    RKHuman *blake = [mapper.mappingResult firstObject];
    expect(blake.name).to.equal(@"Blake Watters");
    expect(blake.managedObjectContext).notTo.beNil();
    expect([blake isDeleted]).to.beFalsy();
    expect([blake valueForKey:@"requiredCat"]).to.equal(cat);
}

- (void)testManagedObjectsMappedWithRequiredRelationshipsThatAreSetByConnectionsAreNotPrematurelyDeletedByPredicateDeletion
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    mappingOperationDataSource.operationQueue = [NSOperationQueue new];
    mappingOperationDataSource.operationQueue.maxConcurrentOperationCount = 1;

    NSManagedObject *cat = [NSEntityDescription insertNewObjectForEntityForName:@"Cat" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    [cat setValue:@(12345) forKey:@"railsID"];

    NSDictionary *representation = @{ @"name": @"Blake Watters", @"favoriteCatID": @(12345) };
    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"Cat" inManagedObjectStore:managedObjectStore];
    catMapping.identificationAttributes = @[ @"railsID" ];

    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    humanMapping.deletionPredicate = [NSPredicate predicateWithFormat:@"favoriteCat == nil"];
    [humanMapping addAttributeMappingsFromDictionary:@{ @"name": @"name" }];
    [humanMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"favoriteCatID" toKeyPath:@"favoriteCatID"]];
    [humanMapping addConnectionForRelationship:@"favoriteCat" connectedBy:@{ @"favoriteCatID": @"railsID" }];

    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:representation mappingsDictionary:@{ [NSNull null]: humanMapping }];
    mapper.mappingOperationDataSource = mappingOperationDataSource;
    [mapper start];
    [mappingOperationDataSource.operationQueue waitUntilAllOperationsAreFinished];

    RKHuman *blake = [mapper.mappingResult firstObject];
    expect(blake.name).to.equal(@"Blake Watters");
    expect(blake.managedObjectContext).notTo.beNil();
    expect([blake isDeleted]).to.beFalsy();
    expect([blake valueForKey:@"favoriteCat"]).to.equal(cat);
}

- (void)testManagedObjectsMappedWithRelationshipsThatAreSetByConnectionsWithInMemoryCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKInMemoryManagedObjectCache *managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    mappingOperationDataSource.operationQueue = [NSOperationQueue new];

    NSDictionary *representation = @{ @"human": @{ @"name": @"Blake Watters", @"favoriteCatID": @(12345) }, @"cat": @{ @"railsID": @(12345) } };
    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"Cat"
                                                      inManagedObjectStore:managedObjectStore];
    catMapping.identificationAttributes = @[ @"railsID" ];
    [catMapping addAttributeMappingsFromDictionary:@{ @"railsID": @"railsID" }];

    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human"
                                                        inManagedObjectStore:managedObjectStore];
    [humanMapping addAttributeMappingsFromDictionary:@{ @"name": @"name" }];
    [humanMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"favoriteCatID" toKeyPath:@"favoriteCatID"]];
    [humanMapping addConnectionForRelationship:@"favoriteCat" connectedBy:@{ @"favoriteCatID": @"railsID" }];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:representation
                                                               mappingsDictionary:@{ @"human": humanMapping , @"cat": catMapping }];
    mapper.mappingOperationDataSource = mappingOperationDataSource;
    mappingOperationDataSource.parentOperation = mapper;
    [mapper start];

    [mappingOperationDataSource.operationQueue waitUntilAllOperationsAreFinished];

    RKCat *cat = (mapper.mappingResult.dictionary)[@"cat"];
    expect(cat.railsID).to.equal(12345);
    expect(cat.managedObjectContext).notTo.beNil();

    RKHuman *blake = (mapper.mappingResult.dictionary)[@"human"];
    expect(blake.name).to.equal(@"Blake Watters");
    expect(blake.managedObjectContext).notTo.beNil();
    expect([blake isDeleted]).to.beFalsy();
    expect([blake valueForKey:@"favoriteCat"]).notTo.beNil();
    expect([blake valueForKey:@"favoriteCat"]).to.equal((mapper.mappingResult.dictionary)[@"cat"]);
}

- (void)testDeletionOperationAfterManagedObjectContextIsDeallocated
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSManagedObjectContext *managedObjectContext = [managedObjectStore newChildManagedObjectContextWithConcurrencyType:NSPrivateQueueConcurrencyType tracksChanges:NO];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectContext cache:nil];
    
    
    NSDictionary *representation = @{ @"human": @{ @"name": @"Blake Watters", @"favoriteCatID": @(12345) }, @"cat": @{ @"railsID": @(12345) } };
    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"Cat"
                                                      inManagedObjectStore:managedObjectStore];
    catMapping.discardsInvalidObjectsOnInsert = YES;
    RKCat *cat = [NSEntityDescription insertNewObjectForEntityForName:@"Cat" inManagedObjectContext:managedObjectContext];
    RKMappingOperation *mappingOperation = [[RKMappingOperation alloc] initWithSourceObject:representation destinationObject:cat mapping:catMapping];
    NSOperationQueue *operationQueue = [NSOperationQueue new];
    [operationQueue setSuspended:YES];
    dataSource.operationQueue = operationQueue;
    
    id mockOperation = [OCMockObject partialMockForObject:mappingOperation];
    [[[mockOperation stub] andReturn:catMapping] objectMapping];
    [dataSource commitChangesForMappingOperation:mockOperation error:nil];
    
    expect([operationQueue operationCount]).to.equal(1);
    dataSource = nil;
    managedObjectContext = nil;
    [operationQueue setSuspended:NO];
    
    [operationQueue waitUntilAllOperationsAreFinished];
    // Create a operation queue
    // Create data source
    
}

- (void)testThatMappingRequiredHasManyRelationshipDoesNotCrash
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    mappingOperationDataSource.operationQueue = [NSOperationQueue new];

    NSDictionary *representation = @{ @"name": @"Blake Watters", @"railsID": @123, @"hoardedCats": @[ @{ @"name": @"Asia", @"railsID": @12345 }] };
    RKEntityMapping *catHoarderMapping = [RKEntityMapping mappingForEntityForName:@"CatHoarder" inManagedObjectStore:managedObjectStore];
    [catHoarderMapping addAttributeMappingsFromArray:@[ @"name", @"railsID" ]];
    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"HoardedCat" inManagedObjectStore:managedObjectStore];
    [catMapping addAttributeMappingsFromArray:@[ @"name", @"railsID" ]];
    catMapping.identificationAttributes = @[ @"railsID" ];
    [catHoarderMapping addRelationshipMappingWithSourceKeyPath:@"hoardedCats" mapping:catMapping];

    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:representation mappingsDictionary:@{ [NSNull null]: catHoarderMapping }];
    mapper.mappingOperationDataSource = mappingOperationDataSource;
    mappingOperationDataSource.parentOperation = mapper;
    [mapper start];
    [mappingOperationDataSource.operationQueue waitUntilAllOperationsAreFinished];

    NSManagedObject *catHoarder = [mapper.mappingResult firstObject];
    expect(catHoarder).notTo.beNil();
    expect([catHoarder valueForKeyPath:@"hoardedCats"]).to.haveCountOf(1);
}

- (void)testThatShouldMapRelationshipsIfObjectIsUnmodifiedFlagWorks {
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    mappingOperationDataSource.operationQueue = [NSOperationQueue new];
    
    NSDate *updatedAt = [NSDate date];
    NSDictionary *representation = @{ @"name": @"Blake Watters", @"railsID": @123, @"updatedAt": updatedAt };
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [humanMapping addAttributeMappingsFromArray:@[ @"name", @"railsID", @"updatedAt" ]];
    [humanMapping setModificationAttributeForName:@"updatedAt"];
    humanMapping.shouldMapRelationshipsIfObjectIsUnmodified = YES;
    
    NSManagedObject *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    [human setValue:updatedAt forKey:@"updatedAt"];
    RKMappingOperation *mappingOperation = [[RKMappingOperation alloc] initWithSourceObject:representation destinationObject:human mapping:humanMapping];
    mappingOperation.dataSource = mappingOperationDataSource;
    
    BOOL canSkipAttrs = [mappingOperationDataSource mappingOperationShouldSkipAttributeMapping:mappingOperation];
    BOOL canSkipRelationships = [mappingOperationDataSource mappingOperationShouldSkipRelationshipMapping:mappingOperation];
    expect(canSkipAttrs).to.equal(YES);
    expect(canSkipRelationships).to.equal(NO);
}

- (void)testThatStringEqualityCausesSkipPropertyMappingToReturnYES
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    mappingOperationDataSource.operationQueue = [NSOperationQueue new];
    
    NSDictionary *representation = @{ @"name": @"Blake Watters", @"railsID": @123 };
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [humanMapping addAttributeMappingsFromArray:@[ @"name", @"railsID" ]];
    [humanMapping setModificationAttributeForName:@"name"];
    
    NSManagedObject *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    [human setValue:@"Blake Watters" forKey:@"name"];
    RKMappingOperation *mappingOperation = [[RKMappingOperation alloc] initWithSourceObject:representation destinationObject:human mapping:humanMapping];
    mappingOperation.dataSource = mappingOperationDataSource;
    
    BOOL canSkipAttributes = [mappingOperationDataSource mappingOperationShouldSkipAttributeMapping:mappingOperation];
    BOOL canSkipRelationships = [mappingOperationDataSource mappingOperationShouldSkipRelationshipMapping:mappingOperation];
    expect(canSkipAttributes).to.equal(YES);
    expect(canSkipRelationships).to.equal(YES);
}

- (void)testThatStringInequalityCausesSkipPropertyMappingToReturnNO
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    mappingOperationDataSource.operationQueue = [NSOperationQueue new];
    
    NSDictionary *representation = @{ @"name": @"Blake Watters", @"railsID": @123 };
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [humanMapping addAttributeMappingsFromArray:@[ @"name", @"railsID" ]];
    [humanMapping setModificationAttributeForName:@"name"];
    
    NSManagedObject *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    [human setValue:@"MISMATCH" forKey:@"name"];
    RKMappingOperation *mappingOperation = [[RKMappingOperation alloc] initWithSourceObject:representation destinationObject:human mapping:humanMapping];
    mappingOperation.dataSource = mappingOperationDataSource;
    
    BOOL canSkipAttributes = [mappingOperationDataSource mappingOperationShouldSkipAttributeMapping:mappingOperation];
    BOOL canSkipRelationships = [mappingOperationDataSource mappingOperationShouldSkipRelationshipMapping:mappingOperation];
    expect(canSkipAttributes).to.equal(NO);
    expect(canSkipRelationships).to.equal(NO);
}

- (void)testThatDateEqualityCausesSkipPropertyMappingToReturnYES
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    mappingOperationDataSource.operationQueue = [NSOperationQueue new];
    
    NSDate *updatedAt = [NSDate date];
    NSDictionary *representation = @{ @"name": @"Blake Watters", @"railsID": @123, @"updatedAt": updatedAt };
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [humanMapping addAttributeMappingsFromArray:@[ @"name", @"railsID", @"updatedAt" ]];
    [humanMapping setModificationAttributeForName:@"updatedAt"];
    
    NSManagedObject *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    [human setValue:updatedAt forKey:@"updatedAt"];
    RKMappingOperation *mappingOperation = [[RKMappingOperation alloc] initWithSourceObject:representation destinationObject:human mapping:humanMapping];
    mappingOperation.dataSource = mappingOperationDataSource;
    
    BOOL canSkipAttributes = [mappingOperationDataSource mappingOperationShouldSkipAttributeMapping:mappingOperation];
    BOOL canSkipRelationships = [mappingOperationDataSource mappingOperationShouldSkipRelationshipMapping:mappingOperation];
    expect(canSkipAttributes).to.equal(YES);
    expect(canSkipRelationships).to.equal(YES);
}

- (void)testThatDateDecensionCausesSkipPropertyMappingToReturnYES
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    mappingOperationDataSource.operationQueue = [NSOperationQueue new];
    
    NSDate *updatedAt = [NSDate date];
    NSDate *futureDate = [updatedAt dateByAddingTimeInterval:60 * 60 * 24];
    NSDictionary *representation = @{ @"name": @"Blake Watters", @"railsID": @123, @"updatedAt": updatedAt };
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [humanMapping addAttributeMappingsFromArray:@[ @"name", @"railsID", @"updatedAt" ]];
    [humanMapping setModificationAttributeForName:@"updatedAt"];
    
    NSManagedObject *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    [human setValue:futureDate forKey:@"updatedAt"];
    RKMappingOperation *mappingOperation = [[RKMappingOperation alloc] initWithSourceObject:representation destinationObject:human mapping:humanMapping];
    mappingOperation.dataSource = mappingOperationDataSource;
    
    BOOL canSkipAttributes = [mappingOperationDataSource mappingOperationShouldSkipAttributeMapping:mappingOperation];
    BOOL canSkipRelationships = [mappingOperationDataSource mappingOperationShouldSkipRelationshipMapping:mappingOperation];
    expect(canSkipAttributes).to.equal(YES);
    expect(canSkipRelationships).to.equal(YES);
}

- (void)testThatDateAscensionCausesSkipPropertyMappingToReturnNO
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    mappingOperationDataSource.operationQueue = [NSOperationQueue new];
    
    NSDate *updatedAt = [NSDate date];
    NSDate *futureDate = [updatedAt dateByAddingTimeInterval:60 * 60 * 24];
    NSDictionary *representation = @{ @"name": @"Blake Watters", @"railsID": @123, @"updatedAt": futureDate };
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [humanMapping addAttributeMappingsFromArray:@[ @"name", @"railsID", @"updatedAt" ]];
    [humanMapping setModificationAttributeForName:@"updatedAt"];
    
    NSManagedObject *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    [human setValue:updatedAt forKey:@"updatedAt"];
    RKMappingOperation *mappingOperation = [[RKMappingOperation alloc] initWithSourceObject:representation destinationObject:human mapping:humanMapping];
    mappingOperation.dataSource = mappingOperationDataSource;
    
    BOOL canSkipAttributes = [mappingOperationDataSource mappingOperationShouldSkipAttributeMapping:mappingOperation];
    BOOL canSkipRelationships = [mappingOperationDataSource mappingOperationShouldSkipRelationshipMapping:mappingOperation];
    expect(canSkipAttributes).to.equal(NO);
    expect(canSkipRelationships).to.equal(NO);
}

- (void)testThatNumericEqualityCausesSkipPropertyMappingToReturnYES
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    mappingOperationDataSource.operationQueue = [NSOperationQueue new];
    
    NSDictionary *representation = @{ @"name": @"Blake Watters", @"railsID": @123 };
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [humanMapping addAttributeMappingsFromArray:@[ @"name", @"railsID", @"updatedAt" ]];
    [humanMapping setModificationAttributeForName:@"railsID"];
    
    NSManagedObject *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    [human setValue:@123 forKey:@"railsID"];
    RKMappingOperation *mappingOperation = [[RKMappingOperation alloc] initWithSourceObject:representation destinationObject:human mapping:humanMapping];
    mappingOperation.dataSource = mappingOperationDataSource;
    
    BOOL canSkipAttributes = [mappingOperationDataSource mappingOperationShouldSkipAttributeMapping:mappingOperation];
    BOOL canSkipRelationships = [mappingOperationDataSource mappingOperationShouldSkipRelationshipMapping:mappingOperation];
    expect(canSkipAttributes).to.equal(YES);
    expect(canSkipRelationships).to.equal(YES);
}

- (void)testThatNumericDecensionCausesSkipPropertyMappingToReturnYES
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    mappingOperationDataSource.operationQueue = [NSOperationQueue new];
    
    NSDictionary *representation = @{ @"name": @"Blake Watters", @"railsID": @100 };
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [humanMapping addAttributeMappingsFromArray:@[ @"name", @"railsID", @"updatedAt" ]];
    [humanMapping setModificationAttributeForName:@"railsID"];
    
    NSManagedObject *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    [human setValue:@999 forKey:@"railsID"];
    RKMappingOperation *mappingOperation = [[RKMappingOperation alloc] initWithSourceObject:representation destinationObject:human mapping:humanMapping];
    mappingOperation.dataSource = mappingOperationDataSource;
    
    BOOL canSkipAttributes = [mappingOperationDataSource mappingOperationShouldSkipAttributeMapping:mappingOperation];
    BOOL canSkipRelationships = [mappingOperationDataSource mappingOperationShouldSkipRelationshipMapping:mappingOperation];
    expect(canSkipAttributes).to.equal(YES);
    expect(canSkipRelationships).to.equal(YES);
}

- (void)testThatNumericAscensionCausesSkipPropertyMappingToReturnNO
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    mappingOperationDataSource.operationQueue = [NSOperationQueue new];
    
    NSDictionary *representation = @{ @"name": @"Blake Watters", @"railsID": @999 };
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [humanMapping addAttributeMappingsFromArray:@[ @"name", @"railsID", @"updatedAt" ]];
    [humanMapping setModificationAttributeForName:@"railsID"];
    
    NSManagedObject *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    [human setValue:@100 forKey:@"railsID"];
    RKMappingOperation *mappingOperation = [[RKMappingOperation alloc] initWithSourceObject:representation destinationObject:human mapping:humanMapping];
    mappingOperation.dataSource = mappingOperationDataSource;
    
    BOOL canSkipAttributes = [mappingOperationDataSource mappingOperationShouldSkipAttributeMapping:mappingOperation];
    BOOL canSkipRelationships = [mappingOperationDataSource mappingOperationShouldSkipRelationshipMapping:mappingOperation];
    expect(canSkipAttributes).to.equal(NO);
    expect(canSkipRelationships).to.equal(NO);
}

- (void)testThatDynamicMappingCanSkipPropertyMapping
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    mappingOperationDataSource.operationQueue = [NSOperationQueue new];
    
    NSDictionary *representation = @{ @"name": @"Blake Watters", @"railsID": @123 };
    RKDynamicMapping *dynamicMapping = [[RKDynamicMapping alloc] init];
    [dynamicMapping setObjectMappingForRepresentationBlock:^RKObjectMapping *(id representation) {
        RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
        [humanMapping addAttributeMappingsFromArray:@[ @"name", @"railsID" ]];
        [humanMapping setModificationAttributeForName:@"name"];
        
        return humanMapping;
    }];
    
    NSManagedObject *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    [human setValue:@"Blake Watters" forKey:@"name"];
    RKMappingOperation *mappingOperation = [[RKMappingOperation alloc] initWithSourceObject:representation destinationObject:human mapping:dynamicMapping];
    mappingOperation.dataSource = mappingOperationDataSource;
    
    NSError *error = nil;
    // Concrete mapping is determined during mapping process
    [mappingOperation performMapping:&error];
    [mappingOperationDataSource.operationQueue waitUntilAllOperationsAreFinished];
    assertThat(error, is(nilValue()));
    
    BOOL canSkipAttributes = [mappingOperationDataSource mappingOperationShouldSkipAttributeMapping:mappingOperation];
    BOOL canSkipRelationships = [mappingOperationDataSource mappingOperationShouldSkipRelationshipMapping:mappingOperation];
    expect(canSkipAttributes).to.equal(YES);
    expect(canSkipRelationships).to.equal(YES);
}

@end
