//
//  RKObjectMappingNextGenTest.m
//  RestKit
//
//  Created by Blake Watters on 4/30/11.
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

#import <OCMock/OCMock.h>
#import <OCMock/NSNotificationCenter+OCMAdditions.h>
#import "RKTestEnvironment.h"
#import "RKObjectMapping.h"
#import "RKMappingOperation.h"
#import "RKAttributeMapping.h"
#import "RKRelationshipMapping.h"
#import "RKLog.h"
#import "RKMapperOperation.h"
#import "RKMapperOperation_Private.h"
#import "RKMappingErrors.h"
#import "RKDynamicMappingModels.h"
#import "RKTestAddress.h"
#import "RKTestUser.h"
#import "RKObjectMappingOperationDataSource.h"
#import "RKManagedObjectMappingOperationDataSource.h"
#import "RKDynamicMapping.h"
#import "RKMIMETypeSerialization.h"
#import "ISO8601DateFormatterValueTransformer.h"
#import "RKCLLocationValueTransformer.h"

// Managed Object Serialization Testific
#import "RKHuman.h"
#import "RKCat.h"
#import "RKHouse.h"

@interface RKExampleGroupWithUserArray : NSObject {
    NSString *_name;
    NSArray *_users;
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSArray *users;

@end

@implementation RKExampleGroupWithUserArray

@synthesize name = _name;
@synthesize users = _users;

+ (RKExampleGroupWithUserArray *)group
{
    return [self new];
}

// isEqual: is consulted by the mapping operation
// to determine if assocation values should be set
- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[RKExampleGroupWithUserArray class]]) {
        return [[(RKExampleGroupWithUserArray *)object name] isEqualToString:self.name];
    } else {
        return NO;
    }
}

@end

@interface RKExampleGroupWithUserSet : NSObject {
    NSString *_name;
    NSSet *_users;
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSSet *users;

@end

@implementation RKExampleGroupWithUserSet

@synthesize name = _name;
@synthesize users = _users;

+ (RKExampleGroupWithUserSet *)group
{
    return [self new];
}

// isEqual: is consulted by the mapping operation
// to determine if assocation values should be set
- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[RKExampleGroupWithUserSet class]]) {
        return [[(RKExampleGroupWithUserSet *)object name] isEqualToString:self.name];
    } else {
        return NO;
    }
}

@end

////////////////////////////////////////////////////////////////////////////////

#pragma mark -

@interface RKObjectMappingNextGenTest : RKTestCase
@property (nonatomic, copy) NSArray *originalDateValueTransformers;
@end

@implementation RKObjectMappingNextGenTest

- (void)setUp
{
    [RKTestFactory setUp];
}

- (void)tearDown
{
    [RKTestFactory tearDown];

    // Reset the default transformer
    [RKValueTransformer setDefaultValueTransformer:nil];
    RKISO8601DateFormatter *dateFormatter = [RKISO8601DateFormatter defaultISO8601DateFormatter];
    [[RKValueTransformer defaultValueTransformer] insertValueTransformer:dateFormatter atIndex:0];
}

#pragma mark - RKObjectKeyPathMapping Tests

- (void)testShouldDefineElementToPropertyMapping
{
    RKAttributeMapping *elementMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"userID"];
    assertThat(elementMapping.sourceKeyPath, is(equalTo(@"id")));
    assertThat(elementMapping.destinationKeyPath, is(equalTo(@"userID")));
}

- (void)testShouldDescribeElementMappings
{
    RKAttributeMapping *elementMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"userID"];
    assertThatBool([[elementMapping description] hasSuffix:@"id => userID>"], is(equalToBool(YES)));
}

#pragma mark - RKObjectMapping Tests

- (void)testShouldDefineMappingFromAnElementToAProperty
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *idMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addPropertyMapping:idMapping];
    assertThat(mapping.propertyMappingsBySourceKeyPath[@"id"], is(sameInstance(idMapping)));
}

- (void)testShouldAddMappingsToAttributeMappings
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *idMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addPropertyMapping:idMapping];
    assertThatBool([mapping.propertyMappings containsObject:idMapping], is(equalToBool(YES)));
    assertThatBool([mapping.attributeMappings containsObject:idMapping], is(equalToBool(YES)));
}

- (void)testShouldAddMappingsToRelationshipMappings
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKRelationshipMapping *idMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"id" toKeyPath:@"userID" withMapping:nil];
    [mapping addPropertyMapping:idMapping];
    assertThatBool([mapping.propertyMappings containsObject:idMapping], is(equalToBool(YES)));
    assertThatBool([mapping.relationshipMappings containsObject:idMapping], is(equalToBool(YES)));
}

- (void)testShouldGenerateAttributeMappings
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    assertThat(mapping.propertyMappingsBySourceKeyPath[@"name"], is(nilValue()));
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"]];
    assertThat(mapping.propertyMappingsBySourceKeyPath[@"name"], isNot(nilValue()));
}

- (void)testShouldGenerateRelationshipMappings
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectMapping *anotherMapping = [RKObjectMapping mappingForClass:[NSDictionary class]];
    assertThat(mapping.propertyMappingsBySourceKeyPath[@"another"], is(nilValue()));
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"another" toKeyPath:@"another" withMapping:anotherMapping]];
    assertThat(mapping.propertyMappingsBySourceKeyPath[@"another"], isNot(nilValue()));
}

- (void)testShouldGenerateAnInverseMappings
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"first_name" toKeyPath:@"firstName"]];
    [mapping addAttributeMappingsFromArray:@[@"city", @"state", @"zip"]];
    RKObjectMapping *otherMapping = [RKObjectMapping mappingForClass:[RKTestAddress class]];
    [otherMapping addAttributeMappingsFromArray:@[@"street"]];
    [mapping addRelationshipMappingWithSourceKeyPath:@"address" mapping:otherMapping];
    RKObjectMapping *inverse = [mapping inverseMapping];
    assertThat(inverse.objectClass, is(equalTo([NSMutableDictionary class])));
    assertThat([inverse propertyMappingsBySourceKeyPath][@"firstName"], isNot(nilValue()));
}

- (void)testShouldLetYouRetrieveMappingsByAttribute
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *attributeMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"nameAttribute"];
    [mapping addPropertyMapping:attributeMapping];
    assertThat(mapping.propertyMappingsByDestinationKeyPath[@"nameAttribute"], is(equalTo(attributeMapping)));
}

- (void)testShouldLetYouRetrieveMappingsByRelationship
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKRelationshipMapping *relationshipMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"friend" toKeyPath:@"friendRelationship" withMapping:mapping];
    [mapping addPropertyMapping:relationshipMapping];
    assertThat(mapping.propertyMappingsByDestinationKeyPath[@"friendRelationship"], is(equalTo(relationshipMapping)));
}

#pragma mark - RKMapperOperation Tests
// TODO: Move these into RKMapperOperationTest.m

- (void)testShouldPerformBasicMapping
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *idMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addPropertyMapping:idMapping];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addPropertyMapping:nameMapping];

    RKMapperOperation *mapper = [RKMapperOperation new];
    mapper.mappingOperationDataSource = [RKObjectMappingOperationDataSource new];
    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKTestUser *user = [RKTestUser user];
    BOOL success = [mapper mapRepresentation:userInfo toObject:user isNew:YES atKeyPath:@"" usingMapping:mapping metadataList:nil];
    assertThatBool(success, is(equalToBool(YES)));
    assertThatInt([user.userID intValue], is(equalToInt(31337)));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
}

- (void)testShouldMapACollectionOfSimpleObjectDictionaries
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *idMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addPropertyMapping:idMapping];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addPropertyMapping:nameMapping];

    RKMapperOperation *mapper = [RKMapperOperation new];
    mapper.mappingOperationDataSource = [RKObjectMappingOperationDataSource new];
    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"users.json"];
    NSArray *users = [mapper mapRepresentations:userInfo atKeyPath:@"" usingMapping:mapping];
    assertThatUnsignedInteger([users count], is(equalToInt(3)));
    RKTestUser *blake = users[0];
    assertThat(blake.name, is(equalTo(@"Blake Watters")));
}

- (void)testShouldIgnoreNSNullInCollections {
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *idMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addPropertyMapping:idMapping];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addPropertyMapping:nameMapping];
    
    RKMapperOperation *mapper = [RKMapperOperation new];
    mapper.mappingOperationDataSource = [RKObjectMappingOperationDataSource new];
    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"users.json"];
    NSArray *friendReps = [userInfo valueForKey:@"friend"];
    NSArray *friends = [mapper mapRepresentations:friendReps atKeyPath:@"" usingMapping:mapping];
    assertThatUnsignedInteger([friends count], is(equalToInt(1)));
    RKTestUser *tony = friends[0];
    assertThat(tony.name, is(equalTo(@"Anthony Stark")));
}

- (void)testShouldDetermineTheObjectMappingByConsultingTheMappingProviderWhenThereIsATargetObject
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    mappingsDictionary[[NSNull null]] = mapping;

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:userInfo mappingsDictionary:mappingsDictionary];
    mapper.targetObject = [RKTestUser user];
    [mapper start];
}

- (void)testShouldAddAnErrorWhenTheKeyPathMappingAndObjectClassDoNotAgree
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:userInfo mappingsDictionary:@{[NSNull null] : mapping}];
    NSDictionary *dictionary = [NSDictionary new];
    mapper.targetObject = dictionary;
    [mapper start];
    assertThat(mapper.error, is(notNilValue()));
    // TODO: Better check on the error type...
}

- (void)testShouldMapToATargetObject
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *idMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addPropertyMapping:idMapping];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addPropertyMapping:nameMapping];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:userInfo mappingsDictionary:@{[NSNull null] : mapping}];
    RKTestUser *user = [RKTestUser user];
    mapper.targetObject = user;
    [mapper start];
    RKMappingResult *result = mapper.mappingResult;

    assertThat(result, isNot(nilValue()));
    assertThatBool([result firstObject] == user, is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
}

- (void)testShouldCreateANewInstanceOfTheAppropriateDestinationObjectWhenThereIsNoTargetObject
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addPropertyMapping:nameMapping];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:userInfo mappingsDictionary:@{ [NSNull null]: mapping }];
    [mapper start];
    id mappingResult = [mapper.mappingResult firstObject];
    assertThatBool([mappingResult isKindOfClass:[RKTestUser class]], is(equalToBool(YES)));
}

- (void)testShouldMapWithoutATargetMapping
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *idMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addPropertyMapping:idMapping];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addPropertyMapping:nameMapping];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:userInfo mappingsDictionary:@{ [NSNull null]: mapping }];
    [mapper start];
    RKTestUser *user = [mapper.mappingResult firstObject];
    assertThat(user, is(notNilValue()));
    assertThatBool([user isKindOfClass:[RKTestUser class]], is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
}

- (void)testShouldMapACollectionOfObjects
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *idMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addPropertyMapping:idMapping];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addPropertyMapping:nameMapping];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"users.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:userInfo mappingsDictionary:@{ [NSNull null]: mapping }];
    [mapper start];
    NSArray *users = [mapper.mappingResult array];
    assertThatBool([users isKindOfClass:[NSArray class]], is(equalToBool(YES)));
    assertThatUnsignedInteger([users count], is(equalToInt(3)));
    RKTestUser *user = users[0];
    assertThatBool([user isKindOfClass:[RKTestUser class]], is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
}

- (void)testShouldMapACollectionOfObjectsWithDynamicKeys
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    mapping.forceCollectionMapping = YES;
    [mapping addAttributeMappingFromKeyOfRepresentationToAttribute:@"name"];
    RKAttributeMapping *idMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"(name).id" toKeyPath:@"userID"];
    [mapping addPropertyMapping:idMapping];
    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    mappingsDictionary[@"users"] = mapping;

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"DynamicKeys.json"];
    
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:userInfo mappingsDictionary:mappingsDictionary];
    [mapper start];
    NSArray *users = [mapper.mappingResult array];
    assertThatBool([users isKindOfClass:[NSArray class]], is(equalToBool(YES)));
    assertThatUnsignedInteger([users count], is(equalToInt(2)));
    RKTestUser *user = users[0];
    assertThatBool([user isKindOfClass:[RKTestUser class]], is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"blake")));
    user = users[1];
    assertThatBool([user isKindOfClass:[RKTestUser class]], is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"rachit")));
}

- (void)testShouldMapACollectionOfObjectsWithDynamicKeysAndRelationships
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    mapping.forceCollectionMapping = YES;
    [mapping addAttributeMappingFromKeyOfRepresentationToAttribute:@"name"];

    RKObjectMapping *addressMapping = [RKObjectMapping mappingForClass:[RKTestAddress class]];
    [addressMapping addAttributeMappingsFromArray:@[@"city", @"state"]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"(name).address" toKeyPath:@"address" withMapping:addressMapping]];;
    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    mappingsDictionary[@"users"] = mapping;

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"DynamicKeysWithRelationship.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:userInfo mappingsDictionary:mappingsDictionary];
    [mapper start];
    RKMappingResult *result = mapper.mappingResult;
    NSArray *users = [result array];
    assertThatBool([users isKindOfClass:[NSArray class]], is(equalToBool(YES)));
    assertThatUnsignedInteger([users count], is(equalToInt(2)));
    RKTestUser *user = users[0];
    assertThatBool([user isKindOfClass:[RKTestUser class]], is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"blake")));
    user = users[1];
    assertThatBool([user isKindOfClass:[RKTestUser class]], is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"rachit")));
    assertThat(user.address, isNot(nilValue()));
    assertThat(user.address.city, is(equalTo(@"New York")));
}

- (void)testShouldMapANestedArrayOfObjectsWithDynamicKeysAndArrayRelationships
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKExampleGroupWithUserArray class]];
    [mapping addAttributeMappingsFromArray:@[@"name"]];


    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    userMapping.forceCollectionMapping = YES;
    [userMapping addAttributeMappingFromKeyOfRepresentationToAttribute:@"name"];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"users" toKeyPath:@"users" withMapping:userMapping]];;

    RKObjectMapping *addressMapping = [RKObjectMapping mappingForClass:[RKTestAddress class]];
    [addressMapping addAttributeMappingsFromDictionary:@{
        @"city": @"city",
        @"state": @"state",
        @"country": @"country",
     }];
    [userMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"(name).address" toKeyPath:@"address" withMapping:addressMapping]];;
    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    mappingsDictionary[@"groups"] = mapping;

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"DynamicKeysWithNestedRelationship.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:userInfo mappingsDictionary:mappingsDictionary];
    [mapper start];
    RKMappingResult *result = mapper.mappingResult;

    NSArray *groups = [result array];
    assertThatBool([groups isKindOfClass:[NSArray class]], is(equalToBool(YES)));
    assertThatUnsignedInteger([groups count], is(equalToInt(2)));

    RKExampleGroupWithUserArray *group = groups[0];
    assertThatBool([group isKindOfClass:[RKExampleGroupWithUserArray class]], is(equalToBool(YES)));
    assertThat(group.name, is(equalTo(@"restkit")));
    NSArray *users = group.users;
    RKTestUser *user = users[0];
    assertThatBool([user isKindOfClass:[RKTestUser class]], is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"blake")));
    user = users[1];
    assertThatBool([user isKindOfClass:[RKTestUser class]], is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"rachit")));
    assertThat(user.address, isNot(nilValue()));
    assertThat(user.address.city, is(equalTo(@"New York")));

    group = groups[1];
    assertThatBool([group isKindOfClass:[RKExampleGroupWithUserArray class]], is(equalToBool(YES)));
    assertThat(group.name, is(equalTo(@"others")));
    users = group.users;
    assertThatUnsignedInteger([users count], is(equalToInt(1)));
    user = users[0];
    assertThatBool([user isKindOfClass:[RKTestUser class]], is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"bjorn")));
    assertThat(user.address, isNot(nilValue()));
    assertThat(user.address.city, is(equalTo(@"Gothenburg")));
    assertThat(user.address.country, is(equalTo(@"Sweden")));
}

