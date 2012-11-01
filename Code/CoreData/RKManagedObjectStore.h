//
//  RKManagedObjectStore.h
//  RestKit
//
//  Created by Blake Watters on 9/22/09.
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

#import <CoreData/CoreData.h>
#import "RKEntityMapping.h"
#import "RKManagedObjectCaching.h"

@class RKManagedObjectStore;

/**
 The `RKManagedObjectStore` class encapsulates a Core Data stack including a managed object model, a persistent store coordinator, and a set of managed object contexts. The managed object store simplifies the task of properly setting up a Core Data stack and provides some additional functionality, such as the use of a seed database to initialize a SQLite backed persistent store and a simple code path for resetting the store by destroying and recreating the persistent stores.

 ## Initialization

 The managed object store is designed to easily initialize a Core Data stack in a recommended configuration. A store object must always be initialized with a managed object model, but this managed object model can be directly provided, inferred from an already configured persistent store coordinator, or read from the currently available bundles within the application. Note that several features provided by the framework rely on the store being initialized with a mutable managed object model. Please refer to the documentation in the `initWithManagedObjectModel:` for details.

 ## Managed Object Contexts

 The managed object store provides the application developer with a pair of managed objects with which to work with Core Data. The store configures a primary managed object context with the NSPrivateQueueConcurrencyType that is associated with the persistent store coordinator for handling Core Data persistence. A second context is also created with the NSMainQueueConcurrencyType that is a child of the primary managed object context for doing work on the main queue. Additional child contexts can be created directly or via a convenience method interface provided by the store (see newChildManagedObjectContextWithConcurrencyType:).

 The managed object context hierarchy is designed to isolate the main thread from disk I/O and avoid deadlocks. Because the primary context manages its own private queue, saving the main queue context will not result in the objects being saved to the persistent store. The primary context must be saved as well for objects to be persisted to disk.

 It is also worth noting that because of the parent/child context hierarchy, objects created on the main thread will not obtain permanent managed object ID's even after the primary context has been saved. If you need to refer to the permanent representations of objects created on the main thread after a save, you may ask the main queue context to obtain permanent managed objects for your objects via `obtainPermanentIDsForObjects:error:`. Be warned that when obtaining permanent managed object ID's, you must include all newly created objects that are reachable from the object you are concerned with in the set of objects provided to `obtainPermanentIDsForObjects:error:`. This means any newly created object in a one-to-one or one-to-many relationship must be provided or you will face a crash from the managed object context. This is due to a bug in Core Data still present in iOS5, but fixed in iOS6 (see Open Radar http://openradar.appspot.com/11478919).

 @see `NSManagedObjectContext (RKAdditions)`
 @see `NSEntityDescription (RKAdditions)`
 */
@interface RKManagedObjectStore : NSObject

///-----------------------------------------
/// @name Accessing the Default Object Store
///-----------------------------------------

/**
 Returns the default managed object store for the application.

 @return The default managed object store.
 */
+ (RKManagedObjectStore *)defaultStore;

/**
 Sets the default managed object store for the application.

 @param managedObjectStore The new default managed object store.
 */
+ (void)setDefaultStore:(RKManagedObjectStore *)managedObjectStore;

///-----------------------------------
/// @name Initializing an Object Store
///-----------------------------------

/**
 Initializes the receiver with a given managed object model. This is the designated initializer for `RKManagedObjectStore`.

 @param managedObjectModel The managed object model with which to initialize the receiver.
 @return The receiver, initialized with the given managed object model.
 @bug Several features require that the managed object model used to initialize the store be mutable so that entities may be changed before the persistent store coordinator is created. Since iOS 5, managed object models initialized via initWithContentsOfURL: return an immutable model. The application developer must send the returned managed object model a mutable copy message to ensure that it is mutable before initializing the managed object store. The recommended approach for initializing a managed object store is as follows:

    NSURL *modelURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"MyApplication" ofType:@"momd"]];
    // NOTE: Due to an iOS 5 bug, the managed object model returned is immutable.
    NSManagedObjectModel *managedObjectModel = [[[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL] mutableCopy];
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:managedObjectModel];
 
 */
- (id)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel;

/**
 Initializes the receiver with an existing persistent store coordinator.

 The managed object model from the persistent store coordinator will be used to initialize the receiver and the given persistent store coordinator will be configured as the persistent store coordinator for the managed object store.

 This initialization method provides for easy integration with an existing Core Data stack.

 @param persistentStoreCoordinator The persistent store coordinator with which to initialize the receiver.
 @return The receiver, initialized with the managed object model of the given persistent store coordinator and the persistent store coordinator.
 */
- (id)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator;

/**
 Initializes the receiver with a managed object model obtained by merging the models from all of the application's non-framework bundles.

 @see `[NSBundle allBundles]`
 @see `[NSManagedObjectModel mergedModelFromBundles:]`

 @warning Obtaining a managed object model by merging all bundles may result in an application error if versioned object models are in use.
 */
- (id)init;

///-----------------------------------------------------------------------------
/// @name Configuring Persistent Stores
///-----------------------------------------------------------------------------

/**
 Creates a persistent store coordinator with the receiver's managed object model. After invocation, the persistentStoreCoordinator property will no longer be nil.

 @warning Creating the persistent store coordinator will render the managed object model immutable. Attempts to use functionality that requires a mutable managed object model after the persistent store coordinator has been created will raise an application error.
 */
- (void)createPersistentStoreCoordinator;

/**
 Adds a new in memory persistent store to the persistent store coordinator of the receiver.

 This method will invoke createPersistentStore if a persistent store coordinator has not yet been created.

 @param error On input, a pointer to an error object. If an error occurs, this pointer is set to an actual error object containing the error information. You may specify nil for this parameter if you do not want the error information.
 @returns The new persistent store, or nil in the event of an error.
 */
