//
//  RKJSONParserURLEncode.m
//  RestKit
//
//  Created by Cemal Eker on 9/6/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKURLEncodeParser.h"
#import "NSDictionary+RKAdditions.h"

@implementation RKURLEncodeParser

- (id)objectFromString:(NSString *)string error:(NSError **)error {
    return [NSDictionary dictionaryWithURLEncodedString:string];
}

- (NSString *)stringFromObject:(id)object error:(NSError **)error {
    NSAssert([object isKindOfClass:[NSDictionary class]], @"URL Encode object must be instance of NSDictionary");
    return [(NSDictionary *)object stringWithURLEncodedEntries];
    
}

@end
