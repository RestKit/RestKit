//
//  RKManagedObjectStore.h
//  RestKit
//
//  Created by Blake Watters on 9/22/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import <CoreData/CoreData.h>

/**
 * Notifications
 */
extern NSString* const RKManagedObjectStoreDidFailSaveNotification;

///////////////////////////////////////////////////////////////////

@interface RKManagedObjectStore : NSObject {
	NSString* _storeFilename;	
    NSManagedObjectModel* _managedObjectModel;
	NSPersistentStoreCoordinator* _persistentStoreCoordinator;
    NSManagedObjectContext* _managedObjectContext;
}

@property (nonatomic, readonly) NSString* storeFilename;
@property (nonatomic, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

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

@end
