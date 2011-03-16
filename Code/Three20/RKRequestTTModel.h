//
//  RKRequestTTModel.h
//  RestKit
//
//  Created by Blake Watters on 2/9/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import <Three20/Three20.h>
#import "../RestKit.h"

/**
 * Generic class for loading a remote model using a RestKit request and supplying the model to a
 * TTListDataSource subclass
 */
@interface RKRequestTTModel : TTModel <RKObjectLoaderDelegate> {
	NSArray *_objects;
	BOOL _isLoaded;
	BOOL _isLoading;
	BOOL _cacheLoaded;
	BOOL _emptyReloadAttempted;

	NSString* _resourcePath;
	NSDictionary* _params;
	RKRequestMethod _method;
	Class _objectClass;
	NSString* _keyPath;

	NSTimeInterval _refreshRate;
}

/**
 * Domain objects loaded via this model
 */
@property (nonatomic, readonly) NSArray* objects;

/**
 * The resourcePath used to create this model
 */
@property (nonatomic, readonly) NSString* resourcePath;

/**
 * The NSDate object representing the last time this model was loaded.
 */
@property (nonatomic, readonly) NSDate* loadedTime;

/**
 * Request parameters
 */
@property (nonatomic, retain) NSDictionary* params;

/**
 * The HTTP method to load the models with. Defaults to RKRequestMethodGET
 */
@property (nonatomic, assign) RKRequestMethod method;

/**
 * The rate at which this model should be refreshed after initial load.
 * Defaults to the value returned by + (NSTimeInterval)defaultRefreshRate.
 */
@property (assign) NSTimeInterval refreshRate;

/**
 * Init methods for creating new models
 */
- (id)initWithResourcePath:(NSString*)resourcePath;
- (id)initWithResourcePath:(NSString*)resourcePath params:(NSDictionary*)params;
- (id)initWithResourcePath:(NSString*)resourcePath params:(NSDictionary*)params objectClass:(Class)klass;
- (id)initWithResourcePath:(NSString*)resourcePath params:(NSDictionary*)params objectClass:(Class)klass keyPath:(NSString*)keyPath;
- (id)initWithResourcePath:(NSString*)resourcePath params:(NSDictionary*)params method:(RKRequestMethod)method;

/**
 * The NSDate representing the first time the app was run. This defaultLoadedTime
 * is used in comparison with refreshRate in cases where a resourcePath-specific
 * loadedTime has yet to be established for a given resourcePath.
 */
+ (NSDate*)defaultLoadedTime;

/**
 * App-level default refreshRate used in determining when to refresh a given model.
 * Defaults to NSTimeIntervalSince1970, which essentially means all app models
 * will never refresh.
 */
+ (NSTimeInterval)defaultRefreshRate;

/**
 * Setter for defaultRefreshRate, which allows one to set an app-wide refreshRate
 * for all models, as opposed to having to set the refreshRate on every instantiation
 * of RKRequestTTModel.
 */
+ (void)setDefaultRefreshRate:(NSTimeInterval)newDefaultRefreshRate;

@end
