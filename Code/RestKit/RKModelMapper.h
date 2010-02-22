//
// RKModelMapper.h
//  RestKit
//
//  Created by Blake Watters on 8/14/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ElementParser.h"
#import "RKModelMappableProtocol.h"

#define kRailsToXMLDateTimeFormatterString @"yyyy-MM-dd'T'HH:mm:ss'Z'" // 2009-08-08T17:23:59Z
#define kRailsToXMLDateFormatterString @"MM/dd/yyyy"

@interface RKModelMapper : NSObject {
	NSMutableDictionary* _elementToClassMappings;
	RKMappingFormat _format;
}

@property(nonatomic, assign) RKMappingFormat format;

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
- (void)setAttributes:(id)object fromJSONDictionary:(NSDictionary*)dict;

@end
