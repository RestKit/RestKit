//
//  RKModelMapper.h
//  RestKit
//
//  Created by Blake Watters on 3/4/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKModelMappableProtocol.h"
#import "RKObjectPropertyInspector.h"

/**
 * The format parser is responsible for transforming a string
 * of data into a dictionary. This allows the model mapper to
 * map properties using key-value coding
 */
@protocol RKMappingFormatParser

/**
 * Return a key-value coding compliant representation of a payload.
 * Object attributes are encoded as a dictionary and collections
 * of objects are returned as arrays.
 */
- (id)objectFromString:(NSString*)string;

@end

@interface RKModelMapper : NSObject {
	NSMutableDictionary* _elementToClassMappings;
	RKMappingFormat _format;
	NSObject<RKMappingFormatParser>* _parser;
	RKObjectPropertyInspector* _inspector;
	NSArray* _dateFormats;
	NSTimeZone* _remoteTimeZone;
	NSTimeZone* _localTimeZone;
}

/**
 * The format the mapper is using
 */
@property(nonatomic, assign) RKMappingFormat format;

/**
 * The object responsible for parsing string data into a mappable
 * dictionary
 */
@property(nonatomic, retain) NSObject<RKMappingFormatParser>* parser;

/**
 * An array of date format strings to attempt to parse mapped date properties with
 *
 * Initialized with a default pair of timestamp and date strings suitable for
 * parseing time and date objects returned from Rails applications
 */
@property(nonatomic, retain) NSArray* dateFormats;

@property(nonatomic, retain) NSTimeZone* remoteTimeZone;
@property(nonatomic, retain) NSTimeZone* localTimeZone;

/**
 * Register a mapping for a given class for an XML element with the given tag name
 * will blow up if the class does not respond to elementToPropertyMappings and elementToRelationshipMappings
 */
- (void)registerModel:(Class)aClass forElementNamed:(NSString*)elementName;

///////////////////////////////////////////////////////////////////////////////
// Core Mapping API

/**
 * Digests a string into an object graph and returns mapped model objects from the objects
 * serialized in the string
 */
- (id)mapFromString:(NSString*)string;

/**
 * Sets the properties and relationships serialized in the string into the model instance
 * provided
 */
- (void)mapModel:(id)model fromString:(NSString*)string;

///////////////////////////////////////////////////////////////////////////////
// Object Mapping API

/**
 * Sets the properties and relationships serialized in the dictionary into the model instance
 * provided
 */
- (void)mapModel:(id)model fromDictionary:(NSDictionary*)dictionary;

/**
 * Returns mapped model(s) from the data serialized in the dictionary into the model instance
 * provided
 */
- (id)mapModelFromDictionary:(NSDictionary*)dictionary;

/**
 * Constructs an array of mapped model objects from an array of dictionaries
 * containing serialized objects
 */
- (NSArray*)mapModelsFromArrayOfDictionaries:(NSArray*)array;

@end
