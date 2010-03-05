//
//  RKMappingFormatJSONParser.m
//  RestKit
//
//  Created by Blake Watters on 3/4/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKMappingFormatJSONParser.h"
#import "JSON.h"

@implementation RKMappingFormatJSONParser

- (NSDictionary*)objectFromString:(NSString*)string {
	return [[[[SBJSON alloc] init] autorelease] objectWithString:string];
}

@end
