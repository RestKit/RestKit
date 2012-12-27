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

// Graph visitor
#import "RKResponseDescriptor.h"
#import "RKEntityMapping.h"
#import "RKDynamicMapping.h"
#import "RKRelationshipMapping.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent RKlcl_cRestKitCoreData

@interface RKNestedManagedObjectKeyPathMappingGraphVisitor : NSObject

@property (nonatomic, readonly) NSSet *keyPaths;
@property (nonatomic, readonly) NSDictionary* entityMappingDictionary;

- (id)initWithResponseDescriptors:(NSArray *)responseDescriptors;

@end

@interface RKNestedManagedObjectKeyPathMappingGraphVisitor ()
@property (nonatomic, strong) NSMutableSet *mutableKeyPaths;
@property (nonatomic, strong) NSMutableDictionary* mutableEntityMappingDictionary;
@end

@implementation RKNestedManagedObjectKeyPathMappingGraphVisitor

- (id)initWithResponseDescriptors:(NSArray *)responseDescriptors
{
    self = [self init];
    if (self) {
        self.mutableKeyPaths = [NSMutableSet set];
        self.mutableEntityMappingDictionary = [NSMutableDictionary dictionary];
        for (RKResponseDescriptor *responseDescriptor in responseDescriptors) {
            [self visitMapping:responseDescriptor.mapping atKeyPath:responseDescriptor.keyPath];
        }
    }
    return self;
}

- (NSSet *)keyPaths
{
    return self.mutableKeyPaths;
}

- (NSDictionary*) entityMappingDictionary
{
    return self.mutableEntityMappingDictionary;
}

