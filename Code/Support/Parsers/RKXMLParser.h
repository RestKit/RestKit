//
//  RKXMLParser.h
//
//  Created by Jeremy Ellison on 2011-02-28.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKParser.h"

/**
 * This is a dead simple XML parser that uses libxml2 to parse an XML document
 * into a dictionary. It is designed specifically for use with RestKit. It
 * does not support any fanciness like Namespaces, DTDs, or other nonsense.
 * It does not save attributes on tags, it only cares about nested content and text.
 */

@interface RKXMLParser : NSObject <RKParser> {
}

+ (NSDictionary*)parse:(NSString*)xml;

@end
