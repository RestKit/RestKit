//
//  RKJSONSerialization.m
//  RestKit
//
//  Created by Blake Watters on 7/8/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKJSONSerialization.h"
#import "NSObject+SBJSON.h"

@implementation RKJSONSerialization

+ (id)JSONSerializationWithObject:(NSObject*)object {
	return [[[self alloc] initWithObject:object] autorelease];
}

- (id)initWithObject:(NSObject*)object {
	if (self = [self init]) {
		_object = [object retain];
	}
	
	return self;
}

- (void)dealloc {	
	[_object release];
	[super dealloc];
}

- (NSString*)ContentTypeHTTPHeader {
	return @"application/json";
}

- (NSString*)JSONRepresentation {
	return [_object JSONRepresentation];
}

- (NSData*)HTTPBody {	
	return [[self JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding];
}

- (BOOL)isEqual:(id)object {
	if ([object isKindOfClass:[NSString class]]) {
		return [[self JSONRepresentation] isEqualToString:object];
	} if ([object respondsToSelector:@selector(JSONRepresentation)]) {
		return [[self JSONRepresentation] isEqualToString:[(NSObject*)object JSONRepresentation]];
	} else {
		return NO;
	}
}

@end
