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

@property (nonatomic, readonly) NSString* storeFilename;
@property (nonatomic, readonly) NSManagedObjectModel* managedObjectModel;
@property (nonatomic, readonly) NSPersistentStoreCoordinator* persistentStoreCoordinator;
@property (nonatomic, retain) NSObject<RKManagedObjectCache>* managedObjectCache;

/*
 * This returns an appropriate managed object context for this object store.
 * Because of the intrecacies of how CoreData works across threads it returns
 * a different NSManagedObjectContext for each thread.
 */
@property (nonatomic, readonly) NSManagedObjectContext* managedObjectContext;

/**
 * Initialize a new managed object store with a SQLite database with the filename specified
 */
- (id)initWithStoreFilename:(NSString*)storeFilename;

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


@end
