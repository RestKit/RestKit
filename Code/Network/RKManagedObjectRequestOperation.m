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

@interface RKMappingGraphVisitation : NSObject
@property (nonatomic, strong) id rootKey; // Will be [NSNull null] or a string value
@property (nonatomic, strong) NSString *keyPath;
@property (nonatomic, assign, getter = isCyclic) BOOL cyclic;
@property (nonatomic, strong) RKMapping *mapping;
@end

@implementation RKMappingGraphVisitation

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p rootKey=%@ keyPath=%@ isCylic=%@ mapping=%@>",
            [self class], self, self.rootKey, self.keyPath, self.isCyclic ? @"YES" : @"NO", self.mapping];
}

@end

/**
 This class implements Tarjan's algorithm to efficiently visit all nodes within the mapping graph and detect cycles in the graph.
 
 For more details on the algorithm, refer to the Wikipedia page: http://en.wikipedia.org/wiki/Tarjan's_strongly_connected_components_algorithm
 
 The following reference implementations were used when building out an Objective-C implementation:
 
 1. http://algowiki.net/wiki/index.php?title=Tarjan%27s_algorithm
 1. http://www.logarithmic.net/pfh-files/blog/01208083168/tarjan.py
 
 */
@interface RKNestedManagedObjectKeyPathMappingGraphVisitor : NSObject
@property (nonatomic, readonly, strong) NSMutableArray *visitations;
- (id)initWithResponseDescriptors:(NSArray *)responseDescriptors;
@end

@interface RKNestedManagedObjectKeyPathMappingGraphVisitor ()
@property (nonatomic, assign) NSUInteger indexCounter;
@property (nonatomic, strong) NSMutableArray *visitationStack;
@property (nonatomic, strong) NSMutableDictionary *index;
@property (nonatomic, strong) NSMutableDictionary *lowLinks;
@property (nonatomic, strong, readwrite) NSMutableArray *visitations;
@end

@implementation RKNestedManagedObjectKeyPathMappingGraphVisitor

- (id)initWithResponseDescriptors:(NSArray *)responseDescriptors
{
    self = [self init];
    if (self) {
        self.indexCounter = 0;
        self.visitationStack = [NSMutableArray array];
        self.index = [NSMutableDictionary dictionary];
        self.lowLinks = [NSMutableDictionary dictionary];
        self.visitations = [NSMutableArray array];
        
        for (RKResponseDescriptor *responseDescriptor in responseDescriptors) {
            self.indexCounter = 0;
            [self.visitationStack removeAllObjects];
            [self.index removeAllObjects];
            [self.lowLinks removeAllObjects];
            [self visitMapping:responseDescriptor.mapping atKeyPath:responseDescriptor.keyPath];
        }
    }
    
    return self;
}

- (RKMappingGraphVisitation *)visitationForMapping:(RKMapping *)mapping atKeyPath:(NSString *)keyPath
{
    RKMappingGraphVisitation *visitation = [RKMappingGraphVisitation new];
    visitation.mapping = mapping;
    if ([self.visitationStack count] == 0) {
        // If we are the first item in the stack, we are visiting the rootKey
        visitation.rootKey = keyPath ?: [NSNull null];
    } else {
        // Take the root key from the visitation stack
        visitation.rootKey = [[self.visitationStack objectAtIndex:0] rootKey];
        visitation.keyPath = keyPath;
    }    
    
    return visitation;
}

