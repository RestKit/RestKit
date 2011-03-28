//
//  RKJSONParser+JSONKit.m
//  RestKit
//
//  Created by Jeff Arena on 3/16/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKJSONParser.h"
#import "JSONKit.h"

@implementation RKJSONParser

- (NSDictionary*)objectFromString:(NSString*)string {
	return [string objectFromJSONString];
}

- (NSString*)stringFromObject:(id)object {
	return [object JSONString];
}

@end
