//
//  RKURLEncodedSerialization.h
//  RestKit
//
//  Created by Blake Watters on 9/4/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
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

#import <RestKit/Support/RKSerialization.h>

/**
 The `RKURLEncodedSerialization` class conforms to the `RKSerialization` protocol and provides support for the serialization and deserialization of URL encoded data. URL encoding is used to replace certain characters in a string with equivalent percent escape sequences. The list of characters replaced by the implementation are designed as illegal URL characters by RFC 3986. URL encoded data is used for the submission of HTML forms with the MIME Type `application/x-www-form-urlencoded`.
 
 @see http://www.w3.org/TR/html401/interact/forms.html
 @see http://www.ietf.org/rfc/rfc3986.txt
 */
@interface RKURLEncodedSerialization : NSObject <RKSerialization>

@end

/**
 Creates and returns a new `NSDictionary` object from the given URL-encoded string, using the specified encoding.
 
 The dictionary is constructed by splitting the string into components using the `&` character as the delimiter. The results array of strings is then split again using the `=` character as the delimiter. Each resulting key and value delimited by the `=` character is then URL decoded and added a resulting dictionary. The process is across the entire string. Any extraneous `=` characters not delimiting a key and value are ignored. The corresponding values for any keys that appear multiple times within the string be coalesced into an `NSArray` of values.
 
 @param URLEncodedString A URL-encoded string that is to be parsed into an `NSDictionary`.
 @param encoding The encoding to use when URL-decoding the components of the given string. If you are uncertain of the correct encoding, you should use UTF-8 (NSUTF8StringEncoding), which is the encoding designated by RFC 3986 as the correct encoding for use in URLs.
 @return An `NSDictionary` object containing the keys and values deserialized from the URL-encoded string.
 */
NSDictionary *RKDictionaryFromURLEncodedStringWithEncoding(NSString *URLEncodedString, NSStringEncoding encoding);

/**
 Returns a URL-encoded `NSString` object containing the entries in the given `NSDictionary` object.
 
 The dictionary is created by collecting each key-value pair, URL-encoding a string representation of the key-value pair, and then joining the components with "&". 
 
 @param dictionary The dictionary from to construct the URL-encoded string.
 @param encoding The encoding to use in constructing the URL-encoded string. If you are uncertain of the correct encoding, you should use UTF-8 (NSUTF8StringEncoding), which is the encoding designated by RFC 3986 as the correct encoding for use in URLs.
 @return A new `NSString` object in the given encoding containing a URL-encoded serialization of the entries in the given dictionary.
 @see `AFQueryStringFromParametersWithEncoding`
 */
NSString *RKURLEncodedStringFromDictionaryWithEncoding(NSDictionary *dictionary, NSStringEncoding encoding);

/**
 Returns a copy of the given string with the characters that are unsafe for use in a URL query string replaced with the equivalent percent escape sequences.

 @param string The string to be escaped.
 @param encoding The encoding to use in constructing the URL-encoded string. If you are uncertain of the correct encoding, you should use UTF-8 (NSUTF8StringEncoding), which is the encoding designated by RFC 3986 as the correct encoding for use in URLs.
 @return A new `NSString` object in the given encoding with the query string unsafe characters replaced with percent escape sequences.
 */
NSString *RKPercentEscapedQueryStringFromStringWithEncoding(NSString *string, NSStringEncoding encoding);

/**
 Creates and returns a new `NSDictionary` object containing the keys and values in the query string of the given string.
 
 The given string is searched for a `?` character denoting the beginning of the query parameters. If none is found, the entire string is treated as a URL encoded query string. The parameters are extracted from the query string by invoking `RKDictionaryFromURLEncodedStringWithEncoding()` with the query string.
 
 @param string A string containing a query string that is to be tokenized into a dictionary of parameters.
 @param encoding The encoding to use in constructing the URL-encoded string. If you are uncertain of the correct encoding, you should use UTF-8 (NSUTF8StringEncoding), which is the encoding designated by RFC 3986 as the correct encoding for use in URLs.
 @return An `NSDictionary` object containing the keys and values contained in the query string of the given string.
 */
NSDictionary *RKQueryParametersFromStringWithEncoding(NSString *string, NSStringEncoding encoding);
