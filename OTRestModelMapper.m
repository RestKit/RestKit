//
//  OTModelMapper.m
//  OTRestFramework
//
//  Created by Blake Watters on 8/14/09.
//  Copyright 2009 Objective 3. All rights reserved.
//

#import "OTRestModelMapper.h"

@interface OTRestModelMapper (Private)

- (id)createOrUpdateInstanceOf:(Class)class fromXML:(Element*)XML;
- (void)setAttributes:(id)object fromXML:(Element*)XML;
- (void)setPropertiesOfModel:(id)model fromXML:(Element*)XML;
- (void)setRelationshipsOfModel:(id)model fromXML:(Element*)XML;

@end


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

- (void)registerModel:(Class<OTRestModelMappable>)class forElementNamed:(NSString*)elementName {
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
	id object = [self createOrUpdateInstanceOf:class fromXML:XML];
	return object;
}

- (id)createOrUpdateInstanceOf:(Class)class fromXML:(Element*)XML {
	id object = nil;
	// Find by PK, if it responds to it
	if ([class respondsToSelector:@selector(findByPrimaryKey:)]) {
		NSString* pk = [XML contentsTextOfChildElement:[class primaryKey]];
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
	// update attributes
	[self setAttributes:object fromXML:XML];
	return object;
}

- (void)setAttributes:(id)object fromXML:(Element*)XML {
	[self setPropertiesOfModel:object fromXML:XML];
	[self setRelationshipsOfModel:object fromXML:XML];
}

- (id)propertyValueForElement:(Element*)propertyElement{
	NSString* typeHint = [propertyElement attribute:@"type"];
	id propertyValue = nil;
	if ([typeHint isEqualToString:@"string"] ||
		typeHint == nil) {		
		propertyValue = [propertyElement contentsText];
	} else if ([typeHint isEqualToString:@"integer"] ||
			   [typeHint isEqualToString:@"float"]) {
		propertyValue = [propertyElement contentsNumber];
	} else if ([typeHint isEqualToString:@"boolean"]) {
		propertyValue = [NSNumber numberWithBool:[[propertyElement contentsText] isEqualToString:@"true"]];
	} else if ([typeHint isEqualToString:@"datetime"]) {
		NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
		// Times coming back are in utc. we should convert them to the local timezone
		// TODO: Make sure this is working correctly
		[formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
		[formatter setDateFormat:kRailsToXMLDateFormatterString];
		propertyValue = [formatter dateFromString:[propertyElement contentsText]];
		[formatter release];
	} else if ([typeHint isEqualToString:@"nil"]) {
		propertyValue = nil;
	} else {
		[NSException raise:@"PropertyTypeError" format:@"Don't know how to handle property type '%@'", typeHint];
	}
	return propertyValue;
}

- (void)setPropertiesOfModel:(id)model fromXML:(Element*)XML {
	for (NSString* selector in [[[model class] elementToPropertyMappings] allKeys]) {
		NSString* propertyName = [[[model class] elementToPropertyMappings] objectForKey:selector];
		Element* propertyElement = [XML selectElement:selector];
		id propertyValue = [self propertyValueForElement:propertyElement];
		[model setValue:propertyValue forKey:propertyName];
	}
}

- (BOOL)isParentSelector:(NSString*)key {
	return !NSEqualRanges([key rangeOfString:@" > "], NSMakeRange(NSNotFound, 0));
}

- (NSString*)containingElementNameForSelector:(NSString*)selector {
	return [[selector componentsSeparatedByString:@" > "] objectAtIndex:0];
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

@end
