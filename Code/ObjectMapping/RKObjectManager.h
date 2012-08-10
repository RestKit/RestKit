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

#import "Network.h"
#import "RKObjectLoader.h"
#import "RKObjectRouter.h"
#import "RKObjectMappingProvider.h"
#import "RKConfigurationDelegate.h"
#import "RKObjectPaginator.h"

@protocol RKParser;

/** Notifications */

/**
 Posted when the object managed has transitioned to the offline state
 */
extern NSString * const RKObjectManagerDidBecomeOfflineNotification;

/**
 Posted when the object managed has transitioned to the online state
 */
extern NSString * const RKObjectManagerDidBecomeOnlineNotification;

typedef enum {
    RKObjectManagerNetworkStatusUnknown,
    RKObjectManagerNetworkStatusOffline,
    RKObjectManagerNetworkStatusOnline
} RKObjectManagerNetworkStatus;

@class RKManagedObjectStore;

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
@interface RKObjectManager : NSObject <RKConfigurationDelegate>

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
 Returns the global default Grand Central Dispatch queue used for object mapping
 operations executed by RKObjectLoaders.

 All object loaders perform their loading within a Grand Central Dispatch
 queue. This provides control over the number of loaders that are performing
 expensive operations such as JSON parsing, object mapping, and accessing Core
 Data concurrently. The defaultMappingQueue is configured as the mappingQueue
 for all RKObjectManager's created by RestKit, but can be overridden on a per
 manager and per object loader basis.

 By default, the defaultMappingQueue is configured as serial GCD queue.
 */
+ (dispatch_queue_t)defaultMappingQueue;

/**
 Sets a new global default Grand Central Dispatch queue for use in object mapping
 operations executed by RKObjectLoaders.
 */
+ (void)setDefaultMappingQueue:(dispatch_queue_t)defaultMappingQueue;

/// @name Initializing an Object Manager

/**
 Create and initialize a new object manager. If this is the first instance created
 it will be set as the shared instance
 */
+ (id)managerWithBaseURLString:(NSString *)baseURLString;
+ (id)managerWithBaseURL:(NSURL *)baseURL;

/**
 Initializes a newly created object manager with a specified baseURL.

 @param baseURL A baseURL to initialize the underlying client instance with
 @return The newly initialized RKObjectManager object
 */
- (id)initWithBaseURL:(RKURL *)baseURL;

/// @name Network Integration

/**
 The underlying HTTP client for this manager
 */
@property (nonatomic, retain) RKClient *client;

/**
 The base URL of the underlying RKClient instance. Object loader
 and paginator instances built through the object manager are
 relative to this URL.

 @see RKClient
 @return The baseURL of the client.
 */
@property (nonatomic, readonly) RKURL *baseURL;

/**
 The request cache used to store and load responses for requests sent
 through this object manager's underlying client object
 */
@property (nonatomic, readonly) RKRequestCache *requestCache;

/**
 The request queue used to dispatch asynchronous requests sent
 through this object manager's underlying client object
 */
@property (nonatomic, readonly) RKRequestQueue *requestQueue;

/**
  Returns the current network status for this object manager as determined
  by connectivity to the remote backend system
 */
@property (nonatomic, readonly) RKObjectManagerNetworkStatus networkStatus;

/**
 Returns YES when we are in online mode
 */
@property (nonatomic, readonly) BOOL isOnline;

/**
 Returns YES when we are in offline mode
 */
@property (nonatomic, readonly) BOOL isOffline;

/// @name Configuring Object Mapping

/**
 The Mapping Provider responsible for returning mappings for various keyPaths.
 */
@property (nonatomic, retain) RKObjectMappingProvider *mappingProvider;

/**
 Router object responsible for generating resource paths for
 HTTP requests
 */
@property (nonatomic, retain) RKObjectRouter *router;

/**
 A Core Data backed object store for persisting objects that have been fetched from the Web
 */
@property (nonatomic, retain) RKManagedObjectStore *objectStore;

/**
 The Grand Dispatch Queue to use when performing expensive object mapping operations
 within RKObjectLoader instances created through this object manager
 */
@property (nonatomic, assign) dispatch_queue_t mappingQueue;

/**
 The Default MIME Type to be used in object serialization.
 */
@property (nonatomic, retain) NSString *serializationMIMEType;

/**
 The value for the HTTP Accept header to specify the preferred format for retrieved data
 */
@property (nonatomic, assign) NSString *acceptMIMEType;

