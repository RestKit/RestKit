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
#import "RKCat.h"
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
    
    [RKEntityMapping setEntityIdentificationInferenceEnabled:YES];
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
    mapping.identificationAttributes = @[ @"name" ];
    [mapping addAttributeMappingFromKeyOfRepresentationToAttribute:@"name"];
    RKAttributeMapping *idMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"(name).id" toKeyPath:@"railsID"];
    [mapping addPropertyMapping:idMapping];
    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    mappingsDictionary[@"users"] = mapping;

    id mockCacheStrategy = [OCMockObject partialMockForObject:managedObjectStore.managedObjectCache];
    [[[mockCacheStrategy expect] andForwardToRealObject] managedObjectsWithEntity:OCMOCK_ANY
                                                                  attributeValues:@{ @"name": @"blake" }
                                                           inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    [[[mockCacheStrategy expect] andForwardToRealObject] managedObjectsWithEntity:OCMOCK_ANY
                                                                  attributeValues:@{ @"name": @"rachit" }
                                                           inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"DynamicKeys.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:userInfo mappingsDictionary:mappingsDictionary];
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
    childMapping.identificationAttributes = @[ @"railsID" ];
    [childMapping addAttributeMappingsFromArray:@[@"name"]];

    RKEntityMapping *parentMapping = [RKEntityMapping mappingForEntityForName:@"Parent" inManagedObjectStore:managedObjectStore];
    parentMapping.identificationAttributes = @[ @"railsID" ];
    [parentMapping addAttributeMappingsFromArray:@[@"name", @"age"]];

    [dynamicMapping addMatcher:[RKObjectMappingMatcher matcherWithKeyPath:@"type" expectedValue:@"Parent" objectMapping:parentMapping]];
    [dynamicMapping addMatcher:[RKObjectMappingMatcher matcherWithKeyPath:@"type" expectedValue:@"Child" objectMapping:childMapping]];

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
    assertThat(attributesByName[@"favoriteColors"], is(notNilValue()));
    assertThat(propertiesByName[@"favoriteColors"], is(notNilValue()));
    assertThat(relationshipsByName[@"favoriteColors"], is(nilValue()));

    NSDictionary *propertyNamesAndTypes = [[RKPropertyInspector sharedInspector] propertyInspectionForEntity:entity];
    assertThat([(RKPropertyInspectorPropertyInfo *)propertyNamesAndTypes[@"favoriteColors"] keyValueCodingClass], is(notNilValue()));
}

- (void)testMappingAnArrayToATransformableWithoutABackingManagedObjectSubclass
{
    NSManagedObjectModel *model = [NSManagedObjectModel new];
    NSEntityDescription *entity = [NSEntityDescription new];
    [entity setName:@"TransformableEntity"];
    NSAttributeDescription *transformableAttribute = [NSAttributeDescription new];
    [transformableAttribute setName:@"transformableURLs"];
    [transformableAttribute setAttributeType:NSTransformableAttributeType];
    [entity setProperties:@[ transformableAttribute ]];
    [model setEntities:@[ entity ]];
    
    RKEntityMapping *entityMapping = [[RKEntityMapping alloc] initWithEntity:entity];
    [entityMapping addAttributeMappingsFromDictionary:@{ @"URLs": @"transformableURLs" }];
    
    NSArray *URLs = @[ @"http://restkit.org", @"http://gateguruapp.com" ];
    NSDictionary *representation = @{ @"URLs": URLs };
    
    NSError *error = nil;
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:model];
    [managedObjectStore createPersistentStoreCoordinator];
    [managedObjectStore addInMemoryPersistentStore:&error];
    [managedObjectStore createManagedObjectContexts];
    
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:representation destinationObject:nil mapping:entityMapping];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext cache:nil];
    operation.dataSource = dataSource;
    BOOL success = [operation performMapping:&error];
    expect(success).to.equal(YES);
    expect(operation.destinationObject).notTo.beNil();
    
    NSArray *mappedURLs = [operation.destinationObject valueForKey:@"transformableURLs"];
    expect(mappedURLs).to.equal(URLs);
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

