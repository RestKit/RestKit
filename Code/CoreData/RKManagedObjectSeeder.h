//
//  RKManagedObjectSeeder.h
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

#import "ObjectMapping.h"

// The default seed database filename. Used when the object store has not been initialized
extern NSString * const RKDefaultSeedDatabaseFileName;

@protocol RKManagedObjectSeederDelegate
@required

// Invoked when the seeder creates a new object
- (void)didSeedObject:(NSManagedObject *)object fromFile:(NSString *)fileName;
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
    RKObjectManager *_manager;
}

// Delegate for seeding operations
@property (nonatomic, assign) NSObject<RKManagedObjectSeederDelegate> *delegate;

// Path to the generated seed database on disk
@property (nonatomic, readonly) NSString *pathToSeedDatabase;

/**
 * Generates a seed database using an object manager and a null terminated list of files. Exits
 * the seeding process and outputs an informational message
 */
+ (void)generateSeedDatabaseWithObjectManager:(RKObjectManager *)objectManager fromFiles:(NSString *)fileName, ...;

/**
 * Returns an object seeder ready to begin seeding. Requires a fully configured instance of an object manager.
 */
+ (RKManagedObjectSeeder *)objectSeederWithObjectManager:(RKObjectManager *)objectManager;

/**
 * Seed the database with objects from the specified file(s). The list must be terminated by nil
 */
- (void)seedObjectsFromFiles:(NSString *)fileName, ...;

/**
 * Seed the database with objects from the specified file using the supplied object mapping.
 */
- (void)seedObjectsFromFile:(NSString *)fileName withObjectMapping:(RKObjectMapping *)nilOrObjectMapping;

/**
 * Seed the database with objects from the specified file, from the specified bundle, using the supplied object mapping.
 */
- (void)seedObjectsFromFile:(NSString *)fileName withObjectMapping:(RKObjectMapping *)nilOrObjectMapping bundle:(NSBundle *)nilOrBundle;

/**
 * Completes a seeding session by persisting the store, outputing an informational message
 * and exiting the process
 */
- (void)finalizeSeedingAndExit;

@end
