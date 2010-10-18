//
//  RKRequestFilterableTTModel.m
//  RestKit
//
//  Created by Blake Watters on 2/12/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKRequestFilterableTTModel.h"
#import "RKSearchEngine.h"

@implementation RKRequestFilterableTTModel

@synthesize searchEngine = _searchEngine;
@synthesize predicate = _predicate;
@synthesize sortDescriptor = _sortDescriptor;

- (id)init {
	if (self = [super init]) {
		_predicate = nil;
		_sortDescriptor = nil;
		_searchText = nil;
		_searchEngine = nil;
	}
	
	return self;
}

- (void)dealloc {
	[_searchEngine release];_searchEngine=nil;
	[_predicate release];_predicate=nil;
	[_sortDescriptor release];_sortDescriptor=nil;
	[_searchText release];_searchText=nil;
	[super dealloc];
}

- (void)reset {
	[_predicate release];_predicate=nil;
	[_sortDescriptor release];_sortDescriptor=nil;
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
	
	if (self.sortDescriptor) {
		results = [results sortedArrayUsingDescriptors:[NSArray arrayWithObject:self.sortDescriptor]];
	}
	
	return results;
}

@end
