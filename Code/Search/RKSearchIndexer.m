//
//  RKSearchIndexer.m
//  RestKit
//
//  Created by Blake Watters on 7/27/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKSearchIndexer.h"
#import "RKSearchWordEntity.h"
#import "RKSearchWord.h"
#import "RKLog.h"
#import "RKSearchTokenizer.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitSearch

NSString * const RKSearchableAttributeNamesUserInfoKey = @"RestKitSearchableAttributes";

@implementation RKSearchIndexer

+ (void)addSearchIndexingToEntity:(NSEntityDescription *)entity onAttributes:(NSArray *)attributes
{
    NSParameterAssert(entity);
    NSParameterAssert(attributes);
    
    // Create a relationship from the RKSearchWordEntity to the given searchable entity
    NSEntityDescription *searchWordEntity = [[entity.managedObjectModel entitiesByName] objectForKey:RKSearchWordEntityName];
    if (! searchWordEntity) {
        searchWordEntity = [[[RKSearchWordEntity alloc] init] autorelease];
        
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
        
        NSAssert(attribute.attributeType == NSStringAttributeType, @"Invalid attribute identifier given: Expected an attribute of type NSStringAttributeType, got %d.", attribute.attributeType);
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
    
    [inverseRelationship release];
    [relationship release];
}

- (void)startObservingManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    NSParameterAssert(managedObjectContext);
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleManagedObjectContextWillSaveNotification:)
                                                 name:NSManagedObjectContextWillSaveNotification
                                               object:managedObjectContext];
}

- (void)stopObservingManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    NSParameterAssert(managedObjectContext);
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextWillSaveNotification object:managedObjectContext];
}

- (NSUInteger)indexManagedObject:(NSManagedObject *)managedObject
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    RKLogDebug(@"Indexing searchable attributes of managed object: %@", managedObject);
    NSArray *searchableAttributes = [managedObject.entity.userInfo objectForKey:RKSearchableAttributeNamesUserInfoKey];
    if (! searchableAttributes) {
        [NSException raise:NSInvalidArgumentException format:@"The given managed object %@ is for an entity (%@) that does not define any searchable attributes. Perhaps you forgot to invoke addSearchIndexingToEntity:onAttributes:?", managedObject, managedObject.entity];
        return NSNotFound;
    }
    
    RKSearchTokenizer *searchTokenizer = [RKSearchTokenizer new];
    searchTokenizer.stopWords = self.stopWords;
    
    __block NSUInteger searchWordCount;
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
                        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:RKSearchWordEntityName];
                        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K = %@", RKSearchWordAttributeName, word];
                        fetchRequest.fetchLimit = 1;
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
    
    [pool drain];
    
    return searchWordCount;
}

- (void)indexChangedObjectsInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    NSArray *candidateObjects = [[[NSSet setWithSet:managedObjectContext.insertedObjects] setByAddingObjectsFromSet:managedObjectContext.updatedObjects] allObjects];
    NSUInteger totalObjects = [candidateObjects count];
    RKLogInfo(@"Indexing %d changed objects in managed object context: %@", totalObjects, managedObjectContext);
    
    for (NSManagedObject *managedObject in candidateObjects) {
        NSUInteger index = [candidateObjects indexOfObject:managedObject];
        double percentage = (((float)index + 1) / (float)totalObjects) * 100;
        if ((index + 1) % 250 == 0) RKLogInfo(@"Indexed %d of %d (%.2f%% complete)", index + 1, totalObjects, percentage);
        NSArray *searchableAttributes = [managedObject.entity.userInfo objectForKey:RKSearchableAttributeNamesUserInfoKey];
        if (! searchableAttributes) {
            RKLogTrace(@"Skipping indexing for managed object for entity '%@': no searchable attributes found.", managedObject.entity.name);
            continue;
        }
        
        for (NSString *attribute in searchableAttributes) {
            if ([[managedObject changedValues] objectForKey:attribute]) {
                RKLogTrace(@"Detected change to searchable attribute '%@' for managed object '%@': updating search index.", attribute, managedObject);
                [self indexManagedObject:managedObject];
                break;
            }
        }
    }
}

#pragma mark - Private

- (void)handleManagedObjectContextWillSaveNotification:(NSNotification *)notification
{
    NSManagedObjectContext *managedObjectContext = [notification object];
    RKLogInfo(@"Managed object context will save notification received. Checking changed and inserted objects for searchable entities...");
    
    [self indexChangedObjectsInManagedObjectContext:managedObjectContext];
}

@end