- (void)testShouldMapANestedArrayOfObjectsWithDynamicKeysAndSetRelationships
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKExampleGroupWithUserSet class]];
    [mapping addAttributeMappingsFromArray:@[@"name"]];


    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    userMapping.forceCollectionMapping = YES;
    [userMapping addAttributeMappingFromKeyOfRepresentationToAttribute:@"name"];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"users" toKeyPath:@"users" withMapping:userMapping]];;

    RKObjectMapping *addressMapping = [RKObjectMapping mappingForClass:[RKTestAddress class]];
    [addressMapping  addAttributeMappingsFromDictionary:@{
        @"city": @"city",
        @"state": @"state",
        @"country": @"country",
     }];
    [userMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"(name).address" toKeyPath:@"address" withMapping:addressMapping]];;
    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    mappingsDictionary[@"groups"] = mapping;

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"DynamicKeysWithNestedRelationship.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:userInfo mappingsDictionary:mappingsDictionary];
    [mapper start];
    RKMappingResult *result = mapper.mappingResult;

    NSArray *groups = [result array];
    assertThatBool([groups isKindOfClass:[NSArray class]], is(equalToBool(YES)));
    assertThatUnsignedInteger([groups count], is(equalToInt(2)));

    RKExampleGroupWithUserSet *group = groups[0];
    assertThatBool([group isKindOfClass:[RKExampleGroupWithUserSet class]], is(equalToBool(YES)));
    assertThat(group.name, is(equalTo(@"restkit")));


    NSSortDescriptor *sortByName = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    NSArray *descriptors = @[sortByName];;
    NSArray *users = [group.users sortedArrayUsingDescriptors:descriptors];
    RKTestUser *user = users[0];
    assertThatBool([user isKindOfClass:[RKTestUser class]], is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"blake")));
    user = users[1];
    assertThatBool([user isKindOfClass:[RKTestUser class]], is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"rachit")));
    assertThat(user.address, isNot(nilValue()));
    assertThat(user.address.city, is(equalTo(@"New York")));

    group = groups[1];
    assertThatBool([group isKindOfClass:[RKExampleGroupWithUserSet class]], is(equalToBool(YES)));
    assertThat(group.name, is(equalTo(@"others")));
    users = [group.users sortedArrayUsingDescriptors:descriptors];
    assertThatUnsignedInteger([users count], is(equalToInt(1)));
    user = users[0];
    assertThatBool([user isKindOfClass:[RKTestUser class]], is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"bjorn")));
    assertThat(user.address, isNot(nilValue()));
    assertThat(user.address.city, is(equalTo(@"Gothenburg")));
    assertThat(user.address.country, is(equalTo(@"Sweden")));
}


- (void)testShouldBeAbleToMapFromAUserObjectToADictionary
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKAttributeMapping *idMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"userID" toKeyPath:@"id"];
    [mapping addPropertyMapping:idMapping];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addPropertyMapping:nameMapping];

    RKTestUser *user = [RKTestUser user];
    user.name = @"Blake Watters";
    user.userID = @123;

    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:user mappingsDictionary:@{ [NSNull null]: mapping }];
    [mapper start];
    RKMappingResult *result = mapper.mappingResult;
    NSDictionary *userInfo = [result firstObject];
    assertThatBool([userInfo isKindOfClass:[NSDictionary class]], is(equalToBool(YES)));
    assertThat([userInfo valueForKey:@"name"], is(equalTo(@"Blake Watters")));
}

- (void)testShouldMapRegisteredSubKeyPathsOfAnUnmappableDictionaryAndReturnTheResults
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *idMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addPropertyMapping:idMapping];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addPropertyMapping:nameMapping];
    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    mappingsDictionary[@"user"] = mapping;

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"nested_user.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:userInfo mappingsDictionary:mappingsDictionary];
    [mapper start];
    NSDictionary *dictionary = [mapper.mappingResult dictionary];
    assertThatBool([dictionary isKindOfClass:[NSDictionary class]], is(equalToBool(YES)));
    RKTestUser *user = dictionary[@"user"];
    assertThat(user, isNot(nilValue()));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
}

#pragma mark Mapping Error States

- (void)testThatMappingWithTargetObjectThatDoesNotMatchRepresentationWorks
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *idMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addPropertyMapping:idMapping];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addPropertyMapping:nameMapping];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"users.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:userInfo mappingsDictionary:@{ [NSNull null]: mapping }];
    mapper.targetObject = [RKTestUser user];
    [mapper start];
    assertThat(mapper.error, is(nilValue()));
    assertThat(mapper.mappingResult, hasCountOf(3));
}

- (void)testShouldAddAnErrorWhenAttemptingToMapADictionaryWithoutAnObjectMapping
{
    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:userInfo mappingsDictionary:@{}];
    [mapper start];
    assertThat([mapper.error localizedDescription], is(equalTo(@"No mappable object representations were found at the key paths searched.")));
}

- (void)testShouldAddAnErrorWhenAttemptingToMapACollectionWithoutAnObjectMapping
{
    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"users.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:userInfo mappingsDictionary:mappingsDictionary];
    [mapper start];
    assertThat([mapper.error localizedDescription], is(equalTo(@"No mappable object representations were found at the key paths searched.")));
}

- (void)testThatAnErrorIsSetWithAHelpfulDescriptionWhenNoKeyPathsMatchTheArrayOfObjectsRepresentationBeingMapped
{
    RKObjectMapping *mapping1 = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKObjectMapping *mapping2 = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    NSDictionary *mappingsDictionary = @{ @"this": mapping1, @"that": mapping2 };
    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"users.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:userInfo mappingsDictionary:mappingsDictionary];
    [mapper start];
    assertThat([mapper.error localizedDescription], is(equalTo(@"No mappable object representations were found at the key paths searched.")));
    assertThat([mapper.error localizedFailureReason], is(equalTo(@"The mapping operation was unable to find any nested object representations at the key paths searched: that, this\nThis likely indicates that you have misconfigured the key paths for your mappings.")));
}

- (void)testThatAnErrorIsSetWithAHelpfulDescriptionWhenNoKeyPathsMatchTheObjectRepresentationBeingMapped
{
    RKObjectMapping *mapping1 = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKObjectMapping *mapping2 = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    NSDictionary *mappingsDictionary = @{ @"this": mapping1, @"that": mapping2 };
    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"RailsUser.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:userInfo mappingsDictionary:mappingsDictionary];
    [mapper start];
    assertThat([mapper.error localizedDescription], is(equalTo(@"No mappable object representations were found at the key paths searched.")));
    assertThat([mapper.error localizedFailureReason], is(equalTo(@"The mapping operation was unable to find any nested object representations at the key paths searched: that, this\nThe representation inputted to the mapper was found to contain nested object representations at the following key paths: user\nThis likely indicates that you have misconfigured the key paths for your mappings.")));
}

#pragma mark RKMapperOperationDelegate Tests

- (void)testShouldInformTheDelegateWhenMappingBegins
{
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKMapperOperationDelegate)];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"users.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:userInfo mappingsDictionary:@{ [NSNull null]: mapping }];
    [[mockDelegate expect] mapperWillStartMapping:mapper];
    mapper.delegate = mockDelegate;
    [mapper start];
    [mockDelegate verify];
}

- (void)testShouldInformTheDelegateWhenMappingEnds
{
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKMapperOperationDelegate)];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"users.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:userInfo mappingsDictionary:@{ [NSNull null]: mapping }];
    [[mockDelegate stub] mapperWillStartMapping:mapper];
    [[mockDelegate expect] mapperDidFinishMapping:mapper];
    mapper.delegate = mockDelegate;
    [mapper start];
    [mockDelegate verify];
}

- (void)testThatMappingResultIsSetBeforeDidFinishMappingIsInvoked
{
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKMapperOperationDelegate)];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    
    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"users.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:userInfo mappingsDictionary:@{ [NSNull null]: mapping }];
    [[mockDelegate stub] mapperWillStartMapping:mapper];
    __block RKMappingResult *mappingResult;
    [[[mockDelegate expect] andDo:^(NSInvocation *invocation) {
        __unsafe_unretained RKMapperOperation *mapperOperationArgument;
        [invocation getArgument:&mapperOperationArgument atIndex:2];
        mappingResult = mapperOperationArgument.mappingResult;
    }] mapperDidFinishMapping:mapper];
    mapper.delegate = mockDelegate;
    [mapper start];
    [mockDelegate verify];
    expect(mappingResult).notTo.beNil();
}

- (void)testShouldInformTheDelegateWhenCheckingForObjectMappingForKeyPathIsSuccessful
{
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKMapperOperationDelegate)];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:userInfo mappingsDictionary:@{ [NSNull null]: mapping }];
    [[mockDelegate expect] mapper:mapper didFindRepresentationOrArrayOfRepresentations:OCMOCK_ANY atKeyPath:nil];
    mapper.delegate = mockDelegate;
    [mapper start];
    [mockDelegate verify];
}

- (void)testShouldInformTheDelegateWhenCheckingForObjectMappingForKeyPathIsNotSuccessful
{
    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    mappingsDictionary[@"users"] = mapping;

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:userInfo mappingsDictionary:mappingsDictionary];
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKMapperOperationDelegate)];
    [[mockDelegate expect] mapper:mapper didNotFindRepresentationOrArrayOfRepresentationsAtKeyPath:@"users"];
    mapper.delegate = mockDelegate;
    [mapper start];
    [mockDelegate verify];
}

- (void)testShouldNotifyTheDelegateWhenItDidMapAnObject
{
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKMapperOperationDelegate)];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addPropertyMapping:nameMapping];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:userInfo mappingsDictionary:@{ [NSNull null]: mapping }];
    [[mockDelegate expect] mapper:mapper didFinishMappingOperation:OCMOCK_ANY forKeyPath:nil];
    mapper.delegate = mockDelegate;
    [mapper start];
    [mockDelegate verify];
}

- (void)testMappingConstructsMappingInfoDictionaryWithAttributeInfo
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping addAttributeMappingsFromArray:@[ @"name" ]];
    NSDictionary *representation = @{ @"name": @"Blake Watters" };
    RKTestUser *user = [RKTestUser new];
    RKMappingOperation *mappingOperation = [[RKMappingOperation alloc] initWithSourceObject:representation destinationObject:user mapping:mapping];
    [mappingOperation start];
    expect(mappingOperation.mappingInfo).notTo.beNil();
    RKPropertyMapping *nameMapping = mappingOperation.mappingInfo[@"name"];
    expect(nameMapping).to.equal([mapping propertyMappingsByDestinationKeyPath][@"name"]);
}

- (void)testAccessingPropertyAndRelationshipSpecificMappingInfo
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping addAttributeMappingsFromArray:@[ @"name" ]];
    [mapping addRelationshipMappingWithSourceKeyPath:@"friends" mapping:mapping];
    NSDictionary *representation = @{ @"name": @"Blake Watters", @"friends": @[ @{ @"name": @"Jeff Arena"} ] };
    RKTestUser *user = [RKTestUser new];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    OCMockObject *mockDataSource = [OCMockObject partialMockForObject:dataSource];
    [[[mockDataSource stub] andReturnValue:@YES] mappingOperationShouldCollectMappingInfo:OCMOCK_ANY];
    RKMappingOperation *mappingOperation = [[RKMappingOperation alloc] initWithSourceObject:representation destinationObject:user mapping:mapping];
    mappingOperation.dataSource = dataSource;
    [mappingOperation start];
    expect(mappingOperation.mappingInfo).notTo.beNil();
    RKPropertyMapping *friendsMapping = mappingOperation.mappingInfo[@"friends"];
    RKPropertyMapping *nameMapping = mappingOperation.mappingInfo[@"name"];
    expect(nameMapping).to.equal([mapping propertyMappingsByDestinationKeyPath][@"name"]);
    expect(friendsMapping).to.equal([mapping propertyMappingsByDestinationKeyPath][@"friends"]);
    
    NSArray *relationshipMappingInfo = [mappingOperation.mappingInfo relationshipMappingInfo][@"friends"];
    expect([relationshipMappingInfo count]).to.equal(1);
    expect(relationshipMappingInfo[0][@"name"]).notTo.beNil();
}

- (void)testThatMappingHasManyDoesNotDuplicateRelationshipMappingInMappingInfo
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping addAttributeMappingsFromArray:@[ @"name" ]];
    [mapping addRelationshipMappingWithSourceKeyPath:@"friends" mapping:mapping];
    NSDictionary *representation = @{ @"name": @"Blake Watters", @"friends": @[ @{ @"name": @"Jeff Arena"}, @{ @"name": @"Dan Gellert" } ] };
    RKTestUser *user = [RKTestUser new];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    OCMockObject *mockDataSource = [OCMockObject partialMockForObject:dataSource];
    [[[mockDataSource stub] andReturnValue:@YES] mappingOperationShouldCollectMappingInfo:OCMOCK_ANY];
    RKMappingOperation *mappingOperation = [[RKMappingOperation alloc] initWithSourceObject:representation destinationObject:user mapping:mapping];
    mappingOperation.dataSource = dataSource;
    [mappingOperation start];
    expect(mappingOperation.mappingInfo).notTo.beNil();
    RKPropertyMapping *friendsMapping = mappingOperation.mappingInfo[@"friends"];
    expect(friendsMapping).to.equal([mapping propertyMappingsByDestinationKeyPath][@"friends"]);
}

- (void)testThatDynamicMappingCoalescesObjectClassesInMappingInfo
{
    // use a dynamic mapping with 2 classes, should have an objectClass as an array containing both
}

