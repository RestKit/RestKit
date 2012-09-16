//
//  RKSearchPredicate.h
//  RestKit
//
//  Created by Blake Watters on 7/27/12.
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
 `RKSearchPredicate` is a suclass of `NSCompoundPredicate` used to represent textual search operations against entities indexed by an instance of `RKSearchIndexer`.

 @see `RKSearchIndexer`
 */
@interface RKSearchPredicate : NSCompoundPredicate

///----------------------------------
/// @name Creating a Search Predicate
///----------------------------------

/**
 Creates and returns a new predicate for performing a full text search on an entity indexed by an instance of `RKSearchIndexer`. The given search text will be tokenized, normalized and used to construct a collection of subpredicates specifying a `BEGINSWITH` match against the searchWords relationship of the searchable entity.

 @param searchText A string of text with which to construct subpredicates for searching.
 @param type The type of the new compound predicate.
 @return A new compound predicate for performing a full text search with the given search text and type.
 */
+ (NSPredicate *)searchPredicateWithText:(NSString *)searchText type:(NSCompoundPredicateType)type;

/**
 Initializes the receiver with a string of search text and a compound predicate type.

 The search text will be tokenized, normalized and then used to construct an array of subpredicates specifying a `BEGINSWITH` match against the `searchWords` relationship of the searchable entity.

 @param searchText A string of text with which to construct subpredicates for searching.
 @param type The type of the new compound predicate.
 @return The receiver with its type set to the given type and its subpredicates set to an array of subpredicates for searching for the given text.
 */
- (id)initWithSearchText:(NSString *)searchText type:(NSCompoundPredicateType)type;

@end
