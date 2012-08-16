//
//  RKSearchIndexer.h
//  RestKit
//
//  Created by Blake Watters on 7/27/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import <CoreData/CoreData.h>

/**
 The key for an NSArray object that indentifies the list of searchable
 attributes in the user info dictionary of an NSEntityDescription.
 */
extern NSString * const RKSearchableAttributeNamesUserInfoKey;

/**
 The RKSearchIndexer class provides support for adding full text searching
 to Core Data entities and managing the indexing of managed object instances
 of searchable entities.
 */
@interface RKSearchIndexer : NSObject

///-----------------------------------------------------------------------------
/// @name Adding Indexing to an Entity
///-----------------------------------------------------------------------------

/**
 Adds search indexing to the given entity for a given list of attributes identified by
 name. The entity will have a to-many relationship to the RKSearchWordEntity added and
 the list of searchable attributes stored into the user info dictionary. 
 
 Managed objects for entities that have had indexing added to them can be indexed by instances of
 RKSearchIndexer and searched via an RKSearchPredicate in a fetch request.
 
 The given entity must exist in a mutable managed object model (that is, one that has not
 been used to create an object graph in a managed object context). The given list of attributes
 must identify attributes of the given entity with the attribute type of NSStringAttributeType.
 
 @param entity The entity to which search indexing support is to be added.
 @param attributes An array of NSAttributeDescription objects or NSString attribute names specifying the
    NSStringAttributeType attributes that are to be indexed for searching.
 */
+ (void)addSearchIndexingToEntity:(NSEntityDescription *)entity onAttributes:(NSArray *)attributes;

///-----------------------------------------------------------------------------
/// @name Configuring Indexing
///-----------------------------------------------------------------------------

/**
 An optional set of stop words to be removed from the set of tokens
 used to create the search words for indexed entities.
 */
@property (nonatomic, retain) NSSet *stopWords;

///-----------------------------------------------------------------------------
/// @name Indexing Changes in a Managed Object Context
///-----------------------------------------------------------------------------

/**
 Tells the receiver to tart monitoring the given managed object context for the 
 NSManagedObjectContextWillSaveNotification and to index any changed objects prior
 to the completion of the save.
 
 @param managedObjectContext The managed object context to be monitored for save notifications.
 
 @see indexChangedObjectsInManagedObjectContext:
 */
- (void)startObservingManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

/**
 Tells the receiver to stop monitoring the given managed object context for the
 NSManagedObjectContextWillSaveNotification and cease indexing changed objects prior to
 the completion of the save.
 
 @param managedObjectContext The managed object context that is no longer to be monitored for 
    save notifications.
 */
- (void)stopObservingManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

/**
 Tells the receiver to build a list of all inserted or updated managed objects in the given
 context and index each one. Objects for entities that are not indexed are silently ignored.
 
 Invoked by the indexer in response to a NSManagedObjectContextWillSaveNotification if the
 context is being observed.
 
 @param managedObjectContext The managed object context that is to be indexed.
 */
- (void)indexChangedObjectsInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

///-----------------------------------------------------------------------------
/// @name Indexing a Managed Object
///-----------------------------------------------------------------------------

/**
 Tells the receiver to index a given managed object instance.
 
 @param managedObject The managed object that is to be indexed.
 @return A count of the number of search words that were indexed from the given object's
    searchable attributes.
 @raises NSInvalidArgumentException Raised if the given managed object is not for a searchable
    entity.
 */
- (NSUInteger)indexManagedObject:(NSManagedObject *)managedObject;

@end
