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

#import "RKNetwork.h"
#import "RKRouter.h"
#import "RKObjectPaginator.h"
#import "RKMacros.h"
#import "AFNetworking.h"
#import "RKManagedObjectRequestOperation.h"

@protocol RKParser;
@class RKManagedObjectStore, RKObjectRequestOperation, RKManagedObjectRequestOperation,
RKMappingResult, RKRequestDescriptor, RKResponseDescriptor;

/**
 The object manager is the primary interface for interacting with RESTful resources via HTTP. It is
 responsible for retrieving remote object representations via HTTP and transforming them into local
 domain objects via the RKObjectMapper. It is also capable of serializing local objects and sending them
 to a remote system for processing. The object manager strives to hide the developer from the details of
 configuring an RKRequest, processing an RKResponse, parsing any data returned by the remote system, and
 running the parsed data through the object mapper.

 <h3>Shared Manager Instance</h3>

 Multiple instances of RKObjectManager may be used in parallel, but the first instance initialized
 is automatically configured as the sharedManager instance. The shared instance can be changed at runtime
 if so desired. See sharedManager and setSharedManager for details.

 <h3>Configuring the Object Manager</h3>

 The object mapper must be configured before object can be loaded from or transmitted to your remote backend
 system. Configuration consists of specifying the desired MIME types to be used during loads and serialization,
 registering object mappings to use for mapping and serialization, registering routes, and optionally configuring
 an instance of the managed object store (for Core Data).

 <h4>MIME Types</h4>

 MIME Types are used for two purposes within RestKit:

 1. Content Negotiation. RestKit leverages the HTTP Accept header to specify the desired representation of content
 when contacting a remote web service. You can specify the MIME Type to use via the acceptMIMEType method. The default
 MIME Type is RKMIMETypeJSON (application/json). If the remote web service responds with content in a different MIME Type
 than specified, RestKit will attempt to parse it by consulting the [parser registry][RKParserRegistry parserForMIMEType:].
 Failure to find a parser for the returned content will result in an unexpected response invocation of
 [RKObjectLoaderDelegate objectLoaderDidLoadUnexpectedResponse].
 1. Serialization. RestKit can be used to transport local object representation back to the remote web server for processing
 by serializing them into an RKRequestSerializable representation. The desired serialization format is configured by setting
 the serializationMIMEType property. RestKit currently supports serialization to RKMIMETypeFormURLEncoded and RKMIMETypeJSON.
 The serialization rules themselves are expressed via an instance of RKObjectMapping.

 <h4>The Mapping Provider</h4>

 RestKit determines how to map and serialize objects by consulting the mappingProvider. The mapping provider is responsible
 for providing instances of RKObjectMapper with object mappings that should be used for transforming mappable data into object
 representations. When you ask the object manager to load or send objects for you, the mappingProvider instance will be used
 for the object mapping operations constructed for you. In this way, the mappingProvider is the central registry for the knowledge
 about how objects in your application are mapped.

 Mappings are registered by constructing instances of RKObjectMapping and registering them with the provider:
 `
    RKObjectManager *manager = [RKObjectManager managerWithBaseURL:myBaseURL];
    RKObjectMapping *articleMapping = [RKObjectMapping mappingForClass:[Article class]];
    [mapping mapAttributes:@"title", @"body", @"publishedAt", nil];
    [manager.mappingProvider setObjectMapping:articleMapping forKeyPath:@"article"];

    // Generate an inverse mapping for transforming Article -> NSMutableDictionary.
    [manager.mappingProvider setSerializationMapping:[articleMapping inverseMapping] forClass:[Article class]];`

 <h4>Configuring Routes</h4>

 Routing is the process of transforming objects and actions (as defined by HTTP verbs) into resource paths. RestKit ships

 <h4>Initializing a Core Data Object Store</h4>
 <h3>Loading Remote Objects</h3>

 <h3>Routing &amp; Object Serialization</h3>

 <h3>Default Error Mapping</h3>

 When an instance of RKObjectManager is configured, the RKObjectMappingProvider
 instance configured
 */
@interface RKObjectManager : NSObject

/// @name Configuring the Shared Manager Instance

/**
 Return the shared instance of the object manager
 */
+ (RKObjectManager *)sharedManager;

/**
 Set the shared instance of the object manager
 */
+ (void)setSharedManager:(RKObjectManager *)manager;

/** @name Object Mapping Dispatch Queue */

/**
 Returns the global default operation queue queue used for object mapping
 operations executed by RKObjectLoaders.

 All object loaders perform their loading within an operation queue.
 This provides control over the number of loaders that are performing
 expensive operations such as JSON parsing, object mapping, and accessing Core
 Data concurrently. The defaultMappingQueue is configured as the mappingQueue
 for all RKObjectManager's created by RestKit, but can be overridden on a per
 manager and per object loader basis.

 By default, the defaultMappingQueue is configured with a maximumConcurrentOperationCount
 of 1.
 */
+ (NSOperationQueue *)defaultMappingQueue;

/**
 Sets a new global default operation queue for use in object mapping
 operations executed by RKObjectLoaders.
 */
+ (void)setDefaultMappingQueue:(NSOperationQueue *)defaultMappingQueue;

/// @name Initializing an Object Manager

/**
 Create and initialize a new object manager. If this is the first instance created
 it will be set as the shared instance
 */
+ (id)managerWithBaseURL:(NSURL *)baseURL;

/**
 Initializes a newly created object manager with a specified baseURL.

 @param baseURL A baseURL to initialize the underlying client instance with
 @return The newly initialized RKObjectManager object
 */
