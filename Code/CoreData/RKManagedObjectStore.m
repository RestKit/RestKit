//
//  RKManagedObjectStore.m
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

#import "RKManagedObjectStore.h"
#import "RKLog.h"
#import "RKPropertyInspector.h"
#import "RKPropertyInspector+CoreData.h"
#import "RKDirectoryUtilities.h"
#import "RKInMemoryManagedObjectCache.h"
#import "RKFetchRequestManagedObjectCache.h"
#import "NSBundle+RKAdditions.h"
#import "NSManagedObjectContext+RKAdditions.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitCoreData

NSString * const RKSQLitePersistentStoreSeedDatabasePathOption = @"RKSQLitePersistentStoreSeedDatabasePathOption";
NSString * const RKManagedObjectStoreDidFailSaveNotification = @"RKManagedObjectStoreDidFailSaveNotification";

static RKManagedObjectStore *defaultStore = nil;

@interface RKManagedObjectStore ()
@property (nonatomic, retain, readwrite) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readwrite) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readwrite) NSManagedObjectContext *primaryManagedObjectContext;
@property (nonatomic, retain, readwrite) NSManagedObjectContext *mainQueueManagedObjectContext;
@end

@implementation RKManagedObjectStore

@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectCache = _managedObjectCache;
@synthesize primaryManagedObjectContext = _primaryManagedObjectContext;
@synthesize mainQueueManagedObjectContext = _mainQueueManagedObjectContext;

+ (RKManagedObjectStore *)defaultStore
{
    return defaultStore;
}

+ (void)setDefaultStore:(RKManagedObjectStore *)managedObjectStore
{
    @synchronized(defaultStore) {
        [managedObjectStore retain];
        [defaultStore release];
        defaultStore = managedObjectStore;
    }
}

- (id)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel
{
    self = [super init];
    if (self) {
        self.managedObjectModel = managedObjectModel;

        // Hydrate the defaultStore
        if (! defaultStore) {
            [RKManagedObjectStore setDefaultStore:self];
        }
    }

    return self;
}

- (id)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    self = [self initWithManagedObjectModel:persistentStoreCoordinator.managedObjectModel];
    if (self) {
        self.persistentStoreCoordinator = persistentStoreCoordinator;
    }

    return self;
}

- (id)init
{
    NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:[NSBundle allBundles]];
    return [self initWithManagedObjectModel:managedObjectModel];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [_managedObjectModel release];
    _managedObjectModel = nil;
    [_persistentStoreCoordinator release];
    _persistentStoreCoordinator = nil;
    [_managedObjectCache release];
    _managedObjectCache = nil;
    [_primaryManagedObjectContext release];
    _primaryManagedObjectContext = nil;
    [_mainQueueManagedObjectContext release];
    _mainQueueManagedObjectContext = nil;

    [super dealloc];
}

- (void)createPersistentStoreCoordinator
{
    self.persistentStoreCoordinator = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel] autorelease];
}

- (NSPersistentStore *)addInMemoryPersistentStore:(NSError **)error
{
    if (! self.persistentStoreCoordinator) [self createPersistentStoreCoordinator];
    
    return [self.persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:error];
}

- (NSPersistentStore *)addSQLitePersistentStoreAtPath:(NSString *)storePath fromSeedDatabaseAtPath:(NSString *)seedPath error:(NSError **)error
{
    if (! self.persistentStoreCoordinator) [self createPersistentStoreCoordinator];
    
    NSURL *storeURL = [NSURL fileURLWithPath:storePath];
    if (seedPath) {
        BOOL success = [self copySeedDatabaseIfNecessaryFromPath:seedPath toPath:storePath error:error];
        if (! success) return nil;
    }
    
    // Allow inferred migration from the original version of the application.
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             (seedPath ? seedPath : [NSNull null]), RKSQLitePersistentStoreSeedDatabasePathOption,
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
                             nil];

    return [self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:error];
}

- (BOOL)copySeedDatabaseIfNecessaryFromPath:(NSString *)seedPath toPath:(NSString *)storePath error:(NSError **)error
{
    if (NO == [[NSFileManager defaultManager] fileExistsAtPath:storePath]) {
        NSError *localError;
        if (![[NSFileManager defaultManager] copyItemAtPath:seedPath toPath:storePath error:&localError]) {
            RKLogError(@"Failed to copy seed database from path '%@' to path '%@': %@", seedPath, storePath, [localError localizedDescription]);
            if (error) *error = localError;

            return NO;
        }
    }

    return YES;
}

