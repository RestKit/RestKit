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

// Managed Object Serialization Testific
#import "RKHuman.h"
#import "RKCat.h"

@interface RKObjectMapping ()
+ (void)resetDefaultDateFormatters;
@end

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

@interface RKObjectMappingNextGenTest : RKTestCase {

}

@end

@implementation RKObjectMappingNextGenTest

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

// TODO: Decide about inverse...
//- (void)testShouldGenerateAnInverseMappings
//{
//    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
//    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"first_name" toKeyPath:@"firstName"]];
//    [mapping addAttributeMappingsFromArray:@[@"city", @"state", @"zip"]];
//    RKObjectMapping *otherMapping = [RKObjectMapping mappingForClass:[RKTestAddress class]];
//    [otherMapping addAttributeMappingsFromArray:@[@"street"]];
//    [mapping mapRelationship:@"address" withMapping:otherMapping];
//    RKObjectMapping *inverse = [mapping inverseMapping];
//    assertThat(inverse.objectClass, is(equalTo([NSMutableDictionary class])));
//    assertThat([inverse mappingForKeyPath:@"firstName"], isNot(nilValue()));
//}

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
    BOOL success = [mapper mapFromObject:userInfo toObject:user atKeyPath:@"" usingMapping:mapping];
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
    NSArray *users = [mapper mapCollection:userInfo atKeyPath:@"" usingMapping:mapping];
    assertThatUnsignedInteger([users count], is(equalToInt(3)));
    RKTestUser *blake = [users objectAtIndex:0];
    assertThat(blake.name, is(equalTo(@"Blake Watters")));
}

// TODO: This doesn't really test anything anymore...
- (void)testShouldDetermineTheObjectMappingByConsultingTheMappingProviderWhenThereIsATargetObject
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    [mappingsDictionary setObject:mapping forKey:[NSNull null]];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithObject:userInfo mappingsDictionary:mappingsDictionary];
    mapper.targetObject = [RKTestUser user];
    [mapper start];
}

- (void)testShouldAddAnErrorWhenTheKeyPathMappingAndObjectClassDoNotAgree
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithObject:userInfo mappingsDictionary:@{[NSNull null] : mapping}];
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

    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    [mappingsDictionary setObject:mapping forKey:[NSNull null]];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithObject:userInfo mappingsDictionary:@{[NSNull null] : mapping}];
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

    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    [mappingsDictionary setObject:mapping forKey:[NSNull null]];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithObject:userInfo mappingsDictionary:mappingsDictionary];
    [mapper start];
    id mappingResult = [mapper.mappingResult firstObject];
    assertThatBool([mappingResult isKindOfClass:[RKTestUser class]], is(equalToBool(YES)));
}

