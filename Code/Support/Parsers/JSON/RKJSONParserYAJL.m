//
//  RKMappingFormatJSONParserYAJL.m
//  RestKit
//
//  Created by Blake Watters on 9/28/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKJSONParserYAJL.h"
#import "YAJL.h"

@implementation RKJSONParserYAJL

- (NSDictionary*)objectFromString:(NSString*)string error:(NSError **)error {
	return [string yajl_JSON:error];
}

- (NSString*)stringFromObject:(id)object error:(NSError **)error {
	return [object yajl_JSONStringWithOptions:YAJLGenOptionsIncludeUnsupportedTypes indentString:@"  "];
}

@end