- (NSManagedObjectContext *)newChildManagedObjectContextWithConcurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType
{
    NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:concurrencyType];
    [managedObjectContext performBlockAndWait:^{
        managedObjectContext.parentContext = self.primaryManagedObjectContext;
        managedObjectContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
        managedObjectContext.managedObjectStore = self;
    }];
    
    return managedObjectContext;
}

- (void)createManagedObjectContexts
{
    NSAssert(!self.primaryManagedObjectContext, @"Unable to create managed object contexts: A primary managed object context already exists.");
    NSAssert(!self.mainQueueManagedObjectContext, @"Unable to create managed object contexts: A main queue managed object context already exists.");

    // Our primary MOC is a private queue concurrency type
    self.primaryManagedObjectContext = [[[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType] autorelease];
    self.primaryManagedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
    self.primaryManagedObjectContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
    self.primaryManagedObjectContext.managedObjectStore = self;
    
    // Create an MOC for use on the main queue
    self.mainQueueManagedObjectContext = [[[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType] autorelease];
    self.mainQueueManagedObjectContext.parentContext = self.primaryManagedObjectContext;
    self.mainQueueManagedObjectContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
    self.mainQueueManagedObjectContext.managedObjectStore = self;
    
    // Merge changes from a primary MOC back into the main queue when complete
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handlePrimaryManagedObjectContextDidSaveNotification:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:self.primaryManagedObjectContext];
}

- (void)recreateManagedObjectContexts
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:self.primaryManagedObjectContext];
    
    self.primaryManagedObjectContext = nil;
    self.mainQueueManagedObjectContext = nil;
    [self createManagedObjectContexts];
}

- (BOOL)resetPersistentStores:(NSError **)error
{
    NSError *localError;
    for (NSPersistentStore *persistentStore in self.persistentStoreCoordinator.persistentStores) {
        NSURL *URL = [self.persistentStoreCoordinator URLForPersistentStore:persistentStore];
        BOOL success = [self.persistentStoreCoordinator removePersistentStore:persistentStore error:&localError];
        if (success) {
            if ([URL isFileURL]) {
                if (! [[NSFileManager defaultManager] removeItemAtURL:URL error:&localError]) {
                    RKLogError(@"Failed to remove persistent store at URL %@: %@", URL, localError);
                    if (error) *error = localError;
                    return NO;
                }
            } else {
                RKLogDebug(@"Skipped removal of persistent store file: URL for persistent store is not a file URL. (%@)", URL);
            }

            // Reclone the persistent store from the seed path if necessary
            if ([persistentStore.type isEqualToString:NSSQLiteStoreType]) {
                NSString *seedPath = [persistentStore.options valueForKey:RKSQLitePersistentStoreSeedDatabasePathOption];
                if (seedPath && ![seedPath isEqual:[NSNull null]]) {
                    success = [self copySeedDatabaseIfNecessaryFromPath:seedPath toPath:[persistentStore.URL path] error:&localError];
                    if (! success) {
                        RKLogError(@"Failed reset of SQLite persistent store: Failed to copy seed database.");
                        if (error) *error = localError;
                        return NO;
                    }
                }
            }

            // Add a new store with the same options
            NSPersistentStore *newStore = [self.persistentStoreCoordinator addPersistentStoreWithType:persistentStore.type
                                                                                        configuration:persistentStore.configurationName
                                                                                                  URL:persistentStore.URL
                                                                                              options:persistentStore.options error:&localError];
            if (! newStore) {
                if (error) *error = localError;
                return NO;
            }
        } else {
            RKLogError(@"Failed reset of persistent store %@: Failed to remove persistent store with error: %@", persistentStore, localError);
            if (error) *error = localError;
            return NO;
        }
    }

    [self recreateManagedObjectContexts];
    return YES;
}

