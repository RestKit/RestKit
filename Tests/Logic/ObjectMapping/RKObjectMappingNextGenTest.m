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
#import "RKObjectMappingOperation.h"
#import "RKObjectAttributeMapping.h"
#import "RKObjectRelationshipMapping.h"
#import "RKLog.h"
#import "RKObjectMapper.h"
#import "RKObjectMapper_Private.h"
#import "RKObjectMapperError.h"
#import "RKDynamicMappingModels.h"
#import "RKTestAddress.h"
#import "RKTestUser.h"
#import "RKObjectMappingProvider+Contexts.h"

// Managed Object Serialization Testific
#import "RKHuman.h"
#import "RKCat.h"

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
    return [[self new] autorelease];
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
    return [[self new] autorelease];
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
    RKObjectAttributeMapping *elementMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    assertThat(elementMapping.sourceKeyPath, is(equalTo(@"id")));
    assertThat(elementMapping.destinationKeyPath, is(equalTo(@"userID")));
}

- (void)testShouldDescribeElementMappings
{
    RKObjectAttributeMapping *elementMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    assertThat([elementMapping description], is(equalTo(@"RKObjectKeyPathMapping: id => userID")));
}

#pragma mark - RKObjectMapping Tests

- (void)testShouldDefineMappingFromAnElementToAProperty
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    assertThat([mapping mappingForKeyPath:@"id"], is(sameInstance(idMapping)));
}

- (void)testShouldAddMappingsToAttributeMappings
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    assertThatBool([mapping.mappings containsObject:idMapping], is(equalToBool(YES)));
    assertThatBool([mapping.attributeMappings containsObject:idMapping], is(equalToBool(YES)));
}

- (void)testShouldAddMappingsToRelationshipMappings
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectRelationshipMapping *idMapping = [RKObjectRelationshipMapping mappingFromKeyPath:@"id" toKeyPath:@"userID" withMapping:nil];
    [mapping addRelationshipMapping:idMapping];
    assertThatBool([mapping.mappings containsObject:idMapping], is(equalToBool(YES)));
    assertThatBool([mapping.relationshipMappings containsObject:idMapping], is(equalToBool(YES)));
}

- (void)testShouldGenerateAttributeMappings
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    assertThat([mapping mappingForKeyPath:@"name"], is(nilValue()));
    [mapping mapKeyPath:@"name" toAttribute:@"name"];
    assertThat([mapping mappingForKeyPath:@"name"], isNot(nilValue()));
}

- (void)testShouldGenerateRelationshipMappings
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectMapping *anotherMapping = [RKObjectMapping mappingForClass:[NSDictionary class]];
    assertThat([mapping mappingForKeyPath:@"another"], is(nilValue()));
    [mapping mapRelationship:@"another" withMapping:anotherMapping];
    assertThat([mapping mappingForKeyPath:@"another"], isNot(nilValue()));
}

- (void)testShouldRemoveMappings
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    assertThat(mapping.mappings, hasItem(idMapping));
    [mapping removeMapping:idMapping];
    assertThat(mapping.mappings, isNot(hasItem(idMapping)));
}

- (void)testShouldRemoveMappingsByKeyPath
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    assertThat(mapping.mappings, hasItem(idMapping));
    [mapping removeMappingForKeyPath:@"id"];
    assertThat(mapping.mappings, isNot(hasItem(idMapping)));
}

- (void)testShouldRemoveAllMappings
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping mapAttributes:@"one", @"two", @"three", nil];
    assertThat(mapping.mappings, hasCountOf(3));
    [mapping removeAllMappings];
    assertThat(mapping.mappings, is(empty()));
}

- (void)testShouldGenerateAnInverseMappings
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping mapKeyPath:@"first_name" toAttribute:@"firstName"];
    [mapping mapAttributes:@"city", @"state", @"zip", nil];
    RKObjectMapping *otherMapping = [RKObjectMapping mappingForClass:[RKTestAddress class]];
    [otherMapping mapAttributes:@"street", nil];
    [mapping mapRelationship:@"address" withMapping:otherMapping];
    RKObjectMapping *inverse = [mapping inverseMapping];
    assertThat(inverse.objectClass, is(equalTo([NSMutableDictionary class])));
    assertThat([inverse mappingForKeyPath:@"firstName"], isNot(nilValue()));
}

- (void)testShouldLetYouRetrieveMappingsByAttribute
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *attributeMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"nameAttribute"];
    [mapping addAttributeMapping:attributeMapping];
    assertThat([mapping mappingForAttribute:@"nameAttribute"], is(equalTo(attributeMapping)));
}

- (void)testShouldLetYouRetrieveMappingsByRelationship
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectRelationshipMapping *relationshipMapping = [RKObjectRelationshipMapping mappingFromKeyPath:@"friend" toKeyPath:@"friendRelationship" withMapping:mapping];
    [mapping addRelationshipMapping:relationshipMapping];
    assertThat([mapping mappingForRelationship:@"friendRelationship"], is(equalTo(relationshipMapping)));
}

#pragma mark - RKObjectMapper Tests

- (void)testShouldPerformBasicMapping
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    RKObjectAttributeMapping *nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];

    RKObjectMapper *mapper = [RKObjectMapper new];
    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKTestUser *user = [RKTestUser user];
    BOOL success = [mapper mapFromObject:userInfo toObject:user atKeyPath:@"" usingMapping:mapping];
    [mapper release];
    assertThatBool(success, is(equalToBool(YES)));
    assertThatInt([user.userID intValue], is(equalToInt(31337)));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
}

- (void)testShouldMapACollectionOfSimpleObjectDictionaries
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    RKObjectAttributeMapping *nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];

    RKObjectMapper *mapper = [RKObjectMapper new];
    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"users.json"];
    NSArray *users = [mapper mapCollection:userInfo atKeyPath:@"" usingMapping:mapping];
    assertThatUnsignedInteger([users count], is(equalToInt(3)));
    RKTestUser *blake = [users objectAtIndex:0];
    assertThat(blake.name, is(equalTo(@"Blake Watters")));
    [mapper release];
}

- (void)testShouldDetermineTheObjectMappingByConsultingTheMappingProviderWhenThereIsATargetObject
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectMappingProvider *provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];
    id mockProvider = [OCMockObject partialMockForObject:provider];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    mapper.targetObject = [RKTestUser user];
    [mapper performMapping];

    [mockProvider verify];
}

- (void)testShouldAddAnErrorWhenTheKeyPathMappingAndObjectClassDoNotAgree
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectMappingProvider *provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];
    id mockProvider = [OCMockObject partialMockForObject:provider];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    mapper.targetObject = [NSDictionary new];
    [mapper performMapping];
    assertThatUnsignedInteger([mapper errorCount], is(equalToInt(1)));
}

- (void)testShouldMapToATargetObject
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    RKObjectAttributeMapping *nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];

    RKObjectMappingProvider *provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];
    id mockProvider = [OCMockObject partialMockForObject:provider];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    RKTestUser *user = [RKTestUser user];
    mapper.targetObject = user;
    RKObjectMappingResult *result = [mapper performMapping];

    [mockProvider verify];
    assertThat(result, isNot(nilValue()));
    assertThatBool([result asObject] == user, is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
}

- (void)testShouldCreateANewInstanceOfTheAppropriateDestinationObjectWhenThereIsNoTargetObject
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];

    RKObjectMappingProvider *provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];
    id mockProvider = [OCMockObject partialMockForObject:provider];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    id mappingResult = [[mapper performMapping] asObject];
    assertThatBool([mappingResult isKindOfClass:[RKTestUser class]], is(equalToBool(YES)));
}

- (void)testShouldDetermineTheMappingClassForAKeyPathByConsultingTheMappingProviderWhenMappingADictionaryWithoutATargetObject
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectMappingProvider *provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];
    id mockProvider = [OCMockObject partialMockForObject:provider];
    [[mockProvider expect] valueForContext:RKObjectMappingProviderContextObjectsByKeyPath];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    [mapper performMapping];
    [mockProvider verify];
}

- (void)testShouldMapWithoutATargetMapping
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    RKObjectAttributeMapping *nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];

    RKObjectMappingProvider *provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];
    id mockProvider = [OCMockObject partialMockForObject:provider];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    RKTestUser *user = [[mapper performMapping] asObject];
    assertThatBool([user isKindOfClass:[RKTestUser class]], is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
}

