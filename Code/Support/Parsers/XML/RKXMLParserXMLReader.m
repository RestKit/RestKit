//
//  RKXMLParserXMLReader.m
//  RestKit
//
//  Created by Christopher Swasey on 1/24/12.
//  Copyright (c) 2012 GateGuru. All rights reserved.
//

#import "RKXMLParserXMLReader.h"

@implementation RKXMLParserXMLReader

- (id)objectFromData:(NSData *)data error:(NSError **)error {
    return [XMLReader dictionaryForXMLData:data error:error];
}

- (NSData *)dataFromObject:(id)object error:(NSError **)error {
    return nil;
}

@end