- (void)handlePrimaryManagedObjectContextDidSaveNotification:(NSNotification *)notification
{
    RKLogDebug(@"primaryManagedObjectContext was saved: merging changes to mainQueueManagedObjectContext");
    RKLogTrace(@"Merging changes detailed in userInfo dictionary: %@", [notification userInfo]);
    NSAssert([notification object] == self.primaryManagedObjectContext, @"Received Managed Object Context Did Save Notification for Unexpected Context: %@", [notification object]);
    [self.mainQueueManagedObjectContext performBlock:^{
        [self.mainQueueManagedObjectContext mergeChangesFromContextDidSaveNotification:notification];
    }];
}

@end

@implementation RKManagedObjectStore (Deprecations)

+ (RKManagedObjectStore *)defaultObjectStore DEPRECATED_ATTRIBUTE
{
    return [RKManagedObjectStore defaultStore];
}

+ (void)setDefaultObjectStore:(RKManagedObjectStore *)objectStore DEPRECATED_ATTRIBUTE
{
    [RKManagedObjectStore setDefaultStore:objectStore];
}

#pragma mark -
#pragma mark Helpers

- (NSManagedObject *)objectWithID:(NSManagedObjectID *)objectID DEPRECATED_ATTRIBUTE
{
    NSAssert(objectID, @"Cannot fetch a managedObject with a nil objectID");
    return [[self managedObjectContextForCurrentThread] objectWithID:objectID];
}

- (NSArray *)objectsWithIDs:(NSArray *)objectIDs DEPRECATED_ATTRIBUTE
{
    NSMutableArray *objects = [[NSMutableArray alloc] init];
    for (NSManagedObjectID *objectID in objectIDs) {
        [objects addObject:[self objectWithID:objectID]];
    }
    NSArray *objectArray = [NSArray arrayWithArray:objects];
    [objects release];

    return objectArray;
}

- (id<RKManagedObjectCaching>)cacheStrategy DEPRECATED_ATTRIBUTE
{
    return self.managedObjectCache;
}

- (void)setCacheStrategy:(id<RKManagedObjectCaching>)cacheStrategy DEPRECATED_ATTRIBUTE
{
    self.managedObjectCache = cacheStrategy;
}

- (NSString *)storeFilename DEPRECATED_ATTRIBUTE
{
    return [[self pathToStoreFile] lastPathComponent];
}

- (NSString *)pathToStoreFile DEPRECATED_ATTRIBUTE
{
    for (NSPersistentStore *persistentStore in self.persistentStoreCoordinator.persistentStores) {
        if ([persistentStore.type isEqualToString:NSSQLiteStoreType]) {
            NSURL *URL = [self.persistentStoreCoordinator URLForPersistentStore:persistentStore];
            if ([URL isFileURL]) {
                return URL.path;
            }
        }
    }

    return nil;
}

- (BOOL)save:(NSError **)error DEPRECATED_ATTRIBUTE
{
    __block NSError *localError = nil;
    __block BOOL success;

    [self.primaryManagedObjectContext performBlockAndWait:^{
        success = [self.primaryManagedObjectContext save:&localError];
        if (!success) {
            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:localError forKey:@"error"];
            [[NSNotificationCenter defaultCenter] postNotificationName:RKManagedObjectStoreDidFailSaveNotification object:self userInfo:userInfo];
            RKLogCoreDataError(localError);
            if (error) *error = localError;
        }
    }];

    return success;
}

+ (void)deleteStoreAtPath:(NSString *)path DEPRECATED_ATTRIBUTE
{
    NSURL *storeURL = [NSURL fileURLWithPath:path];
    NSError *error = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:storeURL.path]) {
        if (! [[NSFileManager defaultManager] removeItemAtPath:storeURL.path error:&error]) {
            NSAssert(NO, @"Managed object store failed to delete persistent store : %@", error);
        }
    } else {
        RKLogWarning(@"Asked to delete persistent store but no store file exists at path: %@", storeURL.path);
    }
}

+ (void)deleteStoreInApplicationDataDirectoryWithFilename:(NSString *)filename DEPRECATED_ATTRIBUTE
{
    NSString *path = [RKApplicationDataDirectory() stringByAppendingPathComponent:filename];
    [self deleteStoreAtPath:path];
}

+ (RKManagedObjectStore *)objectStoreWithStoreFilename:(NSString *)storeFilename DEPRECATED_ATTRIBUTE
{
    return [self objectStoreWithStoreFilename:storeFilename usingSeedDatabaseName:nil managedObjectModel:nil delegate:nil];
}

