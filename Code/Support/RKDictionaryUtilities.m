//
//  RKDictionaryUtilities.m
//  RestKit
//
//  Created by Blake Watters on 9/11/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKDictionaryUtilities.h"

NSDictionary * RKDictionaryByMergingDictionaryWithDictionary(NSDictionary *dict1, NSDictionary *dict2)
{
    NSMutableDictionary *mergedDictionary = [dict1 mutableCopy];

    [dict2 enumerateKeysAndObjectsUsingBlock:^(id key2, id obj2, BOOL *stop) {
        id obj1 = [dict1 valueForKey:key2];
        if ([obj1 isKindOfClass:[NSDictionary class]] && [obj2 isKindOfClass:[NSDictionary class]]) {
            NSDictionary *mergedSubdict = RKDictionaryByMergingDictionaryWithDictionary(obj1, obj2);
            [mergedDictionary setValue:mergedSubdict forKey:key2];
        } else {
            [mergedDictionary setValue:obj2 forKey:key2];
        }
    }];
    
    return [mergedDictionary copy];
}

NSDictionary * RKDictionaryByReplacingPercentEscapesInEntriesFromDictionary(NSDictionary *dictionary)
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
