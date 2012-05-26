//
//  RKRequestSerializable.h
//  RestKit
//
//  Created by Blake Watters on 8/3/09.
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

/**
 This protocol is implemented by objects that can be serialized into a
 representation suitable for transmission over a REST request. Suitable
 serializations are x-www-form-urlencoded and multipart/form-data.

 @warning One of the following methods MUST be implemented for your serializable
 implementation to be complete:

 - (NSData *)HTTPBody - If you are allowing serialization of a small in-memory
 data structure, implement HTTPBody as it is much simpler.
 - (NSInputStream *)HTTPBodyStream - This provides support for streaming a large
 payload from disk instead of memory.

 */
@protocol RKRequestSerializable <NSObject>

///-----------------------------------------------------------------------------
/// @name HTTP Headers
///-----------------------------------------------------------------------------

/**
 The value of the Content-Type header for the HTTP Body representation of the
 serialization.

 @return A string value of the Content-Type header for the HTTP body.
 */
- (NSString *)HTTPHeaderValueForContentType;

@optional

///-----------------------------------------------------------------------------
/// @name Body Implementation
///-----------------------------------------------------------------------------

/**
 An NSData representing the HTTP Body serialization of the object implementing
 the protocol.

 @return An NSData object respresenting the HTTP body serialization.
 */
- (NSData *)HTTPBody;

/**
 Returns an input stream for reading the serialization as a stream used to
 provide support for handling large HTTP payloads.

 @return An input stream for reading the serialization as a stream.
 */
- (NSInputStream *)HTTPBodyStream;


///-----------------------------------------------------------------------------
/// @name Optional HTTP Headers
///-----------------------------------------------------------------------------

/**
 Returns the length of the HTTP Content-Length header.

 @return Unsigned integer length of the HTTP Content-Length header.
 */
- (NSUInteger)HTTPHeaderValueForContentLength;

/**
 The value of the Content-Type header for the HTTP Body representation of the
 serialization.

 @bug **DEPRECATED** in v0.10.0: Implement [RKRequestSerializable HTTPHeaderValueForContentType]
 instead.
 @return A string value of the Content-Type header for the HTTP body.
 */
- (NSString *)ContentTypeHTTPHeader DEPRECATED_ATTRIBUTE;

@end
