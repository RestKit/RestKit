//
//  NSDictionary+RKAdditions.m
//  RestKit
//
//  Created by Blake Watters on 9/5/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "NSDictionary+RKAdditions.h"

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

@end
