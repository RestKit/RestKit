//
//  RKXMLParser.h
//
//  Created by Jeremy Ellison on 2011-02-28.
//  Copyright 2011 RestKit
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//  http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Foundation/Foundation.h>
#import "../../RKParser.h"

/**
 This is a dead simple XML parser that uses libxml2 to parse an XML document
 into a dictionary. It is designed specifically for use with RestKit. It
 does not support any fanciness like Namespaces, DTDs, or other nonsense.
 It does not save attributes on tags, it only cares about nested content and text.
 */
@interface RKXMLParserLibXML : NSObject <RKParser> {
}

- (NSDictionary*)parseXML:(NSString*)XML;

@end
