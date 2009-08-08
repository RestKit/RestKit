//
//  OTRestModelMapper.m
//  gateguru
//
//  Created by Blake Watters on 8/6/09.
//  Copyright 2009 Objective 3. All rights reserved.
//

#import "OTRestModelMapper.h"


@implementation OTRestModelMapper

- (id)init {
	if (self = [super init]) {
		_elementToClassMappings = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

- (void)dealloc {
	[_elementToClassMappings release];
	[super dealloc];
}

- (void)registerModel:(Class)class forElementNamed:(NSString*)elementName {
	[_elementToClassMappings setObject:class forKey:elementName];
}

- (id)buildModelFromXML:(Element*)XML {
	NSString* elementName = [XML key];
	Class class = [_elementToClassMappings objectForKey:elementName];
	id object = [[class alloc] init];
	[object setAttributesFromXML:XML];	
	return object;
}

@end
