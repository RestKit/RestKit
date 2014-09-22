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

#ifdef _COREDATADEFINES_H
#if __has_include("RKManagedObjectCaching.h")

#import "RKManagedObjectRequestOperation.h"
#import "RKLog.h"
#import "RKHTTPUtilities.h"
#import "RKResponseMapperOperation.h"
#import "RKObjectRequestOperationSubclass.h"
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

+ (NSArray *)entityMappingEventsForMappingInfo:(NSDictionary *)mappingInfo;
+ (instancetype)eventWithRootKey:(id)rootKey keyPath:(NSString *)keyPath entityMapping:(RKEntityMapping *)entityMapping;
@end

@implementation RKEntityMappingEvent

+ (NSArray *)entityMappingEventsForMappingInfo:(NSDictionary *)mappingInfo
{
    NSMutableArray *entityMappingEvents = [NSMutableArray array];
    for (id rootKey in mappingInfo) {
        NSArray *mappingInfoArray = [mappingInfo objectForKey:rootKey];
        for (RKMappingInfo *mappingInfo in mappingInfoArray) {                        
            [entityMappingEvents addObjectsFromArray:[self entityMappingEventsWithMappingInfo:mappingInfo rootKey:rootKey keyPath:nil]];
        }
    }    
    return entityMappingEvents;
}

+ (NSArray *)entityMappingEventsWithMappingInfo:(RKMappingInfo *)mappingInfo rootKey:(id)rootKey keyPath:(NSString *)keyPath
{
    NSMutableArray *entityMappingEvents = [NSMutableArray array];
    if ([mappingInfo.objectMapping isKindOfClass:[RKEntityMapping class]]) {
        [entityMappingEvents addObject:[RKEntityMappingEvent eventWithRootKey:rootKey
                                                                      keyPath:keyPath
                                                                entityMapping:(RKEntityMapping *)mappingInfo.objectMapping]];
    }
    
    for (NSString *destinationKeyPath in mappingInfo.relationshipMappingInfo) {
        NSString *nestedKeyPath = keyPath ? [@[ keyPath, destinationKeyPath] componentsJoinedByString:@"."] : destinationKeyPath;
        NSArray *arrayOfMappingInfoForRelationship = [mappingInfo.relationshipMappingInfo objectForKey:destinationKeyPath];
        for (RKMappingInfo *mappingInfo in arrayOfMappingInfoForRelationship) {
            [entityMappingEvents addObjectsFromArray:[self entityMappingEventsWithMappingInfo:mappingInfo rootKey:rootKey keyPath:nestedKeyPath]];
        }
    }
    return entityMappingEvents;
}

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
    if ([managedObjectID isTemporaryID]) {
        RKLogWarning(@"Unable to refetch managed object %@: the object has a temporary managed object ID.", managedObject);
        return managedObject;
    }
    NSError *error = nil;
    NSManagedObject *refetchedObject = [managedObjectContext existingObjectWithID:managedObjectID error:&error];
    if (! refetchedObject) {
        RKLogWarning(@"Failed to refetch managed object with ID %@: %@", managedObjectID, error);
    }
    return refetchedObject;
}

static id RKRefetchedValueInManagedObjectContext(id value, NSManagedObjectContext *managedObjectContext)
{
    if (! value) {
        return value;
    } else if ([value isKindOfClass:[NSArray class]]) {
        NSMutableArray *newValue = [[NSMutableArray alloc] initWithCapacity:[value count]];
        for (__strong id object in value) {
            if ([object isKindOfClass:[NSManagedObject class]]) object = RKRefetchManagedObjectInContext(object, managedObjectContext);
            if (object) [newValue addObject:object];
        }
        return newValue;
    } else if ([value isKindOfClass:[NSSet class]]) {
        NSMutableSet *newValue = [[NSMutableSet alloc] initWithCapacity:[value count]];
        for (__strong id object in value) {
            if ([object isKindOfClass:[NSManagedObject class]]) object = RKRefetchManagedObjectInContext(object, managedObjectContext);
            if (object) [newValue addObject:object];
        }
        return newValue;
    } else if ([value isKindOfClass:[NSOrderedSet class]]) {
        NSMutableOrderedSet *newValue = [NSMutableOrderedSet orderedSet];
        [(NSOrderedSet *)value enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL *stop) {
            if ([object isKindOfClass:[NSManagedObject class]]) object = RKRefetchManagedObjectInContext(object, managedObjectContext);
            if (object) [newValue setObject:object atIndex:index];
        }];
        return newValue;
    } else if ([value isKindOfClass:[NSManagedObject class]]) {
        return RKRefetchManagedObjectInContext(value, managedObjectContext);
    }
    
    return value;
}

