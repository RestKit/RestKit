//
//  RKManagedObjectStore.h
//  RestKit
//
//  Created by Blake Watters on 9/22/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "RKManagedObject.h"
#import "RKManagedObjectCache.h"

/**
 * Notifications
 */
extern NSString* const RKManagedObjectStoreDidFailSaveNotification;

///////////////////////////////////////////////////////////////////

@interface RKManagedObjectStore : NSObject {
	NSString* _storeFilename;	
    NSManagedObjectModel* _managedObjectModel;
	NSPersistentStoreCoordinator* _persistentStoreCoordinator;
	NSObject<RKManagedObjectCache>* _managedObjectCache;
}

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
 * Initialize a new managed object store backed by a SQLite database with the specified filename. If a seed database name is provided
 * and no existing database is found, initialize the store by copying the seed database from the main bundle. If the managed object model
 * provided is nil, all models will be merged from the main bundle for you.
 */
+ (RKManagedObjectStore*)objectStoreWithStoreFilename:(NSString *)storeFilename usingSeedDatabaseName:(NSString *)nilOrNameOfSeedDatabaseInMainBundle managedObjectModel:(NSManagedObjectModel*)nilOrManagedObjectModel;

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
 * Retrieves a model object from the object store given the model object's class and
 * the primaryKeyValue for the model object. This method leverages techniques specific to 
 * Core Data for optimal performance. If an existing object is not found, a new object is created
 * and returned.
 */
- (RKManagedObject*)findOrCreateInstanceOfManagedObject:(Class)class withPrimaryKeyValue:(id)primaryKeyValue;

/**
 * Returns an array of objects that the 'live' at the specified resource path. Usage of this
 * method requires that you have provided an implementation of the managed object cache
 *
 * See managedObjectCache above
 */
- (NSArray*)objectsForResourcePath:(NSString*)resourcePath;

@end