- (void)testShouldMapWithoutATargetMapping
{
    RKLogConfigureByName("RestKit/ObjectMapping", RKLogLevelTrace);
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *idMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addPropertyMapping:idMapping];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addPropertyMapping:nameMapping];

    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    [mappingsDictionary setObject:mapping forKey:[NSNull null]];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithObject:userInfo mappingsDictionary:mappingsDictionary];
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
    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    [mappingsDictionary setObject:mapping forKey:[NSNull null]];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"users.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithObject:userInfo mappingsDictionary:mappingsDictionary];
    [mapper start];
    NSArray *users = [mapper.mappingResult array];
    assertThatBool([users isKindOfClass:[NSArray class]], is(equalToBool(YES)));
    assertThatUnsignedInteger([users count], is(equalToInt(3)));
    RKTestUser *user = [users objectAtIndex:0];
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
    [mappingsDictionary setObject:mapping forKey:@"users"];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"DynamicKeys.json"];
    
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithObject:userInfo mappingsDictionary:mappingsDictionary];
    [mapper start];
    NSArray *users = [mapper.mappingResult array];
    assertThatBool([users isKindOfClass:[NSArray class]], is(equalToBool(YES)));
    assertThatUnsignedInteger([users count], is(equalToInt(2)));
    RKTestUser *user = [users objectAtIndex:0];
    assertThatBool([user isKindOfClass:[RKTestUser class]], is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"blake")));
    user = [users objectAtIndex:1];
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
    [mappingsDictionary setObject:mapping forKey:@"users"];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"DynamicKeysWithRelationship.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithObject:userInfo mappingsDictionary:mappingsDictionary];
    [mapper start];
    RKMappingResult *result = mapper.mappingResult;
    NSArray *users = [result array];
    assertThatBool([users isKindOfClass:[NSArray class]], is(equalToBool(YES)));
    assertThatUnsignedInteger([users count], is(equalToInt(2)));
    RKTestUser *user = [users objectAtIndex:0];
    assertThatBool([user isKindOfClass:[RKTestUser class]], is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"blake")));
    user = [users objectAtIndex:1];
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
    [mappingsDictionary setObject:mapping forKey:@"groups"];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"DynamicKeysWithNestedRelationship.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithObject:userInfo mappingsDictionary:mappingsDictionary];
    [mapper start];
    RKMappingResult *result = mapper.mappingResult;

    NSArray *groups = [result array];
    assertThatBool([groups isKindOfClass:[NSArray class]], is(equalToBool(YES)));
    assertThatUnsignedInteger([groups count], is(equalToInt(2)));

    RKExampleGroupWithUserArray *group = [groups objectAtIndex:0];
    assertThatBool([group isKindOfClass:[RKExampleGroupWithUserArray class]], is(equalToBool(YES)));
    assertThat(group.name, is(equalTo(@"restkit")));
    NSArray *users = group.users;
    RKTestUser *user = [users objectAtIndex:0];
    assertThatBool([user isKindOfClass:[RKTestUser class]], is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"blake")));
    user = [users objectAtIndex:1];
    assertThatBool([user isKindOfClass:[RKTestUser class]], is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"rachit")));
    assertThat(user.address, isNot(nilValue()));
    assertThat(user.address.city, is(equalTo(@"New York")));

    group = [groups objectAtIndex:1];
    assertThatBool([group isKindOfClass:[RKExampleGroupWithUserArray class]], is(equalToBool(YES)));
    assertThat(group.name, is(equalTo(@"others")));
    users = group.users;
    assertThatUnsignedInteger([users count], is(equalToInt(1)));
    user = [users objectAtIndex:0];
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
    [mappingsDictionary setObject:mapping forKey:@"groups"];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"DynamicKeysWithNestedRelationship.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithObject:userInfo mappingsDictionary:mappingsDictionary];
    [mapper start];
    RKMappingResult *result = mapper.mappingResult;

    NSArray *groups = [result array];
    assertThatBool([groups isKindOfClass:[NSArray class]], is(equalToBool(YES)));
    assertThatUnsignedInteger([groups count], is(equalToInt(2)));

    RKExampleGroupWithUserSet *group = [groups objectAtIndex:0];
    assertThatBool([group isKindOfClass:[RKExampleGroupWithUserSet class]], is(equalToBool(YES)));
    assertThat(group.name, is(equalTo(@"restkit")));


    NSSortDescriptor *sortByName = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    NSArray *descriptors = [NSArray arrayWithObject:sortByName];;
    NSArray *users = [group.users sortedArrayUsingDescriptors:descriptors];
    RKTestUser *user = [users objectAtIndex:0];
    assertThatBool([user isKindOfClass:[RKTestUser class]], is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"blake")));
    user = [users objectAtIndex:1];
    assertThatBool([user isKindOfClass:[RKTestUser class]], is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"rachit")));
    assertThat(user.address, isNot(nilValue()));
    assertThat(user.address.city, is(equalTo(@"New York")));

    group = [groups objectAtIndex:1];
    assertThatBool([group isKindOfClass:[RKExampleGroupWithUserSet class]], is(equalToBool(YES)));
    assertThat(group.name, is(equalTo(@"others")));
    users = [group.users sortedArrayUsingDescriptors:descriptors];
    assertThatUnsignedInteger([users count], is(equalToInt(1)));
    user = [users objectAtIndex:0];
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
    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    [mappingsDictionary setObject:mapping forKey:[NSNull null]];

    RKTestUser *user = [RKTestUser user];
    user.name = @"Blake Watters";
    user.userID = [NSNumber numberWithInt:123];

    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithObject:user mappingsDictionary:mappingsDictionary];
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
    [mappingsDictionary setObject:mapping forKey:@"user"];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"nested_user.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithObject:userInfo mappingsDictionary:mappingsDictionary];
    [mapper start];
    NSDictionary *dictionary = [mapper.mappingResult dictionary];
    assertThatBool([dictionary isKindOfClass:[NSDictionary class]], is(equalToBool(YES)));
    RKTestUser *user = [dictionary objectForKey:@"user"];
    assertThat(user, isNot(nilValue()));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
}