- (void)testShouldMapACollectionOfObjects
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    RKObjectAttributeMapping *nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    RKObjectMappingProvider *provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"users.json"];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    RKObjectMappingResult *result = [mapper performMapping];
    NSArray *users = [result asCollection];
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
    [mapping mapKeyOfNestedDictionaryToAttribute:@"name"];
    RKObjectAttributeMapping *idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"(name).id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    RKObjectMappingProvider *provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@"users"];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"DynamicKeys.json"];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    RKObjectMappingResult *result = [mapper performMapping];
    NSArray *users = [result asCollection];
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
    [mapping mapKeyOfNestedDictionaryToAttribute:@"name"];

    RKObjectMapping *addressMapping = [RKObjectMapping mappingForClass:[RKTestAddress class]];
    [addressMapping mapAttributes:@"city", @"state", nil];
    [mapping mapKeyPath:@"(name).address" toRelationship:@"address" withMapping:addressMapping];
    RKObjectMappingProvider *provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@"users"];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"DynamicKeysWithRelationship.json"];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    RKObjectMappingResult *result = [mapper performMapping];
    NSArray *users = [result asCollection];
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
    [mapping mapAttributes:@"name", nil];


    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    userMapping.forceCollectionMapping = YES;
    [userMapping mapKeyOfNestedDictionaryToAttribute:@"name"];
    [mapping mapKeyPath:@"users" toRelationship:@"users" withMapping:userMapping];

    RKObjectMapping *addressMapping = [RKObjectMapping mappingForClass:[RKTestAddress class]];
    [addressMapping mapAttributes:
        @"city", @"city",
        @"state", @"state",
        @"country", @"country",
        nil
     ];
    [userMapping mapKeyPath:@"(name).address" toRelationship:@"address" withMapping:addressMapping];
    RKObjectMappingProvider *provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@"groups"];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"DynamicKeysWithNestedRelationship.json"];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    RKObjectMappingResult *result = [mapper performMapping];

    NSArray *groups = [result asCollection];
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
    [mapping mapAttributes:@"name", nil];


    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    userMapping.forceCollectionMapping = YES;
    [userMapping mapKeyOfNestedDictionaryToAttribute:@"name"];
    [mapping mapKeyPath:@"users" toRelationship:@"users" withMapping:userMapping];

    RKObjectMapping *addressMapping = [RKObjectMapping mappingForClass:[RKTestAddress class]];
    [addressMapping mapAttributes:
        @"city", @"city",
        @"state", @"state",
        @"country", @"country",
        nil
    ];
    [userMapping mapKeyPath:@"(name).address" toRelationship:@"address" withMapping:addressMapping];
    RKObjectMappingProvider *provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@"groups"];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"DynamicKeysWithNestedRelationship.json"];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    RKObjectMappingResult *result = [mapper performMapping];

    NSArray *groups = [result asCollection];
    assertThatBool([groups isKindOfClass:[NSArray class]], is(equalToBool(YES)));
    assertThatUnsignedInteger([groups count], is(equalToInt(2)));

    RKExampleGroupWithUserSet *group = [groups objectAtIndex:0];
    assertThatBool([group isKindOfClass:[RKExampleGroupWithUserSet class]], is(equalToBool(YES)));
    assertThat(group.name, is(equalTo(@"restkit")));


    NSSortDescriptor *sortByName = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease];
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
    RKObjectAttributeMapping *idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"userID" toKeyPath:@"id"];
    [mapping addAttributeMapping:idMapping];
    RKObjectAttributeMapping *nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    RKObjectMappingProvider *provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];

    RKTestUser *user = [RKTestUser user];
    user.name = @"Blake Watters";
    user.userID = [NSNumber numberWithInt:123];

    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:user mappingProvider:provider];
    RKObjectMappingResult *result = [mapper performMapping];
    NSDictionary *userInfo = [result asObject];
    assertThatBool([userInfo isKindOfClass:[NSDictionary class]], is(equalToBool(YES)));
    assertThat([userInfo valueForKey:@"name"], is(equalTo(@"Blake Watters")));
}

- (void)testShouldMapRegisteredSubKeyPathsOfAnUnmappableDictionaryAndReturnTheResults
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    RKObjectAttributeMapping *nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    RKObjectMappingProvider *provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@"user"];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"nested_user.json"];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    NSDictionary *dictionary = [[mapper performMapping] asDictionary];
    assertThatBool([dictionary isKindOfClass:[NSDictionary class]], is(equalToBool(YES)));
    RKTestUser *user = [dictionary objectForKey:@"user"];
    assertThat(user, isNot(nilValue()));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
}

#pragma mark Mapping Error States

- (void)testShouldAddAnErrorWhenYouTryToMapAnArrayToATargetObject
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    RKObjectAttributeMapping *nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    RKObjectMappingProvider *provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"users.json"];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    mapper.targetObject = [RKTestUser user];
    [mapper performMapping];
    assertThatUnsignedInteger([mapper errorCount], is(equalToInt(1)));
    assertThatInteger([[mapper.errors objectAtIndex:0] code], is(equalToInt(RKObjectMapperErrorObjectMappingTypeMismatch)));
}

- (void)testShouldAddAnErrorWhenAttemptingToMapADictionaryWithoutAnObjectMapping
{
    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKObjectMappingProvider *provider = [[RKObjectMappingProvider new] autorelease];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    [mapper performMapping];
    assertThatUnsignedInteger([mapper errorCount], is(equalToInt(1)));
    assertThat([[mapper.errors objectAtIndex:0] localizedDescription], is(equalTo(@"Could not find an object mapping for keyPath: ''")));
}

- (void)testShouldAddAnErrorWhenAttemptingToMapACollectionWithoutAnObjectMapping
{
    RKObjectMappingProvider *provider = [[RKObjectMappingProvider new] autorelease];
    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"users.json"];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    [mapper performMapping];
    assertThatUnsignedInteger([mapper errorCount], is(equalToInt(1)));
    assertThat([[mapper.errors objectAtIndex:0] localizedDescription], is(equalTo(@"Could not find an object mapping for keyPath: ''")));
}

#pragma mark RKObjectMapperDelegate Tests

- (void)testShouldInformTheDelegateWhenMappingBegins
{
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKObjectMapperDelegate)];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectMappingProvider *provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"users.json"];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    [[mockDelegate expect] objectMapperWillBeginMapping:mapper];
    mapper.delegate = mockDelegate;
    [mapper performMapping];
    [mockDelegate verify];
}

- (void)testShouldInformTheDelegateWhenMappingEnds
{
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKObjectMapperDelegate)];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectMappingProvider *provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"users.json"];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    [[mockDelegate stub] objectMapperWillBeginMapping:mapper];
    [[mockDelegate expect] objectMapperDidFinishMapping:mapper];
    mapper.delegate = mockDelegate;
    [mapper performMapping];
    [mockDelegate verify];
}

- (void)testShouldInformTheDelegateWhenCheckingForObjectMappingForKeyPathIsSuccessful
{
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKObjectMapperDelegate)];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectMappingProvider *provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    [[mockDelegate expect] objectMapper:mapper didFindMappableObject:[OCMArg any] atKeyPath:@""withMapping:mapping];
    mapper.delegate = mockDelegate;
    [mapper performMapping];
    [mockDelegate verify];
}

- (void)testShouldInformTheDelegateWhenCheckingForObjectMappingForKeyPathIsNotSuccessful
{
    RKObjectMappingProvider *provider = [[RKObjectMappingProvider new] autorelease];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [provider setMapping:mapping forKeyPath:@"users"];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKObjectMapperDelegate)];
    [[mockDelegate expect] objectMapper:mapper didNotFindMappableObjectAtKeyPath:@"users"];
    mapper.delegate = mockDelegate;
    [mapper performMapping];
    [mockDelegate verify];
}

- (void)testShouldInformTheDelegateOfError
{
    id mockProvider = [OCMockObject niceMockForClass:[RKObjectMappingProvider class]];
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKObjectMapperDelegate)];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"users.json"];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    [[mockDelegate expect] objectMapper:mapper didAddError:[OCMArg isNotNil]];
    mapper.delegate = mockDelegate;
    [mapper performMapping];
    [mockDelegate verify];
}

- (void)testShouldNotifyTheDelegateWhenItWillMapAnObject
{
    RKObjectMappingProvider *provider = [[RKObjectMappingProvider new] autorelease];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [provider setMapping:mapping forKeyPath:@""];
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKObjectMapperDelegate)];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    [[mockDelegate expect] objectMapper:mapper willMapFromObject:userInfo toObject:[OCMArg any] atKeyPath:@"" usingMapping:mapping];
    mapper.delegate = mockDelegate;
    [mapper performMapping];
    [mockDelegate verify];
}

