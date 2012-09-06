//
//  RKObjectManager.h
//  RestKit
//
//  Created by Jeremy Ellison on 8/14/09.
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

#import <RestKit/Network.h>
#import "RKRouter.h"
#import "RKObjectPaginator.h"
#import "RKMacros.h"
#import "AFNetworking.h"
#import "RKManagedObjectRequestOperation.h"

@protocol RKSerialization;
@class RKManagedObjectStore, RKObjectRequestOperation, RKManagedObjectRequestOperation,
RKMappingResult, RKRequestDescriptor, RKResponseDescriptor;

/**
 The `RKObjectManager` class provides a centralized interface for performing object mapping
 based HTTP request and response operations. It encapsulates common configuration such as
 request/response descriptors and routing, provides for the creation of NSURLRequest and RKObjectRequestOperation objects,
 and one-line methods to enqueue object request operations for the basic HTTP request methods (GET, POST, PUT, DELETE, etc).
 
 ## Request and Response Descriptors
 
 ## Routing
 
 ## Core Data
 */
@interface RKObjectManager : NSObject

///----------------------------------------------
/// @name Configuring the Shared Manager Instance
///----------------------------------------------

/**
 Return the shared instance of the object manager
 */
+ (RKObjectManager *)sharedManager;

/**
 Set the shared instance of the object manager
 */
+ (void)setSharedManager:(RKObjectManager *)manager;

///-------------------------------------
/// @name Initializing an Object Manager
///-------------------------------------
/**
 Create and initialize a new object manager. If this is the first instance created
 it will be set as the shared instance
 */
+ (id)managerWithBaseURL:(NSURL *)baseURL;

/**
 Initializes the receiver with a given AFNetworking HTTP client.
 
 This is the designated initializer.

 @param client The AFNetworking HTTP client with which to initialize the receiver.
 @return The receiver, initialized with the given client.
 */
- (id)initWithClient:(AFHTTPClient *)client;

///------------------------------------------
/// @name Accessing Object Manager Properties
///------------------------------------------

/**
 The AFNetworking HTTP client with which the receiver makes requests.
 */
@property (nonatomic, strong, readonly) AFHTTPClient *HTTPClient;

/**
 The operation queue which manages operations enqueued by the object manager.
 */
@property (nonatomic, strong) NSOperationQueue *operationQueue;

/**
 The router used to generate URL objects for routable requests created by the manager.
 
 @see RKRouter
 @see RKRoute
 */
@property (nonatomic, strong) RKRouter *router;

/**
 The Default MIME Type to be used in object serialization.
 */
@property (nonatomic, strong) NSString *serializationMIMEType;

/**
 The value for the HTTP Accept header to specify the preferred format for retrieved data
 */
@property (nonatomic, weak) NSString *acceptMIMEType;

///-------------------------------
/// @name Creating Request Objects
///-------------------------------

/**
 Creates and returns an `NSMutableURLRequest` object with a given object, method, path, and parameters.
 */
- (NSMutableURLRequest *)requestWithObject:(id)object
                                    method:(RKRequestMethod)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters;

/**
 Creates and returns an `NSMutableURLRequest` object with a given object, method, path, and parameters. The body
 of the request is built using the given block.
 */
- (NSMutableURLRequest *)multipartFormRequestWithObject:(id)object
                                                method:(RKRequestMethod)method
                                                  path:(NSString *)path
                                            parameters:(NSDictionary *)parameters
                             constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block;

/**
 Creates an `NSMutableURLRequest` object with the `NSURL` returned by the router for the given route
 name and object and the given parameters.
 */
- (NSMutableURLRequest *)requestForRouteNamed:(NSString *)routeName
                                       object:(id)object
                                   parameters:(NSDictionary *)parameters;   // TODO: requestWithURLForRouteNamed:??

///-----------------------------------------
/// @name Creating Object Request Operations
///-----------------------------------------

/**
 Creates an `RKObjectRequestOperation` operation with the given request and sets the completion block with the given
 success and failure blocks.
 
 @warning Instances of `RKObjectRequestOperation` are not capable of mapping the loaded `NSHTTPURLResponse` into a
 Core Data entity. Use an instance of `RKManagedObjectRequestOperation` if the response is to be mapped using an 
 `RKEntityMapping`.
 */
