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

#import <objc/runtime.h>
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

extern NSString *const RKErrorDomain;

NSString *const RKSQLitePersistentStoreSeedDatabasePathOption = @"RKSQLitePersistentStoreSeedDatabasePathOption";
NSString *const RKManagedObjectStoreDidFailSaveNotification = @"RKManagedObjectStoreDidFailSaveNotification";
NSString *const RKManagedObjectStoreDidResetPersistentStoresNotification = @"RKManagedObjectStoreDidResetPersistentStoresNotification";

static RKManagedObjectStore *defaultStore = nil;

static BOOL RKIsManagedObjectContextDescendentOfContext(NSManagedObjectContext *childContext, NSManagedObjectContext *potentialAncestor)
{
    NSManagedObjectContext *context = [childContext parentContext];
    while (context) {
        if ([context isEqual:potentialAncestor]) return YES;
        context = [context parentContext];
    }
    return NO;
}

static NSSet *RKSetOfManagedObjectIDsFromManagedObjectContextDidSaveNotification(NSNotification *notification)
{
    NSUInteger count = [[[notification.userInfo allValues] valueForKeyPath:@"@sum.@count"] unsignedIntegerValue];
    NSMutableSet *objectIDs = [NSMutableSet setWithCapacity:count];
    for (NSSet *objects in [notification.userInfo allValues]) {
        [objectIDs unionSet:[objects valueForKey:@"objectID"]];
    }
    return objectIDs;
}

@interface RKManagedObjectContextChangeMergingObserver : NSObject
@property (nonatomic, weak) NSManagedObjectContext *observedContext;
@property (nonatomic, weak) NSManagedObjectContext *mergeContext;
@property (nonatomic, strong) NSSet *objectIDsFromChildDidSaveNotification;

- (instancetype)initWithObservedContext:(NSManagedObjectContext *)observedContext mergeContext:(NSManagedObjectContext *)mergeContext NS_DESIGNATED_INITIALIZER;
@end

@implementation RKManagedObjectContextChangeMergingObserver

- (instancetype)initWithObservedContext:(NSManagedObjectContext *)observedContext mergeContext:(NSManagedObjectContext *)mergeContext
{
    if (! observedContext) [NSException raise:NSInvalidArgumentException format:@"observedContext cannot be `nil`."];
    if (! mergeContext) [NSException raise:NSInvalidArgumentException format:@"mergeContext cannot be `nil`."];
    self = [super init];
    if (self) {
        self.observedContext = observedContext;
        self.mergeContext = mergeContext;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleManagedObjectContextDidSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:observedContext];
        
        if (RKIsManagedObjectContextDescendentOfContext(mergeContext, observedContext)) {
            RKLogDebug(@"Detected observation of ancestor context by child: enabling child context save detection");
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleManagedObjectContextWillSaveNotification:) name:NSManagedObjectContextDidSaveNotification object:mergeContext];
        }
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleManagedObjectContextWillSaveNotification:(NSNotification *)notification
{
    self.objectIDsFromChildDidSaveNotification = RKSetOfManagedObjectIDsFromManagedObjectContextDidSaveNotification(notification);
}

- (void)handleManagedObjectContextDidSaveNotification:(NSNotification *)notification
{
    NSAssert([notification object] == self.observedContext, @"Received Managed Object Context Did Save Notification for Unexpected Context: %@", [notification object]);
    if (! [self.objectIDsFromChildDidSaveNotification isEqual:RKSetOfManagedObjectIDsFromManagedObjectContextDidSaveNotification(notification)]) {
        [self.mergeContext performBlock:^{
            
            /*
             Fault updated objects before merging changes into mainQueueManagedObjectContext.

             This enables NSFetchedResultsController to update and re-sort its fetch results and to call its delegate methods
             in response Managed Object updates merged from another context.
             See:
             http://stackoverflow.com/a/3927811/489376
             http://stackoverflow.com/a/16296365/489376
             for issue details.
             */
            for (NSManagedObject *object in [[notification userInfo] objectForKey:NSUpdatedObjectsKey]) {
                NSManagedObjectID *objectID = [object objectID];
                if (objectID && ![objectID isTemporaryID]) {
                    NSError *error = nil;
                    NSManagedObject * updatedObject = [self.mergeContext existingObjectWithID:objectID error:&error];
                    if (error) {
                        RKLogDebug(@"Failed to get existing object for objectID (%@). Failed with error: %@", objectID, error);
                    }
                    else {
                        [updatedObject willAccessValueForKey:nil];
                    }
                }
            }
            
            [self.mergeContext mergeChangesFromContextDidSaveNotification:notification];
        }];
    } else {
        RKLogDebug(@"Skipping merge of `NSManagedObjectContextDidSaveNotification`: the save event originated from the mergeContext and thus no save is necessary.");
    }
    self.objectIDsFromChildDidSaveNotification = nil;
}