- (void)testShouldNotifyTheDelegateWhenItDidMapAnObject
{
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKObjectMapperDelegate)];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];
    RKObjectMappingProvider *provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    [[mockDelegate expect] objectMapper:mapper didMapFromObject:userInfo toObject:[OCMArg any] atKeyPath:@"" usingMapping:mapping];
    mapper.delegate = mockDelegate;
    [mapper performMapping];
    [mockDelegate verify];
}

- (BOOL)fakeValidateValue:(inout id *)ioValue forKeyPath:(NSString *)inKey error:(out NSError **)outError
{
    *outError = [NSError errorWithDomain:RKErrorDomain code:1234 userInfo:nil];
    return NO;
}

- (void)testShouldNotifyTheDelegateWhenItFailedToMapAnObject
{
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKObjectMapperDelegate)];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:NSClassFromString(@"OCPartialMockObject")];
    [mapping mapAttributes:@"name", nil];
    RKObjectMappingProvider *provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:mapping forKeyPath:@""];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    RKTestUser *exampleUser = [[RKTestUser new] autorelease];
    id mockObject = [OCMockObject partialMockForObject:exampleUser];
    [[[mockObject expect] andCall:@selector(fakeValidateValue:forKeyPath:error:) onObject:self] validateValue:[OCMArg anyPointer] forKeyPath:OCMOCK_ANY error:[OCMArg anyPointer]];
    mapper.targetObject = mockObject;
    [[mockDelegate expect] objectMapper:mapper didFailMappingFromObject:userInfo toObject:[OCMArg any] withError:[OCMArg any] atKeyPath:@"" usingMapping:mapping];
    mapper.delegate = mockDelegate;
    [mapper performMapping];
    [mockObject verify];
    [mockDelegate verify];
}

#pragma mark - RKObjectMappingOperationTests

- (void)testShouldBeAbleToMapADictionaryToAUser
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKObjectAttributeMapping *idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    RKObjectAttributeMapping *nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];

    NSMutableDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:123], @"id", @"Blake Watters", @"name", nil];
    RKTestUser *user = [RKTestUser user];

    RKObjectMappingOperation *operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    [operation performMapping:nil];
    assertThat(user.name, is(equalTo(@"Blake Watters")));
    assertThatInt([user.userID intValue], is(equalToInt(123)));
    [operation release];
}

- (void)testShouldConsiderADictionaryContainingOnlyNullValuesForKeysMappable
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKObjectAttributeMapping *idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    RKObjectAttributeMapping *nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];

    NSMutableDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSNull null], @"name", nil];
    RKTestUser *user = [RKTestUser user];

    RKObjectMappingOperation *operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    BOOL success = [operation performMapping:nil];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(user.name, is(nilValue()));
    [operation release];
}

- (void)testShouldBeAbleToMapAUserToADictionary
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKObjectAttributeMapping *idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"userID" toKeyPath:@"id"];
    [mapping addAttributeMapping:idMapping];
    RKObjectAttributeMapping *nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];

    RKTestUser *user = [RKTestUser user];
    user.name = @"Blake Watters";
    user.userID = [NSNumber numberWithInt:123];

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    RKObjectMappingOperation *operation = [[RKObjectMappingOperation alloc] initWithSourceObject:user destinationObject:dictionary mapping:mapping];
    BOOL success = [operation performMapping:nil];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat([dictionary valueForKey:@"name"], is(equalTo(@"Blake Watters")));
    assertThatInt([[dictionary valueForKey:@"id"] intValue], is(equalToInt(123)));
    [operation release];
}

- (void)testShouldReturnNoWithoutErrorWhenGivenASourceObjectThatContainsNoMappableKeys
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKObjectAttributeMapping *idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    RKObjectAttributeMapping *nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];

    NSMutableDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"blue", @"favorite_color", @"coffee", @"preferred_beverage", nil];
    RKTestUser *user = [RKTestUser user];

    RKObjectMappingOperation *operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(NO)));
    assertThat(error, is(nilValue()));
    [operation release];
}

- (void)testShouldInformTheDelegateOfAnErrorWhenMappingFailsBecauseThereIsNoMappableContent
{
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKObjectMappingOperationDelegate)];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKObjectAttributeMapping *idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    RKObjectAttributeMapping *nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];

    NSMutableDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"blue", @"favorite_color", @"coffee", @"preferred_beverage", nil];
    RKTestUser *user = [RKTestUser user];

    RKObjectMappingOperation *operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    operation.delegate = mockDelegate;
    BOOL success = [operation performMapping:nil];
    assertThatBool(success, is(equalToBool(NO)));
    [mockDelegate verify];
}

- (void)testShouldSetTheErrorWhenMappingOperationFails
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKObjectAttributeMapping *idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    [mapping addAttributeMapping:idMapping];
    RKObjectAttributeMapping *nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];

    NSMutableDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"FAILURE", @"id", nil];
    RKTestUser *user = [RKTestUser user];
    id mockObject = [OCMockObject partialMockForObject:user];
    [[[mockObject expect] andCall:@selector(fakeValidateValue:forKeyPath:error:) onObject:self] validateValue:[OCMArg anyPointer] forKeyPath:OCMOCK_ANY error:[OCMArg anyPointer]];

    RKObjectMappingOperation *operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:mockObject mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];
    assertThat(error, isNot(nilValue()));
    [operation release];
}

#pragma mark - Attribute Mapping

- (void)testShouldMapAStringToADateAttribute
{
    [RKObjectMapping setDefaultDateFormatters:nil];

    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *birthDateMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"birthdate" toKeyPath:@"birthDate"];
    [mapping addAttributeMapping:birthDateMapping];

    NSDictionary *dictionary = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKTestUser *user = [RKTestUser user];
    RKObjectMappingOperation *operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];

    NSDateFormatter *dateFormatter = [[NSDateFormatter new] autorelease];
    dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];
    assertThat([dateFormatter stringFromDate:user.birthDate], is(equalTo(@"11/27/1982")));
}

- (void)testShouldMapStringToURL
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *websiteMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"website" toKeyPath:@"website"];
    [mapping addAttributeMapping:websiteMapping];

    NSDictionary *dictionary = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKTestUser *user = [RKTestUser user];
    RKObjectMappingOperation *operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];

    assertThat(user.website, isNot(nilValue()));
    assertThatBool([user.website isKindOfClass:[NSURL class]], is(equalToBool(YES)));
    assertThat([user.website absoluteString], is(equalTo(@"http://restkit.org/")));
}

- (void)testShouldMapAStringToANumberBool
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *websiteMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"is_developer" toKeyPath:@"isDeveloper"];
    [mapping addAttributeMapping:websiteMapping];

    NSDictionary *dictionary = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKTestUser *user = [RKTestUser user];
    RKObjectMappingOperation *operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];

    assertThatBool([[user isDeveloper] boolValue], is(equalToBool(YES)));
}

- (void)testShouldMapAShortTrueStringToANumberBool
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *websiteMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"is_developer" toKeyPath:@"isDeveloper"];
    [mapping addAttributeMapping:websiteMapping];

    NSDictionary *dictionary = [[RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    RKTestUser *user = [RKTestUser user];
    [dictionary setValue:@"T" forKey:@"is_developer"];
    RKObjectMappingOperation *operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];

    assertThatBool([[user isDeveloper] boolValue], is(equalToBool(YES)));
}

- (void)testShouldMapAShortFalseStringToANumberBool
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *websiteMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"is_developer" toKeyPath:@"isDeveloper"];
    [mapping addAttributeMapping:websiteMapping];

    NSDictionary *dictionary = [[RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    RKTestUser *user = [RKTestUser user];
    [dictionary setValue:@"f" forKey:@"is_developer"];
    RKObjectMappingOperation *operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];

    assertThatBool([[user isDeveloper] boolValue], is(equalToBool(NO)));
}

- (void)testShouldMapAYesStringToANumberBool
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *websiteMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"is_developer" toKeyPath:@"isDeveloper"];
    [mapping addAttributeMapping:websiteMapping];

    NSDictionary *dictionary = [[RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    RKTestUser *user = [RKTestUser user];
    [dictionary setValue:@"yes" forKey:@"is_developer"];
    RKObjectMappingOperation *operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];

    assertThatBool([[user isDeveloper] boolValue], is(equalToBool(YES)));
}

