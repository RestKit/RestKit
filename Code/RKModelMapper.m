//
// RKModelMapper.m
//  RestKit
//
//  Created by Blake Watters on 8/14/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import <objc/message.h>
#import "RKModelMapper.h"
#import "RKModelMapper_Private.h"
#import "ElementParser.h"
#import "JSON.h"

// Used for detecting property types at runtime
#import <objc/runtime.h>

@implementation RKModelMapper

@synthesize format = _format;

- (id)init {
	if (self = [super init]) {
		_elementToClassMappings = [[NSMutableDictionary alloc] init];
		_format = RKMappingFormatXML;
	}
	return self;
}

- (void)dealloc {
	[_elementToClassMappings release];
	[super dealloc];
}

- (BOOL)mappingFromJSON {
	return _format == RKMappingFormatJSON;
}

- (BOOL)mappingFromXML {
	return _format == RKMappingFormatXML;
}

// TODO: This is fragile. Prevents you from changing parsing styles on the fly.
- (void)registerModel:(Class)aClass forElementNamed:(NSString*)elementName {
	NSString* formattedElementName = nil;
	if ([aClass respondsToSelector:@selector(formatElementName:forMappingFormat:)]) {
		formattedElementName = [aClass formatElementName:elementName forMappingFormat:_format];
	} else {
		formattedElementName = elementName;
	}
	[_elementToClassMappings setObject:aClass forKey:formattedElementName];
}

- (id)buildModelFromString:(NSString*)string {
	id object = nil;
	if ([self mappingFromJSON]) {
		object = [self buildModelFromJSON:string];
	} else if ([self mappingFromXML]) {
		Element* e = [[[[[ElementParser alloc] init] autorelease] parseXML:string] firstChild];
		object = [self buildModelFromXML:e];
	} else {
		[NSException raise:@"No Parsing Style Set" format:@"you must specify a valid mapping format"];
	}
	return object;
}

- (NSArray*)buildModelsFromString:(NSString*)string {
	NSMutableArray* objects = [NSMutableArray array];
	if ([self mappingFromJSON]) {
		NSArray* collectionDicts = [[[[SBJSON alloc] init] autorelease] objectWithString:string];
		for (NSDictionary* dict in collectionDicts) {
			id object = [self buildModelFromJSONDictionary:dict];
			[objects addObject:object];
		}		
	} else if ([self mappingFromXML]) {
		Element* collectionElement = [[[[[ElementParser alloc] init] autorelease] parseXML:string] firstChild];
		for (Element* e in [collectionElement childElements]) {
			id object = [self buildModelFromXML:e];
			[objects addObject:object];
		}
	} else {
		[NSException raise:@"No Parsing Style Set" format:@"you must specify a valid mapping format"];
	}
	return (NSArray*)objects;
}

#pragma mark -
#pragma mark shared parsing behavior

