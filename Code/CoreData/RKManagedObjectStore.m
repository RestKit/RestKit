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
#import "NSManagedObject+ActiveRecord.h"
#import "RKLog.h"
#import "RKSearchWordObserver.h"
#import "RKObjectPropertyInspector.h"
#import "RKObjectPropertyInspector+CoreData.h"
#import "RKAlert.h"
#import "RKDirectory.h"
#import "RKInMemoryManagedObjectCache.h"
#import "RKFetchRequestManagedObjectCache.h"
#import "NSBundle+RKAdditions.h"
#import "NSManagedObjectContext+RKAdditions.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitCoreData

NSString * const RKManagedObjectStoreDidFailSaveNotification = @"RKManagedObjectStoreDidFailSaveNotification";
static NSString * const RKManagedObjectStoreThreadDictionaryContextKey = @"RKManagedObjectStoreThreadDictionaryContextKey";
static NSString * const RKManagedObjectStoreThreadDictionaryEntityCacheKey = @"RKManagedObjectStoreThreadDictionaryEntityCacheKey";

static RKManagedObjectStore *defaultObjectStore = nil;

@interface RKManagedObjectStore ()
@property (nonatomic, retain, readwrite) NSManagedObjectContext *primaryManagedObjectContext;

- (id)initWithStoreFilename:(NSString *)storeFilename inDirectory:(NSString *)nilOrDirectoryPath usingSeedDatabaseName:(NSString *)nilOrNameOfSeedDatabaseInMainBundle managedObjectModel:(NSManagedObjectModel *)nilOrManagedObjectModel delegate:(id)delegate;
- (void)createPersistentStoreCoordinator;
- (void)createStoreIfNecessaryUsingSeedDatabase:(NSString *)seedDatabase;
- (NSManagedObjectContext *)newManagedObjectContext;
@end

@implementation RKManagedObjectStore

@synthesize delegate = _delegate;
@synthesize storeFilename = _storeFilename;
@synthesize pathToStoreFile = _pathToStoreFile;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize cacheStrategy = _cacheStrategy;
@synthesize primaryManagedObjectContext;

+ (RKManagedObjectStore *)defaultObjectStore
{
    return defaultObjectStore;
}

+ (void)setDefaultObjectStore:(RKManagedObjectStore *)objectStore
{
    [objectStore retain];
    [defaultObjectStore release];
    defaultObjectStore = objectStore;

    [NSManagedObjectContext setDefaultContext:objectStore.primaryManagedObjectContext];
}

+ (void)deleteStoreAtPath:(NSString *)path
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

+ (void)deleteStoreInApplicationDataDirectoryWithFilename:(NSString *)filename
{
    NSString *path = [[RKDirectory applicationDataDirectory] stringByAppendingPathComponent:filename];
    [self deleteStoreAtPath:path];
}

+ (RKManagedObjectStore *)objectStoreWithStoreFilename:(NSString *)storeFilename
{
    return [self objectStoreWithStoreFilename:storeFilename usingSeedDatabaseName:nil managedObjectModel:nil delegate:nil];
}

+ (RKManagedObjectStore *)objectStoreWithStoreFilename:(NSString *)storeFilename usingSeedDatabaseName:(NSString *)nilOrNameOfSeedDatabaseInMainBundle managedObjectModel:(NSManagedObjectModel *)nilOrManagedObjectModel delegate:(id)delegate
{
    return [[[self alloc] initWithStoreFilename:storeFilename inDirectory:nil usingSeedDatabaseName:nilOrNameOfSeedDatabaseInMainBundle managedObjectModel:nilOrManagedObjectModel delegate:delegate] autorelease];
}

+ (RKManagedObjectStore *)objectStoreWithStoreFilename:(NSString *)storeFilename inDirectory:(NSString *)directory usingSeedDatabaseName:(NSString *)nilOrNameOfSeedDatabaseInMainBundle managedObjectModel:(NSManagedObjectModel *)nilOrManagedObjectModel delegate:(id)delegate
{
    return [[[self alloc] initWithStoreFilename:storeFilename inDirectory:directory usingSeedDatabaseName:nilOrNameOfSeedDatabaseInMainBundle managedObjectModel:nilOrManagedObjectModel delegate:delegate] autorelease];
}

- (id)initWithStoreFilename:(NSString *)storeFilename
{
    return [self initWithStoreFilename:storeFilename inDirectory:nil usingSeedDatabaseName:nil managedObjectModel:nil delegate:nil];
}