- (void)testShouldMapANoStringToANumberBool
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *websiteMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"is_developer" toKeyPath:@"isDeveloper"];
    [mapping addAttributeMapping:websiteMapping];

    NSDictionary *dictionary = [[RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    RKTestUser *user = [RKTestUser user];
    [dictionary setValue:@"NO" forKey:@"is_developer"];
    RKObjectMappingOperation *operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];

    assertThatBool([[user isDeveloper] boolValue], is(equalToBool(NO)));
}

- (void)testShouldMapAStringToANumber
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *websiteMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"lucky_number" toKeyPath:@"luckyNumber"];
    [mapping addAttributeMapping:websiteMapping];

    NSDictionary *dictionary = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKTestUser *user = [RKTestUser user];
    RKObjectMappingOperation *operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];

    assertThatInt([user.luckyNumber intValue], is(equalToInt(187)));
}

- (void)testShouldMapAStringToADecimalNumber
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *websiteMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"weight" toKeyPath:@"weight"];
    [mapping addAttributeMapping:websiteMapping];

    NSDictionary *dictionary = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKTestUser *user = [RKTestUser user];
    RKObjectMappingOperation *operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];

    NSDecimalNumber *weight = user.weight;
    assertThatBool([weight isKindOfClass:[NSDecimalNumber class]], is(equalToBool(YES)));
    assertThatInteger([weight compare:[NSDecimalNumber decimalNumberWithString:@"131.3"]], is(equalToInt(NSOrderedSame)));
}

- (void)testShouldMapANumberToAString
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *websiteMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"lucky_number" toKeyPath:@"name"];
    [mapping addAttributeMapping:websiteMapping];

    NSDictionary *dictionary = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKTestUser *user = [RKTestUser user];
    RKObjectMappingOperation *operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];

    assertThat(user.name, is(equalTo(@"187")));
}

- (void)testShouldMapANumberToANSDecimalNumber
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *websiteMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"lucky_number" toKeyPath:@"weight"];
    [mapping addAttributeMapping:websiteMapping];

    NSDictionary *dictionary = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKTestUser *user = [RKTestUser user];
    RKObjectMappingOperation *operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];

    NSDecimalNumber *weight = user.weight;
    assertThatBool([weight isKindOfClass:[NSDecimalNumber class]], is(equalToBool(YES)));
    assertThatInteger([weight compare:[NSDecimalNumber decimalNumberWithString:@"187"]], is(equalToInt(NSOrderedSame)));
}

- (void)testShouldMapANumberToADate
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter new] autorelease];
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];
    NSDate *date = [dateFormatter dateFromString:@"11/27/1982"];

    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *birthDateMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"dateAsNumber" toKeyPath:@"birthDate"];
    [mapping addAttributeMapping:birthDateMapping];

    NSMutableDictionary *dictionary = [[RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    [dictionary setValue:[NSNumber numberWithInt:[date timeIntervalSince1970]] forKey:@"dateAsNumber"];
    RKTestUser *user = [RKTestUser user];
    RKObjectMappingOperation *operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];

    assertThat([dateFormatter stringFromDate:user.birthDate], is(equalTo(@"11/27/1982")));
}

- (void)testShouldMapANestedKeyPathToAnAttribute
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *countryMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"address.country" toKeyPath:@"country"];
    [mapping addAttributeMapping:countryMapping];

    NSDictionary *dictionary = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKTestUser *user = [RKTestUser user];
    RKObjectMappingOperation *operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];

    assertThat(user.country, is(equalTo(@"USA")));
}

- (void)testShouldMapANestedArrayOfStringsToAnAttribute
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *countryMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"interests" toKeyPath:@"interests"];
    [mapping addAttributeMapping:countryMapping];

    NSDictionary *dictionary = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKTestUser *user = [RKTestUser user];
    RKObjectMappingOperation *operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];

    NSArray *interests = [NSArray arrayWithObjects:@"Hacking", @"Running", nil];
    assertThat(user.interests, is(equalTo(interests)));
}

- (void)testShouldMapANestedDictionaryToAnAttribute
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *countryMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"address" toKeyPath:@"addressDictionary"];
    [mapping addAttributeMapping:countryMapping];

    NSDictionary *dictionary = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKTestUser *user = [RKTestUser user];
    RKObjectMappingOperation *operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];

    NSDictionary *address = [NSDictionary dictionaryWithKeysAndObjects:
                             @"city", @"Carrboro",
                             @"state", @"North Carolina",
                             @"id", [NSNumber numberWithInt:1234],
                             @"country", @"USA", nil];
    assertThat(user.addressDictionary, is(equalTo(address)));
}

- (void)testShouldNotSetAPropertyWhenTheValueIsTheSame
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];

    NSDictionary *dictionary = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKTestUser *user = [RKTestUser user];
    user.name = @"Blake Watters";
    id mockUser = [OCMockObject partialMockForObject:user];
    [[mockUser reject] setName:OCMOCK_ANY];
    RKObjectMappingOperation *operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];
}

- (void)testShouldNotSetTheDestinationPropertyWhenBothAreNil
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];

    NSMutableDictionary *dictionary = [[RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    [dictionary setValue:[NSNull null] forKey:@"name"];
    RKTestUser *user = [RKTestUser user];
    user.name = nil;
    id mockUser = [OCMockObject partialMockForObject:user];
    [[mockUser reject] setName:OCMOCK_ANY];
    RKObjectMappingOperation *operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];
}

- (void)testShouldSetNilForNSNullValues
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];

    NSDictionary *dictionary = [[RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    [dictionary setValue:[NSNull null] forKey:@"name"];
    RKTestUser *user = [RKTestUser user];
    user.name = @"Blake Watters";
    id mockUser = [OCMockObject partialMockForObject:user];
    [[mockUser expect] setName:nil];
    RKObjectMappingOperation *operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];
    [mockUser verify];
}

- (void)testDelegateIsInformedWhenANilValueIsMappedForNSNullWithExistingValue
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];

    NSDictionary *dictionary = [[RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    [dictionary setValue:[NSNull null] forKey:@"name"];
    RKTestUser *user = [RKTestUser user];
    user.name = @"Blake Watters";
    id mockDelegate = [OCMockObject mockForProtocol:@protocol(RKObjectMappingOperationDelegate)];
    RKObjectMappingOperation *operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    operation.delegate = mockDelegate;
    NSError *error = nil;
    [[mockDelegate expect] objectMappingOperation:operation didFindMapping:nameMapping forKeyPath:@"name"];
    [[mockDelegate expect] objectMappingOperation:operation didSetValue:nil forKeyPath:@"name" usingMapping:nameMapping];
    [operation performMapping:&error];
    [mockDelegate verify];
}

- (void)testDelegateIsInformedWhenUnchangedValueIsSkipped
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];

    NSDictionary *dictionary = [[RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    [dictionary setValue:@"Blake Watters" forKey:@"name"];
    RKTestUser *user = [RKTestUser user];
    user.name = @"Blake Watters";
    id mockDelegate = [OCMockObject mockForProtocol:@protocol(RKObjectMappingOperationDelegate)];
    RKObjectMappingOperation *operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    operation.delegate = mockDelegate;
    NSError *error = nil;
    [[mockDelegate expect] objectMappingOperation:operation didFindMapping:nameMapping forKeyPath:@"name"];
    [[mockDelegate expect] objectMappingOperation:operation didNotSetUnchangedValue:@"Blake Watters" forKeyPath:@"name" usingMapping:nameMapping];
    [operation performMapping:&error];
    [mockDelegate verify];
}

- (void)testShouldOptionallySetDefaultValueForAMissingKeyPath
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];

    NSMutableDictionary *dictionary = [[RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    [dictionary removeObjectForKey:@"name"];
    RKTestUser *user = [RKTestUser user];
    user.name = @"Blake Watters";
    id mockUser = [OCMockObject partialMockForObject:user];
    [[mockUser expect] setName:nil];
    RKObjectMappingOperation *operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
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
    RKObjectAttributeMapping *nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [mapping addAttributeMapping:nameMapping];

    NSMutableDictionary *dictionary = [[RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    [dictionary removeObjectForKey:@"name"];
    RKTestUser *user = [RKTestUser user];
    user.name = @"Blake Watters";
    id mockUser = [OCMockObject partialMockForObject:user];
    [[mockUser reject] setName:nil];
    RKObjectMappingOperation *operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    id mockMapping = [OCMockObject partialMockForObject:mapping];
    BOOL returnValue = NO;
    [[[mockMapping expect] andReturnValue:OCMOCK_VALUE(returnValue)] shouldSetDefaultValueForMissingAttributes];
    NSError *error = nil;
    [operation performMapping:&error];
    assertThat(user.name, is(equalTo(@"Blake Watters")));
}

#pragma mark - Relationship Mapping

- (void)testShouldMapANestedObject
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addAttributeMapping:nameMapping];
    RKObjectMapping *addressMapping = [RKObjectMapping mappingForClass:[RKTestAddress class]];
    RKObjectAttributeMapping *cityMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"city" toKeyPath:@"city"];
    [addressMapping addAttributeMapping:cityMapping];

    RKObjectRelationshipMapping *hasOneMapping = [RKObjectRelationshipMapping mappingFromKeyPath:@"address" toKeyPath:@"address" withMapping:addressMapping];
    [userMapping addRelationshipMapping:hasOneMapping];

    RKObjectMapper *mapper = [RKObjectMapper new];
    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKTestUser *user = [RKTestUser user];
    BOOL success = [mapper mapFromObject:userInfo toObject:user atKeyPath:@"" usingMapping:userMapping];
    [mapper release];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
    assertThat(user.address, isNot(nilValue()));
}

