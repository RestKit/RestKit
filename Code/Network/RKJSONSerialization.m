//
//  RKJSONSerialization.m
//  RestKit
//
//  Created by Blake Watters on 7/8/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKJSONSerialization.h"
#import "NSObject+RKJSONSerialization.h"
#import "RKJSONParser.h"

@implementation RKJSONSerialization

+ (id)JSONSerializationWithObject:(NSObject*)object {
	return [[[self alloc] initWithObject:object] autorelease];
}

- (id)initWithObject:(NSObject*)object {
    self = [self init];
	if (self) {
		_object = [object retain];
	}
	
	return self;
}

- (void)dealloc {	
	[_object release];
	[super dealloc];
}

- (NSString*)HTTPHeaderValueForContentType {
	return @"application/json";
}

- (NSString*)JSONRepresentation {
	return [[[[RKJSONParser alloc] init] autorelease] stringFromObject:_object];
}

- (NSData*)HTTPBody {	
	return [[self JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding];
}

- (BOOL)isEqual:(id)object {
	if ([object isKindOfClass:[NSString class]]) {
		return [[self JSONRepresentation] isEqualToString:object];
	} else {
		NSString* string = [[[[RKJSONParser alloc] init] autorelease] stringFromObject:object];
		return [[self JSONRepresentation] isEqualToString:string];
	}
}

@end