- (void)testSettingEntityIdentificationAttributesWithInvalidAttributeNameRaisesException
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *humanEntityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    NSException *caughtException = nil;
    @try {
        humanEntityMapping.identificationAttributes = @[ @"invalid" ];
    }
    @catch (NSException *exception) {
        caughtException = exception;
    }
    @finally {
        expect(caughtException).notTo.beNil();
        expect([caughtException reason]).to.equal(@"Invalid attribute 'invalid': no attribute was found for the given name in the 'Human' entity.");
    }
}

- (void)testEntityIdentifierInferenceOnInit
{
    [RKEntityMapping setEntityIdentificationInferenceEnabled:YES];
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Parent" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKEntityMapping *entityMapping = [[RKEntityMapping alloc] initWithEntity:entity];
    expect(entityMapping.identificationAttributes).notTo.beNil();
    assertThat([entityMapping.identificationAttributes valueForKey:@"name"], equalTo(@[ @"parentID" ]));
}

- (void)testInitWithIdentifierInferenceDisabled
{
    [RKEntityMapping setEntityIdentificationInferenceEnabled:NO];
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Parent" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKEntityMapping *entityMapping = [[RKEntityMapping alloc] initWithEntity:entity];
    expect(entityMapping.identificationAttributes).to.beNil();
}

- (void)testEntityMappingCopy
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    entityMapping.identificationAttributes = RKIdentificationAttributesInferredFromEntity(entityMapping.entity);
    entityMapping.identificationPredicate = [NSPredicate predicateWithValue:YES];
    entityMapping.identificationPredicateBlock = ^(NSDictionary *representation, NSManagedObjectContext *context) { return [NSPredicate predicateWithValue:YES]; };
    entityMapping.deletionPredicate = [NSPredicate predicateWithValue:NO];
    [entityMapping setModificationAttributeForName:@"railsID"];
    [entityMapping addConnectionForRelationship:@"cats" connectedBy:@{ @"railsID": @"railsID", @"name": @"name" }];
    
    RKEntityMapping *entityMappingCopy = [entityMapping copy];
    
    expect(entityMappingCopy.entity).to.equal(entityMapping.entity);
    expect(entityMappingCopy.identificationAttributes).to.equal(entityMapping.identificationAttributes);
    expect(entityMappingCopy.identificationPredicate).to.equal(entityMapping.identificationPredicate);
    expect(entityMappingCopy.identificationPredicateBlock).to.equal(entityMapping.identificationPredicateBlock);
    expect(entityMappingCopy.deletionPredicate).to.equal(entityMapping.deletionPredicate);
    expect(entityMappingCopy.modificationAttribute).to.equal(entityMapping.modificationAttribute);
    expect(entityMappingCopy.connections.count == entityMapping.connections.count);
}

