//
//  RKSearchEngine.m
//  Two Toasters
//
//  Created by Blake Watters on 8/26/09.
//  Copyright 2009 Two Toasters
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

#import "RKSearchEngine.h"

@implementation RKSearchEngine

@synthesize mode = _mode, tokenizeQuery = _tokenizeQuery, stripWhitespace = _stripWhitespace, caseSensitive = _caseSensitive;

+ (id)searchEngine {
	return [[[RKSearchEngine alloc] init] autorelease];
}

- (id)init {
    self = [super init];
	if (self) {
		_mode = RKSearchModeOr;
		_tokenizeQuery = YES;
		_stripWhitespace = YES;
		_caseSensitive = NO;
	}
	
	return self;
}

#pragma mark Private
#pragma mark -

- (NSString*)stripWhitespaceIfNecessary:(NSString*)string {
	if (_stripWhitespace) {
		return [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	} else {
		return string;
	}
}

- (NSArray*)tokenizeOrCollect:(NSString*)string {
	if (_tokenizeQuery) {
		return [string componentsSeparatedByString:@" "];
	} else {
		return [NSArray arrayWithObject:string];
	}
}

- (NSArray*)searchWithTerms:(NSArray*)searchTerms onProperties:(NSArray*)properties inCollection:(NSArray*)collection compoundSelector:(SEL)selector {
	NSPredicate* searchPredicate = nil;
	
	// do any of these properties contain all of these terms
	NSMutableArray* propertyPredicates = [NSMutableArray array];
	for (NSString* property in properties) {		
		NSMutableArray* termPredicates = [NSMutableArray array];
		for (NSString* searchTerm in searchTerms) {
			NSPredicate* predicate;
			if (_caseSensitive) {
				predicate = [NSPredicate predicateWithFormat:@"(%K contains %@)", property, searchTerm];
			} else {
				predicate = [NSPredicate predicateWithFormat:@"(%K contains[cd] %@)", property, searchTerm];
			}
			[termPredicates addObject:predicate];
		}
		
		// build an and predicate for all of the search terms
		NSPredicate* termsPredicate = [NSCompoundPredicate performSelector:selector withObject:termPredicates];
		[propertyPredicates addObject:termsPredicate];
	}
	
	searchPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:propertyPredicates];
	return [collection filteredArrayUsingPredicate:searchPredicate];
}

#pragma mark Public
#pragma mark -

- (NSArray*)searchFor:(NSString*)searchText inCollection:(NSArray*)collection {
	NSArray* properties = [NSArray arrayWithObject:@"searchableText"];
	return [self searchFor:searchText onProperties:properties inCollection:collection];
}

- (NSArray*)searchFor:(NSString*)searchText onProperties:(NSArray*)properties inCollection:(NSArray*)collection {
	NSString* searchQuery = [[searchText copy] autorelease];
	searchQuery = [self stripWhitespaceIfNecessary:searchQuery];
	NSArray* searchTerms = [self tokenizeOrCollect:searchQuery];
	
	if (_mode == RKSearchModeOr) {
		return [self searchWithTerms:searchTerms onProperties:properties inCollection:collection compoundSelector:@selector(orPredicateWithSubpredicates:)];
	} else if (_mode == RKSearchModeAnd) {
		return [self searchWithTerms:searchTerms onProperties:properties inCollection:collection compoundSelector:@selector(andPredicateWithSubpredicates:)];
	} else {
		return nil;
	}
}

@end
