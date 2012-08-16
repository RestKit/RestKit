//
//  RKManagedObjectStore+RKSearchAdditions.h
//  RestKit
//
//  Created by Blake Watters on 7/27/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <RestKit/RKManagedObjectStore.h>
#import <RestKit/RKSearchIndexer.h>

/**
 The search additions category provides support for configuring search indexing 
 for entities in a managed object store.
 */
@interface RKManagedObjectStore (RKSearchAdditions)

/**
 Adds search indexing to the entity for the given name in the receiver's managed object model.
 
 Invocation of this method will result in the entity for the given name being updated to include a new
 to-many relationship with the name 'searchWords'. The receiver's search indexer will also be instructed
 to begin monitoring changes to the specified entity's searchable attributes to maintain the collection
 of search words. If no search indexer exists, a new 
 
 @param entityName The name of the entity in the receiver's managed object model that should be made searchable.
 @param attributes An array of NSAttributeDescription objects or NSString attribute names specifying the 
    NSStringAttributeType attributes that are to be indexed for searching.
 
 @warning Must be invoked before adding persistent stores as the managed object model will become
    immutable once the persistent store coordinator is created.
 */
- (void)addSearchIndexingToEntityForName:(NSString *)entityName onAttributes:(NSArray *)attributes;

/**
 The search indexer for the receiver's primary managed object context.
 
 A search indexer is instantiated when search indexing is added to an entity
 in the receiver's managed object model.
 */
@property (nonatomic, readonly) RKSearchIndexer *searchIndexer;

/**
 Tells the search indexer to begin observing the primary managed object context for changes to searchable
 entities and updating the search words.
 
 This is a convenience method that is equivalent to the following example code:
 
    RKSearchIndexer *searchIndexer = managedObjectStore.searchIndexer;
    [searchIndexer startObservingManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
 
 @see RKSearchIndexer
 */
- (void)startIndexingPrimaryManagedObjectContext;

/**
 Tells the search indexer to stop observing the primary managed object context for changes to searchable entities.
 
 This is a convenience method that is equivalent to the following example code:
 
    RKSearchIndexer *searchIndexer = managedObjectStore.searchIndexer;
    [searchIndexer stopObservingManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
 
 @see RKSearchIndexer
 */
- (void)stopIndexingPrimaryManagedObjectContext;

@end
