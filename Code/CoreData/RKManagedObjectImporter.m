//
//  RKManagedObjectImporter.m
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

#if TARGET_OS_IPHONE
#import <MobileCoreServices/UTType.h>
#endif

#import "RKManagedObjectImporter.h"
#import "RKObjectMapper.h"
#import "RKObjectMappingProvider+CoreData.h"
#import "RKManagedObjectMappingOperationDataSource.h"
#import "RKInMemoryManagedObjectCache.h"
#import "NSString+RKAdditions.h"
#import "RKParserRegistry.h"
#import "RKLog.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitCoreData

@interface RKManagedObjectImporter ()
@property (nonatomic, retain, readwrite) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readwrite) NSString *storePath;
@property (nonatomic, retain, readwrite) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readwrite) NSPersistentStore *persistentStore;
@property (nonatomic, retain, readwrite) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readwrite) RKManagedObjectMappingOperationDataSource *mappingOperationDataSource;
@property (nonatomic, assign) BOOL hasPerformedResetIfNecessary;
@end

@implementation RKManagedObjectImporter

@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize persistentStore = _persistentStore;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize mappingOperationDataSource = _mappingOperationDataSource;

- (id)initWithManagedObjectModel:(NSManagedObjectModel *)managedObjectModel storePath:(NSString *)storePath
{
    NSParameterAssert(managedObjectModel);
    NSParameterAssert(storePath);

    self = [super init];
    if (self) {
        self.managedObjectModel = managedObjectModel;
        self.storePath = storePath;

        NSError *error = nil;
        NSPersistentStoreCoordinator *persistentStoreCoordinator = [self createPersistentStoreCoordinator:&error];
        NSAssert(persistentStoreCoordinator, @"Importer initialization failed: Unable to create persistent store coordinator: %@", error);
        self.persistentStoreCoordinator = persistentStoreCoordinator;
        [persistentStoreCoordinator release];

        NSManagedObjectContext *managedObjectContext = [self createManagedObjectContext];
        NSAssert(managedObjectContext, @"Importer initialization failed: Unable to create managed object context");
        self.managedObjectContext = managedObjectContext;
        [managedObjectContext release];

        RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [self createMappingOperationDataSource];
        self.mappingOperationDataSource = mappingOperationDataSource;
        [mappingOperationDataSource release];

        self.hasPerformedResetIfNecessary = NO;
        self.resetsStoreBeforeImporting = YES;
    }

    return self;
}

- (id)initWithPersistentStore:(NSPersistentStore *)persistentStore
{
    NSParameterAssert(persistentStore);

    self = [super init];
    if (self) {
        self.persistentStoreCoordinator = persistentStore.persistentStoreCoordinator;
        self.managedObjectModel = persistentStore.persistentStoreCoordinator.managedObjectModel;

        NSURL *storeURL = [self.persistentStoreCoordinator URLForPersistentStore:persistentStore];
        self.storePath = [storeURL path];

        NSManagedObjectContext *managedObjectContext = [self createManagedObjectContext];
        NSAssert(managedObjectContext, @"Importer initialization failed: Unable to create managed object store");
        self.managedObjectContext = managedObjectContext;
        [managedObjectContext release];

        RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [self createMappingOperationDataSource];
        self.mappingOperationDataSource = mappingOperationDataSource;
        [mappingOperationDataSource release];

        self.hasPerformedResetIfNecessary = NO;
        self.resetsStoreBeforeImporting = NO;
    }

    return self;
}

- (id)init
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"%@ Failed to call designated initializer. Invoke initWithManagedObjectModel:storePath: instead.",
                                           NSStringFromClass([self class])]
                                 userInfo:nil];
}

- (NSPersistentStoreCoordinator *)createPersistentStoreCoordinator:(NSError **)error
{
    BOOL isDirectory = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:self.storePath isDirectory:&isDirectory];
    NSAssert(!isDirectory, @"Cannot create SQLite persistent store: The given store path specifies a directory.");

    NSURL *storeURL = [NSURL fileURLWithPath:self.storePath];
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
    NSPersistentStore *persistentStore = [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                                  configuration:nil
                                                                                            URL:storeURL
                                                                                        options:nil error:error];
    if (! persistentStore) {
        [persistentStoreCoordinator release];
        return nil;
    }

    return persistentStoreCoordinator;
}

- (NSManagedObjectContext *)createManagedObjectContext
{
    NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [managedObjectContext performBlockAndWait:^{
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
        managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
    }];

    return managedObjectContext;
}

- (RKManagedObjectMappingOperationDataSource *)createMappingOperationDataSource
{
    RKInMemoryManagedObjectCache *managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:self.managedObjectContext];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:self.managedObjectContext
                                                                                                                                                      cache:managedObjectCache];

    return mappingOperationDataSource;
}

- (void)dealloc
{
    [_managedObjectModel release];
    [_persistentStoreCoordinator release];
    [_managedObjectContext release];
    [_mappingOperationDataSource release];
    [super dealloc];
}

