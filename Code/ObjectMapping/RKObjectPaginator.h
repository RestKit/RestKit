//
//  RKObjectPaginator.h
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

#import "RKObjectMappingProvider.h"
#import "RKManagedObjectStore.h"
#import "RKObjectLoader.h"
#import "RKConfigurationDelegate.h"

@protocol RKObjectPaginatorDelegate;

typedef void(^RKObjectPaginatorDidLoadObjectsForPageBlock)(NSArray *objects, NSUInteger page);
typedef void(^RKObjectPaginatorDidFailWithErrorBlock)(NSError *error, RKObjectLoader *loader);

/**
 Instances of RKObjectPaginator retrieve paginated collections of mappable data
 from remote systems via HTTP. Paginators perform GET requests and use a patterned
 URL to construct a full URL reflecting the state of the paginator. Paginators rely
 on an instance of RKObjectMappingProvider to determine how to perform object mapping
 on the retrieved data. Paginators can load Core Data backed models provided that an
 instance of RKManagedObjectStore is assigned to the paginator.
 */
@interface RKObjectPaginator : NSObject

/**
 Creates and returns a RKObjectPaginator object with the a provided patternURL and mappingProvider.

 @param patternURL A RKURL containing a dynamic pattern for constructing a URL to the paginated
    resource collection.
 @param mappingProvider An RKObjectMappingProvider containing object mapping configurations for mapping the
    paginated resource collection.
 @see patternURL
 @return A paginator object initialized with patterned URL and mapping provider.
 */
+ (id)paginatorWithPatternURL:(RKURL *)patternURL mappingProvider:(RKObjectMappingProvider *)mappingProvider;

/**
 Initializes a RKObjectPaginator object with the a provided patternURL and mappingProvider.

 @param patternURL A RKURL containing a dynamic pattern for constructing a URL to the paginated
 resource collection.
 @param mappingProvider An RKObjectMappingProvider containing object mapping configurations for mapping the
 paginated resource collection.
 @see patternURL
 @return The receiver, initialized with patterned URL and mapping provider.
 */
- (id)initWithPatternURL:(RKURL *)patternURL mappingProvider:(RKObjectMappingProvider *)mappingProvider;

/**
 A RKURL with a resource path pattern for building a complete URL from
 which to load the paginated resource collection. The patterned resource
 path will be evaluated against the state of the paginator object itself.

 For example, given a paginated collection of data at the /articles resource path,
 the patterned resource path may look like:

 /articles?per_page=:perPage&page_number=:currentPage

 When the pattern is evaluated against the state of the paginator, this will
 yield a complete resource path that can be used to load the specified page. Given
 a paginator configured with 100 objects per page and a current page number of 3,
 the resource path of the pagination URL would become:

 /articles?per_page=100&page_number=3

 @see [RKURL URLByInterpolatingResourcePathWithObject:]
 */
@property (nonatomic, copy) RKURL *patternURL;

/**
 Returns a complete RKURL to the paginated resource collection by interpolating
 the state of the paginator object against the resource
 */
@property (nonatomic, readonly) RKURL *URL;

/**
 The object that acts as the delegate of the receiving paginator.
 */
@property (nonatomic, assign) id<RKObjectPaginatorDelegate> delegate;

/**
 The block to invoke when the paginator has loaded a page of objects from the collection.

 @see [RKObjectPaginatorDelegate paginator:didLoadObjects:forPage]
 */
@property (nonatomic, copy) RKObjectPaginatorDidLoadObjectsForPageBlock onDidLoadObjectsForPage;

/**
 The block to invoke when the paginator has failed loading due to an error.

 @see [RKObjectPaginatorDelegate paginator:didFailWithError:objectLoader:]
 */
@property (nonatomic, copy) RKObjectPaginatorDidFailWithErrorBlock onDidFailWithError;

/**
 The object that acts as the configuration delegate for RKObjectLoader instances built
 and utilized by the paginator.

 **Default**: nil
 @see RKClient
 @see RKObjectManager
 */
@property (nonatomic, assign) id<RKConfigurationDelegate> configurationDelegate;

