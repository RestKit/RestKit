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

NSArray *RKArrayOfFetchRequestFromBlocksWithURL(NSArray *fetchRequestBlocks, NSURL *URL)
{
    NSMutableArray *fetchRequests = [NSMutableArray array];
    NSFetchRequest *fetchRequest = nil;
    for (RKFetchRequestBlock block in [fetchRequestBlocks reverseObjectEnumerator]) {
        fetchRequest = block(URL);
        if (fetchRequest) [fetchRequests addObject:fetchRequest];
    }
    return fetchRequests;
}

static NSDictionary *RKDictionaryOfManagedObjectsInContextFromDictionaryOfManagedObjects(NSDictionary *dictionaryOfManagedObjects, NSManagedObjectContext *managedObjectContext)
{
    NSMutableDictionary *newDictionary = [[NSMutableDictionary alloc] initWithCapacity:[dictionaryOfManagedObjects count]];
    [managedObjectContext performBlockAndWait:^{
        NSError *error = nil;
        for (NSString *key in dictionaryOfManagedObjects) {
            id value = dictionaryOfManagedObjects[key];
            if ([value isKindOfClass:[NSArray class]]) {
                NSMutableArray *newValue = [[NSMutableArray alloc] initWithCapacity:[value count]];
                for (__strong id object in value) {
                    if ([object isKindOfClass:[NSManagedObject class]]) {
                        object = [managedObjectContext existingObjectWithID:[object objectID] error:&error];
                        NSCAssert(object, @"Failed to find existing object with ID %@ in context %@: %@", [object objectID], managedObjectContext, error);
                    }
                    
                    [newValue addObject:object];
                }
                value = [newValue copy];
            } else if ([value isKindOfClass:[NSManagedObject class]]) {
                value = [managedObjectContext existingObjectWithID:[value objectID] error:&error];
                NSCAssert(value, @"Failed to find existing object with ID %@ in context %@: %@", [value objectID], managedObjectContext, error);
            }
            
            [newDictionary setValue:value forKey:key];
        }
    }];
    
    return newDictionary;
}

static NSURL *RKRelativeURLFromURLAndResponseDescriptors(NSURL *URL, NSArray *responseDescriptors)
{
    NSCParameterAssert(URL);
    NSCParameterAssert(responseDescriptors);
    NSArray *baseURLs = [responseDescriptors valueForKeyPath:@"@distinctUnionOfObjects.baseURL"];
    if ([baseURLs count] == 1) {
        NSURL *baseURL = baseURLs[0];
        NSString *pathAndQueryString = RKPathAndQueryStringFromURLRelativeToURL(URL, baseURL);
        URL = [NSURL URLWithString:pathAndQueryString relativeToURL:baseURL];
    }
    
    return URL;
}

@interface RKManagedObjectRequestOperation ()
// Core Data specific
@property (nonatomic, strong) NSManagedObjectContext *privateContext;
@property (nonatomic, copy) NSManagedObjectID *targetObjectID;
@property (nonatomic, strong) RKManagedObjectResponseMapperOperation *responseMapperOperation;
@property (nonatomic, strong, readwrite) NSError *error;
@property (nonatomic, strong, readwrite) RKMappingResult *mappingResult;
@property (nonatomic, copy) id (^willMapDeserializedResponseBlock)(id deserializedResponseBody);
@end

@implementation RKManagedObjectRequestOperation

@dynamic willMapDeserializedResponseBlock;

// Designated initializer
- (id)initWithHTTPRequestOperation:(RKHTTPRequestOperation *)requestOperation responseDescriptors:(NSArray *)responseDescriptors
{
    self = [super initWithHTTPRequestOperation:requestOperation responseDescriptors:responseDescriptors];
    if (self) {
        self.savesToPersistentStore = YES;
        self.deletesOrphanedObjects = YES;
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

    if (managedObjectContext) {
        // Create a private context
        NSManagedObjectContext *privateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [privateContext performBlockAndWait:^{
            privateContext.parentContext = managedObjectContext;
            privateContext.mergePolicy  = NSMergeByPropertyStoreTrumpMergePolicy;
        }];
        self.privateContext = privateContext;
    } else {
        self.privateContext = nil;
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
        NSURL *URL = RKRelativeURLFromURLAndResponseDescriptors(self.HTTPRequestOperation.response.URL, self.responseDescriptors);
        NSArray *fetchRequests = RKArrayOfFetchRequestFromBlocksWithURL(self.fetchRequestBlocks, URL);
        NSMutableArray *managedObjects = [NSMutableArray array];
        [self.privateContext performBlockAndWait:^{
            NSError *error = nil;
            for (NSFetchRequest *fetchRequest in fetchRequests) {
                NSArray *fetchedObjects = [self.privateContext executeFetchRequest:fetchRequest error:&error];
                if (fetchedObjects) {
                    [managedObjects addObjectsFromArray:fetchedObjects];
                } else {
                    RKLogError(@"Failed to execute fetch request %@: %@", fetchRequest, error);
                }
            }
        }];
        return [[RKMappingResult alloc] initWithDictionary:@{ [NSNull null]: managedObjects }];
    }

    self.responseMapperOperation = [[RKManagedObjectResponseMapperOperation alloc] initWithResponse:self.HTTPRequestOperation.response
                                                                                               data:self.HTTPRequestOperation.responseData
                                                                                responseDescriptors:self.responseDescriptors];
    self.responseMapperOperation.mapperDelegate = self;
    self.responseMapperOperation.targetObjectID = self.targetObjectID;
    self.responseMapperOperation.managedObjectContext = self.privateContext;
    self.responseMapperOperation.managedObjectCache = self.managedObjectCache;
    [self.responseMapperOperation setWillMapDeserializedResponseBlock:self.willMapDeserializedResponseBlock];
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
    NSURL *URL = RKRelativeURLFromURLAndResponseDescriptors(self.HTTPRequestOperation.response.URL, self.responseDescriptors);
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
    
    // Refetch the mapping results from the externally configured context
    NSDictionary *resultsDictionaryFromOriginalContext = RKDictionaryOfManagedObjectsInContextFromDictionaryOfManagedObjects([self.mappingResult dictionary], self.managedObjectContext);
    self.mappingResult = [[RKMappingResult alloc] initWithDictionary:resultsDictionaryFromOriginalContext];
}

@end
