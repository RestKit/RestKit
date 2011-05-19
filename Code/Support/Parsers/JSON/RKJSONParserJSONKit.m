//
//  RKJSONParserJSONKit.m
//  RestKit
//
//  Created by Jeff Arena on 3/16/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKJSONParserJSONKit.h"
#import "JSONKit.h"

// TODO: JSONKit serializer instance should be reused to enable leverage
// the internal cacheing capabilities from the JSONKit serializer
@implementation RKJSONParserJSONKit

- (NSDictionary*)objectFromString:(NSString*)string error:(NSError**)error {
    return [string objectFromJSONStringWithParseOptions:JKParseOptionStrict error:error];
}

- (NSString*)stringFromObject:(id)object error:(NSError**)error {
	return [object JSONStringWithOptions:JKSerializeOptionNone error:error];
}

@end
