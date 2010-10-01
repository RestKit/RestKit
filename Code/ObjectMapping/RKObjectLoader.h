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
@protocol RKObjectLoaderDelegate <RKRequestDelegate>

/**
 * Sent when an object loader has completed successfully and loaded a collection of mapped objects
 */
- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray*)objects;

/**
 * Sent when an object loaded failed to load the collection due to an error
 */
- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error;

@end

/**
 * Wraps a request/response cycle and loads a remote object representation into local domain objects
 */
@interface RKObjectLoader : NSObject <RKRequestDelegate> {
	RKObjectMapper* _mapper;
	NSObject<RKObjectLoaderDelegate>* _delegate;	
	RKRequest* _request;
	RKResponse* _response;
	Class<RKObjectMappable> _objectClass;
	NSFetchRequest* _fetchRequest;
}

/**
 * The resource mapper this loader is working with
 */
@property (nonatomic, readonly) RKObjectMapper* mapper;

/**
 * The object to be invoked with the loaded models
 *
 * If this object implements life-cycle methods from the RKRequestDelegate protocol, 
 * events from the request will be forwarded back.
 */
@property (nonatomic, assign) NSObject<RKObjectLoaderDelegate>* delegate;

/**
 * The underlying request object for this loader
 */
@property (nonatomic, retain) RKRequest* request;

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
 * updates back to the source object that sent the request
 */
@property (nonatomic, retain) NSObject<RKObjectMappable>* source;

/**
 * The URL this loader sent the request to
 */
@property (nonatomic, readonly) NSURL* URL;

/**
 * The HTTP method used to send the request
 */
@property (nonatomic, assign) RKRequestMethod method;

/**
 * Parameters sent with the request
 */
@property (nonatomic, retain) NSObject<RKRequestSerializable>* params;

/**
 * Fetch request for loading cached objects. This is used to remove objects from the local persistent store
 * when model mapping operations are completed.
 *
 * TODO: May belong in an inherited subclass to isolate persistent/non-persistent mapping in the future.
 */
@property (nonatomic, retain) NSFetchRequest* fetchRequest;

/**
 * Return an auto-released loader with with an object mapper, a request, and a delegate
 */
+ (id)loaderWithMapper:(RKObjectMapper*)mapper request:(RKRequest*)request delegate:(NSObject<RKObjectLoaderDelegate>*)delegate;

/**
 * Initialize a new object loader with an object mapper, a request, and a delegate
 */
- (id)initWithMapper:(RKObjectMapper*)mapper request:(RKRequest*)request delegate:(NSObject<RKObjectLoaderDelegate>*)delegate;

/**
 * Asynchronously send the object loader request
 */
- (void)send;

/**
 * Synchronously send the object loader request and process the response
 */
- (void)sendSynchronously;																   

@end
