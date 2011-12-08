//
//  RKObjectManager.h
//  RestKit
//
//  Created by Jeremy Ellison on 8/14/09.
//  Copyright 2009 Two Toasters
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

@protocol RKParser;

// Notifications
extern NSString* const RKDidEnterOfflineModeNotification;
extern NSString* const RKDidEnterOnlineModeNotification;

typedef enum {
	RKObjectManagerOnlineStateUndetermined,
	RKObjectManagerOnlineStateDisconnected,
	RKObjectManagerOnlineStateConnected
} RKObjectManagerOnlineState;

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
    RKObjectManager* manager = [RKObjectManager managerWithBaseURL:myBaseURL];
    RKObjectMapping* articleMapping = [RKObjectMapping mappingForClass:[Article class]];
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
@interface RKObjectManager : NSObject {
	RKClient* _client;
	RKObjectRouter* _router;
	RKManagedObjectStore* _objectStore;	
	RKObjectManagerOnlineState _onlineState;
    RKObjectMappingProvider* _mappingProvider;
    NSString* _serializationMIMEType;
    BOOL _inferMappingsFromObjectTypes;
}

/// @name Configuring the Shared Manager Instance

/**
 Return the shared instance of the object manager
 */
+ (RKObjectManager*)sharedManager;

/**
 Set the shared instance of the object manager
 */
+ (void)setSharedManager:(RKObjectManager*)manager;

/// @name Initializing an Object Manager

/**
 Create and initialize a new object manager. If this is the first instance created
 it will be set as the shared instance
 */
+ (RKObjectManager*)objectManagerWithBaseURL:(NSString*)baseURL;

/**
 Initialize a new model manager instance
 */
- (id)initWithBaseURL:(NSString*)baseURL;

/// @name Network Integration

/**
 The underlying HTTP client for this manager
 */
@property (nonatomic, retain) RKClient* client;

/**
 The request cache used to store and load responses for requests sent
 through this object manager's underlying client object
 */
@property (nonatomic, readonly) RKRequestQueue *requestQueue;

/**
 The request queue used to dispatch asynchronous requests sent
 through this object manager's underlying client object
 */
@property (nonatomic, readonly) RKRequestCache *requestCache;

/**
 True when we are in online mode
 */
- (BOOL)isOnline;

/// @name Configuring Object Mapping

/**
 The Mapping Provider responsible for returning mappings for various keyPaths.
 */
@property (nonatomic, retain) RKObjectMappingProvider* mappingProvider;

/**
 Router object responsible for generating resource paths for
 HTTP requests
 */
@property (nonatomic, retain) RKObjectRouter* router;

/**
 A Core Data backed object store for persisting objects that have been fetched from the Web
 */
@property (nonatomic, retain) RKManagedObjectStore* objectStore;

/**
 The Default MIME Type to be used in object serialization.
 */
@property (nonatomic, retain) NSString* serializationMIMEType;

/**
 The value for the HTTP Accept header to specify the preferred format for retrieved data
 */
@property (nonatomic, assign) NSString* acceptMIMEType;

/**
 When YES, RestKit will auto-select the appropriate object mapping for a particular object
 passed through getObject:, postObject:, putObject:, and deleteObject:.
 
 This is useful when you are working with mappable data that is not identifiable via KVC
 and you are sending/receiving objects of the same type. When YES, RestKit will search the
 mappingProvider for an object mapping targeting the same type of object that you passed into
 getObject:, postObject:, :putObject, or deleteObject: and configure the RKObjectLoader to map
 the payload using that mapping. This is merely a convenience for users who are working entirely
 with non-KVC mappable data and saves the added step of searching the mapping provider manually.
 
 Default: NO
 */
@property (nonatomic, assign) BOOL inferMappingsFromObjectTypes;

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
- (RKObjectLoader*)loadObjectsAtResourcePath:(NSString*)resourcePath delegate:(id<RKObjectLoaderDelegate>)delegate;

/**
 Load mappable objects at the specified resourcePath using the specified object mapping.
 */
- (RKObjectLoader*)loadObjectsAtResourcePath:(NSString*)resourcePath objectMapping:(RKObjectMapping*)objectMapping delegate:(id<RKObjectLoaderDelegate>)delegate;

////////////////////////////////////////////////////////
/// @name Mappable Object Loaders

/**
 Fetch the data for a mappable object by performing an HTTP GET. 
 */
- (RKObjectLoader*)getObject:(id<NSObject>)object delegate:(id<RKObjectLoaderDelegate>)delegate;

/**
 Create a remote mappable model by POSTing the attributes to the remote resource and loading the resulting objects from the payload
 */
- (RKObjectLoader*)postObject:(id<NSObject>)object delegate:(id<RKObjectLoaderDelegate>)delegate;

/**
 Update a remote mappable model by PUTing the attributes to the remote resource and loading the resulting objects from the payload
 */
- (RKObjectLoader*)putObject:(id<NSObject>)object delegate:(id<RKObjectLoaderDelegate>)delegate;

/**
 Delete the remote instance of a mappable model by performing an HTTP DELETE on the remote resource
 */
- (RKObjectLoader*)deleteObject:(id<NSObject>)object delegate:(id<RKObjectLoaderDelegate>)delegate;

////////////////////////////////////////////////////////
/// @name Block Configured Object Loaders

#if NS_BLOCKS_AVAILABLE

/**
 Load the objects at the specified resource path and perform object mapping on the response payload. Prior to sending the object loader, the
 block will be invoked to allow you to configure the object loader as you see fit. This can be used to change the response type, set custom
 parameters, choose an object mapping, etc.
 
 For example:
    
    - (void)loadObjectWithBlockExample {
        [[RKObjectManager sharedManager] loadObjectsAtResourcePath:@"/monkeys.json" delegate:self block:^(RKObjectLoader* loader) {
            loader.objectMapping = [[RKObjectManager sharedManager].mappingProvider objectMappingForClass:[Monkey class]];
        }];
    }
 */
