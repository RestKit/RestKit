//
//  RKMappingFormatJSONParser.m
//  RestKit
//
//  Created by Blake Watters on 3/4/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKMappingFormatJSONParser.h"

@implementation RKMappingFormatJSONParser

- (id)init {
	if (self = [super init]) {
		_parser = [[SBJSON alloc] init];
	}
	
	return self;
}

- (void)dealloc {
	[_parser release];
	[super dealloc];
}

- (NSDictionary*)objectFromString:(NSString*)string {
	id result = [_parser objectWithString:string];
	if (nil == result) {
		// TODO: Need to surface these errors in a better fashion
		NSLog(@"[RestKit] RKMappingFormatJSONParser: Parser failed with error trace: %@ and string: %@", _parser.errorTrace, string);
	}
	
	return result;
}

@end