- (void)testEntityDynamicPropertyMappingWithFetchRequestBlockNotCrashing {
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    
    RKEntityMapping *childMapping = [RKEntityMapping mappingForEntityForName:@"Child" inManagedObjectStore:managedObjectStore];
    childMapping.identificationAttributes = @[ @"railsID" ];
    [childMapping addAttributeMappingsFromArray:@[@"name", @"railsID"]];
    
    RKEntityMapping *parentMapping = [RKEntityMapping mappingForEntityForName:@"Parent" inManagedObjectStore:managedObjectStore];
    parentMapping.identificationAttributes = @[ @"railsID" ];
    [parentMapping addAttributeMappingsFromArray:@[@"name", @"railsID"]];
    [parentMapping addRelationshipMappingWithSourceKeyPath:@"children" mapping:childMapping];
    
    RKDynamicMapping *humanMapping = [[RKDynamicMapping alloc] init];
    [humanMapping addMatcher:[RKObjectMappingMatcher matcherWithKeyPath:@"type" expectedValue:@"Parent" objectMapping:parentMapping]];
    [humanMapping addMatcher:[RKObjectMappingMatcher matcherWithKeyPath:@"type" expectedValue:@"Child" objectMapping:childMapping]];
    
    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"HoardedCat" inManagedObjectStore:managedObjectStore];
    catMapping.identificationAttributes = @[ @"railsID" ];
    [catMapping addAttributeMappingsFromArray:@[@"name", @"railsID"]];
    [catMapping addRelationshipMappingWithSourceKeyPath:@"human" mapping:humanMapping];
    
    RKEntityMapping *catHoarderMapping = [RKEntityMapping mappingForEntityForName:@"CatHoarder" inManagedObjectStore:managedObjectStore];
    [catHoarderMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"cats" toKeyPath:@"hoardedCats" withMapping:catMapping]];
    catHoarderMapping.identificationAttributes = @[ @"railsID" ];
    [catHoarderMapping addAttributeMappingsFromArray:@[@"name", @"railsID"]];
    
    NSURL *baseURL = [NSURL URLWithString:@"http://example.org"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"path" relativeToURL:baseURL]];
    request.HTTPMethod = @"GET";
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:request.URL
                                                              statusCode:200
                                                             HTTPVersion:@"1.1"
                                                            headerFields:@{@"Content-Type" : @"application/json"}];
    NSData *responseData = [RKTestFixture dataWithContentsOfFixture:@"hoarderWithCats_issue_2192.json"];
    
    id mockRequestOperation = [OCMockObject niceMockForClass:[RKHTTPRequestOperation class]];
    [[[mockRequestOperation stub] andReturn:request] request];
    [[[mockRequestOperation stub] andReturn:response] response];
    [[[mockRequestOperation stub] andReturn:responseData] responseData];
    [[[mockRequestOperation stub] andDo:^(NSInvocation *invocation) {
        void(^successHandler)(AFHTTPRequestOperation *operation, id responseObject) = nil;
        [invocation getArgument:&successHandler atIndex:2];
        successHandler(mockRequestOperation, [RKTestFixture parsedObjectWithContentsOfFixture:@"hoarderWithCats_issue_2192.json"]);
        
    }] setCompletionBlockWithSuccess:[OCMArg any] failure:[OCMArg any]];
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:catHoarderMapping
                                                                                            method:RKRequestMethodAny
                                                                                       pathPattern:nil
                                                                                           keyPath:nil
                                                                                       statusCodes:[NSIndexSet indexSetWithIndex:200]];
    responseDescriptor.baseURL = baseURL;
    
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithHTTPRequestOperation:mockRequestOperation
                                                                                                                       responseDescriptors:@[responseDescriptor]];
    managedObjectRequestOperation.managedObjectContext = [managedObjectStore newChildManagedObjectContextWithConcurrencyType:NSPrivateQueueConcurrencyType
                                                                                                               tracksChanges:NO];
    
    NSFetchRequest*(^requestBlock)(NSURL *url) = ^(NSURL *url) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"CatHoarder"];
        return request;
    };
    
    managedObjectRequestOperation.fetchRequestBlocks = @[[requestBlock copy]];
    managedObjectRequestOperation.savesToPersistentStore = NO;
    
    NSException *exception = nil;
    @try {
        [managedObjectRequestOperation start];
        [managedObjectRequestOperation waitUntilFinished];
    }
    @catch (NSException *e) {
        exception = e;
    }
    @finally {
        assertThat(exception, is(nilValue()));
    }
}

