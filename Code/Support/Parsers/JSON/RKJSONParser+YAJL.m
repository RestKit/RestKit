//
//  RKMappingFormatJSONParser+YAJL.m
//  RestKit
//
//  Created by Blake Watters on 9/28/10.
//
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
