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
#import "NSManagedObject+RKAdditions.h"
#import "RKObjectUtilities.h"

// Graph visitor
#import "RKResponseDescriptor.h"
#import "RKEntityMapping.h"
#import "RKDynamicMapping.h"
#import "RKRelationshipMapping.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent RKlcl_cRestKitNetworkCoreData

@interface RKEntityMappingEvent : NSObject
@property (nonatomic, copy) id rootKey;
@property (nonatomic, copy) NSString *keyPath;
@property (nonatomic, strong) RKEntityMapping *entityMapping;

+ (instancetype)eventWithRootKey:(id)rootKey keyPath:(NSString *)keyPath entityMapping:(RKEntityMapping *)entityMapping;
@end

@implementation RKEntityMappingEvent
+ (instancetype)eventWithRootKey:(id)rootKey keyPath:(NSString *)keyPath entityMapping:(RKEntityMapping *)entityMapping
{
    RKEntityMappingEvent *event = [RKEntityMappingEvent new];
    event.rootKey = rootKey;
    event.keyPath = keyPath;
    event.entityMapping = entityMapping;
    return event;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p rootKey=%@ keyPath=%@ entityMapping=%@>",
            [self class], self, self.rootKey, self.keyPath, self.entityMapping];
}
@end

/**
 Returns the set of keys containing the outermost nesting keypath for all children.
 For example, given a set containing: 'this', 'this.that', 'another.one.test', 'another.two.test', 'another.one.test.nested'
 would return: 'this, 'another.one', 'another.two'
 */
NSSet *RKSetByRemovingSubkeypathsFromSet(NSSet *setOfKeyPaths);
NSSet *RKSetByRemovingSubkeypathsFromSet(NSSet *setOfKeyPaths)
{
    return [setOfKeyPaths objectsPassingTest:^BOOL(NSString *keyPath, BOOL *stop) {
        if ([keyPath isEqual:[NSNull null]]) return YES; // Special case the root key path
        NSArray *keyPathComponents = [keyPath componentsSeparatedByString:@"."];
        NSMutableSet *parentKeyPaths = [NSMutableSet set];
        for (NSUInteger index = 0; index < [keyPathComponents count] - 1; index++) {
            [parentKeyPaths addObject:[[keyPathComponents subarrayWithRange:NSMakeRange(0, index + 1)] componentsJoinedByString:@"."]];
        }
        for (NSString *parentKeyPath in parentKeyPaths) {
            if ([setOfKeyPaths containsObject:parentKeyPath]) return NO;
        }
        return YES;
    }];
}

// Precondition: Must be called from within the correct context
static NSManagedObject *RKRefetchManagedObjectInContext(NSManagedObject *managedObject, NSManagedObjectContext *managedObjectContext)
{
    NSManagedObjectID *managedObjectID = [managedObject objectID];
    if (! [managedObject managedObjectContext]) return nil; // Object has been deleted
    if ([managedObjectID isTemporaryID]) {
        RKLogWarning(@"Unable to refetch managed object %@: the object has a temporary managed object ID.", managedObject);
        return managedObject;
    }
    NSError *error = nil;
    NSManagedObject *refetchedObject = [managedObjectContext existingObjectWithID:managedObjectID error:&error];
    NSCAssert(refetchedObject, @"Failed to find existing object with ID %@ in context %@: %@", managedObjectID, managedObjectContext, error);
    return refetchedObject;
}

