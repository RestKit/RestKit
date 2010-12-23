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
		self.predicate = nil;
		self.sortDescriptors = nil;
		self.searchEngine = nil;
		_searchText = nil;
		_filteredObjects = nil;
	}
	return self;
}

- (void)dealloc {
	self.predicate = nil;
	self.sortDescriptors = nil;
	self.searchEngine = nil;
	[_searchText release];
	_searchText = nil;
	[super dealloc];
}

- (void)reset {
	self.predicate = nil;
	self.sortDescriptors = nil;
	[_searchText release];
	_searchText = nil;
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

- (NSArray*)search:(NSString*)text inCollection:(NSArray*)collection {
	if (text.length) {
		RKSearchEngine* searchEngine = [self createSearchEngine];
		return [searchEngine searchFor:text inCollection:collection];
	} else {
		return [self didSearchCollectionWithEmptyText:collection];
	}
}

- (void)search:(NSString*)text {
	[_searchText release];
	_searchText = nil;
	_searchText = [text retain];
	
	[_filteredObjects release];
	_filteredObjects = nil;
	
	[self didFinishLoad];
}

- (void)filterRawObjects {
	NSArray* results = _objects;
	if (results && [results count] > 0) {
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
		
		_filteredObjects = [results retain];
	} else {
		_filteredObjects = [results copy];
	}
}

- (NSArray*)objects {
	if (nil == _filteredObjects) {
		[self filterRawObjects];
	}
	return _filteredObjects;
}

- (void)modelsDidLoad:(NSArray*)models {
	[models retain];
	[_objects release];
	_objects = nil;
	[_filteredObjects release];
	_filteredObjects = nil;
	
	_objects = models;
	[self filterRawObjects];
	_isLoaded = YES;
	
	[self didFinishLoad];
}

- (void)setPredicate:(NSPredicate*)predicate {
	[_predicate release];
	_predicate = nil;
	_predicate = [predicate retain];
	
	[_filteredObjects release];
	_filteredObjects = nil;
}

- (void)setSortDescriptors:(NSArray*)sortDescriptors {
	[_sortDescriptors release];
	_sortDescriptors = nil;
	_sortDescriptors = [sortDescriptors retain];
	
	[_filteredObjects release];
	_filteredObjects = nil;
}

- (void)setSortSelector:(SEL)sortSelector {
	_sortSelector = nil;
	_sortSelector = sortSelector;
	
	[_filteredObjects release];
	_filteredObjects = nil;
}

@end
