//
//  RKManagedObjectMappingSpec.m
//  RestKit
//
//  Created by Blake Watters on 5/31/11.
//  Copyright 2011 Two Toasters
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

#import "RKSpecEnvironment.h"
#import "RKManagedObjectMapping.h"
#import "RKHuman.h"
#import "RKMappableObject.h"
#import "RKChild.h"
#import "RKParent.h"

@interface RKManagedObjectMappingSpec : RKSpec {
    NSAutoreleasePool *_autoreleasePool;
}

@end


@implementation RKManagedObjectMappingSpec

//- (void)setUp {
//    _autoreleasePool = [NSAutoreleasePool new];
//}
//
//- (void)tearDown {
//    [_autoreleasePool drain];
//}

- (void)testShouldReturnTheDefaultValueForACoreDataAttribute {
    // Load Core Data
    RKSpecNewManagedObjectStore();
    
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForEntityWithName:@"RKCat"];
    id value = [mapping defaultValueForMissingAttribute:@"name"];
    assertThat(value, is(equalTo(@"Kitty Cat!")));
}

- (void)testShouldCreateNewInstancesOfUnmanagedObjects {
    RKSpecNewManagedObjectStore();
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKMappableObject class]];
    id object = [mapping mappableObjectForData:[NSDictionary dictionary]];
    assertThat(object, isNot(nilValue()));
    assertThat([object class], is(equalTo([RKMappableObject class])));
}

- (void)testShouldCreateNewInstancesOfManagedObjectsWhenTheMappingIsAnRKObjectMapping {
    RKSpecNewManagedObjectStore();
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKMappableObject class]];
    id object = [mapping mappableObjectForData:[NSDictionary dictionary]];
    assertThat(object, isNot(nilValue()));
    assertThat([object class], is(equalTo([RKMappableObject class])));
}

- (void)testShouldFindExistingManagedObjectsByPrimaryKey {
    RKManagedObjectStore* store = RKSpecNewManagedObjectStore();
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[RKHuman class]];
    mapping.primaryKeyAttribute = @"railsID";
    [mapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"railsID"]];
    
    RKHuman* human = [RKHuman object];
    human.railsID = [NSNumber numberWithInt:123];
    [store save];
    assertThatBool([RKHuman hasAtLeastOneEntity], is(equalToBool(YES)));
    
    NSDictionary* data = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:123] forKey:@"id"];
    id object = [mapping mappableObjectForData:data];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(equalTo(human)));
}

- (void)testShouldFindExistingManagedObjectsByPrimaryKeyPath {
    RKManagedObjectStore* store = RKSpecNewManagedObjectStore();
    [RKHuman truncateAll];
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[RKHuman class]];
    mapping.primaryKeyAttribute = @"railsID";
    [mapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"monkey.id" toKeyPath:@"railsID"]];
    
    [RKHuman truncateAll];
    RKHuman* human = [RKHuman object];
    human.railsID = [NSNumber numberWithInt:123];
    [store save];
    assertThatBool([RKHuman hasAtLeastOneEntity], is(equalToBool(YES)));
    
    NSDictionary* data = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:123] forKey:@"id"];
    NSDictionary* nestedDictionary = [NSDictionary dictionaryWithObject:data forKey:@"monkey"];
    id object = [mapping mappableObjectForData:nestedDictionary];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(equalTo(human)));
}

- (void)testShouldCreateNewManagedObjectInstancesWhenThereIsNoPrimaryKeyInTheData {
    RKSpecNewManagedObjectStore();
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[RKHuman class]];
    mapping.primaryKeyAttribute = @"railsID";
    
    NSDictionary* data = [NSDictionary dictionary];
    id object = [mapping mappableObjectForData:data];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(instanceOf([RKHuman class])));
}

- (void)testShouldCreateNewManagedObjectInstancesWhenThereIsNoPrimaryKeyAttribute {
    RKSpecNewManagedObjectStore();
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[RKHuman class]];
    
    NSDictionary* data = [NSDictionary dictionary];
    id object = [mapping mappableObjectForData:data];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(instanceOf([RKHuman class])));
}