- (RKObjectRequestOperation *)objectRequestOperationWithRequest:(NSURLRequest *)request
                                                        success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
                                                        failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

/**
 Creates an `RKManagedObjectRequestOperation` operation with the given request and managed object context, and sets 
 the completion block with the given success and failure blocks.
 
 The given managed object context given will be used as the parent context of the private managed context in which the response
 is mapped and will be used to fetch the results upon invocation of the success completion block.
 
 @see RKManagedObjectRequestOperation
 */
- (RKManagedObjectRequestOperation *)managedObjectRequestOperationWithRequest:(NSURLRequest *)request
                                                         managedObjectContext:(NSManagedObjectContext *)managedObjectContext
                                                                      success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
                                                                      failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

/**
 Creates and returns an object request operation for the given object, request method, path, and parameters.
 
 The type of object request operation created is determined by evaluating the type of the object given and examining
 the list of `RKResponseDescriptor` objects added to the manager. If the given object inherits from `NSManagedObject`
 or the list of response descriptors matching the URL of the request created contains an `RKEntityMapping` object, then
 an `RKManagedObjectRequestOperation` is returned; otherwise an `RKObjectRequestOperation` is returned.
 
 @warning The given object must be a single object instance. Collections are not yet supported.
 */
- (id)objectRequestOperationWithObject:(id)object method:(RKRequestMethod)method path:(NSString *)path parameters:(NSDictionary *)parameters;

///--------------------------------------------------
/// @name Managing Enqueued Object Request Operations
///--------------------------------------------------

/**
 Enqueues an `RKObjectRequestOperation` to the object manager's operation queue.
 
 @param objectRequestOperation The object request operation to be enqueued.
 */
- (void)enqueueObjectRequestOperation:(RKObjectRequestOperation *)objectRequestOperation;
// TODO: Need a cancel...

///-----------------------------
/// @name Making Object Requests
///-----------------------------

/**
 Creates an `RKObjectRequestOperation` with a `GET` request with a URL for the given path, and enqueues it to the manager's operation queue.
 */
- (void)getObjectsAtPath:(NSString *)path
              parameters:(NSDictionary *)parameters
                 success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
                 failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

/**
 Creates an `RKObjectRequestOperation` with a `GET` request for the given object, and enqueues it to the manager's operation queue.
 */
- (void)getObject:(id)object
             path:(NSString *)path
       parameters:(NSDictionary *)parameters
          success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
          failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

/**
 Creates an `RKObjectRequestOperation` with a `POST` request for the given object, and enqueues it to the manager's operation queue.
 */
- (void)postObject:(id)object
              path:(NSString *)path
        parameters:(NSDictionary *)parameters
           success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
           failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

/**
 Creates an `RKObjectRequestOperation` with a `PUT` request for the given object, and enqueues it to the manager's operation queue.
 */
- (void)putObject:(id)object
             path:(NSString *)path
       parameters:(NSDictionary *)parameters
          success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
          failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

/**
 Creates an `RKObjectRequestOperation` with a `PATCH` request for the given object, and enqueues it to the manager's operation queue.
 */
- (void)patchObject:(id)object
               path:(NSString *)path
         parameters:(NSDictionary *)parameters
            success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
            failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

/**
 Creates an `RKObjectRequestOperation` with a `DELETE` request for the given object, and enqueues it to the manager's operation queue.
 */
- (void)deleteObject:(id)object
                path:(NSString *)path
          parameters:(NSDictionary *)parameters
             success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
             failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

/**
 Creates an `RKObjectRequestOperation` with a `GET` request for the relationship with the given name of the given object, 
 and enqueues it to the manager's operation queue.
 */
- (void)getRelationship:(NSString *)relationshipName
               ofObject:(id)object
             parameters:(NSDictionary *)parameters
                success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
                failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

/**
 Creates an `RKObjectRequestOperation` with a `GET` request for the URL returned by the router for the given route name, 
 and enqueues it to the manager's operation queue.
 */
- (void)getObjectsAtRouteNamed:(NSString *)routeName
                        object:(id)object
                    parameters:(NSDictionary *)parameters
                       success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
                       failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

