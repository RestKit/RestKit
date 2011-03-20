//
//  RKObjectLoader.h
//  RestKit
//
//  Created by Blake Watters on 8/8/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "../Network/Network.h"
#import "RKObjectMappable.h"

@class RKObjectManager;
@class RKObjectLoader;

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
 *
 * NOTE: When Core Data is linked into the application, the object manager will return instances of
 * RKManagedObjectLoader instead of RKObjectLoader. RKManagedObjectLoader is a descendent class that 
 * includes Core Data specific mapping logic.
 */
@interface RKObjectLoader : RKRequest {	
    RKObjectManager* _objectManager;
	RKResponse* _response;
	NSObject<RKObjectMappable>* _targetObject;
	Class<RKObjectMappable> _objectClass;
	NSString* _keyPath;
}

/**
 * The object manager that initialized this loader. The object manager is responsible
 * for supplying the mapper and object store used after HTTP transport is completed
 */
@property (nonatomic, readonly) RKObjectManager* objectManager;

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

/**
 * Initialize and return an object loader for a resource path against an object manager. The resource path
 * specifies the remote location to load data from, while the object manager is responsible for supplying
 * mapping and persistence details.
 */
+ (id)loaderWithResourcePath:(NSString*)resourcePath objectManager:(RKObjectManager*)objectManager delegate:(NSObject<RKObjectLoaderDelegate>*)delegate;

/**
 * Initialize a new object loader with an object mapper, a request, and a delegate
 */
- (id)initWithResourcePath:(NSString*)resourcePath objectManager:(RKObjectManager*)objectManager delegate:(NSObject<RKObjectLoaderDelegate>*)delegate;				

@end
