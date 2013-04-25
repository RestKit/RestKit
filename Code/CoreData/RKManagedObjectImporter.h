//
//  RKManagedObjectImporter.h
//  RestKit
//
//  Created by Blake Watters on 3/4/10.
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

@class RKMapping, RKObjectManager;
@protocol RKManagedObjectCaching;

/**
 Instances of `RKManagedObjectImporter` perform bulk imports of managed objects into a persistent store from source files (typically in JSON or XML format) using object mappings. The importer provides functionality for updating an existing persistent store or creating a seed database that can be used to bootstrap a new persistent store with an initial data set.

 The importer requires that the source files have a MIME type that is identifiable by file extension and be parsable using a parser registered with the shared parser registry.

 @see RKMIMETypeSerialization
 */
@interface RKManagedObjectImporter : NSObject

///-------------------------------
/// @name Initializing an Importer
///-------------------------------

/**
 Initializes the receiver with a given managed object model and a path at which a SQLite persistent store
 should be created to persist imported managed objects.

 When initialized with a managed object model and store path, the receiver will construct an internal
 persistent store coordinator, SQLite persistent store, and managed object context with the private queue
 concurrency type with which to perform the importing.

 @param managedObjectModel A Core Data manage object model with which to initialize the receiver.
 @param storePath The path at which to create a SQLite persistent store to persist the imported managed objects.
 @return The receiver, initialized with the given managed object model and a complete Core Data persistence
    stack with a SQLite persistent store at the given store path.

 @warning As this initialization code path is typical for generating seed databases, the value of
    `resetsStoreBeforeImporting` is initialized to **YES**.
 */
- (id)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel storePath:(NSString *)storePath;

/**
 Initializes the receiver with a given persistent store in which to persist imported managed objects.

 When initialized with a persistent store, the receiver will construct a managed object context with the
 private queue concurrency type and the persistent store coordinator of the given persistent store. This
 prepares the receiver for importing content into an existing Core Data persistence stack.

 @param persistentStore A Core Data persistent store with which to initialize the receiver.
 @return The receiver, initialized with the given persistent store. The persistent store coordinator and
    managed object model are determined from the given persistent store and a new managed object context with
    the private queue concurrency type is constructed.
 */
- (id)initWithPersistentStore:(NSPersistentStore *)persistentStore;

/**
 A Boolean value indicating whether existing managed objects in the persistent store should
 be deleted before import.

 The default value of this property is YES if the receiver was initialized with a
 managed object model and store path, else NO.
 */
@property (nonatomic, assign) BOOL resetsStoreBeforeImporting;

///----------------------------------
/// @name Accessing Core Data Details
///----------------------------------

/**
 The persistent store in which imported managed objects will be persisted.
 */
@property (nonatomic, strong, readonly) NSPersistentStore *persistentStore;

/**
 The managed object model containing entities that may be imported by the receiver.
 */
@property (nonatomic, strong, readonly) NSManagedObjectModel *managedObjectModel;

/**
 A managed object context with the NSPrivateQueueConcurrencyType concurrency type
 used to perform the import.
 */
@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;

/**
 A convenience accessor for retrieving the complete filesystem path to the persistent
 store in which the receiver will persist imported managed objects.

 Equivalent to executing the following example code:

    NSURL *URL = [importer.persistentStore.persistentStoreCoordinator URLForPersistentStore:importer.persistentStore];
    return [URL path];
 
 */
@property (nonatomic, strong, readonly) NSString *storePath;

/**
 A class that conforms to the `RKManagedObjectCaching` protocol that should be used when performing the import.
 
 **Default**: An instance of `RKInMemoryManagedObjectCache`.
 */
@property (nonatomic, strong) id<RKManagedObjectCaching> managedObjectCache;

///-----------------------------------------------------------------------------
/// @name Importing Managed Objects
///-----------------------------------------------------------------------------

/**
 Imports managed objects from the file or directory at the given path.

 @param path The path to the file or directory you wish to import. This parameter must not be nil.
 @param mapping The entity or dynamic mapping you wish to use for importing content at the given path.
 @param keyPath An optional key path to be evaluated against the results of parsing the content read at the given path. If the
    mappable content is not contained in a nesting attribute, the key path should be specified as nil.
 @param error On input, a pointer to an error object. If an error occurs, this pointer is set to an actual error object containing
    the error information. You may specify nil for this parameter if you do not want the error information.
 @return A count of the number of managed object imported from the given path or NSNotFound if an error occurred during import.
 */
- (NSUInteger)importObjectsFromItemAtPath:(NSString *)path withMapping:(RKMapping *)mapping keyPath:(NSString *)keyPath error:(NSError **)error;

/**
 Finishes the import process by saving the managed object context to the persistent store, ensuring all
 imported managed objects are written to disk.

 @param error On input, a pointer to an error object. If an error occurs, this pointer is set to an actual error object containing
 the error information. You may specify nil for this parameter if you do not want the error information.
 @return YES if the save to the persistent store was successful, else NO.
 */
- (BOOL)finishImporting:(NSError **)error;

///-----------------------------------------------------------------------------
/// @name Obtaining Seeding Info
///-----------------------------------------------------------------------------

/**
 Logs information about where on the filesystem to access the SQLite database for the persistent
 store in which the imported managed objects were persisted.
 */
- (void)logSeedingInfo;

@end
