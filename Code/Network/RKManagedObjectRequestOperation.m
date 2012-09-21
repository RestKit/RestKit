//
//  RKManagedObjectRequestOperation.m
//  RestKit
//
//  Created by Blake Watters on 8/9/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
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

#import "RKManagedObjectRequestOperation.h"
#import "RKLog.h"
#import "RKHTTPUtilities.h"
#import "RKResponseMapperOperation.h"
#import "RKRequestOperationSubclass.h"
#import "RKManagedObjectMappingOperationDataSource.h"
#import "NSManagedObjectContext+RKAdditions.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitCoreData

@interface RKManagedObjectRequestOperation () <RKMapperOperationDelegate>
// Core Data specific
@property (readwrite, nonatomic, strong) NSManagedObjectContext *privateContext;
@property (readwrite, nonatomic, copy) NSManagedObjectID *targetObjectID;
@property (readwrite, nonatomic, strong) NSMutableDictionary *managedObjectsByKeyPath;
@property (readwrite, nonatomic, strong) RKManagedObjectMappingOperationDataSource *dataSource;
@property (readwrite, nonatomic, strong) NSError *error;
@end

@implementation RKManagedObjectRequestOperation

- (void)setTargetObject:(id)targetObject
{
    [super setTargetObject:targetObject];

    if ([targetObject isKindOfClass:[NSManagedObject class]]) {
        self.targetObjectID = [targetObject objectID];
    }
}

- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    _managedObjectContext = managedObjectContext;

    // Create a private context
    NSManagedObjectContext *privateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [privateContext performBlockAndWait:^{
        privateContext.parentContext = self.managedObjectContext;
        privateContext.mergePolicy  = NSMergeByPropertyStoreTrumpMergePolicy;
    }];
    self.privateContext = privateContext;
}

#pragma mark - RKMapperOperationDelegate methods

- (void)mapper:(RKMapperOperation *)mapper didFinishMappingOperation:(RKMappingOperation *)mappingOperation forKeyPath:(NSString *)keyPath
{
    if ([mappingOperation.destinationObject isKindOfClass:[NSManagedObject class]]) {
        [self.managedObjectsByKeyPath setObject:mappingOperation.destinationObject forKey:keyPath];
    }
}

#pragma mark - RKObjectRequestOperation Overrides

- (RKMappingResult *)performMappingOnResponse:(NSError **)error
{
    if (self.isResponseFromCache) {
        RKLogDebug(@"Managed object mapping requested for cached response: skipping mapping...");
        // TODO: This is unexpectedly returning an empty result set... need to be able to retrieve the appropriate objects...
        return [[RKMappingResult alloc] initWithDictionary:@{}];
    }
    
    self.dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:self.privateContext
                                                                                                cache:self.managedObjectCache];
    self.dataSource.operationQueue = [NSOperationQueue new];
    [self.dataSource.operationQueue setSuspended:YES];
    [self.dataSource.operationQueue setMaxConcurrentOperationCount:1];

    // Spin up an RKObjectResponseMapperOperation
    RKManagedObjectResponseMapperOperation *mapperOperation = [[RKManagedObjectResponseMapperOperation alloc] initWithResponse:self.response
                                                                                                                          data:self.responseData
                                                                                                            responseDescriptors:self.responseDescriptors];
    mapperOperation.targetObjectID = self.targetObjectID;
    mapperOperation.managedObjectContext = self.privateContext;
    mapperOperation.managedObjectCache = self.managedObjectCache;
    mapperOperation.mappingOperationDataSource = self.dataSource;
    [mapperOperation start];
    [mapperOperation waitUntilFinished];
    if (mapperOperation.error) {
        *error = mapperOperation.error;
        return nil;
    }

    // Allow any enqueued operations to execute
    // TODO: This should be eliminated. The operations should be dependent on the mapper operation itself
    RKLogDebug(@"Unsuspending data source operation queue to process the following operations: %@", self.dataSource.operationQueue.operations);
    [self.dataSource.operationQueue setSuspended:NO];
    [self.dataSource.operationQueue waitUntilAllOperationsAreFinished];

    return mapperOperation.mappingResult;
}