- (void)testShouldMapANestedObjectToCollection
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addAttributeMapping:nameMapping];
    RKObjectMapping *addressMapping = [RKObjectMapping mappingForClass:[RKTestAddress class]];
    RKObjectAttributeMapping *cityMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"city" toKeyPath:@"city"];
    [addressMapping addAttributeMapping:cityMapping];

    RKObjectRelationshipMapping *hasOneMapping = [RKObjectRelationshipMapping mappingFromKeyPath:@"address" toKeyPath:@"friends" withMapping:addressMapping];
    [userMapping addRelationshipMapping:hasOneMapping];

    RKObjectMapper *mapper = [RKObjectMapper new];
    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKTestUser *user = [RKTestUser user];
    BOOL success = [mapper mapFromObject:userInfo toObject:user atKeyPath:@"" usingMapping:userMapping];
    [mapper release];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
    assertThat(user.friends, isNot(nilValue()));
    assertThatUnsignedInteger([user.friends count], is(equalToInt(1)));
}

- (void)testShouldMapANestedObjectToOrderedSetCollection
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addAttributeMapping:nameMapping];
    RKObjectMapping *addressMapping = [RKObjectMapping mappingForClass:[RKTestAddress class]];
    RKObjectAttributeMapping *cityMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"city" toKeyPath:@"city"];
    [addressMapping addAttributeMapping:cityMapping];

    RKObjectRelationshipMapping *hasOneMapping = [RKObjectRelationshipMapping mappingFromKeyPath:@"address" toKeyPath:@"friendsOrderedSet" withMapping:addressMapping];
    [userMapping addRelationshipMapping:hasOneMapping];

    RKObjectMapper *mapper = [RKObjectMapper new];
    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKTestUser *user = [RKTestUser user];
    BOOL success = [mapper mapFromObject:userInfo toObject:user atKeyPath:@"" usingMapping:userMapping];
    [mapper release];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
    assertThat(user.friendsOrderedSet, isNot(nilValue()));
    assertThatUnsignedInteger([user.friendsOrderedSet count], is(equalToInt(1)));
}

- (void)testShouldMapANestedObjectCollection
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addAttributeMapping:nameMapping];

    RKObjectRelationshipMapping *hasManyMapping = [RKObjectRelationshipMapping mappingFromKeyPath:@"friends" toKeyPath:@"friends" withMapping:userMapping];
    [userMapping addRelationshipMapping:hasManyMapping];

    RKObjectMapper *mapper = [RKObjectMapper new];
    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKTestUser *user = [RKTestUser user];
    BOOL success = [mapper mapFromObject:userInfo toObject:user atKeyPath:@"" usingMapping:userMapping];
    [mapper release];
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
    RKObjectAttributeMapping *nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addAttributeMapping:nameMapping];

    RKObjectRelationshipMapping *hasManyMapping = [RKObjectRelationshipMapping mappingFromKeyPath:@"friends" toKeyPath:@"friendsSet" withMapping:userMapping];
    [userMapping addRelationshipMapping:hasManyMapping];

    RKObjectMapper *mapper = [RKObjectMapper new];
    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKTestUser *user = [RKTestUser user];
    BOOL success = [mapper mapFromObject:userInfo toObject:user atKeyPath:@"" usingMapping:userMapping];
    [mapper release];
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
    RKObjectAttributeMapping *nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addAttributeMapping:nameMapping];

    RKObjectRelationshipMapping *hasManyMapping = [RKObjectRelationshipMapping mappingFromKeyPath:@"friends" toKeyPath:@"friendsOrderedSet" withMapping:userMapping];
    [userMapping addRelationshipMapping:hasManyMapping];

    RKObjectMapper *mapper = [RKObjectMapper new];
    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKTestUser *user = [RKTestUser user];
    BOOL success = [mapper mapFromObject:userInfo toObject:user atKeyPath:@"" usingMapping:userMapping];
    [mapper release];
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
    RKObjectAttributeMapping *nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addAttributeMapping:nameMapping];
    RKObjectMapping *addressMapping = [RKObjectMapping mappingForClass:[RKTestAddress class]];
    RKObjectAttributeMapping *idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"addressID"];
    [addressMapping addAttributeMapping:idMapping];

    RKObjectRelationshipMapping *hasOneMapping = [RKObjectRelationshipMapping mappingFromKeyPath:@"address" toKeyPath:@"address" withMapping:addressMapping];
    [userMapping addRelationshipMapping:hasOneMapping];

    RKObjectMapper *mapper = [RKObjectMapper new];
    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    [mapper mapFromObject:userInfo toObject:user atKeyPath:@"" usingMapping:userMapping];
    [mapper release];
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
    RKObjectAttributeMapping *nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addAttributeMapping:nameMapping];
    RKObjectMapping *addressMapping = [RKObjectMapping mappingForClass:[RKTestAddress class]];
    RKObjectAttributeMapping *idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"addressID"];
    [addressMapping addAttributeMapping:idMapping];

    RKObjectRelationshipMapping *hasOneMapping = [RKObjectRelationshipMapping mappingFromKeyPath:@"address" toKeyPath:@"address" withMapping:addressMapping];
    [userMapping addRelationshipMapping:hasOneMapping];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKObjectMappingOperation *operation = [RKObjectMappingOperation mappingOperationFromObject:userInfo toObject:user withMapping:userMapping];
    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKObjectMappingOperationDelegate)];
    [[mockDelegate expect] objectMappingOperation:operation didNotSetUnchangedValue:address forKeyPath:@"address" usingMapping:hasOneMapping];
    operation.delegate = mockDelegate;
    [operation performMapping:nil];
    [mockDelegate verify];
}

- (void)testShouldNotSetThePropertyWhenTheNestedObjectCollectionIsIdentical
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"userID"];
    RKObjectAttributeMapping *nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addAttributeMapping:idMapping];
    [userMapping addAttributeMapping:nameMapping];

    RKObjectRelationshipMapping *hasManyMapping = [RKObjectRelationshipMapping mappingFromKeyPath:@"friends" toKeyPath:@"friends" withMapping:userMapping];
    [userMapping addRelationshipMapping:hasManyMapping];

    RKObjectMapper *mapper = [RKObjectMapper new];
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
    [mapper release];
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
    RKObjectAttributeMapping *nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addAttributeMapping:nameMapping];
    RKObjectMapping *addressMapping = [RKObjectMapping mappingForClass:[RKTestAddress class]];
    RKObjectAttributeMapping *idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"addressID"];
    [addressMapping addAttributeMapping:idMapping];
    RKObjectRelationshipMapping *relationshipMapping = [RKObjectRelationshipMapping mappingFromKeyPath:@"address" toKeyPath:@"address" withMapping:addressMapping];
    [userMapping addRelationshipMapping:relationshipMapping];

    NSMutableDictionary *dictionary = [[RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    [dictionary removeObjectForKey:@"address"];
    id mockMapping = [OCMockObject partialMockForObject:userMapping];
    BOOL returnValue = YES;
    [[[mockMapping expect] andReturnValue:OCMOCK_VALUE(returnValue)] setNilForMissingRelationships];
    RKObjectMappingOperation *operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:mockUser mapping:mockMapping];

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
    RKObjectAttributeMapping *nameMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"];
    [userMapping addAttributeMapping:nameMapping];
    RKObjectMapping *addressMapping = [RKObjectMapping mappingForClass:[RKTestAddress class]];
    RKObjectAttributeMapping *idMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"addressID"];
    [addressMapping addAttributeMapping:idMapping];
    RKObjectRelationshipMapping *relationshipMapping = [RKObjectRelationshipMapping mappingFromKeyPath:@"address" toKeyPath:@"address" withMapping:addressMapping];
    [userMapping addRelationshipMapping:relationshipMapping];

    NSMutableDictionary *dictionary = [[RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"] mutableCopy];
    [dictionary removeObjectForKey:@"address"];
    id mockMapping = [OCMockObject partialMockForObject:userMapping];
    BOOL returnValue = YES;
    [[[mockMapping expect] andReturnValue:OCMOCK_VALUE(returnValue)] setNilForMissingRelationships];
    RKObjectMappingOperation *operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:mockUser mapping:mockMapping];

    NSError *error = nil;
    [operation performMapping:&error];
    [mockUser verify];
}

