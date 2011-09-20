//
//  RKManagedObjectStore.h
//  RestKit
//
//  Created by Blake Watters on 9/22/09.
//  Copyright 2009 Two Toasters
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
#import "RKManagedObjectCache.h"

@class RKManagedObjectStore;

/**
 * Notifications
 */
extern NSString* const RKManagedObjectStoreDidFailSaveNotification;

///////////////////////////////////////////////////////////////////

@protocol RKManagedObjectStoreDelegate
@optional

- (void)managedObjectStore:(RKManagedObjectStore *)objectStore didFailToCreatePersistentStoreCoordinatorWithError:(NSError *)error;

- (void)managedObjectStore:(RKManagedObjectStore *)objectStore didFailToDeletePersistentStore:(NSString *)pathToStoreFile error:(NSError *)error;

- (void)managedObjectStore:(RKManagedObjectStore *)objectStore didFailToCopySeedDatabase:(NSString *)seedDatabase error:(NSError *)error;

- (void)managedObjectStore:(RKManagedObjectStore *)objectStore didFailToSaveContext:(NSManagedObjectContext *)context error:(NSError *)error exception:(NSException *)exception;

@end

///////////////////////////////////////////////////////////////////

@interface RKManagedObjectStore : NSObject {
	NSObject<RKManagedObjectStoreDelegate>* _delegate;
	NSString* _storeFilename;
	NSString* _pathToStoreFile;
    NSManagedObjectModel* _managedObjectModel;
	NSPersistentStoreCoordinator* _persistentStoreCoordinator;
	NSObject<RKManagedObjectCache>* _managedObjectCache;
}

// The delegate for this object store
@property (nonatomic, assign) NSObject<RKManagedObjectStoreDelegate>* delegate;

// The filename of the database backing this object store
@property (nonatomic, readonly) NSString* storeFilename;

// The full path to the database backing this object store
@property (nonatomic, readonly) NSString* pathToStoreFile;

// Core Data
@property (nonatomic, readonly) NSManagedObjectModel* managedObjectModel;
@property (nonatomic, readonly) NSPersistentStoreCoordinator* persistentStoreCoordinator;

/**
 * Managed object cache provides support for automatic removal of objects pruned
 * from a server side load. Also used to provide offline object loading
 */
@property (nonatomic, retain) NSObject<RKManagedObjectCache>* managedObjectCache;

/*
 * This returns an appropriate managed object context for this object store.
 * Because of the intrecacies of how Core Data works across threads it returns
 * a different NSManagedObjectContext for each thread.
 */
@property (nonatomic, readonly) NSManagedObjectContext* managedObjectContext;

/**
 * Initialize a new managed object store with a SQLite database with the filename specified
 */
+ (RKManagedObjectStore*)objectStoreWithStoreFilename:(NSString*)storeFilename;

/**
 * Initialize a new managed object store backed by a SQLite database with the specified filename.
 * If a seed database name is provided and no existing database is found, initialize the store by
 * copying the seed database from the main bundle. If the managed object model provided is nil,
 * all models will be merged from the main bundle for you.
 */
+ (RKManagedObjectStore*)objectStoreWithStoreFilename:(NSString *)storeFilename usingSeedDatabaseName:(NSString *)nilOrNameOfSeedDatabaseInMainBundle managedObjectModel:(NSManagedObjectModel*)nilOrManagedObjectModel delegate:(id)delegate;

/**
 * Initialize a new managed object store backed by a SQLite database with the specified filename,
 * in the specified directory. If no directory is specified, will use the app's Documents
 * directory. If a seed database name is provided and no existing database is found, initialize
 * the store by copying the seed database from the main bundle. If the managed object model
 * provided is nil, all models will be merged from the main bundle for you.
 */
+ (RKManagedObjectStore*)objectStoreWithStoreFilename:(NSString *)storeFilename inDirectory:(NSString *)directory usingSeedDatabaseName:(NSString *)nilOrNameOfSeedDatabaseInMainBundle managedObjectModel:(NSManagedObjectModel*)nilOrManagedObjectModel delegate:(id)delegate;

/**
 * Initialize a new managed object store with a SQLite database with the filename specified
 * @deprecated
 */
- (id)initWithStoreFilename:(NSString*)storeFilename DEPRECATED_ATTRIBUTE;

/**
 * Save the current contents of the managed object store
 */
- (NSError*)save;

/**
 * This deletes and recreates the managed object context and 
 * persistant store, effectively clearing all data
 */
- (void)deletePersistantStoreUsingSeedDatabaseName:(NSString *)seedFile;
- (void)deletePersistantStore;

/**
 *	Retrieves a model object from the appropriate context using the objectId
 */
- (NSManagedObject*)objectWithID:(NSManagedObjectID*)objectID;

/**
 *	Retrieves a array of model objects from the appropriate context using
 *	an array of NSManagedObjectIDs
 */
- (NSArray*)objectsWithIDs:(NSArray*)objectIDs;

/**
 * Retrieves a model object from the object store given a Core Data entity and
 * the primary key attribute and value for the desired object. Internally, this method
 * constructs a thread-local cache of managed object instances to avoid repeated fetches from the store
 */
- (NSManagedObject*)findOrCreateInstanceOfEntity:(NSEntityDescription*)entity withPrimaryKeyAttribute:(NSString*)primaryKeyAttribute andValue:(id)primaryKeyValue;

/**
 * Returns an array of objects that the 'live' at the specified resource path. Usage of this
 * method requires that you have provided an implementation of the managed object cache
 *
 * See managedObjectCache above
 */
- (NSArray*)objectsForResourcePath:(NSString*)resourcePath;

@end
