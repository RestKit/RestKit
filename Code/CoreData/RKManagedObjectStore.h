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

// Option containing the path to the seed database a SQLite store was initialized with
extern NSString * const RKSQLitePersistentStoreSeedDatabasePathOption;

@interface RKManagedObjectStore : NSObject

///-----------------------------------------------------------------------------
/// @name Accessing the Default Object Store
///-----------------------------------------------------------------------------

+ (RKManagedObjectStore *)defaultStore;
+ (void)setDefaultStore:(RKManagedObjectStore *)managedObjectStore;

///-----------------------------------------------------------------------------
/// @name Initializing an Object Store
///-----------------------------------------------------------------------------

/**
 ADD NOTE ABOUT THE MANAGED OBJECT MODEL COMING BACK IMMUTABLE IN IOS 5+
 
 NSURL *modelURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"GateGuru" ofType:@"momd"]];
 // NOTE: Due to an iOS 5 bug, the managed object model returned is immutable.
 NSManagedObjectModel *managedObjectModel = [[[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL] mutableCopy];
 */
- (id)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel; // Designated initializer
- (id)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (id)init; // calls initWithManagedObjectModel: by obtaining the merged model...

///-----------------------------------------------------------------------------
/// @name Configuring Persistent Stores
///-----------------------------------------------------------------------------

- (NSPersistentStore *)addInMemoryPersistentStore:(NSError **)error;
- (NSPersistentStore *)addSQLitePersistentStoreAtPath:(NSString *)storePath fromSeedDatabaseAtPath:(NSString *)seedPath error:(NSError **)error;

- (BOOL)resetPersistentStores:(NSError **)error; // has the side-effect of recreating the managed object contexts. Respects seed database

///-----------------------------------------------------------------------------
/// @name Retrieving Details about the Store
///-----------------------------------------------------------------------------

// Core Data
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain) id<RKManagedObjectCaching> managedObjectCache;

///-----------------------------------------------------------------------------
/// @name Working with Managed Object Contexts
///-----------------------------------------------------------------------------

- (void)createManagedObjectContexts; // will raise exception if they are already created...

@property (nonatomic, retain, readonly) NSManagedObjectContext *primaryManagedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectContext *mainQueueManagedObjectContext;
- (NSManagedObjectContext *)newChildManagedObjectContextWithConcurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType;

@end

@interface RKManagedObjectStore (Deprecations)
+ (RKManagedObjectStore *)defaultObjectStore DEPRECATED_ATTRIBUTE;
+ (void)setDefaultObjectStore:(RKManagedObjectStore *)objectStore DEPRECATED_ATTRIBUTE;
- (id)initWithStoreFilename:(NSString *)storeFilename DEPRECATED_ATTRIBUTE;
- (NSManagedObjectContext *)newManagedObjectContext DEPRECATED_ATTRIBUTE;
- (NSManagedObjectContext *)managedObjectContextForCurrentThread DEPRECATED_ATTRIBUTE;
- (NSManagedObject *)objectWithID:(NSManagedObjectID *)objectID DEPRECATED_ATTRIBUTE;
- (NSArray *)objectsWithIDs:(NSArray *)objectIDs DEPRECATED_ATTRIBUTE;

- (id<RKManagedObjectCaching>)cacheStrategy DEPRECATED_ATTRIBUTE;
- (void)setCacheStrategy:(id<RKManagedObjectCaching>)cacheStrategy DEPRECATED_ATTRIBUTE;

- (NSString *)storeFilename DEPRECATED_ATTRIBUTE;
- (NSString *)pathToStoreFile DEPRECATED_ATTRIBUTE;

- (BOOL)save:(NSError **)error DEPRECATED_ATTRIBUTE;

// TODO: Deprecate all of these...
+ (RKManagedObjectStore *)objectStoreWithStoreFilename:(NSString *)storeFilename DEPRECATED_ATTRIBUTE;
+ (RKManagedObjectStore *)objectStoreWithStoreFilename:(NSString *)storeFilename usingSeedDatabaseName:(NSString *)nilOrNameOfSeedDatabaseInMainBundle managedObjectModel:(NSManagedObjectModel *)nilOrManagedObjectModel delegate:(id)delegate DEPRECATED_ATTRIBUTE;
+ (RKManagedObjectStore *)objectStoreWithStoreFilename:(NSString *)storeFilename inDirectory:(NSString *)directory usingSeedDatabaseName:(NSString *)nilOrNameOfSeedDatabaseInMainBundle managedObjectModel:(NSManagedObjectModel *)nilOrManagedObjectModel delegate:(id)delegate DEPRECATED_ATTRIBUTE;

+ (void)deleteStoreAtPath:(NSString *)path DEPRECATED_ATTRIBUTE;
+ (void)deleteStoreInApplicationDataDirectoryWithFilename:(NSString *)filename DEPRECATED_ATTRIBUTE;
- (void)deletePersistentStoreUsingSeedDatabaseName:(NSString *)seedFile DEPRECATED_ATTRIBUTE;
- (void)deletePersistentStore DEPRECATED_ATTRIBUTE;

@end