static id RKRefetchedValueInManagedObjectContext(id value, NSManagedObjectContext *managedObjectContext)
{
    if (! value) {
        return value;
    } else if ([value isKindOfClass:[NSArray class]]) {
        BOOL isMutable = [value isKindOfClass:[NSMutableArray class]];
        NSMutableArray *newValue = [[NSMutableArray alloc] initWithCapacity:[value count]];
        for (__strong id object in value) {
            if ([object isKindOfClass:[NSManagedObject class]]) object = RKRefetchManagedObjectInContext(object, managedObjectContext);
            if (object) [newValue addObject:object];
        }
        value = (isMutable) ? newValue : [newValue copy];
    } else if ([value isKindOfClass:[NSSet class]]) {
        BOOL isMutable = [value isKindOfClass:[NSMutableSet class]];
        NSMutableSet *newValue = [[NSMutableSet alloc] initWithCapacity:[value count]];
        for (__strong id object in value) {
            if ([object isKindOfClass:[NSManagedObject class]]) object = RKRefetchManagedObjectInContext(object, managedObjectContext);
            if (object) [newValue addObject:object];
        }
        value = (isMutable) ? newValue : [newValue copy];
    } else if ([value isKindOfClass:[NSOrderedSet class]]) {
        BOOL isMutable = [value isKindOfClass:[NSMutableOrderedSet class]];
        NSMutableOrderedSet *newValue = [NSMutableOrderedSet orderedSet];
        [(NSOrderedSet *)value enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL *stop) {
            if ([object isKindOfClass:[NSManagedObject class]]) object = RKRefetchManagedObjectInContext(object, managedObjectContext);
            if (object) [newValue setObject:object atIndex:index];
        }];
        value = (isMutable) ? newValue : [newValue copy];
    } else if ([value isKindOfClass:[NSManagedObject class]]) {
        value = RKRefetchManagedObjectInContext(value, managedObjectContext);
    }
    
    return value;
}

/**
 This is an NSProxy object that stands in for the mapping result and provides support for refetching the results on demand. This enables us to defer the refetching until someone accesses the results directly. For managed object request operations that do not use the mapping result (such as those used in conjunction with a NSFetchedResultsController), the refetching will be skipped entirely.
 */
@interface RKRefetchingMappingResult : NSProxy

- (id)initWithMappingResult:(RKMappingResult *)mappingResult
       managedObjectContext:(NSManagedObjectContext *)managedObjectContext
        entityMappingEvents:(NSArray *)entityMappingEvents;
@end

@interface RKRefetchingMappingResult ()
@property (nonatomic, strong) RKMappingResult *mappingResult;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSArray *entityMappingEvents;
@property (nonatomic, assign) BOOL refetched;
@end

@implementation RKRefetchingMappingResult

+ (NSString *)description
{
    return [[super description] stringByAppendingString:@"_RKRefetchingMappingResult"];
}

- (id)initWithMappingResult:(RKMappingResult *)mappingResult
       managedObjectContext:(NSManagedObjectContext *)managedObjectContext
        entityMappingEvents:(NSArray *)entityMappingEvents;
{
    self.mappingResult = mappingResult;
    self.managedObjectContext = managedObjectContext;
    self.entityMappingEvents = entityMappingEvents;
    return self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
    return [self.mappingResult methodSignatureForSelector:selector];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    if (! self.refetched) {
        self.mappingResult = [self refetchedMappingResult];
        self.refetched = YES;
    }
    [invocation invokeWithTarget:self.mappingResult];
}

- (NSString *)description
{
    return [self.mappingResult description];
}