- (void)testMapperOperationAggregatesMappingInfoFromChildOperations
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping addAttributeMappingsFromArray:@[ @"name" ]];
    [mapping addRelationshipMappingWithSourceKeyPath:@"friends" mapping:mapping];
    NSDictionary *representation = @{ @"name": @"Blake Watters", @"friends": @[ @{ @"name": @"Jeff Arena"}, @{ @"name": @"Dan Gellert" } ] };
    RKTestUser *user = [RKTestUser new];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    OCMockObject *mockDataSource = [OCMockObject partialMockForObject:dataSource];
    [[[mockDataSource stub] andReturnValue:@YES] mappingOperationShouldCollectMappingInfo:OCMOCK_ANY];
    RKMapperOperation *mapperOperation = [[RKMapperOperation alloc] initWithRepresentation:representation mappingsDictionary:@{ [NSNull null]: mapping }];
    mapperOperation.targetObject = user;
    mapperOperation.mappingOperationDataSource = dataSource;
    [mapperOperation start];
    expect(mapperOperation.mappingInfo).notTo.beNil();
    RKPropertyMapping *friendsMapping = mapperOperation.mappingInfo[[NSNull null]][0][@"friends"];
    expect(friendsMapping).to.equal([mapping propertyMappingsByDestinationKeyPath][@"friends"]);
}

- (BOOL)fakeValidateValue:(inout id *)ioValue forKeyPath:(NSString *)inKey error:(out NSError **)outError
{
    *outError = [NSError errorWithDomain:RKErrorDomain code:1234 userInfo:nil];
    return NO;
}

- (void)testShouldNotifyTheDelegateWhenItFailedToMapAnObject
{
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKMapperOperationDelegate)];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping addAttributeMappingsFromArray:@[@"name"]];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:userInfo mappingsDictionary:@{ [NSNull null]: mapping }];
    RKTestUser *exampleUser = [RKTestUser new];
    id mockInspector = [OCMockObject partialMockForObject:[RKPropertyInspector sharedInspector]];
    [[[mockInspector stub] andReturn:nil] propertyInspectionForClass:OCMOCK_ANY];
    id mockObject = [OCMockObject partialMockForObject:exampleUser];
    [[[mockObject expect] andCall:@selector(fakeValidateValue:forKeyPath:error:) onObject:self] validateValue:(id __autoreleasing *)[OCMArg anyPointer] forKeyPath:OCMOCK_ANY error:(NSError * __autoreleasing *)[OCMArg anyPointer]];
    mapper.targetObject = mockObject;
    [[mockDelegate expect] mapper:mapper didFailMappingOperation:OCMOCK_ANY forKeyPath:nil withError:OCMOCK_ANY];
    mapper.delegate = mockDelegate;
    [mapper start];
    [mockInspector stopMocking];
    [mockObject verify];
    [mockDelegate verify];
}

#pragma mark - RKObjectMappingOperationTests

- (void)testShouldBeAbleToMapADictionaryToAUser
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKAttributeMapping *idMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addPropertyMapping:idMapping];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addPropertyMapping:nameMapping];

    NSDictionary *dictionary = @{@"id": @123, @"name": @"Blake Watters"};
    RKTestUser *user = [RKTestUser user];

    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    [operation start];
    assertThat(user.name, is(equalTo(@"Blake Watters")));
    assertThatInt([user.userID intValue], is(equalToInt(123)));
}

- (void)testShouldConsiderADictionaryContainingOnlyNullValuesForKeysMappable
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKAttributeMapping *idMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addPropertyMapping:idMapping];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addPropertyMapping:nameMapping];

    NSDictionary *dictionary = @{ @"name": [NSNull null] };
    RKTestUser *user = [RKTestUser user];

    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    BOOL success = [operation performMapping:nil];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(user.name, is(nilValue()));
}

- (void)testShouldBeAbleToMapAUserToADictionary
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKAttributeMapping *idMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"userID" toKeyPath:@"id"];
    [mapping addPropertyMapping:idMapping];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addPropertyMapping:nameMapping];

    RKTestUser *user = [RKTestUser user];
    user.name = @"Blake Watters";
    user.userID = @123;

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:user destinationObject:dictionary mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    BOOL success = [operation performMapping:nil];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat([dictionary valueForKey:@"name"], is(equalTo(@"Blake Watters")));
    assertThatInt([[dictionary valueForKey:@"id"] intValue], is(equalToInt(123)));
}

- (void)testThatMappingSourceObjectWithNilValuesForSpecifiedKeysAssignsNilToDestinationObject
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKAttributeMapping *idMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addPropertyMapping:idMapping];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addPropertyMapping:nameMapping];

    NSDictionary *dictionary = @{@"favorite_color": @"blue", @"preferred_beverage": @"coffee"};
    RKTestUser *user = [RKTestUser user];
    user.name = @"name";
    user.userID = @12345;
    id mockUser = [OCMockObject partialMockForObject:user];
    [[mockUser reject] setUserID:nil];
    [(RKTestUser *)[mockUser reject] setName:nil];

    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:mockUser mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(NO)));
    [mockUser verify];
}

- (void)testShouldInformTheDelegateOfAnErrorWhenMappingFailsBecauseThereIsNoMappableContent
{
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKMappingOperationDelegate)];
    [[mockDelegate expect] mappingOperation:OCMOCK_ANY didFailWithError:OCMOCK_ANY];

    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKAttributeMapping *idMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addPropertyMapping:idMapping];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addPropertyMapping:nameMapping];

    NSDictionary *dictionary = @{@"favorite_color": @"blue", @"preferred_beverage": @"coffee"};
    RKTestUser *user = [RKTestUser user];

    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    operation.delegate = mockDelegate;
    BOOL success = [operation performMapping:nil];
    assertThatBool(success, is(equalToBool(NO)));
    [mockDelegate verify];
}

- (void)testShouldSetTheErrorWhenMappingOperationFails
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKAttributeMapping *idMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addPropertyMapping:idMapping];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addPropertyMapping:nameMapping];

    NSDictionary *dictionary = @{@"id": @"FAILURE"};
    RKTestUser *user = [RKTestUser user];
    id mockObject = [OCMockObject partialMockForObject:user];
    [[[mockObject expect] andCall:@selector(fakeValidateValue:forKeyPath:error:) onObject:self] validateValue:(id __autoreleasing *)[OCMArg anyPointer] forKeyPath:OCMOCK_ANY error:(NSError * __autoreleasing *)[OCMArg anyPointer]];

    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:mockObject mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    [operation performMapping:&error];
    assertThat(error, isNot(nilValue()));
}

#pragma mark - Attribute Mapping

- (void)testShouldMapAStringToADateAttribute
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *birthDateMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"birthdate" toKeyPath:@"birthDate"];
    [mapping addPropertyMapping:birthDateMapping];

    NSDictionary *dictionary = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKTestUser *user = [RKTestUser user];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    [operation performMapping:&error];

    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];
    assertThat([dateFormatter stringFromDate:user.birthDate], is(equalTo(@"11/27/1982")));
}

- (void)testShouldMapStringToURL
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *websiteMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"website" toKeyPath:@"website"];
    [mapping addPropertyMapping:websiteMapping];

    NSDictionary *dictionary = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKTestUser *user = [RKTestUser user];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    [operation performMapping:&error];

    assertThat(user.website, isNot(nilValue()));
    assertThatBool([user.website isKindOfClass:[NSURL class]], is(equalToBool(YES)));
    assertThat([user.website absoluteString], is(equalTo(@"http://restkit.org/")));
}

- (void)testShouldMapAStringToANumberBool
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *websiteMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"is_developer" toKeyPath:@"isDeveloper"];
    [mapping addPropertyMapping:websiteMapping];

    NSDictionary *dictionary = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKTestUser *user = [RKTestUser user];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    [operation performMapping:&error];

    assertThatBool([[user isDeveloper] boolValue], is(equalToBool(YES)));
}

- (void)testShouldMapAShortTrueStringToANumberBool
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *websiteMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"is_developer" toKeyPath:@"isDeveloper"];
    [mapping addPropertyMapping:websiteMapping];

    NSDictionary *dictionary = [[RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    RKTestUser *user = [RKTestUser user];
    [dictionary setValue:@"T" forKey:@"is_developer"];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    [operation performMapping:&error];

    assertThatBool([[user isDeveloper] boolValue], is(equalToBool(YES)));
}

- (void)testShouldMapAShortFalseStringToANumberBool
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *websiteMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"is_developer" toKeyPath:@"isDeveloper"];
    [mapping addPropertyMapping:websiteMapping];

    NSDictionary *dictionary = [[RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    RKTestUser *user = [RKTestUser user];
    [dictionary setValue:@"f" forKey:@"is_developer"];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    [operation performMapping:&error];

    assertThatBool([[user isDeveloper] boolValue], is(equalToBool(NO)));
}

- (void)testShouldMapAYesStringToANumberBool
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *websiteMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"is_developer" toKeyPath:@"isDeveloper"];
    [mapping addPropertyMapping:websiteMapping];

    NSDictionary *dictionary = [[RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    RKTestUser *user = [RKTestUser user];
    [dictionary setValue:@"yes" forKey:@"is_developer"];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    [operation performMapping:&error];

    assertThatBool([[user isDeveloper] boolValue], is(equalToBool(YES)));
}

- (void)testShouldMapANoStringToANumberBool
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *websiteMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"is_developer" toKeyPath:@"isDeveloper"];
    [mapping addPropertyMapping:websiteMapping];

    NSDictionary *dictionary = [[RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    RKTestUser *user = [RKTestUser user];
    [dictionary setValue:@"NO" forKey:@"is_developer"];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    [operation performMapping:&error];

    assertThatBool([[user isDeveloper] boolValue], is(equalToBool(NO)));
}

- (void)testShouldMapAYCharacterStringToANumberBool
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *websiteMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"is_developer" toKeyPath:@"isDeveloper"];
    [mapping addPropertyMapping:websiteMapping];
    
    NSDictionary *dictionary = [[RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    RKTestUser *user = [RKTestUser user];
    [dictionary setValue:@"y" forKey:@"is_developer"];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    [operation performMapping:&error];
    
    assertThatBool([[user isDeveloper] boolValue], is(equalToBool(YES)));
}

- (void)testShouldMapANCharacterStringToANumberBool
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *websiteMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"is_developer" toKeyPath:@"isDeveloper"];
    [mapping addPropertyMapping:websiteMapping];
    
    NSDictionary *dictionary = [[RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    RKTestUser *user = [RKTestUser user];
    [dictionary setValue:@"n" forKey:@"is_developer"];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    [operation performMapping:&error];
    
    assertThatBool([[user isDeveloper] boolValue], is(equalToBool(NO)));
}

- (void)testShouldMapAStringToANumber
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *websiteMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"lucky_number" toKeyPath:@"luckyNumber"];
    [mapping addPropertyMapping:websiteMapping];

    NSDictionary *dictionary = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKTestUser *user = [RKTestUser user];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    [operation performMapping:&error];

    assertThatInt([user.luckyNumber intValue], is(equalToInt(187)));
}

- (void)testShouldMapAStringToADecimalNumber
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *websiteMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"weight" toKeyPath:@"weight"];
    [mapping addPropertyMapping:websiteMapping];

    NSDictionary *dictionary = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKTestUser *user = [RKTestUser user];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    [operation performMapping:&error];

    NSDecimalNumber *weight = user.weight;
    assertThatBool([weight isKindOfClass:[NSDecimalNumber class]], is(equalToBool(YES)));
    assertThatInteger([weight compare:[NSDecimalNumber decimalNumberWithString:@"131.3"]], is(equalToInt(NSOrderedSame)));
}

- (void)testShouldMapANumberToAString
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *websiteMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"lucky_number" toKeyPath:@"name"];
    [mapping addPropertyMapping:websiteMapping];

    NSDictionary *dictionary = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKTestUser *user = [RKTestUser user];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    [operation performMapping:&error];

    assertThat(user.name, is(equalTo(@"187")));
}

- (void)testShouldMapANumberToANSDecimalNumber
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *websiteMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"lucky_number" toKeyPath:@"weight"];
    [mapping addPropertyMapping:websiteMapping];

    NSDictionary *dictionary = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKTestUser *user = [RKTestUser user];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    [operation performMapping:&error];

    NSDecimalNumber *weight = user.weight;
    assertThat(weight, is(instanceOf([NSDecimalNumber class])));
    assertThatInteger([weight compare:[NSDecimalNumber decimalNumberWithString:@"187"]], is(equalToInt(NSOrderedSame)));
}

- (void)testShouldMapANumberToADate
{
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];
    NSDate *date = [dateFormatter dateFromString:@"11/27/1982"];

    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *birthDateMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"dateAsNumber" toKeyPath:@"birthDate"];
    [mapping addPropertyMapping:birthDateMapping];

    NSMutableDictionary *dictionary = [[RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    [dictionary setValue:[NSNumber numberWithInt:[date timeIntervalSince1970]] forKey:@"dateAsNumber"];
    RKTestUser *user = [RKTestUser user];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    [operation performMapping:&error];

    assertThat([dateFormatter stringFromDate:user.birthDate], is(equalTo(@"11/27/1982")));
}

- (void)testShouldMapANestedKeyPathToAnAttribute
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *countryMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"address.country" toKeyPath:@"country"];
    [mapping addPropertyMapping:countryMapping];

    NSDictionary *dictionary = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKTestUser *user = [RKTestUser user];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    [operation performMapping:&error];

    assertThat(user.country, is(equalTo(@"USA")));
}

- (void)testShouldMapANestedArrayOfStringsToAnAttribute
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *countryMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"interests" toKeyPath:@"interests"];
    [mapping addPropertyMapping:countryMapping];

    NSDictionary *dictionary = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKTestUser *user = [RKTestUser user];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    [operation performMapping:&error];

    NSArray *interests = @[@"Hacking", @"Running"];
    assertThat(user.interests, is(equalTo(interests)));
}

- (void)testShouldMapANestedDictionaryToAnAttribute
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *countryMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"address" toKeyPath:@"addressDictionary"];
    [mapping addPropertyMapping:countryMapping];

    NSDictionary *dictionary = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKTestUser *user = [RKTestUser user];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    [operation performMapping:&error];

    NSDictionary *address = @{
                             @"city": @"Carrboro",
                             @"state": @"North Carolina",
                             @"id": @1234,
                             @"country": @"USA"};
    assertThat(user.addressDictionary, is(equalTo(address)));
}

- (void)testShouldNotSetAPropertyWhenTheValueIsTheSame
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addPropertyMapping:nameMapping];

    NSDictionary *dictionary = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKTestUser *user = [RKTestUser user];
    user.name = @"Blake Watters";
    id mockUser = [OCMockObject partialMockForObject:user];
    [(RKTestUser *)[mockUser reject] setName:OCMOCK_ANY];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    [operation performMapping:&error];
}

