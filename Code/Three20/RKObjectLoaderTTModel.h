//
//  RKObjectLoaderTTModel.h
//  RestKit
//
//  Created by Blake Watters on 2/9/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import <Three20/Three20.h>
#import "../RestKit.h"

/**
 * Generic class for loading a remote model using a RestKit object loader and supplying the model to a
 * TTListDataSource subclass
 */
@interface RKObjectLoaderTTModel : TTModel <RKObjectLoaderDelegate> {
	NSArray *_objects;
	BOOL _isLoaded;
	BOOL _isLoading;
	BOOL _cacheLoaded;
	BOOL _emptyReloadAttempted;
    RKObjectLoader* _objectLoader;

	NSTimeInterval _refreshRate;
}

/////////////////////////////////////////////////////////////////////////
/// @name Global Configuration
/////////////////////////////////////////////////////////////////////////

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

/////////////////////////////////////////////////////////////////////////
/// @name Accessing Model Data
/////////////////////////////////////////////////////////////////////////

/**
 * Domain objects loaded via this model
 */
@property (nonatomic, readonly) NSArray* objects;

/**
 * The object loader responsible for loading the data accessed via this model
 */
@property (nonatomic, readonly) RKObjectLoader* objectLoader;

/**
 * The NSDate object representing the last time this model was loaded.
 */
@property (nonatomic, readonly) NSDate* loadedTime;

/**
 * The rate at which this model should be refreshed after initial load.
 * Defaults to the value returned by + (NSTimeInterval)defaultRefreshRate.
 */
@property (assign) NSTimeInterval refreshRate;

+ (id)modelWithObjectLoader:(RKObjectLoader*)objectLoader;
- (id)initWithObjectLoader:(RKObjectLoader*)objectLoader;

/**
 * Load the model
 */
- (void)load;

@end
