//
//  RKRequestFilterableTTModel.m
//  RestKit
//
//  Created by Blake Watters on 2/12/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKRequestFilterableTTModel.h"

@implementation RKRequestFilterableTTModel

@synthesize searchEngine = _searchEngine;
@synthesize predicate = _predicate;
@synthesize sortDescriptors = _sortDescriptors;
@synthesize sortSelector = _sortSelector;

- (id)init {
	if (self = [super init]) {
		_predicate = nil;
		_sortDescriptors = nil;
		_searchText = nil;
		_searchEngine = nil;
	}
	
	return self;
}

- (void)dealloc {
	[_searchEngine release];_searchEngine=nil;
	[_predicate release];_predicate=nil;
	[_sortDescriptors release];_sortDescriptors=nil;
	[_searchText release];_searchText=nil;
	[super dealloc];
}

- (void)reset {
	[_predicate release];_predicate=nil;
	[_sortDescriptors release];_sortDescriptors=nil;
	[_searchText release];_searchText=nil;
	[self didChange];
}

- (NSArray*)didSearchCollectionWithEmptyText:(NSArray*)collection {
	return collection;
}

- (RKSearchEngine*)createSearchEngine {
	if (nil == _searchEngine) {
		_searchEngine = [[RKSearchEngine searchEngine] retain];
		_searchEngine.mode = RKSearchModeAnd;
	}
	return _searchEngine;
}

- (NSArray*)search:(NSString *)text inCollection:(NSArray*)collection {
	if (text.length) {
		RKSearchEngine* searchEngine = [self createSearchEngine];
		return [searchEngine searchFor:text inCollection:collection];
	} else {
		return [self didSearchCollectionWithEmptyText:collection];
	}
}

// public

- (void)search:(NSString *)text {
	[_searchText release];
	_searchText = [text retain];
	[self didFinishLoad];
}

// Overloaded to hide filtering/searching from the underlying data source
- (NSArray*)objects {
	NSArray* results = _model.objects;
	if (self.predicate) {
		results = [results filteredArrayUsingPredicate:self.predicate];
	}
	
	if (_searchText) {
		results = [self search:_searchText inCollection:results];
	}
	
	if (self.sortSelector) {
		results = [results sortedArrayUsingSelector:self.sortSelector];
	} else if (self.sortDescriptors) {
		results = [results sortedArrayUsingDescriptors:self.sortDescriptors];
	}
	
	return results;
}

@end
