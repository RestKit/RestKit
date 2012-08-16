//
//  RKManagedObjectLoader.m
//  RestKit
//
//  Created by Blake Watters on 2/13/11.
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

#import "RKObjectManager.h"
#import "RKManagedObjectLoader.h"
#import "RKURL.h"
#import "RKObjectMapper.h"
#import "RKManagedObjectThreadSafeInvocation.h"
#import "RKObjectLoader_Internals.h"
#import "RKRequest_Internals.h"
#import "RKObjectMappingProvider+CoreData.h"
#import "RKLog.h"
#import "RKManagedObjectMappingOperationDataSource.h"
#import "NSManagedObjectContext+RKAdditions.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitCoreData

@interface RKManagedObjectLoader ()

@property (nonatomic, retain) NSManagedObjectID *targetObjectID;
@property (nonatomic, retain) NSMutableDictionary *managedObjectsByKeyPath;
@property (nonatomic, retain) NSManagedObjectContext *privateContext;
@end

@implementation RKManagedObjectLoader

@synthesize mainQueueManagedObjectContext = _mainQueueManagedObjectContext;
@synthesize managedObjectContext = _parentManagedObjectContext;
@synthesize managedObjectCache = _managedObjectCache;
@synthesize privateContext = _privateContext;
@synthesize targetObjectID = _targetObjectID;
@synthesize managedObjectsByKeyPath = _managedObjectsByKeyPath;

- (id)initWithURL:(RKURL *)URL mappingProvider:(RKObjectMappingProvider *)mappingProvider
{
    self = [super initWithURL:URL mappingProvider:mappingProvider];
    if (self) {
        self.managedObjectsByKeyPath = [NSMutableDictionary dictionary];
        [self addObserver:self forKeyPath:@"managedObjectContext" options:0 context:nil];
        [self addObserver:self forKeyPath:@"targetObject" options:0 context:nil];
        [self addObserver:self forKeyPath:@"managedObjectCache" options:0 context:nil];
    }

    return self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"managedObjectContext"];
    [self removeObserver:self forKeyPath:@"targetObject"];
    [self removeObserver:self forKeyPath:@"managedObjectCache"];
    [_targetObjectID release];
    [_parentManagedObjectContext release];
    [_mainQueueManagedObjectContext release];
    [_managedObjectCache release];
    [_privateContext release];
    [_managedObjectsByKeyPath release];

    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"managedObjectContext"]) {
        self.privateContext = [[[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType] autorelease];
        [self.privateContext performBlockAndWait:^{
            self.privateContext.parentContext = self.managedObjectContext;
            self.privateContext.mergePolicy  = NSMergeByPropertyStoreTrumpMergePolicy;
        }];
        [self createMappingOperationDataSource];
    } else if ([keyPath isEqualToString:@"targetObject"]) {
        if (! [self.targetObject isKindOfClass:[NSManagedObject class]]) {
            self.targetObjectID = nil;
        }
    } else if ([keyPath isEqualToString:@"managedObjectCache"]) {
        [self createMappingOperationDataSource];
    }
}

- (void)createMappingOperationDataSource
{
    if (! self.privateContext) return;

    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:self.privateContext
                                                                                                                                      cache:self.managedObjectCache];
    dataSource.operationQueue = [[NSOperationQueue new] autorelease];
    [dataSource.operationQueue setSuspended:YES];
    [dataSource.operationQueue setMaxConcurrentOperationCount:1];
    dataSource.tracksInsertedObjects = YES; // We need to be able to obtain permanent object ID's
    self.mappingOperationDataSource = dataSource;
}

- (void)obtainPermanentObjectIDs
{
    NSMutableArray *objectsToObtainIDs = [NSMutableArray array];
    if ([self.sourceObject isKindOfClass:[NSManagedObject class]]) [objectsToObtainIDs addObject:self.sourceObject];
    if ([self.targetObject isKindOfClass:[NSManagedObject class]]) [objectsToObtainIDs addObject:self.targetObject];
    
    if ([objectsToObtainIDs count] > 0) {
        [self.privateContext performBlock:^{
            NSError *error;
            BOOL success = [self.privateContext obtainPermanentIDsForObjects:objectsToObtainIDs error:&error];
            if (! success) {
                RKLogError(@"Failed to obtain permanent object ID's for %ld objects: %@", (unsigned long) [objectsToObtainIDs count], error);
            }
            
            if ([self.targetObject isKindOfClass:[NSManagedObject class]]) {
                self.targetObjectID = [(NSManagedObject *)self.targetObject objectID];
            }            
        }];
    }
}

