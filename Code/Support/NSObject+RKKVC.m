//
//  NSObject+RKKVC.m
//  RestKit
//
//  Created by Simon Booth on 31/07/2013.
//  Copyright (c) 2013 RestKit. All rights reserved.
//

#import "NSObject+RKKVC.h"

@protocol RKObjectWithAllKeys <NSObject>

- (NSArray *)allKeys;

@end

@implementation NSObject (RKKVC)

- (NSString *)rk_firstKeyInKeyPath:(NSString *)keyPath
{
    if ([self respondsToSelector:@selector(allKeys)]) {
        for (NSString *key in [(id<RKObjectWithAllKeys>)self allKeys]) {
            if ([keyPath isEqualToString:key] || [keyPath hasPrefix:[key stringByAppendingString:@"."]]) {
                return key;
            }
        }
    }
    
    NSArray *keys = [keyPath componentsSeparatedByString:@"."];
    if (keys.count > 0) return keys[0];
    return nil;
}

- (id)rk_firstValueForKeyPath:(NSString *)keyPath outKeyPath:(NSString **)outKeyPath
{
    id value = nil;
    NSString *key = [self rk_firstKeyInKeyPath:keyPath];
    
    if (key.length > 0)
    {
        value = [self valueForKey:key];
        
        if (outKeyPath) {
            if (key.length >= keyPath.length) {
                keyPath = nil;
            } else {
                keyPath = [keyPath substringFromIndex:key.length + 1];
            }
            
            *outKeyPath = keyPath;
        }
    }
    
    return value;
}

- (id)rk_valueForKeyPath:(NSString *)keyPath
{
    id value = self;
    
    while (keyPath.length > 0)
    {
        NSString *newKeyPath = nil;
        value = [value rk_firstValueForKeyPath:keyPath outKeyPath:&newKeyPath];
        keyPath = newKeyPath;
    }
    
    return value;
}

@end
