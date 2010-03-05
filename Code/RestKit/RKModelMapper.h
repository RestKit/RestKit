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

// TODO: The below goes away
#import "ElementParser.h"

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
 * Register a mapping for a given class for an XML element with the given tag name
 * will blow up if the class does not respond to elementToPropertyMappings and elementToRelationshipMappings
 */
- (void)registerModel:(Class)aClass forElementNamed:(NSString*)elementName;

/**
 * Digest an XML/JSON payload and return the an instance of the model class registered for the element
 */
// TODO: Becomes mapModelFromString
- (id)buildModelFromString:(NSString*)string;

/**
 * Digest an XML/JSON payload and return the resulting collection of model instances
 */
// TODO: Becomes mapModelsFromString
- (NSArray*)buildModelsFromString:(NSString*)string;

/**
 * Sets the properties on a particular object from a payload
 */
// TODO: To support remote creation of model objects
- (void)mapModel:(id)model fromString:(NSString*)string;

//////////////////////////////////////////////
// TODO: The methods below go away!!!!

/**
 * Digests an XML payload and updates the object with its properties and relationships
 */
- (void)setAttributes:(id)object fromXML:(Element*)XML;

/**
 * Digests a JSON payload and updates the object with its properties and relationships
 */
- (void)setAttributes:(id)object fromJSONDictionary:(NSDictionary*)dict;

@end
