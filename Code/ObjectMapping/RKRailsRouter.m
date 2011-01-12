//
//  RKRailsRouter.m
//  RestKit
//
//  Created by Blake Watters on 10/18/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKRailsRouter.h"
#import "../Support/NSString+InflectionSupport.h"

@implementation RKRailsRouter

- (id)init {
	if (self = [super init]) {
		_classToModelMappings = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

- (void)dealloc {
	[_classToModelMappings release];	
	[super dealloc];
}

- (void)setModelName:(NSString*)modelName forClass:(Class<RKObjectMappable>)class {
	[_classToModelMappings setObject:modelName forKey:class];
}

- (NSDictionary*)elementNamesAndPropertyValuesForObject:(NSObject<RKObjectMappable>*)object {
	NSDictionary* mappings = [[object class] elementToPropertyMappings];
	NSMutableDictionary* elementsAndPropertyValues = [NSMutableDictionary dictionaryWithCapacity:[mappings count]];
	// Return all the properties of this model in a dictionary under their element names
	for (NSString* elementName in mappings) {
		NSString* propertyName = [mappings valueForKey:elementName];
		id propertyValue = [object valueForKey:propertyName];
		[elementsAndPropertyValues setValue:propertyValue forKey:elementName];
	}
	
	return (NSDictionary*) elementsAndPropertyValues;
}

#pragma mark RKRouter

- (NSObject<RKRequestSerializable>*)serializationForObject:(NSObject<RKObjectMappable>*)object method:(RKRequestMethod)method {
	// Rails does not send parameters for delete requests.
	if (method == RKRequestMethodDELETE) {
		return nil;
	}
	
	NSDictionary* elementsAndProperties = [self elementNamesAndPropertyValuesForObject:object];
	NSMutableDictionary* resourceParams = [NSMutableDictionary dictionaryWithCapacity:[elementsAndProperties count]];	
	NSString* modelName = [_classToModelMappings objectForKey:[object class]];
	if (nil == modelName) {
		NSString* className = NSStringFromClass([object class]);
		[NSException raise:nil format:@"Unable to find registered modelName for class '%@'", className];
	}
	
	NSString* underscoredModelName = [modelName underscore];
	
	for (NSString* elementName in [elementsAndProperties allKeys]) {
		id value = [elementsAndProperties valueForKey:elementName];
		NSString* attributeName = [elementName stringByReplacingOccurrencesOfString:@"-" withString:@"_"];
		if (![attributeName isEqualToString:@"id"]) {
			NSString* keyName = [NSString stringWithFormat:@"%@[%@]", underscoredModelName, attributeName];
			[resourceParams setValue:value forKey:keyName];
		}
	}
	
	return resourceParams;
}

@end
