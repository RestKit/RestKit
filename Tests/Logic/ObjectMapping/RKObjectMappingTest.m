//
//  RKObjectMappingTest.m
//  RestKit
//
//  Created by Blake Watters on 6/8/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKTestUser.h"
#import "RKObjectMappingOperationDataSource.h"

@interface RKObjectMappingTest : RKTestCase

@end

@implementation RKObjectMappingTest

- (void)tearDown
{
    [RKObjectMapping setDefaultSourceToDestinationKeyTransformationBlock:nil];
}

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

- (void)testThatTwoMappingsWithNilSourceKeyPathAreConsideredEqual
{
    RKObjectMapping *relationshipMapping1 = [RKObjectMapping mappingForClass:[NSNumber class]];
    RKObjectMapping *relationshipMapping2 = [RKObjectMapping mappingForClass:[NSNumber class]];
    
    RKObjectMapping *mapping1 = [RKObjectMapping mappingForClass:[NSString class]];
    [mapping1 addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:nil toKeyPath:@"that" withMapping:relationshipMapping1]];;
    RKObjectMapping *mapping2 = [RKObjectMapping mappingForClass:[NSString class]];
    [mapping2 addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:nil toKeyPath:@"that" withMapping:relationshipMapping2]];;
    
    assertThatBool([mapping1 isEqualToMapping:mapping2], is(equalToBool(YES)));
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

#pragma mark - Key Transformations

- (void)testPropertyNameTransformationBlockForAttributes
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [mapping setSourceToDestinationKeyTransformationBlock:^NSString *(RKObjectMapping *mapping, NSString *sourceKey) {
        return [sourceKey uppercaseString];
    }];
    [mapping addAttributeMappingsFromArray:@[ @"name", @"rank" ]];
    NSArray *expectedNames = @[ @"NAME", @"RANK" ];
    expect([mapping.propertyMappingsByDestinationKeyPath allKeys]).to.equal(expectedNames);
}

- (void)testPropertyNameTransformationBlockForRelationships
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [mapping setSourceToDestinationKeyTransformationBlock:^NSString *(RKObjectMapping *mapping, NSString *sourceKey) {
        return [sourceKey uppercaseString];
    }];
    RKObjectMapping *relatedMapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [mapping addRelationshipMappingWithSourceKeyPath:@"something" mapping:relatedMapping];
    RKRelationshipMapping *relationshipMapping = [mapping propertyMappingsByDestinationKeyPath][@"SOMETHING"];
    expect(relationshipMapping).notTo.beNil();
    expect(relationshipMapping.sourceKeyPath).to.equal(@"something");
    expect(relationshipMapping.destinationKeyPath).to.equal(@"SOMETHING");
}

- (void)testTransformationOfAttributeKeyPaths
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [mapping setSourceToDestinationKeyTransformationBlock:^NSString *(RKObjectMapping *mapping, NSString *sourceKey) {
        return [sourceKey capitalizedString];
    }];
    [mapping addAttributeMappingsFromArray:@[ @"user.comments" ]];
    NSArray *expectedNames = @[ @"User.Comments" ];
    expect([mapping.propertyMappingsByDestinationKeyPath allKeys]).to.equal(expectedNames);
}

- (void)testDefaultSourceToDestinationKeyTransformationBlock
{
    [RKObjectMapping setDefaultSourceToDestinationKeyTransformationBlock:^NSString *(RKObjectMapping *mapping, NSString *sourceKey) {
        return [sourceKey capitalizedString];
    }];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [mapping addAttributeMappingsFromArray:@[ @"user.comments" ]];
    NSArray *expectedNames = @[ @"User.Comments" ];
    expect([mapping.propertyMappingsByDestinationKeyPath allKeys]).to.equal(expectedNames);
}

- (void)testBreakageOfRecursiveInverseCyclicGraphs
{
    RKObjectMapping *parentMapping = [RKObjectMapping mappingForClass:[NSObject class]];
    [parentMapping addAttributeMappingsFromDictionary:@{ @"first_name": @"firstName", @"last_name": @"lastName" }];
    RKObjectMapping *childMapping = [RKObjectMapping mappingForClass:[NSObject class]];
    [childMapping addAttributeMappingsFromDictionary:@{ @"first_name": @"firstName", @"last_name": @"lastName" }];
    [parentMapping addRelationshipMappingWithSourceKeyPath:@"children" mapping:childMapping];
    [childMapping addRelationshipMappingWithSourceKeyPath:@"parents" mapping:parentMapping];
    RKObjectMapping *inverseMapping = [parentMapping inverseMapping];
    expect([inverseMapping propertyMappingsBySourceKeyPath][@"firstName"]).notTo.beNil();
    expect([inverseMapping propertyMappingsBySourceKeyPath][@"lastName"]).notTo.beNil();
    expect([inverseMapping propertyMappingsBySourceKeyPath][@"children"]).notTo.beNil();
}

- (void)testInverseMappingWithNilDestinationKeyPathForAttributeMapping
{
    // Map @"Blake" to RKTestUser with name = @"Blake"
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:nil toKeyPath:@"name"]];
    
    RKObjectMapping *inverseMapping = [mapping inverseMapping];
    
    RKTestUser *user = [RKTestUser new];
    user.name = @"Blake";
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    RKMappingOperation *operation = [[RKMappingOperation alloc] initWithSourceObject:user destinationObject:dictionary mapping:inverseMapping];
    RKObjectMappingOperationDataSource *dataSource = [RKObjectMappingOperationDataSource new];
    operation.dataSource = dataSource;
    [operation start];
    
    expect(operation.destinationObject).to.equal(@{ @"Blake": @{} });
}

- (void)testRemoveAttributeMappingWithNilDestinationKeyPath
{
    // This test fails also if we create directly a mapping from "(something) => (null)"
    // but the inverseMapping case is a more common use case
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:nil toKeyPath:@"name"]];

    RKObjectMapping *inverseMapping = [mapping inverseMapping];
    [inverseMapping removePropertyMapping:[inverseMapping mappingForSourceKeyPath:@"name"]];
    expect([inverseMapping mappingForSourceKeyPath:@"name"]).to.beNil;
}


@end
