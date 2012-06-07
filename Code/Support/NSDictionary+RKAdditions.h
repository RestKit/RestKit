//
//  NSDictionary+RKAdditions.h
//  RestKit
//
//  Created by Blake Watters on 9/5/10.
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

#import <Foundation/Foundation.h>

/**
 Provides useful additions to the NSDictionary interface.
 */
@interface NSDictionary (RKAdditions)

/**
 Creates and initializes a dictionary with key value pairs, with the keys specified
 first instead of the objects.
 */
+ (id)dictionaryWithKeysAndObjects:(id)firstKey, ... NS_REQUIRES_NIL_TERMINATION;

/**
 Return a new dictionary by stripping out any percent escapes (such as %20)
 from the receiving dictionary's key and values.

 @return A new dictionary wherein any percent escape sequences in the key and values
 have been replaced with their literal values.
 */
- (NSDictionary *)dictionaryByReplacingPercentEscapesInEntries;

/**
 Returns a dictionary by digesting a URL encoded set of key/value pairs into unencoded
 values. Keys that appear multiple times with the string are decoded into an array of
 values.
 */
+ (NSDictionary *)dictionaryWithURLEncodedString:(NSString *)URLEncodedString;

/**
 Returns a representation of the dictionary as a URLEncoded string

 @returns A UTF-8 encoded string representation of the keys/values in the dictionary
 */
- (NSString *)stringWithURLEncodedEntries;
- (NSString *)URLEncodedString; // TODO: Deprecated..

@end
