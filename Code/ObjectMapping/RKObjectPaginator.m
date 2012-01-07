//
//  RKObjectPaginator.m
//  RestKit
//
//  Created by Blake Watters on 12/29/11.
//  Copyright (c) 2011 RestKit. All rights reserved.
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
#import "RKObjectMappingOperation.h"
#import "SOCKit.h"
#import "RKLog.h"

// We may want to expose these via class accessors...
static NSUInteger RKObjectPaginatorDefaultPerPage = 25;

// Private interface
@interface RKObjectPaginator () <RKObjectLoaderDelegate>

@property (nonatomic, retain) RKManagedObjectLoader *objectLoader;

@end

@implementation RKObjectPaginator

@synthesize baseURL;
@synthesize requestMethod;
@synthesize resourcePathPattern;
@synthesize currentPage;
@synthesize perPage;
@synthesize loaded;
@synthesize pageCount;
@synthesize objectCount;
@synthesize mappingProvider;
@synthesize delegate;
@synthesize objectStore;
@synthesize objectLoader;
@synthesize customObjectLoaderSetup;

+ (id)paginatorWithBaseURL:(NSURL *)baseURL resourcePathPattern:(NSString *)resourcePathPattern mappingProvider:(RKObjectMappingProvider *)mappingProvider customObjectLoaderSetup:(void (^)(RKObjectLoader *))customObjectLoaderSetup {
    return [[[self alloc] initWithBaseURL:baseURL resourcePathPattern:resourcePathPattern mappingProvider:mappingProvider customObjectLoaderSetup:customObjectLoaderSetup] autorelease];
}

+ (id)paginatorWithBaseURL:(NSURL *)baseURL resourcePathPattern:(NSString *)resourcePathPattern mappingProvider:(RKObjectMappingProvider *)mappingProvider {
    return [[[self alloc] initWithBaseURL:baseURL resourcePathPattern:resourcePathPattern mappingProvider:mappingProvider] autorelease];
}

- (id)initWithBaseURL:(NSURL *)aBaseURL resourcePathPattern:(NSString *)aResourcePathPattern mappingProvider:(RKObjectMappingProvider *)aMappingProvider
{
  return [self initWithBaseURL:aBaseURL resourcePathPattern:aResourcePathPattern mappingProvider:aMappingProvider customObjectLoaderSetup:^(RKObjectLoader* loader) {}];
}

- (id)initWithBaseURL:(NSURL *)aBaseURL resourcePathPattern:(NSString *)aResourcePathPattern mappingProvider:(RKObjectMappingProvider *)aMappingProvider customObjectLoaderSetup:(void (^)(RKObjectLoader *))aCustomObjectLoaderSetup {
    self = [super init];
    if (self) {
        baseURL = [aBaseURL copy];
        resourcePathPattern = [aResourcePathPattern copy];
        mappingProvider = [aMappingProvider retain];
        currentPage = 0;
        perPage = RKObjectPaginatorDefaultPerPage;
        loaded = NO;
        requestMethod = RKRequestMethodGET;
        customObjectLoaderSetup = Block_copy(aCustomObjectLoaderSetup);
    }
    
    return self;
}

- (void)dealloc {
    objectLoader.delegate = nil;
    [baseURL release];
    [mappingProvider release];
    [objectStore release];
    [objectLoader release];
    [customObjectLoaderSetup release];
    
    [super dealloc];
}

- (RKObjectMapping *)paginationMapping {
    return [mappingProvider paginationMapping];
}

- (NSString *)paginationResourcePath {
    SOCPattern *pattern = [SOCPattern patternWithString:resourcePathPattern];
    return [pattern stringFromObject:self];
}

- (NSURL *)paginationURL {
    return [NSURL URLWithString:[[baseURL absoluteString] stringByAppendingString:[self paginationResourcePath]]];
}

#pragma mark - RKObjectLoaderDelegate methods

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects {
    // Propogate the load to the delegate
    self.objectLoader = nil;
    loaded = YES;
    RKLogInfo(@"Loaded objects: %@", objects);
    [self.delegate paginator:self didLoadObjects:objects forPage:self.currentPage];
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
  // Propogate the error to the delegate
  RKLogError(@"Paginator error %@", error);
  [self.delegate paginator:self objectLoader:self.objectLoader didFailWithError:error];
  self.objectLoader = nil;
}

- (void)objectLoader:(RKObjectLoader *)loader willMapData:(inout id *)mappableData {
    NSError *error = nil;
    RKObjectMappingOperation *mappingOperation = [RKObjectMappingOperation mappingOperationFromObject:*mappableData toObject:self withMapping:[self paginationMapping]];
    BOOL success = [mappingOperation performMapping:&error];
    if (!success)
    {
      pageCount = currentPage = 0;
      RKLogError(@"Paginator didn't map info to compute page count.  Assuming no pages.");
    }
    else if (self.perPage)
    {
      float objectCountFloat = self.objectCount;
      pageCount = ceilf( objectCountFloat / self.perPage);
      RKLogInfo(@"Paginator objectCount: %d pageCount: %d", self.objectCount, self.pageCount); 
    }
    else 
    {
      NSAssert(NO, @"Paginator perPage set is 0.");
      RKLogError(@"Paginator perPage set is 0.");
    }
}

- (BOOL)hasNextPage {
    NSAssert(self.isLoaded, @"Cannot determine hasNextPage: paginator is not loaded.");

    return self.currentPage < self.pageCount;
}

- (BOOL)hasPreviousPage {
    NSAssert(self.isLoaded, @"Cannot determine hasPreviousPage: paginator is not loaded.");
    return self.currentPage > 0;
}

#pragma mark - Action methods

- (void)loadNextPage {
    [self loadPage:currentPage + 1];
}

- (void)loadPreviousPage {
    [self loadPage:currentPage - 1];
}

- (void)loadPage:(NSUInteger)pageNumber {
    NSAssert(self.mappingProvider, @"Cannot perform a load with a nil mappingProvider.");
    NSAssert(! objectLoader, @"Cannot perform a load while one is already in progress.");
    currentPage = pageNumber;
    
    self.objectLoader = [[[RKManagedObjectLoader alloc] initWithURL:self.paginationURL mappingProvider:self.mappingProvider objectStore:self.objectStore] autorelease];
  
    self.customObjectLoaderSetup(self.objectLoader);
    self.objectLoader.method = self.requestMethod;
    self.objectLoader.delegate = self;
    [self.objectLoader send];
}

@end
