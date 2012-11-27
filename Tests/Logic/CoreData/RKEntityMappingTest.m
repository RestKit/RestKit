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
    
    [RKEntityMapping setEntityIdentifierInferenceEnabled:YES];
}

- (void)testShouldReturnTheDefaultValueForACoreDataAttribute
{
    // Load Core Data
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];

    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Cat" inManagedObjectStore:managedObjectStore];
    id value = [mapping defaultValueForAttribute:@"name"];
    assertThat(value, is(equalTo(@"Kitty Cat!")));
}

- (void)testShouldMapACollectionOfObjectsWithDynamicKeys
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    managedObjectStore.managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    mapping.forceCollectionMapping = YES;
    mapping.entityIdentifier = [RKEntityIdentifier identifierWithEntityName:@"Human" attributes:@[ @"name" ] inManagedObjectStore:managedObjectStore];
    [mapping addAttributeMappingFromKeyOfRepresentationToAttribute:@"name"];
    RKAttributeMapping *idMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"(name).id" toKeyPath:@"railsID"];
    [mapping addPropertyMapping:idMapping];
    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    [mappingsDictionary setObject:mapping forKey:@"users"];

    id mockCacheStrategy = [OCMockObject partialMockForObject:managedObjectStore.managedObjectCache];
    [[[mockCacheStrategy expect] andForwardToRealObject] managedObjectsWithEntity:OCMOCK_ANY
                                                                  attributeValues:@{ @"name": @"blake" }
                                                           inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    [[[mockCacheStrategy expect] andForwardToRealObject] managedObjectsWithEntity:OCMOCK_ANY
                                                                  attributeValues:@{ @"name": @"rachit" }
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
    RKEntityMapping *childMapping = [RKEntityMapping mappingForEntityForName:@"Child" inManagedObjectStore:managedObjectStore];
    childMapping.entityIdentifier = [RKEntityIdentifier identifierWithEntityName:@"Child" attributes:@[ @"railsID" ] inManagedObjectStore:managedObjectStore];
    [childMapping addAttributeMappingsFromArray:@[@"name"]];

    RKEntityMapping *parentMapping = [RKEntityMapping mappingForEntityForName:@"Parent" inManagedObjectStore:managedObjectStore];
    parentMapping.entityIdentifier = [RKEntityIdentifier identifierWithEntityName:@"Parent" attributes:@[ @"railsID" ] inManagedObjectStore:managedObjectStore];
    [parentMapping addAttributeMappingsFromArray:@[@"name", @"age"]];

    [dynamicMapping setObjectMapping:parentMapping whenValueOfKeyPath:@"type" isEqualTo:@"Parent"];
    [dynamicMapping setObjectMapping:childMapping whenValueOfKeyPath:@"type" isEqualTo:@"Child"];

    RKObjectMapping *mapping = [dynamicMapping objectMappingForRepresentation:[RKTestFixture parsedObjectWithContentsOfFixture:@"parent.json"]];
    expect(mapping).notTo.beNil();
    expect([mapping isKindOfClass:[RKEntityMapping class]]).to.equal(YES);
    expect(NSStringFromClass(mapping.objectClass)).to.equal(@"RKParent");
    mapping = [dynamicMapping objectMappingForRepresentation:[RKTestFixture parsedObjectWithContentsOfFixture:@"child.json"]];
    expect(mapping).notTo.beNil();
    expect([mapping isKindOfClass:[RKEntityMapping class]]).to.equal(YES);
    expect(NSStringFromClass(mapping.objectClass)).to.equal(@"RKChild");
}

- (void)testShouldIncludeTransformableAttributesInPropertyNamesAndTypes
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    NSDictionary *attributesByName = [entity attributesByName];
    NSDictionary *propertiesByName = [entity propertiesByName];
    NSDictionary *relationshipsByName = [entity relationshipsByName];
    assertThat([attributesByName objectForKey:@"favoriteColors"], is(notNilValue()));
    assertThat([propertiesByName objectForKey:@"favoriteColors"], is(notNilValue()));
    assertThat([relationshipsByName objectForKey:@"favoriteColors"], is(nilValue()));

    NSDictionary *propertyNamesAndTypes = [[RKPropertyInspector sharedInspector] propertyNamesAndClassesForEntity:entity];
    assertThat([propertyNamesAndTypes objectForKey:@"favoriteColors"], is(notNilValue()));
}

