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
    [mapping1 addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"this" toKeyPath:@"that"]];
    RKObjectMapping *mapping2 = [RKObjectMapping mappingForClass:[NSString class]];
    [mapping2 addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"this" toKeyPath:@"that"]];

    assertThatBool([mapping1 isEqualToMapping:mapping2], is(equalToBool(YES)));
}

- (void)testThatTwoMappingsForTheSameObjectClassContainingDifferingAttributeMappingsAreNotConsideredEqual
{
    RKObjectMapping *mapping1 = [RKObjectMapping mappingForClass:[NSString class]];
    [mapping1 addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"this" toKeyPath:@"that"]];
    RKObjectMapping *mapping2 = [RKObjectMapping mappingForClass:[NSString class]];
    [mapping2 addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"different" toKeyPath:@"that"]];

    assertThatBool([mapping1 isEqualToMapping:mapping2], is(equalToBool(NO)));
}

- (void)testThatTwoMappingsWithEqualRelationshipMappingsAreConsideredEqual
{
    RKObjectMapping *relationshipMapping1 = [RKObjectMapping mappingForClass:[NSSet class]];
    RKObjectMapping *relationshipMapping2 = [RKObjectMapping mappingForClass:[NSSet class]];

    RKObjectMapping *mapping1 = [RKObjectMapping mappingForClass:[NSString class]];
    [mapping1 addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"this" toKeyPath:@"that" withMapping:relationshipMapping1]];;
    RKObjectMapping *mapping2 = [RKObjectMapping mappingForClass:[NSString class]];
    [mapping2 addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"this" toKeyPath:@"that" withMapping:relationshipMapping2]];;

    assertThatBool([mapping1 isEqualToMapping:mapping2], is(equalToBool(YES)));
}

- (void)testThatTwoMappingsWithDifferingRelationshipMappingClassesAreNotConsideredEqual
{
    RKObjectMapping *relationshipMapping1 = [RKObjectMapping mappingForClass:[NSSet class]];
    RKObjectMapping *relationshipMapping2 = [RKObjectMapping mappingForClass:[NSNumber class]];

    RKObjectMapping *mapping1 = [RKObjectMapping mappingForClass:[NSString class]];
    [mapping1 addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"this" toKeyPath:@"that" withMapping:relationshipMapping1]];;
    RKObjectMapping *mapping2 = [RKObjectMapping mappingForClass:[NSString class]];
    [mapping2 addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"this" toKeyPath:@"that" withMapping:relationshipMapping2]];;

    assertThatBool([mapping1 isEqualToMapping:mapping2], is(equalToBool(NO)));
}

- (void)testThatTwoMappingsWithDifferingRelationshipMappingKeyPathsAreNotConsideredEqual
{
    RKObjectMapping *relationshipMapping1 = [RKObjectMapping mappingForClass:[NSSet class]];
    RKObjectMapping *relationshipMapping2 = [RKObjectMapping mappingForClass:[NSSet class]];

    RKObjectMapping *mapping1 = [RKObjectMapping mappingForClass:[NSString class]];
    [mapping1 addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"this" toKeyPath:@"that" withMapping:relationshipMapping1]];;
    RKObjectMapping *mapping2 = [RKObjectMapping mappingForClass:[NSString class]];
    [mapping2 addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"this" toKeyPath:@"different" withMapping:relationshipMapping2]];;

    assertThatBool([mapping1 isEqualToMapping:mapping2], is(equalToBool(NO)));
}

- (void)testThatAddingAPropertyMappingThatExistsInAnotherMappingTriggersException
{
    RKObjectMapping *firstMapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKAttributeMapping *attributeMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"this" toKeyPath:@"that"];
    [firstMapping addPropertyMapping:attributeMapping];

    RKObjectMapping *secondMapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    NSException *exception = nil;
    @try {
        [secondMapping addPropertyMapping:attributeMapping];
    }
    @catch (NSException *caughtException) {
        exception = caughtException;
    }
    @finally {
        expect(exception).notTo.beNil();
        expect(exception.reason).to.equal(@"Cannot add a property mapping object that has already been added to another `RKObjectMapping` object. You probably want to obtain a copy of the mapping: `[propertyMapping copy]`");
    }
}

- (void)testThatAddingAnArrayOfPropertyMappingsThatExistInAnotherMappingTriggersException
{
    RKObjectMapping *firstMapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKAttributeMapping *attributeMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"this" toKeyPath:@"that"];
    [firstMapping addPropertyMapping:attributeMapping];

    RKObjectMapping *secondMapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    NSException *exception = nil;
    @try {
        [secondMapping addPropertyMappingsFromArray:@[attributeMapping]];
    }
    @catch (NSException *caughtException) {
        exception = caughtException;
    }
    @finally {
        expect(exception).notTo.beNil();
        expect(exception.reason).to.equal(@"One or more of the property mappings in the given array has already been added to another `RKObjectMapping` object. You probably want to obtain a copy of the array of mappings: `[[NSArray alloc] initWithArray:arrayOfPropertyMappings copyItems:YES]`");
    }
}

- (void)testThatAddingAnArrayOfAttributeMappingsThatExistInAnotherMappingTriggersException
{
    RKObjectMapping *firstMapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    RKAttributeMapping *attributeMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"this" toKeyPath:@"that"];
    [firstMapping addPropertyMapping:attributeMapping];

    RKObjectMapping *secondMapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    NSException *exception = nil;
    @try {
        [secondMapping addAttributeMappingsFromArray:@[attributeMapping, @"stringValue"]];
    }
    @catch (NSException *caughtException) {
        exception = caughtException;
    }
    @finally {
        expect(exception).notTo.beNil();
        expect(exception.reason).to.equal(@"One or more of the property mappings in the given array has already been added to another `RKObjectMapping` object. You probably want to obtain a copy of the array of mappings: `[[NSArray alloc] initWithArray:arrayOfPropertyMappings copyItems:YES]`");
    }
}

@end
