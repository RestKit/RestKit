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
#import "RKObjectRequestOperation.h"
#import "RKManagedObjectRequestOperation.h"
#import "SOCKit.h"
#import "RKLog.h"
#import "RKPathUtilities.h"
#import "RKHTTPUtilities.h"

static NSUInteger RKPaginatorDefaultPerPage = 25;

// Private interface
@interface RKPaginator ()
@property (nonatomic, copy) NSURLRequest *request;
@property (nonatomic, strong) RKObjectRequestOperation *objectRequestOperation;
@property (nonatomic, copy) NSArray *responseDescriptors;
@property (nonatomic, assign, readwrite) NSUInteger currentPage;
@property (nonatomic, assign, readwrite) NSUInteger pageCount;
@property (nonatomic, assign, readwrite) NSUInteger objectCount;
@property (nonatomic, assign, readwrite) BOOL loaded;
@property (nonatomic, strong, readwrite) RKMappingResult *mappingResult;
@property (nonatomic, strong, readwrite) NSError *error;

@property (nonatomic, copy) void (^successBlock)(RKPaginator *paginator, NSArray *objects, NSUInteger page);
@property (nonatomic, copy) void (^failureBlock)(RKPaginator *paginator, NSError *error);
@end

@implementation RKPaginator

- (id)initWithRequest:(NSURLRequest *)request
    paginationMapping:(RKObjectMapping *)paginationMapping
  responseDescriptors:(NSArray *)responseDescriptors;
{
    NSParameterAssert(request);
    NSParameterAssert(paginationMapping);
    NSParameterAssert(responseDescriptors);
    NSAssert([paginationMapping.objectClass isSubclassOfClass:[RKPaginator class]], @"The paginationMapping must have a target object class of `RKPaginator`");
    self = [super init];
    if (self) {
        self.request = request;
        self.paginationMapping = paginationMapping;
        self.responseDescriptors = responseDescriptors;
        self.currentPage = NSNotFound;
        self.pageCount = NSNotFound;
        self.objectCount = NSNotFound;
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
    NSAssert(self.responseDescriptors, @"Cannot perform a load with nil response descriptors.");
    NSAssert(! self.objectRequestOperation, @"Cannot perform a load while one is already in progress.");
    self.currentPage = pageNumber;
    
    NSMutableURLRequest *mutableRequest = [self.request mutableCopy];
    mutableRequest.URL = self.URL;

    if (self.managedObjectContext) {
        RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:mutableRequest responseDescriptors:self.responseDescriptors];
        managedObjectRequestOperation.managedObjectContext = self.managedObjectContext;
        managedObjectRequestOperation.managedObjectCache = self.managedObjectCache;
        managedObjectRequestOperation.fetchRequestBlocks = self.fetchRequestBlocks;
        managedObjectRequestOperation.deletesOrphanedObjects = NO;
        
        self.objectRequestOperation = managedObjectRequestOperation;
    } else {
        self.objectRequestOperation = [[RKObjectRequestOperation alloc] initWithRequest:mutableRequest responseDescriptors:self.responseDescriptors];
    }
    
    // Add KVO to ensure notification of loaded state prior to execution of completion block
    [self.objectRequestOperation addObserver:self forKeyPath:@"isFinished" options:0 context:nil];
    
    __weak RKPaginator *weakSelf = self;
    [self.objectRequestOperation setWillMapDeserializedResponseBlock:^id(id deserializedResponseBody) {
        NSError *error = nil;
        RKMappingOperation *mappingOperation = [[RKMappingOperation alloc] initWithSourceObject:deserializedResponseBody destinationObject:weakSelf mapping:weakSelf.paginationMapping];
        BOOL success = [mappingOperation performMapping:&error];
        if (!success) {
            weakSelf.pageCount = 0;
            weakSelf.currentPage = 0;
            RKLogError(@"Paginator didn't map info to compute page count. Assuming no pages.");
        } else if (weakSelf.perPage && [weakSelf hasObjectCount]) {
            float objectCountFloat = weakSelf.objectCount;
            weakSelf.pageCount = ceilf(objectCountFloat / weakSelf.perPage);
            RKLogInfo(@"Paginator objectCount: %ld pageCount: %ld", (long)weakSelf.objectCount, (long)weakSelf.pageCount);
        } else {
            RKLogError(@"Paginator perPage set is 0.");
        }
        
        return deserializedResponseBody;
    }];
    [self.objectRequestOperation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        if (weakSelf.successBlock) {
            weakSelf.successBlock(weakSelf, [mappingResult array], weakSelf.currentPage);
        }
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        if (weakSelf.failureBlock) {
            weakSelf.failureBlock(weakSelf, error);
        }
    }];
    
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
    return [NSString stringWithFormat:@"<%@: %p patternURL=%@ isLoaded=%@ perPage=%ld currentPage=%@ pageCount=%@ objectCount=%@>",
            NSStringFromClass([self class]), self, self.patternURL, self.isLoaded ? @"YES" : @"NO", (long) self.perPage,
            [self hasCurrentPage] ? @(self.currentPage) : @"???",
            [self hasPageCount] ? @(self.pageCount) : @"???",
            [self hasObjectCount] ? @(self.objectCount) : @"???"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"isFinished"] && [self.objectRequestOperation isFinished]) {
        self.loaded = (self.objectRequestOperation.mappingResult != nil);
        self.mappingResult = self.objectRequestOperation.mappingResult;
        self.error = self.objectRequestOperation.error;
        self.objectRequestOperation = nil;
        [object removeObserver:self forKeyPath:@"isFinished"];
    }
}

- (void)cancel
{
    [self.objectRequestOperation cancel];
}

@end