#pragma mark Mapping Error States

- (void)testShouldAddAnErrorWhenYouTryToMapAnArrayToATargetObject
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *idMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addPropertyMapping:idMapping];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addPropertyMapping:nameMapping];
    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    [mappingsDictionary setObject:mapping forKey:[NSNull null]];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"users.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithObject:userInfo mappingsDictionary:mappingsDictionary];
    mapper.targetObject = [RKTestUser user];
    [mapper start];
    assertThatInteger(mapper.error.code, is(equalToInt(RKMappingErrorTypeMismatch)));
}

- (void)testShouldAddAnErrorWhenAttemptingToMapADictionaryWithoutAnObjectMapping
{
    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithObject:userInfo mappingsDictionary:mappingsDictionary];
    [mapper start];
    assertThat([mapper.error localizedDescription], is(equalTo(@"Unable to find any mappings for the given content")));
}

- (void)testShouldAddAnErrorWhenAttemptingToMapACollectionWithoutAnObjectMapping
{
    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"users.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithObject:userInfo mappingsDictionary:mappingsDictionary];
    [mapper start];
    assertThat([mapper.error localizedDescription], is(equalTo(@"Unable to find any mappings for the given content")));
}

#pragma mark RKMapperOperationDelegate Tests

- (void)testShouldInformTheDelegateWhenMappingBegins
{
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKMapperOperationDelegate)];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    [mappingsDictionary setObject:mapping forKey:[NSNull null]];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"users.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithObject:userInfo mappingsDictionary:mappingsDictionary];
    [[mockDelegate expect] mapperWillStartMapping:mapper];
    mapper.delegate = mockDelegate;
    [mapper start];
    [mockDelegate verify];
}

- (void)testShouldInformTheDelegateWhenMappingEnds
{
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKMapperOperationDelegate)];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    [mappingsDictionary setObject:mapping forKey:[NSNull null]];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"users.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithObject:userInfo mappingsDictionary:mappingsDictionary];
    [[mockDelegate stub] mapperWillStartMapping:mapper];
    [[mockDelegate expect] mapperDidFinishMapping:mapper];
    mapper.delegate = mockDelegate;
    [mapper start];
    [mockDelegate verify];
}

- (void)testShouldInformTheDelegateWhenCheckingForObjectMappingForKeyPathIsSuccessful
{
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKMapperOperationDelegate)];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    [mappingsDictionary setObject:mapping forKey:[NSNull null]];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithObject:userInfo mappingsDictionary:mappingsDictionary];
    [[mockDelegate expect] mapper:mapper didFindRepresentationOrArrayOfRepresentations:OCMOCK_ANY atKeyPath:nil];
    mapper.delegate = mockDelegate;
    [mapper start];
    [mockDelegate verify];
}

- (void)testShouldInformTheDelegateWhenCheckingForObjectMappingForKeyPathIsNotSuccessful
{
    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mappingsDictionary setObject:mapping forKey:@"users"];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithObject:userInfo mappingsDictionary:mappingsDictionary];
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
    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    [mappingsDictionary setObject:mapping forKey:[NSNull null]];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithObject:userInfo mappingsDictionary:mappingsDictionary];
    [[mockDelegate expect] mapper:mapper didFinishMappingOperation:OCMOCK_ANY forKeyPath:nil];
    mapper.delegate = mockDelegate;
    [mapper start];
    [mockDelegate verify];
}

- (BOOL)fakeValidateValue:(inout id *)ioValue forKeyPath:(NSString *)inKey error:(out NSError **)outError
{
    *outError = [NSError errorWithDomain:RKErrorDomain code:1234 userInfo:nil];
    return NO;
}

