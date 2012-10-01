//
//  RKObjectPaginator.m
//  RestKit
//
//  Created by Blake Watters on 12/29/11.
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

#import "RKObjectPaginator.h"
#import "RKManagedObjectLoader.h"
#import "RKMappingOperation.h"
#import "SOCKit.h"
#import "RKLog.h"

static NSUInteger RKObjectPaginatorDefaultPerPage = 25;

// Private interface
@interface RKObjectPaginator () <RKObjectLoaderDelegate>
@property (nonatomic, retain) RKObjectLoader *objectLoader;
@property (nonatomic, assign, readwrite) NSUInteger currentPage;
@property (nonatomic, assign, readwrite) NSUInteger pageCount;
@property (nonatomic, assign, readwrite) NSUInteger objectCount;
@property (nonatomic, assign, readwrite) BOOL loaded;
@end

@implementation RKObjectPaginator

@synthesize patternURL = _patternURL;
@synthesize currentPage = _currentPage;
@synthesize perPage = _perPage;
@synthesize loaded = _loaded;
@synthesize pageCount = _pageCount;
@synthesize objectCount = _objectCount;
@synthesize mappingProvider = _mappingProvider;
@synthesize delegate = _delegate;
@synthesize managedObjectStore = _managedObjectStore;
@synthesize objectLoader = _objectLoader;
@synthesize configurationDelegate = _configurationDelegate;
@synthesize onDidLoadObjectsForPage = _onDidLoadObjectsForPage;
@synthesize onDidFailWithError = _onDidFailWithError;

+ (id)paginatorWithPatternURL:(RKURL *)aPatternURL mappingProvider:(RKObjectMappingProvider *)aMappingProvider
{
    return [[[self alloc] initWithPatternURL:aPatternURL mappingProvider:aMappingProvider] autorelease];
}

- (id)initWithPatternURL:(RKURL *)aPatternURL mappingProvider:(RKObjectMappingProvider *)aMappingProvider
{
    self = [super init];
    if (self) {
        self.patternURL = [aPatternURL copy];
        self.mappingProvider = [aMappingProvider retain];
        self.currentPage = NSUIntegerMax;
        self.pageCount = NSUIntegerMax;
        self.objectCount = NSUIntegerMax;
        self.perPage = RKObjectPaginatorDefaultPerPage;
        self.loaded = NO;
    }

    return self;
}

- (void)dealloc
{
    _delegate = nil;
    _configurationDelegate = nil;
    _objectLoader.delegate = nil;
    [_patternURL release];
    _patternURL = nil;
    [_mappingProvider release];
    _mappingProvider = nil;
    [_managedObjectStore release];
    _managedObjectStore = nil;
    [_objectLoader cancel];
    _objectLoader.delegate = nil;
    [_objectLoader release];
    _objectLoader = nil;
    [_onDidLoadObjectsForPage release];
    _onDidLoadObjectsForPage = nil;
    [_onDidFailWithError release];
    _onDidFailWithError = nil;

    [super dealloc];
}

- (RKObjectMapping *)paginationMapping
{
    return [self.mappingProvider paginationMapping];
}

- (RKURL *)URL
{
    return [self.patternURL URLByInterpolatingResourcePathWithObject:self];
}

// Private. Public consumers can rely on isLoaded
- (BOOL)hasCurrentPage
{
    return _currentPage != NSUIntegerMax;
}

- (BOOL)hasPageCount
{
    return _pageCount != NSUIntegerMax;
}

- (BOOL)hasObjectCount
{
    return _objectCount != NSUIntegerMax;
}

- (NSUInteger)currentPage
{
    // Referenced during initial load, so we don't rely on isLoaded.
    NSAssert([self hasCurrentPage], @"Current page has not been initialized.");
    return _currentPage;
}

- (NSUInteger)pageCount
{
    NSAssert([self hasPageCount], @"Page count not available.");
    return _pageCount;
}

- (BOOL)hasNextPage
{
    NSAssert(self.isLoaded, @"Cannot determine hasNextPage: paginator is not loaded.");
    NSAssert([self hasPageCount], @"Cannot determine hasNextPage: page count is not known.");

    return self.currentPage < self.pageCount;
}