@end

static char RKManagedObjectContextChangeMergingObserverAssociationKey;

@interface RKManagedObjectStore ()
@property (nonatomic, strong, readwrite) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong, readwrite) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong, readwrite) NSManagedObjectContext *persistentStoreManagedObjectContext;
@property (nonatomic, strong, readwrite) NSManagedObjectContext *mainQueueManagedObjectContext;
@end

@implementation RKManagedObjectStore

+ (instancetype)defaultStore
{
    return defaultStore;
}

+ (void)setDefaultStore:(RKManagedObjectStore *)managedObjectStore
{
    if (defaultStore) {
        @synchronized(defaultStore) {
            defaultStore = managedObjectStore;
        }
    } else {
        defaultStore = managedObjectStore;
    }
}

- (instancetype)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel
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

- (instancetype)initWithPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    self = [self initWithManagedObjectModel:persistentStoreCoordinator.managedObjectModel];
    if (self) {
        self.persistentStoreCoordinator = persistentStoreCoordinator;
    }

    return self;
}

- (instancetype)init
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

- (NSPersistentStore *)addSQLitePersistentStoreAtPath:(NSString *)storePath
                               fromSeedDatabaseAtPath:(NSString *)seedPath
                                    withConfiguration:(NSString *)nilOrConfigurationName
                                              options:(NSDictionary *)nilOrOptions
                                                error:(NSError **)error
{
    if (! self.persistentStoreCoordinator) [self createPersistentStoreCoordinator];

    NSURL *storeURL = [NSURL fileURLWithPath:storePath];
    
    if (seedPath) {
        BOOL success = [self copySeedDatabaseIfNecessaryFromPath:seedPath toPath:storePath error:error];
        if (! success) return nil;
    }

    NSDictionary *options = nil;
    if (nilOrOptions) {
        NSMutableDictionary *mutableOptions = [nilOrOptions mutableCopy];
        mutableOptions[RKSQLitePersistentStoreSeedDatabasePathOption] = (seedPath ?: [NSNull null]);
        options = mutableOptions;
    } else {
        options = @{ RKSQLitePersistentStoreSeedDatabasePathOption: (seedPath ?: [NSNull null]),
                     NSMigratePersistentStoresAutomaticallyOption: @(YES),
                     NSInferMappingModelAutomaticallyOption: @(YES) };
    }
    
    /** 
     There seems to be trouble with combining configurations and migration. So do this in two steps: first, attach the store with NO configuration, but WITH migration options; then remove it and reattach WITH configuration, but NOT migration options.
     
     http://blog.atwam.com/blog/2012/05/11/multiple-persistent-stores-and-seed-data-with-core-data/
     http://stackoverflow.com/questions/1774359/core-data-migration-error-message-model-does-not-contain-configuration-xyz
     */    
    NSPersistentStore *persistentStore = [self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:error];
    if (! persistentStore) return nil;
    if (! [self.persistentStoreCoordinator removePersistentStore:persistentStore error:error]) return nil;

    NSDictionary *seedOptions = nil;
    if (nilOrOptions) {
        NSMutableDictionary *mutableOptions = [nilOrOptions mutableCopy];
        mutableOptions[RKSQLitePersistentStoreSeedDatabasePathOption] = (seedPath ?: [NSNull null]);
        seedOptions = mutableOptions;
    } else {
        seedOptions = @{ RKSQLitePersistentStoreSeedDatabasePathOption: (seedPath ?: [NSNull null]) };
    }
    persistentStore = [self.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nilOrConfigurationName URL:storeURL options:seedOptions error:error];
    if (! persistentStore) return nil;
    
    // Exclude the SQLite database from iCloud Backups to conform to the iCloud Data Storage Guidelines
    RKSetExcludeFromBackupAttributeForItemAtPath(storePath);
    
    return persistentStore;
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
        if ([[NSFileManager defaultManager] fileExistsAtPath:[seedPath stringByAppendingString:@"-shm"]]) {
            if (![[NSFileManager defaultManager] copyItemAtPath:[seedPath stringByAppendingString:@"-shm"] toPath:[storePath stringByAppendingString:@"-shm"] error:&localError]) {
                RKLogError(@"Failed to copy seed database (SHM) from path '%@' to path '%@': %@", seedPath, storePath, [localError localizedDescription]);
                if (error) *error = localError;
                
                return NO;
            }
        }
        if ([[NSFileManager defaultManager] fileExistsAtPath:[seedPath stringByAppendingString:@"-wal"]]) {
            if (![[NSFileManager defaultManager] copyItemAtPath:[seedPath stringByAppendingString:@"-wal"] toPath:[storePath stringByAppendingString:@"-wal"] error:&localError]) {
                RKLogError(@"Failed to copy seed database (WAL) from path '%@' to path '%@': %@", seedPath, storePath, [localError localizedDescription]);
                if (error) *error = localError;
                
                return NO;
            }
        }
    }
    
    return YES;
}