- (id)initWithStoreFilename:(NSString *)storeFilename inDirectory:(NSString *)nilOrDirectoryPath usingSeedDatabaseName:(NSString *)nilOrNameOfSeedDatabaseInMainBundle managedObjectModel:(NSManagedObjectModel *)nilOrManagedObjectModel delegate:(id)delegate
{
    self = [self init];
    if (self) {
        _storeFilename = [storeFilename retain];

        if (nilOrDirectoryPath == nil) {
            // If initializing into Application Data directory, ensure the directory exists
            nilOrDirectoryPath = [RKDirectory applicationDataDirectory];
            [RKDirectory ensureDirectoryExistsAtPath:nilOrDirectoryPath error:nil];
        } else {
            // If path given, caller is responsible for directory's existence
            BOOL isDir;
            NSAssert1([[NSFileManager defaultManager] fileExistsAtPath:nilOrDirectoryPath isDirectory:&isDir] && isDir == YES, @"Specified storage directory exists", nilOrDirectoryPath);
        }
        _pathToStoreFile = [[nilOrDirectoryPath stringByAppendingPathComponent:_storeFilename] retain];

        if (nilOrManagedObjectModel == nil) {
            // NOTE: allBundles permits Core Data setup in unit tests
            nilOrManagedObjectModel = [NSManagedObjectModel mergedModelFromBundles:[NSBundle allBundles]];
        }
        NSMutableArray *allManagedObjectModels = [NSMutableArray arrayWithObject:nilOrManagedObjectModel];
        _managedObjectModel = [[NSManagedObjectModel modelByMergingModels:allManagedObjectModels] retain];
        _delegate = delegate;

	_delegate = delegate;

        if (nilOrNameOfSeedDatabaseInMainBundle) {
            [self createStoreIfNecessaryUsingSeedDatabase:nilOrNameOfSeedDatabaseInMainBundle];
        }

        [self createPersistentStoreCoordinator];
        self.primaryManagedObjectContext = [[self newManagedObjectContext] autorelease];

        _cacheStrategy = [RKInMemoryManagedObjectCache new];

        // Ensure there is a search word observer
        [RKSearchWordObserver sharedObserver];

        // Hydrate the defaultObjectStore
        if (! defaultObjectStore) {
            [RKManagedObjectStore setDefaultObjectStore:self];
        }
    }

    return self;
}

- (void)setThreadLocalObject:(id)value forKey:(id)key
{
    NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
    NSString *objectStoreKey = [NSString stringWithFormat:@"RKManagedObjectStore_%p", self];
    if (! [threadDictionary valueForKey:objectStoreKey]) {
        [threadDictionary setValue:[NSMutableDictionary dictionary] forKey:objectStoreKey];
    }

    [[threadDictionary objectForKey:objectStoreKey] setObject:value forKey:key];
}

- (id)threadLocalObjectForKey:(id)key
{
    NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
    NSString *objectStoreKey = [NSString stringWithFormat:@"RKManagedObjectStore_%p", self];
    if (! [threadDictionary valueForKey:objectStoreKey]) {
        [threadDictionary setObject:[NSMutableDictionary dictionary] forKey:objectStoreKey];
    }

    return [[threadDictionary objectForKey:objectStoreKey] objectForKey:key];
}

- (void)removeThreadLocalObjectForKey:(id)key
{
    NSMutableDictionary *threadDictionary = [[NSThread currentThread] threadDictionary];
    NSString *objectStoreKey = [NSString stringWithFormat:@"RKManagedObjectStore_%p", self];
    if (! [threadDictionary valueForKey:objectStoreKey]) {
        [threadDictionary setObject:[NSMutableDictionary dictionary] forKey:objectStoreKey];
    }

    [[threadDictionary objectForKey:objectStoreKey] removeObjectForKey:key];
}

- (void)clearThreadLocalStorage
{
    // Clear out our Thread local information
    NSManagedObjectContext *managedObjectContext = [self threadLocalObjectForKey:RKManagedObjectStoreThreadDictionaryContextKey];
    if (managedObjectContext) {
        [self removeThreadLocalObjectForKey:RKManagedObjectStoreThreadDictionaryContextKey];
    }
    if ([self threadLocalObjectForKey:RKManagedObjectStoreThreadDictionaryEntityCacheKey]) {
        [self removeThreadLocalObjectForKey:RKManagedObjectStoreThreadDictionaryEntityCacheKey];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self clearThreadLocalStorage];

    [_storeFilename release];
    _storeFilename = nil;
    [_pathToStoreFile release];
    _pathToStoreFile = nil;

    [_managedObjectModel release];
    _managedObjectModel = nil;
    [_persistentStoreCoordinator release];
    _persistentStoreCoordinator = nil;
    [_cacheStrategy release];
    _cacheStrategy = nil;
    [primaryManagedObjectContext release];
    primaryManagedObjectContext = nil;

    [super dealloc];
}