- (void)testShouldNotSetTheDestinationPropertyWhenBothAreNil
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addPropertyMapping:nameMapping];

    NSMutableDictionary *dictionary = [[RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    [dictionary setValue:[NSNull null] forKey:@"name"];
    RKTestUser *user = [RKTestUser user];
    user.name = nil;
    id mockUser = [OCMockObject partialMockForObject:user];
    [(RKTestUser *)[mockUser reject] setName:OCMOCK_ANY];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    [operation performMapping:&error];
}

- (void)testShouldSetNilForNSNullValues
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addPropertyMapping:nameMapping];

    NSDictionary *dictionary = [[RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    [dictionary setValue:[NSNull null] forKey:@"name"];
    RKTestUser *user = [RKTestUser user];
    user.name = @"Blake Watters";
    id mockUser = [OCMockObject partialMockForObject:user];
    [(RKTestUser *)[mockUser expect] setName:nil];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    [operation performMapping:&error];
    [mockUser verify];
}

- (void)testDelegateIsInformedWhenANilValueIsMappedForNSNullWithExistingValue
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addPropertyMapping:nameMapping];

    NSDictionary *dictionary = [[RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    [dictionary setValue:[NSNull null] forKey:@"name"];
    RKTestUser *user = [RKTestUser user];
    user.name = @"Blake Watters";
    id mockDelegate = [OCMockObject mockForProtocol:@protocol(RKMappingOperationDelegate)];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];    
    operation.delegate = mockDelegate;
    NSError *error = nil;
    [[mockDelegate expect] mappingOperation:operation didFindValue:[NSNull null] forKeyPath:@"name" mapping:nameMapping];
    [[[mockDelegate stub] andReturnValue:OCMOCK_VALUE(YES)] mappingOperation:operation shouldSetValue:nil forKeyPath:@"name" usingMapping:nameMapping];
    [[mockDelegate expect] mappingOperation:operation didSetValue:nil forKeyPath:@"name" usingMapping:nameMapping];
    operation.dataSource = dataSource;
    [operation performMapping:&error];
    [mockDelegate verify];
}

- (void)testDelegateIsInformedWhenUnchangedValueIsSkipped
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addPropertyMapping:nameMapping];

    NSDictionary *dictionary = [[RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    [dictionary setValue:@"Blake Watters" forKey:@"name"];
    RKTestUser *user = [RKTestUser user];
    user.name = @"Blake Watters";
    id mockDelegate = [OCMockObject mockForProtocol:@protocol(RKMappingOperationDelegate)];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    operation.delegate = mockDelegate;
    NSError *error = nil;
    [[mockDelegate expect] mappingOperation:operation didFindValue:@"Blake Watters" forKeyPath:@"name" mapping:nameMapping];
    [[mockDelegate expect] mappingOperation:operation shouldSetValue:@"Blake Watters" forKeyPath:@"name" usingMapping:nameMapping];
    [[mockDelegate expect] mappingOperation:operation didNotSetUnchangedValue:@"Blake Watters" forKeyPath:@"name" usingMapping:nameMapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    [operation performMapping:&error];
    [mockDelegate verify];
}

- (void)testShouldOptionallySetDefaultValueForAMissingKeyPath
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addPropertyMapping:nameMapping];

    NSMutableDictionary *dictionary = [[RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    [dictionary removeObjectForKey:@"name"];
    RKTestUser *user = [RKTestUser user];
    user.name = @"Blake Watters";
    id mockUser = [OCMockObject partialMockForObject:user];
    [(RKTestUser *)[mockUser expect] setName:nil];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    id mockMapping = [OCMockObject partialMockForObject:mapping];
    [[[mockMapping expect] andReturnValue:@YES] assignsDefaultValueForMissingAttributes];
    NSError *error = nil;
    [operation performMapping:&error];
    [mockUser verify];
}

- (void)testMappingFromMissingSourceKeyPathAssignsNil
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addPropertyMapping:nameMapping];

    NSMutableDictionary *dictionary = [[RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    [dictionary removeObjectForKey:@"name"];
    RKTestUser *user = [RKTestUser user];
    user.name = @"Blake Watters";
    id mockUser = [OCMockObject partialMockForObject:user];
    [(RKTestUser *)[mockUser expect] setName:nil];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    id mockMapping = [OCMockObject partialMockForObject:mapping];
    [[[mockMapping expect] andReturnValue:@NO] shouldSetDefaultValueForMissingAttributes];
    NSError *error = nil;
    [operation performMapping:&error];
    assertThat(user.name, is(equalTo(@"Blake Watters")));
}

- (void)testMappingToAnNSDataAttributeUsingKeyedArchiver
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *attributeMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"arrayOfStrings" toKeyPath:@"data"];
    [mapping addPropertyMapping:attributeMapping];
    
    NSDictionary *dictionary = @{ @"arrayOfStrings": @[ @"one", @"two", @"three" ] };
    RKTestUser *user = [RKTestUser user];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    expect(success).to.equal(YES);
    expect(user.data).notTo.beNil();
    NSDictionary *decodedDictionary = [NSKeyedUnarchiver unarchiveObjectWithData:user.data];
    NSArray *expectedValue = @[ @"one", @"two", @"three" ];
    expect(decodedDictionary).to.equal(expectedValue);
}

- (void)testShouldMapNSDateDistantFutureDateStringToADate
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *birthDateMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"birthdate" toKeyPath:@"birthDate"];
    [mapping addPropertyMapping:birthDateMapping];

    NSMutableDictionary *dictionary = [[RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    dictionary[@"birthdate"] = @"3001-01-01T00:00:00Z";
    RKTestUser *user = [RKTestUser user];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    [operation performMapping:&error];

    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];
    assertThat([dateFormatter stringFromDate:user.birthDate], is(equalTo(@"01/01/3001")));
}

- (void)testMappingASingularValueToAnArray
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping addAttributeMappingsFromArray:@[ @"favoriteColors" ]];
    
    NSDictionary *dictionary = @{ @"favoriteColors": @"Blue" };
    RKTestUser *user = [RKTestUser user];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    [operation performMapping:&error];
    
    assertThat(user.favoriteColors, is(equalTo(@[ @"Blue" ])));
}

- (void)testMappingArrayToMutableArray
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping addAttributeMappingsFromDictionary:@{ @"favoriteColors": @"mutableFavoriteColors" }];
    
    NSDictionary *dictionary = @{ @"favoriteColors": @[ @"Blue", @"Red" ] };
    RKTestUser *user = [RKTestUser user];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    [operation performMapping:&error];
    
    assertThat(user.mutableFavoriteColors, is(equalTo(@[ @"Blue", @"Red" ])));
    assertThat(user.mutableFavoriteColors, is(instanceOf([NSMutableArray class])));
}

- (void)testMappingASingularValueToASet
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping addAttributeMappingsFromArray:@[ @"friendsSet" ]];
    
    NSDictionary *dictionary = @{ @"friendsSet": @"Jeff" };
    RKTestUser *user = [RKTestUser user];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    [operation performMapping:&error];
    
    assertThat(user.friendsSet, is(equalTo([NSSet setWithObject:@"Jeff" ])));
}

- (void)testMappingASingularValueToAnOrderedSet
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping addAttributeMappingsFromArray:@[ @"friendsOrderedSet" ]];
    
    NSDictionary *dictionary = @{ @"friendsOrderedSet": @"Jeff" };
    RKTestUser *user = [RKTestUser user];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    [operation performMapping:&error];
    
    assertThat(user.friendsOrderedSet, is(equalTo([NSOrderedSet orderedSetWithObject:@"Jeff" ])));
}

- (void)testTypeTransformationAtKeyPath
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *websiteMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"this.that" toKeyPath:@"address.addressID"];
    [mapping addPropertyMapping:websiteMapping];
    
    NSDictionary *dictionary = @{ @"this": @{ @"that": @"12345" }};
    RKTestUser *user = [RKTestUser user];
    RKTestAddress *address = [RKTestAddress new];
    user.address = address;
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    [operation performMapping:&error];
    
    assertThat(user.address.addressID, is(instanceOf([NSNumber class])));
    assertThat(user.address.addressID, is(equalTo(@(12345))));
}

- (void)testThatAttributeMappingToAPrimitiveValueFromNullDoesNotCrash
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping addAttributeMappingsFromArray:@[ @"age" ]];
    
    NSDictionary *dictionary = @{ @"age": [NSNull null] };
    RKTestUser *user = [RKTestUser user];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    [operation performMapping:&error];
    
    expect(user.age).to.equal(0);
}

- (void)testThatAttributeMappingToAPrimitiveValueFromUnexpectedObjectTypeDoesNotCrash
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping addAttributeMappingsFromArray:@[ @"age" ]];
    
    NSDictionary *dictionary = @{ @"age": @{ @"wrong": @"data" }};
    RKTestUser *user = [RKTestUser user];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    [operation performMapping:&error];
    
    expect(user.age).to.equal(0);
}

- (void)testThatMappingNullValueToTransformablePropertyDoesNotGenerateWarning
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [humanMapping addAttributeMappingsFromArray:@[ @"catIDs" ]];
    
    NSDictionary *dictionary = @{ @"catsIDs": [NSNull null] };
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:human mapping:humanMapping];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext cache:nil];
    operation.dataSource = dataSource;
    NSError *error = nil;
    [operation performMapping:&error];
    
    expect(human.catIDs).to.beNil();
}

#pragma mark - Relationship Mapping

- (void)testShouldMapANestedObject
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addPropertyMapping:nameMapping];
    RKObjectMapping *addressMapping = [RKObjectMapping mappingForClass:[RKTestAddress class]];
    RKAttributeMapping *cityMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"city" toKeyPath:@"city"];
    [addressMapping addPropertyMapping:cityMapping];

    RKRelationshipMapping *hasOneMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"address" toKeyPath:@"address" withMapping:addressMapping];
    [userMapping addPropertyMapping:hasOneMapping];

    RKMapperOperation *mapper = [RKMapperOperation new];
    mapper.mappingOperationDataSource = [RKObjectMappingOperationDataSource new];
    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKTestUser *user = [RKTestUser user];
    BOOL success = [mapper mapRepresentation:userInfo toObject:user isNew:YES atKeyPath:@"" usingMapping:userMapping metadataList:nil];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
    assertThat(user.address, isNot(nilValue()));
}

- (void)testShouldMapANestedObjectToCollection
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addPropertyMapping:nameMapping];
    RKObjectMapping *addressMapping = [RKObjectMapping mappingForClass:[RKTestAddress class]];
    RKAttributeMapping *cityMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"city" toKeyPath:@"city"];
    [addressMapping addPropertyMapping:cityMapping];

    RKRelationshipMapping *hasOneMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"address" toKeyPath:@"friends" withMapping:addressMapping];
    [userMapping addPropertyMapping:hasOneMapping];

    RKMapperOperation *mapper = [RKMapperOperation new];
    mapper.mappingOperationDataSource = [RKObjectMappingOperationDataSource new];
    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKTestUser *user = [RKTestUser user];
    BOOL success = [mapper mapRepresentation:userInfo toObject:user isNew:YES atKeyPath:@"" usingMapping:userMapping metadataList:nil];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
    assertThat(user.friends, isNot(nilValue()));
    assertThatUnsignedInteger([user.friends count], is(equalToInt(1)));
}

- (void)testShouldMapANestedObjectToOrderedSetCollection
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addPropertyMapping:nameMapping];
    RKObjectMapping *addressMapping = [RKObjectMapping mappingForClass:[RKTestAddress class]];
    RKAttributeMapping *cityMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"city" toKeyPath:@"city"];
    [addressMapping addPropertyMapping:cityMapping];

    RKRelationshipMapping *hasOneMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"address" toKeyPath:@"friendsOrderedSet" withMapping:addressMapping];
    [userMapping addPropertyMapping:hasOneMapping];

    RKMapperOperation *mapper = [RKMapperOperation new];
    mapper.mappingOperationDataSource = [RKObjectMappingOperationDataSource new];
    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKTestUser *user = [RKTestUser user];
    BOOL success = [mapper mapRepresentation:userInfo toObject:user isNew:YES atKeyPath:@"" usingMapping:userMapping metadataList:nil];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
    assertThat(user.friendsOrderedSet, isNot(nilValue()));
    assertThatUnsignedInteger([user.friendsOrderedSet count], is(equalToInt(1)));
}

- (void)testShouldMapANestedObjectCollection
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addPropertyMapping:nameMapping];

    RKRelationshipMapping *hasManyMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"friends" toKeyPath:@"friends" withMapping:userMapping];
    [userMapping addPropertyMapping:hasManyMapping];

    RKMapperOperation *mapper = [RKMapperOperation new];
    mapper.mappingOperationDataSource = [RKObjectMappingOperationDataSource new];
    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKTestUser *user = [RKTestUser user];
    BOOL success = [mapper mapRepresentation:userInfo toObject:user isNew:YES atKeyPath:@"" usingMapping:userMapping metadataList:nil];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
    assertThat(user.friends, isNot(nilValue()));
    assertThatUnsignedInteger([user.friends count], is(equalToInt(2)));
    NSArray *names = @[@"Jeremy Ellison", @"Rachit Shukla"];
    assertThat([user.friends valueForKey:@"name"], is(equalTo(names)));
}

- (void)testShouldMapANestedArrayIntoASet
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addPropertyMapping:nameMapping];

    RKRelationshipMapping *hasManyMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"friends" toKeyPath:@"friendsSet" withMapping:userMapping];
    [userMapping addPropertyMapping:hasManyMapping];

    RKMapperOperation *mapper = [RKMapperOperation new];
    mapper.mappingOperationDataSource = [RKObjectMappingOperationDataSource new];
    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKTestUser *user = [RKTestUser user];
    BOOL success = [mapper mapRepresentation:userInfo toObject:user isNew:YES atKeyPath:@"" usingMapping:userMapping metadataList:nil];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
    assertThat(user.friendsSet, isNot(nilValue()));
    assertThatBool([user.friendsSet isKindOfClass:[NSSet class]], is(equalToBool(YES)));
    assertThatUnsignedInteger([user.friendsSet count], is(equalToInt(2)));
    NSSet *names = [NSSet setWithObjects:@"Jeremy Ellison", @"Rachit Shukla", nil];
    assertThat([user.friendsSet valueForKey:@"name"], is(equalTo(names)));
}

- (void)testShouldMapANestedArrayIntoAnOrderedSet
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addPropertyMapping:nameMapping];

    RKRelationshipMapping *hasManyMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"friends" toKeyPath:@"friendsOrderedSet" withMapping:userMapping];
    [userMapping addPropertyMapping:hasManyMapping];

    RKMapperOperation *mapper = [RKMapperOperation new];
    mapper.mappingOperationDataSource = [RKObjectMappingOperationDataSource new];
    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKTestUser *user = [RKTestUser user];
    BOOL success = [mapper mapRepresentation:userInfo toObject:user isNew:YES atKeyPath:@"" usingMapping:userMapping metadataList:nil];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
    assertThat(user.friendsOrderedSet, isNot(nilValue()));
    assertThatBool([user.friendsOrderedSet isKindOfClass:[NSOrderedSet class]], is(equalToBool(YES)));
    assertThatUnsignedInteger([user.friendsOrderedSet count], is(equalToInt(2)));
    NSOrderedSet *names = [NSOrderedSet orderedSetWithObjects:@"Jeremy Ellison", @"Rachit Shukla", nil];
    assertThat([user.friendsOrderedSet valueForKey:@"name"], is(equalTo(names)));
}