- (void)testShouldCreateANewManagedObjectWhenThePrimaryKeyValueIsNSNull {
    RKSpecNewManagedObjectStore();
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[RKHuman class]];
    mapping.primaryKeyAttribute = @"railsID";
    [mapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"railsID"]];
    
    NSDictionary* data = [NSDictionary dictionaryWithObject:[NSNull null] forKey:@"id"];
    id object = [mapping mappableObjectForData:data];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(instanceOf([RKHuman class])));
}

- (void)testShouldMapACollectionOfObjectsWithDynamicKeys {
    RKManagedObjectStore *objectStore = RKSpecNewManagedObjectStore();
    RKManagedObjectMapping *mapping = [RKManagedObjectMapping mappingForClass:[RKHuman class]];
    mapping.forceCollectionMapping = YES;
    mapping.primaryKeyAttribute = @"name";
    [mapping mapKeyOfNestedDictionaryToAttribute:@"name"];    
    RKObjectAttributeMapping *idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"(name).id" toKeyPath:@"railsID"];
    [mapping addAttributeMapping:idMapping];
    RKObjectMappingProvider *provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@"users"];
    
    id mockObjectStore = [OCMockObject partialMockForObject:objectStore];
    [[[mockObjectStore expect] andForwardToRealObject] findOrCreateInstanceOfEntity:OCMOCK_ANY withPrimaryKeyAttribute:@"name" andValue:@"blake"];
    [[[mockObjectStore expect] andForwardToRealObject] findOrCreateInstanceOfEntity:mapping.entity withPrimaryKeyAttribute:@"name" andValue:@"rachit"];
    id userInfo = RKSpecParseFixture(@"DynamicKeys.json");
    RKObjectMapper* mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    [mapper performMapping];
    [mockObjectStore verify];
}

- (void)testShouldPickTheAppropriateMappingBasedOnAnAttributeValue {
    RKSpecNewManagedObjectStore();
    RKDynamicObjectMapping* dynamicMapping = [RKDynamicObjectMapping dynamicMapping];
    RKManagedObjectMapping* childMapping = [RKManagedObjectMapping mappingForClass:[RKChild class]];
    childMapping.primaryKeyAttribute = @"railsID";
    [childMapping mapAttributes:@"name", nil];
    
    RKManagedObjectMapping* parentMapping = [RKManagedObjectMapping mappingForClass:[RKParent class]];
    parentMapping.primaryKeyAttribute = @"railsID";
    [parentMapping mapAttributes:@"name", @"age", nil];
    
    [dynamicMapping setObjectMapping:parentMapping whenValueOfKeyPath:@"type" isEqualTo:@"Parent"];
    [dynamicMapping setObjectMapping:childMapping whenValueOfKeyPath:@"type" isEqualTo:@"Child"];
    
    RKObjectMapping* mapping = [dynamicMapping objectMappingForDictionary:RKSpecParseFixture(@"parent.json")];
    assertThat(mapping, is(notNilValue()));
    assertThatBool([mapping isKindOfClass:[RKManagedObjectMapping class]], is(equalToBool(YES)));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"RKParent")));
    mapping = [dynamicMapping objectMappingForDictionary:RKSpecParseFixture(@"child.json")];
    assertThat(mapping, is(notNilValue()));
    assertThatBool([mapping isKindOfClass:[RKManagedObjectMapping class]], is(equalToBool(YES)));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"RKChild")));
}

- (void)testShouldIncludeTransformableAttributesInPropertyNamesAndTypes {
    RKSpecNewManagedObjectStore();
    NSDictionary *attributesByName = [[RKHuman entity] attributesByName];
    NSDictionary *propertiesByName = [[RKHuman entity] propertiesByName];
    NSDictionary *relationshipsByName = [[RKHuman entity] relationshipsByName];
    assertThat([attributesByName objectForKey:@"favoriteColors"], is(notNilValue()));
    assertThat([propertiesByName objectForKey:@"favoriteColors"], is(notNilValue()));
    assertThat([relationshipsByName objectForKey:@"favoriteColors"], is(nilValue()));

    NSDictionary *propertyNamesAndTypes = [[RKObjectPropertyInspector sharedInspector] propertyNamesAndTypesForEntity:[RKHuman entity]];
    assertThat([propertyNamesAndTypes objectForKey:@"favoriteColors"], is(notNilValue()));
}

@end