- (RKMappingResult *)refetchedMappingResult
{
    NSAssert(!self.refetched, @"Mapping result should only be refetched once");
    if (! [self.mappingResult count]) return self.mappingResult;
    
    NSMutableDictionary *newDictionary = [self.mappingResult.dictionary mutableCopy];
    [self.managedObjectContext performBlockAndWait:^{
        NSSet *rootKeys = [NSSet setWithArray:[self.entityMappingEvents valueForKey:@"rootKey"]];
        for (id rootKey in rootKeys) {
            NSArray *eventsForRootKey = [self.entityMappingEvents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"rootKey = %@", rootKey]];
            NSSet *keyPaths = [NSSet setWithArray:[eventsForRootKey valueForKey:@"keyPath"]];
            // If keyPaths contains null, then the root object is a managed object and we only need to refetch it
            NSSet *nonNestedKeyPaths = ([keyPaths containsObject:[NSNull null]]) ? [NSSet setWithObject:[NSNull null]] : RKSetByRemovingSubkeypathsFromSet(keyPaths);
            
            NSDictionary *mappingResultsAtRootKey = [newDictionary objectForKey:rootKey];
            for (NSString *keyPath in nonNestedKeyPaths) {
                id value = nil;
                if ([keyPath isEqual:[NSNull null]]) {
                    value = RKRefetchedValueInManagedObjectContext(mappingResultsAtRootKey, self.managedObjectContext);
                    if (value) [newDictionary setObject:value forKey:rootKey];
                } else {
                    NSMutableArray *keyPathComponents = [[keyPath componentsSeparatedByString:@"."] mutableCopy];
                    NSString *destinationKey = [keyPathComponents lastObject];
                    [keyPathComponents removeLastObject];
                    id sourceObject = [keyPathComponents count] ? [mappingResultsAtRootKey valueForKeyPath:[keyPathComponents componentsJoinedByString:@"."]] : mappingResultsAtRootKey;
                    if (RKObjectIsCollection(sourceObject)) {
                        // This is a to-many relationship, we want to refetch each item at the keyPath
                        for (id nestedObject in sourceObject) {
                            // Refetch this object. Set it on the destination.
                            NSManagedObject *managedObject = [nestedObject valueForKey:destinationKey];
                            [nestedObject setValue:RKRefetchedValueInManagedObjectContext(managedObject, self.managedObjectContext) forKey:destinationKey];
                        }
                    } else {
                        // This is a singular relationship. We want to refetch the object and set it directly.
                        id valueToRefetch = [sourceObject valueForKey:destinationKey];
                        [sourceObject setValue:RKRefetchedValueInManagedObjectContext(valueToRefetch, self.managedObjectContext) forKey:destinationKey];
                    }
                }
            }
        }
    }];
    
    return [[RKMappingResult alloc] initWithDictionary:newDictionary];
}

@end

static NSString *RKKeyPathByDeletingLastComponent(NSString *keyPath)
{
    NSArray *keyPathComponents = [keyPath componentsSeparatedByString:@"."];
    return ([keyPathComponents count] > 1) ? [[keyPathComponents subarrayWithRange:NSMakeRange(0, [keyPathComponents count] - 1)] componentsJoinedByString:@"."] : nil;
}

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

static NSSet *RKFlattenCollectionToSet(id collection)
{
    NSMutableSet *mutableSet = [NSMutableSet set];
    if ([collection conformsToProtocol:@protocol(NSFastEnumeration)]) {
        for (id nestedObject in collection) {
            if ([nestedObject conformsToProtocol:@protocol(NSFastEnumeration)]) {
                if ([nestedObject isKindOfClass:[NSArray class]]) {
                    [mutableSet unionSet:RKFlattenCollectionToSet([NSSet setWithArray:nestedObject])];
                } else if ([nestedObject isKindOfClass:[NSSet class]]) {
                    [mutableSet unionSet:RKFlattenCollectionToSet(nestedObject)];
                } else if ([nestedObject isKindOfClass:[NSOrderedSet class]]) {
                    [mutableSet unionSet:RKFlattenCollectionToSet([(NSOrderedSet *)nestedObject set])];
                }
            } else {
                [mutableSet addObject:nestedObject];
            }
        }
    } else if (collection) {
        [mutableSet addObject:collection];
    }
    
    return mutableSet;
}

static NSURL *RKRelativeURLFromURLAndResponseDescriptors(NSURL *URL, NSArray *responseDescriptors)
{
    NSCParameterAssert(URL);
    NSCParameterAssert(responseDescriptors);
    NSArray *baseURLs = [responseDescriptors valueForKeyPath:@"@distinctUnionOfObjects.baseURL"];
    if ([baseURLs count] == 1) {
        NSURL *baseURL = [baseURLs objectAtIndex:0];
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
@property (nonatomic, strong) NSArray *entityMappingEvents;

@property (nonatomic, strong) NSCachedURLResponse *cachedResponse;
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
        self.cachedResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:requestOperation.request];
    }
    return self;
}

/**
 NOTE: This dealloc implementation attempts to avoid crashes coming from Core Data due to the ordering of deallocations under ARC. If the MOC is deallocated before its managed objects, it can trigger a crash. We dispose of the mapping result and reset the private context to avoid this situation. The crash manifests itself in `cxx_destruct`
 [sbw - 2/25/2013]
 */
- (void)dealloc
{
    _mappingResult = nil;
    _responseMapperOperation = nil;
    _privateContext = nil;
}

