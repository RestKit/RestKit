//
//  RKDynamicMappingTest.m
//  RestKit
//
//  Created by Blake Watters on 7/28/11.
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
#import "RKDynamicMapping.h"
#import "RKDynamicMappingModels.h"

@interface RKDynamicMappingTest : RKTestCase

@end

@implementation RKDynamicMappingTest

- (void)testShouldPickTheAppropriateMappingBasedOnAnAttributeValue
{
    RKDynamicMapping *dynamicMapping = [RKDynamicMapping new];
    RKObjectMapping *girlMapping = [RKObjectMapping mappingForClass:[Girl class]];
    [girlMapping addAttributeMappingsFromArray:@[@"name"]];
    RKObjectMapping *boyMapping = [RKObjectMapping mappingForClass:[Boy class]];
    [boyMapping addAttributeMappingsFromArray:@[@"name"]];
    [dynamicMapping addMatcher:[RKObjectMappingMatcher matcherWithKeyPath:@"type" expectedValue:@"Girl" objectMapping:girlMapping]];
    [dynamicMapping addMatcher:[RKObjectMappingMatcher matcherWithKeyPath:@"type" expectedValue:@"Boy" objectMapping:boyMapping]];
    RKObjectMapping *mapping = [dynamicMapping objectMappingForRepresentation:[RKTestFixture parsedObjectWithContentsOfFixture:@"girl.json"]];
    assertThat(mapping, is(notNilValue()));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"Girl")));
    mapping = [dynamicMapping objectMappingForRepresentation:[RKTestFixture parsedObjectWithContentsOfFixture:@"boy.json"]];
    assertThat(mapping, is(notNilValue()));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"Boy")));
}

- (void)testShouldMatchOnAnNSNumberAttributeValue
{
    RKDynamicMapping *dynamicMapping = [RKDynamicMapping new];
    RKObjectMapping *girlMapping = [RKObjectMapping mappingForClass:[Girl class]];
    [girlMapping addAttributeMappingsFromArray:@[@"name"]];
    RKObjectMapping *boyMapping = [RKObjectMapping mappingForClass:[Boy class]];
    [boyMapping addAttributeMappingsFromArray:@[@"name"]];
    [dynamicMapping addMatcher:[RKObjectMappingMatcher matcherWithKeyPath:@"numeric_type" expectedValue:@(0) objectMapping:girlMapping]];
    [dynamicMapping addMatcher:[RKObjectMappingMatcher matcherWithKeyPath:@"numeric_type" expectedValue:@(1) objectMapping:boyMapping]];
    RKObjectMapping *mapping = [dynamicMapping objectMappingForRepresentation:[RKTestFixture parsedObjectWithContentsOfFixture:@"girl.json"]];
    assertThat(mapping, is(notNilValue()));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"Girl")));
    mapping = [dynamicMapping objectMappingForRepresentation:[RKTestFixture parsedObjectWithContentsOfFixture:@"boy.json"]];
    assertThat(mapping, is(notNilValue()));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"Boy")));
}

- (void)testMappingSelectionUsingPredicateMatchers
{
    RKDynamicMapping *dynamicMapping = [RKDynamicMapping new];
    RKObjectMapping *girlMapping = [RKObjectMapping mappingForClass:[Girl class]];
    [girlMapping addAttributeMappingsFromArray:@[@"name"]];
    RKObjectMapping *boyMapping = [RKObjectMapping mappingForClass:[Boy class]];
    [boyMapping addAttributeMappingsFromArray:@[@"name"]];
    [dynamicMapping addMatcher:[RKObjectMappingMatcher matcherWithPredicate:[NSPredicate predicateWithFormat:@"numeric_type = 0"] objectMapping:girlMapping]];
    [dynamicMapping addMatcher:[RKObjectMappingMatcher matcherWithPredicate:[NSPredicate predicateWithFormat:@"numeric_type = 1"] objectMapping:boyMapping]];
    RKObjectMapping *mapping = [dynamicMapping objectMappingForRepresentation:[RKTestFixture parsedObjectWithContentsOfFixture:@"girl.json"]];
    assertThat(mapping, is(notNilValue()));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"Girl")));
    mapping = [dynamicMapping objectMappingForRepresentation:[RKTestFixture parsedObjectWithContentsOfFixture:@"boy.json"]];
    assertThat(mapping, is(notNilValue()));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"Boy")));
}

