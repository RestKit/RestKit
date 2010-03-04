//
//  RKModelMapper.m
//  RestKit
//
//  Created by Blake Watters on 3/4/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import <objc/message.h>

#import "RKModelMapper.h"
#import "RKMappingFormatJSONParser.h"

@implementation RKModelMapper

@synthesize format = _format;
@synthesize parser = _parser;

// private

- (id)findOrCreateMappableInstanceOf:(Class)class fromElements:(NSDictionary*)elements {
	id object = nil;
	if ([class respondsToSelector:@selector(findByPrimaryKey:)]) {
		NSString* primaryKeyElement = [class primaryKeyElement];
		NSNumber* primaryKey = [elements objectForKey:primaryKeyElement];
		object = [class findByPrimaryKey:primaryKey];
	}
	
	// instantiate if object is nil
	if (object == nil) {
		if ([class respondsToSelector:@selector(newObject)]) {
			object = [class newObject];
		} else {
			object = [[[class alloc] init] autorelease];
		}
	}
	
	return object;
}

- (id)createOrUpdateInstanceOf:(Class)class withPropertiesForElements:(NSDictionary*)elements {	
	id mappedObject = [self findOrCreateMappableInstanceOf:class fromElements:elements];
	[self setPropertiesOfObject:mappedObject fromElements:elements];
	[self setRelationshipsOfObject:mappedObject fromElements:elements];
	
	return mappedObject;
}

- (NSDictionary*)elementToPropertyMappingsForObject:(id<RKModelMappable>)object {
	return [[object class] elementToPropertyMappings];
}

#pragma mark -
#pragma mark Property Type Methods
// TODO: Move these out into another class???

- (NSString*)propertyTypeFromAttributeString:(NSString*)attributeString {
	NSString *type = [NSString string];
	NSScanner *typeScanner = [NSScanner scannerWithString:attributeString];
	[typeScanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"@"] intoString:NULL];
	
	// we are not dealing with an object
	if([typeScanner isAtEnd]) {
		return @"NULL";
	}
	[typeScanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\"@"] intoString:NULL];
	// this gets the actual object type
	[typeScanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\""] intoString:&type];
	return type;
}

- (NSDictionary *)propertyNamesAndTypesForClass:(Class)class {
	NSMutableDictionary *propertyNames = [NSMutableDictionary dictionary];
	
	//include superclass properties
	Class currentClass = class;
	while (currentClass != nil) {
		// Get the raw list of properties
		unsigned int outCount;
		objc_property_t *propList = class_copyPropertyList(currentClass, &outCount);
		
		// Collect the property names
		int i;
		NSString *propName;
		for (i = 0; i < outCount; i++) {
			// TODO: Add support for custom getter and setter methods
			// property_getAttributes() returns everything we need to implement this...
			// See: http://developer.apple.com/mac/library/DOCUMENTATION/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html#//apple_ref/doc/uid/TP40008048-CH101-SW5
			objc_property_t * prop = propList + i;
			NSString *type = [NSString stringWithCString:property_getAttributes(*prop) encoding:NSUTF8StringEncoding];
			propName = [NSString stringWithCString:property_getName(*prop) encoding:NSUTF8StringEncoding];
			if (![propName isEqualToString:@"_mapkit_hasPanoramaID"]) {
				[propertyNames setObject:[self propertyTypeFromAttributeString:type] forKey:propName];
			}
		}
		
		free(propList);
		currentClass = [currentClass superclass];
	}
	return propertyNames;
}

- (NSString*)typeNameForProperty:(NSString*)property ofClass:(Class)class {
	return [[self propertyNamesAndTypesForClass:class] objectForKey:property];
}

// TODO: Clean up the method below...
- (void)updateObject:(id)model ifNewPropertyValue:(id)propertyValue forPropertyNamed:(NSString*)propertyName {
	id currentValue = [model valueForKey:propertyName];
	if (nil == currentValue && nil == propertyValue) {
		// Don't set the property, both are nil
	} else if (nil == propertyValue || [propertyValue isKindOfClass:[NSNull class]]) {
		// Clear out the value to reset it
		[model setValue:nil forKey:propertyName];
	} else if (currentValue == nil || [currentValue isKindOfClass:[NSNull class]]) {
		// Existing value was nil, just set the property and be happy
		[model setValue:propertyValue forKey:propertyName];
	} else {
		SEL comparisonSelector;
		if ([propertyValue isKindOfClass:[NSString class]]) {
			comparisonSelector = @selector(isEqualToString:);
		} else if ([propertyValue isKindOfClass:[NSNumber class]]) {
			comparisonSelector = @selector(isEqualToNumber:);
		} else if ([propertyValue isKindOfClass:[NSDate class]]) {
			comparisonSelector = @selector(isEqualToDate:);
		} else if ([propertyValue isKindOfClass:[NSArray class]]) {
			comparisonSelector = @selector(isEqualToArray:);
		} else {
			[NSException raise:@"NoComparisonSelectorFound" format:@"You need a comparison selector for %@ (%@)", propertyName, [propertyValue class]];
		}
		
		// Comparison magic using function pointers. See this page for details: http://www.red-sweater.com/blog/320/abusing-objective-c-with-class
		// Original code courtesy of Greg Parker
		// This is necessary because isEqualToNumber will return negative integer values that aren't coercable directly to BOOL's without help [sbw]
		BOOL (*ComparisonSender)(id, SEL, id) = (BOOL (*)(id, SEL, id)) objc_msgSend;		
		BOOL areEqual = ComparisonSender(currentValue, comparisonSelector, propertyValue);
		
		if (NO == areEqual) {
			//NSLog(@"Setting property %@ to new value %@", propertyName, propertyValue);
			[model setValue:propertyValue forKey:propertyName];
		}
	}
}

