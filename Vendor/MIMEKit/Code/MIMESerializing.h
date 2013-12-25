//
//  MIMESerializing.h
//  MIMEKit
//
//  Created by Blake Watters on 10/1/10.
//  Copyright (c) 2009-2013 Blake Watters. All rights reserved.
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

extern NSString *const MIMEErrorDomain;
extern NSString *const MIMETypeErrorKey;

typedef NS_ENUM(NSUInteger, MIMEErrorCode) {
    MIMEUnsupportedMIMETypeError
};

/**
 The `MIMESerializing` protocol declares two methods that a class must implement so that it can provide support for serializing objects to and deserializing objects from UTF-8 encoded data representations of a serialization format such as JSON or XML. Serialization implementations typically handle data in a given MIME Type (i.e. `application/json`) and may be registered with the `MIMETypeSerialization` class.
 
 @see `MIMETypeSerialization`
 */
@protocol MIMESerializing <NSObject>

///------------------------------
/// @name Deserializing an Object
///------------------------------

/**
 Deserializes and returns the given data in the format supported by the receiver (i.e. JSON, XML, etc) as a Foundation object representation.
 
 @param data The UTF-8 encoded data representation of the object to be deserialized.
 @param error A pointer to an `NSError` object.
 @return A Foundation object from the serialized data in data, or nil if an error occurs.
 */
+ (id)objectFromData:(NSData *)data error:(NSError **)error;

///----------------------------
/// @name Serializing an Object
///----------------------------

/**
 Serializes and returns a UTF-8 encoded data representation of the given Foundation object in the format supported by the receiver (i.e. JSON, XML, etc).
 
 @param object The object to be serialized.
 @param error A pointer to an NSError object.
 @return A data representation of the given object in UTF-8 encoding, or nil if an error occurred.
 */
+ (NSData *)dataFromObject:(id)object error:(NSError **)error;

@end

/**
 MIME Type Constants
 */

/// MIME Type application/json
extern NSString *const MIMETypeJSON;

/// MIME Type application/x-www-form-urlencoded
extern NSString *const MIMETypeFormURLEncoded;

/// MIME Type application/xml
extern NSString *const MIMETypeXML;

/// MIME Type text/xml
extern NSString *const MIMETypeTextXML;

/**
 Returns `YES` if the given MIME Type matches any MIME Type identifiers in the given set.

 @param MIMEType The MIME Type to evaluate the match for.
 @param MIMETypes An `NSSet` object who entries are `NSString` or `NSRegularExpression` objects specifying MIME Types.
 @return `YES` if the given MIME Type matches any identifier in the set, else `NO`.
 */
BOOL MIMETypeInSet(NSString *MIMEType, NSSet *MIMETypes);