- (void)testOneToOneRelationshipMappingWithReplacementPolicyWillNotCrash {
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    
    RKEntityMapping *childMapping = [RKEntityMapping mappingForEntityForName:@"Child" inManagedObjectStore:managedObjectStore];
    childMapping.identificationAttributes = @[ @"railsID" ];
    [childMapping addAttributeMappingsFromArray:@[@"name", @"railsID"]];
    
    RKEntityMapping *parentMapping = [RKEntityMapping mappingForEntityForName:@"Parent" inManagedObjectStore:managedObjectStore];
    parentMapping.identificationAttributes = @[ @"railsID" ];
    [parentMapping addAttributeMappingsFromArray:@[@"name", @"railsID"]];
    [parentMapping addRelationshipMappingWithSourceKeyPath:@"children" mapping:childMapping];
    
    RKDynamicMapping *humanMapping = [[RKDynamicMapping alloc] init];
    [humanMapping addMatcher:[RKObjectMappingMatcher matcherWithKeyPath:@"type" expectedValue:@"Parent" objectMapping:parentMapping]];
    [humanMapping addMatcher:[RKObjectMappingMatcher matcherWithKeyPath:@"type" expectedValue:@"Child" objectMapping:childMapping]];
    
    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"Cat" inManagedObjectStore:managedObjectStore];
    catMapping.identificationAttributes = @[ @"railsID" ];
    [catMapping addAttributeMappingsFromArray:@[@"name", @"railsID"]];
    
    RKRelationshipMapping *relationMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"human" toKeyPath:@"human" withMapping:humanMapping];
    relationMapping.assignmentPolicy = RKAssignmentPolicyReplace;
    [catMapping addPropertyMapping:relationMapping];
    
    NSURL *baseURL = [NSURL URLWithString:@"http://example.org"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"path" relativeToURL:baseURL]];
    request.HTTPMethod = @"POST";
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:request.URL
                                                              statusCode:200
                                                             HTTPVersion:@"1.1"
                                                            headerFields:@{@"Content-Type" : @"application/json"}];
    NSData *responseData = [RKTestFixture dataWithContentsOfFixture:@"catsWithParent_issue_2194.json"];
    
    id mockRequestOperation = [OCMockObject niceMockForClass:[RKHTTPRequestOperation class]];
    [[[mockRequestOperation stub] andReturn:request] request];
    [[[mockRequestOperation stub] andReturn:response] response];
    [[[mockRequestOperation stub] andReturn:responseData] responseData];
    [[[mockRequestOperation stub] andDo:^(NSInvocation *invocation) {
        void(^successHandler)(AFHTTPRequestOperation *operation, id responseObject) = nil;
        [invocation getArgument:&successHandler atIndex:2];
        successHandler(mockRequestOperation, [RKTestFixture parsedObjectWithContentsOfFixture:@"catsWithParent_issue_2194.json"]);
        
    }] setCompletionBlockWithSuccess:[OCMArg any] failure:[OCMArg any]];
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:catMapping
                                                                                            method:RKRequestMethodAny
                                                                                       pathPattern:nil
                                                                                           keyPath:nil
                                                                                       statusCodes:[NSIndexSet indexSetWithIndex:200]];
    responseDescriptor.baseURL = baseURL;
    
    RKManagedObjectRequestOperation *requestOperation = [[RKManagedObjectRequestOperation alloc] initWithHTTPRequestOperation:mockRequestOperation
                                                                                                          responseDescriptors:@[responseDescriptor]];
    
    NSManagedObjectContext *context = [managedObjectStore newChildManagedObjectContextWithConcurrencyType:NSPrivateQueueConcurrencyType
                                                                                            tracksChanges:NO];
    requestOperation.managedObjectContext = context;
    requestOperation.savesToPersistentStore = NO;
    
    RKCat *targetCat = [NSEntityDescription insertNewObjectForEntityForName:@"Cat" inManagedObjectContext:context];
    targetCat.railsID = @(5555);
    
    RKChild *child = [NSEntityDescription insertNewObjectForEntityForName:@"Child" inManagedObjectContext:context];
    targetCat.human = child;
    
    requestOperation.targetObject = targetCat;
    
    NSException *exception = nil;
    @try {
        [requestOperation start];
        [requestOperation waitUntilFinished];
    }
    @catch (NSException *e) {
        exception = e;
    }
    @finally {
        assertThat(exception, is(nilValue()));
    }
}

#pragma mark - Entity Identification

- (void)testThatInitEntityIdentificationAttributesToNil
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    RKEntityMapping *entityMapping = [[RKEntityMapping alloc] initWithEntity:entity];
    NSException *expectedExcepetion = nil;
    @try {
        entityMapping.identificationAttributes = nil;
    }
    @catch (NSException *exception) {
        expectedExcepetion = exception;
    }
    expect(expectedExcepetion).to.beNil();
}

