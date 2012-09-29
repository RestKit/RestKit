//
//  RKTestFactory.h
//  RestKit
//
//  Created by Blake Watters on 2/16/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <CoreData/CoreData.h>

/**
 The default filename used for managed object stores created via the factory.

 @see `[RKTestFactory setManagedObjectStoreFilename:]`
 */
extern NSString * const RKTestFactoryDefaultStoreFilename;

/**
 Defines optional callback methods for extending the functionality of the factory. Implementation can be provided via a category.

 @see `RKTestFactory`
 */
@protocol RKTestFactoryCallbacks <NSObject>

@optional

///------------------------------
/// @name Customizing the Factory
///------------------------------

/**
 Application specific initialization point for the factory.
 
 Called once per unit testing run when the factory singleton instance is initialized. RestKit applications may override via a category.
 */
+ (void)didInitialize;

/**
 Application specific customization point for the factory.
 
 Invoked each time the factory is asked to set up the environment. RestKit applications leveraging the factory may override via a category.
 */
+ (void)didSetUp;

/**
 Application specific customization point for the factory.
 
 Invoked each time the factory is tearing down the environment. RestKit applications leveraging the factory may override via a category.
 */
+ (void)didTearDown;

@end

/*
 Default Factory Names
 */
extern NSString * const RKTestFactoryDefaultNamesClient;
extern NSString * const RKTestFactoryDefaultNamesObjectManager;
extern NSString * const RKTestFactoryDefaultNamesManagedObjectStore;

/**
 The `RKTestFactory` class provides an interface for initializing RestKit objects within a unit testing environment. The factory is used to ensure isolation between test cases by ensuring that RestKit's important singleton objects are torn down between tests and that each test is working within a clean Core Data environment. Callback hooks are provided so that application specific set up and tear down logic can be integrated as well.

 The factory also provides for the definition of named factories for instantiating objects quickly. At initialization, there are factories defined for creating instances of `AFHTTPClient`, `RKObjectManager`, and `RKManagedObjectStore`. These factories may be redefined within your application should you choose to utilize a subclass or wish to centralize configuration of objects across the test suite. You may also define additional factories for building instances of objects specific to your application using the same infrastructure.
 */
@interface RKTestFactory : NSObject <RKTestFactoryCallbacks>

///------------------------------
/// @name Configuring the Factory
///------------------------------

/**
 Returns the base URL with which to initialize `AFHTTPClient` and `RKObjectManager` instances created via the factory.

 @return The base URL for the factory.
 */
+ (NSURL *)baseURL;

/**
 Sets the base URL for the factory.

 @param URL The new base URL.
 */
+ (void)setBaseURL:(NSURL *)URL;

/**
 Returns the base URL as a string value.

 @return The base URL for the factory, as a string.
 */
+ (NSString *)baseURLString;

/**
 Sets the base URL for the factory to a new value by constructing an RKURL
 from the given string.

 @param baseURLString A string containing the URL to set as the base URL for the factory.
 */
+ (void)setBaseURLString:(NSString *)baseURLString;

/**
 Returns the filename used when constructing instances of `RKManagedObjectStore` via the factory.

 @return A string containing the filename to use when creating a managed object store.
 */
+ (NSString *)managedObjectStoreFilename;

/**
 Sets the filename to use when the factory constructs an instance of `RKManagedObjectStore`.

 @param managedObjectStoreFilename A string containing the filename to use when creating managed object store instances.
 */
+ (void)setManagedObjectStoreFilename:(NSString *)managedObjectStoreFilename;

///-----------------------------------------------------------------------------
/// @name Defining & Instantiating Objects from Factories
///-----------------------------------------------------------------------------

/**
 Defines a factory with a given name for building object instances using the
 given block. When the factory singleton receives an objectFromFactory: message,
 the block designated for the given factory name is invoked and the resulting object
 reference is returned.

 Existing factories can be invoking defineFactory:withBlock: with an existing factory name.

 @param factoryName The name to assign the factory.
 @param block A block to execute when building an object instance for the factory name.
 @return A configured object instance.
 */
