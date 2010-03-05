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

// TODO: Factor me out...
#define kRailsToXMLDateTimeFormatterString @"yyyy-MM-dd'T'HH:mm:ss'Z'" // 2009-08-08T17:23:59Z
#define kRailsToXMLDateFormatterString @"MM/dd/yyyy"

@interface RKModelMapper (Private)

- (void)updateModel:(id)model fromElements:(NSDictionary*)elements;

- (Class)typeClassForProperty:(NSString*)property ofClass:(Class)class;
- (NSDictionary*)elementToPropertyMappingsForModel:(id)model;

- (id)findOrCreateInstanceOfModelClass:(Class)class fromElements:(NSDictionary*)elements;
- (id)createOrUpdateInstanceOfModelClass:(Class)class fromElements:(NSDictionary*)elements;

- (void)updateModel:(id)model ifNewPropertyValue:(id)propertyValue forPropertyNamed:(NSString*)propertyName; // Rename!
- (void)setPropertiesOfModel:(id)model fromElements:(NSDictionary*)elements;
- (void)setRelationshipsOfModel:(id)object fromElements:(NSDictionary*)elements;
- (void)updateModel:(id)model fromElements:(NSDictionary*)elements;

@end

// TODO: Defined in external file but was creating symbol errors... figure out
@interface NSMutableDictionary (External)

- (id)keyForObject:(id)object;

@end

@implementation RKModelMapper

@synthesize format = _format;
@synthesize parser = _parser;

///////////////////////////////////////////////////////////////////////////////
// public

- (id)init {
	if (self = [super init]) {
		_elementToClassMappings = [[NSMutableDictionary alloc] init];
		_format = RKMappingFormatXML;
		_inspector = [[RKObjectPropertyInspector alloc] init];
	}
	return self;
}

- (void)dealloc {
	[_elementToClassMappings release];
	[_parser release];
	[_inspector release];
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

///////////////////////////////////////////////////////////////////////////////
// Mapping from a string

- (id)mapFromString:(NSString*)string {
	id object = [_parser objectFromString:string];
	if ([object isKindOfClass:[NSDictionary class]]) {
		return [self mapModelFromDictionary:(NSDictionary*)object];
	} else if ([object isKindOfClass:[NSArray class]]) {
		return [self mapModelsFromArrayOfDictionaries:(NSArray*)object];
	} else {
		// TODO: Throw error here!
		return nil;
	}
}

- (void)mapModel:(id)model fromString:(NSString*)string {
	id object = [_parser objectFromString:string];
	if ([object isKindOfClass:[NSDictionary class]]) {
		[self mapModel:model fromDictionary:object];
	} else {
		// TODO: Handle error here!
	}
}

///////////////////////////////////////////////////////////////////////////////
// Mapping from objects

- (void)mapModel:(id)model fromDictionary:(NSDictionary*)dictionary {
	Class class = [model class];
	NSString* elementName = [_elementToClassMappings keyForObject:class];
	if (elementName) {
		NSDictionary* elements = [dictionary objectForKey:elementName];	
		[self updateModel:model fromElements:elements];
	} else {
		// TODO: Do we ignore or throw an exception?
	}
}

- (id)mapModelFromDictionary:(NSDictionary*)dictionary {
	NSString* elementName = [[dictionary allKeys] objectAtIndex:0];
	Class class = [_elementToClassMappings objectForKey:elementName];
	NSDictionary* elements = [dictionary objectForKey:elementName];
	
	id model = [self findOrCreateInstanceOfModelClass:class fromElements:elements];
	[self updateModel:model fromElements:elements];
	return model;
}

- (NSArray*)mapModelsFromArrayOfDictionaries:(NSArray*)array {
	NSMutableArray* objects = [NSMutableArray array];
	for (NSDictionary* dictionary in array) {
		NSString* elementName = [[dictionary allKeys] objectAtIndex:0];
		Class class = [_elementToClassMappings objectForKey:elementName];
		NSDictionary* elements = [dictionary objectForKey:elementName];
		id object = [self createOrUpdateInstanceOfModelClass:class fromElements:elements];
		[objects addObject:object];
	}
	
	return (NSArray*)objects;
}

///////////////////////////////////////////////////////////////////////////////
// Utility Methods

- (Class)typeClassForProperty:(NSString*)property ofClass:(Class)class {
	return [[_inspector propertyNamesAndTypesForClass:class] objectForKey:property];
}

- (NSDictionary*)elementToPropertyMappingsForModel:(id)model {
	return [[model class] elementToPropertyMappings];
}

///////////////////////////////////////////////////////////////////////////////
// Persistent Instance Finders

- (id)findOrCreateInstanceOfModelClass:(Class)class fromElements:(NSDictionary*)elements {
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

- (id)createOrUpdateInstanceOfModelClass:(Class)class fromElements:(NSDictionary*)elements {
	id model = [self findOrCreateInstanceOfModelClass:class fromElements:elements];
	[self updateModel:model fromElements:elements];
	return model;
}

///////////////////////////////////////////////////////////////////////////////
// Property & Relationship Manipulation

// TODO: Clean up the method below...
// Better name?
- (void)updateModel:(id)model ifNewPropertyValue:(id)propertyValue forPropertyNamed:(NSString*)propertyName {
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

- (void)setPropertiesOfModel:(id)model fromElements:(NSDictionary*)elements {
	NSDictionary* elementToPropertyMappings = [self elementToPropertyMappingsForModel:model];
	for (NSString* elementKeyPath in elementToPropertyMappings) {
		NSString* propertyName = [elementToPropertyMappings objectForKey:elementKeyPath];
		Class class = [self typeClassForProperty:propertyName ofClass:[model class]];
		id elementValue = nil;		
		
		@try {
			elementValue = [elements valueForKeyPath:elementKeyPath];
		}
		@catch (NSException * e) {
			// TODO: Need error handling!
			NSLog(@"Encountered exception %@ when asking %@ for valueForKeyPath %@", e, elements, elementKeyPath);
		}
		
		id propertyValue = elementValue;
		if (elementValue != (id)kCFNull) {
			if ([class isEqual:[NSDate class]]) {
				// TODO: This date parsing needs to be factored out...
				NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
				// Times coming back are in utc. we should convert them to the local timezone
				// TODO: Note that this currently only handles times and not stand-alone date's! needs to be cleaned up!
				[formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
				[formatter setDateFormat:kRailsToXMLDateTimeFormatterString];
				propertyValue = [formatter dateFromString:propertyValue];
				if (nil == propertyValue) {
					[formatter setDateFormat:kRailsToXMLDateFormatterString];
					propertyValue = [formatter dateFromString:propertyValue];
				}
				[formatter release];
			}
		}
		
		[self updateModel:model ifNewPropertyValue:propertyValue forPropertyNamed:propertyName];
	}
}

- (void)setRelationshipsOfModel:(id)object fromElements:(NSDictionary*)elements {
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
				id child = [self createOrUpdateInstanceOfModelClass:class fromElements:childElements];		
				[children addObject:child];
			}
			
			[object setValue:children forKey:propertyName];
		} else {
			Class class = [_elementToClassMappings objectForKey:elementKeyPath];
			id child = [self createOrUpdateInstanceOfModelClass:class fromElements:relationshipElements];		
			[object setValue:child forKey:propertyName];
		}
	}
}

- (void)updateModel:(id)model fromElements:(NSDictionary*)elements {
	[self setPropertiesOfModel:model fromElements:elements];
	[self setRelationshipsOfModel:model fromElements:elements];
}

@end