- (void)testThatInitEntityIdentifierWithEmptyAttributesRaisesException
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    NSException *expectedExcepetion = nil;
    RKEntityMapping *entityMapping = [[RKEntityMapping alloc] initWithEntity:entity];
    @try {
        entityMapping.identificationAttributes = @[];
    }
    @catch (NSException *exception) {
        expectedExcepetion = exception;
    }
    expect(expectedExcepetion).notTo.beNil();
    expect([expectedExcepetion description]).to.equal(@"At least one attribute must be provided to identify managed objects");
}

#pragma mark - Entity Identifier Inference

- (void)testEntityIdentifierInferenceForEntityWithLlamaCasedIDAttribute
{
    NSEntityDescription *entity = [[NSEntityDescription alloc] init];
    [entity setName:@"Monkey"];
    NSAttributeDescription *identifierAttribute = [NSAttributeDescription new];
    [identifierAttribute setName:@"monkeyID"];
    [entity setProperties:@[ identifierAttribute ]];
    NSArray *identificationAttributes = RKIdentificationAttributesInferredFromEntity(entity);
    expect(identificationAttributes).notTo.beNil();
    NSArray *attributeNames = @[ @"monkeyID" ];
    expect([identificationAttributes valueForKey:@"name"]).to.equal(attributeNames);
}

- (void)testEntityIdentifierInferenceForEntityWithIDAttribute
{
    NSEntityDescription *entity = [[NSEntityDescription alloc] init];
    [entity setName:@"Monkey"];
    NSAttributeDescription *identifierAttribute = [NSAttributeDescription new];
    [identifierAttribute setName:@"ID"];
    [entity setProperties:@[ identifierAttribute ]];
    NSArray *identificationAttributes = RKIdentificationAttributesInferredFromEntity(entity);
    expect(identificationAttributes).notTo.beNil();
    NSArray *attributeNames = @[ @"ID" ];
    expect([identificationAttributes valueForKey:@"name"]).to.equal(attributeNames);
}

- (void)testEntityIdentifierInferenceForEntityWithIdentifierAttribute
{
    NSEntityDescription *entity = [[NSEntityDescription alloc] init];
    [entity setName:@"Monkey"];
    NSAttributeDescription *identifierAttribute = [NSAttributeDescription new];
    [identifierAttribute setName:@"identifier"];
    [entity setProperties:@[ identifierAttribute ]];
    NSArray *identificationAttributes = RKIdentificationAttributesInferredFromEntity(entity);
    expect(identificationAttributes).notTo.beNil();
    NSArray *attributeNames = @[ @"identifier" ];
    expect([identificationAttributes valueForKey:@"name"]).to.equal(attributeNames);
}

- (void)testEntityIdentifierInferenceForEntityWithURLAttribute
{
    NSEntityDescription *entity = [[NSEntityDescription alloc] init];
    [entity setName:@"Monkey"];
    NSAttributeDescription *identifierAttribute = [NSAttributeDescription new];
    [identifierAttribute setName:@"URL"];
    [entity setProperties:@[ identifierAttribute ]];
    NSArray *identificationAttributes = RKIdentificationAttributesInferredFromEntity(entity);
    expect(identificationAttributes).notTo.beNil();
    NSArray *attributeNames = @[ @"URL" ];
    expect([identificationAttributes valueForKey:@"name"]).to.equal(attributeNames);
}

- (void)testEntityIdentifierInferenceForEntityWithUrlAttribute
{
    NSEntityDescription *entity = [[NSEntityDescription alloc] init];
    [entity setName:@"Monkey"];
    NSAttributeDescription *identifierAttribute = [NSAttributeDescription new];
    [identifierAttribute setName:@"url"];
    [entity setProperties:@[ identifierAttribute ]];
    NSArray *identificationAttributes = RKIdentificationAttributesInferredFromEntity(entity);
    expect(identificationAttributes).notTo.beNil();
    NSArray *attributeNames = @[ @"url" ];
    expect([identificationAttributes valueForKey:@"name"]).to.equal(attributeNames);
}

