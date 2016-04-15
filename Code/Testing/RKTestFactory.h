//
//  RKTestFactory.h
//  RestKit
//
//  Created by Blake Watters on 2/16/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#ifdef _COREDATADEFINES_H
#if __has_include("RKCoreData.h")
#define RKCoreDataIncluded
#endif
#endif

/**
 The default filename used for managed object stores created via the factory.
 */
extern NSString * const RKTestFactoryDefaultStoreFilename;

/*
 Default Factory Names
 */
extern NSString * const RKTestFactoryDefaultNamesClient;
extern NSString * const RKTestFactoryDefaultNamesObjectManager;
extern NSString * const RKTestFactoryDefaultNamesManagedObjectStore;

@class RKManagedObjectStore;

/**
 The `RKTestFactory` class provides an interface for initializing RestKit objects within a unit testing environment. The factory is used to ensure isolation between test cases by ensuring that RestKit's important singleton objects are torn down between tests and that each test is working within a clean Core Data environment. Callback hooks are provided so that application specific set up and tear down logic can be integrated as well.

 The factory also provides for the definition of named factories for instantiating objects quickly. At initialization, there are factories defined for creating instances of `AFHTTPClient`, `RKObjectManager`, and `RKManagedObjectStore`. These factories may be redefined within your application should you choose to utilize a subclass or wish to centralize configuration of objects across the test suite. You may also define additional factories for building instances of objects specific to your application using the same infrastructure.

 ## Customizing the Factory

 The test factory is designed to be customized via an Objective-C category. All factory methods are implemented using blocks that have sensible defaults, but can be overridden by providing an alternate implementation. To do so, implement a category on the `RKTestFactory` class and provide an implementation of the `+ (void)load` method. Within the method body, configure your blocks as you see fit. An example implementation is provided below:

    @interface RKTestFactory (MyApp)

    // Create a convenience method for retrieving an object from the factory
    + (GGAirport *)ohareAirport;
    @end

    @implementation RKTestFactory (MyApp)

    + (void)load
    {
        [self setSetUpBlock:{
            // I am called on every invocation of `setUp`!
        }];

        // Replace the default object manager factory
        [RKTestFactory defineFactory:RKTestFactoryDefaultNamesObjectManager withBlock:^id {
            GGObjectManager *objectManager = [[GGObjectManager alloc] initWithBaseURL:[self baseURL]];
            return objectManager;
         }];

        // Define a new factory called 'ORD' that returns a representation of Chicago's O'Hare Airport
        [RKTestFactory defineFactory:@"ORD" withBlock:^id{
            GGAirport *ord = [RKTestFactory insertManagedObjectForEntityForName:@"Airport" inManagedObjectContext:nil withProperties:nil];
            ord.airportID = @16;
            ord.name = @"Chicago O'Hare International Airport";
            ord.code = @"ORD";
            ord.city = @"Chicago";
            ord.favorite = @(YES);
            ord.timeZoneName = @"America/Chicago";
            ord.latitude = @(41.9781);
            ord.longitude = @(-87.9061);

            return ord;
         }];
    }

    + (GGAirport *)ohareAirport
    {
        return [self objectFromFactory:@"ORD"];
    }

    @end
 */
@interface RKTestFactory : NSObject

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

#ifdef RKCoreDataIncluded
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
#endif

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

#ifdef RKCoreDataIncluded
/**
 Fetches the shared an `RKManagedObjectStore` object using the factory defined for the name `RKTestFactoryDefaultNamesManagedObjectStore`.

 On first invocation per factory setup/teardown, a new managed object store will be configured and returned. If there is an existing persistent store (i.e. from a previous test invocation), then the persistent store is deleted.

 @return The shared managed object store instance.
 */
+ (RKManagedObjectStore *)managedObjectStore;
#endif

///----------------------------------------------
/// @name Configuring Set Up and Tear Down Blocks
///----------------------------------------------

/**
 Sets a block to be executed when the `setUp` method is called as part of a test run.
 */
+ (void)setSetupBlock:(void (^)())block;

/**
 Sets a block to be executed when the `tearDown` method is called as part of a test run.
 */
+ (void)setTearDownBlock:(void (^)())block;

///--------------------------
/// @name Managing Test State
///--------------------------

/**
 Sets up the RestKit testing environment. Executes the block set via `setSetupBlock:` to perform application specific setup.

 Note that the firt time that the `setUp` method is invoked, it will execute a `tearDown` to clear any configuration that may have taken place in during application launch.
 */
+ (void)setUp;

/**
 Tears down the RestKit testing environment by clearing singleton instances, helping to ensure test case isolation. Executes the block set via `setTearDownBlock:` to perform application specific cleanup.
 */
+ (void)tearDown;

@end
