//
//  RKPaginator.h
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

#import "RKHTTPRequestOperation.h"
#import "RKManagedObjectCaching.h"
#import "RKObjectMapping.h"
#import "RKMappingResult.h"

/**
 Instances of RKPaginator retrieve paginated collections of mappable data
 from remote systems via HTTP. Paginators perform GET requests and use a patterned
 URL to construct a full URL reflecting the state of the paginator. Paginators rely
 on an instance of RKObjectMappingProvider to determine how to perform object mapping
 on the retrieved data. Paginators can load Core Data backed models provided that an
 instance of RKManagedObjectStore is assigned to the paginator.
 */
@interface RKPaginator : NSObject

/**
 Initializes a RKPaginator object with the a provided patternURL and mappingProvider.

 @param request A request with a URL containing a dynamic pattern specifying how paginated resources are to be acessed.
 @param paginationMapping The pagination mapping specifying how pagination metadata is to be mapped from responses.
 @param responseDescriptors An array of response descriptors describing how to map object representations loaded by object request operations dispatched by the paginator.
 @return The receiver, initialized with the request, pagination mapping, and response descriptors.
 */
- (id)initWithRequest:(NSURLRequest *)request
    paginationMapping:(RKObjectMapping *)paginationMapping
  responseDescriptors:(NSArray *)responseDescriptors;

/**
 A URL with a path pattern for building a complete URL from
 which to load the paginated resource collection. The patterned resource
 path will be evaluated against the state of the paginator object itself.

 For example, given a paginated collection of data at the /articles path,
 the path portion of the pattern URL may look like:

 /articles?per_page=:perPage&page_number=:currentPage

 When the pattern is evaluated against the state of the paginator, this will
 yield a complete path that can be used to load the specified page. Given
 a paginator configured with 100 objects per page and a current page number of 3,
 the path portion of the pagination URL would become:

 /articles?per_page=100&page_number=3
 */
@property (nonatomic, readonly) NSURL *patternURL;

/**
 Returns a complete URL to the paginated resource collection by interpolating the state of the paginator object against the patternURL.
 */
@property (nonatomic, readonly) NSURL *URL;

/**
 An optional operation queue on which object request operations constructed by the paginator are to be enqueued for processing.
 */
@property (nonatomic, strong) NSOperationQueue *operationQueue;

///-----------------------------------
/// @name Setting the Completion Block
///-----------------------------------

/**
 Sets the completion block to be invoked when the paginator finishes loading a page of results.
 
 @param success A block to be executed upon a successful load of a page of objects. The block has no return value and takes three arguments: the paginator object, an array containing the paginated objects, and an integer indicating the page that was loaded.
 @param failure A block to be exected upon a failed load. The block has no return value and takes two arguments: the paginator object and an error indicating the nature of the failure.
 */
- (void)setCompletionBlockWithSuccess:(void (^)(RKPaginator *paginator, NSArray *objects, NSUInteger page))success
                              failure:(void (^)(RKPaginator *paginator, NSError *error))failure;


///-----------------------------------
/// @name Accessing Pagination Results
///-----------------------------------

/**
 The mapping result containing the last set of paginated objects or `nil` if an error was encountered.
 */
@property (nonatomic, strong, readonly) RKMappingResult *mappingResult;

/**
 The error, if any, that occured during the last load of the paginator.
 */
@property (nonatomic, strong, readonly) NSError *error;

///-----------------------------------
/// @name Object Mapping Configuration
///-----------------------------------

/**
 The object mapping defining how pagination metadata is to be mapped from a paginated response onto the paginator object.
 
 @warning The `objectClass` of the given mapping must be `RKPaginator`.
 */
@property (nonatomic, strong) RKObjectMapping *paginationMapping;

///------------------------------
/// @name Core Data Configuration
///------------------------------

/**
 The managed object context in which paginated managed objects are to be persisted.
 */
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

/**
 The managed object cache used to find existing managed object instances in the persistent store.
 */
@property (nonatomic, strong) id<RKManagedObjectCaching> managedObjectCache;

/**
 An array of fetch request blocks.
 */
@property (nonatomic, copy) NSArray *fetchRequestBlocks;

///------------------------------------
/// @name Accessing Pagination Metadata
///------------------------------------
 
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
 @exception NSInternalInconsistencyException Raised if `isLoaded` is equal to `NO`.
 */
@property (nonatomic, readonly) NSUInteger currentPage;

/**
 Returns the number of pages in the total resource collection.

 @return A count of the number of pages in the resource collection.
 @exception NSInternalInconsistencyException Raised if hasPageCount is `NO`.
 */
@property (nonatomic, readonly) NSUInteger pageCount;

/**
 Returns the total number of objects in the collection

 @return A count of the number of objects in the resource collection.
 @exception NSInternalInconsistencyException Raised if hasObjectCount is `NO`.
 */
@property (nonatomic, readonly) NSUInteger objectCount;

/**
 Returns a Boolean value indicating if the total number of pages in the collection is known by the paginator.

 @return `YES` if the paginator knows the page count, otherwise `NO`.
 */
- (BOOL)hasPageCount;

/**
 Returns a Boolean value indicating if the total number of objects in the collection is known by the paginator.

 @return `YES` if the paginator knows the number of objects in the paginated collection, otherwise `NO`.
 */
- (BOOL)hasObjectCount;

/**
 Returns a Boolean value indicating if there is a next page in the collection.

 @return `YES` if there is a next page, otherwise `NO`.
 @exception NSInternalInconsistencyException Raised if isLoaded or hasPageCount is `NO`.
 */
- (BOOL)hasNextPage;

/**
 Returns a Boolean value indicating if there is a previous page in the collection.

 @return `YES` if there is a previous page, otherwise `NO`.
 @exception NSInternalInconsistencyException Raised if isLoaded is `NO`.
 */
- (BOOL)hasPreviousPage;

///------------------------
/// @name Paginator Actions
///------------------------

/**
 Loads the next page of data by incrementing the current page, constructing an object loader to fetch the data, and object mapping the results.
 */
- (void)loadNextPage;

/**
 Loads the previous page of data by decrementing the current page, constructing an object loader to fetch the data, and object mapping the results.
 */
- (void)loadPreviousPage;

/**
 Loads a specific page of data by mutating the current page, constructing an object loader to fetch the data, and object mapping the results.

 @param pageNumber The page of objects to load from the remote backend
 */
- (void)loadPage:(NSUInteger)pageNumber;

/**
 Cancels an in-progress pagination request.
 */
- (void)cancel;

@end
