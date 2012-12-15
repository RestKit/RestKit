//
//  RKRelationshipMappingTest.m
//  RestKit
//
//  Created by Blake Watters on 6/8/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"

@interface RKRelationshipMappingTest : RKTestCase

@end

@implementation RKRelationshipMappingTest

- (void)testThatRelationshipMappingsWithTheSameSourceAndDestinationKeyPathAreConsideredEqual
{
    RKRelationshipMapping *mapping1 = [RKRelationshipMapping relationshipMappingFromKeyPath:@"this" toKeyPath:@"that" withMapping:nil];
    RKRelationshipMapping *mapping2 = [RKRelationshipMapping relationshipMappingFromKeyPath:@"this" toKeyPath:@"that" withMapping:nil];

    assertThatBool([mapping1 isEqualToMapping:mapping2], is(equalToBool(YES)));
}

- (void)testThatRelationshipMappingsWithDifferingKeyPathsAreNotConsideredEqual
{
    RKRelationshipMapping *mapping1 = [RKRelationshipMapping relationshipMappingFromKeyPath:@"this" toKeyPath:@"that"  withMapping:nil];
    RKRelationshipMapping *mapping2 = [RKRelationshipMapping relationshipMappingFromKeyPath:@"this" toKeyPath:@"the other"  withMapping:nil];

    assertThatBool([mapping1 isEqualToMapping:mapping2], is(equalToBool(NO)));
}

- (void)testThatTwoMappingsWithEqualRelationshipMappingsAreConsideredEqual
{
    RKObjectMapping *relationshipMapping1 = [RKObjectMapping mappingForClass:[NSSet class]];
    RKObjectMapping *relationshipMapping2 = [RKObjectMapping mappingForClass:[NSSet class]];

    RKRelationshipMapping *mapping1 = [RKRelationshipMapping relationshipMappingFromKeyPath:@"this" toKeyPath:@"that"  withMapping:relationshipMapping1];
    RKRelationshipMapping *mapping2 = [RKRelationshipMapping relationshipMappingFromKeyPath:@"this" toKeyPath:@"that"  withMapping:relationshipMapping2];

    assertThatBool([mapping1 isEqualToMapping:mapping2], is(equalToBool(YES)));
}

- (void)testThatTwoMappingsWithDifferingRelationshipMappingClassesAreNotConsideredEqual
{
    RKObjectMapping *relationshipMapping1 = [RKObjectMapping mappingForClass:[NSSet class]];
    RKObjectMapping *relationshipMapping2 = [RKObjectMapping mappingForClass:[NSNumber class]];

    RKRelationshipMapping *mapping1 = [RKRelationshipMapping relationshipMappingFromKeyPath:@"this" toKeyPath:@"that"  withMapping:relationshipMapping1];
    RKRelationshipMapping *mapping2 = [RKRelationshipMapping relationshipMappingFromKeyPath:@"this" toKeyPath:@"that"  withMapping:relationshipMapping2];

    assertThatBool([mapping1 isEqualToMapping:mapping2], is(equalToBool(NO)));
}

- (void)testThatTwoMappingsWhereOneHasANilObjectClassNotConsideredEqual
{
    RKObjectMapping *relationshipMapping1 = [RKObjectMapping mappingForClass:[NSSet class]];
    RKObjectMapping *relationshipMapping2 = [RKObjectMapping mappingForClass:nil];

    RKRelationshipMapping *mapping1 = [RKRelationshipMapping relationshipMappingFromKeyPath:@"this" toKeyPath:@"that"  withMapping:relationshipMapping1];
    RKRelationshipMapping *mapping2 = [RKRelationshipMapping relationshipMappingFromKeyPath:@"this" toKeyPath:@"that"  withMapping:relationshipMapping2];

    assertThatBool([mapping1 isEqualToMapping:mapping2], is(equalToBool(NO)));
}

- (void)testThatTwoMappingsWhereBothHaveANilObjectClassNotConsideredEqual
{
    RKObjectMapping *relationshipMapping1 = [RKObjectMapping mappingForClass:nil];
    RKObjectMapping *relationshipMapping2 = [RKObjectMapping mappingForClass:nil];

    RKRelationshipMapping *mapping1 = [RKRelationshipMapping relationshipMappingFromKeyPath:@"this" toKeyPath:@"that"  withMapping:relationshipMapping1];
    RKRelationshipMapping *mapping2 = [RKRelationshipMapping relationshipMappingFromKeyPath:@"this" toKeyPath:@"that"  withMapping:relationshipMapping2];

    assertThatBool([mapping1 isEqualToMapping:mapping2], is(equalToBool(YES)));
}

@end
