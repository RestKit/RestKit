//
//  NSObject+KVCArray.m
//  RestKit
//
//  Created by Oli on 17/05/2015.
//  Copyright (c) 2015 RestKit. All rights reserved.
//

#import "NSObject+KVCArray.h"

@implementation NSObject (KVCArray)

- (id)valueForIndexedKeyPath:(NSString *)keyPath
{
    NSRegularExpression *testExpression = [NSRegularExpression regularExpressionWithPattern: @"\\[(0-9)+\\]" options:0 error:nil];
    
    NSArray *matches = [testExpression matchesInString:keyPath
                                               options:0
                                                 range:NSMakeRange(0, [keyPath length])];
    
    //If no idexes found, continue with regular KVC
    if(!matches.count){
        return [self valueForKeyPath:keyPath];
    }
    
    id value = self;
    NSUInteger offset = 0;
    int i = 0;
    
    for (NSTextCheckingResult *result in matches) {
        NSRange range = result.range;
        
        NSString *keyPathPart = [keyPath substringWithRange:NSMakeRange(offset, range.location - 1 - offset)];
        
        //Set the new offset in case there are more matches
        offset = range.location + range.length+2; //+2 for ].
        
        //Get the regular KVC value
        value = [value valueForKeyPath:keyPathPart];
        
        //If value is not an array, bail out
        if(![value isKindOfClass:[NSArray class]]){
            NSLog(@"Key Path %@ contains array access, but value is not an array: %@", keyPath, value);
            value = nil;
            break;
        }
        
        //Ensure index exists in array
        NSArray *array = (NSArray*)value;
        NSUInteger index = [[keyPath substringWithRange:range] integerValue];
        if(index >= array.count){
            NSLog(@"Key Path %@ contains array access to index: %lu but array contains only %lu items. %@", keyPath, (unsigned long)index, (unsigned long)array.count, array);
            value = nil;
            break;
        }
        
        //Assign new value as index of array
        value = array[index];
        
        //If this is the last match, attempt to KVC the rest of the key path
        if(i == matches.count-1){
            value = [value valueForKeyPath:[keyPath substringWithRange:NSMakeRange(offset, keyPath.length - offset)]];
        }
        
        i++;
    }
    
    return value;
}

@end
