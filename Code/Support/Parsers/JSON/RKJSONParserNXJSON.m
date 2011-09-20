//
//  RKJSONParserNXJSON.m
//  RestKit
//
//  Created by Evan Cordell on 7/26/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKJSONParserNXJSON.h"
#import "NXJsonParser.h"
#import "NXJsonSerializer.h"

@implementation RKJSONParserNXJSON

- (NSDictionary*)objectFromString:(NSString*)string error:(NSError**)error {
    return [NXJsonParser parseString:string error:error ignoreNulls:YES];
}

- (NSString*)stringFromObject:(id)object error:(NSError**)error {
    return [NXJsonSerializer serialize:object];
}

@end
