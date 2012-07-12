//
//  RKObjectAttributeMappingTest.m
//  RestKit
//
//  Created by Blake Watters on 6/8/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKObjectAttributeMapping.h"

@interface RKObjectAttributeMappingTest : RKTestCase

@end

@implementation RKObjectAttributeMappingTest

- (void)testThatAttributeMappingsWithTheSameSourceAndDestinationKeyPathAreConsideredEqual
{
    RKObjectAttributeMapping *mapping1 = [RKObjectAttributeMapping mappingFromKeyPath:@"this" toKeyPath:@"that"];
    RKObjectAttributeMapping *mapping2 = [RKObjectAttributeMapping mappingFromKeyPath:@"this" toKeyPath:@"that"];

    assertThatBool([mapping1 isEqualToMapping:mapping2], is(equalToBool(YES)));
}

- (void)testThatAttributeMappingsWithDifferingKeyPathsAreNotConsideredEqual
{
    RKObjectAttributeMapping *mapping1 = [RKObjectAttributeMapping mappingFromKeyPath:@"this" toKeyPath:@"that"];
    RKObjectAttributeMapping *mapping2 = [RKObjectAttributeMapping mappingFromKeyPath:@"this" toKeyPath:@"the other"];

    assertThatBool([mapping1 isEqualToMapping:mapping2], is(equalToBool(NO)));
}

@end
