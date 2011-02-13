//
//  RKObjectSeeder.h
//  RestKit
//
//  Created by Blake Watters on 3/4/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "../ObjectMapping/ObjectMapping.h"

/**
 * The object seeder provides support for creating a pre-filled Core Data
 * database suitable for shipping with your application at App Store submission 
 * time.
 */
@interface RKObjectSeeder : NSObject {
	RKObjectManager* _manager;
}

/**
 * Returns a new auto-released object manager
 */
+ (RKObjectSeeder*)seederWithObjectManager:(RKObjectManager*)manager;

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