- (void)testThatMappingAnEmptyArrayOnToAnExistingRelationshipDisassociatesTheRelatedObjects
{
    RKHuman *blake = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:nil withProperties:@{ @"name": @"Blake" }];
    RKCat *asia = [RKTestFactory insertManagedObjectForEntityForName:@"Cat" inManagedObjectContext:nil withProperties:@{ @"name": @"Asia" }];
    RKCat *roy = [RKTestFactory insertManagedObjectForEntityForName:@"Cat" inManagedObjectContext:nil withProperties:@{ @"name": @"Roy" }];
    blake.cats = [NSSet setWithObjects:asia, roy, nil];
    
    NSDictionary *JSON = @{ @"name" : @"Blake Watters", @"cats" : @[] };
    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"Cat" inManagedObjectStore:[RKTestFactory managedObjectStore]];
    [catMapping addAttributeMappingsFromArray:@[@"name"]];
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:[RKTestFactory managedObjectStore]];
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
    RKHuman *blake = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:nil withProperties:@{ @"name": @"Blake" }];
    RKCat *asia = [RKTestFactory insertManagedObjectForEntityForName:@"Cat" inManagedObjectContext:nil withProperties:@{ @"name": @"Asia" }];
    blake.favoriteCat = asia;
    
    NSDictionary *JSON = @{ @"name" : @"Blake Watters", @"favoriteCat" : [NSNull null] };
    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"Cat" inManagedObjectStore:[RKTestFactory managedObjectStore]];
    [catMapping addAttributeMappingsFromArray:@[@"name"]];
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:[RKTestFactory managedObjectStore]];
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
    RKHuman *blake = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:nil withProperties:@{ @"name": @"Blake" }];
    RKCat *asia = [RKTestFactory insertManagedObjectForEntityForName:@"Cat" inManagedObjectContext:nil withProperties:@{ @"name": @"Asia" }];
    RKCat *roy = [RKTestFactory insertManagedObjectForEntityForName:@"Cat" inManagedObjectContext:nil withProperties:@{ @"name": @"Roy" }];
    blake.cats = [NSSet setWithObjects:asia, roy, nil];
    
    NSDictionary *JSON = @{ @"name" : @"Blake Watters", @"cats" : [NSNull null] };
    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"Cat" inManagedObjectStore:[RKTestFactory managedObjectStore]];
    [catMapping addAttributeMappingsFromArray:@[@"name"]];
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:[RKTestFactory managedObjectStore]];
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

- (void)testAssignmentOfEntityIdentifierForIncorrectEntityRaisesException
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *humanEntityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    RKEntityIdentifier *catIdentifier = [RKEntityIdentifier identifierWithEntityName:@"Cat" attributes:@[ @"railsID" ] inManagedObjectStore:managedObjectStore];
    NSException *expectedException = nil;
    @try {
        humanEntityMapping.entityIdentifier = catIdentifier;
    }
    @catch (NSException *exception) {
        expectedException = exception;
    }
    @finally {
        expect(expectedException).notTo.beNil();
        expect([expectedException reason]).to.equal(@"Invalid entity identifier value: The identifier given is for the 'Cat' entity.");
    }
}

- (void)testAddingConnectionByAttributeName
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *humanEntityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [humanEntityMapping addConnectionForRelationship:@"favoriteCat" connectedBy:@"favoriteCatID"];
    RKConnectionDescription *connection = [humanEntityMapping connectionForRelationship:@"favoriteCat"];
    NSDictionary *expectedAttributes = @{ @"favoriteCatID": @"favoriteCatID" };
    expect(connection.attributes).to.equal(expectedAttributes);
}

- (void)testThatAddingConnectionByAttributeNameRespectsTransformationBlock
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *humanEntityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [humanEntityMapping setSourceToDestinationKeyTransformationBlock:^NSString *(RKObjectMapping *mapping, NSString *sourceKey) {
        return @"age";
    }];
    [humanEntityMapping addConnectionForRelationship:@"favoriteCat" connectedBy:@"favoriteCatID"];
    RKConnectionDescription *connection = [humanEntityMapping connectionForRelationship:@"favoriteCat"];
    NSDictionary *expectedAttributes = @{ @"favoriteCatID": @"age" };
    expect(connection.attributes).to.equal(expectedAttributes);
}

- (void)testAddingConnectionByArrayOfAttributeNames
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *humanEntityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [humanEntityMapping addConnectionForRelationship:@"cats" connectedBy:@[ @"railsID", @"name" ]];
    RKConnectionDescription *connection = [humanEntityMapping connectionForRelationship:@"cats"];
    NSDictionary *expectedAttributes = @{ @"railsID": @"railsID", @"name": @"name" };
    expect(connection.attributes).to.equal(expectedAttributes);
}

