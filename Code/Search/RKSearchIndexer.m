//
//  RKSearchIndexer.m
//  RestKit
//
//  Created by Blake Watters on 7/27/12.
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

#import "RKSearchIndexer.h"
#import "RKSearchWordEntity.h"
#import "RKSearchWord.h"
#import "RKLog.h"
#import "RKSearchTokenizer.h"
#import "NSManagedObjectContext+RKAdditions.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent RKlcl_cRestKitSearch

NSString * const RKSearchableAttributeNamesUserInfoKey = @"RestKitSearchableAttributes";

@interface RKSearchIndexer ()
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, assign) NSUInteger totalIndexingOperationCount;
@end

@implementation RKSearchIndexer

+ (void)addSearchIndexingToEntity:(NSEntityDescription *)entity onAttributes:(NSArray *)attributes
{
    NSParameterAssert(entity);
    NSParameterAssert(attributes);

    // Create a relationship from the RKSearchWordEntity to the given searchable entity
    NSEntityDescription *searchWordEntity = [[entity.managedObjectModel entitiesByName] objectForKey:RKSearchWordEntityName];
    if (! searchWordEntity) {
        searchWordEntity = [[RKSearchWordEntity alloc] init];

        // Add the entity to the model
        NSArray *entities = [entity.managedObjectModel entities];
        [entity.managedObjectModel setEntities:[entities arrayByAddingObject:searchWordEntity]];
    }

    NSMutableArray *attributeNames = [NSMutableArray arrayWithCapacity:[attributes count]];
    for (id attributeIdentifier in attributes) {
        NSAttributeDescription *attribute = nil;
        if ([attributeIdentifier isKindOfClass:[NSString class]]) {
            // Look it up by name
            attribute = [[entity attributesByName] objectForKey:attributeIdentifier];
            NSAssert(attribute, @"Invalid attribute identifier given: No attribute with the name '%@' found in the '%@' entity.", attributeIdentifier, entity.name);
        } else if ([attributeIdentifier isKindOfClass:[NSAttributeDescription class]]) {
            attribute = attributeIdentifier;
        } else {
            @throw [NSException exceptionWithName:NSInvalidArgumentException
                                           reason:[NSString stringWithFormat:@"Unable to configure search indexing: Invalid attribute identifier of type '%@' given, expected an NSString or NSAttributeDescription. (Value: %@)", [attributeIdentifier class], attributeIdentifier]
                                         userInfo:nil];
        }

        NSAssert(attribute.attributeType == NSStringAttributeType, @"Invalid attribute identifier given: Expected an attribute of type NSStringAttributeType, got %ld.", (unsigned long) attribute.attributeType);
        [attributeNames addObject:attribute.name];
    }

    // Store the searchable attributes into the user info dictionary
    NSMutableDictionary *userInfo = [[entity userInfo] mutableCopy];
    [userInfo setObject:attributeNames forKey:RKSearchableAttributeNamesUserInfoKey];
    [entity setUserInfo:userInfo];

    // Create a relationship from our indexed entity to the RKSearchWord entity
    NSRelationshipDescription *relationship = [[NSRelationshipDescription alloc] init];
    [relationship setName:RKSearchWordsRelationshipName];
    [relationship setDestinationEntity:searchWordEntity];
    [relationship setMaxCount:0]; // Make it to-many
    [relationship setDeleteRule:NSNullifyDeleteRule];

    NSArray *properties = [entity properties];
    [entity setProperties:[properties arrayByAddingObject:relationship]];

    // Create an inverse relationship from the searchWords to the searchable entity
    NSRelationshipDescription *inverseRelationship = [[NSRelationshipDescription alloc] init];
    [inverseRelationship setName:entity.name];
    [inverseRelationship setDestinationEntity:entity];
    [inverseRelationship setDeleteRule:NSNullifyDeleteRule];
    NSArray *searchWordProperties = [searchWordEntity properties];
    [searchWordEntity setProperties:[searchWordProperties arrayByAddingObject:inverseRelationship]];

    // Connect the relationships as inverses
    [relationship setInverseRelationship:inverseRelationship];
    [inverseRelationship setInverseRelationship:relationship];
}

- (id)init
{
    self = [super init];
    if (self) {
        // Setup serial operation queue to enable cancellation of indexing
        self.operationQueue = [NSOperationQueue new];
        self.operationQueue.maxConcurrentOperationCount = 1;
        [self.operationQueue addObserver:self forKeyPath:@"operationCount" options:0 context:NULL];
    }
    
    return self;
}

