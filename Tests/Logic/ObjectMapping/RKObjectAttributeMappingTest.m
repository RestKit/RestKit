//
//  RKObjectAttributeMappingTest.m
//  RestKit
//
//  Created by Blake Watters on 6/8/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKAttributeMapping.h"

@interface RKObjectAttributeMappingTest : RKTestCase

@end

@implementation RKObjectAttributeMappingTest

- (void)testThatAttributeMappingsWithTheSameSourceAndDestinationKeyPathAreConsideredEqual
{
    RKAttributeMapping *mapping1 = [RKAttributeMapping mappingFromKeyPath:@"this" toKeyPath:@"that"];
    RKAttributeMapping *mapping2 = [RKAttributeMapping mappingFromKeyPath:@"this" toKeyPath:@"that"];

    assertThatBool([mapping1 isEqualToMapping:mapping2], is(equalToBool(YES)));
}

- (void)testThatAttributeMappingsWithDifferingKeyPathsAreNotConsideredEqual
{
    RKAttributeMapping *mapping1 = [RKAttributeMapping mappingFromKeyPath:@"this" toKeyPath:@"that"];
    RKAttributeMapping *mapping2 = [RKAttributeMapping mappingFromKeyPath:@"this" toKeyPath:@"the other"];

    assertThatBool([mapping1 isEqualToMapping:mapping2], is(equalToBool(NO)));
}

@end
