//
//  RKJSONParser+SBJSON.m
//  RestKit
//
//  Created by Blake Watters on 3/4/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKJSONParser.h"
#import "SBJsonParser.h"
#import "NSObject+SBJSON.h"

@implementation RKJSONParser

- (NSDictionary*)objectFromString:(NSString*)string {
	SBJsonParser* parser = [[SBJsonParser alloc] init];
	id result = [parser objectWithString:string];
	if (nil == result) {
		// TODO: Need to surface these errors in a better fashion
		NSLog(@"[RestKit] RKMappingFormatJSONParser: Parser failed with error trace: %@ and string: %@", [parser errorTrace], string);
	}
	[parser release];
	
	return result;
}

- (NSString*)stringFromObject:(id)object {
	return [object JSONRepresentation];
}

@end
