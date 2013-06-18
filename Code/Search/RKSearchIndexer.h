//
//  RKSearchIndexer.h
//  RestKit
//
//  Created by Blake Watters on 7/27/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
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

#import <CoreData/CoreData.h>

@class RKSearchWord;

/**
 The key for an NSArray object that indentifies the list of searchable attributes in the user info dictionary of an NSEntityDescription.
 */
extern NSString * const RKSearchableAttributeNamesUserInfoKey;

@protocol RKSearchIndexerDelegate;

/**
 The `RKSearchIndexer` class provides support for adding full text searching to Core Data entities and managing the indexing of managed object instances of searchable entities.
 */
@interface RKSearchIndexer : NSObject

///-----------------------------------
/// @name Adding Indexing to an Entity
///-----------------------------------

/**
 Adds search indexing to the given entity for a given list of attributes identified by name. The entity will have a to-many relationship to the `RKSearchWordEntity` added and the list of searchable attributes stored into the user info dictionary.

 Managed objects for entities that have had indexing added to them can be indexed by instances of `RKSearchIndexer` and searched via an `RKSearchPredicate` used with an `NSFetchRequest` object.

 The given entity must exist in a mutable managed object model (that is, one that has not been used to create an object graph in a managed object context). The given list of attributes must identify attributes of the given entity with the attribute type of `NSStringAttributeType`.

 @param entity The entity to which search indexing support is to be added.
 @param attributes An array of NSAttributeDescription objects or NSString attribute names specifying the `NSStringAttributeType` attributes that are to be indexed for searching.
 */
+ (void)addSearchIndexingToEntity:(NSEntityDescription *)entity onAttributes:(NSArray *)attributes;

///---------------------------
/// @name Configuring Indexing
///---------------------------

/**
 An optional set of stop words to be removed from the set of tokens used to create the search words for indexed entities.
 */
@property (nonatomic, strong) NSSet *stopWords;

/**
 An optional `NSManagedObjectContext` in which to perform indexing operations.
 
 **Default**: `nil`
 
 @warning It is recommended that the indexing context be configured with a direct connection to the persistent store coordinator and a merge policy of `NSMergeByPropertyObjectTrumpMergePolicy`.
 */
@property (nonatomic, strong) NSManagedObjectContext *indexingContext;

/**
 The delegate of the search indexer.
 */
@property (nonatomic, weak) id<RKSearchIndexerDelegate> delegate;

///---------------------------------------------------
/// @name Indexing Changes in a Managed Object Context
///---------------------------------------------------

/**
 Tells the receiver to start monitoring the given managed object context for save notifications and to index any changed objects in response to the save.
 
 @param managedObjectContext The managed object context to be monitored for save notifications.
 @see `indexChangedObjectsInManagedObjectContext:`
 @see `indexingContext`
 
 @warning The behavior of this method changes based on the availability of an `indexingContext`. When the indexing context is `nil`, this method will register the receiver as an observer for the `NSManagedObjectContextWillSaveNotification`. At save time, the indexer will scan the set of changed objects in the save notification and synchronously index each changed object prior to the completion of the save. This is simple, but introduces a performance penalty that may not be unacceptable.
 
 When an indexing context is provided, invoking `startObservingManagedObjectContext:` will cause the receiver to register for the `NSManagedObjectContextDidSaveNotification` instead. After a save completes, the indexer will reset the indexing context and enqueue an indexing operation for each changed object in the notification. Once all the indexing operations have completed, the indexing context will be saved and its contents should be merged into other contexts.
 */
- (void)startObservingManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

/**
 Tells the receiver to stop monitoring the given managed object context for save notifications and cease indexing changed objects in response to the save.

 @param managedObjectContext The managed object context that is no longer to be monitored for save notifications.
 @see `indexingContext`
 */
- (void)stopObservingManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

/**
 Tells the receiver to build a list of all inserted or updated managed objects in the given context and index each one. Objects for entities that are not indexed are silently ignored.

 The value of the `wait` parameter is significant in the determination of the indexing strategy. When `YES`, indexing is perform synchronously. When `NO`, indexing operations are enqueued and the method returns to the caller immediately. Enqueued indexing operations can later be cancelled by invoking `cancelAllIndexingOperations`.

 This method is called by the indexer in response to a `NSManagedObjectContextWillSaveNotification` for contexts observed with `startObservingManagedObjectContext:`.

 @param managedObjectContext The managed object context that is to be indexed.
 @param wait A Boolean value that determines if the current thread will be blocked until all indexing operations have completed.
 @warning Indexing all changed objects in a managed object context **does not** utilize the `indexingContext` as unsaved objects in the graph would not be visible to that context.
 
 Please beware that indexing changed objects in a context with the `NSMainQueueConcurrencyType` asynchronously (where `wait == NO`) and then invoking `waitUntilAllIndexingOperationsAreFinished` will result in a deadlock if called from the main thread. It is highly recommended that indexing be performed in contexts with the `NSPrivateQueueConcurrencyType` to take advantage of queueing and avoid blocking the main thread.
 */
- (void)indexChangedObjectsInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
                                waitUntilFinished:(BOOL)wait;

