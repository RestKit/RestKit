//
//  OTRestModelManager.h
//  OTRestFramework
//
//  Created by Jeremy Ellison on 8/14/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "OTRestModelMapper.h"
#import "OTRestClient.h"
#import "OTRestManagedObjectStore.h"

extern NSString* const kOTRestDidEnterOfflineMode;
extern NSString* const kOTRestDidEnterOnlineMode;

@interface OTRestModelManager : NSObject {
	OTRestClient* _client;
	OTRestModelMapper* _mapper;
	OTRestManagedObjectStore* _objectStore;
	OTRestMappingFormat _format;
	BOOL _isOnline;
}

+ (OTRestModelManager*)manager;
+ (void)setManager:(OTRestModelManager*)manager;
+ (OTRestModelManager*)managerWithBaseURL:(NSString*)baseURL;
- (id)initWithBaseURL:(NSString*)baseURL;

/**
 * The wire format to use for communications. Either OTRestMappingFormatXML or OTRestMappingFormatJSON.
 *
 * Defaults to OTRestMappingFormatXML
 */
@property(nonatomic, assign) OTRestMappingFormat format;

/**
 * The REST client for this manager
 */
@property (nonatomic, readonly) OTRestClient* client;

/**
 * gets rid of the client, effectively making online connection impossible
 */
- (void)goOffline;

/**
 * recreates the client with the original base url
 */
- (void)goOnline;

/**
 * returns true if the _client exists (does not detect network connectivity)
 */
- (BOOL)isOnline;

/**
 * Register a model mapping from a domain model class to an XML element name
 */
- (void)registerModel:(Class<OTRestModelMappable>)class forElementNamed:(NSString*)elementName;

/**
 * The model mapper for this manager
 */
@property(nonatomic, readonly) OTRestModelMapper* mapper;

/**
 * A Core Data backed object store for persisting objects that have been fetched from the Web
 */
@property(nonatomic, retain) OTRestManagedObjectStore* objectStore;

/**
 * Fetch a resource via an HTTP GET and invoke a callback with the model for the resulting payload
 */
- (OTRestRequest*)loadModel:(NSString*)resourcePath delegate:(id)delegate callback:(SEL)callback;

/**
 * Fetch a resource via an HTTP GET and invoke a callback with the model for the resulting payload
 */
- (OTRestRequest*)loadModels:(NSString*)resourcePath delegate:(id)delegate callback:(SEL)callback;
- (OTRestRequest*)loadModels:(NSString*)resourcePath params:(NSDictionary*)params delegate:(id)delegate callback:(SEL)callback;

- (OTRestRequest*)getModel:(id<OTRestModelMappable>)model delegate:(id)delegate callback:(SEL)callback;
- (OTRestRequest*)postModel:(id<OTRestModelMappable>)model delegate:(id)delegate callback:(SEL)callback;
- (OTRestRequest*)putModel:(id<OTRestModelMappable>)model delegate:(id)delegate callback:(SEL)callback;
- (OTRestRequest*)deleteModel:(id<OTRestModelMappable>)model delegate:(id)delegate callback:(SEL)callback;

@end
