//
//  RKDictionaryUtilities.m
//  RestKit
//
//  Created by Blake Watters on 9/11/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKDictionaryUtilities.h"

NSDictionary *RKDictionaryByMergingDictionaryWithDictionary(NSDictionary *dict1, NSDictionary *dict2)
{
    if (! dict1) return dict2;
    if (! dict2) return dict1;

    NSMutableDictionary *mergedDictionary = [dict1 mutableCopy];

    for (id key2 in dict2) {
        id obj2 = dict2[key2];
        id obj1 = dict1[key2];
        if ([obj1 isKindOfClass:[NSDictionary class]] && [obj2 isKindOfClass:[NSDictionary class]]) {
            NSDictionary *mergedSubdict = RKDictionaryByMergingDictionaryWithDictionary(obj1, obj2);
            mergedDictionary[key2] = mergedSubdict;
        } else {
            mergedDictionary[key2] = obj2;
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
         results[escapedKey] = escapedValue;
     }];
    return results;
}