- (void)testShouldNotifyTheDelegateWhenItFailedToMapAnObject
{
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKMapperOperationDelegate)];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:NSClassFromString(@"OCPartialMockObject")];
    [mapping addAttributeMappingsFromArray:@[@"name"]];
    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    [mappingsDictionary setObject:mapping forKey:[NSNull null]];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithObject:userInfo mappingsDictionary:mappingsDictionary];
    RKTestUser *exampleUser = [RKTestUser new];
    id mockObject = [OCMockObject partialMockForObject:exampleUser];
    [[[mockObject expect] andCall:@selector(fakeValidateValue:forKeyPath:error:) onObject:self] validateValue:(id __autoreleasing *)[OCMArg anyPointer] forKeyPath:OCMOCK_ANY error:(NSError * __autoreleasing *)[OCMArg anyPointer]];
    mapper.targetObject = mockObject;
    [[mockDelegate expect] mapper:mapper didFailMappingOperation:OCMOCK_ANY forKeyPath:nil withError:OCMOCK_ANY];
    mapper.delegate = mockDelegate;
    [mapper start];
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

    NSMutableDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:123], @"id", @"Blake Watters", @"name", nil];
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

    NSMutableDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNull null], @"name", nil];
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
    user.userID = [NSNumber numberWithInt:123];

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:user destinationObject:dictionary mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    BOOL success = [operation performMapping:nil];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat([dictionary valueForKey:@"name"], is(equalTo(@"Blake Watters")));
    assertThatInt([[dictionary valueForKey:@"id"] intValue], is(equalToInt(123)));
}

- (void)testShouldReturnNoWithoutErrorWhenGivenASourceObjectThatContainsNoMappableKeys
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKAttributeMapping *idMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addPropertyMapping:idMapping];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addPropertyMapping:nameMapping];

    NSMutableDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"blue", @"favorite_color", @"coffee", @"preferred_beverage", nil];
    RKTestUser *user = [RKTestUser user];

    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(NO)));
    assertThat(error, is(notNilValue()));
    assertThatInteger(operation.error.code, is(equalToInteger(RKMappingErrorUnmappableRepresentation)));
}

- (void)testShouldInformTheDelegateOfAnErrorWhenMappingFailsBecauseThereIsNoMappableContent
{
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKMappingOperationDelegate)];
    
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKAttributeMapping *idMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addPropertyMapping:idMapping];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addPropertyMapping:nameMapping];

    NSMutableDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"blue", @"favorite_color", @"coffee", @"preferred_beverage", nil];
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

    NSMutableDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"FAILURE", @"id", nil];
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
    [RKObjectMapping resetDefaultDateFormatters];

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
    assertThatBool([weight isKindOfClass:[NSDecimalNumber class]], is(equalToBool(YES)));
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

    NSArray *interests = [NSArray arrayWithObjects:@"Hacking", @"Running", nil];
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
                             @"id": [NSNumber numberWithInt:1234],
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
    BOOL returnValue = YES;
    [[[mockMapping expect] andReturnValue:OCMOCK_VALUE(returnValue)] shouldSetDefaultValueForMissingAttributes];
    NSError *error = nil;
    [operation performMapping:&error];
    [mockUser verify];
}

