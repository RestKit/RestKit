//
//  RKSearchTokenizer.h
//  RestKit
//
//  Created by Blake Watters on 7/30/12.
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
 The `RKSearchTokenizer` class provides an interface for tokenizing input text into a set of searchable words. Diacritics are removed and the input text is tokenized case insensitively. A set of stop words can be optionally trimmed from the result token set.
 */
@interface RKSearchTokenizer : NSObject

///-------------------------------
/// @name Configuring Tokenization
///-------------------------------

/**
 The set of stop words that are to be removed from the token set.

 Defaults to nil.
 */
@property (nonatomic, strong) NSSet *stopWords;

///----------------------------------
/// @name Tokenizing a String of Text
///----------------------------------

/**
 Tokenizes the given string by folding it case and diacritic insensitively and then splitting it apart using the the word unit delimiters for the current locale. If a set of stop words has been provided, the resulting token set will have the stop words subtracted.

 @param string A string of text you wish to tokenize.
 @returns A set of searchable text tokens extracted from the given string.
 */
- (NSSet *)tokenize:(NSString *)string;

@end
