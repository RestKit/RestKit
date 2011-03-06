<<<<<<< .mine
//
//  RKManagedObjectSeeder.h
//  RestKit
//
//  Created by Blake Watters on 3/4/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "../ObjectMapping/ObjectMapping.h"

// The default seed database filename. Used when the object store has not been initialized
extern NSString* const RKDefaultSeedDatabaseFileName;

@protocol RKManagedObjectSeederDelegate
@required

// Invoked when the seeder creates a new object
- (void)didSeedObject:(NSObject<RKObjectMappable>*)object fromFile:(NSString*)fileName;
@end

/**
 * Provides an interface for generating a seed database suitable for initializing
 * a Core Data backed RestKit application. The object seeder loads files from the
 * application's main bundle and processes them with the Object Mapper to produce
 * a database on disk. This file can then be copied into the main bundle of an application
 * and provided to RKManagedObjectStore at initialization to start the app with a set of
 * data immediately available for use within Core Data.
 */
@interface RKManagedObjectSeeder : NSObject {
	RKObjectManager* _manager;
    NSObject<RKManagedObjectSeederDelegate>* _delegate;
}

// Delegate for seeding operations
@property (nonatomic, assign) NSObject<RKManagedObjectSeederDelegate>* delegate;

// Path to the generated seed database on disk
@property (nonatomic, readonly) NSString* pathToSeedDatabase;

/**
 * Generates a seed database using an object manager and a null terminated list of files. Exits
 * the seeding process and outputs an informational message
 */
+ (void)generateSeedDatabaseWithObjectManager:(RKObjectManager*)objectManager fromFiles:(NSString*)fileName, ...;

/**
 * Returns an object seeder ready to begin seeding. Requires a fully configured instance of an object manager.
 */
+ (RKManagedObjectSeeder*)objectSeederWithObjectManager:(RKObjectManager*)objectManager;

/**
 * Seed the database with objects from the specified file(s). The list must be terminated by nil
 */
- (void)seedObjectsFromFiles:(NSString*)fileName, ...;

/**
 * Seed the database with objects from the specified file. Optionally use the specified mappable class and
 * keyPath to traverse the object graph before seeding
 */
- (void)seedObjectsFromFile:(NSString*)fileName toClass:(Class<RKObjectMappable>)nilOrMppableClass keyPath:(NSString*)nilOrKeyPath;

/**
 * Completes a seeding session by persisting the store, outputing an informational message
 * and exiting the process
 */
- (void)finalizeSeedingAndExit;

@end
=======
//
//  RKObjectSeeder.h
//  RestKit
//
//  Created by Blake Watters on 3/4/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "../ObjectMapping/ObjectMapping.h"

// TODO: This class needs an API scrubbing
// TODO: Should be updated with ability to auto-detect MIME type
// from the file extension. Does this need a delegate property?
@interface RKObjectSeeder : NSObject {
	RKObjectManager* _manager;
}

/**
 * Initialize a new object seeder
 */
- (id)initWithObjectManager:(RKObjectManager*)manager;

/**
 * Read a file from the main bundle and seed the database with its contents.
 * Returns the array of model objects built from the file.
 */
- (NSArray*)seedDatabaseWithBundledFile:(NSString*)fileName ofType:(NSString*)type;

/**
 * Seeds the database with an array of files of the specified type
 */
- (void)seedDatabaseWithBundledFiles:(NSArray*)fileNames ofType:(NSString*)type;

/**
 * Seed a specific object class with data from a file
 */
- (void)seedObjectsFromFile:(NSString*)fileName ofType:(NSString*)type toClass:(Class)theClass keyPath:(NSString*)keyPath;

/**
 * Completes a seeding session by persisting the store, outputing an informational message
 * and exiting the process
 */
- (void)finalizeSeedingAndExit;

@end
>>>>>>> .r450
