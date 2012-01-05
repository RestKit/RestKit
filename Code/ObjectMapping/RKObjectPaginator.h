//
//  RKObjectPaginator.h
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

#import "RKObjectMappingProvider.h"
#import "RKManagedObjectStore.h"
#import "RKObjectLoader.h"

@protocol RKObjectPaginatorDelegate;

/**
 A pagination component capable of paging through a RESTful collection
 of JSON/XML objects returned via a web service.
 
 The paginator is configured to retrieve 
 */
@interface RKObjectPaginator : NSObject

+ (id)paginatorWithBaseURL:(NSURL *)baseURL resourcePathPattern:(NSString *)resourcePathPattern mappingProvider:(RKObjectMappingProvider *)mappingProvider;
- (id)initWithBaseURL:(NSURL *)baseURL resourcePathPattern:(NSString *)resourcePathPattern mappingProvider:(RKObjectMappingProvider *)mappingProvider;

/**
 The base URL to build the complete pagination URL from
 */
@property (nonatomic, copy) NSURL *baseURL;

/**
 A SOCKit pattern for building the resource path to load
 pages of data. The pattern will be evaluated against the paginator
 object itself.
 
 For examples, imagine that we are paginating a collection of data from
 an /articles resource path. Our pattern may look like:
 
 /articles?per_page=:perPage&page_number=:currentPage
 
 When the pattern is evaluated against the state of the paginator, this will
 yield a complete resource path that can be used to load the specified page. Given
 a paginator configured with 100 objects per page and a current page number of 3,
 our resource path would look like:
 
 /articles?per_page=100&page_number=3
 */
@property (nonatomic, copy) NSString *resourcePathPattern;

@property (nonatomic, readonly) NSString *paginationResourcePath;
@property (nonatomic, readonly) NSURL *paginationURL;

/**
 The HTTP method to use when loading the collection.
 
 **Default**: RKRequestMethodGET
 */
@property (nonatomic, assign) RKRequestMethod requestMethod;

/**
 Delegate to call back with pagination results
 */
@property (nonatomic, assign) id<RKObjectPaginatorDelegate> delegate;

/** @name Object Mapping Configuration */

@property (nonatomic, retain) RKManagedObjectStore *objectStore;
@property (nonatomic, retain) RKObjectMappingProvider *mappingProvider;

/** @name Pagination Metadata */

/// The number of objects to load per page
@property (nonatomic, assign) NSUInteger perPage;

/// The number of pages in the total collection
@property (nonatomic, readonly) NSUInteger pageCount;

/// The total number of objects in the collection
@property (nonatomic, readonly) NSUInteger objectCount;

/// The current page number the paginator has loaded
@property (nonatomic, readonly) NSUInteger currentPage;

@property (nonatomic, readonly, getter = isLoaded) BOOL loaded;

/// Returns YES when there is a next page to load
- (BOOL)hasNextPage;

/// Returns YES when there is a previous page to load
- (BOOL)hasPreviousPage;

/** @name Paginator Actions */

/**
 Loads the next page of data by incrementing the current page, constructing an object
 loader to fetch the data, and object mapping the results.
 */
- (void)loadNextPage;

/**
 Loads the previous page of data by decrementing the current page, constructing an object
 loader to fetch the data, and object mapping the results.
 */
- (void)loadPreviousPage;

/**
 Loads a specific page of data by mutating the current page, constructing an object
 loader to fetch the data, and object mapping the results.
 */
- (void)loadPage:(NSUInteger)pageNumber;

@end

/**
 The RKObjectPaginatorDelegate formal protocol defines
 RKObjectPaginator delegate methods that can be implemented by
 objects to receive informational callbacks about paginated loading
 of mapping objects through RestKit.
 */
@protocol RKObjectPaginatorDelegate <NSObject>

/**
 Sent to the delegate when the paginator has loaded a collection of objects for a given page
 */
- (void)paginator:(RKObjectPaginator *)paginator didLoadObjects:(NSArray *)objects forPage:(NSUInteger)page;

/**
 Sent to the delegate when the paginator has failed loading due to an error
 
 @param paginator The paginator that failed loading due to an error
 @param error An NSError indicating the cause of the failure
 */
- (void)paginator:(RKObjectPaginator *)paginator didFailWithError:(NSError *)error;

@optional

/**
 Sent to the delegate before the paginator begins loading a page
 
 @param paginator The paginator performing the load
 @param page The numeric page number being loaded
 */
- (void)paginator:(RKObjectPaginator *)paginator willLoadPage:(NSUInteger)page;

/**
 Sent to the delegate when the paginator has loaded the last page in the collection
 
 @param paginator The paginator instance that has loaded the last page
 */
- (void)paginatorDidLoadLastPage:(RKObjectPaginator *)paginator;

/**
 Sent to the delegate when the paginator has loaded the first page in the collection
 
 @param paginator The paginator instance that has loaded the first page
 */
- (void)paginatorDidLoadFirstPage:(RKObjectPaginator *)paginator;

@end