///------------------------------------------------
/// @name Managing Request and Response Descriptors
///------------------------------------------------

/**
 Returns an array containing the `RKRequestDescriptor` objects added to the manager.
 
 The request descriptors describe how `NSURLRequest` objects constructed by the manager will be built
 by specifying how the attributes and relationships for a given class will be object mapped to construct
 request parameters and what, if any, root key path the parameters will be nested under.
 
 @return An array containing the request descriptors of the receiver. The elements of the array
 are instances of `RKRequestDescriptor`.
 
 @see RKRequestDescriptor
 */
@property (nonatomic, readonly) NSArray *requestDescriptors;

/**
 Adds a request descriptor to the manager.
 
 @param requestDescriptor The request descriptor object to the be added to the manager.
 */
- (void)addRequestDescriptor:(RKRequestDescriptor *)requestDescriptor;

/**
 Adds the `RKRequestDescriptor` objects contained in a given array to the manager.
 
 @param requestDescriptors An array of `RKRequestDescriptor` objects to be added to the manager. 
 @exception NSInvalidArgumentException Raised if any element of the given array is not an `RKRequestDescriptor` object.
 */
- (void)addRequestDescriptorsFromArray:(NSArray *)requestDescriptors;

/**
 Removes a given request descriptor from the manager.
 
 @param requestDescriptor An `RKRequestDescriptor` object to be removed from the manager.
 */
- (void)removeRequestDescriptor:(RKRequestDescriptor *)requestDescriptor;

/**
 Returns an array containing the `RKResponseDescriptor` objects added to the manager.
 
 The response descriptors describe how `NSHTTPURLResponse` objects loaded by object request operations
 sent by the manager are to be object mapped into local domain objects. Response descriptors are matched
 against a given response via URL path matching, parsed content key path matching, or both. The `RKMapping`
 object associated from a matched `RKResponseDescriptor` is given to an instance of `RKObjectMapper` with the
 parsed response body to perform object mapping on the response.
 
 @return An array containing the request descriptors of the receiver. The elements of the array
 are instances of `RKRequestDescriptor`.
 
 @see RKResponseDescriptor
 */
@property (nonatomic, readonly) NSArray *responseDescriptors;

/**
 Adds a response descriptor to the manager.
 
 @param responseDescriptor The response descriptor object to the be added to the manager.
 */
- (void)addResponseDescriptor:(RKResponseDescriptor *)responseDescriptor;

/**
 Adds the `RKResponseDescriptor` objects contained in a given array to the manager.
 
 @param responseDescriptors An array of `RKResponseDescriptor` objects to be added to the manager.
 @exception NSInvalidArgumentException Raised if any element of the given array is not an `RKResponseDescriptor` object.
 */
- (void)addResponseDescriptorsFromArray:(NSArray *)responseDescriptors;

/**
 Removes a given response descriptor from the manager.
 
 @param responseDescriptor An `RKResponseDescriptor` object to be removed from the manager.
 */
- (void)removeResponseDescriptor:(RKResponseDescriptor *)responseDescriptor;

///----------------------------------------
/// @name Configuring Core Data Integration
///----------------------------------------

// Moves to RKObjectManager+CoreData

/**
 A Core Data backed object store for persisting objects that have been fetched from the Web
 */
@property (nonatomic, strong) RKManagedObjectStore *managedObjectStore;

/**
 An array of `RKFetchRequestBlock` blocks used to map `NSURL` objects into corresponding `NSFetchRequest`
 objects.
 */
@property (nonatomic, readonly) NSArray *fetchRequestBlocks;

/**
 Adds the given `RKFetchRequestBlock` block to the manager.
 */
- (void)addFetchRequestBlock:(RKFetchRequestBlock)block;

///---------------------------------
/// @name Creating Paginator Objects
///---------------------------------

/**
 Creates and returns an RKObjectPaginator instance targeting the specified path pattern.
 
 The paginator instantiated will be initialized with a URL built by appending the pathPattern to the
 baseURL of the client.
 
 @return The newly created paginator instance.
 @see RKObjectPaginator
 */
//- (RKObjectPaginator *)paginatorWithPathPattern:(NSString *)pathPattern;

@end