////////////////////////////////////////////////////////
/// @name Building Object Loaders

/**
 Returns the class of object loader instances built through the manager. When Core Data has
 been configured, instances of RKManagedObjectLoader will be emitted by the manager. Otherwise
 RKObjectLoader is used.

 @return RKObjectLoader OR RKManagedObjectLoader
 */
- (Class)objectLoaderClass;

/**
 Creates and returns an RKObjectLoader or RKManagedObjectLoader instance targeting the specified resourcePath.

 The object loader instantiated will be initialized with an RKURL built by appending the resourcePath to the baseURL of the client. The loader will then
 be configured with object mapping configuration from the manager and request configuration from the client.

 @param resourcePath A resource to use when building the URL to initialize the object loader instance.
 @return The newly created object loader instance.
 @see RKURL
 @see RKClient
 */
- (id)loaderWithResourcePath:(NSString *)resourcePath;

/**
 Creates and returns an RKObjectLoader or RKManagedObjectLoader instance targeting the specified URL.

 The object loader instantiated will be initialized with URL and will then
 be configured with object mapping configuration from the manager and request configuration from the client.

 @param URL The URL with which to initialize the object loader.
 @return The newly created object loader instance.
 @see RKURL
 @see RKClient
 */
- (id)loaderWithURL:(NSURL *)URL;

/**
 Creates and returns an RKObjectLoader or RKManagedObjectLoader instance for an object instance.

 The object loader instantiated will be initialized with a URL built by evaluating the object with the
 router to construct a resource path and then appending that resource path to the baseURL of the client.
 The loader will then be configured with object mapping configuration from the manager and request
 configuration from the client. The specified object will be the target of the object loader and will
 have any returned content mapped back onto the instance.

 @param object The object with which to initialize the object loader.
 @return The newly created object loader instance.
 @see RKObjectLoader
 @see RKObjectRouter
 */
- (id)loaderForObject:(id<NSObject>)object method:(RKRequestMethod)method;

/**
 Creates and returns an RKObjectPaginator instance targeting the specified resource path pattern.

 The paginator instantiated will be initialized with an RKURL built by appending the resourcePathPattern to the
 baseURL of the client.

 @return The newly created paginator instance.
 @see RKObjectMappingProvider
 @see RKObjectPaginator
 */
- (RKObjectPaginator *)paginatorWithResourcePathPattern:(NSString *)resourcePathPattern;

////////////////////////////////////////////////////////
/// @name Registered Object Loaders

/**
 These methods are suitable for loading remote payloads that encode type information into the payload. This enables
 the mapping of complex payloads spanning multiple types (i.e. a search operation returning Articles & Comments in
 one payload). Ruby on Rails JSON serialization is an example of such a conformant system.
 */

/**
 Create and send an asynchronous GET request to load the objects at the resource path and call back the delegate
 with the loaded objects. Remote objects will be mapped to local objects by consulting the keyPath registrations
 set on the mapping provider.
 */
- (void)loadObjectsAtResourcePath:(NSString *)resourcePath delegate:(id<RKObjectLoaderDelegate>)delegate;

////////////////////////////////////////////////////////
/// @name Mappable Object Loaders

/**
 Fetch the data for a mappable object by performing an HTTP GET.
 */
- (void)getObject:(id<NSObject>)object delegate:(id<RKObjectLoaderDelegate>)delegate;

/**
 Create a remote mappable model by POSTing the attributes to the remote resource and loading the resulting objects from the payload
 */
- (void)postObject:(id<NSObject>)object delegate:(id<RKObjectLoaderDelegate>)delegate;

/**
 Update a remote mappable model by PUTing the attributes to the remote resource and loading the resulting objects from the payload
 */
- (void)putObject:(id<NSObject>)object delegate:(id<RKObjectLoaderDelegate>)delegate;

/**
 Delete the remote instance of a mappable model by performing an HTTP DELETE on the remote resource
 */
- (void)deleteObject:(id<NSObject>)object delegate:(id<RKObjectLoaderDelegate>)delegate;

////////////////////////////////////////////////////////
/// @name Block Configured Object Loaders

#if NS_BLOCKS_AVAILABLE

