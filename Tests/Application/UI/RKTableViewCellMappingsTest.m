//
//  RKTableViewCellMappingsTest.m
//  RestKit
//
//  Created by Blake Watters on 8/9/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKTableViewCellMappings.h"
#import "RKTestUser.h"
#import "RKTestAddress.h"

@interface RKTestSubclassedUser : RKTestUser
@end
@implementation RKTestSubclassedUser
@end

@interface RKTableViewCellMappingsTest : RKTestCase

@end

@implementation RKTableViewCellMappingsTest

- (void)testRaiseAnExceptionWhenAnAttemptIsMadeToRegisterAnExistingMappableClass
{
    RKTableViewCellMappings *cellMappings = [RKTableViewCellMappings cellMappings];
    RKTableViewCellMapping *firstMapping = [RKTableViewCellMapping cellMapping];
    RKTableViewCellMapping *secondMapping = [RKTableViewCellMapping cellMapping];
    [cellMappings setCellMapping:firstMapping forClass:[RKTestUser class]];
    NSException *exception = nil;
    @try {
        [cellMappings setCellMapping:secondMapping forClass:[RKTestUser class]];
    }
    @catch (NSException *e) {
        exception = e;
    }
    @finally {
        assertThat(exception, is(notNilValue()));
    }
}

- (void)testFindCellMappingsWithAnExactClassMatch
{
    RKTableViewCellMappings *cellMappings = [RKTableViewCellMappings cellMappings];
    RKTableViewCellMapping *firstMapping = [RKTableViewCellMapping cellMapping];
    RKTableViewCellMapping *secondMapping = [RKTableViewCellMapping cellMapping];
    [cellMappings setCellMapping:firstMapping forClass:[RKTestSubclassedUser class]];
    [cellMappings setCellMapping:secondMapping forClass:[RKTestUser class]];
    assertThat([cellMappings cellMappingForObject:[RKTestUser new]], is(equalTo(secondMapping)));
}

- (void)testFindCellMappingsWithASubclassMatch
{
    RKTableViewCellMappings *cellMappings = [RKTableViewCellMappings cellMappings];
    RKTableViewCellMapping *firstMapping = [RKTableViewCellMapping cellMapping];
    RKTableViewCellMapping *secondMapping = [RKTableViewCellMapping cellMapping];
    [cellMappings setCellMapping:firstMapping forClass:[RKTestUser class]];
    [cellMappings setCellMapping:secondMapping forClass:[RKTestSubclassedUser class]];
    assertThat([cellMappings cellMappingForObject:[RKTestSubclassedUser new]], is(equalTo(secondMapping)));
}

- (void)testReturnTheCellMappingForAnObjectInstance
{
    RKTableViewCellMappings *cellMappings = [RKTableViewCellMappings cellMappings];
    RKTableViewCellMapping *mapping = [RKTableViewCellMapping cellMapping];
    [cellMappings setCellMapping:mapping forClass:[RKTestUser class]];
    assertThat([cellMappings cellMappingForObject:[RKTestUser new]], is(equalTo(mapping)));
}

@end
