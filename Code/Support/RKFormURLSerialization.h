//
//  RKFormURLSerialization.h
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

#import "RKSerialization.h"

/**
 The `RKFormURLSerialization` class conforms to the `RKSerialization` protocol and provides support for the serialization and deserialization of URL encoded data. URL encoding is used to replace certain characters in a string with equivalent percent escape sequences. The list of characters replaced by the implementation are designed as illegal URL characters by RFC 3986. URL encoded data is used for the submission of HTML forms with the MIME Type `application/x-www-form-urlencoded`.
 
 @see http://www.w3.org/TR/html401/interact/forms.html
 @see http://www.ietf.org/rfc/rfc3986.txt
 */
@interface RKFormURLSerialization : NSObject <RKSerialization>

@end

/**
 */
NSDictionary *RKDictionaryFromURLEncodedStringWithEncoding(NSString *URLEncodedString, NSStringEncoding encoding);

/**
 */
NSString *RKURLEncodedStringFromDictionaryWithEncoding(NSDictionary *dictionary, NSStringEncoding encoding);
