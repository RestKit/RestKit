//
//  OTModelMapper.m
//  OTRestFramework
//
//  Created by Blake Watters on 8/14/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

// #import <objc/objc-runtime.h>
#import <objc/message.h>
#import "OTRestModelMapper.h"
#import "OTRestModelMapper_Private.h"
#import "ElementParser.h"
#import "JSON.h"

// Used for detecting property types at runtime
#import <objc/runtime.h>

@implementation OTRestModelMapper

@synthesize format = _format;

- (id)init {
	if (self = [super init]) {
		_elementToClassMappings = [[NSMutableDictionary alloc] init];
		_format = OTRestMappingFormatXML;
	}
	return self;
}

- (void)dealloc {
	[_elementToClassMappings release];
	[super dealloc];
}

- (BOOL)mappingFromJSON {
	return _format == OTRestMappingFormatJSON;
}

- (BOOL)mappingFromXML {
	return _format == OTRestMappingFormatXML;
}

- (void)registerModel:(Class)aClass forElementNamed:(NSString*)elementName {
	[_elementToClassMappings setObject:aClass forKey:elementName];
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
			id object = [self buildModelFromJSONDict:dict];
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
		[model setNilValueForKey:propertyName];
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
		} else {
			[NSException raise:@"NoComparisonSelectorFound" format:@"You need a comparison selector for %@ (%@)", propertyName, [propertyValue class]];
		}
		
		// Comparison magic using function pointers. See this page for details: http://www.red-sweater.com/blog/320/abusing-objective-c-with-class
		// Original code courtesy of Greg Parker
		// This is necessary because isEqualToNumber will return negative integer values that aren't coercable directly to BOOL's without help [sbw]
		BOOL (*ComparisonSender)(id, SEL, id) = (BOOL (*)(id, SEL, id)) objc_msgSend;		
		BOOL areEqual = ComparisonSender(currentValue, comparisonSelector, propertyValue);
				
		if (NO == areEqual) {
			NSLog(@"Setting property %@ to new value %@", propertyName, propertyValue);
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
		return nil;
	}
	return [self buildModelFromJSONDict:jsonDict];
}

- (id)buildModelFromJSONDict:(NSDictionary*)dict {
	assert([[dict allKeys] count] == 1);
	NSString* keyName = [[dict allKeys] objectAtIndex:0];
	Class class = [_elementToClassMappings objectForKey:keyName];
	
	return [self createOrUpdateInstanceOf:class fromJSONDict:[dict objectForKey:keyName]];
}

- (id)createOrUpdateInstanceOf:(Class)class fromJSONDict:(NSDictionary*)dict {
	id object = nil;
	if ([class respondsToSelector:@selector(findByPrimaryKey:)]) {
		// TODO: factor to class method? incase it is not a number
		NSNumber* pk = [dict objectForKey:[class primaryKey]];
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
	if ([object respondsToSelector:@selector(digestJSONDict:)]) {
		[object digestJSONDict:dict];
	}  else {
		// update attributes
		[self setAttributes:object fromJSONDict:dict];
	}
	return object;
}

- (void)setAttributes:(id)object fromJSONDict:(NSDictionary*)dict {
	[self setPropertiesOfModel:object fromJSONDict:dict];
	[self setRelationshipsOfModel:object fromJSONDict:dict];
}

- (void)setPropertiesOfModel:(id)model fromJSONDict:(NSDictionary*)dict {
	for (NSString* selector in [[model class] elementToPropertyMappings]) {
		NSString* propertyName = [[[model class] elementToPropertyMappings] objectForKey:selector];
		
		NSString* propertyType = [self typeNameForProperty:propertyName ofClass:[model class] typeHint:nil];
		id propertyValue = [dict objectForKey:selector];
		
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

- (void)setRelationshipsOfModel:(id)model fromJSONDict:(NSDictionary*)dict {
	for (NSString* selector in [[model class] elementToRelationshipMappings]) {
		NSString* propertyName = [[[model class] elementToRelationshipMappings] objectForKey:selector];
		if ([self isParentSelector:selector]) {
			NSMutableSet* children = [NSMutableSet set];
			// If the collection key doesn't appear, we will not set the collection to nil.
			NSString* collectionKey = [self containingElementNameForSelector:selector];
			// Used to figure out what class to map to, since we don't have element names for the dictionaries in the array
			NSString* objectKey = [self childElementNameForSelelctor:selector];
			NSArray* objects = [dict objectForKey:collectionKey];
			if (objects != nil) {
				for (NSDictionary* childDict in objects) {
					Class class = [_elementToClassMappings objectForKey:objectKey];
					[children addObject:[self createOrUpdateInstanceOf:class fromJSONDict:childDict]];
				}
				[model setValue:(NSSet*)children forKey:propertyName];
			}
		} else {
			NSDictionary* objectDict = [dict objectForKey:selector];
			Class class = [_elementToClassMappings objectForKey:selector];
			id child = [self createOrUpdateInstanceOf:class fromJSONDict:objectDict];
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
		NSLog(@"Attempting to find object by primary key %@ via primaryKeyElement %@", pk, [class primaryKeyElement]);
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

- (id)propertyValueForElement:(Element*)propertyElement type:(NSString*)type{
	//NSString* typeHint = [propertyElement attribute:@"type"];
	id propertyValue = nil;
	if ([type isEqualToString:@"NSString"]) {		
		propertyValue = [propertyElement contentsText];
	} else if ([type isEqualToString:@"NSNumber"]) {
		propertyValue = [propertyElement contentsNumber];
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

- (void)setPropertiesOfModel:(id)model fromXML:(Element*)XML {
	for (NSString* selector in [[model class] elementToPropertyMappings]) {
		NSString* propertyName = [[[model class] elementToPropertyMappings] objectForKey:selector];
		Element* propertyElement = [XML selectElement:selector];
		NSString* typeHint = [propertyElement attribute:@"type"];
		NSString* propertyType = [self typeNameForProperty:propertyName ofClass:[model class] typeHint:typeHint];
		NSLog(@"The propertyType is %@", propertyType);
		id propertyValue = [self propertyValueForElement:propertyElement type:propertyType]; // valueForElement instead???
		if (typeHint) {
			NSLog(@"TypeHint is %@", typeHint);
			if ([typeHint isEqualToString:@"boolean"]) {
				// Booleans must be cast to NSNumber...
				NSLog(@"Boolean value before cast: %@", propertyValue);
				propertyValue = [NSNumber numberWithBool:[propertyValue boolValue]];
				NSLog(@"Boolean value after cast: %@", propertyValue);
			}
		}
		NSLog(@"Trying potential update to %@ with value %@", propertyName, propertyValue);
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

- (BOOL)isParentSelector:(NSString*)key {
	return !NSEqualRanges([key rangeOfString:@" > "], NSMakeRange(NSNotFound, 0));
}

- (NSString*)containingElementNameForSelector:(NSString*)selector {
	return [[selector componentsSeparatedByString:@" > "] objectAtIndex:0];
}

- (NSString*)childElementNameForSelelctor:(NSString*)selector {
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
