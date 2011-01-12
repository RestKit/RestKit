//
//  RKObject.m
//  RestKit
//
//  Created by Blake Watters on 7/20/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKObject.h"

@implementation RKObject

+ (NSDictionary*)elementToPropertyMappings {
	[self doesNotRecognizeSelector:_cmd];
	return nil;
}

+ (NSDictionary*)elementToRelationshipMappings {
	return [NSDictionary dictionary];
}

+ (id)object {
	return [[self new] autorelease];
}

- (id<RKRequestSerializable>)paramsForSerialization {
	NSMutableDictionary* params = [NSMutableDictionary dictionary];
	for (NSString* elementName in [[self class] elementToPropertyMappings]) {
		NSString* propertyName = [[[self class] elementToPropertyMappings] objectForKey:elementName];
		[params setValue:[self valueForKey:propertyName] forKey:elementName];
	}
	
	return [NSDictionary dictionaryWithDictionary:params];
}

@end
