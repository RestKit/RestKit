//
//  RKJSONParserSBJSON.m
//  RestKit
//
//  Created by Blake Watters on 3/4/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKJSONParserSBJSON.h"
#import "SBJsonParser.h"
#import "SBJsonWriter.h"

@implementation RKJSONParserSBJSON

- (NSDictionary*)objectFromString:(NSString*)string error:(NSError **)error {
	SBJsonParser* parser = [[SBJsonParser alloc] init];
	id result = [parser objectWithString:string];
	if (nil == result) {
        if (error) *error = [[parser errorTrace] lastObject];
	}
	[parser release];
	
	return result;
}

- (NSString*)stringFromObject:(id)object error:(NSError **)error {
    SBJsonWriter *jsonWriter = [SBJsonWriter new];    
    NSString *json = [jsonWriter stringWithObject:object];
    if (!json) {
        if (error) *error = [[jsonWriter errorTrace] lastObject];
    }
    [jsonWriter release];
    return json;
}

@end
