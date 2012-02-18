//
//  RKTestFactory.h
//  RKGithub
//
//  Created by Blake Watters on 2/16/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <RestKit/RestKit.h>

/**
 RKTestFactory provides an interface for initializing RestKit
 objects within a unit testing environment.
 */
@interface RKTestFactory : NSObject

///-----------------------------------------------------------------------------
/// @name Configuring the Factory
///-----------------------------------------------------------------------------

/**
 The baseURL with which to initialize RKClient and RKObjectManager
 instances created via the factory.
 */
@property (nonatomic, strong) RKURL *baseURL;

/**
 The class to use when instantiating new client instances.
 
 **Default**: [RKClient class]
 */
@property (nonatomic, strong) Class clientClass;

/**
 The class to use when instantiating new object manager instances.
 
 **Default**: [RKObjectManager class]
 */
@property (nonatomic, strong) Class objectManagerClass;

///-----------------------------------------------------------------------------
/// @name Accessing the Shared Factory Instance
///-----------------------------------------------------------------------------

/**
 Returns the shared test factory object.
 
 @return The shared test factory.
 */
+ (RKTestFactory *)sharedFactory;

///-----------------------------------------------------------------------------
/// @name Building Instances
///-----------------------------------------------------------------------------

/**
 Create and return an RKClient instance.
 */
- (RKClient *)client;

/**
 Create and return an RKObjectManager instance.
 */
- (RKObjectManager *)objectManager;

/**
 Create and return an RKManagedObjectStore instance.
 */
- (RKManagedObjectStore *)objectStore;

/**
 Sets up the RestKit testing environment. Invokes the didSetUp callback for application 
 specific setup.
 */
- (void)setUp;

/**
 Tears down the RestKit testing environment by clearing singleton instances, helping to
 ensure test case isolation. Invokes the didTearDown callback for application specific
 cleanup.
 */
- (void)tearDown;

///-----------------------------------------------------------------------------
/// @name Customizing the Factory
///-----------------------------------------------------------------------------

/**
 Application specific initialization point for the sharedFactory.
 Called once per unit testing run when the sharedFactory instance is initialized. RestKit
 applications can override via a category.
 */
- (void)didInitialize;

/**
 Application specific customization point for the sharedFactory.
 Invoked each time the factory is asked to set up the environment. RestKit applications
 leveraging the factory may override via a category.
 */
- (void)didSetUp;

/**
 Application specific customization point for the sharedFactory.
 Invoked each time the factory is tearing down the environment. RestKit applications
 leveraging the factory may override via a category.
 */
- (void)didTearDown;

@end

/**
 Provides a static interface for common tasks on the RKTestFactory
 sharedInstance. All methods are static aliases for instance method
 counterparts on [RKTestFactory sharedFactory]
 */
@interface RKTestFactory (ConvenienceAliases)

/**
 Ensures the test factory has been initialized
 */
+ (void)setUp;
+ (void)tearDown;

+ (RKURL *)baseURL;
+ (void)setBaseURL:(RKURL *)URL;
+ (NSString *)baseURLString;
+ (void)setBaseURLString:(NSString *)baseURLString;

+ (RKClient *)client;
+ (RKObjectManager *)objectManager;
+ (RKManagedObjectStore *)objectStore;

@end
