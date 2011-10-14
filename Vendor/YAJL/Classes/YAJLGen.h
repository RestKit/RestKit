//
//  YAJLGen.h
//  YAJL
//
//  Created by Gabriel Handford on 7/19/09.
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

#include "yajl_gen.h"


extern NSString *const YAJLGenInvalidObjectException; //! Exception type if we encounter invalid object

//! JSON generate options
enum YAJLGenOptions {
  YAJLGenOptionsNone = 0, //!< No options
  YAJLGenOptionsBeautify = 1 << 0, //!< Beautifiy JSON output
  YAJLGenOptionsIgnoreUnknownTypes = 1 << 1, //!< Ignore unknown types (will use null value)
  YAJLGenOptionsIncludeUnsupportedTypes = 1 << 2, //!< Handle non-JSON types (including NSDate, NSData, NSURL)
};
typedef NSUInteger YAJLGenOptions;

/*!
 YAJL JSON string generator.
 Supports the following types:
 - NSArray
 - NSDictionary
 - NSString
 - NSNumber
 - NSNull
 
 We also support the following types (if using YAJLGenOptionsIncludeUnsupportedTypes option),
 by converting to JSON supported types:
 - NSDate: number representing number of milliseconds since (1970) epoch
 - NSData: Base64 encoded string
 - NSURL: URL (absolute) string 
 */
@interface YAJLGen : NSObject {
  yajl_gen gen_;
  
  YAJLGenOptions genOptions_;
}

/*!
 JSON generator with options.
 @param genOptions Generate options
  - YAJLGenOptionsNone: No options
  - YAJLGenOptionsBeautify: Beautifiy JSON output
  - YAJLGenOptionsIgnoreUnknownTypes: Ignore unknown types (will use null value)
  - YAJLGenOptionsIncludeUnsupportedTypes: Handle non-JSON types (including NSDate, NSData, NSURL) 
 
 @param indentString String for indentation
 */
- (id)initWithGenOptions:(YAJLGenOptions)genOptions indentString:(NSString *)indentString;

/*!
 Write JSON for object to buffer.
 @param obj Supported or custom object
 */
- (void)object:(id)obj;

/*!
 Write null value to buffer.
 */
- (void)null;

/*!
 Write bool value to buffer.
 @param b Output true or false
 */
- (void)bool:(BOOL)b;

/*!
 Write numeric value to buffer.
 @param number Numeric value
 */
- (void)number:(NSNumber *)number;

/*!
 Write string value to buffer.
 @param s String value
 */
- (void)string:(NSString *)s;

/*!
 Write dictionary start ('{') to buffer.
 */
- (void)startDictionary;

/*!
 Write dictionary end ('}') to buffer.
 */
- (void)endDictionary;

/*!
 Write array start ('[') to buffer.
 */
- (void)startArray;

/*!
 Write array end (']') to buffer.
 */
- (void)endArray;

/*!
 Clear JSON buffer.
 */
- (void)clear;

/*!
 Get current JSON buffer.
 */
- (NSString *)buffer;

@end


/*!
 Custom objects can support manual JSON encoding.
 
 @code
 @interface CustomObject : NSObject
 @end
 
 @implementation CustomObject
 
 - (id)JSON {
 return [NSArray arrayWithObject:[NSNumber numberWithInteger:1]];
 }
 
 @end
 @endcode
 
 And then:
 
 @code 
 CustomObject *customObject = [[CustomObject alloc] init];
 NSString *JSONString = [customObject yajl_JSON];
 // JSONString == "[1]";
 @endcode
 */
@protocol YAJLCoding <NSObject>

/*!
 Provide custom and/or encodable object to parse to JSON string.
 @result Object encodable as JSON such as NSDictionary, NSArray, etc
 */
- (id)JSON;

@end