- (void)testShouldOptionallyIgnoreAMissingSourceKeyPath
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKAttributeMapping *nameMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addPropertyMapping:nameMapping];

    NSMutableDictionary *dictionary = [[RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    [dictionary removeObjectForKey:@"name"];
    RKTestUser *user = [RKTestUser user];
    user.name = @"Blake Watters";
    id mockUser = [OCMockObject partialMockForObject:user];
    [(RKTestUser *)[mockUser reject] setName:nil];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    id mockMapping = [OCMockObject partialMockForObject:mapping];
    BOOL returnValue = NO;
    [[[mockMapping expect] andReturnValue:OCMOCK_VALUE(returnValue)] shouldSetDefaultValueForMissingAttributes];
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
    BOOL success = [mapper mapFromObject:userInfo toObject:user atKeyPath:@"" usingMapping:userMapping];
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
    BOOL success = [mapper mapFromObject:userInfo toObject:user atKeyPath:@"" usingMapping:userMapping];
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
    BOOL success = [mapper mapFromObject:userInfo toObject:user atKeyPath:@"" usingMapping:userMapping];
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
    BOOL success = [mapper mapFromObject:userInfo toObject:user atKeyPath:@"" usingMapping:userMapping];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
    assertThat(user.friends, isNot(nilValue()));
    assertThatUnsignedInteger([user.friends count], is(equalToInt(2)));
    NSArray *names = [NSArray arrayWithObjects:@"Jeremy Ellison", @"Rachit Shukla", nil];
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
    BOOL success = [mapper mapFromObject:userInfo toObject:user atKeyPath:@"" usingMapping:userMapping];
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
    BOOL success = [mapper mapFromObject:userInfo toObject:user atKeyPath:@"" usingMapping:userMapping];
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
    address.addressID = [NSNumber numberWithInt:1234];
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
    [mapper mapFromObject:userInfo toObject:user atKeyPath:@"" usingMapping:userMapping];
}

- (void)testSkippingOfIdenticalObjectsInformsDelegate
{
    RKTestUser *user = [RKTestUser user];
    RKTestAddress *address = [RKTestAddress address];
    address.addressID = [NSNumber numberWithInt:1234];
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
    [[mockDelegate expect] mappingOperation:operation didNotSetUnchangedValue:address forKeyPath:@"address" usingMapping:hasOneMapping];
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
    jeremy.userID = [NSNumber numberWithInt:187];
    RKTestUser *rachit = [RKTestUser user];
    rachit.name = @"Rachit Shukla";
    rachit.userID = [NSNumber numberWithInt:7];
    user.friends = [NSArray arrayWithObjects:jeremy, rachit, nil];

    id mockUser = [OCMockObject partialMockForObject:user];
    [[mockUser reject] setFriends:OCMOCK_ANY];
    [mapper mapFromObject:userInfo toObject:mockUser atKeyPath:@"" usingMapping:userMapping];
    [mockUser verify];
}

- (void)testShouldOptionallyNilOutTheRelationshipIfItIsMissing
{
    RKTestUser *user = [RKTestUser user];
    RKTestAddress *address = [RKTestAddress address];
    address.addressID = [NSNumber numberWithInt:1234];
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
    BOOL returnValue = YES;
    [[[mockMapping expect] andReturnValue:OCMOCK_VALUE(returnValue)] setNilForMissingRelationships];
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
    BOOL returnValue = YES;
    [[[mockMapping expect] andReturnValue:OCMOCK_VALUE(returnValue)] setNilForMissingRelationships];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:dictionary destinationObject:mockUser mapping:mockMapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;

    NSError *error = nil;
    [operation performMapping:&error];
    [mockUser verify];
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
    [mappingsDictionary setObject:dynamicMapping forKey:@""];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"boy.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithObject:userInfo mappingsDictionary:mappingsDictionary];
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
    [dynamicMapping setObjectMapping:boyMapping whenValueOfKeyPath:@"type" isEqualTo:@"Boy"];
    [dynamicMapping setObjectMapping:girlMapping whenValueOfKeyPath:@"type" isEqualTo:@"Girl"];

    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    [mappingsDictionary setObject:dynamicMapping forKey:@""];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"boy.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithObject:userInfo mappingsDictionary:mappingsDictionary];
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
    [dynamicMapping setObjectMapping:boyMapping whenValueOfKeyPath:@"type" isEqualTo:@"Boy"];
    [dynamicMapping setObjectMapping:girlMapping whenValueOfKeyPath:@"type" isEqualTo:@"Girl"];

    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    [mappingsDictionary setObject:dynamicMapping forKey:@""];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"mixed.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithObject:userInfo mappingsDictionary:mappingsDictionary];
    [mapper start];
    NSArray *objects = [mapper.mappingResult array];
    expect(objects).to.haveCountOf(2);
    expect(objects[0]).to.beInstanceOf([Boy class]);
    expect(objects[1]).to.beInstanceOf([Girl class]);
    Boy *boy = [objects objectAtIndex:0];
    Girl *girl = [objects objectAtIndex:1];
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
    [dynamicMapping setObjectMapping:boyMapping whenValueOfKeyPath:@"type" isEqualTo:@"Boy"];
    [dynamicMapping setObjectMapping:girlMapping whenValueOfKeyPath:@"type" isEqualTo:@"Girl"];
    [boyMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"friends" toKeyPath:@"friends" withMapping:dynamicMapping]];;

    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    [mappingsDictionary setObject:dynamicMapping forKey:@""];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"friends.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithObject:userInfo mappingsDictionary:mappingsDictionary];
    [mapper start];
    Boy *blake = [mapper.mappingResult firstObject];
    NSArray *friends = blake.friends;

    assertThat(friends, hasCountOf(2));
    assertThat([friends objectAtIndex:0], is(instanceOf([Boy class])));
    assertThat([friends objectAtIndex:1], is(instanceOf([Girl class])));
    Boy *boy = [friends objectAtIndex:0];
    Girl *girl = [friends objectAtIndex:1];
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
    [mappingsDictionary setObject:dynamicMapping forKey:@""];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"mixed.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithObject:userInfo mappingsDictionary:mappingsDictionary];
    [mapper start];
    NSArray *boys = [mapper.mappingResult array];
    assertThat(boys, hasCountOf(1));
    Boy *user = [boys objectAtIndex:0];
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
    [mappingsDictionary setObject:dynamicMapping forKey:@""];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"friends.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithObject:userInfo mappingsDictionary:mappingsDictionary];
    [mapper start];
    Boy *blake = [mapper.mappingResult firstObject];
    assertThat(blake, is(notNilValue()));
    assertThat(blake.name, is(equalTo(@"Blake Watters")));
    assertThat(blake, is(instanceOf([Boy class])));
    NSArray *friends = blake.friends;

    assertThat(friends, hasCountOf(1));
    assertThat([friends objectAtIndex:0], is(instanceOf([Boy class])));
    Boy *boy = [friends objectAtIndex:0];
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
    [mappingsDictionary setObject:dynamicMapping forKey:@""];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"boy.json"];
    Boy *blake = [Boy new];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithObject:userInfo mappingsDictionary:mappingsDictionary];
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
    [mappingsDictionary setObject:dynamicMapping forKey:@""];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"boy.json"];
    Boy *blake = [Boy new];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithObject:userInfo mappingsDictionary:mappingsDictionary];
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
    [mappingsDictionary setObject:dynamicMapping forKey:@""];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"girl.json"];
    Boy *blake = [Boy new];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithObject:userInfo mappingsDictionary:mappingsDictionary];
    mapper.targetObject = blake;
    [mapper start];
    Boy *user = [mapper.mappingResult firstObject];
    assertThat(user, is(nilValue()));
    assertThat(mapper.error, is(notNilValue()));
}

