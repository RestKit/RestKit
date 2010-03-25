//
//  RKModelManager.h
//  RestKit
//
//  Created by Jeremy Ellison on 8/14/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "RKModelMapper.h"
#import "RKClient.h"
#import "RKManagedObjectStore.h"
#import "RKModelLoader.h"

// Notifications
extern NSString* const RKDidEnterOfflineModeNotification;
extern NSString* const RKDidEnterOnlineModeNotification;

@interface RKModelManager : NSObject {
	RKClient* _client;
	RKModelMapper* _mapper;
	RKManagedObjectStore* _objectStore;
	RKMappingFormat _format;
	BOOL _isOnline;
}

/**
 * Return the shared instance of the model manager
 */
+ (RKModelManager*)manager;

/**
 * Set the shared instance of the model manager
 */
+ (void)setManager:(RKModelManager*)manager;

/**
 * Create and initialize a new model manager. If this is the first instance created
 * it will be set as the shared instance
 */
+ (RKModelManager*)managerWithBaseURL:(NSString*)baseURL;

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
 * Register a model mapping from a domain model class to an XML element name
 */
- (void)registerModel:(Class<RKModelMappable>)class forElementNamed:(NSString*)elementName;

/**
 * The model mapper for this manager
 */
@property(nonatomic, readonly) RKModelMapper* mapper;

/**
 * A Core Data backed object store for persisting objects that have been fetched from the Web
 */
@property(nonatomic, retain) RKManagedObjectStore* objectStore;

/**
 * Fetch a resource via an HTTP GET and invoke a callback with the model for the resulting payload
 */
- (RKRequest*)loadModels:(NSString*)resourcePath delegate:(NSObject<RKModelLoaderDelegate>*)delegate;

// Load via a method...
- (RKRequest*)loadModels:(NSString*)resourcePath method:(RKRequestMethod)method delegate:(NSObject<RKModelLoaderDelegate>*)delegate;

/**
 * Fetch a resource via a specified HTTP method
 */
- (RKRequest*)loadModels:(NSString *)resourcePath method:(RKRequestMethod)method params:(NSObject<RKRequestSerializable>*)params delegate:(NSObject<RKModelLoaderDelegate>*)delegate;

/**
 * Fetch a resource via an HTTP GET with a dictionary of parameters and invoke a callback with the models mapped from the payload
 */
- (RKRequest*)loadModels:(NSString*)resourcePath params:(NSDictionary*)params delegate:(NSObject<RKModelLoaderDelegate>*)delegate;

////////////////////////////////////////////////////////
// Model Mappable object helpers

/**
 * Update a mappable model by loading its attributes from the web
 */
- (RKRequest*)getModel:(id<RKModelMappable>)model delegate:(NSObject<RKModelLoaderDelegate>*)delegate;

/**
 * Create a remote mappable model by POSTing the attributes to the remote resource and loading the resulting model from the payload
 */
- (RKRequest*)postModel:(id<RKModelMappable>)model delegate:(NSObject<RKModelLoaderDelegate>*)delegate;

/**
 * Update a remote mappable model by PUTing the attributes to the remote resource and loading the resulting model from the payload
 */
- (RKRequest*)putModel:(id<RKModelMappable>)model delegate:(NSObject<RKModelLoaderDelegate>*)delegate;

/**
 * Delete the remote instance of a mappable model by performing an HTTP DELETE on the remote resource
 */
- (RKRequest*)deleteModel:(id<RKModelMappable>)model delegate:(NSObject<RKModelLoaderDelegate>*)delegate;

@end
