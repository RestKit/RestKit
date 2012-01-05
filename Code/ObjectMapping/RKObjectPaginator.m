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

+ (id)paginatorWithBaseURL:(NSURL *)baseURL resourcePathPattern:(NSString *)resourcePathPattern mappingProvider:(RKObjectMappingProvider *)mappingProvider {
    return [[self alloc] initWithBaseURL:baseURL resourcePathPattern:resourcePathPattern mappingProvider:mappingProvider];
}

- (id)initWithBaseURL:(NSURL *)aBaseURL resourcePathPattern:(NSString *)aResourcePathPattern mappingProvider:(RKObjectMappingProvider *)aMappingProvider {
    self = [super init];
    if (self) {
        baseURL = [aBaseURL copy];
        resourcePathPattern = [aResourcePathPattern copy];
        mappingProvider = [aMappingProvider retain];
        currentPage = 0;
        perPage = RKObjectPaginatorDefaultPerPage;
        loaded = NO;
        requestMethod = RKRequestMethodGET;
    }
    
    return self;
}

- (void)dealloc {
    [baseURL release];
    [mappingProvider release];
    [objectStore release];
    [objectLoader release];
    
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
    
    NSLog(@"Loaded objects: %@", objects); // TODO: RKLog
    [self.delegate paginator:self didLoadObjects:objects forPage:self.currentPage];
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
    // Propogate the error to the delegate
    self.objectLoader = nil;
    
    NSLog(@"Failed with error: %@", error); // TODO: RKLog...
    [self.delegate paginator:self didFailWithError:error];
}

- (void)objectLoader:(RKObjectLoader *)loader willMapData:(inout id *)mappableData {
    NSError *error = nil;
    RKObjectMappingOperation *mappingOperation = [RKObjectMappingOperation mappingOperationFromObject:*mappableData toObject:self withMapping:[self paginationMapping]];
    [mappingOperation performMapping:&error];
}

- (BOOL)hasNextPage {
    NSAssert(self.isLoaded, @"Cannot determine hasNextPage: paginator is not loaded.");
    if (self.pageCount) {
        return self.currentPage < self.pageCount;
    } else if (self.objectCount && self.perPage) {
        return self.currentPage < (self.objectCount / perPage);
    }
    
    return YES;
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
    
    self.objectLoader = [[RKManagedObjectLoader alloc] initWithURL:self.paginationURL];
    self.objectLoader.method = self.requestMethod;
    self.objectLoader.mappingProvider = self.mappingProvider;
    self.objectLoader.objectStore = self.objectStore;
    self.objectLoader.delegate = self;
    [self.objectLoader release];
    [self.objectLoader send];
}

@end
