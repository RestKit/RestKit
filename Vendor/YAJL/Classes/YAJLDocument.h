//
//  YAJLDecoder.h
//  YAJL
//
//  Created by Gabriel Handford on 3/1/09.
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


#include "YAJLParser.h"

typedef enum {
  YAJLDecoderCurrentTypeNone,
  YAJLDecoderCurrentTypeArray,
  YAJLDecoderCurrentTypeDict
} YAJLDecoderCurrentType;

extern NSInteger YAJLDocumentStackCapacity;

@class YAJLDocument;

/*!
 YAJLDocument delegate notified when objects are added.
 */
@protocol YAJLDocumentDelegate <NSObject>
@optional
/*!
 Did add dictionary.
 @param document Sender
 @param dict Dictionary that was added
 */
- (void)document:(YAJLDocument *)document didAddDictionary:(NSDictionary *)dict;

/*!
 Did add array.
 @param document Sender
 @param array Array that was added
 */
- (void)document:(YAJLDocument *)document didAddArray:(NSArray *)array;

/*!
 Did add object to array.
 @param document Sender
 @param object Object added
 @param array Array objct was added to
 */
- (void)document:(YAJLDocument *)document didAddObject:(id)object toArray:(NSArray *)array;

/*!
 Did set object for key on dictionary.
 @param document Sender
 @param object Object that was set
 @param key Key
 @param dict Dictionary object was set for key on
 */
- (void)document:(YAJLDocument *)document didSetObject:(id)object forKey:(id)key inDictionary:(NSDictionary *)dict;
@end

/*!
 JSON document interface.
 
 @code
 NSData *data = [NSData dataWithContentsOfFile:@"example.json"];
 NSError *error = nil;
 YAJLDocument *document = [[YAJLDocument alloc] initWithData:data parserOptions:YAJLParserOptionsNone error:&error];
 // Access root element at document.root
 NSLog(@"Root: %@", document.root);
 [document release];
 @endcode
 
 Example for streaming:
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
 */
@interface YAJLDocument : NSObject <YAJLParserDelegate> {
  
  id root_; // NSArray or NSDictionary
  YAJLParser *parser_;
  
  // TODO(gabe): This should be __weak
  id<YAJLDocumentDelegate> delegate_;
  
  __weak NSMutableDictionary *dict_; // weak; if map in progress, points to the current map 
  __weak NSMutableArray *array_; // weak; If array in progress, points the current array
  __weak NSString *key_; // weak; If map in progress, points to current key
  
  NSMutableArray *stack_;
  NSMutableArray *keyStack_;
  
  YAJLDecoderCurrentType currentType_;
  
  YAJLParserStatus parserStatus_;
  
}

@property (readonly, nonatomic) id root; //! The root element of the document, either NSArray or NSDictionary
@property (readonly, nonatomic) YAJLParserStatus parserStatus; //! The current status of parsing
@property (assign, nonatomic) id<YAJLDocumentDelegate> delegate; //! Delegate

/*!
 Create document from data.
 @param data Data to parse
 @param parserOptions Parse options
  - YAJLParserOptionsNone: No options
  - YAJLParserOptionsAllowComments: Javascript style comments will be allowed in the input (both /&asterisk; &asterisk;/ and //)
  - YAJLParserOptionsCheckUTF8: Invalid UTF8 strings will cause a parse error
  - YAJLParserOptionsStrictPrecision: If YES will force strict precision and return integer overflow error
 @param error Error to set on failure
 */
- (id)initWithData:(NSData *)data parserOptions:(YAJLParserOptions)parserOptions error:(NSError **)error;

/*!
 Create document from data.
 @param data Data to parse
 @param parserOptions Parse options
 - YAJLParserOptionsNone: No options
 - YAJLParserOptionsAllowComments: Javascript style comments will be allowed in the input (both /&asterisk; &asterisk;/ and //)
 - YAJLParserOptionsCheckUTF8: Invalid UTF8 strings will cause a parse error
 - YAJLParserOptionsStrictPrecision: If YES will force strict precision and return integer overflow error
 @param capacity Initial capacity for NSArray and NSDictionary objects (Defaults to 20)
 @param error Error to set on failure
 */
- (id)initWithData:(NSData *)data parserOptions:(YAJLParserOptions)parserOptions capacity:(NSInteger)capacity error:(NSError **)error;

/*!
 Create empty document with parser options.
 @param parserOptions Parse options
  - YAJLParserOptionsNone: No options
  - YAJLParserOptionsAllowComments: Javascript style comments will be allowed in the input (both /&asterisk; &asterisk;/ and //)
  - YAJLParserOptionsCheckUTF8: Invalid UTF8 strings will cause a parse error
  - YAJLParserOptionsStrictPrecision: If YES will force strict precision and return integer overflow error
 */
- (id)initWithParserOptions:(YAJLParserOptions)parserOptions;

/*!
 Create empty document with parser options.
 @param parserOptions Parse options
 - YAJLParserOptionsNone: No options
 - YAJLParserOptionsAllowComments: Javascript style comments will be allowed in the input (both /&asterisk; &asterisk;/ and //)
 - YAJLParserOptionsCheckUTF8: Invalid UTF8 strings will cause a parse error
 - YAJLParserOptionsStrictPrecision: If YES will force strict precision and return integer overflow error
 @param capacity Initial capacity for NSArray and NSDictionary objects (Defaults to 20)
 */
- (id)initWithParserOptions:(YAJLParserOptions)parserOptions capacity:(NSInteger)capacity;

/*!
 Parse data.
 @param data Data to parse
 @param error Out error to set on failure
 @result Parser status
  - YAJLParserStatusNone: No status
  - YAJLParserStatusOK: Parsed OK 
  - YAJLParserStatusInsufficientData: There was insufficient data
  - YAJLParserStatusError: Parser errored
 */
- (YAJLParserStatus)parse:(NSData *)data error:(NSError **)error;

@end
