//
//  RKRequestModel.h
//  RestKit
//
//  Created by Jeff Arena on 4/26/10.
//  Copyright 2010 RestKit. All rights reserved.
//

#import <RestKit/RestKit.h>
#import "../CoreData/RKManagedObject.h"

/**
 * Lifecycle events for RKRequestModel
 *
 * Modeled off of RKRequestDelegate (and therefore TTURLRequest)
 */
@protocol RKRequestModelDelegate 
@optional
- (void)rkModelDidStartLoad;
- (void)rkModelDidFinishLoad;
- (void)rkModelDidFailLoadWithError:(NSError*)error;
- (void)rkModelDidCancelLoad;
- (void)rkModelDidLoad;
@end

/**
 * Generic class for loading a remote model using a RestKit request
 */
@interface RKRequestModel : NSObject <RKObjectLoaderDelegate, RKRequestDelegate> {
	NSArray *_objects;
	BOOL _loaded;
	
	NSString* _resourcePath;
	NSDictionary* _params;
	RKRequestMethod _method;
	id _delegate;
	RKObjectLoader* _objectLoader;
	Class _objectClass;
	NSString* _keyPath;
	
	NSTimeInterval _refreshRate;
}

/**
 * Domain objects loaded via this model
 */
@property (nonatomic, readonly) NSArray *objects;

@property (readonly) BOOL loaded;

@property (nonatomic, readonly) NSString* resourcePath;

/**
 * Any parameters POSTed with the request
 */
@property (nonatomic, readonly) NSDictionary* params;

@property (nonatomic, readonly) RKObjectLoader* objectLoader;

/**
 * The HTTP method to load the models with. Defaults to RKRequestMethodGET
 */
@property (nonatomic, assign) RKRequestMethod method;

@property (assign) NSTimeInterval refreshRate;


/**
 * Init methods for creating new models
 */
- (id)initWithResourcePath:(NSString*)resourcePath delegate:(id)delegate;
- (id)initWithResourcePath:(NSString*)resourcePath params:(NSDictionary*)params delegate:(id)delegate;
- (id)initWithResourcePath:(NSString*)resourcePath params:(NSDictionary*)params objectClass:(Class)klass delegate:(id)delegate;
- (id)initWithResourcePath:(NSString*)resourcePath params:(NSDictionary*)params objectClass:(Class)klass keyPath:(NSString*)keyPath delegate:(id)delegate;

/**
 * Clear the last loaded time for the model
 */
- (void)clearLoadedTime;

/*
 * Save the last loaded time for the model
 */
- (void)saveLoadedTime;

/**
 * Get the last loaded time for the model
 */
- (NSDate*)loadedTime;

/**
 * Invoked after a remote request has completed and model objects have been
 * built from the response. Subclasses must invoke super to complete the load operation
 */
- (void)modelsDidLoad:(NSArray*)models;

- (void)reset;

- (void)load;

- (void)loadFromObjectCache;

@end
