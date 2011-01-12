//
//  RKRequestFilterableTTModel.h
//  RestKit
//
//  Created by Blake Watters on 2/12/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKRequestTTModel.h"
#import "../Support/RKSearchEngine.h"

/**
 * Provides an interface for searching and filtering a collection
 * of objects loaded from a remote source
 */
@interface RKRequestFilterableTTModel : RKRequestTTModel {
	RKSearchEngine* _searchEngine;
	NSPredicate* _predicate;
	NSArray* _sortDescriptors;
	NSString* _searchText;
	SEL _sortSelector;
	NSArray* _filteredObjects;
}

/**
 * A predicate to filter the model objects by
 */	
@property (nonatomic, retain) NSPredicate* predicate;

/**
 * An array of sort descriptors to sort the objects with
 */
@property (nonatomic, retain) NSArray* sortDescriptors;

/**
 * A selector to use in sorting the objects.  When present,
 * the sortSelector will be used for sorting objects, rather than
 * the sortDescriptors.
 */
@property (nonatomic, assign) SEL sortSelector;

/**
 * A search engine instance for searching the data. If none is assigned,
 * a default search engine will be created for you
 */
@property (nonatomic, retain) RKSearchEngine* searchEngine;

/**
 * Creates an RKSearchEngine instance for searching the collection.
 */
- (RKSearchEngine*)createSearchEngine;

/**
 * Resets the model by clearing the filter, sort descriptor, and search text
 */
- (void)reset;

/**
 * Triggered when the model was search with empty text. Default implementation preserves filtered collection.
 */
- (NSArray*)didSearchCollectionWithEmptyText:(NSArray*)collection;

/**
 * Search the model for matching text
 */
- (void)search:(NSString*)text;

@end