- (void)testThatRegistrationOfMatcherASecondTimeMovesToTopOfTheStack
{
    RKDynamicMapping *dynamicMapping = [RKDynamicMapping new];
    RKObjectMapping *girlMapping = [RKObjectMapping mappingForClass:[Girl class]];
    [girlMapping addAttributeMappingsFromArray:@[@"name"]];
    RKObjectMapping *boyMapping = [RKObjectMapping mappingForClass:[Boy class]];
    [boyMapping addAttributeMappingsFromArray:@[@"name"]];
    RKObjectMappingMatcher *girlMatcher = [RKObjectMappingMatcher matcherWithPredicate:[NSPredicate predicateWithFormat:@"numeric_type = 0"] objectMapping:girlMapping];
    RKObjectMappingMatcher *boyMatcher = [RKObjectMappingMatcher matcherWithPredicate:[NSPredicate predicateWithFormat:@"numeric_type = 0"] objectMapping:boyMapping];
    [dynamicMapping addMatcher:girlMatcher];
    [dynamicMapping addMatcher:boyMatcher];

    // Frst time you get a Girl
    RKObjectMapping *mapping = [dynamicMapping objectMappingForRepresentation:[RKTestFixture parsedObjectWithContentsOfFixture:@"girl.json"]];
    assertThat(mapping, is(notNilValue()));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"Girl")));

    // Reregister boyMatcher
    [dynamicMapping addMatcher:boyMatcher];
    mapping = [dynamicMapping objectMappingForRepresentation:[RKTestFixture parsedObjectWithContentsOfFixture:@"girl.json"]];
    assertThat(mapping, is(notNilValue()));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"Boy")));
}

- (void)testIteratingAndRemovingAllMatchers
{
    RKDynamicMapping *dynamicMapping = [RKDynamicMapping new];
    RKObjectMapping *girlMapping = [RKObjectMapping mappingForClass:[Girl class]];
    [girlMapping addAttributeMappingsFromArray:@[@"name"]];
    RKObjectMapping *boyMapping = [RKObjectMapping mappingForClass:[Boy class]];
    [boyMapping addAttributeMappingsFromArray:@[@"name"]];
    [dynamicMapping addMatcher:[RKObjectMappingMatcher matcherWithPredicate:[NSPredicate predicateWithFormat:@"numeric_type = 0"] objectMapping:girlMapping]];
    [dynamicMapping addMatcher:[RKObjectMappingMatcher matcherWithPredicate:[NSPredicate predicateWithFormat:@"numeric_type = 1"] objectMapping:boyMapping]];

    for (RKObjectMappingMatcher *matcher in dynamicMapping.matchers) {
        [dynamicMapping removeMatcher:matcher];
    }
    expect(dynamicMapping.matchers).to.beEmpty();
}

- (void)testShouldPickTheAppropriateMappingBasedOnBlockDelegateCallback
{
    RKDynamicMapping *dynamicMapping = [RKDynamicMapping new];
    [dynamicMapping setObjectMappingForRepresentationBlock:^RKObjectMapping *(id representation) {
        if ([[representation valueForKey:@"type"] isEqualToString:@"Girl"]) {
            RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[Girl class]];
            [mapping addAttributeMappingsFromArray:@[@"name"]];
            return mapping;
        } else if ([[representation valueForKey:@"type"] isEqualToString:@"Boy"]) {
            RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[Boy class]];
            [mapping addAttributeMappingsFromArray:@[@"name"]];
            return mapping;
        }

        return nil;
    }];
    RKObjectMapping *mapping = [dynamicMapping objectMappingForRepresentation:[RKTestFixture parsedObjectWithContentsOfFixture:@"girl.json"]];
    assertThat(mapping, is(notNilValue()));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"Girl")));
    mapping = [dynamicMapping objectMappingForRepresentation:[RKTestFixture parsedObjectWithContentsOfFixture:@"boy.json"]];
    assertThat(mapping, is(notNilValue()));
    assertThat(NSStringFromClass(mapping.objectClass), is(equalTo(@"Boy")));
}

@end
