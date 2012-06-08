//
//  RKObjectRelationshipMappingTest.m
//  RestKit
//
//  Created by Blake Watters on 6/8/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"

@interface RKObjectRelationshipMappingTest : RKTestCase

@end

@implementation RKObjectRelationshipMappingTest

- (void)testThatRelationshipMappingsWithTheSameSourceAndDestinationKeyPathAreConsideredEqual
{
    RKObjectRelationshipMapping *mapping1 = [RKObjectRelationshipMapping mappingFromKeyPath:@"this" toKeyPath:@"that" withMapping:nil];
    RKObjectRelationshipMapping *mapping2 = [RKObjectRelationshipMapping mappingFromKeyPath:@"this" toKeyPath:@"that" withMapping:nil];

    assertThatBool([mapping1 isEqualToMapping:mapping2], is(equalToBool(YES)));
}

- (void)testThatRelationshipMappingsWithDifferingKeyPathsAreNotConsideredEqual
{
    RKObjectRelationshipMapping *mapping1 = [RKObjectRelationshipMapping mappingFromKeyPath:@"this" toKeyPath:@"that"  withMapping:nil];
    RKObjectRelationshipMapping *mapping2 = [RKObjectRelationshipMapping mappingFromKeyPath:@"this" toKeyPath:@"the other"  withMapping:nil];

    assertThatBool([mapping1 isEqualToMapping:mapping2], is(equalToBool(NO)));
}

- (void)testThatTwoMappingsWithEqualRelationshipMappingsAreConsideredEqual
{
    RKObjectMapping *relationshipMapping1 = [RKObjectMapping mappingForClass:[NSSet class]];
    RKObjectMapping *relationshipMapping2 = [RKObjectMapping mappingForClass:[NSSet class]];

    RKObjectRelationshipMapping *mapping1 = [RKObjectRelationshipMapping mappingFromKeyPath:@"this" toKeyPath:@"that"  withMapping:relationshipMapping1];
    RKObjectRelationshipMapping *mapping2 = [RKObjectRelationshipMapping mappingFromKeyPath:@"this" toKeyPath:@"that"  withMapping:relationshipMapping2];

    assertThatBool([mapping1 isEqualToMapping:mapping2], is(equalToBool(YES)));
}

- (void)testThatTwoMappingsWithDifferingRelationshipMappingClassesAreNotConsideredEqual
{
    RKObjectMapping *relationshipMapping1 = [RKObjectMapping mappingForClass:[NSSet class]];
    RKObjectMapping *relationshipMapping2 = [RKObjectMapping mappingForClass:[NSNumber class]];

    RKObjectRelationshipMapping *mapping1 = [RKObjectRelationshipMapping mappingFromKeyPath:@"this" toKeyPath:@"that"  withMapping:relationshipMapping1];
    RKObjectRelationshipMapping *mapping2 = [RKObjectRelationshipMapping mappingFromKeyPath:@"this" toKeyPath:@"that"  withMapping:relationshipMapping2];

    assertThatBool([mapping1 isEqualToMapping:mapping2], is(equalToBool(NO)));
}

- (void)testThatTwoMappingsWhereOneHasANilObjectClassNotConsideredEqual
{
    RKObjectMapping *relationshipMapping1 = [RKObjectMapping mappingForClass:[NSSet class]];
    RKObjectMapping *relationshipMapping2 = [RKObjectMapping mappingForClass:nil];

    RKObjectRelationshipMapping *mapping1 = [RKObjectRelationshipMapping mappingFromKeyPath:@"this" toKeyPath:@"that"  withMapping:relationshipMapping1];
    RKObjectRelationshipMapping *mapping2 = [RKObjectRelationshipMapping mappingFromKeyPath:@"this" toKeyPath:@"that"  withMapping:relationshipMapping2];

    assertThatBool([mapping1 isEqualToMapping:mapping2], is(equalToBool(NO)));
}

- (void)testThatTwoMappingsWhereBothHaveANilObjectClassNotConsideredEqual
{
    RKObjectMapping *relationshipMapping1 = [RKObjectMapping mappingForClass:nil];
    RKObjectMapping *relationshipMapping2 = [RKObjectMapping mappingForClass:nil];

    RKObjectRelationshipMapping *mapping1 = [RKObjectRelationshipMapping mappingFromKeyPath:@"this" toKeyPath:@"that"  withMapping:relationshipMapping1];
    RKObjectRelationshipMapping *mapping2 = [RKObjectRelationshipMapping mappingFromKeyPath:@"this" toKeyPath:@"that"  withMapping:relationshipMapping2];

    assertThatBool([mapping1 isEqualToMapping:mapping2], is(equalToBool(YES)));
}

@end