- (id)initWithClient:(AFHTTPClient *)client; // Designated initializer
- (id)initWithBaseURL:(NSURL *)baseURL;

/// @name Network Integration

/**
 The base URL of the underlying RKClient instance. Object loader
 and paginator instances built through the object manager are
 relative to this URL.

 @see RKClient
 @return The baseURL of the client.
 */
@property (weak, nonatomic, readonly) RKURL *baseURL;

/// @name Configuring Object Mapping

/**
 Router object responsible for generating URLs for
 HTTP requests
 */
@property (nonatomic, strong) RKRouter *router;

/**
 A Core Data backed object store for persisting objects that have been fetched from the Web
 */
@property (nonatomic, strong) RKManagedObjectStore *managedObjectStore;

/**
 The operation queue to use when performing expensive object mapping operations
 within RKObjectLoader instances created through this object manager
 */
@property (nonatomic, strong) NSOperationQueue *mappingQueue;

/**
 The Default MIME Type to be used in object serialization.
 */
@property (nonatomic, strong) NSString *serializationMIMEType;

/**
 The value for the HTTP Accept header to specify the preferred format for retrieved data
 */
@property (nonatomic, weak) NSString *acceptMIMEType;

////////////////////////////////////////////////////////
/// @name Building Object Request Operations

/**
 Creates and returns an RKObjectPaginator instance targeting the specified resource path pattern.

 The paginator instantiated will be initialized with an RKURL built by appending the resourcePathPattern to the
 baseURL of the client.

 @return The newly created paginator instance.
 @see RKObjectMappingProvider
 @see RKObjectPaginator
 */
//- (RKObjectPaginator *)paginatorWithResourcePathPattern:(NSString *)resourcePathPattern;

////////////////////////////////////////////////////////
/// @name Registered Object Loaders

@property (nonatomic, strong) AFHTTPClient *HTTPClient;
@property (nonatomic, strong, readonly) NSOperationQueue *operationQueue;

/**
 New RestKit + AFNetworking Primitives
 */
- (NSMutableURLRequest *)requestWithObject:(id)object
                                    method:(RKRequestMethod)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters;

- (NSMutableURLRequest *)multipartFormRequestForObject:(id)object
                                                method:(RKRequestMethod)method
                                                  path:(NSString *)path
                                            parameters:(NSDictionary *)parameters
                             constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block;

- (NSMutableURLRequest *)requestForRouteNamed:(NSString *)routeName
                                       object:(id)object
                                   parameters:(NSDictionary *)parameters;

- (RKObjectRequestOperation *)objectRequestOperationWithRequest:(NSURLRequest *)request
                                                        success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
                                                        failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

- (RKManagedObjectRequestOperation *)managedObjectRequestOperationWithRequest:(NSURLRequest *)request
                                                         managedObjectContext:(NSManagedObjectContext *)managedObjectContext
                                                                      success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
                                                                      failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

// Returns an RKObjectRequestOperation or RKManagedObjectRequestOperation as appropriate for the given object
// object must be a single object
// TODO: Could use some guards against collections...
- (id)objectRequestOperationWithObject:(id)object method:(RKRequestMethod)method path:(NSString *)path parameters:(NSDictionary *)parameters;

- (void)getObjectsAtPath:(NSString *)path
              parameters:(NSDictionary *)parameters
                 success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
                 failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

- (void)getObject:(id)object
             path:(NSString *)path
       parameters:(NSDictionary *)parameters
          success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
          failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

- (void)postObject:(id)object
              path:(NSString *)path
        parameters:(NSDictionary *)parameters
           success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
           failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

- (void)putObject:(id)object
             path:(NSString *)path
       parameters:(NSDictionary *)parameters
          success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
          failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

- (void)patchObject:(id)object
               path:(NSString *)path
         parameters:(NSDictionary *)parameters
            success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
            failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

- (void)deleteObject:(id)object
                path:(NSString *)path
          parameters:(NSDictionary *)parameters
             success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
             failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

- (void)getRelationship:(NSString *)relationshipName
               ofObject:(id)object
             parameters:(NSDictionary *)parameters
                success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
                failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

- (void)getObjectsAtRouteNamed:(NSString *)routeName
                        object:(id)object
                    parameters:(NSDictionary *)parameters
                       success:(void (^)(RKObjectRequestOperation *operation, RKMappingResult *mappingResult))success
                       failure:(void (^)(RKObjectRequestOperation *operation, NSError *error))failure;

@property (nonatomic, readonly) NSArray *requestDescriptors;
- (void)addRequestDescriptor:(RKRequestDescriptor *)requestDescriptor;
- (void)addRequestDescriptorsFromArray:(NSArray *)requestDescriptors;
- (void)removeRequestDescriptor:(RKRequestDescriptor *)requestDescriptor;

/**
 An array of RKResponseDescriptor objects describing how to perform object mapping on
 HTTP responses loaded by requests sent via the receiver.
 */
@property (nonatomic, readonly) NSArray *responseDescriptors;
- (void)addResponseDescriptor:(RKResponseDescriptor *)responseDescriptor;
- (void)addResponseDescriptorsFromArray:(NSArray *)responseDescriptors;
- (void)removeResponseDescriptor:(RKResponseDescriptor *)responseDescriptor;

@property (nonatomic, readonly) NSArray *fetchRequestBlocks;
- (void)addFetchRequestBlock:(RKFetchRequestBlock)block;

@end