/**
 Load the objects at the specified resource path and perform object mapping on the response payload. Prior to sending the object loader, the
 block will be invoked to allow you to configure the object loader as you see fit. This can be used to change the response type, set custom
 parameters, choose an object mapping, etc.

 For example:

    - (void)loadObjectUsingBlockExample {
        [[RKObjectManager sharedManager] loadObjectsAtResourcePath:@"/monkeys.json" usingBlock:^(RKObjectLoader *loader) {
            loader.objectMapping = [[RKObjectManager sharedManager].mappingProvider objectMappingForClass:[Monkey class]];
        }];
    }
 */
- (void)loadObjectsAtResourcePath:(NSString *)resourcePath usingBlock:(RKObjectLoaderBlock)block;

/*
 Configure and send an object loader after yielding it to a block for configuration. This allows for very succinct on-the-fly
 configuration of the request without obtaining an object reference via objectLoaderForObject: and then sending it yourself.

 For example:

    - (BOOL)changePassword:(NSString *)newPassword error:(NSError **)error {
        if ([self validatePassword:newPassword error:error]) {
            self.password = newPassword;
            [[RKObjectManager sharedManager] sendObject:self toResourcePath:@"/some/path" usingBlock:^(RKObjectLoader *loader) {
                loader.delegate = self;
                loader.method = RKRequestMethodPOST;
                loader.serializationMIMEType = RKMIMETypeJSON; // We want to send this request as JSON
                loader.targetObject = nil;  // Map the results back onto a new object instead of self
                // Set up a custom serialization mapping to handle this request
                loader.serializationMapping = [RKObjectMapping serializationMappingUsingBlock:^(RKObjectMapping *mapping) {
                    [mapping mapAttributes:@"password", nil];
                }];
            }];
        }
    }
 */
- (void)sendObject:(id<NSObject>)object toResourcePath:(NSString *)resourcePath usingBlock:(RKObjectLoaderBlock)block;

/**
 GET a remote object instance and yield the object loader to the block before sending

 @see sendObject:method:delegate:block
 */
- (void)getObject:(id<NSObject>)object usingBlock:(RKObjectLoaderBlock)block;

/**
 POST a remote object instance and yield the object loader to the block before sending

 @see sendObject:method:delegate:block
 */
- (void)postObject:(id<NSObject>)object usingBlock:(RKObjectLoaderBlock)block;

/**
 PUT a remote object instance and yield the object loader to the block before sending

 @see sendObject:method:delegate:block
 */
- (void)putObject:(id<NSObject>)object usingBlock:(RKObjectLoaderBlock)block;

/**
 DELETE a remote object instance and yield the object loader to the block before sending

 @see sendObject:method:delegate:block
 */
- (void)deleteObject:(id<NSObject>)object usingBlock:(RKObjectLoaderBlock)block;

#endif

//////


// Deprecations

+ (RKObjectManager *)objectManagerWithBaseURLString:(NSString *)baseURLString;
+ (RKObjectManager *)objectManagerWithBaseURL:(NSURL *)baseURL;
- (void)loadObjectsAtResourcePath:(NSString *)resourcePath objectMapping:(RKObjectMapping *)objectMapping delegate:(id<RKObjectLoaderDelegate>)delegate DEPRECATED_ATTRIBUTE;
- (RKObjectLoader *)objectLoaderWithResourcePath:(NSString *)resourcePath delegate:(id<RKObjectLoaderDelegate>)delegate DEPRECATED_ATTRIBUTE;
- (RKObjectLoader *)objectLoaderForObject:(id<NSObject>)object method:(RKRequestMethod)method delegate:(id<RKObjectLoaderDelegate>)delegate DEPRECATED_ATTRIBUTE;

/*
 NOTE:

 The mapResponseWith: family of methods have been deprecated by the support for object mapping selection
 using resourcePath's
 */
- (void)getObject:(id<NSObject>)object mapResponseWith:(RKObjectMapping *)objectMapping delegate:(id<RKObjectLoaderDelegate>)delegate DEPRECATED_ATTRIBUTE;
- (void)postObject:(id<NSObject>)object mapResponseWith:(RKObjectMapping *)objectMapping delegate:(id<RKObjectLoaderDelegate>)delegate DEPRECATED_ATTRIBUTE;
- (void)putObject:(id<NSObject>)object mapResponseWith:(RKObjectMapping *)objectMapping delegate:(id<RKObjectLoaderDelegate>)delegate DEPRECATED_ATTRIBUTE;
- (void)deleteObject:(id<NSObject>)object mapResponseWith:(RKObjectMapping *)objectMapping delegate:(id<RKObjectLoaderDelegate>)delegate DEPRECATED_ATTRIBUTE;

@end