- (void)dealloc
{
    [self cancelAllIndexingOperations];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)startObservingManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    NSParameterAssert(managedObjectContext);

    if (self.indexingContext) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleManagedObjectContextDidSaveNotification:)
                                                     name:NSManagedObjectContextDidSaveNotification
                                                   object:managedObjectContext];
    } else {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleManagedObjectContextWillSaveNotification:)
                                                     name:NSManagedObjectContextWillSaveNotification
                                                   object:managedObjectContext];
    }
}

- (void)stopObservingManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    NSParameterAssert(managedObjectContext);
    [[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:managedObjectContext];
}

- (NSUInteger)indexManagedObject:(NSManagedObject *)managedObject withProgressBlock:(void (^)(NSManagedObject *managedObject, RKSearchWord *searchWord, BOOL *stop))progressBlock;
{
    @autoreleasepool {

        RKLogDebug(@"Indexing searchable attributes of managed object: %@", managedObject);
        NSArray *searchableAttributes = [managedObject.entity.userInfo objectForKey:RKSearchableAttributeNamesUserInfoKey];
        if (! searchableAttributes) {
            [NSException raise:NSInvalidArgumentException format:@"The given managed object %@ is for an entity (%@) that does not define any searchable attributes. Perhaps you forgot to invoke addSearchIndexingToEntity:onAttributes:?", managedObject, managedObject.entity];
            return NSNotFound;
        }

        RKSearchTokenizer *searchTokenizer = [RKSearchTokenizer new];
        searchTokenizer.stopWords = self.stopWords;

        __block NSUInteger searchWordCount;
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:RKSearchWordEntityName];
        fetchRequest.fetchLimit = 1;
        NSPredicate *predicateTemplate = [NSPredicate predicateWithFormat:@"%K == $SEARCH_WORD", RKSearchWordAttributeName];
        NSManagedObjectContext *managedObjectContext = managedObject.managedObjectContext;
        __block BOOL stop = NO;
        
        [managedObjectContext performBlockAndWait:^{
            NSMutableSet *searchWords = [NSMutableSet set];
            for (NSString *searchableAttribute in searchableAttributes) {
                NSString *attributeValue = [managedObject valueForKey:searchableAttribute];
                if (attributeValue) {
                    RKLogTrace(@"Generating search words for searchable attribute: %@", searchableAttribute);
                    NSSet *tokens = [searchTokenizer tokenize:attributeValue];
                    for (NSString *word in tokens) {
                        if (word && [word length] > 0) {
                            RKSearchWord *searchWord = nil;
                            NSError *error = nil;
                            if ([self.delegate respondsToSelector:@selector(searchIndexer:searchWordForWord:inManagedObjectContext:error:)]) {
                                // Let our delegate retrieve an existing search word
                                searchWord = [self.delegate searchIndexer:self searchWordForWord:word inManagedObjectContext:managedObjectContext error:&error];
                            } else {
                                // Fall back to vanilla fetch request
                                fetchRequest.predicate = [predicateTemplate predicateWithSubstitutionVariables:@{ @"SEARCH_WORD" : word }];
                                NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
                                searchWord = ([results count] > 0) ? [results objectAtIndex:0] : nil;
                            }
                            if (error == nil) {
                                if (! searchWord) {
                                    if ([self.delegate respondsToSelector:@selector(searchIndexer:shouldInsertSearchWordForWord:inManagedObjectContext:)]) {
                                        if (! [self.delegate searchIndexer:self shouldInsertSearchWordForWord:word inManagedObjectContext:managedObjectContext]) {
                                            continue;
                                        }
                                    }
                                    searchWord = [NSEntityDescription insertNewObjectForEntityForName:RKSearchWordEntityName inManagedObjectContext:managedObjectContext];
                                    searchWord.word = word;
                                    
                                    if ([self.delegate respondsToSelector:@selector(searchIndexer:didInsertSearchWord:forWord:inManagedObjectContext:)]) {
                                        [self.delegate searchIndexer:self didInsertSearchWord:searchWord forWord:word inManagedObjectContext:managedObjectContext];
                                    }
                                }

                                NSAssert([[searchWord managedObjectContext] isEqual:managedObjectContext], @"Serious Core Data error: Expected `NSManagedObject` for the 'RKSearchWord' entity in context %@, but got one in %@", managedObject, [searchWord managedObjectContext]);
                                [searchWords addObject:searchWord];
                                                                
                                if (progressBlock) progressBlock(managedObject, searchWord, &stop);
                            } else {
                                RKLogError(@"Failed to retrieve search word: %@", error);
                            }
                        }
                        
                        if (stop) break;
                    }
                }
                
                if (stop) break;
            }

            if (! stop) {
                [managedObject setValue:searchWords forKey:RKSearchWordsRelationshipName];
                RKLogTrace(@"Indexed search words: %@", [searchWords valueForKey:RKSearchWordAttributeName]);
                searchWordCount = [searchWords count];
                
                if ([self.delegate respondsToSelector:@selector(searchIndexer:didIndexManagedObject:)]) {
                    [self.delegate searchIndexer:self didIndexManagedObject:managedObject];
                }
            }
        }];

        return searchWordCount;
    }
}