- (void)updateObject:(id)model ifNewPropertyPropertyValue:(id)propertyValue forPropertyNamed:(NSString*)propertyName {
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

#pragma mark -
#pragma mark JSON Parsing

- (id)buildModelFromJSON:(NSString*)JSON {
	SBJsonParser* parser = [[[SBJsonParser alloc] init] autorelease];
	NSDictionary* jsonDict = [parser objectWithString:JSON];
	if (jsonDict == nil) {
		// TODO: We do not handle parsing error worth a damn!
		NSLog(@"Unable to parse JSON fragment: %@", JSON);
		[NSException raise:@"UnableToParseJSON" format:@"An error occurred while processing the JSON"];
		return nil;
	}
	return [self buildModelFromJSONDictionary:jsonDict];
}

- (id)buildModelFromJSONDictionary:(NSDictionary*)dict {
	assert([[dict allKeys] count] == 1);
	NSString* keyName = [[dict allKeys] objectAtIndex:0];
	Class class = [_elementToClassMappings objectForKey:keyName];
	
	return [self createOrUpdateInstanceOf:class fromJSONDictionary:[dict objectForKey:keyName]];
}

- (id)createOrUpdateInstanceOf:(Class)class fromJSONDictionary:(NSDictionary*)dict {
	id object = nil;
	if ([class respondsToSelector:@selector(findByPrimaryKey:)]) {
		// TODO: factor to class method? incase it is not a number
		NSString* primaryKey = nil;
		if ([class respondsToSelector:@selector(formatElementName:forMappingFormat:)]) {
			primaryKey = [class formatElementName:[class primaryKeyElement] forMappingFormat:RKMappingFormatJSON];
		} else {
			primaryKey = [class primaryKeyElement];
		}
		NSNumber* pk = [dict objectForKey:primaryKey];
		object = [class findByPrimaryKey:pk];
	}
	// instantiate if object is nil
	if (object == nil) {
		if ([class respondsToSelector:@selector(newObject)]) {
			object = [class newObject];
		} else {
			object = [[[class alloc] init] autorelease];
		}
	}
	// check to see if we should hand the object the JSON to set it's own properties
	// (custom implementation)
	if ([object respondsToSelector:@selector(digestJSONDictionary:)]) {
		[object digestJSONDictionary:dict];
	}  else {
		// update attributes
		[self setAttributes:object fromJSONDictionary:dict];
	}
	return object;
}

- (void)setAttributes:(id)object fromJSONDictionary:(NSDictionary*)dict {
	[self setPropertiesOfModel:object fromJSONDictionary:dict];
	[self setRelationshipsOfModel:object fromJSONDictionary:dict];
}

- (NSString*)selectorFromMapping:(id)mapping forMappingFormat:(RKMappingFormat)format {
	if ([mapping isKindOfClass:[NSArray class]]) {
		if (RKMappingFormatXML == format) {
			return [(NSArray*)mapping objectAtIndex:0];
		} else if (RKMappingFormatJSON == format) {
			return [(NSArray*)mapping objectAtIndex:1];
		}
	} else {
		return mapping;
	}
}

- (void)setPropertiesOfModel:(id)model fromJSONDictionary:(NSDictionary*)dict {
	for (id mapping in [[model class] elementToPropertyMappings]) {		
		NSString* propertyName = [[[model class] elementToPropertyMappings] objectForKey:mapping];
		NSString* selector = [self selectorFromMapping:mapping forMappingFormat:RKMappingFormatJSON];
		NSString* propertyType = [self typeNameForProperty:propertyName ofClass:[model class] typeHint:nil];
		NSString* elementName = nil;
		
		// TODO: This shit needs to go...
		if ([mapping isKindOfClass:[NSString class]] && [[model class] respondsToSelector:@selector(formatElementName:forMappingFormat:)]) {
			elementName = [[model class] formatElementName:selector forMappingFormat:RKMappingFormatJSON];
		} else {
			elementName = selector;
		}
		
//		id propertyValue = [dict objectForKey:elementName];
		id propertyValue = nil;
		@try {
			propertyValue = [dict valueForKeyPath:elementName];
		}
		@catch (NSException * e) {
			NSLog(@"Encountered exception %@ when asking %@ for valueForKeyPath %@", e, dict, elementName);
		}
		//NSLog(@"Asked JSON dictionary %@ for object with key %@. Got %@", dict, elementName, propertyValue);
		
		// Types of objects SBJSON does not handle:
		if ([propertyType isEqualToString:@"NSDate"]) {
			NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
			// Times coming back are in utc. we should convert them to the local timezone
			// TODO: Make sure this is working correctly
			[formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
			[formatter setDateFormat:kRailsToXMLDateFormatterString];
			propertyValue = [formatter dateFromString:propertyValue];
			[formatter release];			
		}
		
		[self updateObject:model ifNewPropertyPropertyValue:propertyValue forPropertyNamed:propertyName];
	}
}

- (void)setRelationshipsOfModel:(id)model fromJSONDictionary:(NSDictionary*)dict {
	for (NSString* selector in [[model class] elementToRelationshipMappings]) {
		NSString* propertyName = [[[model class] elementToRelationshipMappings] objectForKey:selector];
		if ([self isParentSelector:selector]) {
			NSMutableSet* children = [NSMutableSet set];
			// If the collection key doesn't appear, we will not set the collection to nil.
			NSString* collectionKey = [self containingElementNameForSelector:selector];
			// Used to figure out what class to map to, since we don't have element names for the dictionaries in the array
			NSString* objectKey = [self childElementNameForSelector:selector];
			NSArray* objects = [dict objectForKey:collectionKey];
			if (objects != nil) {
				for (NSDictionary* childDict in objects) {
					Class class = [_elementToClassMappings objectForKey:objectKey];
					[children addObject:[self createOrUpdateInstanceOf:class fromJSONDictionary:childDict]];
				}
				[model setValue:(NSSet*)children forKey:propertyName];
			}
		} else {
			// TODO: This shit needs to go...
			NSString* elementName = nil;
			if ([[model class] respondsToSelector:@selector(formatElementName:forMappingFormat:)]) {
				elementName = [[model class] formatElementName:selector forMappingFormat:RKMappingFormatJSON];
			} else {
				elementName = selector;
			}
			
			NSDictionary* objectDict = [dict objectForKey:elementName];
			Class class = [_elementToClassMappings objectForKey:elementName];
			id child = [self createOrUpdateInstanceOf:class fromJSONDictionary:objectDict];
			[model setValue:child forKey:propertyName];
		}
	}
}

#pragma mark -
#pragma mark XML Parsing

- (id)buildModelFromXML:(Element*)XML {
	if (XML == nil) {
		return nil;
	}
	NSString* elementName = [XML key];
	Class class = [_elementToClassMappings objectForKey:elementName];
	if (class == nil) {
		NSLog(@"Encountered an unmapped class while processing XML Element: %@", XML);
		[NSException raise:@"NoClassMappingForModel" format:@"No Class Mapping for Element name '%@'", elementName];
	}
	id object = [self createOrUpdateInstanceOf:class fromXML:XML];
	return object;
}

- (id)createOrUpdateInstanceOf:(Class)class fromXML:(Element*)XML {
	id object = nil;
	// Find by PK, if it responds to it
	if ([class respondsToSelector:@selector(findByPrimaryKey:)]) {
		// TODO: factor to class method? incase it is not a number
		NSNumber* pk = [XML contentsNumberOfChildElement:[class primaryKeyElement]];
		//NSLog(@"Attempting to find object by primary key %@ via primaryKeyElement %@", pk, [class primaryKeyElement]);
		object = [class findByPrimaryKey:pk];
	}
	// instantiate if object is nil
	if (object == nil) {
		if ([class respondsToSelector:@selector(newObject)]) {
			object = [class newObject];
		} else {
			object = [[[class alloc] init] autorelease];
		}
	}
	// check to see if we should hand the object the xml to set it's own properties
	// (custom implementation)
	if ([object respondsToSelector:@selector(digestXML:)]) {
		[object digestXML:XML];
	}  else {
		// update attributes
		[self setAttributes:object fromXML:XML];
	}
	return object;
}

- (void)setAttributes:(id)object fromXML:(Element*)XML {
	[self setPropertiesOfModel:object fromXML:XML];
	[self setRelationshipsOfModel:object fromXML:XML];
}

- (id)propertyValueForElement:(Element*)propertyElement type:(NSString*)type {
	id propertyValue = nil;
	SEL valueSelector = nil;
	if ([type isEqualToString:@"NSString"]) {		
		propertyValue = [propertyElement contentsText];
	} else if ([type isEqualToString:@"NSNumber"]) {
		NSString* string = [propertyElement contentsText];
		if (nil != string) {
			NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
			[formatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
			[formatter setNumberStyle:NSNumberFormatterDecimalStyle];		
			propertyValue = [formatter numberFromString:string];
			[formatter release];
		}
	} else if ([type isEqualToString:@"NSDecimalNumber"]) {
		propertyValue = [NSDecimalNumber decimalNumberWithString:[propertyElement contentsText]];
	} else if ([type isEqualToString:@"NSDate"]) {
		NSString* dateString = [propertyElement contentsText];
		if (nil != dateString) {
			NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
			// Times coming back are in utc. we should convert them to the local timezone
			// TODO: Need a way to handle date/time formats. Maybe part of the mapper?
			[formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
			[formatter setDateFormat:kRailsToXMLDateTimeFormatterString];
			propertyValue = [formatter dateFromString:dateString];
			if (nil == propertyValue) {
				[formatter setDateFormat:kRailsToXMLDateFormatterString];
				propertyValue = [formatter dateFromString:dateString];
			}
			[formatter release];
		}
	} else if ([type isEqualToString:@"nil"]) {
		[NSException raise:@"PropertyTypeError" format:@"Don't know how to handle property type '%@'", type];
	}
	return propertyValue;
}

- (id)propertyValueForElements:(NSArray*)elements type:(NSString*)type {
	NSMutableArray* values = [NSMutableArray arrayWithCapacity:[elements count]];
	for (Element* element in elements) {
		[values addObject:[self propertyValueForElement:element type:type]];
	}
	
	return values;
}

- (void)setPropertiesOfModel:(id)model fromXML:(Element*)XML {
	for (id mapping in [[model class] elementToPropertyMappings]) {
		NSString* selector = [self selectorFromMapping:mapping forMappingFormat:RKMappingFormatXML];
		NSString* propertyName = [[[model class] elementToPropertyMappings] objectForKey:mapping];
		NSString* typeHint;
		
		Element* propertyElement = nil;
		if ([self isSelectorGrouped:selector]) {
			selector = [selector stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"[]"]];
			propertyElement = [XML selectElements:selector];
			typeHint = [[(NSArray*)propertyElement objectAtIndex:0] attribute:@"type"];
		} else {
			propertyElement = [XML selectElement:selector];
			typeHint = [propertyElement attribute:@"type"];
		}
		
		NSString* propertyType = [self typeNameForProperty:propertyName ofClass:[model class] typeHint:typeHint];
		id propertyValue = nil;
		if ([propertyElement isKindOfClass:[NSArray class]]) {
			propertyValue = [self propertyValueForElements:propertyElement type:propertyType];
		} else {
			propertyValue = [self propertyValueForElement:propertyElement type:propertyType];
		}
		
		// TODO: typeHint shit needs better factoring...
		if (typeHint) {
			//NSLog(@"TypeHint is %@", typeHint);
			if ([typeHint isEqualToString:@"boolean"]) {
				// Booleans must be cast to NSNumber...
				propertyValue = [NSNumber numberWithBool:[propertyValue boolValue]];
			}
		}
		//NSLog(@"Trying potential update to %@ with value %@", propertyName, propertyValue);
		[self updateObject:model ifNewPropertyPropertyValue:propertyValue forPropertyNamed:propertyName];
	}
}

- (void)setRelationshipsOfModel:(id)model fromXML:(Element*)XML {
	for (NSString* selector in [[[model class] elementToRelationshipMappings] allKeys]) {
		NSString* propertyName = [[[model class] elementToRelationshipMappings] objectForKey:selector];
		if ([self isParentSelector:selector]) {
			NSMutableSet* children = [NSMutableSet set];
			// If the parent element doesn't appear, we will not set the collection to nil.
			NSString* containingElementName = [self containingElementNameForSelector:selector];
			if ([XML selectElement:containingElementName] != nil) {
				NSArray* childrenElements = [XML selectElements:selector];
				for (Element* childElement in childrenElements) {
					[children addObject:[self buildModelFromXML:childElement]];
				}
				[model setValue:(NSSet*)children forKey:propertyName];
			}
		} else {
			Element* childElement = [XML selectElement:selector];
			id child = [self buildModelFromXML:childElement];
			[model setValue:child forKey:propertyName];
		}
	}
}

#pragma mark -
#pragma mark selector methods

- (BOOL)isSelectorGrouped:(NSString*)key {
	return ([key hasPrefix:@"["] && [key hasSuffix:@"]"]);
}

- (BOOL)isParentSelector:(NSString*)key {
	return !NSEqualRanges([key rangeOfString:@" > "], NSMakeRange(NSNotFound, 0));
}

- (NSString*)containingElementNameForSelector:(NSString*)selector {
	return [[selector componentsSeparatedByString:@" > "] objectAtIndex:0];
}

- (NSString*)childElementNameForSelector:(NSString*)selector {
	return [[selector componentsSeparatedByString:@" > "] objectAtIndex:1];
}

#pragma mark -
#pragma mark Property Type Methods

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

- (NSString*)typeNameForProperty:(NSString*)property ofClass:(Class)class typeHint:(NSString*)typeHint {
	if ([typeHint isEqualToString:@"boolean"]) {
		return @"NSString";
	} else {
		return [[self propertyNamesAndTypesForClass:class] objectForKey:property];
	}	
}

@end
