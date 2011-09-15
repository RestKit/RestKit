//
//  RKFilterableObjectLoaderTTModel.m
//  RestKit
//
//  Created by Blake Watters on 2/12/10.
//  Copyright 2010 Two Toasters
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

#import "RKFilterableObjectLoaderTTModel.h"

@implementation RKFilterableObjectLoaderTTModel

@synthesize searchEngine = _searchEngine;
@synthesize predicate = _predicate;
@synthesize sortDescriptors = _sortDescriptors;
@synthesize sortSelector = _sortSelector;

- (id)init {
    self = [super init];
	if (self) {
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
