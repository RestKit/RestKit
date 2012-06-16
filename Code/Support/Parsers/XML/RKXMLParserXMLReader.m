//
//  RKXMLParserXMLReader.m
//  RestKit
//
//  Created by Christopher Swasey on 1/24/12.
//  Copyright (c) 2012 GateGuru. All rights reserved.
//

#import "RKXMLParserXMLReader.h"

@implementation RKXMLParserXMLReader

- (id)objectFromString:(NSString *)string error:(NSError **)error
{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    return [XMLReader dictionaryForXMLData:data error:error];
}

- (NSString *)stringFromObject:(id)object error:(NSError **)error
{
    return nil;
}

@end
