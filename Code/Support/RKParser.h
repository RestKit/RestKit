//
//  RKParser.h
//  RestKit
//
//  Created by Blake Watters on 10/1/10.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
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

@protocol RKParserData, RKParserString;

/**
 The RKParser protocol groups two similar protocols together. A class must
 implement either one to support for parsing and serializing object
 representations to the RestKit framework. Parsers are required to transform
 objects to and from NSString or NSData objects, respectively. They are
 configured via the RKParserRegistry shared instance.
 */
@protocol RKParser <NSObject, RKParserData, RKParserString>

@end

@protocol RKParserData

@optional

/**
 Returns an object representation of the source data encoded in the
 format provided by the parser (i.e. BSON, MessagePack, etc).

 @param data The data representation of the object to be parsed.
 @param error A pointer to an NSError object.
 @return The parsed object or nil if an error occurred during parsing.
 */
- (id)objectFromData:(NSData *)data error:(NSError **)error;

/**
 Returns a data representation encoded in the format
 provided by the parser (i.e. BSON, MessagePack, etc) for the given object.

 @param object The object to be serialized.
 @param A pointer to an NSError object.
 @return A data representation of the serialized object or nil if an error occurred.
 */
- (NSData *)dataFromObject:(id)object error:(NSError **)error;

@end

@protocol RKParserString

@optional

/**
 Returns an object representation of the source string encoded in the
 format provided by the parser (i.e. JSON, XML, etc).

 @param string The string representation of the object to be parsed.
 @param error A pointer to an NSError object.
 @return The parsed object or nil if an error occurred during parsing.
 */
- (id)objectFromString:(NSString *)string error:(NSError **)error;

/**
 Returns a string representation encoded in the format
 provided by the parser (i.e. JSON, XML, etc) for the given object.

 @param object The object to be serialized.
 @param A pointer to an NSError object.
 @return A string representation of the serialized object or nil if an error occurred.
 */
- (NSString *)stringFromObject:(id)object error:(NSError **)error;

@end