- (void)resetPersistentStoreIfNecessary
{
    if (self.hasPerformedResetIfNecessary) return;

    if (self.resetsStoreBeforeImporting) {
        RKLogInfo(@"Persistent store reset requested before importing. Deleting existing managed object instances...");
        for (NSEntityDescription *entity in self.managedObjectModel.entities) {
            @autoreleasepool {
                NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
                fetchRequest.entity = entity;
                [self.managedObjectContext performBlockAndWait:^{
                    NSError *error;
                    NSArray *managedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
                    RKLogInfo(@"Deleting %ld managed object instances for the '%@' entity", (unsigned long) [managedObjects count], entity.name);
                    for (NSManagedObject *managedObject in managedObjects) {
                        [self.managedObjectContext deleteObject:managedObject];
                    }
                }];
            }
        }
    }

    self.hasPerformedResetIfNecessary = YES;
}

- (NSUInteger)importObjectsFromFileAtPath:(NSString *)path withMapping:(RKMapping *)mapping keyPath:(NSString *)keyPath error:(NSError **)error
{
    // Perform the reset on the first import action if requested
    [self resetPersistentStoreIfNecessary];

    NSError *localError = nil;
    NSString *payload = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&localError];
    if (! payload) {
        RKLogError(@"Failed to read file at path '%@': %@", path, [localError localizedDescription]);
        if (error) *error = localError;
        return NSNotFound;
    }

    NSString *MIMEType = [path MIMETypeForPathExtension];
    id<RKParser> parser = [[RKParserRegistry sharedRegistry] parserForMIMEType:MIMEType];
    // TODO: Return error RKParserNotRegisteredForMIMETypeError
    NSAssert1(parser, @"Could not find a parser for the MIME Type '%@'", MIMEType);
    id parsedData = [parser objectFromString:payload error:&localError];
    if (! parsedData) {
        if (error) *error = localError;
        return NSNotFound;
    }

    RKObjectMappingProvider *mappingProvider = [[RKObjectMappingProvider new] autorelease];
    [mappingProvider setMapping:mapping forKeyPath:keyPath ? keyPath : @""];

    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:parsedData mappingProvider:mappingProvider];
    mapper.mappingOperationDataSource = self.mappingOperationDataSource;
    __block RKMappingResult *mappingResult;
    [self.managedObjectContext performBlockAndWait:^{
        mappingResult = [mapper performMapping];
    }];
    if (mappingResult == nil) {
        // TODO: Return error
        RKLogError(@"Importing file at path '%@' failed with mapping errors: %@", path, mapper.errors);
        return NSNotFound;
    }

    NSUInteger objectCount = [[mappingResult asCollection] count];
    RKLogInfo(@"Imported %lu objects from file at path '%@'", (unsigned long)objectCount, path);
    return objectCount;
}

- (NSUInteger)importObjectsFromDirectoryAtPath:(NSString *)path withMapping:(RKMapping *)mapping keyPath:(NSString *)keyPath error:(NSError **)error
{
    NSError *localError = nil;
    NSArray *entries = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&localError];
    if (! entries) {
        RKLogError(@"Import failed for directory at path '%@': Unable to read directory contents with error: %@", path, localError);
        if (error) *error = localError;
        return NSNotFound;
    }

    NSUInteger aggregateObjectCount = 0;
    for (NSString *entry in entries) {
        NSUInteger objectCount = [self importObjectsFromFileAtPath:path withMapping:mapping keyPath:keyPath error:&localError];
        if (objectCount == NSNotFound) {
            if (error) *error = localError;
            return NSNotFound;
        } else {
            aggregateObjectCount += objectCount;
        }
    }

    return aggregateObjectCount;
}

- (NSUInteger)importObjectsFromItemAtPath:(NSString *)path withMapping:(RKMapping *)mapping keyPath:(NSString *)keyPath error:(NSError **)error
{
    NSParameterAssert(path);
    NSParameterAssert(mapping);

    BOOL isDirectory;
    [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory];
    if (isDirectory) {
        return [self importObjectsFromDirectoryAtPath:path withMapping:mapping keyPath:keyPath error:error];
    }

    return [self importObjectsFromFileAtPath:path withMapping:mapping keyPath:keyPath error:error];
}

- (BOOL)finishImporting:(NSError **)error
{
    __block BOOL success;
    __block NSError *localError = nil;
    [self.managedObjectContext performBlockAndWait:^{
        success = [self.managedObjectContext save:&localError];
        if (! success) {
            RKLogCoreDataError(localError);
        }
    }];

    if (! success && error) *error = localError;
    return success;
}

- (void)logSeedingInfo
{
    NSString *storeDirectory = [self.storePath stringByDeletingLastPathComponent];
    NSString *storeFilename = [self.storePath lastPathComponent];
    RKLogCritical(@"A seed database has been generated at '%@'. "
                  @"Please execute `open \"%@\"` in your Terminal and copy %@ to your app. Be sure to add the seed database to your \"Copy Resources\" build phase.",
                  self.storePath, storeDirectory, storeFilename);
}

@end