///--------------------------------
/// @name Indexing a Managed Object
///--------------------------------

/**
 Tells the receiver to index a given managed object instance.

 @param managedObject The managed object that is to be indexed.
 @return A count of the number of search words that were indexed from the given object's searchable attributes.
 @raises `NSInvalidArgumentException` Raised if the given managed object is not for a searchable entity.
 */
- (NSUInteger)indexManagedObject:(NSManagedObject *)managedObject;

///-----------------------------------
/// @name Managing Indexing Operations
///-----------------------------------

/**
 Tells the indexer to cancel all indexing operations in progress.
 
 When a managed object context that is being observed is saved, the indexer enqueues an indexing operation for each indexable object that was inserted or updated during the save event. This method provides support for cancelling all in indexing operations that have not yet been processed.
 */
- (void)cancelAllIndexingOperations;

/**
 Blocks the current thread until all of the receiver’s queued and executing indexing operations finish executing.
 
 When called, this method blocks the current thread and waits for the receiver’s current and queued indexing operations to finish executing. While the current thread is blocked, the receiver continues to launch already queued operations and monitor those that are executing. During this time, the current thread cannot add operations to the queue, but other threads may. Once all of the pending operations are finished, this method returns.
 
 If there are no indexing operations in the queue, this method returns immediately.

 @warning Invoking this method may cause a deadlock if indexing operations have been enqueued for a managed object context with the `NSMainQueueConcurrencyType` and the method is called from the main thread.
 */
- (void)waitUntilAllIndexingOperationsAreFinished;

@end

/**
 Objects that acts as the delegate for a `RKSearchIndexer` object must adopt the `RKSearchIndexerDelegate` protocol. The delegate may customize the behavior of the search indexer to match the needs of the application in several ways. The delegate may provide an alternate implementation for fetching an existing `RKSearchWord` managed object for a given word, it  is consulted when the indexer determines that a new search word object is to be inserted and may decline the insertion, and it is notified after a new search word has been inserted.
 */
@protocol RKSearchIndexerDelegate <NSObject>

@optional

///-------------------------------------
/// @name Fetching Existing Search Words
///-------------------------------------

/**
 Asks the delegate for an existing search word object for a given word in the managed object context being indexed. If no search word is found for the given word, then `nil` is to be returned.
 
 By default, the search indexer creates and executes a fetch request against the context being indexed for each word during indexing. For large data-sets, this can wind up taking a significant amount of time. By providing an implementation of `searchIndexer:searchWordForWord:inManagedObjectContext:error:`, the delegate can be used to implement a caching scheme to reduce the overhead associated with the execution of these fetch requests.
 
 @param searchIndexer The search indexer object performing the indexing.
 @param word The search word for which to retrieve an existing
 @param managedObjectContext The managed object context in which indexing is taking place.
 @param error A pointer to an error object to be set in the event an error occurs.
 @return The `RKSearchWord` object corresponding to the given word, or `nil` if none could be found. In the event an error occurs, `nil` is to be returned and the value of the error property is to be set to a pointer to an `NSError` object describing the failure.
 */
- (RKSearchWord *)searchIndexer:(RKSearchIndexer *)searchIndexer searchWordForWord:(NSString *)word inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext error:(NSError **)error;

///-------------------------------------------
/// @name Tracking Indexing of Managed Objects
///-------------------------------------------

/**
 Asks the delegate is a managed object should be indexed.
 
 @param searchIndexer The search indexer object performing the indexing. 
 @param managedObject The managed object the indexer is preparing to index.
 @return `YES` if indexing should proceed, else `NO`.
 */
- (BOOL)searchIndexer:(RKSearchIndexer *)searchIndexer shouldIndexManagedObject:(NSManagedObject *)managedObject;

/**
 Tells the delegate that the indexer has finished indexing a managed object.
 
 @param searchIndexer The search indexer object performing the indexing.
 @param managedObject The managed object the indexer has just finished indexing.
 */
- (void)searchIndexer:(RKSearchIndexer *)searchIndexer didIndexManagedObject:(NSManagedObject *)managedObject;

///-----------------------------------------
/// @name Tracking Insertion of Search Words
///-----------------------------------------

/**
 Asks the delegate if the indexer should insert a new search word for a word that does not currently exist in the index.
 
 @param searchIndexer The search indexer object performing the indexing.
 @param word A search word that appears in an indexed object but does not yet exist in the index.
 @param managedObjectContext The managed object context in which indexing is taking place.
 @return `YES` if the indexer should insert an `RKSearchWord` object for the given word, else `NO`.
 */
- (BOOL)searchIndexer:(RKSearchIndexer *)searchIndexer shouldInsertSearchWordForWord:(NSString *)word inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

/**
 Tells the delegate that the indexer has inserted a new search word object for a word.
 
 @param searchIndexer The search indexer object performing the indexing.
 @param searchWord The search word that was inserted.
 @param word The word for which the search word object was created.
 @param managedObjectContext The managed object context in which indexing is taking place.
 */
- (void)searchIndexer:(RKSearchIndexer *)searchIndexer didInsertSearchWord:(RKSearchWord *)searchWord forWord:(NSString *)word inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

@end