#pragma mark - RKObjectMappingProvider

- (void)testShouldRegisterRailsIdiomaticObjects
{
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping mapAttributes:@"name", @"website", nil];
    [mapping mapKeyPath:@"id" toAttribute:@"userID"];

    [objectManager.router routeClass:[RKTestUser class] toResourcePath:@"/humans/:userID"];
    [objectManager.router routeClass:[RKTestUser class] toResourcePath:@"/humans" forMethod:RKRequestMethodPOST];
    [objectManager.mappingProvider registerMapping:mapping withRootKeyPath:@"human"];

    RKTestUser *user = [RKTestUser new];
    user.userID = [NSNumber numberWithInt:1];

    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    loader.timeout = 5;
    [objectManager getObject:user delegate:loader];
    [loader waitForResponse];
    assertThatBool(loader.wasSuccessful, is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"Blake Watters")));

    [objectManager postObject:user delegate:loader];
    [loader waitForResponse];
    assertThatBool(loader.wasSuccessful, is(equalToBool(YES)));
    assertThat(user.name, is(equalTo(@"My Name")));
    assertThat(user.website, is(equalTo([NSURL URLWithString:@"http://restkit.org/"])));
}

- (void)testShouldReturnAllMappingsForAClass
{
    RKObjectMapping *firstMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectMapping *secondMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectMapping *thirdMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectMappingProvider *mappingProvider = [[RKObjectMappingProvider new] autorelease];
    [mappingProvider addObjectMapping:firstMapping];
    [mappingProvider addObjectMapping:secondMapping];
    [mappingProvider setMapping:thirdMapping forKeyPath:@"third"];
    assertThat([mappingProvider objectMappingsForClass:[RKTestUser class]], is(equalTo([NSArray arrayWithObjects:firstMapping, secondMapping, thirdMapping, nil])));
}

- (void)testShouldReturnAllMappingsForAClassAndNotExplodeWithRegisteredDynamicMappings
{
    RKObjectMappingProvider *provider = [[RKObjectMappingProvider new] autorelease];
    RKObjectMapping *boyMapping = [RKObjectMapping mappingForClass:[Boy class]];
    [boyMapping mapAttributes:@"name", nil];
    RKObjectMapping *girlMapping = [RKObjectMapping mappingForClass:[Girl class]];
    [girlMapping mapAttributes:@"name", nil];
    RKDynamicObjectMapping *dynamicMapping = [RKDynamicObjectMapping dynamicMapping];
    [dynamicMapping setObjectMapping:boyMapping whenValueOfKeyPath:@"type" isEqualTo:@"Boy"];
    [dynamicMapping setObjectMapping:girlMapping whenValueOfKeyPath:@"type" isEqualTo:@"Girl"];
    [provider setMapping:dynamicMapping forKeyPath:@"dynamic"];
    RKObjectMapping *firstMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectMapping *secondMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [provider addObjectMapping:firstMapping];
    [provider setMapping:secondMapping forKeyPath:@"second"];
    NSException *exception = nil;
    NSArray *actualMappings = nil;
    @try {
        actualMappings = [provider objectMappingsForClass:[RKTestUser class]];
    }
    @catch (NSException *e) {
        exception = e;
    }
    assertThat(exception, is(nilValue()));
    assertThat(actualMappings, is(equalTo([NSArray arrayWithObjects:firstMapping, secondMapping, nil])));
}

#pragma mark - RKDynamicObjectMapping

- (void)testShouldMapASingleObjectDynamically
{
    RKObjectMapping *boyMapping = [RKObjectMapping mappingForClass:[Boy class]];
    [boyMapping mapAttributes:@"name", nil];
    RKObjectMapping *girlMapping = [RKObjectMapping mappingForClass:[Girl class]];
    [girlMapping mapAttributes:@"name", nil];
    RKDynamicObjectMapping *dynamicMapping = [RKDynamicObjectMapping dynamicMapping];
    dynamicMapping.objectMappingForDataBlock = ^ RKObjectMapping *(id mappableData) {
        if ([[mappableData valueForKey:@"type"] isEqualToString:@"Boy"]) {
            return boyMapping;
        } else if ([[mappableData valueForKey:@"type"] isEqualToString:@"Girl"]) {
            return girlMapping;
        }

        return nil;
    };

    RKObjectMappingProvider *provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:dynamicMapping forKeyPath:@""];
    id mockProvider = [OCMockObject partialMockForObject:provider];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"boy.json"];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    Boy *user = [[mapper performMapping] asObject];
    assertThat(user, is(instanceOf([Boy class])));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
}

- (void)testShouldMapASingleObjectDynamicallyWithADeclarativeMatcher
{
    RKObjectMapping *boyMapping = [RKObjectMapping mappingForClass:[Boy class]];
    [boyMapping mapAttributes:@"name", nil];
    RKObjectMapping *girlMapping = [RKObjectMapping mappingForClass:[Girl class]];
    [girlMapping mapAttributes:@"name", nil];
    RKDynamicObjectMapping *dynamicMapping = [RKDynamicObjectMapping dynamicMapping];
    [dynamicMapping setObjectMapping:boyMapping whenValueOfKeyPath:@"type" isEqualTo:@"Boy"];
    [dynamicMapping setObjectMapping:girlMapping whenValueOfKeyPath:@"type" isEqualTo:@"Girl"];

    RKObjectMappingProvider *provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:dynamicMapping forKeyPath:@""];
    id mockProvider = [OCMockObject partialMockForObject:provider];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"boy.json"];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    Boy *user = [[mapper performMapping] asObject];
    assertThat(user, is(instanceOf([Boy class])));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
}

- (void)testShouldACollectionOfObjectsDynamically
{
    RKObjectMapping *boyMapping = [RKObjectMapping mappingForClass:[Boy class]];
    [boyMapping mapAttributes:@"name", nil];
    RKObjectMapping *girlMapping = [RKObjectMapping mappingForClass:[Girl class]];
    [girlMapping mapAttributes:@"name", nil];
    RKDynamicObjectMapping *dynamicMapping = [RKDynamicObjectMapping dynamicMapping];
    [dynamicMapping setObjectMapping:boyMapping whenValueOfKeyPath:@"type" isEqualTo:@"Boy"];
    [dynamicMapping setObjectMapping:girlMapping whenValueOfKeyPath:@"type" isEqualTo:@"Girl"];

    RKObjectMappingProvider *provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:dynamicMapping forKeyPath:@""];
    id mockProvider = [OCMockObject partialMockForObject:provider];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"mixed.json"];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    NSArray *objects = [[mapper performMapping] asCollection];
    assertThat(objects, hasCountOf(2));
    assertThat([objects objectAtIndex:0], is(instanceOf([Boy class])));
    assertThat([objects objectAtIndex:1], is(instanceOf([Girl class])));
    Boy *boy = [objects objectAtIndex:0];
    Girl *girl = [objects objectAtIndex:1];
    assertThat(boy.name, is(equalTo(@"Blake Watters")));
    assertThat(girl.name, is(equalTo(@"Sarah")));
}

