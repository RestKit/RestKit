//
//  RKObjectManager.h
//  RestKit
//
//  Created by Jeremy Ellison on 8/14/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "RKClient.h"
#import "RKObjectMapper.h"
#import "RKObjectLoader.h"
#import "RKStaticRouter.h"
#import "RKManagedObjectStore.h"

// Notifications
extern NSString* const RKDidEnterOfflineModeNotification;
extern NSString* const RKDidEnterOnlineModeNotification;

@interface RKObjectManager : NSObject {
	RKClient* _client;
	RKMappingFormat _format;
	RKObjectMapper* _mapper;
	NSObject<RKRouter>* _router;
	RKManagedObjectStore* _objectStore;		
	BOOL _isOnline;
}

/**
 * Return the shared instance of the model manager
 */
+ (RKObjectManager*)manager;

/**
 * Set the shared instance of the model manager
 */
+ (void)setManager:(RKObjectManager*)manager;

/**
 * Create and initialize a new model manager. If this is the first instance created
 * it will be set as the shared instance
 */
+ (RKObjectManager*)managerWithBaseURL:(NSString*)baseURL;

/**
 * Initialize a new model manager instance
 */
- (id)initWithBaseURL:(NSString*)baseURL;

/**
 * The wire format to use for communications. Either RKMappingFormatXML or RKMappingFormatJSON.
 *
 * Defaults to RKMappingFormatXML
 */
@property(nonatomic, assign) RKMappingFormat format;

/**
 * The REST client for this manager
 */
@property (nonatomic, retain) RKClient* client;

/**
 * Puts the manager into offline mode. Requests will not be sent.
 */
- (void)goOffline;

/**
 * Puts the manager into online mode. Requests will be sent.
 */
- (void)goOnline;

/**
 * True when we are in online mode
 */
- (BOOL)isOnline;

/**
 * Register a resource mapping from a domain model class to a JSON/XML element name
 */
- (void)registerClass:(Class<RKObjectMappable>)class forElementNamed:(NSString*)elementName;

/**
 * Mapper object responsible for mapping remote HTTP resources to Cocoa objects
 */
@property(nonatomic, readonly) RKObjectMapper* mapper;

/**
 * Routing object responsible for generating paths for objects and serializing
 * representations of the object for transport.
 *
 * Defaults to an instance of RKStaticRouter
 */
@property(nonatomic, retain) NSObject<RKRouter>* router;

/**
 * A Core Data backed object store for persisting objects that have been fetched from the Web
 */
@property(nonatomic, retain) RKManagedObjectStore* objectStore;

/**
 * Fetch a resource via an HTTP GET and invoke a callback with the model for the resulting payload
 */
- (RKRequest*)loadResource:(NSString*)resourcePath delegate:(NSObject<RKObjectLoaderDelegate>*)delegate;

// Load via a method...
- (RKRequest*)loadResource:(NSString*)resourcePath method:(RKRequestMethod)method delegate:(NSObject<RKObjectLoaderDelegate>*)delegate;

/**
 * Fetch a resource via a specified HTTP method
 */
- (RKRequest*)loadResource:(NSString*)resourcePath method:(RKRequestMethod)method params:(NSObject<RKRequestSerializable>*)params delegate:(NSObject<RKObjectLoaderDelegate>*)delegate;

/**
 * Fetch a resource via an HTTP GET with a dictionary of parameters and invoke a callback with the models mapped from the payload
 */
- (RKRequest*)loadResource:(NSString*)resourcePath params:(NSDictionary*)params delegate:(NSObject<RKObjectLoaderDelegate>*)delegate;

/**
 * Fetch methods for clients that implement local caching
 */
// TODO: Need a better implementation of the cacheing...
- (RKRequest*)loadResource:(NSString*)resourcePath fetchRequest:(NSFetchRequest*)fetchRequest method:(RKRequestMethod)method delegate:(NSObject<RKObjectLoaderDelegate>*)delegate;
- (RKRequest*)loadResource:(NSString*)resourcePath fetchRequest:(NSFetchRequest*)fetchRequest method:(RKRequestMethod)method params:(NSObject<RKRequestSerializable>*)params delegate:(NSObject<RKObjectLoaderDelegate>*)delegate;

////////////////////////////////////////////////////////
// Model Mappable object helpers

/**
 * Update a mappable model by loading its attributes from the web
 */
- (RKRequest*)getObject:(NSObject<RKObjectMappable>*)object delegate:(NSObject<RKObjectLoaderDelegate>*)delegate;

/**
 * Create a remote mappable model by POSTing the attributes to the remote resource and loading the resulting model from the payload
 */
- (RKRequest*)postObject:(NSObject<RKObjectMappable>*)object delegate:(NSObject<RKObjectLoaderDelegate>*)delegate;

/**
 * Update a remote mappable model by PUTing the attributes to the remote resource and loading the resulting model from the payload
 */
- (RKRequest*)putObject:(NSObject<RKObjectMappable>*)object delegate:(NSObject<RKObjectLoaderDelegate>*)delegate;

/**
 * Delete the remote instance of a mappable model by performing an HTTP DELETE on the remote resource
 */
- (RKRequest*)deleteObject:(NSObject<RKObjectMappable>*)object delegate:(NSObject<RKObjectLoaderDelegate>*)delegate;

@end
