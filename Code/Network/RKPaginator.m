//
//  RKPaginator.m
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

#import "RKPaginator.h"
#import "RKMappingOperation.h"
#import "SOCKit.h"
#import "RKLog.h"
#import "RKPathMatcher.h"
#import "RKHTTPUtilities.h"

#if __has_include("CoreData.h")
#define RKCoreDataIncluded
#import "RKManagedObjectRequestOperation.h"
#endif

static NSUInteger RKPaginatorDefaultPerPage = 25;

// Private interface
@interface RKPaginator ()
@property (nonatomic, copy) NSURLRequest *request;
@property (nonatomic, strong) Class HTTPOperationClass;
@property (nonatomic, copy) NSArray *responseDescriptors;
@property (nonatomic, assign, readwrite) NSUInteger currentPage;
@property (nonatomic, assign, readwrite) NSUInteger offset;
@property (nonatomic, assign, readwrite) NSUInteger pageCount;
@property (nonatomic, assign, readwrite) NSUInteger objectCount;
@property (nonatomic, assign, readwrite) BOOL loaded;
@property (nonatomic, strong, readwrite) RKMappingResult *mappingResult;
@property (nonatomic, strong, readwrite) NSError *error;
@property (nonatomic, strong, readwrite) RKObjectRequestOperation *objectRequestOperation;

// iOS 5.x compatible proxy attributes
@property (nonatomic, assign, readwrite) NSNumber *perPageNumber;
@property (nonatomic, assign, readwrite) NSNumber *currentPageNumber;
@property (nonatomic, assign, readwrite) NSNumber *pageCountNumber;
@property (nonatomic, assign, readwrite) NSNumber *objectCountNumber;

@property (nonatomic, copy) void (^successBlock)(RKPaginator *paginator, NSArray *objects, NSUInteger page);
@property (nonatomic, copy) void (^failureBlock)(RKPaginator *paginator, NSError *error);
@end

@implementation RKPaginator


- (instancetype)initWithRequest:(NSURLRequest *)request
    paginationMapping:(RKObjectMapping *)paginationMapping
  responseDescriptors:(NSArray *)responseDescriptors;
{
    NSParameterAssert(request);
    NSParameterAssert(paginationMapping);
    NSParameterAssert(responseDescriptors);
    NSAssert([paginationMapping.objectClass isSubclassOfClass:[RKPaginator class]], @"The paginationMapping must have a target object class of `RKPaginator`");
    self = [super init];
    if (self) {
        self.HTTPOperationClass = [RKHTTPRequestOperation class];
        self.request = request;
        self.paginationMapping = paginationMapping;
        self.responseDescriptors = responseDescriptors;
        self.currentPage = NSNotFound;
        self.pageCount = NSNotFound;
        self.objectCount = NSNotFound;
        self.offset = NSNotFound;
        self.perPage = RKPaginatorDefaultPerPage;
        self.loaded = NO;
    }

    return self;
}

- (void)dealloc
{
    [self.objectRequestOperation cancel];
}

- (NSURL *)patternURL
{
    return self.request.URL;
}

- (NSURL *)URL
{
    NSString *pathAndQueryString = RKPathAndQueryStringFromURLRelativeToURL(self.patternURL, nil);
    NSString *interpolatedString = RKPathFromPatternWithObject(pathAndQueryString, self);
    return [NSURL URLWithString:interpolatedString relativeToURL:self.request.URL];
}

- (void)setHTTPOperationClass:(Class)operationClass
{
    NSAssert(operationClass == nil || [operationClass isSubclassOfClass:[RKHTTPRequestOperation class]], @"The HTTP operation class must be a subclass of `RKHTTPRequestOperation`");
    _HTTPOperationClass = operationClass;
}

- (void)setCompletionBlockWithSuccess:(void (^)(RKPaginator *paginator, NSArray *objects, NSUInteger page))success
                              failure:(void (^)(RKPaginator *paginator, NSError *error))failure
{
    self.successBlock = success;
    self.failureBlock = failure;
}

// Private. Public consumers can rely on isLoaded
- (BOOL)hasCurrentPage
{
    return _currentPage != NSNotFound;
}

- (BOOL)hasOffset
{
    return _offset != NSNotFound;
}

- (BOOL)hasPageCount
{
    return _pageCount != NSNotFound;
}

- (BOOL)hasObjectCount
{
    return _objectCount != NSNotFound;
}

- (NSUInteger)currentPage
{
    // Referenced during initial load, so we don't rely on isLoaded.
    NSAssert([self hasCurrentPage], @"Current page has not been initialized.");
    return _currentPage;
}

