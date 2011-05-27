//
//  RKObjectLoader.h
//  RestKit
//
//  Created by Blake Watters on 8/8/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "../Network/Network.h"
#import "RKObjectMapping.h"
#import "RKObjectMappingResult.h"

@class RKObjectManager;
@class RKObjectLoader;

@protocol RKObjectLoaderDelegate <RKRequestDelegate>

@required

/**
 * Sent when an object loaded failed to load the collection due to an error
 */
- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error;

@optional

/*!
 When implemented, sent to the delegate when the object laoder has completed successfully
 and loaded a collection of objects. All objects mapped from the remote payload will be returned
 as a single array.
 */
- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray*)objects;

/*!
 When implemented, sent to the delegate when the object loader has completed succesfully. 
 If the load resulted in a collection of objects being mapped, only the first object
 in the collection will be sent with this delegate method. This method simplifies things
 when you know you are working with a single object reference.
 */
- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObject:(id)object;

/*!
 When implemented, sent to the delegate when an object loader has completed successfully. The
 dictionary will be expressed as pairs of keyPaths and objects mapped from the payload. This
 method is useful when you have multiple root objects and want to differentiate them by keyPath.
 */
- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjectDictionary:(NSDictionary*)dictionary;

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
    RKObjectMapping* _objectMapping;
    RKObjectMappingResult* _result;
	NSObject* _targetObject;
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
 * The object mapping to apply to the response
 */
@property (nonatomic, retain) RKObjectMapping* objectMapping;

/**
 * The mappable object that generated this loader. This is used to map object
 * updates back to the object that sent the request
 */
@property (nonatomic, retain) NSObject* targetObject;

/**
 * If the request was sent synchronously, this is how you get at the object mapping result.
 */
@property (nonatomic, retain) RKObjectMappingResult* result;

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
