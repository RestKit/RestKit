//
//  RKManagedObjectMappingTest.m
//  RestKit
//
//  Created by Blake Watters on 5/31/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "RKTestEnvironment.h"
#import "RKEntityMapping.h"
#import "RKHuman.h"
#import "RKMappableObject.h"
#import "RKChild.h"
#import "RKParent.h"
#import "NSEntityDescription+RKAdditions.h"
#import "RKManagedObjectMappingOperationDataSource.h"
#import "RKDynamicMapping.h"

@interface RKEntityMappingTest : RKTestCase

@end

@implementation RKEntityMappingTest

- (void)setUp
{
    [RKTestFactory setUp];
}

- (void)tearDown
{
    [RKTestFactory tearDown];
}

- (void)testShouldReturnTheDefaultValueForACoreDataAttribute
{
    // Load Core Data
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];

    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"RKCat" inManagedObjectStore:managedObjectStore];
    id value = [mapping defaultValueForMissingAttribute:@"name"];
    assertThat(value, is(equalTo(@"Kitty Cat!")));
}

- (void)testShouldMapACollectionOfObjectsWithDynamicKeys
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:managedObjectStore];
    mapping.forceCollectionMapping = YES;
    mapping.primaryKeyAttribute = @"name";
    [mapping mapKeyOfNestedDictionaryToAttribute:@"name"];
    RKAttributeMapping *idMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"(name).id" toKeyPath:@"railsID"];
    [mapping addPropertyMapping:idMapping];
    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    [mappingsDictionary setObject:mapping forKey:@"users"];

    id mockCacheStrategy = [OCMockObject partialMockForObject:managedObjectStore.managedObjectCache];
    [[[mockCacheStrategy expect] andForwardToRealObject] findInstanceOfEntity:OCMOCK_ANY
                                                      withPrimaryKeyAttribute:mapping.primaryKeyAttribute
                                                                        value:@"blake"
                                                       inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    [[[mockCacheStrategy expect] andForwardToRealObject] findInstanceOfEntity:mapping.entity
                                                      withPrimaryKeyAttribute:mapping.primaryKeyAttribute
                                                                        value:@"rachit"
                                                       inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"DynamicKeys.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithObject:userInfo mappingsDictionary:mappingsDictionary];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    mapper.mappingOperationDataSource = dataSource;
    [mapper start];
    [mockCacheStrategy verify];
}

- (void)testShouldPickTheAppropriateMappingBasedOnAnAttributeValue
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKDynamicMapping *dynamicMapping = [RKDynamicMapping new];
    RKEntityMapping *childMapping = [RKEntityMapping mappingForEntityForName:@"RKChild" inManagedObjectStore:managedObjectStore];
    childMapping.primaryKeyAttribute = @"railsID";
    [childMapping addAttributeMappingsFromArray:@[@"name"]];

    RKEntityMapping *parentMapping = [RKEntityMapping mappingForEntityForName:@"RKParent" inManagedObjectStore:managedObjectStore];
    parentMapping.primaryKeyAttribute = @"railsID";
    [parentMapping addAttributeMappingsFromArray:@[@"name", @"age"]];

    [dynamicMapping setObjectMapping:parentMapping whenValueOfKeyPath:@"type" isEqualTo:@"Parent"];
    [dynamicMapping setObjectMapping:childMapping whenValueOfKeyPath:@"type" isEqualTo:@"Child"];

    RKObjectMapping *mapping = [dynamicMapping objectMappingForRepresentation:[RKTestFixture parsedObjectWithContentsOfFixture:@"parent.json"]];
    assertThat(mapping, is(notNilValue()));
    assertThatBool([mapping isKindOfClass:[RKEntityMapping class]], is(equalToBool(YES)));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"RKParent")));
    mapping = [dynamicMapping objectMappingForRepresentation:[RKTestFixture parsedObjectWithContentsOfFixture:@"child.json"]];
    assertThat(mapping, is(notNilValue()));
    assertThatBool([mapping isKindOfClass:[RKEntityMapping class]], is(equalToBool(YES)));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"RKChild")));
}

- (void)testShouldIncludeTransformableAttributesInPropertyNamesAndTypes
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    NSDictionary *attributesByName = [entity attributesByName];
    NSDictionary *propertiesByName = [entity propertiesByName];
    NSDictionary *relationshipsByName = [entity relationshipsByName];
    assertThat([attributesByName objectForKey:@"favoriteColors"], is(notNilValue()));
    assertThat([propertiesByName objectForKey:@"favoriteColors"], is(notNilValue()));
    assertThat([relationshipsByName objectForKey:@"favoriteColors"], is(nilValue()));

    NSDictionary *propertyNamesAndTypes = [[RKPropertyInspector sharedInspector] propertyNamesAndTypesForEntity:entity];
    assertThat([propertyNamesAndTypes objectForKey:@"favoriteColors"], is(notNilValue()));
}

- (void)testThatAssigningAnEntityWithANonNilPrimaryKeyAttributeSetsTheDefaultValueForTheMapping
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RKCat" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:entity];
    assertThat(mapping.primaryKeyAttribute, is(equalTo(@"railsID")));
}

