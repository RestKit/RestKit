//
//  NSObject+YAJL.h
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

#import "YAJLGen.h"
#import "YAJLParser.h"

/*!
 Generate JSON string from NSArray, NSDictionary or custom object or parse JSON from NSString or custom object.
 
 Parse JSON:
 @code
 NSData *JSONData = [NSData dataWithContentsOfFile:@"example.json"];
 NSArray *arrayFromData = [JSONData yajl_JSON];
 
 NSString *JSONString = @"[\"Test\"]";
 NSArray *arrayFromString = [JSONString yajl_JSON];
 
 // With options and out error
 NSError *error = nil;
 NSArray *arrayFromString = [JSONString yajl_JSONWithOptions:YAJLParserOptionsAllowComments error:&error];
 @endcode
 
 Generate JSON:
 @code
 NSDictionary *dict = [NSDictionary dictionaryWithObject:@"value" forKey:@"key"];
 NSString *JSONString = [dict yajl_JSONString];
 
 // Beautified with custon indent string
 NSArray *array = [NSArray arrayWithObjects:@"value1", @"value2", nil];
 NSString *JSONString = [dict yajl_JSONStringWithOptions:YAJLGenOptionsBeautify indentString:@"    "];
 @endcode
 */
@interface NSObject(YAJL)

#pragma mark Gen

/*!
 Create JSON string from object.
 Supported objects include: NSArray, NSDictionary, NSNumber, NSString, NSNull
 To override JSON value to encode (or support custom objects), implement (id)JSON; See YAJLCoding in YAJLGen.h
 @throws YAJLGenInvalidObjectException If object is invalid
 @result JSON String
 */
- (NSString *)yajl_JSONString;

/*!
 Create JSON string from object.
 Supported objects include: NSArray, NSDictionary, NSNumber, NSString, NSNull
 To override JSON value to encode (or support custom objects), implement (id)JSON; See YAJLCoding in YAJLGen.h
 @throws YAJLGenInvalidObjectException If object is invalid
 @param options
  - YAJLGenOptionsNone: No options
  - YAJLGenOptionsBeautify: Beautifiy JSON output
  - YAJLGenOptionsIgnoreUnknownTypes: Ignore unknown types (will use null value)
  - YAJLGenOptionsIncludeUnsupportedTypes: Handle non-JSON types (including NSDate, NSData, NSURL) 
 
 @param indentString
 @result JSON String
 */
- (NSString *)yajl_JSONStringWithOptions:(YAJLGenOptions)options indentString:(NSString *)indentString;


#pragma mark Parsing

/*!
 Parse JSON (NSString or NSData or dataUsingEncoding:).
 @result JSON object
 @throws YAJLParserException If a parse error occured
 @throws YAJLParsingUnsupportedException If not NSData or doesn't respond to dataUsingEncoding:
 
 @code
 NSString *JSONString = @"{'foo':['bar', true]}";
 id JSONValue = [JSONString yajl_JSON];
 
 NSData *JSONData = ...;
 id JSONValue = [JSONData yajl_JSON];
 @endcode
 */
- (id)yajl_JSON;

/*!
 Parse JSON (NSString or NSData or dataUsingEncoding:) with out error.
 
 If an error occurs, the returned object will be the current state of the object when
 the error occurred.

 @param error Error to set if we failed to parse
 @result JSON object
 @throws YAJLParserException If a parse error occured
 @throws YAJLParsingUnsupportedException If not NSData or doesn't respond to dataUsingEncoding:
 
 @code
 NSString *JSONString = @"{'foo':['bar', true]}";
 NSError *error = nil;
 [JSONString yajl_JSON:error];
 if (error) ...;
 @endcode
 */
- (id)yajl_JSON:(NSError **)error;

/*!
 Parse JSON (NSString or NSData or dataUsingEncoding:) with options and out error.
 
 If an error occurs, the returned object will be the current state of the object when
 the error occurred.
 
 @param options Parse options
  - YAJLParserOptionsNone: No options
  - YAJLParserOptionsAllowComments: Javascript style comments will be allowed in the input (both /&asterisk; &asterisk;/ and //)
  - YAJLParserOptionsCheckUTF8: Invalid UTF8 strings will cause a parse error
  - YAJLParserOptionsStrictPrecision: If YES will force strict precision and return integer overflow error
 
 @param error Error to set if we failed to parse
 @result JSON object
 @throws YAJLParserException If a parse error occured
 @throws YAJLParsingUnsupportedException If not NSData or doesn't respond to dataUsingEncoding:
 
 @code
 NSString *JSONString = @"{'foo':['bar', true]} // comment";
 NSError *error = nil;
 [JSONString yajl_JSONWithOptions:YAJLParserOptionsAllowComments error:error];
 if (error) ...;
 @endcode
 */
- (id)yajl_JSONWithOptions:(YAJLParserOptions)options error:(NSError **)error;

@end