#pragma mark - Date and Time Formatting

- (void)testShouldAutoConfigureDefaultDateFormatters
{
    [RKObjectMapping resetDefaultDateFormatters];
    NSArray *dateFormatters = [RKObjectMapping defaultDateFormatters];
    expect(dateFormatters).to.haveCountOf(5);
    expect([dateFormatters[0] dateFormat]).to.equal(@"yyyy-MM-dd");
    expect([dateFormatters[1] dateFormat]).to.equal(@"yyyy-MM-dd'T'HH:mm:ss'Z'");
    expect([dateFormatters[2] dateFormat]).to.equal(@"MM/dd/yyyy");

    NSTimeZone *UTCTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    expect([[dateFormatters objectAtIndex:0] timeZone]).to.equal(UTCTimeZone);
    expect([[dateFormatters objectAtIndex:1] timeZone]).to.equal(UTCTimeZone);
    expect([[dateFormatters objectAtIndex:2] timeZone]).to.equal(UTCTimeZone);
}

- (void)testShouldLetYouSetTheDefaultDateFormatters
{
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    NSArray *dateFormatters = [NSArray arrayWithObject:dateFormatter];
    [RKObjectMapping setDefaultDateFormatters:dateFormatters];
    assertThat([RKObjectMapping defaultDateFormatters], is(equalTo(dateFormatters)));
}

