//
//  RKResourceMapper.h
//  RestKit
//
//  Created by Blake Watters on 3/4/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKResourceMappable.h"
#import "RKObjectPropertyInspector.h"

/**
 * Define the resource mapping formats
 */
typedef enum {
	RKMappingFormatXML = 0,
	RKMappingFormatJSON
} RKMappingFormat;

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

@interface RKResourceMapper : NSObject {
	NSMutableDictionary* _elementToClassMappings;
	RKMappingFormat _format;
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
 * An array of date format strings to attempt to parse mapped date properties with
 *
 * Initialized with a default pair of timestamp and date strings suitable for
 * parseing time and date objects returned from Rails applications
 */
@property(nonatomic, retain) NSArray* dateFormats;

/**
 * The time zone of the remote system. Date strings pulled from the remote source
 * will be considered to be local to this time zone when mapping.
 *
 * Defaults to UTC
 */
@property(nonatomic, retain) NSTimeZone* remoteTimeZone;

/**
 * The target time zone to map dates to.
 *
 * Defaults to the local time zone
 */
@property(nonatomic, retain) NSTimeZone* localTimeZone;

/**
 * Register a mapping for a given class for an XML element with the given tag name
 * will blow up if the class does not respond to elementToPropertyMappings and elementToRelationshipMappings
 */
- (void)registerClass:(Class<RKResourceMappable>)aClass forElementNamed:(NSString*)elementName;

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
- (void)mapObject:(id)model fromString:(NSString*)string;

///////////////////////////////////////////////////////////////////////////////
// Object Mapping API

/**
 * Sets the properties and relationships serialized in the dictionary into the model instance
 * provided
 */
- (void)mapObject:(id)model fromDictionary:(NSDictionary*)dictionary;

/**
 * Returns mapped model(s) from the data serialized in the dictionary into the model instance
 * provided
 */
- (id)mapObjectFromDictionary:(NSDictionary*)dictionary;

/**
 * Constructs an array of mapped model objects from an array of dictionaries
 * containing serialized objects
 */
- (NSArray*)mapObjectsFromArrayOfDictionaries:(NSArray*)array;

///////////////////////////////////////////////////////////////////////////////
// Non-element based object mapping

- (id)parseString:(NSString*)string;
- (NSArray*)mapObjectsFromArrayOfDictionaries:(NSArray*)array toClass:(Class)class;

@end