- (void)setTargetObject:(id)targetObject
{
    [super setTargetObject:targetObject];

    if ([targetObject isKindOfClass:[NSManagedObject class]]) {
        if ([[targetObject objectID] isTemporaryID]) {
            [[targetObject managedObjectContext] performBlockAndWait:^{
                NSError *error = nil;
                BOOL success = [[targetObject managedObjectContext] obtainPermanentIDsForObjects:@[ targetObject ] error:&error];
                if (! success) RKLogWarning(@"Failed to obtain permanent objectID for targetObject: %@ (%ld)", [error localizedDescription], (long) error.code);
            }];            
        }
        self.targetObjectID = [targetObject objectID];
    } else {
        self.targetObjectID = nil;
    }
}

- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    _managedObjectContext = managedObjectContext;

    if (managedObjectContext) {
        // Create a private context
        NSManagedObjectContext *privateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [privateContext setParentContext:managedObjectContext];
        [privateContext setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];

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

// RKResponseHasBeenMappedCacheUserInfoKey is stored by RKObjectRequestOperation
- (BOOL)canSkipMapping
{
    // Is the request cacheable
    if (!self.cachedResponse) return NO;
    NSURLRequest *request = self.HTTPRequestOperation.request;
    if (! [[request HTTPMethod] isEqualToString:@"GET"] && ! [[request HTTPMethod] isEqualToString:@"HEAD"]) return NO;
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)self.HTTPRequestOperation.response;
    if (! [RKCacheableStatusCodes() containsIndex:response.statusCode]) return NO;

    // Check for a change in the Etag
    NSString *cachedEtag = [[(NSHTTPURLResponse *)[self.cachedResponse response] allHeaderFields] objectForKey:@"Etag"];
    NSString *responseEtag = [[response allHeaderFields] objectForKey:@"Etag"];
    if (! [cachedEtag isEqualToString:responseEtag]) return NO;

    // Response data has changed
    NSData *responseData = self.HTTPRequestOperation.responseData;
    if (! [responseData isEqualToData:[self.cachedResponse data]]) return NO;

    // Check that we have mapped this response previously
    NSCachedURLResponse *cachedResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:request];
    return [[cachedResponse.userInfo objectForKey:RKResponseHasBeenMappedCacheUserInfoKey] boolValue];
}

- (RKMappingResult *)performMappingOnResponse:(NSError **)error
{
    if ([self canSkipMapping]) {
        RKLogDebug(@"Managed object mapping requested for cached response which was previously mapped: skipping...");
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

    self.responseMapperOperation = [[RKManagedObjectResponseMapperOperation alloc] initWithRequest:self.HTTPRequestOperation.request
                                                                                          response:self.HTTPRequestOperation.response
                                                                                              data:self.HTTPRequestOperation.responseData
                                                                               responseDescriptors:self.responseDescriptors];
    self.responseMapperOperation.mapperDelegate = self;
    self.responseMapperOperation.mappingMetadata = self.mappingMetadata;
    self.responseMapperOperation.targetObject = self.targetObject;
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
            // Workaround for iOS 5 -- The log statement crashes if the entity is not assigned before logging
            [fetchRequest setEntity:[[[[self.privateContext persistentStoreCoordinator] managedObjectModel] entitiesByName] objectForKey:[fetchRequest entityName]]];
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
            RKLogTrace(@"Fetch request block %@ returned nil fetch request for URL: '%@'", fetchRequestBlock, URL);
        }
    }

    return localObjects;
}