- (void)testEntityIdentifierInferenceFromUserInfoKeyForSingleValue
{
    NSEntityDescription *entity = [[NSEntityDescription alloc] init];
    [entity setName:@"Monkey"];
    NSAttributeDescription *identifierAttribute = [NSAttributeDescription new];
    [identifierAttribute setName:@"monkeyID"]; // We ignore this by specifying the userInfo key
    NSAttributeDescription *nameAttribute = [NSAttributeDescription new];
    [nameAttribute setName:@"name"];
    [entity setProperties:@[ identifierAttribute, nameAttribute ]];
    [entity setUserInfo:@{ RKEntityIdentificationAttributesUserInfoKey: @"name" }];
    NSArray *identificationAttributes = RKIdentificationAttributesInferredFromEntity(entity);
    expect(identificationAttributes).notTo.beNil();
    NSArray *attributeNames = @[ @"name" ];
    expect([identificationAttributes valueForKey:@"name"]).to.equal(attributeNames);
}

- (void)testEntityIdentifierInferenceFromUserInfoKeyForCommaSeparatedString
{
    NSEntityDescription *entity = [[NSEntityDescription alloc] init];
    [entity setName:@"Monkey"];
    NSAttributeDescription *identifierAttribute = [NSAttributeDescription new];
    [identifierAttribute setName:@"monkeyID"];
    NSAttributeDescription *nameAttribute = [NSAttributeDescription new];
    [nameAttribute setName:@"name"];
    [entity setProperties:@[ identifierAttribute, nameAttribute ]];
    [entity setUserInfo:@{ RKEntityIdentificationAttributesUserInfoKey: @"name,monkeyID" }];
    NSArray *identificationAttributes = RKIdentificationAttributesInferredFromEntity(entity);
    expect(identificationAttributes).notTo.beNil();
    NSArray *attributeNames = @[ @"name", @"monkeyID" ];
    expect([identificationAttributes valueForKey:@"name"]).to.equal(attributeNames);
}

- (void)testEntityIdentifierInferenceFromUserInfoKeyForArrayOfValues
{
    NSEntityDescription *entity = [[NSEntityDescription alloc] init];
    [entity setName:@"Monkey"];
    NSAttributeDescription *identifierAttribute = [NSAttributeDescription new];
    [identifierAttribute setName:@"monkeyID"];
    NSAttributeDescription *nameAttribute = [NSAttributeDescription new];
    [nameAttribute setName:@"name"];
    [entity setProperties:@[ identifierAttribute, nameAttribute ]];
    [entity setUserInfo:@{ RKEntityIdentificationAttributesUserInfoKey: @[ @"name", @"monkeyID" ] }];
    NSArray *identificationAttributes = RKIdentificationAttributesInferredFromEntity(entity);
    expect(identificationAttributes).notTo.beNil();
    NSArray *attributeNames = @[ @"name", @"monkeyID" ];
    expect([identificationAttributes valueForKey:@"name"]).to.equal(attributeNames);
}

- (void)testEntityIdentifierInferenceFromUserInfoKeyRaisesErrorForInvalidValue
{
    NSEntityDescription *entity = [[NSEntityDescription alloc] init];
    [entity setName:@"Monkey"];
    NSAttributeDescription *identifierAttribute = [NSAttributeDescription new];
    [identifierAttribute setName:@"monkeyID"];
    NSAttributeDescription *nameAttribute = [NSAttributeDescription new];
    [nameAttribute setName:@"name"];
    [entity setProperties:@[ identifierAttribute, nameAttribute ]];
    [entity setUserInfo:@{ RKEntityIdentificationAttributesUserInfoKey: @(12345) }];
    
    NSException *caughtException = nil;
    @try {
        NSArray __unused *identificationAttributes = RKIdentificationAttributesInferredFromEntity(entity);
    }
    @catch (NSException *exception) {
        caughtException = exception;
    }
    @finally {
        expect([caughtException name]).to.equal(NSInvalidArgumentException);
        expect([caughtException reason]).to.equal(@"Invalid value given in user info key 'RKEntityIdentificationAttributes' of entity 'Monkey': expected an `NSString` or `NSArray` of strings, instead got '12345' (__NSCFNumber)");
    }
}

