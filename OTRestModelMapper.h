//
//  OTModelMapper.h
//  OTRestFramework
//
//  Created by Blake Watters on 8/14/09.
//  Copyright 2009 Objective 3. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ElementParser.h"
#import "OTRestModelMappableProtocol.h"

#define kRailsToXMLDateFormatterString @"yyyy-MM-dd'T'HH:mm:ss'Z'" // 2009-08-08T17:23:59Z

typedef enum {
	OTRestMappingFormatXML = 0,
	OTRestMappingFormatJSON
} OTRestMappingFormat;

@interface OTRestModelMapper : NSObject {
	NSMutableDictionary* _elementToClassMappings;
	OTRestMappingFormat _format;
}

@property(nonatomic, assign) OTRestMappingFormat format;

/**
 * Register a mapping for a given class for an XML element with the given tag name
 * will blow up if the class does not respond to elementToPropertyMappings and elementToRelationshipMappings
 */
- (void)registerModel:(Class)aClass forElementNamed:(NSString*)elementName;

/**
 * Digest an XML/JSON payload and return the an instance of the model class registered for the element
 */
- (id)buildModelFromString:(NSString*)payload;

/**
 * Digest an XML/JSON payload and return the resulting collection of model instances
 */
- (NSArray*)buildModelsFromString:(NSString*)payload;

/**
 * Digests an XML payload and updates the object with its properties and relationships
 */
- (void)setAttributes:(id)object fromXML:(Element*)XML;

/**
 * Digests a JSON payload and updates the object with its properties and relationships
 */
- (void)setAttributes:(id)object fromJSONDict:(NSDictionary*)dict;

@end
