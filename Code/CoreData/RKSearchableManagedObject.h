//
//  RKSearchableManagedObject.h
//  RestKit
//
//  Created by Jeff Arena on 3/31/11.
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

#import "NSManagedObject+ActiveRecord.h"
#import "RKManagedObjectSearchEngine.h"

@class RKSearchWord;

/**
 RKSearchableManagedObject provides an abstract base class for Core Data entities
 that are searchable using the RKManagedObjectSearchEngine interface. The collection of
 search words is maintained by the RKSearchWordObserver singleton at managed object context
 save time.

 @see RKSearchWord
 @see RKSearchWordObserver
 @see RKManagedObjectSearchEngine
 */
@interface RKSearchableManagedObject : NSManagedObject

///-----------------------------------------------------------------------------
/// @name Configuring Searchable Attributes
///-----------------------------------------------------------------------------

/**
 Returns an array of attributes which should be processed by the search word observer to
 build the set of search words for entities with the type of the receiver. Subclasses must
 provide an implementation for indexing to occur as the base implementation returns an empty
 array.

 @warning *NOTE*: May only include attributes property names, not key paths.

 @return An array of attribute names containing searchable textual content for entities with the type of the receiver.
 @see RKSearchWordObserver
 @see searchWords
 */
+ (NSArray *)searchableAttributes;

///-----------------------------------------------------------------------------
/// @name Obtaining a Search Predicate
///-----------------------------------------------------------------------------

/**
 A predicate that will search for the specified text with the specified mode. Mode can be
 configured to be RKSearchModeAnd or RKSearchModeOr.

 @return A predicate that will search for the specified text with the specified mode.
 @see RKSearchMode
 */

+ (NSPredicate *)predicateForSearchWithText:(NSString *)searchText searchMode:(RKSearchMode)mode;

///-----------------------------------------------------------------------------
/// @name Managing the Search Words
///-----------------------------------------------------------------------------

/**
 The set of tokenized search words contained in the receiver.
 */
@property (nonatomic, retain) NSSet *searchWords;

/**
 Rebuilds the set of tokenized search words associated with the receiver by processing the
 searchable attributes and tokenizing the contents into RKSearchWord instances.

 @see [RKSearchableManagedObject searchableAttributes]
 */
- (void)refreshSearchWords;

@end

@interface RKSearchableManagedObject (SearchWordsAccessors)

/**
 Adds a search word object to the receiver's set of search words.

 @param searchWord The search word to be added to the set of search words.
 */
- (void)addSearchWordsObject:(RKSearchWord *)searchWord;

/**
 Removes a search word object from the receiver's set of search words.

 @param searchWord The search word to be removed from the receiver's set of search words.
 */
- (void)removeSearchWordsObject:(RKSearchWord *)searchWord;

/**
 Adds a set of search word objects to the receiver's set of search words.

 @param searchWords The set of search words to be added to receiver's the set of search words.
 */
- (void)addSearchWords:(NSSet *)searchWords;

/**
 Removes a set of search word objects from the receiver's set of search words.

 @param searchWords The set of search words to be removed from receiver's the set of search words.
 */
- (void)removeSearchWords:(NSSet *)searchWords;

@end