- (NSUInteger)offset
{
    if ([self hasOffset]) return _offset;
    return [self hasCurrentPage] ? ((_currentPage - 1) * _perPage) : 0;
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
    if (self.objectRequestOperation.HTTPRequestOperation.response) {
        // The user by calling loadPage is ready to perform the next request so invalidate objectRequestOperation
        self.objectRequestOperation = nil;
    }

    NSAssert(self.responseDescriptors, @"Cannot perform a load with nil response descriptors.");
    NSAssert(! self.objectRequestOperation, @"Cannot perform a load while one is already in progress.");
    self.currentPage = pageNumber;
    
    NSMutableURLRequest *mutableRequest = [self.request mutableCopy];
    mutableRequest.URL = self.URL;

#ifdef RKCoreDataIncluded
    if (self.managedObjectContext) {
        RKHTTPRequestOperation *requestOperation = [[self.HTTPOperationClass alloc] initWithRequest:mutableRequest];
        RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithHTTPRequestOperation:requestOperation responseDescriptors:self.responseDescriptors];
        managedObjectRequestOperation.managedObjectContext = self.managedObjectContext;
        managedObjectRequestOperation.managedObjectCache = self.managedObjectCache;
        managedObjectRequestOperation.fetchRequestBlocks = self.fetchRequestBlocks;
        managedObjectRequestOperation.deletesOrphanedObjects = NO;
        
        self.objectRequestOperation = managedObjectRequestOperation;
    } else {
        self.objectRequestOperation = [[RKObjectRequestOperation alloc] initWithRequest:mutableRequest responseDescriptors:self.responseDescriptors];
    }
#else
    self.objectRequestOperation = [[RKObjectRequestOperation alloc] initWithRequest:mutableRequest responseDescriptors:self.responseDescriptors];
#endif

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
    [self.objectRequestOperation setWillMapDeserializedResponseBlock:^id(id deserializedResponseBody) {
        NSError *error = nil;
        RKMappingOperation *mappingOperation = [[RKMappingOperation alloc] initWithSourceObject:deserializedResponseBody destinationObject:self mapping:self.paginationMapping];
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
            RKLogError(@"Paginator perPage set is 0.");
        }
        
        return deserializedResponseBody;
    }];
    [self.objectRequestOperation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        [self finish];
        if (self.successBlock) {
            self.successBlock(self, [mappingResult array], self.currentPage);
        }
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        [self finish];
        if (self.failureBlock) {
            self.failureBlock(self, error);
        }
    }];
#pragma clang diagnostic pop
    
    if (self.operationQueue) {
        [self.operationQueue addOperation:self.objectRequestOperation];
    } else {
        [self.objectRequestOperation start];
    }
}

- (void)waitUntilFinished
{
    [self.objectRequestOperation waitUntilFinished];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p patternURL=%@ isLoaded=%@ perPage=%ld currentPage=%@ offset=%@ pageCount=%@ objectCount=%@>",
            NSStringFromClass([self class]), self, self.patternURL, self.isLoaded ? @"YES" : @"NO", (long) self.perPage,
            [self hasCurrentPage] ? @(self.currentPage) : @"???",
            [self hasOffset] ? @(self.offset) : @"???",
            [self hasPageCount] ? @(self.pageCount) : @"???",
            [self hasObjectCount] ? @(self.objectCount) : @"???"];
}

- (void)finish
{
    self.loaded = (self.objectRequestOperation.mappingResult != nil);
    self.mappingResult = self.objectRequestOperation.mappingResult;
    self.error = self.objectRequestOperation.error;
}

- (void)cancel
{
    [self.objectRequestOperation cancel];
    self.objectRequestOperation = nil;
}

#pragma mark - iOS 5 proxy attributes

- (NSNumber *)perPageNumber
{
    return @(self.perPage);
}

- (void)setPerPageNumber:(NSNumber *)perPageNumber
{
    self.perPage = [perPageNumber unsignedIntegerValue];
}

- (NSNumber *)currentPageNumber
{
    return @(self.currentPage);
}

- (void)setCurrentPageNumber:(NSNumber *)currentPageNumber
{
    self.currentPage = [currentPageNumber unsignedIntegerValue];
}

- (NSNumber *)pageCountNumber
{
    return @(self.pageCount);
}

- (void)setPageCountNumber:(NSNumber *)pageCountNumber
{
    self.pageCount = [pageCountNumber unsignedIntegerValue];
}

- (NSNumber *)objectCountNumber
{
    return @(self.objectCount);
}

- (void)setObjectCountNumber:(NSNumber *)objectCountNumber
{
    self.objectCount = [objectCountNumber unsignedIntegerValue];
}

- (NSNumber *)offsetNumber
{
    return @(self.offset);
}

- (void)setOffsetNumber:(NSNumber *)offsetNumber
{
    self.offset = [offsetNumber unsignedIntegerValue];
}

@end
