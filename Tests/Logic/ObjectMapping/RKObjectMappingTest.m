//
//  RKObjectMappingTest.m
//  RestKit
//
//  Created by Blake Watters on 6/8/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"

@interface RKObjectMappingTest : RKTestCase

@end

@implementation RKObjectMappingTest

- (void)testThatTwoMappingsWithTheSameAttributeMappingsButDifferentObjectClassesAreNotConsideredEqual
{
    RKObjectMapping *mapping1 = [RKObjectMapping mappingForClass:[NSString class]];
    RKObjectMapping *mapping2 = [RKObjectMapping mappingForClass:[NSNumber class]];

    assertThatBool([mapping1 isEqualToMapping:mapping2], is(equalToBool(NO)));
}

- (void)testThatTwoMappingsForNilObjectClassAreConsideredEqual
{
    RKObjectMapping *mapping1 = [RKObjectMapping mappingForClass:nil];
    RKObjectMapping *mapping2 = [RKObjectMapping mappingForClass:nil];

    assertThatBool([mapping1 isEqualToMapping:mapping2], is(equalToBool(YES)));
}

- (void)testThatTwoMappingsAreNotConsideredEqualIfOneHasNilObjectClass
{
    RKObjectMapping *mapping1 = [RKObjectMapping mappingForClass:nil];
    RKObjectMapping *mapping2 = [RKObjectMapping mappingForClass:[NSString class]];

    assertThatBool([mapping1 isEqualToMapping:mapping2], is(equalToBool(NO)));
}

- (void)testThatRelationshipMappingsWithTheSameObjectClassAndNoAttributesAreConsideredEqual
{
    RKObjectMapping *mapping1 = [RKObjectMapping mappingForClass:[NSString class]];
    RKObjectMapping *mapping2 = [RKObjectMapping mappingForClass:[NSString class]];

    assertThatBool([mapping1 isEqualToMapping:mapping2], is(equalToBool(YES)));
}

- (void)testThatTwoMappingsForTheSameObjectClassContainingIdenticalAttributeMappingsAreConsideredEqual
{
    RKObjectMapping *mapping1 = [RKObjectMapping mappingForClass:[NSString class]];
    [mapping1 mapKeyPath:@"this" toAttribute:@"that"];
    RKObjectMapping *mapping2 = [RKObjectMapping mappingForClass:[NSString class]];
    [mapping2 mapKeyPath:@"this" toAttribute:@"that"];

    assertThatBool([mapping1 isEqualToMapping:mapping2], is(equalToBool(YES)));
}

- (void)testThatTwoMappingsForTheSameObjectClassContainingDifferingAttributeMappingsAreNotConsideredEqual
{
    RKObjectMapping *mapping1 = [RKObjectMapping mappingForClass:[NSString class]];
    [mapping1 mapKeyPath:@"this" toAttribute:@"that"];
    RKObjectMapping *mapping2 = [RKObjectMapping mappingForClass:[NSString class]];
    [mapping2 mapKeyPath:@"different" toAttribute:@"that"];

    assertThatBool([mapping1 isEqualToMapping:mapping2], is(equalToBool(NO)));
}

- (void)testThatTwoMappingsWithEqualRelationshipMappingsAreConsideredEqual
{
    RKObjectMapping *relationshipMapping1 = [RKObjectMapping mappingForClass:[NSSet class]];
    RKObjectMapping *relationshipMapping2 = [RKObjectMapping mappingForClass:[NSSet class]];

    RKObjectMapping *mapping1 = [RKObjectMapping mappingForClass:[NSString class]];
    [mapping1 mapKeyPath:@"this" toRelationship:@"that" withMapping:relationshipMapping1];
    RKObjectMapping *mapping2 = [RKObjectMapping mappingForClass:[NSString class]];
    [mapping2 mapKeyPath:@"this" toRelationship:@"that" withMapping:relationshipMapping2];

    assertThatBool([mapping1 isEqualToMapping:mapping2], is(equalToBool(YES)));
}

- (void)testThatTwoMappingsWithDifferingRelationshipMappingClassesAreNotConsideredEqual
{
    RKObjectMapping *relationshipMapping1 = [RKObjectMapping mappingForClass:[NSSet class]];
    RKObjectMapping *relationshipMapping2 = [RKObjectMapping mappingForClass:[NSNumber class]];

    RKObjectMapping *mapping1 = [RKObjectMapping mappingForClass:[NSString class]];
    [mapping1 mapKeyPath:@"this" toRelationship:@"that" withMapping:relationshipMapping1];
    RKObjectMapping *mapping2 = [RKObjectMapping mappingForClass:[NSString class]];
    [mapping2 mapKeyPath:@"this" toRelationship:@"that" withMapping:relationshipMapping2];

    assertThatBool([mapping1 isEqualToMapping:mapping2], is(equalToBool(NO)));
}

- (void)testThatTwoMappingsWithDifferingRelationshipMappingKeyPathsAreNotConsideredEqual
{
    RKObjectMapping *relationshipMapping1 = [RKObjectMapping mappingForClass:[NSSet class]];
    RKObjectMapping *relationshipMapping2 = [RKObjectMapping mappingForClass:[NSSet class]];

    RKObjectMapping *mapping1 = [RKObjectMapping mappingForClass:[NSString class]];
    [mapping1 mapKeyPath:@"this" toRelationship:@"that" withMapping:relationshipMapping1];
    RKObjectMapping *mapping2 = [RKObjectMapping mappingForClass:[NSString class]];
    [mapping2 mapKeyPath:@"this" toRelationship:@"different" withMapping:relationshipMapping2];

    assertThatBool([mapping1 isEqualToMapping:mapping2], is(equalToBool(NO)));
}

@end
