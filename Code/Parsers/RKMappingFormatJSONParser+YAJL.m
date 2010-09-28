//
//  RKMappingFormatJSONParser+YAJL.m
//  RestKit
//
//  Created by Blake Watters on 9/28/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKMappingFormatJSONParser.h"
#import "YAJL.h"

@implementation RKMappingFormatJSONParser

- (NSDictionary*)objectFromString:(NSString*)string {
	return [string yajl_JSON];
}

@end
