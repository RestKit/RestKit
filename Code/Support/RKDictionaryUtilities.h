//
//  RKDictionaryUtilities.h
//  RestKit
//
//  Created by Blake Watters on 9/11/12.
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

#import <Foundation/Foundation.h>

/**
 Reverse merges two dictionary to produce a new dictionary wherein the keys in the second dictionary have taken precedence in instances where keys overlap. The merge is performed recursively such that subdictionaries are reverse merged as well.
 
 @param dict1 The dictionary to be reverse merged.
 @param dict2 A secondary dictionary to perform the reverse merging with.
 @return A new `NSDicionary` object that is the product of the reverse merge.
 */
NSDictionary *RKDictionaryByMergingDictionaryWithDictionary(NSDictionary *dict1, NSDictionary *dict2);

/**
 Return a new dictionary by stripping out any percent escapes (such as %20) from the given dictionary's key and values.
 
 @param dictionary The dictionary from which to remove the percent escape sequences.
 @return A new `NSDictionary` wherein any percent escape sequences in the key and values have been replaced with their literal values.
 */
NSDictionary *RKDictionaryByReplacingPercentEscapesInEntriesFromDictionary(NSDictionary *dictionary);
