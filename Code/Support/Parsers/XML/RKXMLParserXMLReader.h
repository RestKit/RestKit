//
//  RKXMLParserXMLReader.h
//  RestKit
//
//  Created by Christopher Swasey on 1/24/12.
//  Copyright (c) 2012 GateGuru. All rights reserved.
//

/**
 Provides a basic XML implementation using an adapted version
 of the XMLReader class by "Insert-Witty-Name" available at:
 https://github.com/RestKit/XML-to-NSDictionary

 RKXMLParserXMLReader will parse an XML document into an NSDictionary
 representation suitable for use with RestKit's key-value coding based
 object mapping implementation.

 XML attributes are represented as keys in a dictionary.

 **NOTE** When an XML tag is parsed containing both XML attributes and
 an enclosed text node, the value of the text node will be inserted in
 the parsed dictionary at the `@"text"` key.
 */

#import "XMLReader.h"
#import "RKParser.h"

@interface RKXMLParserXMLReader : NSObject <RKParser> {

}

@end