- (NSPersistentStore *)addInMemoryPersistentStore:(NSError **)error;

/**
 Adds a new SQLite persistent store, optionally initialized with a seed database, to the persistent store coordinator of the receiver.

 @param storePath The path at which to save the persistent store on disk.
 @param seedPath An optional path to a seed database to copy to the given storePath in the event that a store does not yet exist.
 @param nilOrConfigurationName An optional name of a Core Data configuration in the managed object model.
 @param nilOrOptions An optional dictionary of options with which to configure the persistent store. If `nil`, a dictionary of options enabling `NSMigratePersistentStoresAutomaticallyOption` and `NSInferMappingModelAutomaticallyOption` will be used.
 @param error On input, a pointer to an error object. If an error occurs, this pointer is set to an actual error object containing the error information. You may specify nil for this parameter if you do not want the error information.

 @bug Note that when built for iOS, this method will set a resource value on the SQLite file backing the persistent store for the `NSURLIsExcludedFromBackupKey` key set to `YES` to exclude the SQLite file from being backed up by iCloud to conform with the ["iOS Data Storage Guidelines"](https://developer.apple.com/icloud/documentation/data-storage/)
 @warning If the seed database at the given path was created with an incompatible managed object model an application error may be raised.
 */
- (NSPersistentStore *)addSQLitePersistentStoreAtPath:(NSString *)storePath
                               fromSeedDatabaseAtPath:(NSString *)seedPath
                                    withConfiguration:(NSString *)nilOrConfigurationName
                                              options:(NSDictionary *)nilOrOptions
                                                error:(NSError **)error;

/**
 Resets the persistent stores in the receiver's persistent store coordinator and recreates them. If a store being reset is backed by a file on disk (such as a SQLite file), the file will be removed prior to recreating the store. If the store was originally created using a seed database, the seed will be recopied to reset the store to its seeded state.

 @param error On input, a pointer to an error object. If an error occurs, this pointer is set to an actual error object containing the error information. You may specify nil for this parameter if you do not want the error information.
 @return A Boolean value indicating if the reset was successful.

 @bug This method will implictly result in the managed object contexts associated with the receiver to be discarded and recreated. Any managed objects or additional child contexts associated with the store will need to be discarded or else exceptions may be raised (i.e. `NSObjectInaccessibleException`).

 Also note that care must be taken to cancel/suspend all mapping operations, reset all managed object contexts, and disconnect all `NSFetchedResultController` objects that are associated with managed object contexts using the persistent stores of the receiver before attempting a reset. Failure to completely disconnect usage before calling this method is likely to result in a deadlock.
 */
- (BOOL)resetPersistentStores:(NSError **)error;

///-----------------------------------------
/// @name Retrieving Details about the Store
///-----------------------------------------

/**
 Returns the managed object model of the receiver.

 @return The managed object model of the receiver.
 */
@property (nonatomic, strong, readonly) NSManagedObjectModel *managedObjectModel;

/**
 Returns the persistent store coordinator of the receiver.

 @return The persistent store coordinator of the receiver.
 */
@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

/**
 The managed object cache associated with the receiver.

 The managed object cache is used to accelerate intensive Core Data operations by caching managed objects by their primary key value.
 
 **Default**: An instance of `RKFetchRequestManagedObjectCache`.

 @see `RKManagedObjectCaching`
 @warning A nil managed object cache will result in a store that is unable to uniquely identify existing objects by primary key attribute value and may result in the creation of duplicate objects within the store.
 */
@property (nonatomic, strong) id<RKManagedObjectCaching> managedObjectCache;

///-------------------------------------------
/// @name Working with Managed Object Contexts
///-------------------------------------------

/**
 Creates the persistent store and main queue managed object contexts for the receiver.

 @see `persistentStoreManagedObjectContext`
 @see `mainQueueManagedObjectContext`
 @raises NSInternalInconsistencyException Raised if the managed object contexts have already been created.
 */
- (void)createManagedObjectContexts;

/**
 Returns the managed object context of the receiver that is associated with the persistent store coordinator and is responsible for managing persistence.

 The persistent store context is created with the `NSPrivateQueueConcurrencyType` and as such must be interacted with using `[NSManagedObjectContext performBlock:]` or `[NSManagedObjectContext performBlockAndWait:]`. This context typically serves as the parent context for scratch contexts or main queue contexts for interacting with the user interface. Created by the invocation of `createManagedObjectContexts`.

 @see `createManagedObjectContexts`
 */
@property (nonatomic, strong, readonly) NSManagedObjectContext *persistentStoreManagedObjectContext;

/**
 The main queue managed object context of the receiver.

 The main queue context is available for usage on the main queue to drive user interface needs. The context is created with the NSMainQueueConcurrencyType and as such may be messaged directly from the main thread. The context is a child context of the persistentStoreManagedObjectContext and can persist changes up to the parent via a save.
 */
@property (nonatomic, strong, readonly) NSManagedObjectContext *mainQueueManagedObjectContext;

/**
 Creates a new child managed object context of the persistent store managed object context with a given concurrency type.

 @param concurrencyType The desired concurrency type for the new context.
 @return A newly created managed object context with the given concurrency type whose parent is the `persistentStoreManagedObjectContext`.
 */
- (NSManagedObjectContext *)newChildManagedObjectContextWithConcurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType;

@end

// Option containing the path to the seed database a SQLite store was initialized with
extern NSString * const RKSQLitePersistentStoreSeedDatabasePathOption;
