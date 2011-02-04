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
	NSError* error = nil;
	NSDictionary* json = [string yajl_JSON:&error];
	if (error) {
		NSLog(@"Encountered error: %@ parsing json strong: %@", error, string);
	}
	return json;
}

- (NSString*)stringFromObject:(id)object {
	return [object yajl_JSONString];
}

@end