- (BOOL)hasPreviousPage
{
    NSAssert(self.isLoaded, @"Cannot determine hasPreviousPage: paginator is not loaded.");
    return self.currentPage > 1;
}

#pragma mark - RKObjectLoaderDelegate methods

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects
{
    self.objectLoader = nil;
    self.loaded = YES;
    RKLogInfo(@"Loaded objects: %@", objects);
    [self.delegate paginator:self didLoadObjects:objects forPage:self.currentPage];

    if (self.onDidLoadObjectsForPage) {
        self.onDidLoadObjectsForPage(objects, self.currentPage);
    }

    if ([self hasPageCount] && self.currentPage == 1) {
        if ([self.delegate respondsToSelector:@selector(paginatorDidLoadFirstPage:)]) {
            [self.delegate paginatorDidLoadFirstPage:self];
        }
    }

    if ([self hasPageCount] && self.currentPage == self.pageCount) {
        if ([self.delegate respondsToSelector:@selector(paginatorDidLoadLastPage:)]) {
            [self.delegate paginatorDidLoadLastPage:self];
        }
    }
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error
{
    RKLogError(@"Paginator error %@", error);
    [self.delegate paginator:self didFailWithError:error objectLoader:self.objectLoader];
    if (self.onDidFailWithError) {
        self.onDidFailWithError(error, self.objectLoader);
    }
    self.objectLoader = nil;
}

- (void)objectLoader:(RKObjectLoader *)loader willMapData:(inout id *)mappableData
{
    NSError *error = nil;
    RKMappingOperation *mappingOperation = [RKMappingOperation mappingOperationFromObject:*mappableData toObject:self withMapping:[self paginationMapping]];
    BOOL success = [mappingOperation performMapping:&error];
    if (!success) {
        self.pageCount = 0;
        self.currentPage = 0;
        RKLogError(@"Paginator didn't map info to compute page count. Assuming no pages.");
    } else if (self.perPage && [self hasObjectCount]) {
        float objectCountFloat = self.objectCount;
        self.pageCount = ceilf(objectCountFloat / self.perPage);
        RKLogInfo(@"Paginator objectCount: %ld pageCount: %ld", (long)self.objectCount, (long)self.pageCount);
    } else {
        NSAssert(NO, @"Paginator perPage set is 0.");
        RKLogError(@"Paginator perPage set is 0.");
    }
}

#pragma mark - Action methods

- (void)loadNextPage
{
    [self loadPage:self.currentPage + 1];
}

- (void)loadPreviousPage
{
    [self loadPage:self.currentPage - 1];
}

- (void)loadPage:(NSUInteger)pageNumber
{
    NSAssert(self.mappingProvider, @"Cannot perform a load with a nil mappingProvider.");
    NSAssert(! self.objectLoader, @"Cannot perform a load while one is already in progress.");
    self.currentPage = pageNumber;

    if (self.managedObjectStore) {
        RKManagedObjectLoader *managedObjectLoader = [[[RKManagedObjectLoader alloc] initWithURL:self.URL mappingProvider:self.mappingProvider] autorelease];
        managedObjectLoader.managedObjectContext = self.managedObjectStore.primaryManagedObjectContext;
        managedObjectLoader.mainQueueManagedObjectContext = self.managedObjectStore.mainQueueManagedObjectContext;
        self.objectLoader = managedObjectLoader;
    } else {
        self.objectLoader = [[[RKObjectLoader alloc] initWithURL:self.URL mappingProvider:self.mappingProvider] autorelease];
    }

    if ([self.configurationDelegate respondsToSelector:@selector(configureObjectLoader:)]) {
        [self.configurationDelegate configureObjectLoader:self.objectLoader];
    }
    self.objectLoader.method = RKRequestMethodGET;
    self.objectLoader.delegate = self;

    if ([self.delegate respondsToSelector:@selector(paginator:willLoadPage:objectLoader:)]) {
        [self.delegate paginator:self willLoadPage:pageNumber objectLoader:self.objectLoader];
    }

    [self.objectLoader send];
}

@end