- (void)testShouldNotSetThePropertyWhenTheNestedObjectIsIdentical
{
    RKTestUser *user = [RKTestUser user];
    RKTestAddress *address = [RKTestAddress address];
    address.addressID = @1234;
    user.address = address;
    id mockUser = [OCMockObject partialMockForObject:user];
    [[mockUser reject] setAddress:OCMOCK_ANY];

    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addPropertyMapping:nameMapping];
    RKObjectMapping *addressMapping = [RKObjectMapping mappingForClass:[RKTestAddress class]];
    RKAttributeMapping *idMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"addressID"];
    [addressMapping addPropertyMapping:idMapping];

    RKRelationshipMapping *hasOneMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"address" toKeyPath:@"address" withMapping:addressMapping];
    [userMapping addPropertyMapping:hasOneMapping];

    RKMapperOperation *mapper = [RKMapperOperation new];
    mapper.mappingOperationDataSource = [RKObjectMappingOperationDataSource new];
    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    [mapper mapRepresentation:userInfo toObject:user isNew:NO atKeyPath:@"" usingMapping:userMapping metadataList:nil];
}

- (void)testSkippingOfIdenticalObjectsInformsDelegate
{
    RKTestUser *user = [RKTestUser user];
    RKTestAddress *address = [RKTestAddress address];
    address.addressID = @1234;
    user.address = address;
    id mockUser = [OCMockObject partialMockForObject:user];
    [[mockUser reject] setAddress:OCMOCK_ANY];

    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addPropertyMapping:nameMapping];
    RKObjectMapping *addressMapping = [RKObjectMapping mappingForClass:[RKTestAddress class]];
    RKAttributeMapping *idMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"addressID"];
    [addressMapping addPropertyMapping:idMapping];

    RKRelationshipMapping *hasOneMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"address" toKeyPath:@"address" withMapping:addressMapping];
    [userMapping addPropertyMapping:hasOneMapping];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:userInfo destinationObject:user mapping:userMapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKMappingOperationDelegate)];
    [[[mockDelegate stub] andReturnValue:OCMOCK_VALUE(NO)] mappingOperation:operation shouldSetValue:OCMOCK_ANY forKeyPath:OCMOCK_ANY usingMapping:OCMOCK_ANY];
    [[mockDelegate expect] mappingOperation:operation didNotSetUnchangedValue:OCMOCK_ANY forKeyPath:@"address" usingMapping:hasOneMapping];
    operation.delegate = mockDelegate;
    [operation performMapping:nil];
    [mockDelegate verify];
}

- (void)testShouldNotSetThePropertyWhenTheNestedObjectCollectionIsIdentical
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *idMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"userID"];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addPropertyMapping:idMapping];
    [userMapping addPropertyMapping:nameMapping];

    RKRelationshipMapping *hasManyMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"friends" toKeyPath:@"friends" withMapping:userMapping];
    [userMapping addPropertyMapping:hasManyMapping];

    RKMapperOperation *mapper = [RKMapperOperation new];
    mapper.mappingOperationDataSource = [RKObjectMappingOperationDataSource new];
    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKTestUser *user = [RKTestUser user];

    // Set the friends up
    RKTestUser *jeremy = [RKTestUser user];
    jeremy.name = @"Jeremy Ellison";
    jeremy.userID = @187;
    RKTestUser *rachit = [RKTestUser user];
    rachit.name = @"Rachit Shukla";
    rachit.userID = @7;
    user.friends = @[jeremy, rachit];

    id mockUser = [OCMockObject partialMockForObject:user];
    [[mockUser reject] setFriends:OCMOCK_ANY];
    [mapper mapRepresentation:userInfo toObject:mockUser isNew:NO atKeyPath:@"" usingMapping:userMapping metadataList:nil];
    [mockUser verify];
}

- (void)testShouldOptionallyNilOutTheRelationshipIfItIsMissing
{
    RKTestUser *user = [RKTestUser user];
    RKTestAddress *address = [RKTestAddress address];
    address.addressID = @1234;
    user.address = address;
    id mockUser = [OCMockObject partialMockForObject:user];
    [[mockUser expect] setAddress:nil];

    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addPropertyMapping:nameMapping];
    RKObjectMapping *addressMapping = [RKObjectMapping mappingForClass:[RKTestAddress class]];
    RKAttributeMapping *idMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"addressID"];
    [addressMapping addPropertyMapping:idMapping];
    RKRelationshipMapping *relationshipMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"address" toKeyPath:@"address" withMapping:addressMapping];
    [userMapping addPropertyMapping:relationshipMapping];

    NSMutableDictionary *dictionary = [[RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    [dictionary removeObjectForKey:@"address"];
    id mockMapping = [OCMockObject partialMockForObject:userMapping];
    [[[mockMapping expect] andReturnValue:@YES] assignsNilForMissingRelationships];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:mockUser mapping:mockMapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    
    NSError *error = nil;
    [operation performMapping:&error];
    [mockUser verify];
}

- (void)testShouldNotNilOutTheRelationshipIfItIsMissingAndCurrentlyNilOnTheTargetObject
{
    RKTestUser *user = [RKTestUser user];
    user.address = nil;
    id mockUser = [OCMockObject partialMockForObject:user];
    [[mockUser reject] setAddress:nil];

    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addPropertyMapping:nameMapping];
    RKObjectMapping *addressMapping = [RKObjectMapping mappingForClass:[RKTestAddress class]];
    RKAttributeMapping *idMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"addressID"];
    [addressMapping addPropertyMapping:idMapping];
    RKRelationshipMapping *relationshipMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"address" toKeyPath:@"address" withMapping:addressMapping];
    [userMapping addPropertyMapping:relationshipMapping];

    NSMutableDictionary *dictionary = [[RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    [dictionary removeObjectForKey:@"address"];
    id mockMapping = [OCMockObject partialMockForObject:userMapping];
    [[[mockMapping expect] andReturnValue:@YES] setNilForMissingRelationships];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:mockUser mapping:mockMapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;

    NSError *error = nil;
    [operation performMapping:&error];
    [mockUser verify];
}

#pragma mark Assignment Policies

- (void)testThatAttemptingToUnionOneToOneRelationshipGeneratesMappingError
{
    RKTestUser *user = [RKTestUser new];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectMapping *addressMapping = [RKObjectMapping mappingForClass:[RKTestAddress class]];
    [mapping addAttributeMappingsFromArray:@[ @"name" ]];
    RKRelationshipMapping *relationshipMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"address" toKeyPath:@"address" withMapping:addressMapping];
    relationshipMapping.assignmentPolicy = RKUnionAssignmentPolicy;
    [mapping addPropertyMapping:relationshipMapping];
    
    NSDictionary *dictionary = @{ @"address": @{ @"city": @"NYC" } };
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    
    NSError *error = nil;
    [operation performMapping:&error];
    expect(error).notTo.beNil();
    expect(error.code).to.equal(RKMappingErrorInvalidAssignmentPolicy);
    expect([error localizedDescription]).to.equal(@"Invalid assignment policy: cannot union a one-to-one relationship.");
}

- (void)testUnionAssignmentPolicyWithSet
{
    RKTestUser *user = [RKTestUser new];
    RKTestUser *friend = [RKTestUser new];
    friend.name = @"Jeff";
    user.friendsSet = [NSSet setWithObject:friend];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping addAttributeMappingsFromArray:@[ @"name" ]];
    RKRelationshipMapping *relationshipMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"friendsSet" toKeyPath:@"friendsSet" withMapping:mapping];
    relationshipMapping.assignmentPolicy = RKUnionAssignmentPolicy;
    [mapping addPropertyMapping:relationshipMapping];
    
    NSDictionary *dictionary = @{ @"friendsSet": @[ @{ @"name": @"Zach" } ] };
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    
    NSError *error = nil;
    [operation performMapping:&error];
    expect([user.friendsSet count]).to.equal(2);
    NSArray *names = [user.friendsSet valueForKey:@"name"];
    assertThat(names, hasItems(@"Jeff", @"Zach", nil));
}

- (void)testUnionAssignmentPolicyWithOrderedSet
{
    RKTestUser *user = [RKTestUser new];
    RKTestUser *friend = [RKTestUser new];
    friend.name = @"Jeff";
    user.friendsOrderedSet = [NSOrderedSet orderedSetWithObject:friend];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping addAttributeMappingsFromArray:@[ @"name" ]];
    RKRelationshipMapping *relationshipMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"friendsOrderedSet" toKeyPath:@"friendsOrderedSet" withMapping:mapping];
    relationshipMapping.assignmentPolicy = RKUnionAssignmentPolicy;
    [mapping addPropertyMapping:relationshipMapping];
    
    NSDictionary *dictionary = @{ @"friendsOrderedSet": @[ @{ @"name": @"Zach" } ] };
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    
    NSError *error = nil;
    [operation performMapping:&error];
    expect([user.friendsOrderedSet count]).to.equal(2);
    NSArray *names = [user.friendsOrderedSet valueForKey:@"name"];
    assertThat(names, hasItems(@"Jeff", @"Zach", nil));
}

- (void)testUnionAssignmentPolicyWithArray
{
    RKTestUser *user = [RKTestUser new];
    RKTestUser *friend = [RKTestUser new];
    friend.name = @"Jeff";
    user.friends = @[friend];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping addAttributeMappingsFromArray:@[ @"name" ]];
    RKRelationshipMapping *relationshipMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"friends" toKeyPath:@"friends" withMapping:mapping];
    relationshipMapping.assignmentPolicy = RKUnionAssignmentPolicy;
    [mapping addPropertyMapping:relationshipMapping];
    
    NSDictionary *dictionary = @{ @"friends": @[ @{ @"name": @"Zach" } ] };
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    
    NSError *error = nil;
    [operation performMapping:&error];
    expect([user.friends count]).to.equal(2);
    NSArray *names = [user.friends valueForKey:@"name"];
    assertThat(names, hasItems(@"Jeff", @"Zach", nil));
}

- (void)testUnionAssignmentPolicyWithNilValue
{
    RKTestUser *user = [RKTestUser new];
    user.friends = nil;
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping addAttributeMappingsFromArray:@[ @"name" ]];
    RKRelationshipMapping *relationshipMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"friends" toKeyPath:@"friends" withMapping:mapping];
    relationshipMapping.assignmentPolicy = RKUnionAssignmentPolicy;
    [mapping addPropertyMapping:relationshipMapping];
    
    NSDictionary *dictionary = @{ @"friends": @[ @{ @"name": @"Zach" } ] };
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    
    NSError *error = nil;
    [operation performMapping:&error];
    expect([user.friends count]).to.equal(1);
    NSArray *names = [user.friends valueForKey:@"name"];
    assertThat(names, hasItems(@"Zach", nil));
}

- (void)testReplacementPolicyForUnmanagedRelationship
{
    RKTestUser *user = [RKTestUser new];
    RKTestUser *friend = [RKTestUser new];
    friend.name = @"Jeff";
    user.friends = @[friend];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping addAttributeMappingsFromArray:@[ @"name" ]];
    RKRelationshipMapping *relationshipMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"friends" toKeyPath:@"friends" withMapping:mapping];
    relationshipMapping.assignmentPolicy = RKReplaceAssignmentPolicy;
    [mapping addPropertyMapping:relationshipMapping];
    
    NSDictionary *dictionary = @{ @"friends": @[ @{ @"name": @"Zach" } ] };
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    
    NSError *error = nil;
    [operation performMapping:&error];
    expect([user.friends count]).to.equal(1);
    NSArray *names = [user.friends valueForKey:@"name"];
    assertThat(names, hasItems(@"Zach", nil));
}

- (void)testReplacmentPolicyForToManyCoreDataRelationshipDeletesExistingValues
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    RKCat *existingCat = [NSEntityDescription insertNewObjectForEntityForName:@"Cat" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    existingCat.name = @"Lola";
    human.cats = [NSSet setWithObject:existingCat];
    
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [entityMapping addAttributeMappingsFromArray:@[ @"name" ]];
    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"Cat" inManagedObjectStore:managedObjectStore];
    [catMapping addAttributeMappingsFromArray:@[ @"name" ]];
    catMapping.identificationAttributes = @[ @"name" ];
    RKRelationshipMapping *relationshipMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"cats" toKeyPath:@"cats" withMapping:catMapping];
    relationshipMapping.assignmentPolicy = RKReplaceAssignmentPolicy;
    [entityMapping addPropertyMapping:relationshipMapping];
    
    NSDictionary *dictionary = @{ @"name": @"Blake", @"cats": @[ @{ @"name": @"Roy" } ] };
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:human mapping:entityMapping];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext cache:nil];
    operation.dataSource = dataSource;
    
    NSError *error = nil;
    [operation performMapping:&error];
    expect([human.cats count]).to.equal(1);
    NSArray *names = [human.cats valueForKey:@"name"];
    assertThat(names, hasItems(@"Roy", nil));
    expect([existingCat isDeleted]).to.equal(YES);
}

- (void)testReplacmentPolicyForToManyCoreDataRelationshipDoesNotDeleteNewValuesOnSecondMapping
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [entityMapping addAttributeMappingsFromArray:@[ @"name" ]];
    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"Cat" inManagedObjectStore:managedObjectStore];
    [catMapping addAttributeMappingsFromArray:@[ @"name" ]];
    RKRelationshipMapping *relationshipMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"cats" toKeyPath:@"cats" withMapping:catMapping];
    relationshipMapping.assignmentPolicy = RKReplaceAssignmentPolicy;
    [entityMapping addPropertyMapping:relationshipMapping];
    
    NSError *error = nil;
    NSDictionary *dictionary = @{ @"name": @"Blake", @"cats": @[ @{ @"name": @"Roy" } ] };
    
    RKMappingOperation *firstOperation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:human mapping:entityMapping];
    RKManagedObjectMappingOperationDataSource *firstDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext cache:nil];
    firstOperation.dataSource = firstDataSource;
    
    [firstOperation performMapping:&error];
    [human.managedObjectContext save:&error];
    
    expect([human.cats count]).to.equal(1);
    NSArray *firstCatNames = [human.cats valueForKey:@"name"];
    assertThat(firstCatNames, hasItems(@"Roy", nil));
    
    RKMappingOperation *secondOperation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:human mapping:entityMapping];
    RKManagedObjectMappingOperationDataSource *secondDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext cache:nil];
    secondOperation.dataSource = secondDataSource;
    
    [secondOperation performMapping:&error];
    [human.managedObjectContext save:&error];
    
    expect([human.cats count]).to.equal(1);
    NSArray *secondCatNames = [human.cats valueForKey:@"name"];
    assertThat(secondCatNames, hasItems(@"Roy", nil));
}