/**
 Performs the save action for the application, which is to send the save:
 message to the application's managed object context.
 */
- (BOOL)save:(NSError **)error
{
    NSManagedObjectContext *moc = [self managedObjectContextForCurrentThread];
    NSError *localError = nil;

    @try {
        if (![moc save:&localError]) {
            if (self.delegate != nil && [self.delegate respondsToSelector:@selector(managedObjectStore:didFailToSaveContext:error:exception:)]) {
                [self.delegate managedObjectStore:self didFailToSaveContext:moc error:localError exception:nil];
            }

            NSDictionary *userInfo = [NSDictionary dictionaryWithObject:localError forKey:@"error"];
            [[NSNotificationCenter defaultCenter] postNotificationName:RKManagedObjectStoreDidFailSaveNotification object:self userInfo:userInfo];

            if ([[localError domain] isEqualToString:@"NSCocoaErrorDomain"]) {
                NSDictionary *userInfo = [localError userInfo];
                NSArray *errors = [userInfo valueForKey:@"NSDetailedErrors"];
                if (errors) {
                    for (NSError *detailedError in errors) {
                        NSDictionary *subUserInfo = [detailedError userInfo];
                        RKLogError(@"Core Data Save Error\n \
                              NSLocalizedDescription:\t\t%@\n \
                              NSValidationErrorKey:\t\t\t%@\n \
                              NSValidationErrorPredicate:\t%@\n \
                              NSValidationErrorObject:\n%@\n",
                              [subUserInfo valueForKey:@"NSLocalizedDescription"],
                              [subUserInfo valueForKey:@"NSValidationErrorKey"],
                              [subUserInfo valueForKey:@"NSValidationErrorPredicate"],
                              [subUserInfo valueForKey:@"NSValidationErrorObject"]);
                    }
                }
                else {
                    RKLogError(@"Core Data Save Error\n \
                               NSLocalizedDescription:\t\t%@\n \
                               NSValidationErrorKey:\t\t\t%@\n \
                               NSValidationErrorPredicate:\t%@\n \
                               NSValidationErrorObject:\n%@\n",
                               [userInfo valueForKey:@"NSLocalizedDescription"],
                               [userInfo valueForKey:@"NSValidationErrorKey"],
                               [userInfo valueForKey:@"NSValidationErrorPredicate"],
                               [userInfo valueForKey:@"NSValidationErrorObject"]);
                }
            }

            if (error) {
                *error = localError;
            }

            return NO;
        }
    }
    @catch (NSException *e) {
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(managedObjectStore:didFailToSaveContext:error:exception:)]) {
            [self.delegate managedObjectStore:self didFailToSaveContext:moc error:nil exception:e];
        }
        else {
            @throw;
        }
    }

    return YES;
}

- (NSManagedObjectContext *)newManagedObjectContext
{
    NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
    [managedObjectContext setUndoManager:nil];
    [managedObjectContext setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];
    managedObjectContext.managedObjectStore = self;

    return managedObjectContext;
}

- (void)createStoreIfNecessaryUsingSeedDatabase:(NSString *)seedDatabase
{
    if (NO == [[NSFileManager defaultManager] fileExistsAtPath:self.pathToStoreFile]) {
        NSString *seedDatabasePath = [[NSBundle mainBundle] pathForResource:seedDatabase ofType:nil];
        NSAssert1(seedDatabasePath, @"Unable to find seed database file '%@' in the Main Bundle, aborting...", seedDatabase);
        RKLogInfo(@"No existing database found, copying from seed path '%@'", seedDatabasePath);

        NSError *error;
        if (![[NSFileManager defaultManager] copyItemAtPath:seedDatabasePath toPath:self.pathToStoreFile error:&error]) {
            if (self.delegate != nil && [self.delegate respondsToSelector:@selector(managedObjectStore:didFailToCopySeedDatabase:error:)]) {
                [self.delegate managedObjectStore:self didFailToCopySeedDatabase:seedDatabase error:error];
            } else {
                RKLogError(@"Encountered an error during seed database copy: %@", [error localizedDescription]);
            }
        }
        NSAssert1([[NSFileManager defaultManager] fileExistsAtPath:seedDatabasePath], @"Seed database not found at path '%@'!", seedDatabasePath);
    }
}

