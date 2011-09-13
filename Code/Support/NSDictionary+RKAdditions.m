//
//  NSDictionary+RKAdditions.m
//  RestKit
//
//  Created by Blake Watters on 9/5/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "NSDictionary+RKAdditions.h"
#import "RKFixCategoryBug.h"

RK_FIX_CATEGORY_BUG(NSDictionary_RKAdditions)

@implementation NSDictionary (RKAdditions)

+ (id)dictionaryWithKeysAndObjects:(id)firstKey, ... {
	va_list args;
    va_start(args, firstKey);
	NSMutableArray* keys = [NSMutableArray array];
	NSMutableArray* values = [NSMutableArray array];
    for (id key = firstKey; key != nil; key = va_arg(args, id)) {
		id value = va_arg(args, id);
        [keys addObject:key];
		[values addObject:value];		
    }
    va_end(args);
    
    return [self dictionaryWithObjects:values forKeys:keys];
}

- (NSDictionary *)removePercentEscapesFromKeysAndObjects {
    NSMutableDictionary *results = [NSMutableDictionary dictionaryWithCapacity:[self count]];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop)
     {
         NSString *escapedKey = [key stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
         id escapedValue = value;
         if ([value respondsToSelector:@selector(stringByReplacingPercentEscapesUsingEncoding:)])
             escapedValue = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
         [results setObject:escapedValue forKey:escapedKey];
     }];
    return results;
}

@end
