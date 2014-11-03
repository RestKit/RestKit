//
//  RKDictionaryUtilities.m
//  RestKit
//
//  Created by Blake Watters on 9/11/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKDictionaryUtilities.h"

NSArray *RKInsertInDictionaryList(NSArray *list, NSDictionary *dict3, NSDictionary *dict2, NSDictionary *dict1)
{
    if (dict3 == nil && dict2 == nil && dict1 == nil)
        return list;
    NSMutableArray *newArray = [[NSMutableArray alloc] initWithArray:list];
    if (dict3)
        [newArray insertObject:dict3 atIndex:0];
    if (dict2)
        [newArray insertObject:dict2 atIndex:0];
    if (dict1)
        [newArray insertObject:dict1 atIndex:0];
    return newArray;
}

NSDictionary *RKDictionaryByMergingDictionaryWithDictionary(NSDictionary *dict1, NSDictionary *dict2)
{
    if (! dict1) return dict2;
    if (! dict2) return dict1;

    NSMutableDictionary *mergedDictionary = [dict1 mutableCopy];

    for (id key2 in dict2) {
        id obj2 = [dict2 objectForKey:key2];
        id obj1 = [dict1 objectForKey:key2];
        if ([obj1 isKindOfClass:[NSDictionary class]] && [obj2 isKindOfClass:[NSDictionary class]]) {
            NSDictionary *mergedSubdict = RKDictionaryByMergingDictionaryWithDictionary(obj1, obj2);
            [mergedDictionary setObject:mergedSubdict forKey:key2];
        } else {
            [mergedDictionary setObject:obj2 forKey:key2];
        }
    }
    
    return mergedDictionary;
}

NSDictionary *RKDictionaryByReplacingPercentEscapesInEntriesFromDictionary(NSDictionary *dictionary)
{
    NSMutableDictionary *results = [NSMutableDictionary dictionaryWithCapacity:[dictionary count]];
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop)
     {
         NSString *escapedKey = [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
         id escapedValue = value;
         if ([value respondsToSelector:@selector(stringByReplacingPercentEscapesUsingEncoding:)])
             escapedValue = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
         [results setObject:escapedValue forKey:escapedKey];
     }];
    return results;
}