- (NSManagedObjectContext *)newChildManagedObjectContextWithConcurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType tracksChanges:(BOOL)tracksChanges
{
    NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:concurrencyType];
    [managedObjectContext performBlockAndWait:^{
        managedObjectContext.parentContext = self.persistentStoreManagedObjectContext;
        managedObjectContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
    }];
    
    if (tracksChanges) {
        RKManagedObjectContextChangeMergingObserver *observer = [[RKManagedObjectContextChangeMergingObserver alloc] initWithObservedContext:self.persistentStoreManagedObjectContext mergeContext:managedObjectContext];        
        objc_setAssociatedObject(managedObjectContext,
                                 &RKManagedObjectContextChangeMergingObserverAssociationKey,
                                 observer,
                                 OBJC_ASSOCIATION_RETAIN);
    }

    return managedObjectContext;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (NSManagedObjectContext *)newChildManagedObjectContextWithConcurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType
{
    return [self newChildManagedObjectContextWithConcurrencyType:concurrencyType tracksChanges:NO];
}
#pragma clang diagnostic pop

- (void)createManagedObjectContexts
{
    NSAssert(!self.persistentStoreManagedObjectContext, @"Unable to create managed object contexts: A primary managed object context already exists.");
    NSAssert(!self.mainQueueManagedObjectContext, @"Unable to create managed object contexts: A main queue managed object context already exists.");
    NSAssert([[self.persistentStoreCoordinator persistentStores] count], @"Cannot create managed object contexts: The persistent store coordinator does not have any persistent stores. This likely means that you forgot to add a persistent store or your attempt to do so failed with an error.");

    // Our primary MOC is a private queue concurrency type
    self.persistentStoreManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    self.persistentStoreManagedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
    self.persistentStoreManagedObjectContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;

    // Create an MOC for use on the main queue
    self.mainQueueManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    self.mainQueueManagedObjectContext.parentContext = self.persistentStoreManagedObjectContext;
    self.mainQueueManagedObjectContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;

    // Merge changes from a primary MOC back into the main queue when complete
    RKManagedObjectContextChangeMergingObserver *observer = [[RKManagedObjectContextChangeMergingObserver alloc] initWithObservedContext:self.persistentStoreManagedObjectContext mergeContext:self.mainQueueManagedObjectContext];
    objc_setAssociatedObject(self.mainQueueManagedObjectContext,
                             &RKManagedObjectContextChangeMergingObserverAssociationKey,
                             observer,
                             OBJC_ASSOCIATION_RETAIN);
}

- (void)recreateManagedObjectContexts
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:self.persistentStoreManagedObjectContext];

    self.persistentStoreManagedObjectContext = nil;
    self.mainQueueManagedObjectContext = nil;
    [self createManagedObjectContexts];
}