- (void)testReplacmentPolicyForToOneCoreDataRelationshipDeletesExistingValues
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    RKCat *existingCat = [NSEntityDescription insertNewObjectForEntityForName:@"Cat" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    existingCat.name = @"Lola";
    human.favoriteCat = existingCat;
    
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [entityMapping addAttributeMappingsFromArray:@[ @"name" ]];
    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"Cat" inManagedObjectStore:managedObjectStore];
    [catMapping addAttributeMappingsFromArray:@[ @"name" ]];
    catMapping.identificationAttributes = @[ @"name" ];
    RKRelationshipMapping *relationshipMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"favoriteCat" toKeyPath:@"favoriteCat" withMapping:catMapping];
    relationshipMapping.assignmentPolicy = RKReplaceAssignmentPolicy;
    [entityMapping addPropertyMapping:relationshipMapping];
    
    NSDictionary *dictionary = @{ @"name": @"Blake", @"favoriteCat": @{ @"name": @"Roy" } };
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:human mapping:entityMapping];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext cache:nil];
    operation.dataSource = dataSource;
    
    NSError *error = nil;
    [operation performMapping:&error];
    expect(human.favoriteCat.name).to.equal(@"Roy");
    expect([existingCat isDeleted]).to.equal(YES);
}

- (void)testReplacmentPolicyForToOneCoreDataRelationshipDeletesExistingValuesAndRespectsAssignsNilForMissingRelationships
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    RKCat *existingCat = [NSEntityDescription insertNewObjectForEntityForName:@"Cat" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    existingCat.name = @"Lola";
    human.favoriteCat = existingCat;

    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    entityMapping.assignsNilForMissingRelationships = YES;
    [entityMapping addAttributeMappingsFromArray:@[ @"name" ]];
    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"Cat" inManagedObjectStore:managedObjectStore];
    [catMapping addAttributeMappingsFromArray:@[ @"name" ]];
    catMapping.identificationAttributes = @[ @"name" ];
    RKRelationshipMapping *relationshipMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"favoriteCat" toKeyPath:@"favoriteCat" withMapping:catMapping];
    relationshipMapping.assignmentPolicy = RKReplaceAssignmentPolicy;
    [entityMapping addPropertyMapping:relationshipMapping];

    NSDictionary *dictionary = @{ @"name": @"Blake" };
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:human mapping:entityMapping];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext cache:nil];
    operation.dataSource = dataSource;

    NSError *error = nil;
    [operation performMapping:&error];
    expect(human.favoriteCat).to.beNil();
    expect([existingCat isDeleted]).to.equal(YES);
}

// NOTE: Using `assignsNilForMissingRelationships` with `RKAssignmentPolicyUnion` is functionally a no-op and leaves the existing values alone
- (void)testUnionAssignmentPolicyForToManyCoreDataRelationshipDeletesExistingValuesWithAssignsNilForMissingRelationships
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    RKCat *existingCat = [NSEntityDescription insertNewObjectForEntityForName:@"Cat" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    existingCat.name = @"Lola";
    human.cats = [NSSet setWithObject:existingCat];

    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    entityMapping.assignsNilForMissingRelationships = YES;
    [entityMapping addAttributeMappingsFromArray:@[ @"name" ]];
    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"Cat" inManagedObjectStore:managedObjectStore];
    [catMapping addAttributeMappingsFromArray:@[ @"name" ]];
    catMapping.identificationAttributes = @[ @"name" ];
    RKRelationshipMapping *relationshipMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"cats" toKeyPath:@"cats" withMapping:catMapping];
    relationshipMapping.assignmentPolicy = RKAssignmentPolicyUnion;
    [entityMapping addPropertyMapping:relationshipMapping];

    // No cats in the dictionary
    NSDictionary *dictionary = @{ @"name": @"Blake" };
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:human mapping:entityMapping];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext cache:nil];
    operation.dataSource = dataSource;

    NSError *error = nil;
    [operation performMapping:&error];
    expect([human.cats count]).to.equal(1);
    NSArray *names = [human.cats valueForKey:@"name"];
    assertThat(names, hasItems(@"Lola", nil));
    expect([existingCat isDeleted]).to.equal(NO);
}

#pragma mark - RKDynamicMapping

- (void)testShouldMapASingleObjectDynamically
{
    RKObjectMapping *boyMapping = [RKObjectMapping mappingForClass:[Boy class]];
    [boyMapping addAttributeMappingsFromArray:@[@"name"]];
    RKObjectMapping *girlMapping = [RKObjectMapping mappingForClass:[Girl class]];
    [girlMapping addAttributeMappingsFromArray:@[@"name"]];
    RKDynamicMapping *dynamicMapping = [RKDynamicMapping new];
    [dynamicMapping setObjectMappingForRepresentationBlock:^RKObjectMapping *(id representation) {
        if ([[representation valueForKey:@"type"] isEqualToString:@"Boy"]) {
            return boyMapping;
        } else if ([[representation valueForKey:@"type"] isEqualToString:@"Girl"]) {
            return girlMapping;
        }

        return nil;
    }];

    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    mappingsDictionary[[NSNull null]] = dynamicMapping;

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"boy.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:userInfo mappingsDictionary:mappingsDictionary];
    [mapper start];
    Boy *user = [mapper.mappingResult firstObject];
    assertThat(user, is(instanceOf([Boy class])));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
}

- (void)testShouldMapASingleObjectDynamicallyWithADeclarativeMatcher
{
    RKObjectMapping *boyMapping = [RKObjectMapping mappingForClass:[Boy class]];
    [boyMapping addAttributeMappingsFromArray:@[@"name"]];
    RKObjectMapping *girlMapping = [RKObjectMapping mappingForClass:[Girl class]];
    [girlMapping addAttributeMappingsFromArray:@[@"name"]];
    RKDynamicMapping *dynamicMapping = [RKDynamicMapping new];
    [dynamicMapping addMatcher:[RKObjectMappingMatcher matcherWithKeyPath:@"type" expectedValue:@"Boy" objectMapping:boyMapping]];
    [dynamicMapping addMatcher:[RKObjectMappingMatcher matcherWithKeyPath:@"type" expectedValue:@"Girl" objectMapping:girlMapping]];

    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    mappingsDictionary[[NSNull null]] = dynamicMapping;

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"boy.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:userInfo mappingsDictionary:mappingsDictionary];
    [mapper start];
    Boy *user = [mapper.mappingResult firstObject];
    assertThat(user, is(instanceOf([Boy class])));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
}

- (void)testShouldACollectionOfObjectsDynamically
{
    RKObjectMapping *boyMapping = [RKObjectMapping mappingForClass:[Boy class]];
    [boyMapping addAttributeMappingsFromArray:@[@"name"]];
    RKObjectMapping *girlMapping = [RKObjectMapping mappingForClass:[Girl class]];
    [girlMapping addAttributeMappingsFromArray:@[@"name"]];
    RKDynamicMapping *dynamicMapping = [RKDynamicMapping new];
    [dynamicMapping addMatcher:[RKObjectMappingMatcher matcherWithKeyPath:@"type" expectedValue:@"Boy" objectMapping:boyMapping]];
    [dynamicMapping addMatcher:[RKObjectMappingMatcher matcherWithKeyPath:@"type" expectedValue:@"Girl" objectMapping:girlMapping]];

    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    mappingsDictionary[[NSNull null]] = dynamicMapping;

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"mixed.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:userInfo mappingsDictionary:mappingsDictionary];
    [mapper start];
    NSArray *objects = [mapper.mappingResult array];
    expect(objects).to.haveCountOf(2);
    expect(objects[0]).to.beInstanceOf([Boy class]);
    expect(objects[1]).to.beInstanceOf([Girl class]);
    Boy *boy = objects[0];
    Girl *girl = objects[1];
    expect(boy.name).to.equal(@"Blake Watters");
    expect(girl.name).to.equal(@"Sarah");
}

- (void)testShouldMapARelationshipDynamically
{
    RKObjectMapping *boyMapping = [RKObjectMapping mappingForClass:[Boy class]];
    [boyMapping addAttributeMappingsFromArray:@[@"name"]];
    RKObjectMapping *girlMapping = [RKObjectMapping mappingForClass:[Girl class]];
    [girlMapping addAttributeMappingsFromArray:@[@"name"]];
    RKDynamicMapping *dynamicMapping = [RKDynamicMapping new];
    [dynamicMapping addMatcher:[RKObjectMappingMatcher matcherWithKeyPath:@"type" expectedValue:@"Boy" objectMapping:boyMapping]];
    [dynamicMapping addMatcher:[RKObjectMappingMatcher matcherWithKeyPath:@"type" expectedValue:@"Girl" objectMapping:girlMapping]];
    [boyMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"friends" toKeyPath:@"friends" withMapping:dynamicMapping]];;

    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    mappingsDictionary[[NSNull null]] = dynamicMapping;

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"friends.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:userInfo mappingsDictionary:mappingsDictionary];
    [mapper start];
    Boy *blake = [mapper.mappingResult firstObject];
    NSArray *friends = blake.friends;

    assertThat(friends, hasCountOf(2));
    assertThat(friends[0], is(instanceOf([Boy class])));
    assertThat(friends[1], is(instanceOf([Girl class])));
    Boy *boy = friends[0];
    Girl *girl = friends[1];
    assertThat(boy.name, is(equalTo(@"John Doe")));
    assertThat(girl.name, is(equalTo(@"Jane Doe")));
}

- (void)testShouldBeAbleToDeclineMappingAnObjectByReturningANilObjectMapping
{
    RKObjectMapping *boyMapping = [RKObjectMapping mappingForClass:[Boy class]];
    [boyMapping addAttributeMappingsFromArray:@[@"name"]];
    RKObjectMapping *girlMapping = [RKObjectMapping mappingForClass:[Girl class]];
    [girlMapping addAttributeMappingsFromArray:@[@"name"]];
    RKDynamicMapping *dynamicMapping = [RKDynamicMapping new];
    [dynamicMapping setObjectMappingForRepresentationBlock:^RKObjectMapping *(id representation) {
        if ([[representation valueForKey:@"type"] isEqualToString:@"Boy"]) {
            return boyMapping;
        } else if ([[representation valueForKey:@"type"] isEqualToString:@"Girl"]) {
            // NO GIRLS ALLOWED(*$!)(*
            return nil;
        }

        return nil;
    }];

    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    mappingsDictionary[[NSNull null]] = dynamicMapping;

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"mixed.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:userInfo mappingsDictionary:mappingsDictionary];
    [mapper start];
    NSArray *boys = [mapper.mappingResult array];
    assertThat(boys, hasCountOf(1));
    Boy *user = boys[0];
    assertThat(user, is(instanceOf([Boy class])));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
}

- (void)testShouldBeAbleToDeclineMappingObjectsInARelationshipByReturningANilObjectMapping
{
    RKObjectMapping *boyMapping = [RKObjectMapping mappingForClass:[Boy class]];
    [boyMapping addAttributeMappingsFromArray:@[@"name"]];
    RKObjectMapping *girlMapping = [RKObjectMapping mappingForClass:[Girl class]];
    [girlMapping addAttributeMappingsFromArray:@[@"name"]];
    RKDynamicMapping *dynamicMapping = [RKDynamicMapping new];
    [dynamicMapping setObjectMappingForRepresentationBlock:^RKObjectMapping *(id representation) {
        if ([[representation valueForKey:@"type"] isEqualToString:@"Boy"]) {
            return boyMapping;
        } else if ([[representation valueForKey:@"type"] isEqualToString:@"Girl"]) {
            // NO GIRLS ALLOWED(*$!)(*
            return nil;
        }

        return nil;
    }];
    [boyMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"friends" toKeyPath:@"friends" withMapping:dynamicMapping]];;

    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    mappingsDictionary[[NSNull null]] = dynamicMapping;

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"friends.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:userInfo mappingsDictionary:mappingsDictionary];
    [mapper start];
    Boy *blake = [mapper.mappingResult firstObject];
    assertThat(blake, is(notNilValue()));
    assertThat(blake.name, is(equalTo(@"Blake Watters")));
    assertThat(blake, is(instanceOf([Boy class])));
    NSArray *friends = blake.friends;

    assertThat(friends, hasCountOf(1));
    assertThat(friends[0], is(instanceOf([Boy class])));
    Boy *boy = friends[0];
    assertThat(boy.name, is(equalTo(@"John Doe")));
}

- (void)testShouldMapATargetObjectWithADynamicMapping
{
    RKObjectMapping *boyMapping = [RKObjectMapping mappingForClass:[Boy class]];
    [boyMapping addAttributeMappingsFromArray:@[@"name"]];
    RKDynamicMapping *dynamicMapping = [RKDynamicMapping new];
    [dynamicMapping setObjectMappingForRepresentationBlock:^RKObjectMapping *(id representation) {
        if ([[representation valueForKey:@"type"] isEqualToString:@"Boy"]) {
            return boyMapping;
        }

        return nil;
    }];

    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    mappingsDictionary[[NSNull null]] = dynamicMapping;

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"boy.json"];
    Boy *blake = [Boy new];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:userInfo mappingsDictionary:mappingsDictionary];
    mapper.targetObject = blake;
    [mapper start];
    Boy *user = [mapper.mappingResult firstObject];
    assertThat(user, is(instanceOf([Boy class])));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
}

- (void)testShouldFailWithAnErrorIfATargetObjectIsProvidedAndTheDynamicMappingReturnsNil
{
    RKObjectMapping *boyMapping = [RKObjectMapping mappingForClass:[Boy class]];
    [boyMapping addAttributeMappingsFromArray:@[@"name"]];
    RKDynamicMapping *dynamicMapping = [RKDynamicMapping new];
    [dynamicMapping setObjectMappingForRepresentationBlock:^RKObjectMapping *(id representation) {
        return nil;
    }];

    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    mappingsDictionary[[NSNull null]] = dynamicMapping;

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"boy.json"];
    Boy *blake = [Boy new];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:userInfo mappingsDictionary:mappingsDictionary];
    mapper.targetObject = blake;
    [mapper start];
    Boy *user = [mapper.mappingResult firstObject];
    assertThat(user, is(nilValue()));
    assertThat(mapper.error, is(notNilValue()));
}

- (void)testShouldFailWithAnErrorIfATargetObjectIsProvidedAndTheDynamicMappingReturnsTheIncorrectType
{
    RKObjectMapping *girlMapping = [RKObjectMapping mappingForClass:[Girl class]];
    [girlMapping addAttributeMappingsFromArray:@[@"name"]];
    RKDynamicMapping *dynamicMapping = [RKDynamicMapping new];
    [dynamicMapping setObjectMappingForRepresentationBlock:^RKObjectMapping *(id representation) {
        if ([[representation valueForKey:@"type"] isEqualToString:@"Girl"]) {
            return girlMapping;
        }

        return nil;
    }];

    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    mappingsDictionary[[NSNull null]] = dynamicMapping;

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"girl.json"];
    Boy *blake = [Boy new];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:userInfo mappingsDictionary:mappingsDictionary];
    mapper.targetObject = blake;
    [mapper start];
    Boy *user = [mapper.mappingResult firstObject];
    assertThat(user, is(nilValue()));
    assertThat(mapper.error, is(notNilValue()));
}

