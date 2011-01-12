//
//  RKSearchEngine.h
//  Two Toasters
//
//  Created by Blake Watters on 8/26/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Methods conforming to this protocol are searchable
 * without specifying a list of properties to concatenate
 */
@protocol RKSearchable

/**
 * Returns a string representation of searchable text the object exposes
 */
- (NSString*)searchableText;

@end

typedef enum _RKSearchMode {
	RKSearchModeAnd,
	RKSearchModeOr
} RKSearchMode;

@interface RKSearchEngine : NSObject {
	RKSearchMode _mode;
	BOOL _tokenizeQuery;
	BOOL _stripWhitespace;
	BOOL _caseSensitive;
}

/**
 * The type of searching to perform. Can be either RKSearchModeAnd or RKSearchModeOr.
 *
 * Defaults to RKSearchModeOr
 */
@property (nonatomic, assign) RKSearchMode mode;

/**
 * Whether or not to split the search query at whitespace boundaries or consider the string
 * as a single term
 *
 * Defaults to YES
 */
@property (nonatomic, assign) BOOL tokenizeQuery;

/**
 * Whether or not to strip the whitespace off of the search terms before searching. This can
 * prevent search misses when the terms have leading/trailing whitespace
 *
 * Defaults to YES
 */
@property (nonatomic, assign) BOOL stripWhitespace;

/**
 * Whether or not to perform a case-sensitive search
 *
 * Defaults to NO
 */
@property (nonatomic, assign) BOOL caseSensitive;

/**
 * Construct a new search engine
 */
+ (id)searchEngine;

/**
 * Search for a string in a collection of RKSearchable objects
 */
- (NSArray*)searchFor:(NSString*)searchText inCollection:(NSArray*)collection;

/**
 * Search for a string in a collection of objects by specifying an array of
 * properties (strings that correspond to the selectors of properties) that return strings
 */
- (NSArray*)searchFor:(NSString*)searchText onProperties:(NSArray*)properties inCollection:(NSArray*)collection;

@end