/**
 This is an NSProxy object that stands in for the mapping result and provides support for refetching the results on demand. This enables us to defer the refetching until someone accesses the results directly. For managed object request operations that do not use the mapping result (such as those used in conjunction with a NSFetchedResultsController), the refetching will be skipped entirely.
 */
@interface RKRefetchingMappingResult : NSProxy

- (id)initWithMappingResult:(RKMappingResult *)mappingResult
       managedObjectContext:(NSManagedObjectContext *)managedObjectContext
                mappingInfo:(NSDictionary *)mappingInfo;
@end

@interface RKRefetchingMappingResult ()
@property (nonatomic, strong) RKMappingResult *mappingResult;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSDictionary *mappingInfo;
@property (nonatomic, assign) BOOL refetched;
@end

@implementation RKRefetchingMappingResult

+ (NSString *)description
{
    return [[super description] stringByAppendingString:@"_RKRefetchingMappingResult"];
}

/**
 Add explicit ordering of deallocations to fight `cxx_destruct` crashes
 */
- (void)dealloc
{
    _mappingResult = nil;
    _mappingInfo = nil;
    _managedObjectContext = nil;
}

- (id)initWithMappingResult:(RKMappingResult *)mappingResult
       managedObjectContext:(NSManagedObjectContext *)managedObjectContext
                mappingInfo:(NSDictionary *)mappingInfo;
{
    self.mappingResult = mappingResult;
    self.managedObjectContext = managedObjectContext;
    self.mappingInfo = mappingInfo;
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

- (NSUInteger)count
{
    return [self.mappingResult count];
}

- (RKMappingResult *)refetchedMappingResult
{
    NSAssert(!self.refetched, @"Mapping result should only be refetched once");
    if (! [self.mappingResult count]) return self.mappingResult;
    
    NSMutableDictionary *newDictionary = [self.mappingResult.dictionary mutableCopy];
    [self.managedObjectContext performBlockAndWait:^{
        NSArray *entityMappingEvents = [RKEntityMappingEvent entityMappingEventsForMappingInfo:self.mappingInfo];
        NSSet *rootKeys = [NSSet setWithArray:[entityMappingEvents valueForKey:@"rootKey"]];
        for (id rootKey in rootKeys) {
            NSArray *eventsForRootKey = [entityMappingEvents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"rootKey = %@", rootKey]];
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
                            // NOTE: If this collection was mapped with a dynamic mapping then each instance may not respond to the key
                            if ([nestedObject respondsToSelector:NSSelectorFromString(destinationKey)]) {
                                NSManagedObject *managedObject = [nestedObject valueForKey:destinationKey];
                                [nestedObject setValue:RKRefetchedValueInManagedObjectContext(managedObject, self.managedObjectContext) forKey:destinationKey];
                            }
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

static NSSet *RKGatherManagedObjectsFromObjectWithRelationshipMapping(id object, RKRelationshipMapping *relationshipMapping)
{
    NSMutableSet *managedObjects = [NSMutableSet set];
    NSSet *relationshipValue = RKFlattenCollectionToSet([object valueForKeyPath:relationshipMapping.destinationKeyPath]);
    for (id relatedObject in relationshipValue) {
        if ([relatedObject isKindOfClass:[NSManagedObject class]]) [managedObjects addObject:relatedObject];
        
        if ([relationshipMapping.mapping isKindOfClass:[RKObjectMapping class]]) {
            for (RKRelationshipMapping *childRelationshipMapping in [(RKObjectMapping *)relationshipMapping.mapping relationshipMappings]) {
                [managedObjects unionSet:RKGatherManagedObjectsFromObjectWithRelationshipMapping(relatedObject, childRelationshipMapping)];
            }
        } else if ([relationshipMapping.mapping isKindOfClass:[RKDynamicMapping class]]) {
            for (RKObjectMapping *objectMapping in [(RKDynamicMapping *)relationshipMapping.mapping objectMappings]) {
                @try {
                    for (RKRelationshipMapping *childRelationshipMapping in objectMapping.relationshipMappings) {
                        [managedObjects unionSet:RKGatherManagedObjectsFromObjectWithRelationshipMapping(relatedObject, childRelationshipMapping)];
                    }
                }
                @catch (NSException *exception) {
                    continue;
                }
            }
        }
    }
    return managedObjects;
}

static NSSet *RKManagedObjectsFromObjectWithMappingInfo(id object, RKMappingInfo *mappingInfo)
{
    NSMutableSet *managedObjects = [NSMutableSet set];
    
    if ([mappingInfo.objectMapping isKindOfClass:[RKEntityMapping class]]) {
        [managedObjects unionSet:RKFlattenCollectionToSet(object)];
    }
    
    if ([[mappingInfo propertyMappings] count] == 0) {
        // This object was matched, but no changes were made. Gather all related objects
        for (RKRelationshipMapping *relationshipMapping in [mappingInfo.objectMapping relationshipMappings]) {
            [managedObjects unionSet:RKGatherManagedObjectsFromObjectWithRelationshipMapping(object, relationshipMapping)];
        }
    } else {    
        for (NSString *destinationKeyPath in mappingInfo.relationshipMappingInfo) {
            id relationshipValue = [object valueForKeyPath:destinationKeyPath];
            NSArray *mappingInfos = [mappingInfo.relationshipMappingInfo objectForKey:destinationKeyPath];
            for (RKMappingInfo *relationshipMappingInfo in mappingInfos) {
                NSUInteger index = [mappingInfos indexOfObject:relationshipMappingInfo];
                id mappedObjectAtIndex = ([relationshipValue respondsToSelector:@selector(objectAtIndex:)]) ? [NSSet setWithObject:[relationshipValue objectAtIndex:index]] : relationshipValue;
                [managedObjects unionSet:RKFlattenCollectionToSet(RKManagedObjectsFromObjectWithMappingInfo(mappedObjectAtIndex, relationshipMappingInfo))];
            }
        }
    }
    
    return ([managedObjects count]) ? managedObjects : nil;
}

static NSSet *RKManagedObjectsFromMappingResultWithMappingInfo(RKMappingResult *mappingResult, NSDictionary *mappingInfo)
{
    NSMutableSet *managedObjectsInMappingResult = nil;
    NSDictionary *mappingResultDictionary = [mappingResult dictionary];

    for (id rootKey in mappingInfo) {
        NSArray *mappingInfoArray = [mappingInfo objectForKey:rootKey];
        id objectsAtRoot = [mappingResultDictionary objectForKey:rootKey];
        for (RKMappingInfo *mappingInfo in mappingInfoArray) {
            NSUInteger index = [mappingInfoArray indexOfObject:mappingInfo];
            id mappedObjectAtIndex = ([objectsAtRoot respondsToSelector:@selector(objectAtIndex:)]) ? [NSSet setWithObject:[objectsAtRoot objectAtIndex:index]] : objectsAtRoot;
            
            NSSet *managedObjects = RKManagedObjectsFromObjectWithMappingInfo(mappedObjectAtIndex, mappingInfo);
            if (managedObjects) {
                if (! managedObjectsInMappingResult) managedObjectsInMappingResult = [NSMutableSet set];
                [managedObjectsInMappingResult unionSet:managedObjects];
            }
        }
    };

    return managedObjectsInMappingResult;
}

// Defined in RKObjectManager.h
BOOL RKDoesArrayOfResponseDescriptorsContainOnlyEntityMappings(NSArray *responseDescriptors);

@interface RKObjectRequestOperation ()
@property (nonatomic, strong, readwrite) NSError *error;
@property (nonatomic, strong, readwrite) RKMappingResult *mappingResult;
@end

@interface RKManagedObjectRequestOperation ()
// Core Data specific
@property (nonatomic, strong) NSManagedObjectContext *privateContext;
@property (nonatomic, copy) NSManagedObjectID *targetObjectID;
@property (nonatomic, strong) RKManagedObjectResponseMapperOperation *responseMapperOperation;
@property (nonatomic, copy) id (^willMapDeserializedResponseBlock)(id deserializedResponseBody);
@property (nonatomic, strong) NSDictionary *mappingInfo;
@property (nonatomic, strong) NSCachedURLResponse *cachedResponse;
@property (nonatomic, readonly) BOOL canSkipMapping;
@property (nonatomic, assign) BOOL hasMemoizedCanSkipMapping;
@property (nonatomic, copy) void (^willSaveMappingContextBlock)(NSManagedObjectContext *mappingContext);
@end

@implementation RKManagedObjectRequestOperation

@dynamic willMapDeserializedResponseBlock;
@synthesize canSkipMapping = _canSkipMapping;

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
        [managedObjectContext performBlockAndWait:^{
            if ([managedObjectContext hasChanges]) {
                if ([managedObjectContext.insertedObjects count] && [self.managedObjectCache respondsToSelector:@selector(didCreateObject:)]) {
                    for (NSManagedObject *managedObject in managedObjectContext.insertedObjects) {
                        [self.managedObjectCache didCreateObject:managedObject];
                    }
                }
                
                if ([managedObjectContext.updatedObjects count] && [self.managedObjectCache respondsToSelector:@selector(didFetchObject:)]) {
                    for (NSManagedObject *managedObject in managedObjectContext.updatedObjects) {
                        [self.managedObjectCache didFetchObject:managedObject];
                    }
                }
                
                if ([managedObjectContext.deletedObjects count] && [self.managedObjectCache respondsToSelector:@selector(didDeleteObject:)]) {
                    for (NSManagedObject *managedObject in managedObjectContext.deletedObjects) {
                        [self.managedObjectCache didDeleteObject:managedObject];
                    }
                }
            }
        }];
        
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
    BOOL (^shouldSkipMapping)(void) = ^{
        // Is the request cacheable
        if (!self.cachedResponse) return NO;
        if (!self.managedObjectCache) return NO;
        NSURLRequest *request = self.HTTPRequestOperation.request;
        if (! [[request HTTPMethod] isEqualToString:@"GET"] && ! [[request HTTPMethod] isEqualToString:@"HEAD"]) return NO;
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)self.HTTPRequestOperation.response;
        if (! [RKCacheableStatusCodes() containsIndex:response.statusCode]) return NO;
        
        // Check if all the response descriptors are backed by Core Data
        NSMutableArray *matchingResponseDescriptors = [NSMutableArray array];
        for (RKResponseDescriptor *responseDescriptor in self.responseDescriptors) {
            if ([responseDescriptor matchesResponse:response]) [matchingResponseDescriptors addObject:responseDescriptor];
        }
        if (! RKDoesArrayOfResponseDescriptorsContainOnlyEntityMappings(matchingResponseDescriptors)) return NO;

        // Check for a change in the Etag
        NSString *cachedEtag = [[(NSHTTPURLResponse *)[self.cachedResponse response] allHeaderFields] objectForKey:@"ETag"];
        NSString *responseEtag = [[response allHeaderFields] objectForKey:@"ETag"];
        if (!(cachedEtag && responseEtag && [cachedEtag isEqualToString:responseEtag])) return NO;
        
        // Response data has changed
        NSData *responseData = self.HTTPRequestOperation.responseData;
        if (! [responseData isEqualToData:[self.cachedResponse data]]) return NO;
        
        // Check that we have mapped this response previously
        NSCachedURLResponse *cachedResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:request];
        return [[cachedResponse.userInfo objectForKey:RKResponseHasBeenMappedCacheUserInfoKey] boolValue];
    };
    
    if (! self.hasMemoizedCanSkipMapping) {
        _canSkipMapping = shouldSkipMapping();
        self.hasMemoizedCanSkipMapping = YES;
    }
    return _canSkipMapping;
}

- (void)performMappingOnResponseWithCompletionBlock:(void(^)(RKMappingResult *mappingResult, NSError *error))completionBlock
{
    NSArray *fetchRequests = [self fetchRequestsMatchingResponseURL];
    if ([fetchRequests count] && [self canSkipMapping]) {
        RKLogDebug(@"Managed object mapping requested for cached response which was previously mapped: skipping...");
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
        RKMappingResult *mappingResult = [[RKMappingResult alloc] initWithDictionary:@{ [NSNull null]: managedObjects }];
        completionBlock(mappingResult, nil);
        return;
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
    __weak __typeof(self)weakSelf = self;
    [self.responseMapperOperation setDidFinishMappingBlock:^(RKMappingResult *mappingResult, NSError *responseMappingError) {
        if ([weakSelf isCancelled]) return completionBlock(mappingResult, responseMappingError);
        
        BOOL success;
        NSError *error = nil;
        
        // Handle any cleanup
        if (weakSelf.targetObjectID
            && NSLocationInRange(weakSelf.HTTPRequestOperation.response.statusCode, RKStatusCodeRangeForClass(RKStatusCodeClassSuccessful))
            && [[[weakSelf.HTTPRequestOperation.request HTTPMethod] uppercaseString] isEqualToString:@"DELETE"]) {
            success = [weakSelf deleteTargetObject:&error];
            if (! success || [weakSelf isCancelled]) {
                return completionBlock(nil, error);
            }
        }

        if (!responseMappingError) {
            success = [weakSelf deleteLocalObjectsMissingFromMappingResult:mappingResult error:&error];
            if (! success || [weakSelf isCancelled]) {
                return completionBlock(nil, error);
            }
        
            // Persist our mapped objects
            success = [weakSelf obtainPermanentObjectIDsForInsertedObjects:&error];
            if (! success || [weakSelf isCancelled]) {
                return completionBlock(nil, error);
            }
            
            success = [weakSelf saveContext:&error];
            if (! success || [weakSelf isCancelled]) {
                return completionBlock(nil, error);
            }
        }
        
        // Refetch all managed objects nested at key paths within the results dictionary before returning
        if (mappingResult) {
            RKRefetchingMappingResult *refetchingMappingResult = [[RKRefetchingMappingResult alloc] initWithMappingResult:mappingResult
                                                                                                     managedObjectContext:weakSelf.managedObjectContext
                                                                                                              mappingInfo:weakSelf.mappingInfo];
            return completionBlock((RKMappingResult *)refetchingMappingResult, nil);
        }
        completionBlock(nil, responseMappingError);
    }];
    [[RKObjectRequestOperation responseMappingQueue] addOperation:self.responseMapperOperation];
}

- (BOOL)deleteTargetObject:(NSError **)error
{
    __block BOOL _blockSuccess = YES;

    if (self.targetObjectID) {
        // 2xx/404/410 DELETE request, proceed with deletion from the MOC
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

- (NSSet *)localObjectsFromFetchRequests:(NSArray *)fetchRequests matchingRequestURL:(NSError **)error
{
    NSMutableSet *localObjects = [NSMutableSet set];
    __block NSError *_blockError;
    __block NSArray *_blockObjects;
    
    for (NSFetchRequest *fetchRequest in fetchRequests) {
        [self.privateContext performBlockAndWait:^{
            _blockObjects = [self.privateContext executeFetchRequest:fetchRequest error:&_blockError];
        }];
        
        if (_blockObjects == nil) {
            if (error) *error = _blockError;
            return nil;
        }
        RKLogTrace(@"Fetched local objects matching URL with fetch request '%@': %@", fetchRequest, _blockObjects);
        [localObjects addObjectsFromArray:_blockObjects];
        
    }
    
    return localObjects;
}

- (NSArray *)fetchRequestsMatchingResponseURL
{
    // Pass the fetch request blocks a relative `NSURL` object if possible
    NSMutableArray *fetchRequests = [NSMutableArray array];
    NSURL *URL = RKRelativeURLFromURLAndResponseDescriptors(self.HTTPRequestOperation.response.URL, self.responseDescriptors);
    for (RKFetchRequestBlock fetchRequestBlock in [self.fetchRequestBlocks reverseObjectEnumerator]) {
        NSFetchRequest *fetchRequest = fetchRequestBlock(URL);
        if (fetchRequest) {
            // Workaround for iOS 5 -- The log statement crashes if the entity is not assigned before logging
            [fetchRequest setEntity:[[[[self.privateContext persistentStoreCoordinator] managedObjectModel] entitiesByName] objectForKey:[fetchRequest entityName]]];
            RKLogDebug(@"Found fetch request matching URL '%@': %@", URL, fetchRequest);
            [fetchRequests addObject:fetchRequest];
        }
    }
    return fetchRequests;
}

- (BOOL)deleteLocalObjectsMissingFromMappingResult:(RKMappingResult *)mappingResult error:(NSError **)error
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
    
    // Determine if there are any fetch request blocks to use for orphaned object cleanup
    NSArray *fetchRequests = [self fetchRequestsMatchingResponseURL];
    if (! [fetchRequests count]) return YES;
    
    // Proceed with cleanup
    NSSet *managedObjectsInMappingResult = RKManagedObjectsFromMappingResultWithMappingInfo(mappingResult, self.mappingInfo) ?: [NSSet set];
    NSSet *localObjects = [self localObjectsFromFetchRequests:fetchRequests matchingRequestURL:error];
    if (! localObjects) {
        RKLogError(@"Failed when attempting to fetch local candidate objects for orphan cleanup: %@", error ? *error : nil);
        return NO;
    }
    RKLogDebug(@"Checking mappings result of %ld objects for %ld potentially orphaned local objects...", (long) [managedObjectsInMappingResult count], (long) [localObjects count]);
    
    NSMutableSet *orphanedObjects = [localObjects mutableCopy];
    [orphanedObjects minusSet:managedObjectsInMappingResult];
    RKLogDebug(@"Deleting %lu orphaned objects found in local database, but missing from mapping result", (unsigned long) [orphanedObjects count]);
    
    if ([orphanedObjects count]) {
        [self.privateContext performBlockAndWait:^{
            for (NSManagedObject *orphanedObject in orphanedObjects) {
                [self.privateContext deleteObject:orphanedObject];
            }
        }];
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
        RKLogError(@"Failed saving managed object context %@ %@: %@", (self.savesToPersistentStore ? @"to the persistent store" : @""),  context, localError);
        RKLogCoreDataError(localError);
    }

    return success;
}

- (BOOL)saveContext:(NSError **)error
{
    if (self.willSaveMappingContextBlock) {
        [self.privateContext performBlockAndWait:^{
            self.willSaveMappingContextBlock(self.privateContext);
        }];
    }
    
    if ([self.privateContext hasChanges]) {
        return [self saveContext:self.privateContext error:error];
    } else if ([self.targetObject isKindOfClass:[NSManagedObject class]]) {
        NSManagedObjectContext *context = [(NSManagedObject *)self.targetObject managedObjectContext];
        __block BOOL isNew = NO;
        [context performBlockAndWait:^{
            isNew = [(NSManagedObject *)self.targetObject isNew];
        }];
        // Object was like POST'd in an unsaved state and we wish to persist
        if (isNew) [self saveContext:context error:error];
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

- (void)mapperDidFinishMapping:(RKMapperOperation *)mapper
{
    self.mappingInfo = mapper.mappingInfo;
}

- (void)willFinish
{
    NSMutableIndexSet *deleteableStatusCodes = [NSMutableIndexSet indexSet];
    [deleteableStatusCodes addIndex:404]; // Not Found
    [deleteableStatusCodes addIndex:410]; // Gone
    if (self.error && self.targetObjectID
        && [[[self.HTTPRequestOperation.request HTTPMethod] uppercaseString] isEqualToString:@"DELETE"]
        && [deleteableStatusCodes containsIndex:self.HTTPRequestOperation.response.statusCode]) {
        NSError *error = nil;
        if (! [self deleteTargetObject:&error]) {
            RKLogWarning(@"Secondary error encountered while attempting to delete target object in response to 404 (Not Found) or 410 (Gone) status code: %@", error);
            self.error = error;
        } else {
            if (! [self saveContext:&error]) {
                
            } else {
                // All good, clear any errors
                self.error = nil;
            }
        }
    }
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

#endif
#endif
