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

    if (self.indexingContext) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:managedObjectContext];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextWillSaveNotification object:managedObjectContext];
    }
}

- (NSUInteger)indexManagedObject:(NSManagedObject *)managedObject
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

        [managedObjectContext performBlockAndWait:^{
            NSMutableSet *searchWords = [NSMutableSet set];
            for (NSString *searchableAttribute in searchableAttributes) {
                NSString *attributeValue = [managedObject valueForKey:searchableAttribute];
                if (attributeValue) {
                    RKLogTrace(@"Generating search words for searchable attribute: %@", searchableAttribute);
                    NSSet *tokens = [searchTokenizer tokenize:attributeValue];
                    for (NSString *word in tokens) {
                        if (word && [word length] > 0) {
                            fetchRequest.predicate = [predicateTemplate predicateWithSubstitutionVariables:@{ @"SEARCH_WORD" : word }];
                            NSError *error = nil;
                            NSArray *results = [managedObject.managedObjectContext executeFetchRequest:fetchRequest error:&error];
                            if (results) {
                                RKSearchWord *searchWord;
                                if ([results count] == 0) {
                                    searchWord = [NSEntityDescription insertNewObjectForEntityForName:RKSearchWordEntityName inManagedObjectContext:managedObjectContext];
                                    searchWord.word = word;
                                } else {
                                    searchWord = [results objectAtIndex:0];
                                }

                                [searchWords addObject:searchWord];
                            } else {
                                RKLogError(@"Failed to retrieve search word: %@", error);
                            }
                        }
                    }
                }
            }

            [managedObject setValue:searchWords forKey:RKSearchWordsRelationshipName];
            RKLogTrace(@"Indexed search words: %@", [searchWords valueForKey:RKSearchWordAttributeName]);
            searchWordCount = [searchWords count];
        }];

        return searchWordCount;
    }
}

- (void)indexChangedObjectsInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    NSArray *candidateObjects = [[[NSSet setWithSet:managedObjectContext.insertedObjects] setByAddingObjectsFromSet:managedObjectContext.updatedObjects] allObjects];
    NSArray *objectsToIndex = [self objectsToIndexFromObjects:candidateObjects checkChangedValues:YES];
    for (NSManagedObject *managedObject in objectsToIndex) {
        [self indexManagedObject:managedObject];
    }
}

- (void)indexChangedObjectsFromManagedObjectContextDidSaveNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSArray *candidateObjects = [[[NSSet setWithSet:[userInfo objectForKey:NSInsertedObjectsKey]] setByAddingObjectsFromSet:[userInfo objectForKey:NSUpdatedObjectsKey]] allObjects];
    NSArray *objectsToIndex = [self objectsToIndexFromObjects:candidateObjects checkChangedValues:NO];

    NSArray *objectIDsForObjectsToIndex = [objectsToIndex valueForKey:@"objectID"];
    [self.indexingContext performBlock:^{
        [self.indexingContext reset];
        NSUInteger indexedObjects = 0;
        for (NSManagedObjectID *managedObjectID in objectIDsForObjectsToIndex) {
            NSError *error = nil;
            NSManagedObject *managedObject = [self.indexingContext existingObjectWithID:managedObjectID error:&error];
            if (managedObject && error == nil) {
                [self indexManagedObject:managedObject];
                indexedObjects++;
            } else {
                RKLogError(@"Skipping indexing of object (%@) with ID (%@) and error (%@)", managedObject, managedObjectID, error);
            }
        }
        RKLogTrace(@"Completed indexing of %d changed objects", indexedObjects);
        NSAssert(objectsToIndex.count == indexedObjects, @"Expected indexing to index all candidate objects");

        NSError *error = nil;
        [self.indexingContext saveToPersistentStore:&error];
    }];
}

#pragma mark - Private

- (void)handleManagedObjectContextWillSaveNotification:(NSNotification *)notification
{
    NSManagedObjectContext *managedObjectContext = [notification object];
    RKLogInfo(@"Managed object context will save notification received. Checking changed and inserted objects for searchable entities...");

    [self indexChangedObjectsInManagedObjectContext:managedObjectContext];
}

- (void)handleManagedObjectContextDidSaveNotification:(NSNotification *)notification
{
    RKLogInfo(@"Managed object context did save notification received. Checking changed and inserted objects for searchable entities...");
    [self indexChangedObjectsFromManagedObjectContextDidSaveNotification:notification];
}

- (NSArray *)objectsToIndexFromObjects:(NSArray *)objects checkChangedValues:(BOOL)checkChangedValues
{
    NSUInteger totalObjects = [objects count];
    NSMutableArray *objectsNeedingIndexing = [[NSMutableArray alloc] initWithCapacity:totalObjects];
    RKLogInfo(@"Indexing %ld changed objects@", (unsigned long) totalObjects);

    for (NSManagedObject *managedObject in objects) {
        NSUInteger index = [objects indexOfObject:managedObject];
        double percentage = (((float)index + 1) / (float)totalObjects) * 100;
        if ((index + 1) % 250 == 0) RKLogInfo(@"Indexed %ld of %ld (%.2f%% complete)", (unsigned long) index + 1, (unsigned long) totalObjects, percentage);
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

@end