- (NSUInteger)indexManagedObject:(NSManagedObject *)managedObject
{
    return [self indexManagedObject:managedObject withProgressBlock:nil];
}

/**
 NOTE: Does **NOT** use the indexing context as unsaved objects would not be available for indexing in that context
 */
- (void)indexChangedObjectsInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
                                waitUntilFinished:(BOOL)wait
{
    NSParameterAssert(managedObjectContext);
    
    NSSet *candidateObjects = [[NSSet setWithSet:managedObjectContext.insertedObjects] setByAddingObjectsFromSet:managedObjectContext.updatedObjects];
    NSSet *objectsToIndex = [self objectsToIndexFromCandidateObjects:candidateObjects checkChangedValues:YES];
    
    if (wait) {
        // Synchronous indexing
        NSUInteger totalObjects = [objectsToIndex count];
        __block NSMutableSet *indexedIDs = [NSMutableSet setWithCapacity:totalObjects];
        for (NSManagedObject *managedObject in objectsToIndex) {
            if ([self.delegate respondsToSelector:@selector(searchIndexer:shouldIndexManagedObject:)]) {
                if (! [self.delegate searchIndexer:self shouldIndexManagedObject:managedObject]) continue;
            }
            [self indexManagedObject:managedObject withProgressBlock:^(NSManagedObject *managedObject, RKSearchWord *searchWord, BOOL *stop) {
                if (totalObjects < 250) return;
                if ([indexedIDs containsObject:[managedObject objectID]]) return;
                [indexedIDs addObject:[managedObject objectID]];
                double percentage = (((float)[indexedIDs count]) / (float)totalObjects) * 100;
                if ([indexedIDs count] % 250 == 0 || percentage >= 100.0) RKLogInfo(@"Indexing object %ld of %ld (%.2f%% complete)", (unsigned long) [indexedIDs count], (unsigned long) totalObjects, percentage);
            }];
        }
                
        if (totalObjects >= 250) RKLogInfo(@"Finished indexing.");
    } else {
        // Perform asynchronous indexing
        [self.operationQueue addOperationWithBlock:^{
            for (NSManagedObject *managedObject in objectsToIndex) {
                if ([self.delegate respondsToSelector:@selector(searchIndexer:shouldIndexManagedObject:)]) {
                    if (! [self.delegate searchIndexer:self shouldIndexManagedObject:managedObject]) continue;
                }
                [self indexManagedObject:managedObject];
            }
        }];
        self.totalIndexingOperationCount = [self.operationQueue operationCount];
    }
}

