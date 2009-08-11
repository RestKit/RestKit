//
//  OTRestModelMapper.m
//  gateguru
//
//  Created by Blake Watters on 8/6/09.
//  Copyright 2009 Objective 3. All rights reserved.
//

#import "OTRestModelMapper.h"
#import "OTRestModel.h"

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
	if (XML == nil) {
		return nil;
	}
	NSString* elementName = [XML key];
	Class class = [_elementToClassMappings objectForKey:elementName];
	if (class == nil) {
		[NSException raise:@"NoClassMappingForModel" format:@"No Class Mapping for Element name '%@'", elementName];
	}
	OTRestModel* object = [class createOrUpdateAttributesFromXML:XML];
	return object;
}

@end
