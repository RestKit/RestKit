//
//  RKTestFactory.h
//  RKGithub
//
//  Created by Blake Watters on 2/16/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <RestKit/RestKit.h>

/**
 Defines optional callback methods for extending the functionality of the
 factory. Implementation can be provided via a category.

 @see RKTestFactory
 */
@protocol RKTestFactoryCallbacks <NSObject>

@optional

///-----------------------------------------------------------------------------
/// @name Customizing the Factory
///-----------------------------------------------------------------------------

/**
 Application specific initialization point for the factory.
 Called once per unit testing run when the factory singleton instance is initialized. RestKit
 applications may override via a category.
 */
+ (void)didInitialize;

/**
 Application specific customization point for the factory.
 Invoked each time the factory is asked to set up the environment. RestKit applications
 leveraging the factory may override via a category.
 */
+ (void)didSetUp;

/**
 Application specific customization point for the factory.
 Invoked each time the factory is tearing down the environment. RestKit applications
 leveraging the factory may override via a category.
 */
+ (void)didTearDown;

@end

/**
 RKTestFactory provides an interface for initializing RestKit
 objects within a unit testing environment. The factory is used to ensure isolation
 between test cases by ensuring that RestKit's important singleton objects are torn
 down between tests and that each test is working within a clean Core Data environment.
 Callback hooks are provided so that application specific set up and tear down logic can be
 integrated as well.
 */
@interface RKTestFactory : NSObject <RKTestFactoryCallbacks>

///-----------------------------------------------------------------------------
/// @name Configuring the Factory
///-----------------------------------------------------------------------------

/**
 Returns the base URL with which to initialize RKClient and RKObjectManager
 instances created via the factory.
 
 @return The base URL for the factory.
 */
+ (RKURL *)baseURL;

/**
 Sets the base URL for the factory.
 
 @param URL The new base URL.
 */
+ (void)setBaseURL:(RKURL *)URL;

/**
 Returns the base URL as a string value.
 
 @return The base URL for the factory, as a string.
 */
+ (NSString *)baseURLString;

/**
 Sets the base URL for the factory to a new value by constructing an RKURL
 from the given string.
 
 @param A string containing the URL to set as the base URL for the factory.
 */
+ (void)setBaseURLString:(NSString *)baseURLString;

///-----------------------------------------------------------------------------
/// @name Building Instances
///-----------------------------------------------------------------------------

/**
 Creates and returns an RKClient instance.
 
 @return A new client object.
 */
+ (RKClient *)client;

/**
 Creates and returns an RKObjectManager instance.
 
 @return A new client object.
 */
+ (RKObjectManager *)objectManager;

/**
 Creates and returns a RKManagedObjectStore instance.
 
 A new managed object store will be configured and returned. If there is an existing
 persistent store (i.e. from a previous test invocation), then the persistent store
 is deleted.
 
 @return A new managed object store object.
 */
+ (RKManagedObjectStore *)managedObjectStore;

///-----------------------------------------------------------------------------
/// @name Managing Test State
///-----------------------------------------------------------------------------

/**
 Sets up the RestKit testing environment. Invokes the didSetUp callback for application 
 specific setup.
 */
+ (void)setUp;

/**
 Tears down the RestKit testing environment by clearing singleton instances, helping to
 ensure test case isolation. Invokes the didTearDown callback for application specific
 cleanup.
 */
+ (void)tearDown;

///-----------------------------------------------------------------------------
/// @name Other Tasks
///-----------------------------------------------------------------------------

/**
 Clears the contents of the cache directory by removing the directory and
 recreating it.
 
 @see [RKDirectory cachesDirectory]
 */
+ (void)clearCacheDirectory;

@end
