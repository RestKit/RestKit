//
//  RKMappingFormatJSONParser+YAJL.m
//  RestKit
//
//  Created by Blake Watters on 9/28/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKJSONParser.h"
#import "YAJL.h"

@implementation RKJSONParser

- (NSDictionary*)objectFromString:(NSString*)string {
	return [string yajl_JSON];
}

- (NSString*)stringFromObject:(id)object {
	return [object yajl_JSONString];
}

@end