- (BOOL)deleteLocalObjectsMissingFromMappingResult:(NSError **)error
{
    if (! self.deletesOrphanedObjects) {
        RKLogDebug(@"Skipping deletion of orphaned objects: disabled as deletesOrphanedObjects=NO");
        return YES;
    }

    if (! [[self.HTTPRequestOperation.request.HTTPMethod uppercaseString] isEqualToString:@"GET"]) {
        RKLogDebug(@"Skipping deletion of orphaned objects: only performed for GET requests.");
        return YES;
    }
    
    if ([self canSkipMapping]) {
        RKLogDebug(@"Skipping deletion of orphaned objects: 304 (Not Modified) status code encountered");
        return YES;
    }

    // Build an aggregate collection of all the managed objects in the mapping result
    NSMutableSet *managedObjectsInMappingResult = [NSMutableSet set];
    NSDictionary *mappingResultDictionary = self.mappingResult.dictionary;
    
    for (RKEntityMappingEvent *event in self.entityMappingEvents) {
        id objectsAtRoot = [mappingResultDictionary objectForKey:event.rootKey];
        id managedObjects = event.keyPath ? [objectsAtRoot valueForKeyPath:event.keyPath] : objectsAtRoot;
        NSSet *flattenedSet = RKFlattenCollectionToSet(managedObjects);
        [managedObjectsInMappingResult unionSet:flattenedSet];
    }

    NSSet *localObjects = [self localObjectsFromFetchRequestsMatchingRequestURL:error];
    if (! localObjects) return NO;
    RKLogDebug(@"Checking mappings result of %ld objects for %ld potentially orphaned local objects...", (long) [managedObjectsInMappingResult count], (long) [localObjects count]);
    for (id object in localObjects) {
        if (NO == [managedObjectsInMappingResult containsObject:object]) {
            RKLogDebug(@"Deleting orphaned object %@: not found in result set and expected at this URL", object);
            [self.privateContext performBlockAndWait:^{
                [self.privateContext deleteObject:object];
            }];
        }
    }

    return YES;
}

/**
 NOTE: This is more or less a direct port of the functionality provided by `[NSManagedObjectContext saveToPersistentStore:]` in the `RKAdditions` category. We have duplicated the logic here to add in support for checking if the operation has been cancelled since we began cascading up the MOC chain. Because each `performBlockAndWait:` invocation essentially jumps threads and is subject to the availability of the context, it is very possible for the operation to be cancelled during this part of the operation's lifecycle.
 */
- (BOOL)saveContextToPersistentStore:(NSManagedObjectContext *)contextToSave error:(NSError **)error
{
    __block NSError *localError = nil;
    while (contextToSave) {
        __block BOOL success;
        [contextToSave performBlockAndWait:^{
            if (! [self isCancelled]) {
                success = [contextToSave save:&localError];
                if (! success && localError == nil) RKLogWarning(@"Saving of managed object context failed, but a `nil` value for the `error` argument was returned. This typically indicates an invalid implementation of a key-value validation method exists within your model. This violation of the API contract may result in the save operation being mis-interpretted by callers that rely on the availability of the error.");
            } else {
                // We have been cancelled while the save is in progress -- bail
                success = NO;
            }
        }];

        if (! success) {
            if (error) *error = localError;
            return NO;
        }

        if (! contextToSave.parentContext && contextToSave.persistentStoreCoordinator == nil) {
            RKLogWarning(@"Reached the end of the chain of nested managed object contexts without encountering a persistent store coordinator. Objects are not fully persisted.");
            return NO;
        }
        contextToSave = contextToSave.parentContext;
    }

    return YES;
}

- (BOOL)saveContext:(NSManagedObjectContext *)context error:(NSError **)error
{
    __block BOOL success = YES;
    __block NSError *localError = nil;
    if (self.savesToPersistentStore) {
        success = [self saveContextToPersistentStore:context error:&localError];
    } else {
        [context performBlockAndWait:^{
            success = ([self isCancelled]) ? NO : [context save:&localError];
        }];
    }
    if (success) {
        if ([self.targetObject isKindOfClass:[NSManagedObject class]]) {
            [self.managedObjectContext performBlock:^{
                RKLogDebug(@"Refreshing mapped target object %@ in context %@", self.targetObject, self.managedObjectContext);
                if (! [self isCancelled]) [self.managedObjectContext refreshObject:self.targetObject mergeChanges:YES];
            }];
        }
    } else {
        if (error) *error = localError;
        RKLogError(@"Failed saving managed object context %@ %@", (self.savesToPersistentStore ? @"to the persistent store" : @""),  context);
        RKLogCoreDataError(localError);
    }

    return success;
}