- (void)testShouldLetYouAppendADateFormatterToTheList
{
    [RKObjectMapping resetDefaultDateFormatters];
    assertThat([RKObjectMapping defaultDateFormatters], hasCountOf(5));
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [RKObjectMapping addDefaultDateFormatter:dateFormatter];
    assertThat([RKObjectMapping defaultDateFormatters], hasCountOf(6));
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
    [RKObjectMapping resetDefaultDateFormatters];
    assertThat([RKObjectMapping defaultDateFormatters], hasCountOf(5));
    NSTimeZone *EDTTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"EDT"];
    [RKObjectMapping addDefaultDateFormatterForString:@"mm/dd/YYYY" inTimeZone:EDTTimeZone];
    assertThat([RKObjectMapping defaultDateFormatters], hasCountOf(6));
    NSDateFormatter *dateFormatter = [[RKObjectMapping defaultDateFormatters] objectAtIndex:0];
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
    [RKObjectMapping resetDefaultDateFormatters];
    assertThat([RKObjectMapping defaultDateFormatters], hasCountOf(5));
    [RKObjectMapping addDefaultDateFormatterForString:@"mm/dd/YYYY" inTimeZone:nil];
    assertThat([RKObjectMapping defaultDateFormatters], hasCountOf(6));
    NSDateFormatter *dateFormatter = [[RKObjectMapping defaultDateFormatters] objectAtIndex:0];
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

#pragma mark - Object Serialization
// TODO: Move to RKObjectSerializerTest

- (void)testShouldSerializeHasOneRelatioshipsToJSON
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [userMapping addAttributeMappingsFromArray:@[@"name"]];
    RKObjectMapping *addressMapping = [RKObjectMapping mappingForClass:[RKTestAddress class]];
    [addressMapping addAttributeMappingsFromArray:@[@"city", @"state"]];
    [userMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"address" toKeyPath:@"address" withMapping:addressMapping]];

    RKTestUser *user = [RKTestUser new];
    user.name = @"Blake Watters";
    RKTestAddress *address = [RKTestAddress new];
    address.state = @"North Carolina";
    user.address = address;

    RKObjectMapping *serializationMapping = [userMapping inverseMapping];
    NSDictionary *params = [RKObjectParameterization parametersWithObject:user requestDescriptor:[RKRequestDescriptor requestDescriptorWithMapping:serializationMapping objectClass:[RKTestUser class] rootKeyPath:nil] error:nil];
    NSError *error = nil;
    NSString *JSON = [[NSString alloc] initWithData:[RKMIMETypeSerialization dataFromObject:params MIMEType:RKMIMETypeJSON error:nil] encoding:NSUTF8StringEncoding];
    assertThat(error, is(nilValue()));
    assertThat(JSON, is(equalTo(@"{\"name\":\"Blake Watters\",\"address\":{\"state\":\"North Carolina\"}}")));
}

- (void)testShouldSerializeHasManyRelationshipsToJSON
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [userMapping addAttributeMappingsFromArray:@[@"name"]];
    RKObjectMapping *addressMapping = [RKObjectMapping mappingForClass:[RKTestAddress class]];
    [addressMapping addAttributeMappingsFromArray:@[@"city", @"state"]];
    [userMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"friends" toKeyPath:@"friends" withMapping:addressMapping]];

    RKTestUser *user = [RKTestUser new];
    user.name = @"Blake Watters";
    RKTestAddress *address1 = [RKTestAddress new];
    address1.city = @"Carrboro";
    RKTestAddress *address2 = [RKTestAddress new];
    address2.city = @"New York City";
    user.friends = [NSArray arrayWithObjects:address1, address2, nil];


    RKObjectMapping *serializationMapping = [userMapping inverseMapping];
    NSDictionary *params = [RKObjectParameterization parametersWithObject:user requestDescriptor:[RKRequestDescriptor requestDescriptorWithMapping:serializationMapping objectClass:[RKTestUser class] rootKeyPath:nil] error:nil];
    NSError *error = nil;
    NSString *JSON = [[NSString alloc] initWithData:[RKMIMETypeSerialization dataFromObject:params MIMEType:RKMIMETypeJSON error:nil] encoding:NSUTF8StringEncoding];
    assertThat(error, is(nilValue()));
    assertThat(JSON, is(equalTo(@"{\"name\":\"Blake Watters\",\"friends\":[{\"city\":\"Carrboro\"},{\"city\":\"New York City\"}]}")));
}