- (void)testShouldMapARelationshipDynamically
{
    RKObjectMapping *boyMapping = [RKObjectMapping mappingForClass:[Boy class]];
    [boyMapping mapAttributes:@"name", nil];
    RKObjectMapping *girlMapping = [RKObjectMapping mappingForClass:[Girl class]];
    [girlMapping mapAttributes:@"name", nil];
    RKDynamicObjectMapping *dynamicMapping = [RKDynamicObjectMapping dynamicMapping];
    [dynamicMapping setObjectMapping:boyMapping whenValueOfKeyPath:@"type" isEqualTo:@"Boy"];
    [dynamicMapping setObjectMapping:girlMapping whenValueOfKeyPath:@"type" isEqualTo:@"Girl"];
    [boyMapping mapKeyPath:@"friends" toRelationship:@"friends" withMapping:dynamicMapping];

    RKObjectMappingProvider *provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:dynamicMapping forKeyPath:@""];
    id mockProvider = [OCMockObject partialMockForObject:provider];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"friends.json"];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    Boy *blake = [[mapper performMapping] asObject];
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
    [boyMapping mapAttributes:@"name", nil];
    RKObjectMapping *girlMapping = [RKObjectMapping mappingForClass:[Girl class]];
    [girlMapping mapAttributes:@"name", nil];
    RKDynamicObjectMapping *dynamicMapping = [RKDynamicObjectMapping dynamicMapping];
    dynamicMapping.objectMappingForDataBlock = ^ RKObjectMapping *(id mappableData) {
        if ([[mappableData valueForKey:@"type"] isEqualToString:@"Boy"]) {
            return boyMapping;
        } else if ([[mappableData valueForKey:@"type"] isEqualToString:@"Girl"]) {
            // NO GIRLS ALLOWED(*$!)(*
            return nil;
        }

        return nil;
    };

    RKObjectMappingProvider *provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:dynamicMapping forKeyPath:@""];
    id mockProvider = [OCMockObject partialMockForObject:provider];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"mixed.json"];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    NSArray *boys = [[mapper performMapping] asCollection];
    assertThat(boys, hasCountOf(1));
    Boy *user = [boys objectAtIndex:0];
    assertThat(user, is(instanceOf([Boy class])));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
}

- (void)testShouldBeAbleToDeclineMappingObjectsInARelationshipByReturningANilObjectMapping
{
    RKObjectMapping *boyMapping = [RKObjectMapping mappingForClass:[Boy class]];
    [boyMapping mapAttributes:@"name", nil];
    RKObjectMapping *girlMapping = [RKObjectMapping mappingForClass:[Girl class]];
    [girlMapping mapAttributes:@"name", nil];
    RKDynamicObjectMapping *dynamicMapping = [RKDynamicObjectMapping dynamicMapping];
    dynamicMapping.objectMappingForDataBlock = ^ RKObjectMapping *(id mappableData) {
        if ([[mappableData valueForKey:@"type"] isEqualToString:@"Boy"]) {
            return boyMapping;
        } else if ([[mappableData valueForKey:@"type"] isEqualToString:@"Girl"]) {
            // NO GIRLS ALLOWED(*$!)(*
            return nil;
        }

        return nil;
    };
    [boyMapping mapKeyPath:@"friends" toRelationship:@"friends" withMapping:dynamicMapping];

    RKObjectMappingProvider *provider = [[RKObjectMappingProvider new] autorelease];
    [provider setMapping:dynamicMapping forKeyPath:@""];
    id mockProvider = [OCMockObject partialMockForObject:provider];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"friends.json"];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:mockProvider];
    Boy *blake = [[mapper performMapping] asObject];
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
    [boyMapping mapAttributes:@"name", nil];
    RKDynamicObjectMapping *dynamicMapping = [RKDynamicObjectMapping dynamicMapping];
    dynamicMapping.objectMappingForDataBlock = ^ RKObjectMapping *(id mappableData) {
        if ([[mappableData valueForKey:@"type"] isEqualToString:@"Boy"]) {
            return boyMapping;
        }

        return nil;
    };

    RKObjectMappingProvider *provider = [RKObjectMappingProvider objectMappingProvider];
    [provider setMapping:dynamicMapping forKeyPath:@""];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"boy.json"];
    Boy *blake = [[Boy new] autorelease];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    mapper.targetObject = blake;
    Boy *user = [[mapper performMapping] asObject];
    assertThat(user, is(instanceOf([Boy class])));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
}

- (void)testShouldBeBackwardsCompatibleWithTheOldClassName
{
    RKObjectMapping *boyMapping = [RKObjectMapping mappingForClass:[Boy class]];
    [boyMapping mapAttributes:@"name", nil];
    RKObjectDynamicMapping *dynamicMapping = (RKObjectDynamicMapping *)[RKObjectDynamicMapping dynamicMapping];
    dynamicMapping.objectMappingForDataBlock = ^ RKObjectMapping *(id mappableData) {
        if ([[mappableData valueForKey:@"type"] isEqualToString:@"Boy"]) {
            return boyMapping;
        }

        return nil;
    };

    RKObjectMappingProvider *provider = [RKObjectMappingProvider objectMappingProvider];
    [provider setMapping:dynamicMapping forKeyPath:@""];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"boy.json"];
    Boy *blake = [[Boy new] autorelease];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    mapper.targetObject = blake;
    Boy *user = [[mapper performMapping] asObject];
    assertThat(user, is(instanceOf([Boy class])));
    assertThat(user.name, is(equalTo(@"Blake Watters")));
}

- (void)testShouldFailWithAnErrorIfATargetObjectIsProvidedAndTheDynamicMappingReturnsNil
{
    RKObjectMapping *boyMapping = [RKObjectMapping mappingForClass:[Boy class]];
    [boyMapping mapAttributes:@"name", nil];
    RKDynamicObjectMapping *dynamicMapping = [RKDynamicObjectMapping dynamicMapping];
    dynamicMapping.objectMappingForDataBlock = ^ RKObjectMapping *(id mappableData) {
        return nil;
    };

    RKObjectMappingProvider *provider = [RKObjectMappingProvider objectMappingProvider];
    [provider setMapping:dynamicMapping forKeyPath:@""];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"boy.json"];
    Boy *blake = [[Boy new] autorelease];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    mapper.targetObject = blake;
    Boy *user = [[mapper performMapping] asObject];
    assertThat(user, is(nilValue()));
    assertThat(mapper.errors, hasCountOf(1));
}

- (void)testShouldFailWithAnErrorIfATargetObjectIsProvidedAndTheDynamicMappingReturnsTheIncorrectType
{
    RKObjectMapping *girlMapping = [RKObjectMapping mappingForClass:[Girl class]];
    [girlMapping mapAttributes:@"name", nil];
    RKDynamicObjectMapping *dynamicMapping = [RKDynamicObjectMapping dynamicMapping];
    dynamicMapping.objectMappingForDataBlock = ^ RKObjectMapping *(id mappableData) {
        if ([[mappableData valueForKey:@"type"] isEqualToString:@"Girl"]) {
            return girlMapping;
        }

        return nil;
    };

    RKObjectMappingProvider *provider = [RKObjectMappingProvider objectMappingProvider];
    [provider setMapping:dynamicMapping forKeyPath:@""];

    id userInfo = [RKTestFixture parsedObjectWithContentsOfFixture:@"girl.json"];
    Boy *blake = [[Boy new] autorelease];
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:userInfo mappingProvider:provider];
    mapper.targetObject = blake;
    Boy *user = [[mapper performMapping] asObject];
    assertThat(user, is(nilValue()));
    assertThat(mapper.errors, hasCountOf(1));
}

#pragma mark - Date and Time Formatting

- (void)testShouldAutoConfigureDefaultDateFormatters
{
    [RKObjectMapping setDefaultDateFormatters:nil];
    NSArray *dateFormatters = [RKObjectMapping defaultDateFormatters];
    assertThat(dateFormatters, hasCountOf(3));
    assertThat([[dateFormatters objectAtIndex:0] dateFormat], is(equalTo(@"yyyy-MM-dd'T'HH:mm:ss'Z'")));
    assertThat([[dateFormatters objectAtIndex:1] dateFormat], is(equalTo(@"MM/dd/yyyy")));
    NSTimeZone *UTCTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    assertThat([[dateFormatters objectAtIndex:0] timeZone], is(equalTo(UTCTimeZone)));
    assertThat([[dateFormatters objectAtIndex:1] timeZone], is(equalTo(UTCTimeZone)));
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
    [RKObjectMapping setDefaultDateFormatters:nil];
    assertThat([RKObjectMapping defaultDateFormatters], hasCountOf(3));
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    [RKObjectMapping addDefaultDateFormatter:dateFormatter];
    assertThat([RKObjectMapping defaultDateFormatters], hasCountOf(4));
}