- (BOOL)prepareURLRequest
{
    [self obtainPermanentObjectIDs];
    return [super prepareURLRequest];
}

#pragma mark - RKObjectMapperDelegate methods

- (void)mapper:(RKObjectMapper *)objectMapper didMapFromObject:(id)sourceObject toObject:(id)destinationObject atKeyPath:(NSString *)keyPath usingMapping:(RKObjectMapping *)objectMapping
{
    if ([destinationObject isKindOfClass:[NSManagedObject class]]) {
        [self.managedObjectsByKeyPath setObject:destinationObject forKey:keyPath];
    }
}

#pragma mark - RKObjectLoader overrides

- (RKMappingResult *)performMappingWithMapper:(RKObjectMapper *)mapper
{
    __block RKMappingResult *mappingResult = nil;

    // Map it
    [self.privateContext performBlockAndWait:^{
        NSError *error;
        if (self.targetObjectID) {
            NSManagedObject *localObject = [self.privateContext existingObjectWithID:self.targetObjectID error:&error];
            if (! localObject) {
                RKLogWarning(@"Failed to retrieve existing object with ID: %@", self.targetObjectID);
                RKLogCoreDataError(error);
            }

            mapper.targetObject = localObject;
        }
        mappingResult = [mapper performMapping];
    }];

    // Allow any enqueued operations to execute
    RKManagedObjectMappingOperationDataSource *dataSource = self.mappingOperationDataSource;
    // TODO: This should be eliminated. The operations should be dependent on the mapper operation itself
    RKLogDebug(@"Unsuspending data source operation queue to process the following operations: %@", dataSource.operationQueue.operations);
    [dataSource.operationQueue setSuspended:NO];
    [dataSource.operationQueue waitUntilAllOperationsAreFinished];

    return mappingResult;
}

- (NSArray *)cachedObjects
{
    NSFetchRequest *fetchRequest = [self.mappingProvider fetchRequestForResourcePath:self.resourcePath];
    if (fetchRequest) {
        __block NSError *error = nil;
        __block NSArray *cachedObjects;
        [self.privateContext performBlockAndWait:^{
            cachedObjects = [self.privateContext executeFetchRequest:fetchRequest error:&error];
        }];
        if (! cachedObjects) {
            RKLogError(@"Failed to retrieve cached objects with error: %@", error);
        }
        return cachedObjects;
    }

    return nil;
}

- (void)deleteCachedObjectsMissingFromResult:(RKMappingResult *)result
{
    if (! [self isGET]) {
        RKLogDebug(@"Skipping cleanup of objects via managed object cache: only used for GET requests.");
        return;
    }

    if ([self.URL isKindOfClass:[RKURL class]]) {
        NSArray *results = [result asCollection];
        NSArray *cachedObjects = [self cachedObjects];
        for (id object in cachedObjects) {
            if (NO == [results containsObject:object]) {
                RKLogDebug(@"Deleting orphaned object %@: not found in result set and expected at this resource path", object);
                [self.privateContext performBlockAndWait:^{
                    [self.privateContext deleteObject:object];
                }];
            }
        }
    } else {
        RKLogWarning(@"Unable to perform cleanup of server-side object deletions: unable to determine resource path.");
    }
}

