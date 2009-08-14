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

@interface OTRestModelMapper : NSObject {
	NSMutableDictionary* _elementToClassMappings;
}

/**
 * Register a mapping for a given class for an XML element with the given tag name
 * will blow up if the class does not respond to elementToPropertyMappings and elementToRelationshipMappings
 */
- (void)registerModel:(Class<OTRestModelMappable>)class forElementNamed:(NSString*)elementName;

/**
 * Digest an XML payload and return the an instance of the model class registered for the element
 */
- (id)buildModelFromXML:(Element*)XML;

/**
 *	Digests an XML payload and updates the object with its properties and relationships
 */
- (void)setAttributes:(id)object fromXML:(Element*)XML;

@end