#pragma mark - Date and Time Formatting

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

- (void)testShouldAutoConfigureDefaultDateFormatters
{
    NSArray *dateFormatters = [RKObjectMapping defaultDateFormatters];
    expect(dateFormatters).to.haveCountOf(6);
    expect([dateFormatters[2] dateFormat]).to.equal(@"yyyy-MM-dd");
    expect([dateFormatters[1] dateFormat]).to.equal(@"MM/dd/yyyy");

    NSTimeZone *UTCTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    expect([dateFormatters[1] timeZone]).to.equal(UTCTimeZone);
    expect([dateFormatters[2] timeZone]).to.equal(UTCTimeZone);
}

- (void)testShouldLetYouSetTheDefaultDateFormatters
{
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    NSArray *dateFormatters = @[dateFormatter];
    [RKObjectMapping setDefaultDateFormatters:dateFormatters];
    assertThat([RKObjectMapping defaultDateFormatters], is(equalTo(dateFormatters)));
}

- (void)testShouldLetYouAppendADateFormatterToTheList
{
    assertThat([RKObjectMapping defaultDateFormatters], hasCountOf(6));
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [RKObjectMapping addDefaultDateFormatter:dateFormatter];
    assertThat([RKObjectMapping defaultDateFormatters], hasCountOf(7));
}

- (void)testShouldAllowNewlyAddedDateFormatterToRunFirst
{
    [RKObjectMapping setDefaultDateFormatters:nil];
    NSDateFormatter *newDateFormatter = [NSDateFormatter new];
    [newDateFormatter setDateFormat:@"dd/MM/yyyy"];
    [RKObjectMapping addDefaultDateFormatter:newDateFormatter];

    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *birthDateMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"favorite_date" toKeyPath:@"favoriteDate"];
    [mapping addPropertyMapping:birthDateMapping];

    NSDictionary *dictionary = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKTestUser *user = [RKTestUser user];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    [operation performMapping:&error];

    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];

    /*
     If RKObjectMappingOperation is using the date formatter set above, we're
     going to get a really wonky date, which is what we are testing for.
     */
    assertThat([dateFormatter stringFromDate:user.favoriteDate], is(equalTo(@"01/03/2012")));
}

- (void)testShouldLetYouConfigureANewDateFormatterFromAStringAndATimeZone
{
    assertThat([RKObjectMapping defaultDateFormatters], hasCountOf(6));
    NSTimeZone *EDTTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"EDT"];
    [RKObjectMapping addDefaultDateFormatterForString:@"mm/dd/YYYY" inTimeZone:EDTTimeZone];
    assertThat([RKObjectMapping defaultDateFormatters], hasCountOf(7));
    NSDateFormatter *dateFormatter = [RKObjectMapping defaultDateFormatters][0];
    assertThat(dateFormatter.timeZone, is(equalTo(EDTTimeZone)));
}

- (void)testShouldReturnNilForEmptyDateValues
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *birthDateMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"birthdate" toKeyPath:@"birthDate"];
    [mapping addPropertyMapping:birthDateMapping];

    NSDictionary *dictionary = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    NSMutableDictionary *mutableDictionary = [dictionary mutableCopy];
    [mutableDictionary setValue:@"" forKey:@"birthdate"];
    RKTestUser *user = [RKTestUser user];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:mutableDictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    [operation performMapping:&error];

    assertThat(user.birthDate, is(equalTo(nil)));
}

- (void)testShouldConfigureANewDateFormatterInTheUTCTimeZoneIfPassedANilTimeZone
{
    assertThat([RKObjectMapping defaultDateFormatters], hasCountOf(6));
    [RKObjectMapping addDefaultDateFormatterForString:@"mm/dd/YYYY" inTimeZone:nil];
    assertThat([RKObjectMapping defaultDateFormatters], hasCountOf(7));
    NSDateFormatter *dateFormatter = [RKObjectMapping defaultDateFormatters][0];
    NSTimeZone *UTCTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    assertThat(dateFormatter.timeZone, is(equalTo(UTCTimeZone)));
}

- (void)testShouldEnsureRailsDatesAreParsedInUTCTimeZone
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *birthDateMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"birthdate" toKeyPath:@"birthDate"];
    [mapping addPropertyMapping:birthDateMapping];

    NSDictionary *dictionary = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    NSMutableDictionary *mutableDictionary = [dictionary mutableCopy];
    [mutableDictionary setValue:@"2012-03-01" forKey:@"birthdate"];
    RKTestUser *user = [RKTestUser user];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:mutableDictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    [operation performMapping:&error];

    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.year = 2012;
    components.month = 3;
    components.day = 1;
    components.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDate *date = [calendar dateFromComponents:components];

    expect(user.birthDate).to.equal(date);
}

#pragma clang diagnostic pop

#pragma mark - Misc

- (void)testUpdatingArrayOfExistingCats
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSArray *array = [RKTestFixture parsedObjectWithContentsOfFixture:@"ArrayOfHumans.json"];
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [humanMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"railsID"]];
    humanMapping.identificationAttributes = @[ @"railsID" ];
    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    mappingsDictionary[@"human"] = humanMapping;

    // Create instances that should match the fixture
    RKHuman *human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    human1.railsID = @201;
    RKHuman *human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    human2.railsID = @202;
    [managedObjectStore.persistentStoreManagedObjectContext save:nil];

    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:array mappingsDictionary:mappingsDictionary];
    RKFetchRequestManagedObjectCache *managedObjectCache = [[RKFetchRequestManagedObjectCache alloc] init];
    mapper.mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                  cache:managedObjectCache];
                                                                                                                  
    [mapper start];
    RKMappingResult *result = mapper.mappingResult;
    assertThat(result, is(notNilValue()));

    NSArray *humans = [result array];
    assertThat(humans, hasCountOf(2));
    assertThat(humans[0], is(equalTo(human1)));
    assertThat(humans[1], is(equalTo(human2)));
}

- (void)testMappingMultipleKeyPathsAtRootOfObject
{
    RKObjectMapping *mapping1 = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping1 addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"prodId" toKeyPath:@"userID"]];
    
    RKObjectMapping *mapping2 = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping2 addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"catId" toKeyPath:@"userID"]];
    
    NSDictionary *dictionary = [RKTestFixture parsedObjectWithContentsOfFixture:@"SameKeyDifferentTargetClasses.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithRepresentation:dictionary mappingsDictionary:@{ @"products": mapping1, @"categories": mapping2 }];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    mapper.mappingOperationDataSource = dataSource;
    [mapper start];
    
    expect(mapper.error).to.beNil();
    expect(mapper.mappingResult).notTo.beNil();
    expect([mapper.mappingResult array]).to.haveCountOf(4);
}

- (void)testAggregatingPropertyMappingUsingNilKeyPath
{
    NSDictionary *objectRepresentation = @{ @"name": @"Blake", @"latitude": @(125.55), @"longitude": @(200.5) };
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [userMapping addAttributeMappingsFromArray:@[ @"name" ]];
    RKObjectMapping *coordinateMapping = [RKObjectMapping mappingForClass:[RKTestCoordinate class]];
    [coordinateMapping addAttributeMappingsFromArray:@[ @"latitude", @"longitude" ]];
    [userMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:nil toKeyPath:@"coordinate" withMapping:coordinateMapping]];
    RKTestUser *user = [RKTestUser new];
    RKMappingOperation *mappingOperation = [[RKMappingOperation alloc] initWithSourceObject:objectRepresentation destinationObject:user mapping:userMapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    mappingOperation.dataSource = dataSource;
    [mappingOperation start];
    expect(mappingOperation.error).to.beNil();
    expect(user.coordinate).notTo.beNil();
    expect(user.coordinate.latitude).to.equal(125.55);
    expect(user.coordinate.longitude).to.equal(200.5);
}

- (void)testMappingDictionaryToCLLocationUsingValueTransformer
{
    NSDictionary *objectRepresentation = @{ @"name": @"Blake", @"latitude": @(125.55), @"longitude": @(200.5) };
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [userMapping addAttributeMappingsFromArray:@[ @"name" ]];
    RKAttributeMapping *attributeMapping = [RKAttributeMapping attributeMappingFromKeyPath:nil toKeyPath:@"location"];
    attributeMapping.valueTransformer = [RKCLLocationValueTransformer locationValueTransformerWithLatitudeKey:@"latitude" longitudeKey:@"longitude"];
    [userMapping addPropertyMapping:attributeMapping];
    RKTestUser *user = [RKTestUser new];
    RKMappingOperation *mappingOperation = [[RKMappingOperation alloc] initWithSourceObject:objectRepresentation destinationObject:user mapping:userMapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    mappingOperation.dataSource = dataSource;
    [mappingOperation start];
    expect(mappingOperation.error).to.beNil();
    expect(user.location).notTo.beNil();
    expect(user.location.coordinate.latitude).to.equal(125.55);
    expect(user.location.coordinate.longitude).to.equal(200.5);
}

- (void)testThatAggregatedRelationshipMappingsAreOnlyAppliedIfThereIsAtLeastOneValueInTheRepresentation
{
    NSDictionary *objectRepresentation = @{ @"name": @"Blake" };
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [userMapping addAttributeMappingsFromArray:@[ @"name" ]];
    RKObjectMapping *coordinateMapping = [RKObjectMapping mappingForClass:[RKTestCoordinate class]];
    [coordinateMapping addAttributeMappingsFromArray:@[ @"latitude", @"longitude" ]];
    [userMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:nil toKeyPath:@"coordinate" withMapping:coordinateMapping]];
    RKTestUser *user = [RKTestUser new];
    RKMappingOperation *mappingOperation = [[RKMappingOperation alloc] initWithSourceObject:objectRepresentation destinationObject:user mapping:userMapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    mappingOperation.dataSource = dataSource;
    [mappingOperation start];
    expect(mappingOperation.error).to.beNil();
    expect(user.coordinate).to.beNil();
}

#pragma mark - Metadata Mapping

- (void)testMappingURLFromMetadata
{
    NSDictionary *objectRepresentation = @{ @"name": @"Blake Watters" };
    NSDictionary *metadata = @{ @"HTTP": @{ @"request": @{ @"URL": [NSURL URLWithString:@"http://restkit.org/"] } } };
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [userMapping addAttributeMappingsFromDictionary:@{ @"name": @"name", @"@metadata.HTTP.request.URL": @"website" }];
    RKTestUser *user = [RKTestUser new];
    RKMappingOperation *mappingOperation = [[RKMappingOperation alloc] initWithSourceObject:objectRepresentation destinationObject:user mapping:userMapping metadataList:@[metadata]];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    mappingOperation.dataSource = dataSource;
    [mappingOperation start];
    expect(mappingOperation.error).to.beNil();
    expect(user.name).to.equal(@"Blake Watters");
    expect([user.website absoluteString]).to.equal(@"http://restkit.org/");
}

- (void)testMappingHeadersFromMetadata
{
    NSDictionary *objectRepresentation = @{ @"name": @"Blake Watters" };
    NSDictionary *metadata = @{ @"HTTP": @{ @"request": @{ @"headers": @{ @"Content-Type": @"text/html; charset=UTF-8" } } } };
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [userMapping addAttributeMappingsFromDictionary:@{ @"name": @"name", @"@metadata.HTTP.request.headers.Content-Type": @"emailAddress" }];
    RKTestUser *user = [RKTestUser new];
    RKMappingOperation *mappingOperation = [[RKMappingOperation alloc] initWithSourceObject:objectRepresentation destinationObject:user mapping:userMapping metadataList:@[metadata]];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    mappingOperation.dataSource = dataSource;
    [mappingOperation start];
    expect(mappingOperation.error).to.beNil();
    expect(user.name).to.equal(@"Blake Watters");
    expect(user.emailAddress).to.equal(@"text/html; charset=UTF-8");
}

- (void)testMappingCollectionIndexFromRelationship
{
    // Do same as above, but use the "friends" relationship
    NSDictionary *objectRepresentation = @{ @"name": @"Blake Watters", @"friends": @[ @{ @"name": @"Jeff Arena" } ] };
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [userMapping addAttributeMappingsFromDictionary:@{ @"name": @"name", @"@metadata.mapping.collectionIndex": @"userID" }];
    [userMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"friends" toKeyPath:@"friendsSet" withMapping:userMapping]];
    RKTestUser *user = [RKTestUser new];
    RKMappingOperation *mappingOperation = [[RKMappingOperation alloc] initWithSourceObject:objectRepresentation destinationObject:user mapping:userMapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    mappingOperation.dataSource = dataSource;
    [mappingOperation start];
    expect(mappingOperation.error).to.beNil();
    expect(user.name).to.equal(@"Blake Watters");
    expect(user.friendsSet).to.haveCountOf(1);
    RKTestUser *jeff = [user.friendsSet anyObject];
    expect(jeff.name).to.equal(@"Jeff Arena");
    expect(jeff.userID).notTo.beNil();
    expect(jeff.userID).to.equal(0);
}

- (void)testMappingCollectionIndexFromMapperOperation
{
    NSArray *representations = @[ @{ @"name": @"Blake Watters" }, @{ @"name": @"Jeff Arena" }, @{ @"name": @"Dan Gellert" }, @{ @"name": @"Zachary Einzig" } ];
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [userMapping addAttributeMappingsFromDictionary:@{ @"name": @"name", @"@metadata.mapping.collectionIndex": @"position" }];
    RKMapperOperation *mapperOperation = [[RKMapperOperation alloc] initWithRepresentation:representations mappingsDictionary:@{ [NSNull null]: userMapping }];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    mapperOperation.mappingOperationDataSource = dataSource;
    NSError *error = nil;
    [mapperOperation execute:&error];
    NSArray *users = [mapperOperation.mappingResult array];
    expect(error).to.beNil();
    expect(users).to.haveCountOf(4);
    NSArray *expectedUsers = @[ @"Blake Watters", @"Jeff Arena", @"Dan Gellert", @"Zachary Einzig" ];
    [expectedUsers enumerateObjectsUsingBlock:^(NSString *name, NSUInteger index, BOOL *stop) {
        RKTestUser *user = users[index];
        expect(user.name).to.equal(name);
        expect(user.position).to.equal(index);
    }];
}

- (void)testMetadataIsMerged
{
    NSArray *representations = @[ @{ @"name": @"Blake Watters" } ];
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [userMapping addAttributeMappingsFromDictionary:@{ @"name": @"name", @"@metadata.mapping.collectionIndex": @"position", @"@metadata.mapping.country": @"country" }];
    RKMapperOperation *mapperOperation = [[RKMapperOperation alloc] initWithRepresentation:representations mappingsDictionary:@{ [NSNull null]: userMapping }];
    mapperOperation.metadata = @{ @"mapping": @{ @"country": @"United States of America" } };
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    mapperOperation.mappingOperationDataSource = dataSource;
    NSError *error = nil;
    [mapperOperation execute:&error];
    RKTestUser *user = [mapperOperation.mappingResult firstObject];
    expect(error).to.beNil();
    expect(user.name).to.equal(@"Blake Watters");
    expect(user.position).to.equal(0);
    expect(user.country).to.equal(@"United States of America");
}

- (void)testMappingCustomMetadataAsRelationship
{
    NSArray *representations = @[ @{ @"name": @"Blake Watters" } ];
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [userMapping addAttributeMappingsFromDictionary:@{ @"name": @"name" }];
    RKObjectMapping *friendsMapping = [userMapping copy];
    
    RKRelationshipMapping *relationshipMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"@metadata.custom" toKeyPath:@"friends" withMapping:friendsMapping];
    [userMapping addPropertyMapping:relationshipMapping];    
    RKMapperOperation *mapperOperation = [[RKMapperOperation alloc] initWithRepresentation:representations mappingsDictionary:@{ [NSNull null]: userMapping }];
    mapperOperation.metadata = @{ @"custom": @{ @"name": @"Valerio Mazzeo" } };
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    mapperOperation.mappingOperationDataSource = dataSource;
    NSError *error = nil;
    [mapperOperation execute:&error];
    RKTestUser *user = [mapperOperation.mappingResult firstObject];
    expect(error).to.beNil();
    expect(user.name).to.equal(@"Blake Watters");
    expect(user.friends).to.haveCountOf(1);
    expect([user.friends[0] name]).to.equal(@"Valerio Mazzeo");
}

