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
#import "NSManagedObjectContext+RKAdditions.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent RKlcl_cRestKitCoreData

NSFetchRequest *RKFetchRequestFromBlocksWithURL(NSArray *fetchRequestBlocks, NSURL *URL)
{
    NSFetchRequest *fetchRequest = nil;
    for (RKFetchRequestBlock block in [fetchRequestBlocks reverseObjectEnumerator]) {
        fetchRequest = block(URL);
        if (fetchRequest) break;
    }
    return fetchRequest;
}

@interface RKManagedObjectRequestOperation () <RKMapperOperationDelegate>
// Core Data specific
@property (readwrite, nonatomic, strong) NSManagedObjectContext *privateContext;
@property (readwrite, nonatomic, copy) NSManagedObjectID *targetObjectID;
@property (readwrite, nonatomic, strong) NSMutableDictionary *managedObjectsByKeyPath;
@property (readwrite, nonatomic, strong) NSError *error;
@property (nonatomic, strong) RKManagedObjectResponseMapperOperation *responseMapperOperation;
@end

@implementation RKManagedObjectRequestOperation

// Designated initializer
- (id)initWithHTTPRequestOperation:(RKHTTPRequestOperation *)requestOperation responseDescriptors:(NSArray *)responseDescriptors
{
    self = [super initWithHTTPRequestOperation:requestOperation responseDescriptors:responseDescriptors];
    if (self) {
        self.savesToPersistentStore = YES;
    }
    return self;
}

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

- (void)cancel
{
    [super cancel];
    [self.responseMapperOperation cancel];
}

- (RKMappingResult *)performMappingOnResponse:(NSError **)error
{
    if (self.HTTPRequestOperation.wasNotModified) {
        RKLogDebug(@"Managed object mapping requested for cached response: skipping mapping...");
        // TODO: This is unexpectedly returning an empty result set... need to be able to retrieve the appropriate objects...
        return [[RKMappingResult alloc] initWithDictionary:@{}];
    }

    self.responseMapperOperation = [[RKManagedObjectResponseMapperOperation alloc] initWithResponse:self.HTTPRequestOperation.response
                                                                                               data:self.HTTPRequestOperation.responseData
                                                                                responseDescriptors:self.responseDescriptors];
    self.responseMapperOperation.targetObjectID = self.targetObjectID;
    self.responseMapperOperation.managedObjectContext = self.privateContext;
    self.responseMapperOperation.managedObjectCache = self.managedObjectCache;
    [self.responseMapperOperation setQueuePriority:[self queuePriority]];
    [[RKObjectRequestOperation responseMappingQueue] addOperation:self.responseMapperOperation];
    [self.responseMapperOperation waitUntilFinished];
    if ([self isCancelled]) return nil;
    if (self.responseMapperOperation.error) {
        if (error) *error = self.responseMapperOperation.error;
        return nil;
    }

    return self.responseMapperOperation.mappingResult;
}

- (BOOL)deleteTargetObjectIfAppropriate:(NSError **)error
{
    __block BOOL _blockSuccess = YES;

    if (self.targetObjectID
        && NSLocationInRange(self.HTTPRequestOperation.response.statusCode, RKStatusCodeRangeForClass(RKStatusCodeClassSuccessful))
        && [[[self.HTTPRequestOperation.request HTTPMethod] uppercaseString] isEqualToString:@"DELETE"]) {

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
                *error = _blockError;
            }
        }];
    }

    return _blockSuccess;
}

- (NSSet *)localObjectsFromFetchRequestsMatchingRequestURL:(NSError **)error
{
    NSMutableSet *localObjects = [NSMutableSet set];    
    __block NSError *_blockError;
    __block NSArray *_blockObjects;
    
    // Pass the fetch request blocks a relative `NSURL` object if possible
    NSURL *URL = [self.HTTPRequestOperation.request URL];
    NSArray *baseURLs = [self.responseDescriptors valueForKeyPath:@"@distinctUnionOfObjects.baseURL"];
    if ([baseURLs count] == 1) {
        NSURL *baseURL = baseURLs[0];
        NSString *pathAndQueryString = RKPathAndQueryStringFromURLRelativeToURL(URL, baseURL);
        URL = [NSURL URLWithString:pathAndQueryString relativeToURL:baseURL];
    }

    for (RKFetchRequestBlock fetchRequestBlock in [self.fetchRequestBlocks reverseObjectEnumerator]) {
        NSFetchRequest *fetchRequest = fetchRequestBlock(URL);
        if (fetchRequest) {
            RKLogDebug(@"Found fetch request matching URL '%@': %@", URL, fetchRequest);

            [self.privateContext performBlockAndWait:^{
                _blockObjects = [self.privateContext executeFetchRequest:fetchRequest error:&_blockError];
            }];

            if (_blockObjects == nil) {
                if (error) *error = _blockError;
                return nil;
            }
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

    if (! [[self.HTTPRequestOperation.request.HTTPMethod uppercaseString] isEqualToString:@"GET"]) {
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
    __block BOOL success = YES;
    __block NSError *localError = nil;
    if ([self.privateContext hasChanges]) {
        if (self.savesToPersistentStore) {
            success = [self.privateContext saveToPersistentStore:&localError];
        } else {
            [self.privateContext performBlockAndWait:^{
                success = [self.privateContext save:&localError];
            }];
        }
        if (success) {
            if ([self.targetObject isKindOfClass:[NSManagedObject class]]) {
                [self.managedObjectContext performBlock:^{
                    RKLogDebug(@"Refreshing mapped target object %@ in context %@", self.targetObject, self.managedObjectContext);
                    [self.managedObjectContext refreshObject:self.targetObject mergeChanges:YES];
                }];
            }
        } else {
            if (error) *error = localError;
            RKLogError(@"Failed saving managed object context %@ %@", (self.savesToPersistentStore ? @"to the persistent store" : @""),  self.privateContext);
            RKLogCoreDataError(localError);
        }
    }

    return success;
}

- (BOOL)obtainPermanentObjectIDsForInsertedObjects:(NSError **)error
{
    __block BOOL _blockSuccess = YES;
    __block NSError *localError = nil;
    NSArray *insertedObjects = [self.privateContext.insertedObjects allObjects];
    if ([insertedObjects count] > 0) {
        RKLogDebug(@"Obtaining permanent ID's for %ld managed objects", (unsigned long) [insertedObjects count]);
        [self.privateContext performBlockAndWait:^{
            _blockSuccess = [self.privateContext obtainPermanentIDsForObjects:insertedObjects error:&localError];
        }];
        if (!_blockSuccess && error) *error = localError;
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
