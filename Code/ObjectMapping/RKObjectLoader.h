//
//  RKObjectLoader.h
//  RestKit
//
//  Created by Blake Watters on 8/8/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

// TODO: Factor core data out...
#import <CoreData/CoreData.h>
#import "../Network/Network.h"
#import "RKObjectMapper.h"

@class RKObjectLoader;
@class RKManagedObjectStore;

@protocol RKObjectLoaderDelegate <RKRequestDelegate>

/**
 * Sent when an object loader has completed successfully and loaded a collection of mapped objects
 */
- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray*)objects;

/**
 * Sent when an object loaded failed to load the collection due to an error
 */
- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error;

@optional
/**
 * Sent when an object loader encounters a response status code it does not know how to handle.
 * 2xx, 4xx, and 5xx responses are all handled appropriately. This should only occur when the remote
 * service sends back a really odd-ball response.
 *
 * @optional
 */
- (void)objectLoaderDidLoadUnexpectedResponse:(RKObjectLoader*)objectLoader;

@end

/**
 * Wraps a request/response cycle and loads a remote object representation into local domain objects
 */
@interface RKObjectLoader : RKRequest {
	RKObjectMapper* _mapper;
	RKResponse* _response;
	NSObject<RKObjectMappable>* _targetObject;
	Class<RKObjectMappable> _objectClass;
	NSString* _keyPath;
	RKManagedObjectStore* _managedObjectStore;
	NSManagedObjectID* _targetObjectID;
	RKClient* _client;
}

/**
 * The resource mapper this loader is working with
 */
@property (nonatomic, readonly) RKObjectMapper* mapper;

/**
 * The underlying response object for this loader
 */
@property (nonatomic, readonly) RKResponse* response;

/**
 * The mappable object class to load payload results into. When nil, indicates that
 * the resulting objects will be determined via element registrations on the mapper.
 */
@property (nonatomic, assign) Class<RKObjectMappable> objectClass;

/**
 * The mappable object that generated this loader. This is used to map object
 * updates back to the object that sent the request
 */
@property (nonatomic, retain) NSObject<RKObjectMappable>* targetObject;

/*
 * The keyPath property is an optional property to tell the mapper to map a subset of the response
 * defined by a specific key.
 */
@property (nonatomic, copy) NSString* keyPath;

/*
 * In cases where CoreData is used for local object storage/caching, a reference to
 * the managedObjectStore for use in retrieving locally cached objects using the store's
 * managedObjectCache property.
 */
@property (nonatomic, retain) RKManagedObjectStore* managedObjectStore;

/**
 * Return an auto-released loader with with an object mapper, a request, and a delegate
 */
+ (id)loaderWithResourcePath:(NSString*)resourcePath mapper:(RKObjectMapper*)mapper delegate:(NSObject<RKObjectLoaderDelegate>*)delegate;
+ (id)loaderWithResourcePath:(NSString*)resourcePath client:(RKClient*)client mapper:(RKObjectMapper*)mapper delegate:(NSObject<RKObjectLoaderDelegate>*)delegate;

/**
 * Initialize a new object loader with an object mapper, a request, and a delegate
 */
- (id)initWithResourcePath:(NSString*)resourcePath mapper:(RKObjectMapper*)mapper delegate:(NSObject<RKObjectLoaderDelegate>*)delegate;									
- (id)initWithResourcePath:(NSString*)resourcePath client:(RKClient*)client mapper:(RKObjectMapper*)mapper delegate:(NSObject<RKObjectLoaderDelegate>*)delegate;

@end
