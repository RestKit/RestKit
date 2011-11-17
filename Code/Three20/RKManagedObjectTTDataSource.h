//
//  RKFetchedResultsTTDataSource.h
//  RestKit
//
//  Created by Jeff Arena on 3/24/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Three20/Three20.h>
#import "../RestKit.h"
#import "RKManagedObjectTTTableItem.h"


@protocol RKManagedObjectTTDataSourceDelegate

@optional

/**
 * Sent when editing completes for the tableView item that contains the
 * managedObject.  Use this method to perform the required action
 * (e.g. delete, edit, etc.) on the managedObject after tableView editing
 * completes.
 *
 * @optional
 */
- (void)commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forManagedObject:(NSManagedObject*)managedObject;

/**
 * Sent prior to performing action on remote object in response to edit completion.
 * As an example, you can use this delegate method to prevent the data source from sending
 * a DELETE for the managedObject modified as part of the tableView editing operation
 *
 * @optional
 */
- (BOOL)shouldUpdateManagedObject:(NSManagedObject*)managedObject;

/**
 * Sent after a RKManagedObjectTTTableItem is created to allow delegate
 * to customize the item (e.g. customize URL, etc.) prior to handing control
 * to the RKFetchedResultsTTDataSource
 *
 * @optional
 */
- (void)didCreateTableItem:(RKManagedObjectTTTableItem*)item;

/**
 * Sent prior to sending objectLoader to refresh the dataSource
 * from the network.  Default behavior is to send the objectLoader
 * if this delegate method is unimplemented.
 *
 * @optional
 */
- (BOOL)shouldSendObjectLoader:(RKObjectLoader*)objectLoader;

@end


@interface RKManagedObjectTTDataSource : TTTableViewDataSource <NSFetchedResultsControllerDelegate, RKObjectLoaderDelegate> {
	NSFetchedResultsController* _fetchedResultsController;
	NSMutableArray* _headerItems;
	NSMutableArray* _footerItems;
	TTTableItem* _emptyItem;
	NSMutableDictionary* _indexPathToItems;
	BOOL _showSectionIndexTitles;
    BOOL _allowSwipeToDelete;
	NSObject<RKManagedObjectTTDataSourceDelegate>* _delegate;
	NSString* _resourcePath;
	BOOL _isLoading;
	NSMutableArray* _modelDelegates;
	NSTimeInterval _refreshRate;
    BOOL _showingEmptyItemAtBeginUpdates;
}

/**
 * The NSFetchRequest, retrieved from RKManagedObjectCache, used to
 * create the fetchedResultsController powering the dataSource.
 */
@property (nonatomic, readonly) NSFetchRequest* fetchRequest;

/**
 * Whether to show section index titles for data in the dataSource
 */
@property (nonatomic, assign) BOOL showSectionIndexTitles;

/**
 * Whether to allow swipe to delete support for data in the dataSource
 * Defaults to NO.
 */
@property (nonatomic, assign) BOOL allowSwipeToDelete;

/**
 * Header TTTableItems appended to the top of section 0
 */
@property (nonatomic, readonly) NSArray* headerTableItems;

/**
 * Footer TTTableItems appended to the bottom of the dataSource's
 * last section
 */
@property (nonatomic, readonly) NSArray* footerTableItems;

/**
 * TTTableItem to display when fetchedResultsController returns
 * no fetchedObjects
 */
@property (nonatomic, retain) TTTableItem* emptyTableItem;

/**
 * RKManagedObjectTTDataSourceDelegate to notify of tableView edit events
 * and TTTableItem creation.
 */
@property (nonatomic, assign) NSObject<RKManagedObjectTTDataSourceDelegate>* delegate;

/**
 * The resourcePath used to create this dataSource
 */
@property (nonatomic, readonly) NSString* resourcePath;

/**
 * The rate at which this model should be refreshed after initial load.
 * Defaults to the value returned by + (NSTimeInterval)defaultRefreshRate.
 */
@property (nonatomic, assign) NSTimeInterval refreshRate;

/**
 * The NSDate object representing the last time this model was loaded.
 */
@property (nonatomic, readonly) NSDate* loadedTime;

/**
 * App-level default refreshRate used in determining when to refresh a given model
 * from the network.
 * Defaults to NSTimeIntervalSince1970, which essentially means all app models
 * will never refresh from the network.
 */
+ (NSTimeInterval)defaultRefreshRate;

/**
 * Set the app-level default refreshRate.
 */
+ (void)setDefaultRefreshRate:(NSTimeInterval)newDefaultRefreshRate;


- (id)initWithResourcePath:(NSString*)resourcePath;

- (id)initWithResourcePath:(NSString*)resourcePath
				 predicate:(NSPredicate*)predicate
		   sortDescriptors:(NSArray*)sortDescriptors;

- (id)initWithResourcePath:(NSString*)resourcePath
		sectionNameKeyPath:(NSString*)sectionNameKeyPath
				 cacheName:(NSString*)cacheName;

- (id)initWithResourcePath:(NSString*)resourcePath
				 predicate:(NSPredicate*)predicate
		   sortDescriptors:(NSArray*)sortDescriptors
		sectionNameKeyPath:(NSString*)sectionNameKeyPath
				 cacheName:(NSString*)cacheName;

- (void)changePredicateForFetchRequest:(NSPredicate*)predicate;

- (void)changeSortDescriptorsForFetchRequest:(NSArray*)sortDescriptors;

- (RKManagedObjectTTTableItem*)tableItemForManagedObject:(NSManagedObject*)object;

- (void)addHeaderTableItem:(TTTableItem*)tableItem;

- (void)removeHeaderTableItem:(TTTableItem*)tableItem;

- (void)removeHeaderTableItems;

- (void)replaceHeaderTableItem:(TTTableItem*)tableItem withTableItem:(TTTableItem*)newTableItem;

- (void)addFooterTableItem:(TTTableItem*)tableItem;

- (void)removeFooterTableItem:(TTTableItem*)tableItem;

- (void)removeFooterTableItems;

- (void)replaceFooterTableItem:(TTTableItem*)tableItem withTableItem:(TTTableItem*)newTableItem;

- (id<NSFetchedResultsSectionInfo>)sectionInfoForSection:(NSInteger)section;

- (NSManagedObject*)managedObjectForIndexPath:(NSIndexPath*)indexPath;

/**
 * Notifies delegates that the model started to load.
 */
- (void)didStartLoad;

/**
 * Notifies delegates that the model finished loading
 */
- (void)didFinishLoad;

/**
 * Notifies delegates that the model failed to load.
 */
- (void)didFailLoadWithError:(NSError*)error;

/**
 * Notifies delegates that the model canceled its load.
 */
- (void)didCancelLoad;

/**
 * Notifies delegates that the model has begun making multiple updates.
 */
- (void)beginUpdates;

/**
 * Notifies delegates that the model has completed its updates.
 */
- (void)endUpdates;

/**
 * Notifies delegates that an object was updated.
 */
- (void)didUpdateObject:(id)object atIndexPath:(NSIndexPath*)indexPath;

/**
 * Notifies delegates that an object was inserted.
 */
- (void)didInsertObject:(id)object atIndexPath:(NSIndexPath*)indexPath;

/**
 * Notifies delegates that an object was deleted.
 */
- (void)didDeleteObject:(id)object atIndexPath:(NSIndexPath*)indexPath;

/**
 * Notifies delegates that the model changed in some fundamental way.
 */
- (void)didChange;

@end
