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
#import "RKMapperOperation.h"
#import "RKManagedObjectMappingOperationDataSource.h"
#import "RKInMemoryManagedObjectCache.h"
#import "RKMIMETypeSerialization.h"
#import "RKPathUtilities.h"
#import "RKLog.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent RKlcl_cRestKitCoreData

@interface RKManagedObjectImporter ()
@property (nonatomic, strong, readwrite) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong, readwrite) NSString *storePath;
@property (nonatomic, strong, readwrite) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong, readwrite) NSPersistentStore *persistentStore;
@property (nonatomic, strong, readwrite) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong, readwrite) RKManagedObjectMappingOperationDataSource *mappingOperationDataSource;
@property (nonatomic, strong, readwrite) NSOperationQueue *connectionQueue;
@property (nonatomic, assign) BOOL hasPerformedResetIfNecessary;
@end

@implementation RKManagedObjectImporter

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

        NSManagedObjectContext *managedObjectContext = [self createManagedObjectContext];
        NSAssert(managedObjectContext, @"Importer initialization failed: Unable to create managed object context");
        self.managedObjectContext = managedObjectContext;

        self.connectionQueue = [NSOperationQueue new];
        [self.connectionQueue setName:@"RKManagedObjectImporter Connection Queue"];
        [self.connectionQueue setSuspended:YES];

        RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [self createMappingOperationDataSource];
        self.mappingOperationDataSource = mappingOperationDataSource;

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

        self.connectionQueue = [NSOperationQueue new];
        [self.connectionQueue setName:@"RKManagedObjectImporter Connection Queue"];
        [self.connectionQueue setSuspended:YES];

        RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [self createMappingOperationDataSource];
        self.mappingOperationDataSource = mappingOperationDataSource;

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
    NSAssert(self.connectionQueue, @"Connection Queue cannot be nil");
    RKInMemoryManagedObjectCache *managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:self.managedObjectContext];
    RKManagedObjectMappingOperationDataSource *mappingOperationDataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:self.managedObjectContext
                                                                                                                                                      cache:managedObjectCache];
    mappingOperationDataSource.operationQueue = self.connectionQueue;

    return mappingOperationDataSource;
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
    NSParameterAssert(path);
    NSParameterAssert(mapping);

    // Perform the reset on the first import action if requested
    [self resetPersistentStoreIfNecessary];

    __block NSError *localError = nil;
    NSData *payload = [NSData dataWithContentsOfFile:path options:0 error:&localError];
    if (! payload) {
        RKLogError(@"Failed to read file at path '%@': %@", path, [localError localizedDescription]);
        if (error) *error = localError;
        return NSNotFound;
    }

    NSString *MIMEType = RKMIMETypeFromPathExtension(path);
    id parsedData = [RKMIMETypeSerialization objectFromData:payload MIMEType:MIMEType error:&localError];
    if (!parsedData) {
        RKLogError(@"Failed to parse file at path '%@': %@", path, [localError localizedDescription]);
    }
    
    if (! parsedData) {
        if (error) *error = localError;
        return NSNotFound;
    }

    NSDictionary *mappingDictionary = @{ (keyPath ?: [NSNull null]) : mapping };
    RKMapperOperation *mapper = [[RKMapperOperation alloc] initWithObject:parsedData mappingsDictionary:mappingDictionary];
    mapper.mappingOperationDataSource = self.mappingOperationDataSource;
    __block RKMappingResult *mappingResult;
    [self.managedObjectContext performBlockAndWait:^{
        [mapper start];
        mappingResult = mapper.mappingResult;
        localError = mapper.error;
    }];
    if (mappingResult == nil) {
        if (error) *error = localError;
        RKLogError(@"Importing file at path '%@' failed with error: %@", path, localError);
        return NSNotFound;
    }

    NSUInteger objectCount = [mappingResult count];
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
    // Perform our connection operations in a batch, before we save the MOC
    [self.connectionQueue setSuspended:NO];
    [self.connectionQueue waitUntilAllOperationsAreFinished];

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
