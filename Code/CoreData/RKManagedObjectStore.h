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
#import "RKManagedObjectMapping.h"
#import "RKManagedObjectCaching.h"

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

///-----------------------------------------------------------------------------
/// @name Accessing the Default Object Store
///-----------------------------------------------------------------------------

+ (RKManagedObjectStore *)defaultObjectStore;
+ (void)setDefaultObjectStore:(RKManagedObjectStore *)objectStore;

///-----------------------------------------------------------------------------
/// @name Deleting Store Files
///-----------------------------------------------------------------------------

/**
 Deletes the SQLite file backing an RKManagedObjectStore instance at a given path.

 @param path The complete path to the store file to delete.
 */
+ (void)deleteStoreAtPath:(NSString *)path;

/**
 Deletes the SQLite file backing an RKManagedObjectStore instance with a given
 filename within the application data directory.

 @param filename The name of the file within the application data directory backing a managed object store.
 */
+ (void)deleteStoreInApplicationDataDirectoryWithFilename:(NSString *)filename;

///-----------------------------------------------------------------------------
/// @name Initializing an Object Store
///-----------------------------------------------------------------------------

/**

 */
@property (nonatomic, retain) NSObject<RKManagedObjectCaching> *cacheStrategy;

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
- (BOOL)save:(NSError **)error;

/**
 * This deletes and recreates the managed object context and
 * persistent store, effectively clearing all data
 */
- (void)deletePersistentStoreUsingSeedDatabaseName:(NSString *)seedFile;
- (void)deletePersistentStore;

/**
 *	Retrieves a model object from the appropriate context using the objectId
 */
- (NSManagedObject*)objectWithID:(NSManagedObjectID*)objectID;

/**
 *	Retrieves a array of model objects from the appropriate context using
 *	an array of NSManagedObjectIDs
 */
- (NSArray*)objectsWithIDs:(NSArray*)objectIDs;

///-----------------------------------------------------------------------------
/// @name Retrieving Managed Object Contexts
///-----------------------------------------------------------------------------

/**
 Retrieves the Managed Object Context for the main thread that was initialized when
 the object store was created. 
 
 This context uses the NSMainQueueConcurrencyType to allow
 you to create child contexts for passing between UIViewControllers, allowing 
 the view to save its changes (which are passed back to the parent context) or 
 discard them. 
 
 Warning: Do not attempt to use the primary context or any child contexts on
 other threads, unless done via performBlock: or performBlockAndWait: 
 You should ask for a context for the current thread @see managedObjectContextForCurrentThread
 */
@property (nonatomic, retain, readonly) NSManagedObjectContext *primaryManagedObjectContext;

/**
 Creates a new child Managed Object Context suitable for use on the main UI thread.
 This context can handle object insertions or modifications without making those changes
 visible anywhere else in the application. In this example a controller that creates
 a new object is initialized with a child context so the new object it creates is 
 not made visible (no need to delete it should the user cancel the operation, nor will
 it show up as a result of an NSFetchedResultsController's change notifications)
 
 NewItemViewController *controller = [NewItemViewController controllerWithContext:[store newChildManagedObjectContext]];
 [self.navigationController pushViewController:controller animated:YES];
 
 
 Although you can make calls without using performBlock: (since the concurrency type is MainQueue),
 it is still considered best practice by Apple to do so. This call to save: will
 propagate the pending changes up to the parent context (the primary in this case). 
 To persist those changes to the persistent store you must call save: on it as well.
 
 [childContext performBlockAndWait:^{
    [childContext save:nil];
    [childContext.parentContext performBlockAndWait:^{
        childContext.parentContext save:nil];
    }];
 }];
 */
- (NSManagedObjectContext *)newChildManagedObjectContext;

/**
 Instantiates a new managed object context
 */
- (NSManagedObjectContext *)newManagedObjectContext;

/*
 * This returns an appropriate managed object context for this object store.
 * Because of the intrecacies of how Core Data works across threads it returns
 * a different NSManagedObjectContext for each thread.
 */
- (NSManagedObjectContext *)managedObjectContextForCurrentThread;

@end