// NOTE: We are on the background thread here, be mindful of Core Data's threading needs
- (void)processMappingResult:(RKMappingResult *)result
{
    NSAssert(_sentSynchronously || ![NSThread isMainThread], @"Mapping result processing should occur on a background thread");
    NSAssert([self.mappingOperationDataSource isKindOfClass:[RKManagedObjectMappingOperationDataSource class]], @"Expected a managed object mapping operation data source but got a %@", [self.mappingOperationDataSource class]);
    if (self.targetObjectID && self.targetObject && self.method == RKRequestMethodDELETE) {
        [self.privateContext performBlockAndWait:^{
            NSError *error;
            NSManagedObject *backgroundThreadObject = [self.privateContext existingObjectWithID:self.targetObjectID error:&error];
            if (backgroundThreadObject) {
                RKLogInfo(@"Deleting local object %@ due to DELETE request", backgroundThreadObject);
                [self.privateContext deleteObject:backgroundThreadObject];
            } else {
                RKLogWarning(@"Unable to delete object sent with DELETE request: Failed to retrieve object with objectID %@", self.targetObjectID);
                RKLogCoreDataError(error);
            }
        }];
    }

    // If the response was successful, save the store...
    if ([self.response isSuccessful]) {
        [self deleteCachedObjectsMissingFromResult:result];
        __block BOOL success = NO;
        __block NSError *error = nil;
            
        NSArray *insertedObjects = [(RKManagedObjectMappingOperationDataSource *)self.mappingOperationDataSource insertedObjects];
        RKLogDebug(@"Obtaining permanent object ID's for %ld objects", (unsigned long) [insertedObjects count]);
        [self.privateContext performBlockAndWait:^{
            success = [self.privateContext obtainPermanentIDsForObjects:insertedObjects error:&error];
        }];
        
        if (! success) {
            RKLogError(@"Failed to obtain permanent object ID's for %ld managed objects. Error: %@", (unsigned long) [insertedObjects count], [error localizedDescription]);
        }
        
        [self.privateContext performBlockAndWait:^{
            success = [self.privateContext save:&error];
        }];
        if (! success) {
            RKLogError(@"Failed to save managed object context after mapping completed: %@", [error localizedDescription]);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self performSelector:@selector(informDelegateOfError:) withObject:error];
                [self finalizeLoad:success];
            });
            return;
        }
    }

    NSDictionary *dictionary = [result asDictionary];
    NSMethodSignature *signature = [self methodSignatureForSelector:@selector(informDelegateOfObjectLoadWithResultDictionary:)];

    // Save back to the persistent store
    NSError *error = nil;
    BOOL success = [self.privateContext saveToPersistentStore:&error];
    if (! success) {
        RKLogError(@"Failed saving managed object context %@ to persistent store: ", self.privateContext);
        RKLogCoreDataError(error);
    }

    RKManagedObjectThreadSafeInvocation *invocation = [RKManagedObjectThreadSafeInvocation invocationWithMethodSignature:signature];
    invocation.mainQueueManagedObjectContext = self.mainQueueManagedObjectContext;
    invocation.privateQueueManagedObjectContext = self.privateContext;
    invocation.target = self;
    invocation.selector = @selector(informDelegateOfObjectLoadWithResultDictionary:);
    [invocation setArgument:&dictionary atIndex:2];
    [invocation setManagedObjectKeyPaths:[NSSet setWithArray:[self.managedObjectsByKeyPath allKeys]] forArgument:2];
    [invocation invokeOnMainThread];
}

- (BOOL)isResponseMappable
{
    if ([self.response wasLoadedFromCache]) {
        NSArray *cachedObjects = [self cachedObjects];
        if (! cachedObjects) {
            RKLogDebug(@"Skipping managed object mapping optimization -> Managed object cache returned nil cachedObjects for resourcePath: %@", self.resourcePath);
            return [super isResponseMappable];
        }
        [self informDelegateOfObjectLoadWithResultDictionary:[NSDictionary dictionaryWithObject:cachedObjects forKey:@""]];
        return NO;
    }
    return [super isResponseMappable];
}

@end


@implementation RKManagedObjectLoader (Deprecations)

+ (id)loaderWithURL:(RKURL *)URL mappingProvider:(RKObjectMappingProvider *)mappingProvider objectStore:(RKManagedObjectStore *)objectStore DEPRECATED_ATTRIBUTE
{
    return [[[self alloc] initWithURL:URL mappingProvider:mappingProvider objectStore:objectStore] autorelease];
}

- (id)initWithURL:(RKURL *)URL mappingProvider:(RKObjectMappingProvider *)mappingProvider objectStore:(RKManagedObjectStore *)objectStore DEPRECATED_ATTRIBUTE
{
    self = [self initWithURL:URL mappingProvider:mappingProvider];
    if (self) {
        self.managedObjectContext = objectStore.primaryManagedObjectContext;
        self.mainQueueManagedObjectContext = objectStore.mainQueueManagedObjectContext;
    }

    return self;
}

@end
