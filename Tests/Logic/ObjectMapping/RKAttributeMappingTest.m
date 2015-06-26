//
//  RKAttributeMappingTest.m
//  RestKit
//
//  Created by Blake Watters on 6/8/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKAttributeMapping.h"
#import "RKValueTransformers.h"

@interface RKAttributeMappingTest : RKTestCase

@end

@implementation RKAttributeMappingTest

- (void)testThatAttributeMappingsWithTheSameSourceAndDestinationKeyPathAreConsideredEqual
{
    RKAttributeMapping *mapping1 = [RKAttributeMapping attributeMappingFromKeyPath:@"this" toKeyPath:@"that"];
    RKAttributeMapping *mapping2 = [RKAttributeMapping attributeMappingFromKeyPath:@"this" toKeyPath:@"that"];

    assertThatBool([mapping1 isEqualToMapping:mapping2], is(equalToBool(YES)));
}

- (void)testThatAttributeMappingsWithDifferingKeyPathsAreNotConsideredEqual
{
    RKAttributeMapping *mapping1 = [RKAttributeMapping attributeMappingFromKeyPath:@"this" toKeyPath:@"that"];
    RKAttributeMapping *mapping2 = [RKAttributeMapping attributeMappingFromKeyPath:@"this" toKeyPath:@"the other"];

    assertThatBool([mapping1 isEqualToMapping:mapping2], is(equalToBool(NO)));
}

- (void)testAttributeMappingCopy {
    RKAttributeMapping *propertyMapping = [RKAttributeMapping attributeMappingFromKeyPath:@"source" toKeyPath:@"destination"];
    propertyMapping.valueTransformer = [RKBlockValueTransformer valueTransformerWithValidationBlock:^BOOL(__unsafe_unretained Class inputValueClass, __unsafe_unretained Class outputValueClass) {
        return [inputValueClass isSubclassOfClass:[NSString class]] && [outputValueClass isSubclassOfClass:[NSString class]];
    } transformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, __unsafe_unretained Class outputClass, NSError *__autoreleasing *error) {
        return YES;
    }];
    propertyMapping.propertyValueClass = [NSString class];
    
    RKAttributeMapping *propertyMappingCopy = [propertyMapping copy];
    expect([propertyMappingCopy.sourceKeyPath isEqual:propertyMapping.sourceKeyPath]);
    expect([propertyMappingCopy.destinationKeyPath isEqual:propertyMapping.destinationKeyPath]);
    expect(propertyMappingCopy.propertyValueClass == propertyMapping.propertyValueClass);
    expect([propertyMappingCopy.valueTransformer isEqual:propertyMapping.valueTransformer]);
}

@end
