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
@property (nonatomic, readonly) RKClient* client;

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
- (RKRequest*)loadModel:(NSString*)resourcePath delegate:(NSObject<RKModelLoaderDelegate>*)delegate callback:(SEL)callback;

/**
 * Fetch a resource via an HTTP GET and invoke a callback with the model for the resulting payload
 */
- (RKRequest*)loadModels:(NSString*)resourcePath delegate:(NSObject<RKModelLoaderDelegate>*)delegate callback:(SEL)callback;

/**
 * Fetch a resource via an HTTP POST with a dictionary of parameters and invoke a callback with the models mapped from the payload
 *
 * TODO: This may not be right... may want to allow specification of the HTTP verb. The use case is to support
 * loading a remote resource where the amount of data exceeds what is encodeable in URL parameters. This comes up
 * in GateGuru when loading HighFlyer's from Facebook friends, as the payload gets big fast.
 */
- (RKRequest*)loadModels:(NSString*)resourcePath params:(NSDictionary*)params delegate:(NSObject<RKModelLoaderDelegate>*)delegate callback:(SEL)callback;

/**
 * Update a mappable model by loading its attributes from the web
 */
- (RKRequest*)getModel:(id<RKModelMappable>)model delegate:(NSObject<RKModelLoaderDelegate>*)delegate callback:(SEL)callback;

/**
 * Create a remote mappable model by POSTing the attributes to the remote resource and loading the resulting model from the payload
 */
- (RKRequest*)postModel:(id<RKModelMappable>)model delegate:(NSObject<RKModelLoaderDelegate>*)delegate callback:(SEL)callback;

/**
 * Update a remote mappable model by PUTing the attributes to the remote resource and loading the resulting model from the payload
 */
- (RKRequest*)putModel:(id<RKModelMappable>)model delegate:(NSObject<RKModelLoaderDelegate>*)delegate callback:(SEL)callback;

/**
 * Delete the remote instance of a mappable model by performing an HTTP DELETE on the remote resource
 */
- (RKRequest*)deleteModel:(id<RKModelMappable>)model delegate:(NSObject<RKModelLoaderDelegate>*)delegate callback:(SEL)callback;

@end