- (RKObjectLoader*)loadObjectsAtResourcePath:(NSString*)resourcePath delegate:(id<RKObjectLoaderDelegate>)delegate block:(void(^)(RKObjectLoader*))block;

/**
 Configure and send an object loader after yielding it to a block for configuration. This allows for very succinct on-the-fly
 configuration of the request without obtaining an object reference via objectLoaderForObject: and then sending it yourself.
 
 For example:
 
    - (BOOL)changePassword:(NSString*)newPassword error:(NSError**)error {
        if ([self validatePassword:newPassword error:error]) {
            self.password = newPassword;
            [[RKObjectManager sharedManager] sendObject:self delegate:self block:^(RKObjectLoader* loader) {
                loader.method = RKRequestMethodPOST;
                loader.serializationMIMEType = RKMIMETypeJSON; // We want to send this request as JSON
                loader.targetObject = nil;  // Map the results back onto a new object instead of self
                // Set up a custom serialization mapping to handle this request
                loader.serializationMapping = [RKObjectMapping serializationMappingWithBlock:^(RKObjectMapping* mapping) {
                    [mapping mapAttributes:@"password", nil];
                }];
            }];
        }
    }
 */
- (RKObjectLoader*)sendObject:(id<NSObject>)object delegate:(id<RKObjectLoaderDelegate>)delegate block:(void(^)(RKObjectLoader*))block;

/**
 GET a remote object instance and yield the object loader to the block before sending
 
 @see sendObject:method:delegate:block
 */
- (RKObjectLoader*)getObject:(id<NSObject>)object delegate:(id<RKObjectLoaderDelegate>)delegate block:(void(^)(RKObjectLoader*))block;

/**
 POST a remote object instance and yield the object loader to the block before sending
 
 @see sendObject:method:delegate:block
 - (RKObjectLoader*)postObject:(id<NSObject>)object delegate:(id<RKObjectLoaderDelegate>)delegate block:(void(^)(RKObjectLoader*))block;
 */
- (RKObjectLoader*)postObject:(id<NSObject>)object delegate:(id<RKObjectLoaderDelegate>)delegate block:(void(^)(RKObjectLoader*))block;

/**
 PUT a remote object instance and yield the object loader to the block before sending
 
 @see sendObject:method:delegate:block
 */
- (RKObjectLoader*)putObject:(id<NSObject>)object delegate:(id<RKObjectLoaderDelegate>)delegate block:(void(^)(RKObjectLoader*))block;

/**
 DELETE a remote object instance and yield the object loader to the block before sending
 
 @see sendObject:method:delegate:block
 */
- (RKObjectLoader*)deleteObject:(id<NSObject>)object delegate:(id<RKObjectLoaderDelegate>)delegate block:(void(^)(RKObjectLoader*))block;

#endif

//////

/**
 Fetch the data for a mappable object by performing an HTTP GET. The data returned in the response will be mapped according
 to the object mapping provided.
 */
- (RKObjectLoader*)getObject:(id<NSObject>)object mapResponseWith:(RKObjectMapping*)objectMapping delegate:(id<RKObjectLoaderDelegate>)delegate;

/**
 Send the data for a mappable object by performing an HTTP POST. The data returned in the response will be mapped according
 to the object mapping provided.
 */
- (RKObjectLoader*)postObject:(id<NSObject>)object mapResponseWith:(RKObjectMapping*)objectMapping delegate:(id<RKObjectLoaderDelegate>)delegate;

/**
 Send the data for a mappable object by performing an HTTP PUT. The data returned in the response will be mapped according
 to the object mapping provided.
 */
- (RKObjectLoader*)putObject:(id<NSObject>)object mapResponseWith:(RKObjectMapping*)objectMapping delegate:(id<RKObjectLoaderDelegate>)delegate;

/**
 Delete a remote object representation by performing an HTTP DELETE. The data returned in the response will be mapped according
 to the object mapping provided.
 */
- (RKObjectLoader*)deleteObject:(id<NSObject>)object mapResponseWith:(RKObjectMapping*)objectMapping delegate:(id<RKObjectLoaderDelegate>)delegate;

/**
 These methods are provided for situations where the remote system you are working with has slightly different conventions
 than the default methods provide. They return fully initialized object loaders that are ready for dispatch, but
 have not yet been sent. This can be used to add one-off params to the request body or otherwise manipulate the request
 before it is sent off to be loaded & object mapped. This can also be used to perform a synchronous object load.
 */

/**
 Return an object loader ready to be sent. The method defaults to GET and the URL is relative to the
 baseURL configured on the client. The loader is configured for an implicit objectClass load. This is
 the best place to begin work if you need to create a slightly different collection loader than what is
 provided by the loadObjects family of methods.
 */
- (RKObjectLoader*)objectLoaderWithResourcePath:(NSString*)resourcePath delegate:(id<RKObjectLoaderDelegate>)delegate;

/**
 Returns an object loader configured for transmitting an object instance across the wire. A request will be constructed
 for you with the resource path configured for you by the Router. This is the best place to
 begin work if you need a slightly different interaction with the server than what is provided for you by get/post/put/delete
 object family of methods. Note that this should be used for one-off changes. If you need to substantially modify all your
 object loads, you are better off subclassing or implementing your own RKRouter for dryness.
 
 // TODO: Cleanup this comment
 */
- (RKObjectLoader*)objectLoaderForObject:(id<NSObject>)object method:(RKRequestMethod)method delegate:(id<RKObjectLoaderDelegate>)delegate;

@end
