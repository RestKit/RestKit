//
//  RKRequestSerializable.h
//  RestKit
//
//  Created by Blake Watters on 8/3/09.
//  Copyright 2009 Two Toasters
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

/*
 * This protocol is implemented by objects that can be serialized into a representation suitable
 * for transmission over a REST request. Suitable serializations are x-www-form-urlencoded and
 * multipart/form-data.
 */
@protocol RKRequestSerializable

/**
 * The value of the Content-Type header for the HTTP Body representation of the serialization
 */
- (NSString*)HTTPHeaderValueForContentType;

@optional

/**
 * NOTE: One of the following methods MUST be implemented for your serializable implementation
 * to be complete. If you are allowing serialization of a small in-memory data structure, implement
 * HTTPBody as it is much simpler. HTTPBodyStream provides support for streaming a large payload
 * from disk instead of memory.
 */

/**
 * An NSData representing the HTTP Body serialization of the object implementing the protocol
 */
- (NSData*)HTTPBody;

/**
 * Returns an input stream for reading the serialization as a stream. Used to provide support for
 * handling large HTTP payloads.
 */
- (NSInputStream*)HTTPBodyStream;

/**
 * Returns the length of the HTTP Content-Length header
 */
- (NSUInteger)HTTPHeaderValueForContentLength;

/**
 * The value of the Content-Type header for the HTTP Body representation of the serialization
 *
 * @deprecated Implement HTTPHeaderValueForContentType instead
 */
- (NSString*)ContentTypeHTTPHeader DEPRECATED_ATTRIBUTE;

/**
 Get the dictionary of the params which are:
     *  The entity-body is single-part.
     *  The entity-body follows the encoding requirements of the
        "application/x-www-form-urlencoded" content-type as defined by
        [W3C.REC-html40-19980424].
     *  The HTTP request entity-header includes the "Content-Type"
     header field set to "application/x-www-form-urlencoded".
 Source: http://tools.ietf.org/html/rfc5849#section-3.4.1.3
 
 This method is used for OAuth 1.0 HMAC signature. It should return a valid dictionary if
 [self HTTPHeaderValueForContentType] returns "application/x-www-form-urlencoded"
 
 If this method does not exist, it assumes no extra params to be signed.
 */
- (NSDictionary *)dictionaryForOAuthHmacSignature;

@end