- (void)testEntityIdentifierInferenceFromUserInfoKeyRaisesErrorForNonexistantAttributeName
{
    NSEntityDescription *entity = [[NSEntityDescription alloc] init];
    [entity setName:@"Monkey"];
    NSAttributeDescription *identifierAttribute = [NSAttributeDescription new];
    [identifierAttribute setName:@"monkeyID"];
    [entity setProperties:@[ identifierAttribute ]];
    [entity setUserInfo:@{ RKEntityIdentificationAttributesUserInfoKey: @"nonExistant" }];
    
    NSException *caughtException = nil;
    @try {
        NSArray __unused *identificationAttributes = RKIdentificationAttributesInferredFromEntity(entity);
    }
    @catch (NSException *exception) {
        caughtException = exception;
    }
    @finally {
        expect([caughtException name]).to.equal(NSInvalidArgumentException);
        expect([caughtException reason]).to.equal(@"Invalid identifier attribute specified in user info key 'RKEntityIdentificationAttributes' of entity 'Monkey': no attribue was found with the name 'nonExistant'");
    }
}

- (void)testInferenceOfSnakeCasedEntityName
{
    NSEntityDescription *entity = [[NSEntityDescription alloc] init];
    [entity setName:@"Monkey"];
    NSAttributeDescription *identifierAttribute = [NSAttributeDescription new];
    [identifierAttribute setName:@"monkey_id"];
    [entity setProperties:@[ identifierAttribute ]];
    NSArray *identificationAttributes = RKIdentificationAttributesInferredFromEntity(entity);
    expect(identificationAttributes).notTo.beNil();
    NSArray *attributeNames = @[ @"monkey_id" ];
    expect([identificationAttributes valueForKey:@"name"]).to.equal(attributeNames);
}

- (void)testInferenceOfCompoundSnakeCasedEntityName
{
    NSEntityDescription *entity = [[NSEntityDescription alloc] init];
    [entity setName:@"ArcticMonkey"];
    NSAttributeDescription *identifierAttribute = [NSAttributeDescription new];
    [identifierAttribute setName:@"arctic_monkey_id"];
    [entity setProperties:@[ identifierAttribute ]];
    NSArray *identificationAttributes = RKIdentificationAttributesInferredFromEntity(entity);
    expect(identificationAttributes).notTo.beNil();
    NSArray *attributeNames = @[ @"arctic_monkey_id" ];
    expect([identificationAttributes valueForKey:@"name"]).to.equal(attributeNames);
}

- (void)testInferenceOfSnakeCasedEntityNameWithAbbreviation
{
    NSEntityDescription *entity = [[NSEntityDescription alloc] init];
    [entity setName:@"ArcticMonkeyURL"];
    NSAttributeDescription *identifierAttribute = [NSAttributeDescription new];
    [identifierAttribute setName:@"arctic_monkey_url_id"];
    [entity setProperties:@[ identifierAttribute ]];
    NSArray *identificationAttributes = RKIdentificationAttributesInferredFromEntity(entity);
    expect(identificationAttributes).notTo.beNil();
    NSArray *attributeNames = @[ @"arctic_monkey_url_id" ];
    expect([identificationAttributes valueForKey:@"name"]).to.equal(attributeNames);
}

- (void)testEntityIdentifierInferenceSearchesParentEntities
{
    NSEntityDescription *entity = [[NSEntityDescription alloc] init];
    [entity setName:@"Monkey"];
    NSEntityDescription *parentEntity = [[NSEntityDescription alloc] init];
    [parentEntity setName:@"Parent"];
    [parentEntity setSubentities:@[ entity ]];
    NSAttributeDescription *identifierAttribute = [NSAttributeDescription new];
    [identifierAttribute setName:@"monkeyID"];
    [parentEntity setProperties:@[ identifierAttribute ]];
    NSArray *identificationAttributes = RKIdentificationAttributesInferredFromEntity(entity);
    expect(identificationAttributes).notTo.beNil();
    NSArray *attributeNames = @[ @"monkeyID" ];
    expect([identificationAttributes valueForKey:@"name"]).to.equal(attributeNames);
}