- (void)visitMapping:(RKMapping *)mapping atKeyPath:(NSString *)keyPath
{
    id actualKeyPath = keyPath ?: [NSNull null];
    if ([self.keyPaths containsObject:actualKeyPath]) return;    
    if ([mapping isKindOfClass:[RKEntityMapping class]])
    {
        [self.mutableKeyPaths addObject:actualKeyPath];
        [self.mutableEntityMappingDictionary setObject:mapping forKey:NSStringFromClass([(RKEntityMapping*)mapping objectClass])];
    }
    if ([mapping isKindOfClass:[RKDynamicMapping class]]) {
        RKDynamicMapping *dynamicMapping = (RKDynamicMapping *)mapping;
        for (RKMapping *nestedMapping in dynamicMapping.objectMappings) {
            [self visitMapping:nestedMapping atKeyPath:keyPath];
        }
    } else if ([mapping isKindOfClass:[RKObjectMapping class]]) {
        RKObjectMapping *objectMapping = (RKObjectMapping *)mapping;
        for (RKRelationshipMapping *relationshipMapping in objectMapping.relationshipMappings) {
            NSString *nestedKeyPath = keyPath ? [@[ keyPath, relationshipMapping.destinationKeyPath ] componentsJoinedByString:@"."] : relationshipMapping.destinationKeyPath;
            [self visitMapping:relationshipMapping.mapping atKeyPath:nestedKeyPath];
        }
    }
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

// When we map the root object, it is returned under the key `[NSNull null]`
static id RKMappedValueForKeyPathInDictionary(NSString *keyPath, NSDictionary *dictionary)
{
    return ([keyPath isEqual:[NSNull null]]) ? [dictionary objectForKey:[NSNull null]] : [dictionary valueForKeyPath:keyPath];
}

static void RKSetMappedValueForKeyPathInDictionary(id value, NSString *keyPath, NSMutableDictionary *dictionary)
{
    NSCParameterAssert(value);
    NSCParameterAssert(keyPath);
    NSCParameterAssert(dictionary);
    [keyPath isEqual:[NSNull null]] ? [dictionary setObject:value forKey:keyPath] : [dictionary setValue:value forKeyPath:keyPath];
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

// Finds the key paths for all entity mappings in the graph whose parent objects are not other managed objects
static NSDictionary *RKDictionaryFromDictionaryWithManagedObjectsAtKeyPathsRefetchedInContext(NSDictionary *dictionaryOfManagedObjects, NSSet *keyPaths, NSManagedObjectContext *managedObjectContext)
{
    if (! [dictionaryOfManagedObjects count]) return dictionaryOfManagedObjects;    
    NSMutableDictionary *newDictionary = [dictionaryOfManagedObjects mutableCopy];
    [managedObjectContext performBlockAndWait:^{
        for (NSString *keyPath in keyPaths) {
            id value = RKMappedValueForKeyPathInDictionary(keyPath, dictionaryOfManagedObjects);
            if (! value) {
                continue;
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
            
            if (value) RKSetMappedValueForKeyPathInDictionary(value, keyPath, newDictionary);
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

- (BOOL)deleteLocalObjectsMissingFromMappingResult:(RKMappingResult *)result atKeyPaths:(NSSet *)keyPaths error:(NSError **)error
{
    if (! self.deletesOrphanedObjects) {
        RKLogDebug(@"Skipping deletion of orphaned objects: disabled as deletesOrphanedObjects=NO");
        return YES;
    }

    if (! [[self.HTTPRequestOperation.request.HTTPMethod uppercaseString] isEqualToString:@"GET"]) {
        RKLogDebug(@"Skipping deletion of orphaned objects: only performed for GET requests.");
        return YES;
    }
    
    if (self.HTTPRequestOperation.wasNotModified) {
        RKLogDebug(@"Skipping deletion of orphaned objects: 304 (Not Modified) status code encountered");
        return YES;
    }

    // Build an aggregate collection of all the managed objects in the mapping result
    NSMutableSet *managedObjectsInMappingResult = [NSMutableSet set];
    NSDictionary *mappingResultDictionary = result.dictionary;
    for (NSString *keyPath in keyPaths) {
        id managedObjects = RKMappedValueForKeyPathInDictionary(keyPath, mappingResultDictionary);
        if (! managedObjects) {
            continue;
        } else if ([managedObjects isKindOfClass:[NSManagedObject class]]) {
            [managedObjectsInMappingResult addObject:managedObjects];
        } else if ([managedObjects isKindOfClass:[NSSet class]]) {
            [managedObjectsInMappingResult unionSet:managedObjects];
        } else if ([managedObjects isKindOfClass:[NSArray class]]) {
            [managedObjectsInMappingResult addObjectsFromArray:managedObjects];
        } else if ([managedObjects isKindOfClass:[NSOrderedSet class]]) {
            [managedObjectsInMappingResult addObjectsFromArray:[managedObjects array]];
        } else {
            [NSException raise:NSInternalInconsistencyException format:@"Unexpected object type '%@' encountered at keyPath '%@': Expected an `NSManagedObject`, `NSArray`, or `NSSet`.", [managedObjects class], keyPath];
        }
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

//JIFF ADDITION
- (void) deleteInsertedOrUpdatedObjectsWithDeletedAttributeAsYes:(NSDictionary*) entityMappingDictionary
{
    NSMutableArray *insertedOrUpdatedObjects = [[self.privateContext.insertedObjects allObjects] mutableCopy];
    NSMutableArray * toBeDeletedObjects = [NSMutableArray array];
    [insertedOrUpdatedObjects addObjectsFromArray:[self.privateContext.updatedObjects allObjects]];
    if ([insertedOrUpdatedObjects count] > 0) {

        for (NSManagedObject* obj in insertedOrUpdatedObjects) {
            RKEntityMapping * mapping = [entityMappingDictionary valueForKey:NSStringFromClass([obj class])];
            NSString * deletedAttributeName = [mapping deletedAttributeName];
            if (mapping && deletedAttributeName && ([[obj valueForKeyPath:deletedAttributeName] isEqual:@YES])) {
                [toBeDeletedObjects addObject:obj];
            }
        }
        if ([toBeDeletedObjects count] > 0) {
            RKLogDebug(@"Deleting %d objects with deletedAttribute as YES", [toBeDeletedObjects count]);
            [self.privateContext performBlockAndWait:^{
                for (NSManagedObject* obj in toBeDeletedObjects) {
                    [self.privateContext deleteObject:obj];
                }
            }];
        }
    }
    return;
    
}
//END OF JIFF ADDITION


- (void)willFinish
{
    BOOL success;
    NSError *error = nil;

    // Construct a set of key paths to all of the managed objects in the mapping result
    RKNestedManagedObjectKeyPathMappingGraphVisitor *visitor = [[RKNestedManagedObjectKeyPathMappingGraphVisitor alloc] initWithResponseDescriptors:self.responseDescriptors];
    NSSet *managedObjectMappingResultKeyPaths = visitor.keyPaths;

    // Handle any cleanup
    success = [self deleteTargetObjectIfAppropriate:&error];
    if (! success) {
        self.error = error;
        return;
    }

    success = [self deleteLocalObjectsMissingFromMappingResult:self.mappingResult atKeyPaths:managedObjectMappingResultKeyPaths error:&error];
    if (! success) {
        self.error = error;
        return;
    }
    
    [self deleteInsertedOrUpdatedObjectsWithDeletedAttributeAsYes:visitor.entityMappingDictionary];

    // Persist our mapped objects
    success = [self obtainPermanentObjectIDsForInsertedObjects:&error];
    if (! success) {
        self.error = error;
        return;
    }
    success = [self saveContext:&error];
    if (! success) self.error = error;
    
    // Refetch all managed objects nested at key paths within the results dictionary before returning
    if (self.mappingResult) {
        NSSet *nonNestedKeyPaths = RKSetByRemovingSubkeypathsFromSet(managedObjectMappingResultKeyPaths);
        NSDictionary *resultsDictionaryFromOriginalContext = RKDictionaryFromDictionaryWithManagedObjectsAtKeyPathsRefetchedInContext([self.mappingResult dictionary], nonNestedKeyPaths, self.managedObjectContext);
        self.mappingResult = [[RKMappingResult alloc] initWithDictionary:resultsDictionaryFromOriginalContext];
    }
}

@end
