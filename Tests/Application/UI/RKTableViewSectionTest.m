//
//  RKTableViewSectionTest.m
//  RestKit
//
//  Created by Blake Watters on 8/3/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKTableSection.h"
#import "RKTableViewCellMappings.h"
#import "RKTableViewCellMapping.h"
#import "RKTableController.h"

@interface RKTableViewSectionTest : RKTestCase

@end

@implementation RKTableViewSectionTest

- (void)testInitializeASection
{
    RKTableSection *section = [RKTableSection section];
    assertThat(section.objects, is(notNilValue()));
    assertThat(section.objects, is(empty()));
    assertThat(section.cellMappings, is(nilValue()));
}

- (void)testInitializeASectionWithObjectsAndMappings
{
    NSArray *objects = [NSArray array];
    RKTableViewCellMappings *mappings = [RKTableViewCellMappings new];
    RKTableSection *section = [RKTableSection sectionForObjects:objects withMappings:mappings];
    assertThat(section.objects, is(notNilValue()));
    assertThat(section.cellMappings, isNot(nilValue()));
    assertThat(section.objects, is(equalTo(objects)));
    assertThat(section.cellMappings, is(equalTo(mappings)));
}

- (void)testMakeAMutableCopyOfTheObjectsItIsInitializedWith
{
    NSArray *objects = [NSArray array];
    RKTableViewCellMappings *mappings = [RKTableViewCellMappings new];
    RKTableSection *section = [RKTableSection sectionForObjects:objects withMappings:mappings];
    assertThat(section.objects, is(instanceOf([NSMutableArray class])));
}

- (void)testReturnTheNumberOfRowsInTheSection
{
    NSArray *objects = [NSArray arrayWithObject:@"first object"];
    RKTableViewCellMappings *mappings = [RKTableViewCellMappings new];
    RKTableSection *section = [RKTableSection sectionForObjects:objects withMappings:mappings];
    assertThatInt(section.rowCount, is(equalToInt(1)));
}

- (void)testReturnTheObjectAtAGivenIndex
{
    NSArray *objects = [NSArray arrayWithObject:@"first object"];
    RKTableViewCellMappings *mappings = [RKTableViewCellMappings new];
    RKTableSection *section = [RKTableSection sectionForObjects:objects withMappings:mappings];
    assertThat([section objectAtIndex:0], is(equalTo(@"first object")));
}

- (void)testInsertTheObjectAtAGivenIndex
{
    NSArray *objects = [NSArray arrayWithObject:@"first object"];
    RKTableViewCellMappings *mappings = [RKTableViewCellMappings new];
    RKTableSection *section = [RKTableSection sectionForObjects:objects withMappings:mappings];
    assertThat([section objectAtIndex:0], is(equalTo(@"first object")));
    [section insertObject:@"inserted object" atIndex:0];
    assertThat([section objectAtIndex:0], is(equalTo(@"inserted object")));
}

- (void)testRemoveTheObjectAtAGivenIndex
{
    NSArray *objects = [NSArray arrayWithObjects:@"first object", @"second object", nil];
    RKTableViewCellMappings *mappings = [RKTableViewCellMappings new];
    RKTableSection *section = [RKTableSection sectionForObjects:objects withMappings:mappings];
    assertThat([section objectAtIndex:0], is(equalTo(@"first object")));
    assertThat([section objectAtIndex:1], is(equalTo(@"second object")));
    [section removeObjectAtIndex:0];
    assertThat([section objectAtIndex:0], is(equalTo(@"second object")));
}

- (void)testReplaceTheObjectAtAGivenIndex
{
    NSArray *objects = [NSArray arrayWithObjects:@"first object", @"second object", nil];
    RKTableViewCellMappings *mappings = [RKTableViewCellMappings new];
    RKTableSection *section = [RKTableSection sectionForObjects:objects withMappings:mappings];
    assertThat([section objectAtIndex:0], is(equalTo(@"first object")));
    assertThat([section objectAtIndex:1], is(equalTo(@"second object")));
    [section replaceObjectAtIndex:0 withObject:@"new first object"];
    assertThat([section objectAtIndex:0], is(equalTo(@"new first object")));
}

- (void)testMoveTheObjectAtAGivenIndex
{
    NSArray *objects = [NSArray arrayWithObjects:@"first object", @"second object", nil];
    RKTableViewCellMappings *mappings = [RKTableViewCellMappings new];
    RKTableSection *section = [RKTableSection sectionForObjects:objects withMappings:mappings];
    assertThat([section objectAtIndex:0], is(equalTo(@"first object")));
    assertThat([section objectAtIndex:1], is(equalTo(@"second object")));
    [section moveObjectAtIndex:1 toIndex:0];
    assertThat([section objectAtIndex:0], is(equalTo(@"second object")));
    assertThat([section objectAtIndex:1], is(equalTo(@"first object")));
}

@end
