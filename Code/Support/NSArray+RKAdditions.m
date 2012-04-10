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
    NSString *keyPathWithOperator = [NSString stringWithFormat:@"@distinctUnionOfObjects.%@", keyPath];
    NSArray *sectionValues = [self valueForKeyPath:keyPathWithOperator];
    NSMutableArray *sections = [NSMutableArray arrayWithCapacity:[sectionValues count]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = $sectionValue", keyPath];
    for (id value in sectionValues) {
        NSDictionary *sub = [NSDictionary dictionaryWithObject:value forKey:@"sectionValue"];
        NSPredicate *sectionPredicate = [predicate predicateWithSubstitutionVariables:sub];
        NSArray *objectsForSection = [self filteredArrayUsingPredicate:sectionPredicate];
        [sections addObject:objectsForSection];
    }
    
    return [NSArray arrayWithArray:sections];
}

@end