- (void)testThatAssigningAPrimaryKeyAttributeToAMappingWhoseEntityHasANilPrimaryKeyAttributeAssignsItToTheEntity
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RKCloud" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKEntityMapping *mapping = [[RKEntityMapping alloc] initWithEntity:entity];
    assertThat(mapping.primaryKeyAttribute, is(nilValue()));
    mapping.primaryKeyAttribute = @"name";
    assertThat(entity.primaryKeyAttributeName, is(equalTo(@"name")));
    assertThat(entity.primaryKeyAttribute, is(notNilValue()));
}

- (void)testThatMappingAnEmptyArrayOnToAnExistingRelationshipDisassociatesTheRelatedObjects
{
    RKHuman *blake = [RKTestFactory insertManagedObjectForEntityForName:@"RKHuman" inManagedObjectContext:nil withProperties:@{ @"name": @"Blake" }];
    RKCat *asia = [RKTestFactory insertManagedObjectForEntityForName:@"RKCat" inManagedObjectContext:nil withProperties:@{ @"name": @"Asia" }];
    RKCat *roy = [RKTestFactory insertManagedObjectForEntityForName:@"RKCat" inManagedObjectContext:nil withProperties:@{ @"name": @"Roy" }];
    blake.cats = [NSSet setWithObjects:asia, roy, nil];
    
    NSDictionary *JSON = @{ @"name" : @"Blake Watters", @"cats" : @[] };
    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"RKCat" inManagedObjectStore:[RKTestFactory managedObjectStore]];
    [catMapping addAttributeMappingsFromArray:@[@"name"]];
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:[RKTestFactory managedObjectStore]];
    [humanMapping addAttributeMappingsFromArray:@[@"name"]];
    [humanMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"cats" toKeyPath:@"cats" withMapping:catMapping]];
    
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:[[RKTestFactory managedObjectStore] mainQueueManagedObjectContext] cache:nil];
    RKMappingOperation *mappingOperation = [[RKMappingOperation alloc] initWithSourceObject:JSON destinationObject:blake mapping:humanMapping];
    mappingOperation.dataSource = dataSource;
    expect(blake.cats).notTo.beEmpty();
    [mappingOperation start];
    expect(mappingOperation.error).to.beNil();
    expect(blake.cats).to.beEmpty();
}

- (void)testThatMappingAnNullArrayOnToAnExistingToOneRelationshipDisassociatesTheRelatedObjects
{
    RKHuman *blake = [RKTestFactory insertManagedObjectForEntityForName:@"RKHuman" inManagedObjectContext:nil withProperties:@{ @"name": @"Blake" }];
    RKCat *asia = [RKTestFactory insertManagedObjectForEntityForName:@"RKCat" inManagedObjectContext:nil withProperties:@{ @"name": @"Asia" }];
    blake.favoriteCat = asia;
    
    NSDictionary *JSON = @{ @"name" : @"Blake Watters", @"favoriteCat" : [NSNull null] };
    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"RKCat" inManagedObjectStore:[RKTestFactory managedObjectStore]];
    [catMapping addAttributeMappingsFromArray:@[@"name"]];
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:[RKTestFactory managedObjectStore]];
    [humanMapping addAttributeMappingsFromArray:@[@"name"]];
    [humanMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"favoriteCat" toKeyPath:@"favoriteCat" withMapping:catMapping]];
    
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:[[RKTestFactory managedObjectStore] mainQueueManagedObjectContext] cache:nil];
    RKMappingOperation *mappingOperation = [[RKMappingOperation alloc] initWithSourceObject:JSON destinationObject:blake mapping:humanMapping];
    mappingOperation.dataSource = dataSource;
    expect(blake.favoriteCat).to.equal(asia);
    [mappingOperation start];
    expect(mappingOperation.error).to.beNil();
    expect(blake.favoriteCat).to.beNil();
}


- (void)testThatMappingAnNullArrayOnToAnExistingToManyRelationshipDisassociatesTheRelatedObjects
{
    RKHuman *blake = [RKTestFactory insertManagedObjectForEntityForName:@"RKHuman" inManagedObjectContext:nil withProperties:@{ @"name": @"Blake" }];
    RKCat *asia = [RKTestFactory insertManagedObjectForEntityForName:@"RKCat" inManagedObjectContext:nil withProperties:@{ @"name": @"Asia" }];
    RKCat *roy = [RKTestFactory insertManagedObjectForEntityForName:@"RKCat" inManagedObjectContext:nil withProperties:@{ @"name": @"Roy" }];
    blake.cats = [NSSet setWithObjects:asia, roy, nil];
    
    NSDictionary *JSON = @{ @"name" : @"Blake Watters", @"cats" : [NSNull null] };
    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"RKCat" inManagedObjectStore:[RKTestFactory managedObjectStore]];
    [catMapping addAttributeMappingsFromArray:@[@"name"]];
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:[RKTestFactory managedObjectStore]];
    [humanMapping addAttributeMappingsFromArray:@[@"name"]];
    [humanMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"cats" toKeyPath:@"cats" withMapping:catMapping]];
    
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:[[RKTestFactory managedObjectStore] mainQueueManagedObjectContext] cache:nil];
    RKMappingOperation *mappingOperation = [[RKMappingOperation alloc] initWithSourceObject:JSON destinationObject:blake mapping:humanMapping];
    mappingOperation.dataSource = dataSource;
    expect(blake.cats).notTo.beEmpty();
    [mappingOperation start];
    expect(mappingOperation.error).to.beNil();
    expect(blake.cats).to.beEmpty();
}

@end
