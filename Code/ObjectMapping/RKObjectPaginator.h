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
#import "RKConfigurationDelegate.h"

@protocol RKObjectPaginatorDelegate;

/**
 A pagination component capable of paging through a RESTful collection
 of JSON/XML objects returned via a web service.
 */
@interface RKObjectPaginator : NSObject

// TODO: paginatorWithDynamicURL:mappingProvider:
+ (id)paginatorWithBaseURL:(RKURL *)baseURL resourcePathPattern:(NSString *)resourcePathPattern mappingProvider:(RKObjectMappingProvider *)mappingProvider;
- (id)initWithBaseURL:(RKURL *)baseURL resourcePathPattern:(NSString *)resourcePathPattern mappingProvider:(RKObjectMappingProvider *)mappingProvider;

/**
 The base URL to build the complete pagination URL from
 */
@property (nonatomic, copy) RKURL *baseURL;

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

/**
 Returns a complete resource path built by evaluating the resourcePathPattern
 against the state of the paginator object. This path will be appended to the
 baseURL when initializing an RKObjectLoader to fetch the paginated objects.
 */
@property (nonatomic, readonly) NSString *paginationResourcePath;

/**
 Returns a complete RKURL to the paginated resource collection by concatenating
 the baseURL and the paginationResourcePath.
 */
@property (nonatomic, readonly) RKURL *paginationURL;

/**
 Delegate to call back with pagination results
 */
@property (nonatomic, assign) id<RKObjectPaginatorDelegate> delegate;

/**
 A delegate responsible for configuring the request. Centralizes common configuration
 data (such as HTTP headers, authentication information, etc) for re-use.
 
 RKClient and RKObjectManager conform to the RKConfigurationDelegate protocol. Paginator
 instances built through these objects will have a reference to their
 parent client/object manager assigned as the configuration delegate.
 
 **Default**: nil
 @see RKClient
 @see RKObjectManager
 */
@property (nonatomic, assign) id<RKConfigurationDelegate> configurationDelegate;

/** @name Object Mapping Configuration */

/**
 The object mapping provider to use when performing object mapping on the data
 loaded from the remote system. The provider will be assigned to the RKObjectLoader
 instance built to retrieve the paginated data.
 */
@property (nonatomic, retain) RKObjectMappingProvider *mappingProvider;

/**
 An object store for accessing Core Data. Required if the objects being paginated
 are stored into Core Data.
 */
@property (nonatomic, retain) RKManagedObjectStore *objectStore;

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
 @param loader The loader request that resulted in the failure
 */
- (void)paginator:(RKObjectPaginator *)paginator didFailWithError:(NSError *)error objectLoader:(RKObjectLoader *)loader;

@optional

/**
 Sent to the delegate before the paginator begins loading a page
 
 @param paginator The paginator performing the load
 @param page The numeric page number being loaded
 @param loader The object loader request used to load the page
 */
- (void)paginator:(RKObjectPaginator *)paginator willLoadPage:(NSUInteger)page objectLoader:(RKObjectLoader *)loader;

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