+ (void)defineFactory:(NSString *)factoryName withBlock:(id (^)())block;

/**
 Creates and returns a new instance of an object using the factory with the given name.

 @param factoryName The name of the factory to use when building the requested object.
 @raises NSInvalidArgumentException Raised if a factory with the given name is not defined.
 @param properties An `NSDictionary` of properties to be set on the created object.
 @return An object built using the factory registered for the given name.
 */
+ (id)objectFromFactory:(NSString *)factoryName properties:(NSDictionary *)properties;
+ (id)objectFromFactory:(NSString *)factoryName;

/**
 Fetches a shared object from the factory with the given name. If an existing object has already been created, then that instance is returned. If a shared instance does not yet exist, one will be constructed and returned for this and all subsequent invocations of `sharedObjectFromFactory:`. Shared object instances are discarded when the factory is torn down.

 Shared objects are used to return object instances for cases where it does not make sense to instantiate a new instance on every invocation of the factory. A common example where this is appropriate is the `managedObjectStore` factory, where construction of a new store on each invocation would yield managed objects that cross Core Data stacks.

 @param factoryName The name of the factory to retrieve the shared instance of.
 @return The shared object instance for the factory registered with the given name.
 */
+ (id)sharedObjectFromFactory:(NSString *)factoryName;

/**
 Inserts a new managed object for the `NSEntityDescription` with the given name into the specified  managed object context and sets properties on the instance from the given dictionary. A permanent managed object ID is obtained for the object so that it can be referenced across threads without any further work.
 
 @param entityName The name of the entity to insert a new managed object for.
 @param managedObjectContext The managed object context to insert the new object into. If nil, then the managed object context returned by invoking `[RKTestFactory managedObjectStore].mainQueueManagedObjectContext]` is used.
 @param properties A dictionary of properties to be set on the new managed object instance.
 @return A new object inheriting from `NSManagedObject`.
 */
+ (id)insertManagedObjectForEntityForName:(NSString *)entityName
                   inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
                           withProperties:(NSDictionary *)properties;

/**
 Returns a set of names for all defined factories.

 @return A set of the string names for all defined factories.
 */
+ (NSSet *)factoryNames;

///--------------------------------
/// @name Retrieving Shared Objects
///--------------------------------

/**
 Fetches the shared `AFHTTPClient` object using the factory defined for the name `RKTestFactoryDefaultNamesClient`.

 @return The shared client instance.
 */
+ (id)client;

/**
 Fetches the shared `RKObjectManager` object using the factory defined for the name `RKTestFactoryDefaultNamesObjectManager`.

 @return The shared object manager instance.
 */
+ (id)objectManager;

/**
 Fetches the shared an `RKManagedObjectStore` object using the factory defined for the name `RKTestFactoryDefaultNamesManagedObjectStore`.

 On first invocation per factory setup/teardown, a new managed object store will be configured and returned. If there is an existing persistent store (i.e. from a previous test invocation), then the persistent store is deleted.

 @return The shared managed object store instance.
 */
+ (id)managedObjectStore;

///-----------------------------------------------------------------------------
/// @name Managing Test State
///-----------------------------------------------------------------------------

/**
 Sets up the RestKit testing environment. Invokes the `didSetUp` callback for application specific setup.
 */
+ (void)setUp;

/**
 Tears down the RestKit testing environment by clearing singleton instances, helping to ensure test case isolation. Invokes the `didTearDown` callback for application specific cleanup.
 */
+ (void)tearDown;

///------------------
/// @name Other Tasks
///------------------

/**
 Clears the contents of the cache directory by removing the directory and recreating it.
 
 This has the effect of clearing any `NSCachedURLResponse` objects stored by `NSURLCache` as well as any application specific cache data.

 @see `RKCachesDirectory()`
 */
+ (void)clearCacheDirectory;

@end
