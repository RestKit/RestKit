//
//  YAJL.h
//  YAJL
//
//  Created by Gabriel Handford on 7/23/09.
//  Copyright 2009. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

#import "YAJLParser.h"
#import "YAJLDocument.h"
#import "YAJLGen.h"
#import "NSObject+YAJL.h"
#import "NSBundle+YAJL.h"

/*! 
 @mainpage YAJL
 
 The YAJL framework is an Objective-C wrapper around the http://lloyd.github.com/yajl/ SAX-style JSON parser.

 @section Links
 
 Source: http://github.com/gabriel/yajl-objc
 
 View docs online: http://gabriel.github.com/yajl-objc/
 
 YAJL C docs: http://lloyd.github.com/yajl/
 
 @section Usage Usage
 
 To use the framework (for Mac OS X or iOS):
 
 @code
 // For Mac OS X
 #import <YAJL/YAJL.h>
 // For iOS
 #import <YAJLiOS/YAJL.h>
 @endcode
 
 @section Examples Examples
 
 @subsection Example1 To parse JSON from NSData
 
 @code
 NSData *JSONData = [NSData dataWithContentsOfFile:@"example.json"];
 NSArray *arrayFromData = [JSONData yajl_JSON];
 @endcode
 
 @subsection Example2 To parse JSON from NSString
 
 @code
 NSString *JSONString = @"[1, 2, 3]";
 NSArray *arrayFromString = [JSONString yajl_JSON];
 @endcode
 
 @subsection Example2_1 To parse JSON from NSString with error and comments
 
 @code
 // With options and out error
 NSString *JSONString = @"[1, 2, 3] // Allow comments";
 NSError *error = nil;
 NSArray *arrayFromString = [JSONString yajl_JSONWithOptions:YAJLParserOptionsAllowComments error:&error];
 @endcode
 
 @subsection Example3 To generate JSON from an object, NSArray, NSDictionary, etc.
 
 @code
 NSDictionary *dict = [NSDictionary dictionaryWithObject:@"value" forKey:@"key"];
 NSString *JSONString = [dict yajl_JSONString];
 // ==> {"key":"value"}
 @endcode
 
 @subsection Example4 To generate JSON from an object, beautified with custom indent
 
 @code
 // Beautified with custon indent string
 NSArray *array = [NSArray arrayWithObjects:@"value1", @"value2", nil];
 NSString *JSONString = [dict yajl_JSONStringWithOptions:YAJLGenOptionsBeautify indentString:@"    "];
 @endcode
 
 @subsection Example5 To use the streaming (or SAX style) parser, use YAJLParser
 
 @code
 NSData *data = [NSData dataWithContentsOfFile:@"example.json"];
 
 YAJLParser *parser = [[YAJLParser alloc] initWithParserOptions:YAJLParserOptionsAllowComments];
 parser.delegate = self;
 [parser parse:data];
 if (parser.parserError)
   NSLog(@"Error:\n%@", parser.parserError);
 
 parser.delegate = nil;
 [parser release];
 
 // Include delegate methods from YAJLParserDelegate 
 - (void)parserDidStartDictionary:(YAJLParser *)parser { }
 - (void)parserDidEndDictionary:(YAJLParser *)parser { }
 
 - (void)parserDidStartArray:(YAJLParser *)parser { }
 - (void)parserDidEndArray:(YAJLParser *)parser { }
 
 - (void)parser:(YAJLParser *)parser didMapKey:(NSString *)key { }
 - (void)parser:(YAJLParser *)parser didAdd:(id)value { }
 @endcode

 @subsection ParserOptions Parser Options

 There are options when parsing that can be specified with YAJLParser#initWithParserOptions:.

 - YAJLParserOptionsAllowComments: Allows comments in JSON
 - YAJLParserOptionsCheckUTF8: Will verify UTF-8
 - YAJLParserOptionsStrictPrecision: Will force strict precision and return integer overflow error, if number is greater than long long.

 @subsection Example6 Parsing as data becomes available

 @code
 YAJLParser *parser = [[[YAJLParser alloc] init] autorelease];
 parser.delegate = self;

 // A chunk of data comes...
 YAJLParserStatus status = [parser parse:chunk1];
 // 'status' should be YAJLParserStatusInsufficientData, if its not finished
 if (parser.parserError)
   NSLog(@"Error:\n%@", parser.parserError);

 // Another chunk of data comes...
 YAJLParserStatus status = [parser parse:chunk2];
 // 'status' should be YAJLParserStatusOK if its finished
 if (parser.parserError)
   NSLog(@"Error:\n%@", parser.parserError);
 @endcode

 @subsection Example7 Document style parsing

 To use the document style, use YAJLDocument. Usage should be very similar to NSXMLDocument.

 @code
 NSData *data = [NSData dataWithContentsOfFile:@"example.json"];
 NSError *error = nil;
 YAJLDocument *document = [[YAJLDocument alloc] initWithData:data parserOptions:YAJLParserOptionsNone error:&error];
 // Access root element at document.root
 NSLog(@"Root: %@", document.root);
 [document release];
 @endcode

 @subsection Example8 Document style parsing as data becomes available

 @code
 YAJLDocument *document = [[YAJLDocument alloc] init];
 document.delegate = self;

 NSError *error = nil;
 [document parse:chunk1 error:error];
 [document parse:chunk2 error:error];

 // You can access root element at document.root
 NSLog(@"Root: %@", document.root);
 [document release];

 // Or via the YAJLDocumentDelegate delegate methods

 - (void)document:(YAJLDocument *)document didAddDictionary:(NSDictionary *)dict { }
 - (void)document:(YAJLDocument *)document didAddArray:(NSArray *)array { }
 - (void)document:(YAJLDocument *)document didAddObject:(id)object toArray:(NSArray *)array { }
 - (void)document:(YAJLDocument *)document didSetObject:(id)object forKey:(id)key inDictionary:(NSDictionary *)dict { }
 @endcode

 @subsection Example9 Load JSON from Bundle

 @code
 id JSONValue = [[NSBundle mainBundle] yajl_JSONFromResource:@"kegs.json"];
 @endcode

 @section CustomizedEncoding Customized Encoding

 To implement JSON encodable value for custom objects or override for existing objects, implement <tt>- (id)JSON;</tt>

 For example:

 @code
 @interface CustomObject : NSObject
 @end

 @implementation CustomObject

 - (id)JSON {
   return [NSArray arrayWithObject:[NSNumber numberWithInteger:1]];
 } 

 @end
 @endcode

 */