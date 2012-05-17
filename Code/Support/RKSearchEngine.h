//
//  RKSearchEngine.h
//  RestKit
//
//  Created by Blake Watters on 8/26/09.
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
 The RKSearchable protocol declares a method for providing a searchable
 textual representation of content contained within the receiver. Searchable
 objects can be searched via instances of RKSearchEngine.
 */
@protocol RKSearchable

@required

/**
 Returns a string representation of searchable text contained within the receiver.

 @return A string of searchable text.
 */
- (NSString *)searchableText;

@end

/**
 The mode (and/or) in which to search for tokenized text via an RKSearchEngine instance.
 */
typedef enum {
    /**
     The search text should be matched inclusively using AND.
     Matches will include all search terms.
     */
    RKSearchModeAnd,

    /**
     The search text should be matched exclusively using OR.
     Matches will include any search terms.
     */
    RKSearchModeOr
} RKSearchMode;

/**
 An instance of RKSearchEngine provides a simple interface for searching
 arbitrary objects for matching text. Searching is performed by constructing
 a compound NSPredicate and evaluating a collection of candidate objects for matches.
 RKSearchEngine is only suitable for searching a relatively small collection of in-memory
 objects that are not backed by Core Data (see RKManagedObjectSearchEngine).

 @see RKManagedObjectSearchEngine
 */
@interface RKSearchEngine : NSObject

///-----------------------------------------------------------------------------
/// @name Configuring Search Parameters
///-----------------------------------------------------------------------------

/**
 The type of matching to perform. Can be either RKSearchModeAnd or RKSearchModeOr.

 **Default**: RKSearchModeOr
 */
@property (nonatomic, assign) RKSearchMode mode;

/**
 A Boolean value that determines if the search query should be split into subterms at whitespace boundaries.

 **Default**: YES
 */
@property (nonatomic, assign) BOOL tokenizeQuery;

/**
 A Boolean value that determines if whitespace is to be stripped off of the search terms before searching.

 This can prevent search misses when the terms have leading/trailing whitespace.

 **Default**: YES
 */
@property (nonatomic, assign) BOOL stripsWhitespace;

/**
 A Boolean value that determines if search terms should be matched case sensitively.

 **Default**: NO
 */
@property (nonatomic, assign, getter = isCaseSensitive) BOOL caseSensitive;

/**
 Creates and returns a search engine object.

 @returns A search engine object.
 */
+ (id)searchEngine;

///-----------------------------------------------------------------------------
/// @name Performing a Search
///-----------------------------------------------------------------------------

/**
 Searches a collection of RKSearchable objects for the given text using the configuration of the receiver
 and returns an array of objects for which a match was found.

 @return A new array containing the objects in the given collection for which a match was found.
 @exception NSInvalidArgumentException Raised if any objects contained in the search collection do not
 conform to the RKSearchable protocol.
 */
- (NSArray *)searchFor:(NSString *)searchText inCollection:(NSArray *)collection;

/**
 Searches a set of properties in a collection of objects for the given text using the configuration of the receiver
 and returns an array of objects for which a match was found.

 @return A new array containing the objects in the given collection for which a match was found.
 @exception NSInvalidArgumentException Raised if any objects contained in the search collection do not
 conform to the RKSearchable protocol.
 */
- (NSArray *)searchFor:(NSString *)searchText onProperties:(NSArray *)properties inCollection:(NSArray *)collection;

@end