- (BOOL)saveContext:(NSError **)error
{
    if ([self.privateContext hasChanges]) {
        return [self saveContext:self.privateContext error:error];
    } else if ([self.targetObject isKindOfClass:[NSManagedObject class]] && [(NSManagedObject *)self.targetObject isNew]) {
        // Object was like POST'd in an unsaved state and we wish to persist
        return [self saveContext:[self.targetObject managedObjectContext] error:error];
    }

    return YES;
}

- (BOOL)obtainPermanentObjectIDsForInsertedObjects:(NSError **)error
{
    __block BOOL _blockSuccess = YES;
    __block NSError *localError = nil;
    [self.privateContext performBlockAndWait:^{
        NSArray *insertedObjects = [[self.privateContext insertedObjects] allObjects];
        RKLogDebug(@"Obtaining permanent ID's for %ld managed objects", (unsigned long) [insertedObjects count]);
        _blockSuccess = [self.privateContext obtainPermanentIDsForObjects:insertedObjects error:nil];
    }];
    if (!_blockSuccess && error) *error = localError;

    return _blockSuccess;;
}

- (void)willFinish
{
    if ([self isCancelled]) return;
    
    BOOL success;
    NSError *error = nil;

    // Handle any cleanup
    success = [self deleteTargetObjectIfAppropriate:&error];
    if (! success || [self isCancelled]) {
        self.error = error;
        return;
    }

    success = [self deleteLocalObjectsMissingFromMappingResult:&error];
    if (! success || [self isCancelled]) {
        self.error = error;
        return;
    }

    // Persist our mapped objects
    success = [self obtainPermanentObjectIDsForInsertedObjects:&error];
    if (! success || [self isCancelled]) {
        self.error = error;
        return;
    }
    success = [self saveContext:&error];
    if (! success || [self isCancelled]) {
        self.error = error;
        return;
    }        

    // Refetch all managed objects nested at key paths within the results dictionary before returning
    if (self.mappingResult) {
        self.mappingResult = (RKMappingResult *)[[RKRefetchingMappingResult alloc] initWithMappingResult:self.mappingResult managedObjectContext:self.managedObjectContext entityMappingEvents:self.entityMappingEvents];
    }
}

- (void)mapperDidFinishMapping:(RKMapperOperation *)mapper
{
    NSMutableArray *entityMappingEvents = [NSMutableArray array];
    [mapper.mappingInfo enumerateKeysAndObjectsUsingBlock:^(id rootKey, NSDictionary *keyPathsToPropertyMappings, BOOL *stop) {
        [keyPathsToPropertyMappings enumerateKeysAndObjectsUsingBlock:^(NSString *keyPath, RKPropertyMapping *propertyMapping, BOOL *stop) {
            if ([propertyMapping.objectMapping isKindOfClass:[RKEntityMapping class]]) {
                // If the parent object mapping is an `RKEntityMapping`, add a mapping event at its keyPath
                [entityMappingEvents addObject:[RKEntityMappingEvent eventWithRootKey:rootKey
                                                                              keyPath:RKKeyPathByDeletingLastComponent(keyPath)
                                                                        entityMapping:(RKEntityMapping *)propertyMapping.objectMapping]];
            }
            if ([propertyMapping isKindOfClass:[RKRelationshipMapping class]]) {
                if ([[(RKRelationshipMapping *)propertyMapping mapping] isKindOfClass:[RKEntityMapping class]]) {
                    [entityMappingEvents addObject:[RKEntityMappingEvent eventWithRootKey:rootKey keyPath:keyPath entityMapping:(RKEntityMapping *)[(RKRelationshipMapping *)propertyMapping mapping]]];
                }
            }
        }];
    }];    
    self.entityMappingEvents = entityMappingEvents;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    RKManagedObjectRequestOperation *operation = (RKManagedObjectRequestOperation *)[super copyWithZone:zone];
    operation.managedObjectContext = self.managedObjectContext;
    operation.managedObjectCache = self.managedObjectCache;
    operation.fetchRequestBlocks = self.fetchRequestBlocks;
    operation.deletesOrphanedObjects = self.deletesOrphanedObjects;
    operation.savesToPersistentStore = self.savesToPersistentStore;
    
    return operation;
}

@end
