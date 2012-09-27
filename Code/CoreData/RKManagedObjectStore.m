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
#import "RKPathUtilities.h"
#import "RKInMemoryManagedObjectCache.h"
#import "RKFetchRequestManagedObjectCache.h"
#import "NSManagedObjectContext+RKAdditions.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent RKlcl_cRestKitCoreData

NSString * const RKSQLitePersistentStoreSeedDatabasePathOption = @"RKSQLitePersistentStoreSeedDatabasePathOption";
NSString * const RKManagedObjectStoreDidFailSaveNotification = @"RKManagedObjectStoreDidFailSaveNotification";

static RKManagedObjectStore *defaultStore = nil;

@interface RKManagedObjectStore ()
@property (nonatomic, strong, readwrite) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong, readwrite) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong, readwrite) NSManagedObjectContext *primaryManagedObjectContext;
@property (nonatomic, strong, readwrite) NSManagedObjectContext *mainQueueManagedObjectContext;
@end

@implementation RKManagedObjectStore


+ (RKManagedObjectStore *)defaultStore
{
    return defaultStore;
}

+ (void)setDefaultStore:(RKManagedObjectStore *)managedObjectStore
{
    @synchronized(defaultStore) {
        defaultStore = managedObjectStore;
    }
}

- (id)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel
{
    self = [super init];
    if (self) {
        self.managedObjectModel = managedObjectModel;
        self.managedObjectCache = [RKFetchRequestManagedObjectCache new];

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


}

- (void)createPersistentStoreCoordinator
{
    self.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
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
    }];

    return managedObjectContext;
}

- (void)createManagedObjectContexts
{
    NSAssert(!self.primaryManagedObjectContext, @"Unable to create managed object contexts: A primary managed object context already exists.");
    NSAssert(!self.mainQueueManagedObjectContext, @"Unable to create managed object contexts: A main queue managed object context already exists.");

    // Our primary MOC is a private queue concurrency type
    self.primaryManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    self.primaryManagedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
    self.primaryManagedObjectContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;

    // Create an MOC for use on the main queue
    self.mainQueueManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    self.mainQueueManagedObjectContext.parentContext = self.primaryManagedObjectContext;
    self.mainQueueManagedObjectContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;

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