- (void)indexChangedObjectsFromManagedObjectContextDidSaveNotification:(NSNotification *)notification
{
    if (! self.indexingContext) {
        RKLogWarning(@"Received `NSManagedObjectContextDidSaveNotification` with nil indexing context: ignoring...");
        return;
    }
    
    NSDictionary *userInfo = [notification userInfo];
    NSSet *candidateObjects = [[NSSet setWithSet:[userInfo objectForKey:NSInsertedObjectsKey]] setByAddingObjectsFromSet:[userInfo objectForKey:NSUpdatedObjectsKey]];
    NSSet *objectsToIndex = [self objectsToIndexFromCandidateObjects:candidateObjects checkChangedValues:NO];    
    
    NSMutableSet *failedObjectIDs = [NSMutableSet set];
    
    // Enqueue an operation for each object to index
    NSArray *objectIDsForObjectsToIndex = [objectsToIndex valueForKey:@"objectID"];
    __block NSBlockOperation *indexingOperation = [NSBlockOperation blockOperationWithBlock:^{
        if ([indexingOperation isCancelled]) return;
        [self.indexingContext performBlockAndWait:^{
            for (NSManagedObjectID *objectID in objectIDsForObjectsToIndex) {
                if ([indexingOperation isCancelled]) return;
                NSError *error = nil;
                NSManagedObject *managedObject = [self.indexingContext existingObjectWithID:objectID error:&error];
                NSAssert(managedObject == nil || [[managedObject managedObjectContext] isEqual:self.indexingContext], @"Serious Core Data error: Asked for an `NSManagedObject` with ID %@ in indexing context %@, but got one in %@", objectID, self.indexingContext, [managedObject managedObjectContext]);
                if (managedObject && error == nil) {
                    BOOL performIndexing = YES;
                    if ([self.delegate respondsToSelector:@selector(searchIndexer:shouldIndexManagedObject:)]) {
                        performIndexing = [self.delegate searchIndexer:self shouldIndexManagedObject:managedObject];
                    }
                    if (performIndexing) {
                        [self indexManagedObject:managedObject withProgressBlock:^(NSManagedObject *managedObject, RKSearchWord *searchWord, BOOL *stop) {
                            // Stop the indexing process if we have been cancelled
                            if ([indexingOperation isCancelled]) *stop = YES;
                        }];
                    }
                } else {
                    RKLogError(@"Failed indexing of object %@ with error: %@", managedObject, error);
                }
            }
            
            // After all indexing is complete, save the indexing context
            if ([indexingOperation isCancelled]) return;
            NSError *error = nil;
            RKLogInfo(@"Indexing completed. Saving indexing context...");
            BOOL success = [self.indexingContext saveToPersistentStore:&error];
            if (! success) {
                RKLogError(@"Failed to save indexing context: %@", error);
            }
        }];
    }];
    
    [self.operationQueue addOperation:indexingOperation];
    
    // Assert that we indexed everything sucessfully
    [self.operationQueue addOperationWithBlock:^{
        NSAssert([failedObjectIDs count] == 0, @"Expected no indexing failures, got %ld", (long) [failedObjectIDs count]);
    }];
    
    self.totalIndexingOperationCount = [self.operationQueue operationCount];
}

- (void)cancelAllIndexingOperations
{
    [self.operationQueue cancelAllOperations];
}

- (void)waitUntilAllIndexingOperationsAreFinished
{
    [self.operationQueue waitUntilAllOperationsAreFinished];
}

#pragma mark - Private

- (void)handleManagedObjectContextWillSaveNotification:(NSNotification *)notification
{
    NSManagedObjectContext *managedObjectContext = [notification object];
    RKLogInfo(@"Managed object context will save notification received. Checking changed and inserted objects for searchable entities...");

    // We wait until finished to ensure that the indexed objects are persisted with the save
    [self indexChangedObjectsInManagedObjectContext:managedObjectContext waitUntilFinished:YES];
}

- (void)handleManagedObjectContextDidSaveNotification:(NSNotification *)notification
{
    RKLogInfo(@"Managed object context did save notification received. Checking changed and inserted objects for searchable entities...");
    [self indexChangedObjectsFromManagedObjectContextDidSaveNotification:notification];
}

- (NSSet *)objectsToIndexFromCandidateObjects:(NSSet *)objects checkChangedValues:(BOOL)checkChangedValues
{
    NSUInteger totalObjects = [objects count];
    NSMutableSet *objectsNeedingIndexing = [[NSMutableSet alloc] initWithCapacity:totalObjects];
    RKLogInfo(@"Indexing %ld changed objects", (unsigned long) totalObjects);

    for (NSManagedObject *managedObject in objects) {        
        NSArray *searchableAttributes = [managedObject.entity.userInfo objectForKey:RKSearchableAttributeNamesUserInfoKey];
        if (! searchableAttributes) {
            RKLogTrace(@"Skipping indexing for managed object for entity '%@': no searchable attributes found.", managedObject.entity.name);
            continue;
        }

        for (NSString *attribute in searchableAttributes) {
            if (!checkChangedValues || [[managedObject changedValues] objectForKey:attribute]) {
                RKLogTrace(@"Detected change to searchable attribute '%@' for managed object '%@': updating search index.", attribute, managedObject);
                [objectsNeedingIndexing addObject:managedObject];
                break;
            }
        }
    }
    return objectsNeedingIndexing;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"operationCount"]) {
        if (self.totalIndexingOperationCount > 0 && self.operationQueue.operationCount > 0) {
            NSUInteger index = self.totalIndexingOperationCount - self.operationQueue.operationCount;
            double percentage = (((float)index) / (float)self.totalIndexingOperationCount) * 100;
            if (index % 250 == 0) RKLogInfo(@"Indexing object %ld of %ld (%.2f%% complete)", (unsigned long) index, (unsigned long) self.totalIndexingOperationCount, percentage);
            if (self.operationQueue.operationCount == 0) {
                if (self.totalIndexingOperationCount >= 250) RKLogInfo(@"Finished indexing.");
                self.totalIndexingOperationCount = 0;
            }
        }
    }
}

@end
