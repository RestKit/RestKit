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

+ (RKModelManager*)manager;
+ (void)setManager:(RKModelManager*)manager;
+ (RKModelManager*)managerWithBaseURL:(NSString*)baseURL;
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
- (RKRequest*)loadModels:(NSString*)resourcePath params:(NSDictionary*)params delegate:(NSObject<RKModelLoaderDelegate>*)delegate callback:(SEL)callback;

- (RKRequest*)getModel:(id<RKModelMappable>)model delegate:(NSObject<RKModelLoaderDelegate>*)delegate callback:(SEL)callback;
- (RKRequest*)postModel:(id<RKModelMappable>)model delegate:(NSObject<RKModelLoaderDelegate>*)delegate callback:(SEL)callback;
- (RKRequest*)putModel:(id<RKModelMappable>)model delegate:(NSObject<RKModelLoaderDelegate>*)delegate callback:(SEL)callback;
- (RKRequest*)deleteModel:(id<RKModelMappable>)model delegate:(NSObject<RKModelLoaderDelegate>*)delegate callback:(SEL)callback;

@end