// Traverse the mappings graph using Tarjan's algorithm
- (void)visitMapping:(RKMapping *)mapping atKeyPath:(NSString *)keyPath
{
    // Track the visit to each node in the graph. Note that we do not pop the stack as we traverse back up
    NSValue *dictionaryKey = [NSValue valueWithNonretainedObject:mapping];
    [self.index setObject:@(self.indexCounter) forKey:dictionaryKey];
    [self.lowLinks setObject:@(self.indexCounter) forKey:dictionaryKey];
    self.indexCounter++;
    
    RKMappingGraphVisitation *visitation = [self visitationForMapping:mapping atKeyPath:keyPath];
    [self.visitationStack addObject:visitation];
    
    if ([mapping isKindOfClass:[RKObjectMapping class]]) {
        RKObjectMapping *objectMapping = (RKObjectMapping *)mapping;
        for (RKRelationshipMapping *relationshipMapping in objectMapping.relationshipMappings) {
            // Check if the successor relationship appears in the lowlinks
            NSValue *relationshipKey = [NSValue valueWithNonretainedObject:relationshipMapping.mapping];
            NSNumber *relationshipLowValue = [self.lowLinks objectForKey:relationshipKey];
            NSString *nestedKeyPath = ([self.visitationStack count] > 1 && keyPath) ? [@[ keyPath, relationshipMapping.destinationKeyPath ] componentsJoinedByString:@"."] : relationshipMapping.destinationKeyPath;
            if (relationshipLowValue == nil) {
                // The relationship has not yet been visited, recurse
                [self visitMapping:relationshipMapping.mapping atKeyPath:nestedKeyPath];
                
                // Set the lowlink value for parent mapping to the lower value for us or the child mapping we just recursed on
                NSNumber *lowLinkForMapping = [self.lowLinks objectForKey:dictionaryKey];
                NSNumber *lowLinkForSuccessor = [self.lowLinks objectForKey:relationshipKey];
                
                if ([lowLinkForMapping compare:lowLinkForSuccessor] == NSOrderedDescending) {
                    [self.lowLinks setObject:lowLinkForSuccessor forKey:dictionaryKey];
                }
            } else {
                // The child mapping is already in the stack, so it is part of a strongly connected component
                NSNumber *lowLinkForMapping = [self.lowLinks objectForKey:dictionaryKey];
                NSNumber *indexValueForSuccessor = [self.index objectForKey:relationshipKey];
                if ([lowLinkForMapping compare:indexValueForSuccessor] == NSOrderedDescending) {
                    [self.lowLinks setObject:indexValueForSuccessor forKey:dictionaryKey];
                }
                
                // Since this mapping already appears in lowLinks, we have a cycle at this point in the graph
                if ([relationshipMapping.mapping isKindOfClass:[RKEntityMapping class]]) {
                    RKMappingGraphVisitation *cyclicVisitation = [self visitationForMapping:relationshipMapping.mapping atKeyPath:nestedKeyPath];
                    cyclicVisitation.cyclic = YES;
                    [self.visitations addObject:cyclicVisitation];
                }
            }
        }
    } else if ([mapping isKindOfClass:[RKDynamicMapping class]]) {
        // Pop the dynamic mapping off of the stack so that our children are rooted at the same level
        [self.visitationStack removeLastObject];
        
        // Dynamic mappings appear at the same point in the graph, so we recurse with the same keyPath
        for (RKMapping *nestedMapping in [(RKDynamicMapping *)mapping objectMappings]) {
            [self visitMapping:nestedMapping atKeyPath:keyPath];
        }
    }
    
    // If the current mapping is a root node, then pop the stack to create an SCC
    NSNumber *lowLinkValueForMapping = [self.lowLinks objectForKey:dictionaryKey];
    NSNumber *indexValueForMapping = [self.index objectForKey:dictionaryKey];
    if ([lowLinkValueForMapping isEqualToNumber:indexValueForMapping]) {
        NSUInteger index = [self.visitationStack indexOfObject:visitation];
        if (index != NSNotFound) {
            NSRange removalRange = NSMakeRange(index, [self.visitationStack count] - index);
            [self.visitationStack removeObjectsInRange:removalRange];
        }
        
        if ([visitation.mapping isKindOfClass:[RKEntityMapping class]]) {
            [self.visitations addObject:visitation];
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

/**
 Traverses a set of cyclic key paths within the mapping result. Because these relationships are cyclic, we continue collecting managed objects and traversing until the values returned by the key path are a complete subset of all objects already in the set.
 */
static void RKAddObjectsInGraphWithCyclicKeyPathsToMutableSet(id graph, NSSet *cyclicKeyPaths, NSMutableSet *mutableSet)
{
    if ([graph respondsToSelector:@selector(count)] && [graph count] == 0) return;
    
    for (NSString *cyclicKeyPath in cyclicKeyPaths) {
        NSSet *objectsAtCyclicKeyPath = RKFlattenCollectionToSet([graph valueForKeyPath:cyclicKeyPath]);
        if ([objectsAtCyclicKeyPath count] == 0 || [objectsAtCyclicKeyPath isEqualToSet:[NSSet setWithObject:[NSNull null]]]) continue;
        if (! [objectsAtCyclicKeyPath isSubsetOfSet:mutableSet]) {
            [mutableSet unionSet:objectsAtCyclicKeyPath];
            for (id nestedValue in objectsAtCyclicKeyPath) {
                RKAddObjectsInGraphWithCyclicKeyPathsToMutableSet(nestedValue, cyclicKeyPaths, mutableSet);
            }
        }
    }
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

static void RKSetMappedValueForKeyPathInDictionary(id value, id rootKey, NSString *keyPath, NSMutableDictionary *dictionary)
{
    NSCParameterAssert(value);
    NSCParameterAssert(rootKey);
    NSCParameterAssert(dictionary);
    if (keyPath && ![keyPath isEqual:[NSNull null]]) {
        id valueAtRootKey = [dictionary objectForKey:rootKey];
        [valueAtRootKey setValue:value forKeyPath:keyPath];
    } else {
        [dictionary setObject:value forKey:rootKey];
    }
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
static NSDictionary *RKDictionaryFromDictionaryWithManagedObjectsInVisitationsRefetchedInContext(NSDictionary *dictionaryOfManagedObjects, NSArray *visitations, NSManagedObjectContext *managedObjectContext)
{
    if (! [dictionaryOfManagedObjects count]) return dictionaryOfManagedObjects;
    
    NSMutableDictionary *newDictionary = [dictionaryOfManagedObjects mutableCopy];
    [managedObjectContext performBlockAndWait:^{
        NSSet *rootKeys = [NSSet setWithArray:[visitations valueForKey:@"rootKey"]];
        for (id rootKey in rootKeys) {
            NSArray *visitationsForRootKey = [visitations filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"rootKey = %@", rootKey]];
            NSSet *keyPaths = [visitationsForRootKey valueForKey:@"keyPath"];
            // If keyPaths contains null, then the root object is a managed object and we only need to refetch it
            NSSet *nonNestedKeyPaths = ([keyPaths containsObject:[NSNull null]]) ? [NSSet setWithObject:[NSNull null]] : RKSetByRemovingSubkeypathsFromSet(keyPaths);
            
            NSDictionary *mappingResultsAtRootKey = [dictionaryOfManagedObjects objectForKey:rootKey];
            for (NSString *keyPath in nonNestedKeyPaths) {
                id value = [keyPath isEqual:[NSNull null]] ? mappingResultsAtRootKey : [mappingResultsAtRootKey valueForKeyPath:keyPath];
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
                
                if (value) {
                    RKSetMappedValueForKeyPathInDictionary(value, rootKey, keyPath, newDictionary);
                }
            }
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

- (BOOL)deleteLocalObjectsMissingFromMappingResult:(RKMappingResult *)result withVisitor:(RKNestedManagedObjectKeyPathMappingGraphVisitor *)visitor error:(NSError **)error
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
    
    for (RKMappingGraphVisitation *visitation in visitor.visitations) {
        id objectsAtRoot = [mappingResultDictionary objectForKey:visitation.rootKey];
        id managedObjects = nil;
        @try {
            managedObjects = visitation.keyPath ? [objectsAtRoot valueForKeyPath:visitation.keyPath] : objectsAtRoot;
        }
        @catch (NSException *exception) {
            if ([exception.name isEqualToString:NSUndefinedKeyException]) {
                RKLogWarning(@"Caught undefined key exception for keyPath '%@' in mapping result: This likely indicates an ambiguous keyPath is used across response descriptor or dynamic mappings.", visitation.keyPath);
                continue;
            }
            [exception raise];
        }
        [managedObjectsInMappingResult unionSet:RKFlattenCollectionToSet(managedObjects)];
        
        if (visitation.isCyclic) {
            NSSet *cyclicKeyPaths = [NSSet setWithArray:[visitation valueForKeyPath:@"mapping.relationshipMappings.destinationKeyPath"]];
            [managedObjectsInMappingResult unionSet:RKFlattenCollectionToSet(managedObjects)];
            RKAddObjectsInGraphWithCyclicKeyPathsToMutableSet(managedObjects, cyclicKeyPaths, managedObjectsInMappingResult);
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

- (void)willFinish
{
    BOOL success;
    NSError *error = nil;

    // Construct a set of key paths to all of the managed objects in the mapping result
    RKNestedManagedObjectKeyPathMappingGraphVisitor *visitor = [[RKNestedManagedObjectKeyPathMappingGraphVisitor alloc] initWithResponseDescriptors:self.responseMapperOperation.matchingResponseDescriptors];

    // Handle any cleanup
    success = [self deleteTargetObjectIfAppropriate:&error];
    if (! success) {
        self.error = error;
        return;
    }

    success = [self deleteLocalObjectsMissingFromMappingResult:self.mappingResult withVisitor:visitor error:&error];
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
    if (! success) {
        self.error = error;
        return;
    }
    
    // Refetch all managed objects nested at key paths within the results dictionary before returning
    if (self.mappingResult) {
        NSDictionary *resultsDictionaryFromOriginalContext = RKDictionaryFromDictionaryWithManagedObjectsInVisitationsRefetchedInContext([self.mappingResult dictionary], visitor.visitations, self.managedObjectContext);
        self.mappingResult = [[RKMappingResult alloc] initWithDictionary:resultsDictionaryFromOriginalContext];
    }
}

@end
