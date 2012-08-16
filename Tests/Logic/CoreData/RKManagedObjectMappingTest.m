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

@interface RKManagedObjectMappingTest : RKTestCase

@end

@implementation RKManagedObjectMappingTest

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
    managedObjectStore.managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:managedObjectStore];
    mapping.forceCollectionMapping = YES;
    mapping.primaryKeyAttribute = @"name";
    [mapping mapKeyOfNestedDictionaryToAttribute:@"name"];
    RKAttributeMapping *idMapping = [RKAttributeMapping mappingFromKeyPath:@"(name).id" toKeyPath:@"railsID"];
    [mapping addAttributeMapping:idMapping];
    RKObjectMappingProvider *provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@"users"];

    id mockCacheStrategy = [OCMockObject partialMockForObject:managedObjectStore.managedObjectCache];
    [[[mockCacheStrategy expect] andForwardToRealObject] findInstanceOfEntity:OCMOCK_ANY
                                                      withPrimaryKeyAttribute:mapping.primaryKeyAttribute
                                                                        value:@"blake"
                                                       inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    [[[mockCacheStrategy expect] andForwardToRealObject] findInstanceOfEntity:mapping.entity
                                                      withPrimaryKeyAttribute:mapping.primaryKeyAttribute
                                                                        value:@"rachit"
                                                       inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"DynamicKeys.json"];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                      cache:managedObjectStore.managedObjectCache];
    mapper.mappingOperationDataSource = dataSource;
    [mapper performMapping];
    [mockCacheStrategy verify];
}

- (void)testShouldPickTheAppropriateMappingBasedOnAnAttributeValue
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKDynamicMapping *dynamicMapping = [RKDynamicMapping dynamicMapping];
    RKEntityMapping *childMapping = [RKEntityMapping mappingForEntityForName:@"RKChild" inManagedObjectStore:managedObjectStore];
    childMapping.primaryKeyAttribute = @"railsID";
    [childMapping mapAttributes:@"name", nil];

    RKEntityMapping *parentMapping = [RKEntityMapping mappingForEntityForName:@"RKParent" inManagedObjectStore:managedObjectStore];
    parentMapping.primaryKeyAttribute = @"railsID";
    [parentMapping mapAttributes:@"name", @"age", nil];

    [dynamicMapping setObjectMapping:parentMapping whenValueOfKeyPath:@"type" isEqualTo:@"Parent"];
    [dynamicMapping setObjectMapping:childMapping whenValueOfKeyPath:@"type" isEqualTo:@"Child"];

    RKObjectMapping *mapping = [dynamicMapping objectMappingForDictionary:[RKTestFixture parsedObjectWithContentsOfFixture:@"parent.json"]];
    assertThat(mapping, is(notNilValue()));
    assertThatBool([mapping isKindOfClass:[RKEntityMapping class]], is(equalToBool(YES)));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"RKParent")));
    mapping = [dynamicMapping objectMappingForDictionary:[RKTestFixture parsedObjectWithContentsOfFixture:@"child.json"]];
    assertThat(mapping, is(notNilValue()));
    assertThatBool([mapping isKindOfClass:[RKEntityMapping class]], is(equalToBool(YES)));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"RKChild")));
}

- (void)testShouldIncludeTransformableAttributesInPropertyNamesAndTypes
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
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
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RKCat" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntity:entity];
    assertThat(mapping.primaryKeyAttribute, is(equalTo(@"railsID")));
}

- (void)testThatAssigningAPrimaryKeyAttributeToAMappingWhoseEntityHasANilPrimaryKeyAttributeAssignsItToTheEntity
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RKCloud" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntity:entity];
    assertThat(mapping.primaryKeyAttribute, is(nilValue()));
    mapping.primaryKeyAttribute = @"name";
    assertThat(entity.primaryKeyAttributeName, is(equalTo(@"name")));
    assertThat(entity.primaryKeyAttribute, is(notNilValue()));
}

@end