- (void)testEntityIdentifierInferenceFromUserInfoSearchesParentEntities
{
    NSEntityDescription *entity = [[NSEntityDescription alloc] init];
    [entity setName:@"Monkey"];
    NSAttributeDescription *identifierAttribute = [NSAttributeDescription new];
    [identifierAttribute setName:@"monkeyID"]; // We ignore this by specifying the userInfo key
    NSAttributeDescription *nameAttribute = [NSAttributeDescription new];
    [nameAttribute setName:@"name"];
    [entity setProperties:@[ identifierAttribute, nameAttribute ]];
    [entity setUserInfo:@{ RKEntityIdentificationAttributesUserInfoKey: @"name" }];
    
    NSEntityDescription *subentity = [NSEntityDescription new];
    [subentity setName:@"SubMonkey"];
    [entity setSubentities:@[ subentity ]];
    NSArray *identificationAttributes = RKIdentificationAttributesInferredFromEntity(subentity);
    expect(identificationAttributes).notTo.beNil();
    NSArray *attributeNames = @[ @"name" ];
    expect([identificationAttributes valueForKey:@"name"]).to.equal(attributeNames);
}

- (void)testInvokingRequestMappingRaisesHelpfulException
{
    NSException *caughtException = nil;
    @try {
        [RKEntityMapping requestMapping];
    }
    @catch (NSException *exception) {
        caughtException = exception;
    }
    expect(caughtException).notTo.beNil();
    expect(caughtException.reason).to.equal(@"`requestMapping` is not meant to be invoked on `RKEntityMapping`. You probably want to invoke `[RKObjectMapping requestMapping]`.");
}

- (void)testMappingArrayToMutableSet
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [mapping addAttributeMappingsFromDictionary:@{ @"favoriteColors": @"mutableFavoriteColors" }];
    
    NSDictionary *dictionary = @{ @"favoriteColors": @[ @"Blue", @"Red" ] };
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:human mapping:mapping];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext cache:nil];
    operation.dataSource = dataSource;
    NSError *error = nil;
    [operation performMapping:&error];
    
    assertThat(human.mutableFavoriteColors, is(equalTo([NSMutableSet setWithArray:@[ @"Blue", @"Red" ]])));
    assertThat(human.mutableFavoriteColors, is(instanceOf([NSMutableSet class])));
}

- (void)testSettingModificationAttributeForName
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [mapping setModificationAttributeForName:@"railsID"];
    expect(mapping.modificationAttribute).notTo.beNil();
    expect(mapping.modificationAttribute).to.equal(mapping.entity.attributesByName[@"railsID"]);
}

- (void)testSettingModificationAttributeForNameRaisesErrorIfNameIsInvalid
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    expect(^{ [mapping setModificationAttributeForName:@"INVALID"]; }).to.raiseWithReason(NSInvalidArgumentException, @"No attribute with the name 'INVALID' was found in the 'Human' entity.");
}

- (void)testAssigningAttributeFromOtherEntityRaisesInvalidArgumentException
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    NSEntityDescription *catEntity = managedObjectStore.managedObjectModel.entitiesByName[@"Cat"];
    expect(^{ mapping.modificationAttribute = catEntity.attributesByName[@"name"]; }).to.raiseWithReason(NSInvalidArgumentException, @"The attribute given is not a property of the 'Human' entity.");
}

- (void)testAssigningNilModificationAttribute
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    mapping.modificationAttribute = mapping.entity.attributesByName[@"railsID"];
    mapping.modificationAttribute = nil;
    expect(mapping.modificationAttribute).to.beNil();
}

- (void)testSettingNilModificationAttributeForName
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    mapping.modificationAttribute = mapping.entity.attributesByName[@"railsID"];
    [mapping setModificationAttributeForName:nil];
    expect(mapping.modificationAttribute).to.beNil();
}

@end
