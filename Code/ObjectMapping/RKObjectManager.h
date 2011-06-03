//
//  RKObjectManager.h
//  RestKit
//
//  Created by Jeremy Ellison on 8/14/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "../Network/Network.h"
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

@interface RKObjectManager : NSObject {
	RKClient* _client;
	RKObjectRouter* _router;
	RKManagedObjectStore* _objectStore;	
	RKObjectManagerOnlineState _onlineState;
    RKObjectMappingProvider* _mappingProvider;
    NSString* _serializationMIMEType;
}

/**
 * Return the shared instance of the object manager
 */
+ (RKObjectManager*)sharedManager;

/**
 * Set the shared instance of the object manager
 */
+ (void)setSharedManager:(RKObjectManager*)manager;

/**
 * Create and initialize a new object manager. If this is the first instance created
 * it will be set as the shared instance
 */
+ (RKObjectManager*)objectManagerWithBaseURL:(NSString*)baseURL;

/**
 * Initialize a new model manager instance
 */
- (id)initWithBaseURL:(NSString*)baseURL;

/**
 * The REST client for this manager
 */
@property (nonatomic, retain) RKClient* client;

/**
 * True when we are in online mode
 */
- (BOOL)isOnline;

/**
 * The Mapping Provider responsible for returning mappings for various keyPaths.
 */
@property (nonatomic, retain) RKObjectMappingProvider* mappingProvider;

/**
 * Router object responsible for generating resource paths for
 * HTTP requests
 */
@property (nonatomic, retain) RKObjectRouter* router;

/**
 * A Core Data backed object store for persisting objects that have been fetched from the Web
 */
@property (nonatomic, retain) RKManagedObjectStore* objectStore;

/**
 * The Default MIME Type to be used in object serialization.
 */
@property (nonatomic, retain) NSString* serializationMIMEType;

/**
 * The value for the HTTP Accept header to specify the preferred format for retrieved data
 */
@property (nonatomic, assign) NSString* acceptMIMEType;

////////////////////////////////////////////////////////
// Registered Object Loaders

/**
 * These methods are suitable for loading remote payloads that encode type information into the payload. This enables
 * the mapping of complex payloads spanning multiple types (i.e. a search operation returning Articles & Comments in
 * one payload). Ruby on Rails JSON serialization is an example of such a conformant system.
 */
 
/**
 * Create and send an asynchronous GET request to load the objects at the resource path and call back the delegate
 * with the loaded objects. Remote objects will be mapped to local objects by consulting the element registrations
 * set on the mapper.
 */
- (RKObjectLoader*)loadObjectsAtResourcePath:(NSString*)resourcePath delegate:(id<RKObjectLoaderDelegate>)delegate;

/**
 * Create and send an asynchronous GET request to load the objects at the specified resource path with a dictionary
 * of query parameters to append to the URL and call back the delegate with the loaded objects. Remote objects will be mapped to 
 * local objects by consulting the element registrations set on the mapper.
 */
// TODO: Deprecate! Just RKPathAppendQueryParams(resourcePath, queryParams)
- (RKObjectLoader*)loadObjectsAtResourcePath:(NSString *)resourcePath queryParams:(NSDictionary*)queryParams delegate:(id<RKObjectLoaderDelegate>)delegate;

// TODO: Document!
- (RKObjectLoader*)loadObjectsAtResourcePath:(NSString*)resourcePath objectMapping:(RKObjectMapping*)objectMapping delegate:(id<RKObjectLoaderDelegate>)delegate;
- (RKObjectLoader*)loadObjectsAtResourcePath:(NSString *)resourcePath queryParams:(NSDictionary*)queryParams objectMapping:(RKObjectMapping*)objectMapping delegate:(id<RKObjectLoaderDelegate>)delegate;

////////////////////////////////////////////////////////
// Mappable object helpers

/**
 * Update a mappable model by loading its attributes from the web
 */
- (RKObjectLoader*)getObject:(id<NSObject>)object delegate:(id<RKObjectLoaderDelegate>)delegate;

/**
 * Create a remote mappable model by POSTing the attributes to the remote resource and loading the resulting objects from the payload
 */
- (RKObjectLoader*)postObject:(id<NSObject>)object delegate:(id<RKObjectLoaderDelegate>)delegate;

/**
 * Update a remote mappable model by PUTing the attributes to the remote resource and loading the resulting objects from the payload
 */
- (RKObjectLoader*)putObject:(id<NSObject>)object delegate:(id<RKObjectLoaderDelegate>)delegate;

/**
 * Delete the remote instance of a mappable model by performing an HTTP DELETE on the remote resource
 */
- (RKObjectLoader*)deleteObject:(id<NSObject>)object delegate:(id<RKObjectLoaderDelegate>)delegate;

////////////////////////////////////////////////////////
// Object Loader Primitives

/**
 * These methods are provided for situations where the remote system you are working with has slightly different conventions
 * than the default methods provide. They return fully initialized object loaders that are ready for dispatch, but
 * have not yet been sent. This can be used to add one-off params to the request body or otherwise manipulate the request
 * before it is sent off to be loaded & object mapped. This can also be used to perform a synchronous object load.
 */

/**
 * Return an object loader ready to be sent. The method defaults to GET and the URL is relative to the
 * baseURL configured on the client. The loader is configured for an implicit objectClass load. This is
 * the best place to begin work if you need to create a slightly different collection loader than what is
 * provided by the loadObjects family of methods.
 */
- (RKObjectLoader*)objectLoaderWithResourcePath:(NSString*)resourcePath delegate:(id<RKObjectLoaderDelegate>)delegate;

/**
 * Returns an object loader configured for transmitting an object instance across the wire. A request will be constructed
 * for you with the resource path configured for you by the Router. This is the best place to
 * begin work if you need a slightly different interaction with the server than what is provided for you by get/post/put/delete
 * object family of methods. Note that this should be used for one-off changes. If you need to substantially modify all your
 * object loads, you are better off subclassing or implementing your own RKRouter for dryness.
 
 // TODO: Cleanup this comment
 */
- (RKObjectLoader*)objectLoaderForObject:(id<NSObject>)object method:(RKRequestMethod)method delegate:(id<RKObjectLoaderDelegate>)delegate;

@end