- (void)testAddingConnectionByArrayOfAttributeNamesRespectsTransformationBlock
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *humanEntityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [humanEntityMapping setSourceToDestinationKeyTransformationBlock:^NSString *(RKObjectMapping *mapping, NSString *sourceKey) {
        if ([sourceKey isEqualToString:@"railsID"]) return @"age";
        else if ([sourceKey isEqualToString:@"name"]) return @"color";
        else return sourceKey;
    }];
    [humanEntityMapping addConnectionForRelationship:@"cats" connectedBy:@[ @"railsID", @"name" ]];
    RKConnectionDescription *connection = [humanEntityMapping connectionForRelationship:@"cats"];
    NSDictionary *expectedAttributes = @{ @"railsID": @"age", @"name": @"color" };
    expect(connection.attributes).to.equal(expectedAttributes);
}

- (void)testAddingConnectionByDictionaryOfAttributes
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *humanEntityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [humanEntityMapping addConnectionForRelationship:@"cats" connectedBy:@{ @"railsID": @"railsID", @"name": @"name" }];
    RKConnectionDescription *connection = [humanEntityMapping connectionForRelationship:@"cats"];
    NSDictionary *expectedAttributes = @{ @"railsID": @"railsID", @"name": @"name" };
    expect(connection.attributes).to.equal(expectedAttributes);
}

- (void)testSettingEntityIdentifierForRelationship
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *humanEntityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [humanEntityMapping setEntityIdentifier:[RKEntityIdentifier identifierWithEntityName:@"Cat" attributes:@[ @"name" ] inManagedObjectStore:managedObjectStore] forRelationship:@"cats"];
    RKEntityIdentifier *entityIdentifier = [humanEntityMapping entityIdentifierForRelationship:@"cats"];
    expect(entityIdentifier).notTo.beNil();
    expect([entityIdentifier.attributes valueForKey:@"name"]).to.equal(@[ @"name" ]);
}

- (void)testSettingEntityIdentifierForInvalidRelationshipRaisesError
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *humanEntityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    NSException *caughtException = nil;
    @try {
        [humanEntityMapping setEntityIdentifier:[RKEntityIdentifier identifierWithEntityName:@"Cat" attributes:@[ @"name" ] inManagedObjectStore:managedObjectStore] forRelationship:@"invalid"];
    }
    @catch (NSException *exception) {
        caughtException = exception;
    }
    @finally {
        expect(caughtException).notTo.beNil();
        expect([caughtException reason]).to.equal(@"Cannot set entity identififer for relationship 'invalid': no relationship found for that name.");
    }
}

- (void)testSettingEntityIdentifierWithEntityMismatchRaisesError
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *humanEntityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    NSException *caughtException = nil;
    @try {
        [humanEntityMapping setEntityIdentifier:[RKEntityIdentifier identifierWithEntityName:@"Human" attributes:@[ @"name" ] inManagedObjectStore:managedObjectStore] forRelationship:@"cats"];
    }
    @catch (NSException *exception) {
        caughtException = exception;
    }
    @finally {
        NSLog(@"In finally the exception is: %@", caughtException);
        expect(caughtException).notTo.beNil();
        expect([caughtException reason]).to.equal(@"Cannot set entity identifier for relationship 'cats': the given relationship identifier is for the 'Human' entity, but the 'Cat' entity was expected.");
    }
}

- (void)testEntityIdentifierInferenceOnInit
{
    [RKEntityMapping setEntityIdentifierInferenceEnabled:YES];
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Parent" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKEntityMapping *entityMapping = [[RKEntityMapping alloc] initWithEntity:entity];
    expect(entityMapping.entityIdentifier).notTo.beNil();
    assertThat([entityMapping.entityIdentifier.attributes valueForKey:@"name"], equalTo(@[ @"parentID" ]));
}

- (void)testInitWithIdentifierInferenceEnabledInfersIdentifiersForRelationships
{
    [RKEntityMapping setEntityIdentifierInferenceEnabled:YES];
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Parent" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKEntityMapping *entityMapping = [[RKEntityMapping alloc] initWithEntity:entity];
    
    RKEntityIdentifier *childrenIdentifier = [entityMapping entityIdentifierForRelationship:@"children"];
    expect(childrenIdentifier).notTo.beNil();
    assertThat([childrenIdentifier.attributes valueForKey:@"name"], equalTo(@[ @"childID" ]));
}

- (void)testInitWithIdentifierInferenceDisabled
{
    [RKEntityMapping setEntityIdentifierInferenceEnabled:NO];
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Parent" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKEntityMapping *entityMapping = [[RKEntityMapping alloc] initWithEntity:entity];
    expect(entityMapping.entityIdentifier).to.beNil();
}

@end