- (BOOL)resetPersistentStores:(NSError **)error
{
    [self.mainQueueManagedObjectContext performBlockAndWait:^{
        [self.mainQueueManagedObjectContext reset];
    }];
    [self.persistentStoreManagedObjectContext performBlockAndWait:^{
        [self.persistentStoreManagedObjectContext reset];
    }];
    
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
                
                // Check for and remove an external storage directory
                NSString *supportDirectoryName = [NSString stringWithFormat:@".%@_SUPPORT", [[URL lastPathComponent] stringByDeletingPathExtension]];
                NSURL *supportDirectoryFileURL = [NSURL URLWithString:supportDirectoryName relativeToURL:[URL URLByDeletingLastPathComponent]];
                BOOL isDirectory = NO;
                if ([[NSFileManager defaultManager] fileExistsAtPath:[supportDirectoryFileURL path] isDirectory:&isDirectory]) {
                    if (isDirectory) {
                        if (! [[NSFileManager defaultManager] removeItemAtURL:supportDirectoryFileURL error:&localError]) {
                            RKLogError(@"Failed to remove persistent store Support directory at URL %@: %@", supportDirectoryFileURL, localError);
                            if (error) *error = localError;
                            return NO;
                        }
                    } else {
                        RKLogWarning(@"Found external support item for store at path that is not a directory: %@", [supportDirectoryFileURL path]);
                    }
                }

                // Check for and remove -shm and -wal files
                for (NSString *suffix in @[ @"-shm", @"-wal" ]) {
                    NSString *supportFileName = [[URL lastPathComponent] stringByAppendingString:suffix];
                    NSURL *supportFileURL = [NSURL URLWithString:supportFileName relativeToURL:[URL URLByDeletingLastPathComponent]];
                    if ([[NSFileManager defaultManager] fileExistsAtPath:[supportFileURL path]]) {
                        if (! [[NSFileManager defaultManager] removeItemAtURL:supportFileURL error:&localError]) {
                            RKLogError(@"Failed to remove support file at URL %@: %@", supportFileURL, localError);
                            if (error) *error = localError;
                            return NO;
                        }
                    }
                }
            } else {
                RKLogDebug(@"Skipped removal of persistent store file: URL for persistent store is not a file URL. (%@)", URL);
            }

            NSPersistentStore *newStore;
            if ([persistentStore.type isEqualToString:NSSQLiteStoreType]) {
                // Seed path for reclone the persistent store from the seed path if necessary
                NSString *seedPath = [persistentStore.options valueForKey:RKSQLitePersistentStoreSeedDatabasePathOption];
                if ([seedPath isEqual:[NSNull null]]) {
                    seedPath = nil;
                }
                
                // Add a new store with the same options, except RKSQLitePersistentStoreSeedDatabasePathOption option
                // that is not expected in this method.
                NSMutableDictionary *mutableOptions = [persistentStore.options mutableCopy];
                [mutableOptions removeObjectForKey:RKSQLitePersistentStoreSeedDatabasePathOption];
                mutableOptions = [mutableOptions count] > 0 ? mutableOptions : nil;
                // This method is only for NSSQLiteStoreType
                newStore = [self addSQLitePersistentStoreAtPath:[persistentStore.URL path]
                                         fromSeedDatabaseAtPath:seedPath
                                              withConfiguration:persistentStore.configurationName
                                                        options:mutableOptions
                                                          error:&localError];
            }
            else {
                // Add a new store with the same options
                newStore = [self.persistentStoreCoordinator addPersistentStoreWithType:persistentStore.type
                                                                         configuration:persistentStore.configurationName
                                                                                   URL:persistentStore.URL
                                                                               options:persistentStore.options error:&localError];
                
            }
            
            
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
    
    [[NSNotificationCenter defaultCenter] postNotificationName:RKManagedObjectStoreDidResetPersistentStoresNotification object:self];
    
    return YES;
}