- (BOOL)deleteTargetObjectIfAppropriate:(NSError **)error
{
    __block BOOL _blockSuccess = YES;

    if (self.targetObjectID
        && NSLocationInRange(self.response.statusCode, RKStatusCodeRangeForClass(RKStatusCodeClassSuccessful))
        && [[[self.request HTTPMethod] uppercaseString] isEqualToString:@"DELETE"]) {

        // 2xx DELETE request, proceed with deletion from the MOC
        __block NSError *_blockError = nil;
        [self.privateContext performBlockAndWait:^{
            NSManagedObject *backgroundThreadObject = [self.privateContext existingObjectWithID:self.targetObjectID error:&_blockError];
            if (backgroundThreadObject) {
                RKLogInfo(@"Deleting local object %@ due to `DELETE` request", backgroundThreadObject);
                [self.privateContext deleteObject:backgroundThreadObject];
            } else {
                RKLogWarning(@"Unable to delete object sent with `DELETE` request: Failed to retrieve object with objectID %@", self.targetObjectID);
                RKLogCoreDataError(_blockError);
                _blockSuccess = NO;
            }
        }];
    }

    return _blockSuccess;
}

- (NSSet *)localObjectsFromFetchRequestsMatchingRequestURL:(NSError **)error
{
    NSMutableSet *localObjects = [NSMutableSet set];
    NSURL *URL = [self.request URL];
    __block NSError *_blockError;
    __block NSArray *_blockObjects;

    for (RKFetchRequestBlock fetchRequestBlock in [self.fetchRequestBlocks reverseObjectEnumerator]) {
        NSFetchRequest *fetchRequest = fetchRequestBlock(URL);
        if (fetchRequest) {
            RKLogDebug(@"Found fetch request matching URL '%@': %@", URL, fetchRequest);

            [self.privateContext performBlockAndWait:^{
                _blockObjects = [self.privateContext executeFetchRequest:fetchRequest error:&_blockError];
            }];
            RKLogTrace(@"Fetched local objects matching URL '%@' with fetch request '%@': %@", URL, fetchRequest, _blockObjects);
            [localObjects addObjectsFromArray:_blockObjects];
        } else {
            RKLogDebug(@"Fetch request block %@ returned nil fetch request for URL: '%@'", fetchRequestBlock, URL);
        }
    }

    return localObjects;
}

- (BOOL)deleteLocalObjectsMissingFromMappingResult:(RKMappingResult *)result error:(NSError **)error
{
    if (! self.deletesOrphanedObjects) {
        RKLogDebug(@"Skipping deletion of orphaned objects: deletesOrphanedObjects=NO");
        return YES;
    }

    if (! [[self.request.HTTPMethod uppercaseString] isEqualToString:@"GET"]) {
        RKLogDebug(@"Skipping cleanup of objects via managed object cache: only used for GET requests.");
        return YES;
    }

    NSArray *results = [result array];
    NSSet *localObjects = [self localObjectsFromFetchRequestsMatchingRequestURL:error];
    if (! localObjects) return NO;
    for (id object in localObjects) {
        if (NO == [results containsObject:object]) {
            RKLogDebug(@"Deleting orphaned object %@: not found in result set and expected at this URL", object);
            [self.privateContext performBlockAndWait:^{
                [self.privateContext deleteObject:object];
            }];
        }
    }

    return YES;
}

- (BOOL)saveContext:(NSError **)error
{
    BOOL success = YES;
    if ([self.privateContext hasChanges]) {
        success = [self.privateContext saveToPersistentStore:error];
        if (! success) {
            RKLogError(@"Failed saving managed object context %@ to persistent store: ", self.privateContext);
            RKLogCoreDataError(*error);
        }
    }

    return success;
}

- (BOOL)obtainPermanentObjectIDsForInsertedObjects:(NSError **)error
{
    __block BOOL _blockSuccess = YES;
    NSArray *insertedObjects = [self.privateContext.insertedObjects allObjects];
    if ([insertedObjects count] > 0) {
        RKLogDebug(@"Obtaining permanent ID's for %ld managed objects", (unsigned long) [insertedObjects count]);
        [self.privateContext performBlockAndWait:^{
            _blockSuccess = [self.privateContext obtainPermanentIDsForObjects:insertedObjects error:error];
        }];
    }

    return _blockSuccess;;
}

- (void)willFinish
{
    BOOL success;
    NSError *error = nil;

    // Handle any cleanup
    success = [self deleteTargetObjectIfAppropriate:&error];
    if (! success) {
        self.error = error;
        return;
    }

    success = [self deleteLocalObjectsMissingFromMappingResult:self.mappingResult error:&error];
    if (! success) {
        self.error = error;
        return;
    }

    // Persist our mapped objects
    success = [self obtainPermanentObjectIDsForInsertedObjects:&error];
    if (! success) {
        self.error = error;
        return;
    }
    success = [self saveContext:&error];
    if (! success) self.error = error;
}

@end