/** @name Object Mapping Configuration */

/**
 The mapping provider to use when performing object mapping on the data
 loaded from the remote system. The provider will be assigned to the RKObjectLoader
 instance built to retrieve the paginated resource collection.
 */
@property (nonatomic, retain) RKObjectMappingProvider *mappingProvider;

/**
 An object store for accessing Core Data. Required if the objects being paginated
 are stored into Core Data.
 */
@property (nonatomic, retain) RKManagedObjectStore *objectStore;

/** @name Pagination Metadata */

/**
 The number of objects to load per page
 */
@property (nonatomic, assign) NSUInteger perPage;

/**
 A Boolean value indicating if the paginator has loaded a page of objects

 @returns YES when the paginator has loaded a page of objects
 */
@property (nonatomic, readonly, getter = isLoaded) BOOL loaded;

/**
 Returns the page number for the most recently loaded page of objects.

 @return The page number for the current page of objects.
 @exception NSInternalInconsistencyException Raised if isLoaded is NO.
 */
@property (nonatomic, readonly) NSUInteger currentPage;

/**
 Returns the number of pages in the total resource collection.

 @return A count of the number of pages in the resource collection.
 @exception NSInternalInconsistencyException Raised if hasPageCount is NO.
 */
@property (nonatomic, readonly) NSUInteger pageCount;

/**
 Returns the total number of objects in the collection

 @return A count of the number of objects in the resource collection.
 @exception NSInternalInconsistencyException Raised if hasObjectCount is NO.
 */
@property (nonatomic, readonly) NSUInteger objectCount;

/**
 Returns a Boolean value indicating if the total number of pages in the collection
 is known by the paginator.

 @return YES if the paginator knows the page count, otherwise NO
 */
- (BOOL)hasPageCount;

/**
 Returns a Boolean value indicating if the total number of objects in the collection
 is known by the paginator.

 @return YES if the paginator knows the number of objects in the paginated collection, otherwise NO.
 */
- (BOOL)hasObjectCount;

/**
 Returns a Boolean value indicating if there is a next page in the collection.

 @return YES if there is a next page, otherwise NO.
 @exception NSInternalInconsistencyException Raised if isLoaded or hasPageCount is NO.
 */
- (BOOL)hasNextPage;

/**
 Returns a Boolean value indicating if there is a previous page in the collection.

 @return YES if there is a previous page, otherwise NO.
 @exception NSInternalInconsistencyException Raised if isLoaded is NO.
 */
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

 @param pageNumber The page of objects to load from the remote backend
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
 Tells the delegate the paginator has loaded a page of objects from the collection.

 @param paginator The paginator that loaded the objects.
 @param objects An array of objects mapped from the remote JSON/XML representation.
 @param page The page number that was loaded.
 */
- (void)paginator:(RKObjectPaginator *)paginator didLoadObjects:(NSArray *)objects forPage:(NSUInteger)page;

/**
 Tells the delegate the paginator has failed loading due to an error.

 @param paginator The paginator that failed loading due to an error.
 @param error An NSError indicating the cause of the failure.
 @param loader The loader request that resulted in the failure.
 */
- (void)paginator:(RKObjectPaginator *)paginator didFailWithError:(NSError *)error objectLoader:(RKObjectLoader *)loader;

@optional

/**
 Tells the delegate that the paginator is about to begin loading a page of objects.

 @param paginator The paginator performing the load.
 @param page The numeric page number being loaded.
 @param loader The object loader request used to load the page.
 */
- (void)paginator:(RKObjectPaginator *)paginator willLoadPage:(NSUInteger)page objectLoader:(RKObjectLoader *)loader;

/**
 Tells the delegate the paginator has loaded the first page of objects in the collection.

 @param paginator The paginator instance that has loaded the first page.
 */
- (void)paginatorDidLoadFirstPage:(RKObjectPaginator *)paginator;

/**
 Tells the delegate the paginator has loaded the last page of objects in the collection.

 @param paginator The paginator instance that has loaded the last page.
 */
- (void)paginatorDidLoadLastPage:(RKObjectPaginator *)paginator;

@end