- (void)setPropertiesOfObject:(id)object fromElements:(NSDictionary*)elements {
	NSDictionary* elementToPropertyMappings = [self elementToPropertyMappingsForObject:object];
	for (NSString* elementKeyPath in elementToPropertyMappings) {
		NSString* propertyName = [elementToPropertyMappings objectForKey:elementKeyPath];
//		NSString* propertyType = [self typeNameForProperty:propertyName ofClass:[object class]];
//		NSLog(@"propertyType is %@", propertyType);
		id elementValue = nil;		
		
		@try {
			elementValue = [elements valueForKeyPath:elementKeyPath];
		}
		@catch (NSException * e) {
			// TODO: Need error handling!
			NSLog(@"Encountered exception %@ when asking %@ for valueForKeyPath %@", e, elements, elementKeyPath);
		}
		
		// TODO: Need to parse date's and shit here...
		id propertyValue = elementValue;		
		[self updateObject:object ifNewPropertyValue:propertyValue forPropertyNamed:propertyName];
	}
}

- (void)setRelationshipsOfObject:(id)object fromElements:(NSDictionary*)elements {
	NSDictionary* elementToRelationshipMappings = [[object class] elementToRelationshipMappings];
	for (NSString* elementKeyPath in elementToRelationshipMappings) {
		NSString* propertyName = [elementToRelationshipMappings objectForKey:elementKeyPath];
		
		id relationshipElements = [elements valueForKeyPath:elementKeyPath];
		if ([relationshipElements isKindOfClass:[NSArray class]]) {
			// NOTE: The last part of the keyPath contains the elementName for the mapped destination class of our children
			NSArray* componentsOfKeyPath = [elementKeyPath componentsSeparatedByString:@"."];
			Class class = [_elementToClassMappings objectForKey:[componentsOfKeyPath objectAtIndex:[componentsOfKeyPath count] - 1]];
			NSMutableArray* children = [NSMutableArray arrayWithCapacity:[relationshipElements count]];
			for (NSDictionary* childElements in relationshipElements) {
				id child = [self createOrUpdateInstanceOf:class withPropertiesForElements:childElements];		
				[children addObject:child];
			}
			
			[object setValue:children forKey:propertyName];
		} else {
			Class class = [_elementToClassMappings objectForKey:elementKeyPath];
			id child = [self createOrUpdateInstanceOf:class withPropertiesForElements:relationshipElements];		
			[object setValue:child forKey:propertyName];
		}
	}
}

///////////////////////////////////////////////////////////////////////////////
// public

- (id)init {
	if (self = [super init]) {
		_elementToClassMappings = [[NSMutableDictionary alloc] init];
		_format = RKMappingFormatXML;
	}
	return self;
}

- (void)dealloc {
	[_elementToClassMappings release];
	[_parser release];
	[super dealloc];
}

- (void)registerModel:(Class)aClass forElementNamed:(NSString*)elementName {
	[_elementToClassMappings setObject:aClass forKey:elementName];
}

- (void)setFormat:(RKMappingFormat)format {
	_format = format;
	if (nil == self.parser) {
		if (RKMappingFormatJSON == _format) {
			self.parser = [[[RKMappingFormatJSONParser alloc] init] autorelease];
		} else if (RKMappingFormatXML == _format) {
			// TODO: Implement in the future...
		}
	}	
}

- (id)buildModelFromString:(NSString*)string {
	NSDictionary* dictionary = [_parser dictionaryFromString:string];
	NSString* elementName = [[dictionary allKeys] objectAtIndex:0];
	Class class = [_elementToClassMappings objectForKey:elementName];
	NSDictionary* elements = [dictionary objectForKey:elementName];
	return [self createOrUpdateInstanceOf:class withPropertiesForElements:elements];
}

- (NSArray*)buildModelsFromString:(NSString*)string {
	NSDictionary* collectionDictionary = [_parser dictionaryFromString:string];
	NSMutableArray* objects = [NSMutableArray array];
	NSString* collectionKey = [[collectionDictionary allKeys] objectAtIndex:0];
	for (NSDictionary* dictionary in [collectionDictionary objectForKey:collectionKey]) {
		NSString* elementName = [[dictionary allKeys] objectAtIndex:0];
		Class class = [_elementToClassMappings objectForKey:elementName];
		NSDictionary* elements = [dictionary objectForKey:elementName];
		id object = [self createOrUpdateInstanceOf:class withPropertiesForElements:elements];
		[objects addObject:object];
	}
	
	return (NSArray*)objects;
}

- (void)mapModel:(id)model fromString:(NSString*)string {
	// TODO
}

- (void)setAttributes:(id)object fromXML:(Element*)XML {
	// TODO: Do nothing for now...
}

- (void)setAttributes:(id)object fromJSONDictionary:(NSDictionary*)dict {
	// TODO: Do nothing for now...
}

@end
