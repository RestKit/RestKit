//
//  RKAttributeMappingTest.m
//  RestKit
//
//  Created by Blake Watters on 6/8/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKAttributeMapping.h"

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

@end
