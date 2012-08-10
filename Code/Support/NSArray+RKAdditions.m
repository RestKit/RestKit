//
//  NSArray+RKAdditions.m
//  RestKit
//
//  Created by Blake Watters on 4/10/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "NSArray+RKAdditions.h"

@implementation NSArray (RKAdditions)

- (NSArray *)sectionsGroupedByKeyPath:(NSString *)keyPath
{
    // Code adapted from: https://gist.github.com/1243312
    NSMutableArray *sections = [NSMutableArray array];

    // If we don't contain any items, return an empty collection of sections.
    if ([self count] == 0) {
        return sections;
    }

    // Create the first section and establish the first section's grouping value.
    NSMutableArray *sectionItems = [NSMutableArray array];
    id currentGroup = [[self objectAtIndex:0] valueForKeyPath:keyPath];

    // Iterate over our items, placing them in the appropriate section and
    // creating new sections when necessary.
    for (id item in self) {
        // Retrieve the grouping value from the current item.
        id itemGroup = [item valueForKeyPath:keyPath];

        // Compare the current item's grouping value to the current section's
        // grouping value.
        if (![itemGroup isEqual:currentGroup] && (currentGroup != nil || itemGroup != nil)) {
            // The current item doesn't belong in the current section, so
            // store the section we've been building and create a new one,
            // caching the new grouping value.
            [sections addObject:sectionItems];
            sectionItems = [NSMutableArray array];
            currentGroup = itemGroup;
        }

        // Add the item to the appropriate section.
        [sectionItems addObject:item];
    }

    // If we were adding items to a section that has not yet been added
    // to the aggregate section collection, add it now.
    if ([sectionItems count] > 0) {
        [sections addObject:sectionItems];
    }

    return sections;
}

@end
