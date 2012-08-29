//
//  NSArray+RKAdditions.m
//  RestKit
//
//  Created by Blake Watters on 4/10/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
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
