//
//  RKRequestModel.h
//  RestKit
//
//  Created by Jeff Arena on 4/26/10.
//  Copyright 2010 GateGuru. All rights reserved.
//

#import <RestKit/RestKit.h>

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
@interface RKRequestModel : NSObject <RKModelLoaderDelegate, RKRequestDelegate> {
	NSArray *_objects;
	BOOL _loaded;
	
	NSString* _resourcePath;
	NSDictionary* _params;
	RKRequest* _loadingRequest;
	RKRequestMethod _method;
	id _delegate;
	
	NSFetchRequest* _fetchRequest;
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

@property (nonatomic, readonly) RKRequest* loadingRequest;

/**
 * The HTTP method to load the models with. Defaults to RKRequestMethodGET
 */
@property (nonatomic, assign) RKRequestMethod method;

@property (nonatomic, retain) NSFetchRequest* fetchRequest;

@property (assign) NSTimeInterval refreshRate;


/**
 * Init methods and class methods for creating new models
 */
+ (id)modelWithResourcePath:(NSString*)resourcePath delegate:(id)delegate;
+ (id)modelWithResourcePath:(NSString*)resourcePath params:(NSDictionary*)params delegate:(id)delegate;
- (id)initWithResourcePath:(NSString*)resourcePath delegate:(id)delegate;
- (id)initWithResourcePath:(NSString*)resourcePath params:(NSDictionary*)params delegate:(id)delegate;

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

@end