- (void)createPersistentStoreCoordinator
{
    NSAssert(_managedObjectModel, @"Cannot create persistent store coordinator without a managed object model");
    NSAssert(!_persistentStoreCoordinator, @"Cannot create persistent store coordinator: one already exists.");
    NSURL *storeURL = [NSURL fileURLWithPath:self.pathToStoreFile];

    NSError *error;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_managedObjectModel];

    // Allow inferred migration from the original version of the application.
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];

    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(managedObjectStore:didFailToCreatePersistentStoreCoordinatorWithError:)]) {
            [self.delegate managedObjectStore:self didFailToCreatePersistentStoreCoordinatorWithError:error];
        } else {
            NSAssert(NO, @"Managed object store failed to create persistent store coordinator: %@", error);
        }
    }
}

- (void)deletePersistentStoreUsingSeedDatabaseName:(NSString *)seedFile
{
    NSURL *storeURL = [NSURL fileURLWithPath:self.pathToStoreFile];
    NSError *error = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:storeURL.path]) {
        if (![[NSFileManager defaultManager] removeItemAtPath:storeURL.path error:&error]) {
            if (self.delegate != nil && [self.delegate respondsToSelector:@selector(managedObjectStore:didFailToDeletePersistentStore:error:)]) {
                [self.delegate managedObjectStore:self didFailToDeletePersistentStore:self.pathToStoreFile error:error];
            }
            else {
                NSAssert(NO, @"Managed object store failed to delete persistent store : %@", error);
            }
        }
    } else {
        RKLogWarning(@"Asked to delete persistent store but no store file exists at path: %@", storeURL.path);
    }

    [_persistentStoreCoordinator release];
    _persistentStoreCoordinator = nil;

    if (seedFile) {
        [self createStoreIfNecessaryUsingSeedDatabase:seedFile];
    }

    [self createPersistentStoreCoordinator];

    // Recreate the MOC
    self.primaryManagedObjectContext = [[self newManagedObjectContext] autorelease];
}

- (void)deletePersistentStore
{
    [self deletePersistentStoreUsingSeedDatabaseName:nil];
}

- (NSManagedObjectContext *)managedObjectContextForCurrentThread
{
    if ([NSThread isMainThread]) {
        return self.primaryManagedObjectContext;
    }

    // Background threads leverage thread-local storage
    NSManagedObjectContext *managedObjectContext = [self threadLocalObjectForKey:RKManagedObjectStoreThreadDictionaryContextKey];
    if (!managedObjectContext) {
        managedObjectContext = [self newManagedObjectContext];

        // Store into thread local storage dictionary
        [self setThreadLocalObject:managedObjectContext forKey:RKManagedObjectStoreThreadDictionaryContextKey];
        [managedObjectContext release];

        // If we are a background Thread MOC, we need to inform the main thread on save
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(mergeChanges:)
                                                     name:NSManagedObjectContextDidSaveNotification
                                                   object:managedObjectContext];
    }

    return managedObjectContext;
}

- (void)mergeChangesOnMainThreadWithNotification:(NSNotification *)notification
{
    assert([NSThread isMainThread]);
    [self.primaryManagedObjectContext performSelectorOnMainThread:@selector(mergeChangesFromContextDidSaveNotification:)
                                                withObject:notification
                                             waitUntilDone:YES];
}

- (void)mergeChanges:(NSNotification *)notification
{
    // Merge changes into the main context on the main thread
    [self performSelectorOnMainThread:@selector(mergeChangesOnMainThreadWithNotification:) withObject:notification waitUntilDone:YES];
}

#pragma mark -
#pragma mark Helpers

- (NSManagedObject *)objectWithID:(NSManagedObjectID *)objectID
{
    NSAssert(objectID, @"Cannot fetch a managedObject with a nil objectID");
    return [[self managedObjectContextForCurrentThread] objectWithID:objectID];
}

- (NSArray *)objectsWithIDs:(NSArray *)objectIDs
{
    NSMutableArray *objects = [[NSMutableArray alloc] init];
    for (NSManagedObjectID *objectID in objectIDs) {
        [objects addObject:[self objectWithID:objectID]];
    }
    NSArray *objectArray = [NSArray arrayWithArray:objects];
    [objects release];

    return objectArray;
}

@end
