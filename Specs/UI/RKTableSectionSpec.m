//
//  RKTableViewSectionSpec.m
//  RestKit
//
//  Created by Blake Watters on 8/3/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKTableSection.h"
#import "RKTableViewCellMappings.h"
#import "RKTableViewCellMapping.h"
#import "RKTableController.h"

@interface RKTableViewSectionSpec : RKSpec <RKSpecUI>

@end

@implementation RKTableViewSectionSpec

- (void)itShouldInitializeASection {
    RKTableSection* section = [RKTableSection section];
    assertThat(section.objects, is(notNilValue()));
    assertThat(section.objects, is(empty()));
    assertThat(section.cellMappings, is(nilValue()));    
}

- (void)itShouldInitializeASectionWithObjectsAndMappings {
    NSArray* objects = [NSArray array];
    RKTableViewCellMappings* mappings = [RKTableViewCellMappings new];
    RKTableSection* section = [RKTableSection sectionForObjects:objects withMappings:mappings];
    assertThat(section.objects, is(notNilValue()));
    assertThat(section.cellMappings, isNot(nilValue()));
    assertThat(section.objects, is(equalTo(objects)));
    assertThat(section.cellMappings, is(equalTo(mappings)));
}

- (void)itShouldMakeAMutableCopyOfTheObjectsItIsInitializedWith {
    NSArray* objects = [NSArray array];
    RKTableViewCellMappings* mappings = [RKTableViewCellMappings new];
    RKTableSection* section = [RKTableSection sectionForObjects:objects withMappings:mappings];
    assertThat(section.objects, is(instanceOf([NSMutableArray class])));
}

- (void)itShouldReturnTheNumberOfRowsInTheSection {
    NSArray* objects = [NSArray arrayWithObject:@"first object"];
    RKTableViewCellMappings* mappings = [RKTableViewCellMappings new];
    RKTableSection* section = [RKTableSection sectionForObjects:objects withMappings:mappings];
    assertThatInt(section.rowCount, is(equalToInt(1)));
}

- (void)itShouldReturnTheObjectAtAGivenIndex {
    NSArray* objects = [NSArray arrayWithObject:@"first object"];
    RKTableViewCellMappings* mappings = [RKTableViewCellMappings new];
    RKTableSection* section = [RKTableSection sectionForObjects:objects withMappings:mappings];
    assertThat([section objectAtIndex:0], is(equalTo(@"first object")));
}

- (void)itShouldInsertTheObjectAtAGivenIndex {
    NSArray* objects = [NSArray arrayWithObject:@"first object"];
    RKTableViewCellMappings* mappings = [RKTableViewCellMappings new];
    RKTableSection* section = [RKTableSection sectionForObjects:objects withMappings:mappings];
    assertThat([section objectAtIndex:0], is(equalTo(@"first object")));
    [section insertObject:@"inserted object" atIndex:0];
    assertThat([section objectAtIndex:0], is(equalTo(@"inserted object")));
}

- (void)itShouldRemoveTheObjectAtAGivenIndex {
    NSArray* objects = [NSArray arrayWithObjects:@"first object", @"second object", nil];
    RKTableViewCellMappings* mappings = [RKTableViewCellMappings new];
    RKTableSection* section = [RKTableSection sectionForObjects:objects withMappings:mappings];
    assertThat([section objectAtIndex:0], is(equalTo(@"first object")));
    assertThat([section objectAtIndex:1], is(equalTo(@"second object")));
    [section removeObjectAtIndex:0];
    assertThat([section objectAtIndex:0], is(equalTo(@"second object")));
}

- (void)itShouldReplaceTheObjectAtAGivenIndex {
    NSArray* objects = [NSArray arrayWithObjects:@"first object", @"second object", nil];
    RKTableViewCellMappings* mappings = [RKTableViewCellMappings new];
    RKTableSection* section = [RKTableSection sectionForObjects:objects withMappings:mappings];
    assertThat([section objectAtIndex:0], is(equalTo(@"first object")));
    assertThat([section objectAtIndex:1], is(equalTo(@"second object")));
    [section replaceObjectAtIndex:0 withObject:@"new first object"];
    assertThat([section objectAtIndex:0], is(equalTo(@"new first object")));
}

- (void)itShouldMoveTheObjectAtAGivenIndex {
    NSArray* objects = [NSArray arrayWithObjects:@"first object", @"second object", nil];
    RKTableViewCellMappings* mappings = [RKTableViewCellMappings new];
    RKTableSection* section = [RKTableSection sectionForObjects:objects withMappings:mappings];
    assertThat([section objectAtIndex:0], is(equalTo(@"first object")));
    assertThat([section objectAtIndex:1], is(equalTo(@"second object")));
    [section moveObjectAtIndex:1 toIndex:0];
    assertThat([section objectAtIndex:0], is(equalTo(@"second object")));
    assertThat([section objectAtIndex:1], is(equalTo(@"first object")));
}

@end