+ (RKManagedObjectStore *)objectStoreWithStoreFilename:(NSString *)storeFilename usingSeedDatabaseName:(NSString *)nilOrNameOfSeedDatabaseInMainBundle managedObjectModel:(NSManagedObjectModel *)nilOrManagedObjectModel delegate:(id)delegate DEPRECATED_ATTRIBUTE
{
    return [[[self alloc] initWithStoreFilename:storeFilename inDirectory:nil usingSeedDatabaseName:nilOrNameOfSeedDatabaseInMainBundle managedObjectModel:nilOrManagedObjectModel delegate:delegate] autorelease];
}

+ (RKManagedObjectStore *)objectStoreWithStoreFilename:(NSString *)storeFilename inDirectory:(NSString *)directory usingSeedDatabaseName:(NSString *)nilOrNameOfSeedDatabaseInMainBundle managedObjectModel:(NSManagedObjectModel *)nilOrManagedObjectModel delegate:(id)delegate DEPRECATED_ATTRIBUTE
{
    return [[[self alloc] initWithStoreFilename:storeFilename inDirectory:directory usingSeedDatabaseName:nilOrNameOfSeedDatabaseInMainBundle managedObjectModel:nilOrManagedObjectModel delegate:delegate] autorelease];
}

- (id)initWithStoreFilename:(NSString *)storeFilename DEPRECATED_ATTRIBUTE
{
    return [self initWithStoreFilename:storeFilename inDirectory:nil usingSeedDatabaseName:nil managedObjectModel:nil delegate:nil];
}

- (id)initWithStoreFilename:(NSString *)storeFilename inDirectory:(NSString *)nilOrDirectoryPath usingSeedDatabaseName:(NSString *)nilOrNameOfSeedDatabaseInMainBundle managedObjectModel:(NSManagedObjectModel *)nilOrManagedObjectModel delegate:(id)delegate DEPRECATED_ATTRIBUTE
{
    NSManagedObjectModel *managedObjectModel = nilOrManagedObjectModel;
    if (! managedObjectModel) {
        managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:[NSBundle allBundles]];
    }

    self = [self initWithManagedObjectModel:managedObjectModel];
    if (self) {
        NSString *storeDirectory = nilOrDirectoryPath;
        if (storeDirectory == nil) {
            // If initializing into Application Data directory, ensure the directory exists
            storeDirectory = RKApplicationDataDirectory();
            RKEnsureDirectoryExistsAtPath(storeDirectory, nil);
        } else {
            // If path given, caller is responsible for directory's existence
            BOOL isDir;
            NSAssert1([[NSFileManager defaultManager] fileExistsAtPath:storeDirectory isDirectory:&isDir] && isDir == YES, @"Specified storage directory exists", storeDirectory);
        }

        NSString *SQLiteStorePath = [storeDirectory stringByAppendingPathComponent:storeFilename];

        NSString *seedPath = nilOrDirectoryPath ? [[NSBundle mainBundle] pathForResource:nilOrNameOfSeedDatabaseInMainBundle ofType:nil] : nil;
        NSError *error;
        NSPersistentStore *persistentStore = [self addSQLitePersistentStoreAtPath:SQLiteStorePath fromSeedDatabaseAtPath:seedPath error:&error];
        if (! persistentStore) {
            RKLogError(@"Initialization of SQLite store failed with error: %@", error);
        }

        [self createManagedObjectContexts];

        self.managedObjectCache = [[[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:self.primaryManagedObjectContext] autorelease];
    }

    return self;
}

- (void)deletePersistentStoreUsingSeedDatabaseName:(NSString *)seedFile DEPRECATED_ATTRIBUTE
{
    [self resetPersistentStores:nil];
}

- (void)deletePersistentStore DEPRECATED_ATTRIBUTE
{
    [self resetPersistentStores:nil];
}

- (NSManagedObjectContext *)newManagedObjectContext DEPRECATED_ATTRIBUTE
{
    NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
    managedObjectContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
    managedObjectContext.managedObjectStore = self;

    return managedObjectContext;
}

- (NSManagedObjectContext *)managedObjectContextForCurrentThread DEPRECATED_ATTRIBUTE
{
    return [[self newManagedObjectContext] autorelease];
}

@end