+ (BOOL)migratePersistentStoreOfType:(NSString *)storeType
                               atURL:(NSURL *)storeURL
                        toModelAtURL:(NSURL *)destinationModelURL
                               error:(NSError **)error
          configuringModelsWithBlock:(void (^)(NSManagedObjectModel *, NSURL *))block
{
    BOOL isMomd = [[destinationModelURL pathExtension] isEqualToString:@"momd"]; // Momd contains a directory of versioned models
    NSManagedObjectModel *destinationModel = [[[NSManagedObjectModel alloc] initWithContentsOfURL:destinationModelURL] mutableCopy];
    
    // Yield the destination model for configuration (i.e. search indexing)
    if (block) block(destinationModel, destinationModelURL);
    
    // Check if the store is compatible with our model
    NSDictionary *storeMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType
                                                                                             URL:storeURL
                                                                                           error:error];
    if (! storeMetadata) return NO;
    if ([destinationModel isConfiguration:nil compatibleWithStoreMetadata:storeMetadata]) {
        // Our store is compatible with the current model, no migration is necessary
        return YES;
    }
    
    RKLogInfo(@"Determined that store at URL %@ has incompatible metadata for managed object model: performing migration...", storeURL);
        
    NSURL *momdURL = isMomd ? destinationModelURL : [destinationModelURL URLByDeletingLastPathComponent];
    
    // We can only do migrations within a versioned momd
    if (![[momdURL pathExtension] isEqualToString:@"momd"]) {
        NSString *errorDescription = [NSString stringWithFormat:@"Migration failed: Migrations can only be performed to versioned destination models contained in a .momd package. Incompatible destination model given at path '%@'", [momdURL path]];
        if (error) *error = [NSError errorWithDomain:RKErrorDomain code:NSMigrationError userInfo:@{ NSLocalizedDescriptionKey: errorDescription }];
        return NO;
    }
    
    NSArray *versionedModelURLs = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:momdURL
                                                                includingPropertiesForKeys:@[] // We only want the URLs
                                                                                   options:NSDirectoryEnumerationSkipsPackageDescendants|NSDirectoryEnumerationSkipsHiddenFiles
                                                                                     error:error];
    if (! versionedModelURLs) {
        return NO;
    }
    
    // Iterate across each model version and try to find a compatible store
    NSManagedObjectModel *sourceModel = nil;
    for (NSURL *versionedModelURL in versionedModelURLs) {
        if (! [@[@"mom", @"momd"] containsObject:[versionedModelURL pathExtension]]) continue;
        NSManagedObjectModel *model = [[[NSManagedObjectModel alloc] initWithContentsOfURL:versionedModelURL] mutableCopy];
        if (! model) continue;
        if (block) block(model, versionedModelURL);
        
        if ([model isConfiguration:nil compatibleWithStoreMetadata:storeMetadata]) {
            sourceModel = model;
            break;
        }
    }
    
    // Cannot complete the migration as we can't find a source model
    if (! sourceModel) {
        NSString *errorDescription = [NSString stringWithFormat:@"Migration failed: Unable to find the source managed object model used to create the %@ store at path '%@'", storeType, [storeURL path]];
        if (error) *error = [NSError errorWithDomain:RKErrorDomain code:NSMigrationMissingSourceModelError userInfo:@{ NSLocalizedDescriptionKey: errorDescription }];
        return NO;
    }
    
    // Infer a mapping model and complete the migration
    NSMappingModel *mappingModel = [NSMappingModel inferredMappingModelForSourceModel:sourceModel
                                                                     destinationModel:destinationModel
                                                                                error:error];
    if (!mappingModel) {
        RKLogError(@"Failed to obtain inferred mapping model for source and destination models: aborting migration...");
        RKLogError(@"%@", *error);
        return NO;
    }

    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *UUID = (__bridge_transfer NSString*)CFUUIDCreateString(kCFAllocatorDefault, uuid);
    CFRelease(uuid);

    NSString *migrationPath = [NSTemporaryDirectory() stringByAppendingFormat:@"Migration-%@.sqlite", UUID];
    NSURL *migrationURL = [NSURL fileURLWithPath:migrationPath];
    
    // Create a migration manager to perform the migration.
    NSMigrationManager *manager = [[NSMigrationManager alloc] initWithSourceModel:sourceModel destinationModel:destinationModel];
    BOOL success = [manager migrateStoreFromURL:storeURL type:NSSQLiteStoreType
                                        options:nil withMappingModel:mappingModel toDestinationURL:migrationURL
                                destinationType:NSSQLiteStoreType destinationOptions:nil error:error];
    
    if (success) {
        success = [[NSFileManager defaultManager] removeItemAtURL:storeURL error:error];
        if (success) {
            success = [[NSFileManager defaultManager] moveItemAtURL:migrationURL toURL:storeURL error:error];
            if (success) RKLogInfo(@"Successfully migrated existing store to managed object model at path '%@'...", [destinationModelURL path]);
        } else {
            RKLogError(@"Failed to remove existing store at path '%@': unable to complete migration...", [storeURL path]);
            RKLogError(@"%@", *error);
        }
    } else {
        RKLogError(@"Failed migration with error: %@", *error);
    }
    return success;
}

@end