- (void)testShouldAllowNewlyAddedDateFormatterToRunFirst
{
    [RKObjectMapping setDefaultDateFormatters:nil];
    NSDateFormatter *newDateFormatter = [[NSDateFormatter new] autorelease];
    [newDateFormatter setDateFormat:@"dd/MM/yyyy"];
    [RKObjectMapping addDefaultDateFormatter:newDateFormatter];

    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *birthDateMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"favorite_date" toKeyPath:@"favoriteDate"];
    [mapping addAttributeMapping:birthDateMapping];

    NSDictionary *dictionary = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKTestUser *user = [RKTestUser user];
    RKObjectMappingOperation *operation = [[RKObjectMappingOperation alloc] initWithSourceObject:dictionary destinationObject:user mapping:mapping];
    NSError *error = nil;
    [operation performMapping:&error];

    NSDateFormatter *dateFormatter = [[NSDateFormatter new] autorelease];
    dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    [dateFormatter setDateFormat:@"MM/dd/yyyy"];

    /*
     If RKObjectMappingOperation is using the date formatter set above, we're
     going to get a really wonky date, which is what we are testing for.
     */
    assertThat([dateFormatter stringFromDate:user.favoriteDate], is(equalTo(@"01/03/2012")));
}

- (void)testShouldLetYouConfigureANewDateFormatterFromAStringAndATimeZone
{
    [RKObjectMapping setDefaultDateFormatters:nil];
    assertThat([RKObjectMapping defaultDateFormatters], hasCountOf(3));
    NSTimeZone *EDTTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"EDT"];
    [RKObjectMapping addDefaultDateFormatterForString:@"mm/dd/YYYY" inTimeZone:EDTTimeZone];
    assertThat([RKObjectMapping defaultDateFormatters], hasCountOf(4));
    NSDateFormatter *dateFormatter = [[RKObjectMapping defaultDateFormatters] objectAtIndex:0];
    assertThat(dateFormatter.timeZone, is(equalTo(EDTTimeZone)));
}

- (void)testShouldReturnNilForEmptyDateValues
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKObjectAttributeMapping *birthDateMapping = [RKObjectAttributeMapping mappingFromKeyPath:@"birthdate" toKeyPath:@"birthDate"];
    [mapping addAttributeMapping:birthDateMapping];

    NSDictionary *dictionary = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    NSMutableDictionary *mutableDictionary = [dictionary mutableCopy];
    [mutableDictionary setValue:@"" forKey:@"birthdate"];
    RKTestUser *user = [RKTestUser user];
    RKObjectMappingOperation *operation = [[RKObjectMappingOperation alloc] initWithSourceObject:mutableDictionary destinationObject:user mapping:mapping];
    [mutableDictionary release];
    NSError *error = nil;
    [operation performMapping:&error];

    assertThat(user.birthDate, is(equalTo(nil)));
}

- (void)testShouldConfigureANewDateFormatterInTheUTCTimeZoneIfPassedANilTimeZone
{
    [RKObjectMapping setDefaultDateFormatters:nil];
    assertThat([RKObjectMapping defaultDateFormatters], hasCountOf(3));
    [RKObjectMapping addDefaultDateFormatterForString:@"mm/dd/YYYY" inTimeZone:nil];
    assertThat([RKObjectMapping defaultDateFormatters], hasCountOf(4));
    NSDateFormatter *dateFormatter = [[RKObjectMapping defaultDateFormatters] objectAtIndex:0];
    NSTimeZone *UTCTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    assertThat(dateFormatter.timeZone, is(equalTo(UTCTimeZone)));
}

#pragma mark - Object Serialization
// TODO: Move to RKObjectSerializerTest

- (void)testShouldSerializeHasOneRelatioshipsToJSON
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [userMapping mapAttributes:@"name", nil];
    RKObjectMapping *addressMapping = [RKObjectMapping mappingForClass:[RKTestAddress class]];
    [addressMapping mapAttributes:@"city", @"state", nil];
    [userMapping hasOne:@"address" withMapping:addressMapping];

    RKTestUser *user = [RKTestUser new];
    user.name = @"Blake Watters";
    RKTestAddress *address = [RKTestAddress new];
    address.state = @"North Carolina";
    user.address = address;

    RKObjectMapping *serializationMapping = [userMapping inverseMapping];
    RKObjectSerializer *serializer = [RKObjectSerializer serializerWithObject:user mapping:serializationMapping];
    NSError *error = nil;
    NSString *JSON = [serializer serializedObjectForMIMEType:RKMIMETypeJSON error:&error];
    assertThat(error, is(nilValue()));
    assertThat(JSON, is(equalTo(@"{\"name\":\"Blake Watters\",\"address\":{\"state\":\"North Carolina\"}}")));
}

- (void)testShouldSerializeHasManyRelationshipsToJSON
{
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [userMapping mapAttributes:@"name", nil];
    RKObjectMapping *addressMapping = [RKObjectMapping mappingForClass:[RKTestAddress class]];
    [addressMapping mapAttributes:@"city", @"state", nil];
    [userMapping hasMany:@"friends" withMapping:addressMapping];

    RKTestUser *user = [RKTestUser new];
    user.name = @"Blake Watters";
    RKTestAddress *address1 = [RKTestAddress new];
    address1.city = @"Carrboro";
    RKTestAddress *address2 = [RKTestAddress new];
    address2.city = @"New York City";
    user.friends = [NSArray arrayWithObjects:address1, address2, nil];


    RKObjectMapping *serializationMapping = [userMapping inverseMapping];
    RKObjectSerializer *serializer = [RKObjectSerializer serializerWithObject:user mapping:serializationMapping];
    NSError *error = nil;
    NSString *JSON = [serializer serializedObjectForMIMEType:RKMIMETypeJSON error:&error];
    assertThat(error, is(nilValue()));
    assertThat(JSON, is(equalTo(@"{\"name\":\"Blake Watters\",\"friends\":[{\"city\":\"Carrboro\"},{\"city\":\"New York City\"}]}")));
}

- (void)testShouldSerializeManagedHasManyRelationshipsToJSON
{
    [RKTestFactory managedObjectStore];
    RKObjectMapping *humanMapping = [RKObjectMapping mappingForClass:[RKHuman class]];
    [humanMapping mapAttributes:@"name", nil];
    RKObjectMapping *catMapping = [RKObjectMapping mappingForClass:[RKCat class]];
    [catMapping mapAttributes:@"name", nil];
    [humanMapping hasMany:@"cats" withMapping:catMapping];

    RKHuman *blake = [RKHuman object];
    blake.name = @"Blake Watters";
    RKCat *asia = [RKCat object];
    asia.name = @"Asia";
    RKCat *roy = [RKCat object];
    roy.name = @"Roy";
    blake.cats = [NSSet setWithObjects:asia, roy, nil];

    RKObjectMapping *serializationMapping = [humanMapping inverseMapping];
    RKObjectSerializer *serializer = [RKObjectSerializer serializerWithObject:blake mapping:serializationMapping];
    NSError *error = nil;
    NSString *JSON = [serializer serializedObjectForMIMEType:RKMIMETypeJSON error:&error];
    NSDictionary *parsedJSON = [JSON performSelector:@selector(objectFromJSONString)];
    assertThat(error, is(nilValue()));
    assertThat([parsedJSON valueForKey:@"name"], is(equalTo(@"Blake Watters")));
    NSArray *catNames = [[parsedJSON valueForKeyPath:@"cats.name"] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    assertThat(catNames, is(equalTo([NSArray arrayWithObjects:@"Asia", @"Roy", nil])));
}

- (void)testUpdatingArrayOfExistingCats
{
    RKManagedObjectStore *objectStore = [RKTestFactory managedObjectStore];
    NSArray *array = [RKTestFixture parsedObjectWithContentsOfFixture:@"ArrayOfHumans.json"];
    RKManagedObjectMapping *humanMapping = [RKManagedObjectMapping mappingForClass:[RKHuman class] inManagedObjectStore:objectStore];
    [humanMapping mapKeyPath:@"id" toAttribute:@"railsID"];
    humanMapping.primaryKeyAttribute = @"railsID";
    RKObjectMappingProvider *provider = [RKObjectMappingProvider mappingProvider];
    [provider setObjectMapping:humanMapping forKeyPath:@"human"];

    // Create instances that should match the fixture
    RKHuman *human1 = [RKHuman createInContext:objectStore.primaryManagedObjectContext];
    human1.railsID = [NSNumber numberWithInt:201];
    RKHuman *human2 = [RKHuman createInContext:objectStore.primaryManagedObjectContext];
    human2.railsID = [NSNumber numberWithInt:202];
    [objectStore save:nil];

    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:array mappingProvider:provider];
    RKObjectMappingResult *result = [mapper performMapping];
    assertThat(result, is(notNilValue()));

    NSArray *humans = [result asCollection];
    assertThat(humans, hasCountOf(2));
    assertThat([humans objectAtIndex:0], is(equalTo(human1)));
    assertThat([humans objectAtIndex:1], is(equalTo(human2)));
}

@end
