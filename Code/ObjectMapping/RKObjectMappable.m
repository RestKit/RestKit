//
//  RKObjectMappable.m
//  RestKit
//
//  Created by Blake Watters on 1/20/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKObjectMappable.h"

// Return all the mapped properties of object in a dictionary
NSDictionary* RKObjectMappableGetProperties(NSObject<RKObjectMappable>*object) {
	NSDictionary* mappings = [[object class] elementToPropertyMappings];
	NSMutableDictionary* propertyNamesAndValues = [NSMutableDictionary dictionaryWithCapacity:[mappings count]];
	// Return all the properties of this model in a dictionary under their element names
	for (NSString* elementName in mappings) {
		NSString* propertyName = [mappings valueForKey:elementName];
		id propertyValue = [object valueForKey:propertyName];
		[propertyNamesAndValues setValue:propertyValue forKey:propertyName];
	}
	
	return [NSDictionary dictionaryWithDictionary:propertyNamesAndValues];
}

// Return all the mapped properties of object in a dictionary under their element names
NSDictionary* RKObjectMappableGetPropertiesByElement(NSObject<RKObjectMappable>*object) {
	NSDictionary* mappings = [[object class] elementToPropertyMappings];
	NSMutableDictionary* elementsAndPropertyValues = [NSMutableDictionary dictionaryWithCapacity:[mappings count]];
	
	for (NSString* elementName in mappings) {
		NSString* propertyName = [mappings valueForKey:elementName];
		id propertyValue = [object valueForKey:propertyName];
		[elementsAndPropertyValues setValue:propertyValue forKey:elementName];
	}
	
	return [NSDictionary dictionaryWithDictionary:elementsAndPropertyValues];
}