- (void)testShouldSerializeManagedHasManyRelationshipsToJSON
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKObjectMapping *humanMapping = [RKObjectMapping mappingForClass:[RKHuman class]];
    [humanMapping addAttributeMappingsFromArray:@[@"name"]];
    RKObjectMapping *catMapping = [RKObjectMapping mappingForClass:[RKCat class]];
    [catMapping addAttributeMappingsFromArray:@[@"name"]];
    [humanMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"cats" toKeyPath:@"cats" withMapping:catMapping]];

    RKHuman *blake = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    blake.name = @"Blake Watters";
    RKCat *asia = [NSEntityDescription insertNewObjectForEntityForName:@"Cat" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    asia.name = @"Asia";
    RKCat *roy = [NSEntityDescription insertNewObjectForEntityForName:@"Cat" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    roy.name = @"Roy";
    blake.cats = [NSSet setWithObjects:asia, roy, nil];

    RKObjectMapping *serializationMapping = [humanMapping inverseMapping];
    
    NSDictionary *params = [RKObjectParameterization parametersWithObject:blake requestDescriptor:[RKRequestDescriptor requestDescriptorWithMapping:serializationMapping objectClass:[RKHuman class] rootKeyPath:nil] error:nil];
    NSError *error = nil;
    NSDictionary *parsedJSON = [NSJSONSerialization JSONObjectWithData:[RKMIMETypeSerialization dataFromObject:params MIMEType:RKMIMETypeJSON error:nil] options:0 error:nil];
    assertThat(error, is(nilValue()));
    assertThat([parsedJSON valueForKey:@"name"], is(equalTo(@"Blake Watters")));
    NSArray *catNames = [[parsedJSON valueForKeyPath:@"cats.name"] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    assertThat(catNames, is(equalTo([NSArray arrayWithObjects:@"Asia", @"Roy", nil])));
}

- (void)testUpdatingArrayOfExistingCats
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSArray *array = [RKTestFixture parsedObjectWithContentsOfFixture:@"ArrayOfHumans.json"];
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [humanMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"railsID"]];
    humanMapping.identificationAttributes = @[ @"railsID" ];
    NSMutableDictionary *mappingsDictionary = [NSMutableDictionary dictionary];
    [mappingsDictionary setObject:humanMapping forKey:@"human"];

    // Create instances that should match the fixture
    RKHuman *human1 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    human1.railsID = [NSNumber numberWithInt:201];
    RKHuman *human2 = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    human2.railsID = [NSNumber numberWithInt:202];
    [managedObjectStore.persistentStoreManagedObjectContext save:nil];

    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithObject:array mappingsDictionary:mappingsDictionary];
    RKFetchRequestManagedObjectCache *managedObjectCache = [[RKFetchRequestManagedObjectCache alloc] init];
    mapper.mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext
                                                                                                                  cache:managedObjectCache];
                                                                                                                  
    [mapper start];
    RKMappingResult *result = mapper.mappingResult;
    assertThat(result, is(notNilValue()));

    NSArray *humans = [result array];
    assertThat(humans, hasCountOf(2));
    assertThat([humans objectAtIndex:0], is(equalTo(human1)));
    assertThat([humans objectAtIndex:1], is(equalTo(human2)));
}

- (void)testMappingMultipleKeyPathsAtRootOfObject
{
    RKObjectMapping *mapping1 = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping1 addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"prodId" toKeyPath:@"userID"]];
    
    RKObjectMapping *mapping2 = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping2 addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"catId" toKeyPath:@"userID"]];
    
    NSDictionary *dictionary = [RKTestFixture parsedObjectWithContentsOfFixture:@"SameKeyDifferentTargetClasses.json"];
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithObject:dictionary mappingsDictionary:@{ @"products": mapping1, @"categories": mapping2 }];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    mapper.mappingOperationDataSource = dataSource;
    [mapper start];
    
    expect(mapper.error).to.beNil();
    expect(mapper.mappingResult).notTo.beNil();
    expect([mapper.mappingResult array]).to.haveCountOf(4);
}

@end
