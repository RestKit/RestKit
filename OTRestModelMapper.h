//
//  OTRestModelMapper.h
//  gateguru
//
//  Created by Blake Watters on 8/6/09.
//  Copyright 2009 Objective 3. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Element.h"

@interface OTRestModelMapper : NSObject {
	NSMutableDictionary* _elementToClassMappings;
}

/**
 * Register a mapping for a given class for an XML element with the given tag name
 */
- (void)registerModel:(Class)class forElementNamed:(NSString*)elementName;

/**
 * Digest an XML payload and return the an instance of the model class registered for the element
 */
- (id)buildModelFromXML:(Element*)XML;

@end