#pragma mark - Persistent Stores

- (void)testMappingObjectToInMemoryPersistentStore
{
    NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"InMemoryTest.sqlite"];
    NSError *error = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:storePath]) [[NSFileManager defaultManager] removeItemAtPath:storePath error:&error];
    NSAssert(error == nil, @"Unexpectedly failed with error: %@", error);
    NSURL *modelURL = [[RKTestFixture fixtureBundle] URLForResource:@"Data Model" withExtension:@"mom"];
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:model];
    NSPersistentStore __unused *sqlStore = [managedObjectStore addSQLitePersistentStoreAtPath:storePath fromSeedDatabaseAtPath:nil withConfiguration:nil options:nil error:&error];
    NSAssert(error == nil, @"Unexpectedly failed with error: %@", error);
    NSPersistentStore __unused *inMemoryStore = [managedObjectStore addInMemoryPersistentStore:&error];
    NSAssert(error == nil, @"Unexpectedly failed with error: %@", error);
    [managedObjectStore createManagedObjectContexts];
    
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    humanMapping.persistentStore = inMemoryStore;
    [humanMapping addAttributeMappingsFromArray:@[ @"name" ]];
    
    NSDictionary *representation = @{ @"name": @"Blake Watters" };
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:representation destinationObject:nil mapping:humanMapping];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext cache:nil];
    operation.dataSource = dataSource;
    [operation performMapping:&error];
    expect(operation.destinationObject).notTo.beNil();
    expect([(NSManagedObject *)operation.destinationObject objectID].persistentStore).to.equal(inMemoryStore);
}

- (void)testMappingObjectToSQLitePersistentStore
{
    NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"SQLiteTest.sqlite"];
    NSError *error = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:storePath]) [[NSFileManager defaultManager] removeItemAtPath:storePath error:&error];
    NSAssert(error == nil, @"Unexpectedly failed with error: %@", error);
    NSURL *modelURL = [[RKTestFixture fixtureBundle] URLForResource:@"Data Model" withExtension:@"mom"];
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:model];
    NSPersistentStore __unused *sqlStore = [managedObjectStore addSQLitePersistentStoreAtPath:storePath fromSeedDatabaseAtPath:nil withConfiguration:nil options:nil error:&error];
    NSAssert(error == nil, @"Unexpectedly failed with error: %@", error);
    NSPersistentStore __unused *inMemoryStore = [managedObjectStore addInMemoryPersistentStore:&error];
    NSAssert(error == nil, @"Unexpectedly failed with error: %@", error);
    [managedObjectStore createManagedObjectContexts];
    
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    humanMapping.persistentStore = sqlStore;
    [humanMapping addAttributeMappingsFromArray:@[ @"name" ]];
    
    NSDictionary *representation = @{ @"name": @"Blake Watters" };
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:representation destinationObject:nil mapping:humanMapping];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext cache:nil];
    operation.dataSource = dataSource;
    [operation performMapping:&error];
    expect(operation.destinationObject).notTo.beNil();
    expect([(NSManagedObject *)operation.destinationObject objectID].persistentStore).to.equal(sqlStore);
}

- (void)testIdentifyingNestedObjectsUsingMetadataTraversalToParentObject
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];

    // Do same as above, but use the "friends" relationship
    NSDictionary *representation = @{ @"name": @"Blake Watters", @"house_id": @12345, @"friends": @[ @{ @"name": @"Jeff Arena" } ] };
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [humanMapping addAttributeMappingsFromDictionary:@{ @"name": @"name", @"house_id": @"houseID" }];
    RKEntityMapping *friendMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [friendMapping addAttributeMappingsFromDictionary:@{ @"name": @"name", @"@metadata.mapping.parentObject.houseID": @"houseID" }];
    friendMapping.identificationAttributes = @[ @"houseID", @"name" ];
    [humanMapping addRelationshipMappingWithSourceKeyPath:@"friends" mapping:friendMapping];

    RKHouse *house = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    house.railsID = @12345;

    RKHuman *firstJeff = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    firstJeff.name = @"Jeff Arena";
    firstJeff.houseID = @99999;
    RKHuman *secondJeff = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    secondJeff.name = @"Jeff Arena";
    secondJeff.houseID = @12345;

    RKFetchRequestManagedObjectCache *cache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext cache:cache];

    RKMapperOperation *mapperOperation = [[RKMapperOperation alloc] initWithRepresentation:representation mappingsDictionary:@{ [NSNull null]: humanMapping }];
    mapperOperation.mappingOperationDataSource = dataSource;
    NSError *error = nil;
    [mapperOperation execute:&error];

    expect(mapperOperation.error).to.beNil();
    RKHuman *blake = [mapperOperation.mappingResult firstObject];
    expect(blake.friends).notTo.beNil();
    expect([blake.friends anyObject]).to.equal(secondJeff);
}

- (void)testIdentifyingNestedObjectsUsingParentRepresentationTraversal
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];

    // Do same as above, but use the "@parent" key path
    NSDictionary *representation = @{ @"name": @"Blake Watters", @"house_id": @23456, @"friends": @[ @{ @"name": @"Jeff Arena" } ] };
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [humanMapping addAttributeMappingsFromDictionary:@{ @"name": @"name", @"house_id": @"houseID" }];
    RKEntityMapping *friendMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [friendMapping addAttributeMappingsFromDictionary:@{ @"name": @"name", @"@parent.house_id": @"houseID" }];
    friendMapping.identificationAttributes = @[ @"houseID", @"name" ];
    [humanMapping addRelationshipMappingWithSourceKeyPath:@"friends" mapping:friendMapping];

    RKHouse *house = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    house.railsID = @23456;

    RKHuman *firstJeff = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    firstJeff.name = @"Jeff Arena";
    firstJeff.houseID = @99999;
    RKHuman *secondJeff = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    secondJeff.name = @"Jeff Arena";
    secondJeff.houseID = @23456;

    RKFetchRequestManagedObjectCache *cache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext cache:cache];

    RKMapperOperation *mapperOperation = [[RKMapperOperation alloc] initWithRepresentation:representation mappingsDictionary:@{ [NSNull null]: humanMapping }];
    mapperOperation.mappingOperationDataSource = dataSource;
    NSError *error = nil;
    [mapperOperation execute:&error];

    expect(mapperOperation.error).to.beNil();
    RKHuman *blake = [mapperOperation.mappingResult firstObject];
    expect(blake.friends).notTo.beNil();
    expect([blake.friends anyObject]).to.equal(secondJeff);
}

- (void)testIdentifyingNestedObjectsUsingDeeplyNestedParentRepresentationTraversal
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];

    // Do same as above, but use the "@parent.@parent" key path
    NSDictionary *representation = @{ @"name": @"Blake Watters", @"house" : @{ @"house_id": @34567 }, @"people" : @{ @"friends": @[ @{ @"name": @"Jeff Arena" } ] } };
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [humanMapping addAttributeMappingsFromDictionary:@{ @"name": @"name", @"house.house_id": @"houseID" }];
    RKEntityMapping *friendMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [friendMapping addAttributeMappingsFromDictionary:@{ @"name": @"name", @"@parent.@parent.house.house_id": @"houseID" }];
    friendMapping.identificationAttributes = @[ @"houseID", @"name" ];

    RKRelationshipMapping *relationshipMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"people.friends" toKeyPath:@"friends" withMapping:friendMapping];
    [humanMapping addPropertyMapping:relationshipMapping];

    RKHouse *house = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    house.railsID = @34567;

    RKHuman *firstJeff = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    firstJeff.name = @"Jeff Arena";
    firstJeff.houseID = @99999;
    RKHuman *secondJeff = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    secondJeff.name = @"Jeff Arena";
    secondJeff.houseID = @34567;

    RKFetchRequestManagedObjectCache *cache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext cache:cache];

    RKMapperOperation *mapperOperation = [[RKMapperOperation alloc] initWithRepresentation:representation mappingsDictionary:@{ [NSNull null]: humanMapping }];
    mapperOperation.mappingOperationDataSource = dataSource;
    NSError *error = nil;
    [mapperOperation execute:&error];

    expect(mapperOperation.error).to.beNil();
    RKHuman *blake = [mapperOperation.mappingResult firstObject];
    expect(blake.friends).notTo.beNil();
    expect([blake.friends anyObject]).to.equal(secondJeff);
}

- (void)testIdentifyingNestedObjectsUsingRootRepresentation
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];

    // Do same as above, but use the "@root" key path
    NSDictionary *representation = @{ @"name": @"Blake Watters", @"house_id": @45678, @"people" : @{ @"friends": @[ @{ @"name": @"Jeff Arena" } ] } };
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [humanMapping addAttributeMappingsFromDictionary:@{ @"name": @"name", @"house_id": @"houseID" }];
    RKEntityMapping *friendMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [friendMapping addAttributeMappingsFromDictionary:@{ @"name": @"name", @"@root.house_id": @"houseID" }];
    friendMapping.identificationAttributes = @[ @"houseID", @"name" ];

    RKRelationshipMapping *relationshipMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"people.friends" toKeyPath:@"friends" withMapping:friendMapping];
    [humanMapping addPropertyMapping:relationshipMapping];

    RKHouse *house = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    house.railsID = @45678;

    RKHuman *firstJeff = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    firstJeff.name = @"Jeff Arena";
    firstJeff.houseID = @99999;
    RKHuman *secondJeff = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    secondJeff.name = @"Jeff Arena";
    secondJeff.houseID = @45678;

    RKFetchRequestManagedObjectCache *cache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext cache:cache];

    RKMapperOperation *mapperOperation = [[RKMapperOperation alloc] initWithRepresentation:representation mappingsDictionary:@{ [NSNull null]: humanMapping }];
    mapperOperation.mappingOperationDataSource = dataSource;
    NSError *error = nil;
    [mapperOperation execute:&error];

    expect(mapperOperation.error).to.beNil();
    RKHuman *blake = [mapperOperation.mappingResult firstObject];
    expect(blake.friends).notTo.beNil();
    expect([blake.friends anyObject]).to.equal(secondJeff);
}

- (void)testUsingRootKeyDirectlyWithMappingOperation
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    
    // Do same as above, but use the "@root" key path
    NSDictionary *representation = @{ @"name": @"Blake Watters", @"house_id": @45678, @"people" : @{ @"friends": @[ @{ @"name": @"Jeff Arena" } ] } };
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [humanMapping addAttributeMappingsFromDictionary:@{ @"name": @"name", @"house_id": @"houseID" }];
    RKEntityMapping *friendMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [friendMapping addAttributeMappingsFromDictionary:@{ @"name": @"name", @"@root.house_id": @"houseID" }];
    friendMapping.identificationAttributes = @[ @"houseID", @"name" ];
    
    RKRelationshipMapping *relationshipMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"people.friends" toKeyPath:@"friends" withMapping:friendMapping];
    [humanMapping addPropertyMapping:relationshipMapping];
    
    RKHouse *house = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    house.railsID = @45678;
    
    RKHuman *firstJeff = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    firstJeff.name = @"Jeff Arena";
    firstJeff.houseID = @99999;
    RKHuman *secondJeff = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    secondJeff.name = @"Jeff Arena";
    secondJeff.houseID = @45678;
    
    RKFetchRequestManagedObjectCache *cache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext cache:cache];
    
    NSError *error = nil;
    RKMappingOperation *mappingOperation = [[RKMappingOperation alloc] initWithSourceObject:representation destinationObject:nil mapping:humanMapping];
    mappingOperation.dataSource = dataSource;
    BOOL success = [mappingOperation performMapping:&error];
    
    expect(success).to.beTruthy();
    expect(mappingOperation.error).to.beNil();
    RKHuman *blake = mappingOperation.destinationObject;
    expect(blake.friends).notTo.beNil();
    expect([blake.friends anyObject]).to.equal(secondJeff);
}

- (void)testIdentifyingNestedObjectsUsingParentRepresentationTraversalDirectlyWithMappingOperation
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    
    // Do same as above, but use the "@parent" key path
    NSDictionary *representation = @{ @"name": @"Blake Watters", @"house_id": @23456, @"friends": @[ @{ @"name": @"Jeff Arena" } ] };
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [humanMapping addAttributeMappingsFromDictionary:@{ @"name": @"name", @"house_id": @"houseID" }];
    RKEntityMapping *friendMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [friendMapping addAttributeMappingsFromDictionary:@{ @"name": @"name", @"@parent.house_id": @"houseID" }];
    friendMapping.identificationAttributes = @[ @"houseID", @"name" ];
    [humanMapping addRelationshipMappingWithSourceKeyPath:@"friends" mapping:friendMapping];
    
    RKHouse *house = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    house.railsID = @23456;
    
    RKHuman *firstJeff = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    firstJeff.name = @"Jeff Arena";
    firstJeff.houseID = @99999;
    RKHuman *secondJeff = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    secondJeff.name = @"Jeff Arena";
    secondJeff.houseID = @23456;
    
    RKFetchRequestManagedObjectCache *cache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext cache:cache];
    
    NSError *error = nil;
    RKMappingOperation *mappingOperation = [[RKMappingOperation alloc] initWithSourceObject:representation destinationObject:nil mapping:humanMapping];
    mappingOperation.dataSource = dataSource;
    BOOL success = [mappingOperation performMapping:&error];
    
    expect(success).to.beTruthy();
    expect(error).to.beNil();
    RKHuman *blake = mappingOperation.destinationObject;
    expect(blake.friends).notTo.beNil();
    expect([blake.friends anyObject]).to.equal(secondJeff);
}

@end
