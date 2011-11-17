//
//  RKManagedObjectTTDataSource.m
//  RestKit
//
//  Created by Jeff Arena on 3/24/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKManagedObjectTTDataSource.h"
#import "RKManagedObjectStore.h"
#import "RKManagedObjectMapping.h"
#import "NSManagedObject+ActiveRecord.h"
#import <Three20Core/NSArrayAdditions.h>
#import <objc/runtime.h>
#import "RKLog.h"

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitThree20


static NSTimeInterval defaultRefreshRate = NSTimeIntervalSince1970;

@interface RKManagedObjectTTDataSource (Private)

- (void)clearLoadedTime;
- (void)saveLoadedTime;
- (BOOL)isRKOfflineError:(NSError*)error;

@end


@implementation RKManagedObjectTTDataSource

@synthesize showSectionIndexTitles = _showSectionIndexTitles;
@synthesize headerTableItems = _headerItems;
@synthesize footerTableItems = _footerItems;
@synthesize emptyTableItem = _emptyItem;
@synthesize delegate = _delegate;
@synthesize refreshRate = _refreshRate;
@synthesize allowSwipeToDelete = _allowSwipeToDelete;

+ (NSTimeInterval)defaultRefreshRate {
	return defaultRefreshRate;
}

+ (void)setDefaultRefreshRate:(NSTimeInterval)newDefaultRefreshRate {
	defaultRefreshRate = newDefaultRefreshRate;
}

- (id)init {
    self = [super init];
	if (self) {
		_indexPathToItems = [[NSMutableDictionary alloc] init];
		_showSectionIndexTitles = NO;
        _allowSwipeToDelete = NO;
		_headerItems = [[NSMutableArray alloc] init];
		_footerItems = [[NSMutableArray alloc] init];
		_emptyItem = nil;
		_delegate = nil;
		_resourcePath = nil;
		_isLoading = NO;
		_refreshRate = defaultRefreshRate;
	}
	return self;
}

- (id)initWithResourcePath:(NSString*)resourcePath {
    self = [self initWithResourcePath:resourcePath
                            predicate:nil
                      sortDescriptors:nil
                   sectionNameKeyPath:nil
                            cacheName:nil];
	return self;
}

- (id)initWithResourcePath:(NSString*)resourcePath
				 predicate:(NSPredicate*)predicate
		   sortDescriptors:(NSArray*)sortDescriptors {

    self = [self initWithResourcePath:resourcePath
                            predicate:predicate
                      sortDescriptors:sortDescriptors
                   sectionNameKeyPath:nil
                            cacheName:nil];
	return self;
}

- (id)initWithResourcePath:(NSString*)resourcePath
		sectionNameKeyPath:(NSString*)sectionNameKeyPath
				 cacheName:(NSString*)cacheName {

    self = [self initWithResourcePath:resourcePath
                            predicate:nil
                      sortDescriptors:nil
                   sectionNameKeyPath:sectionNameKeyPath
                            cacheName:cacheName];
	return self;
}

- (id)initWithResourcePath:(NSString*)resourcePath
				 predicate:(NSPredicate*)predicate
		   sortDescriptors:(NSArray*)sortDescriptors
		sectionNameKeyPath:(NSString*)sectionNameKeyPath
				 cacheName:(NSString*)cacheName {

    self = [self init];
	if (self) {
		_resourcePath = [resourcePath copy];
		RKManagedObjectStore* store = [RKObjectManager sharedManager].objectStore;
		NSAssert(store.managedObjectCache != nil, @"Attempted to initialize RKManagedObjectTTDataSource with nil RKManageObjectCache");

		NSFetchRequest* cacheFetchRequest = [store.managedObjectCache fetchRequestForResourcePath:resourcePath];
		NSAssert(cacheFetchRequest != nil, @"Attempted to initialize RKManagedObjectTTDataSource with nil fetchRequest");

		if (predicate) {
			[cacheFetchRequest setPredicate:predicate];
		}
		if (sortDescriptors) {
			[cacheFetchRequest setSortDescriptors:sortDescriptors];
		}

		_showSectionIndexTitles = (sectionNameKeyPath != nil);
		_fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:cacheFetchRequest
																		managedObjectContext:[NSManagedObject managedObjectContext]
																		  sectionNameKeyPath:sectionNameKeyPath
																				   cacheName:cacheName];
		_fetchedResultsController.delegate = self;
	}
	return self;
}

- (void)dealloc {
	[self cancel];
	[_indexPathToItems release];
	_indexPathToItems = nil;
	_fetchedResultsController.delegate = nil;
	[_fetchedResultsController release];
	_fetchedResultsController = nil;
	[_headerItems release];
	_headerItems = nil;
	[_footerItems release];
	_footerItems = nil;
	[_resourcePath release];
	_resourcePath = nil;
	[_modelDelegates release];
	_modelDelegates = nil;
	self.emptyTableItem = nil;
	[super dealloc];
}


#pragma mark -
#pragma mark Public

- (NSFetchRequest*)fetchRequest {
	return _fetchedResultsController.fetchRequest;
}

- (NSString*)resourcePath {
	return _resourcePath;
}

- (void)changePredicateForFetchRequest:(NSPredicate*)predicate {
	[NSFetchedResultsController deleteCacheWithName:_fetchedResultsController.cacheName];
    [self beginUpdates];
    for (NSIndexPath* indexPath in _indexPathToItems) {
        id item = [_indexPathToItems objectForKey:indexPath];
        [self didDeleteObject:item atIndexPath:indexPath];
    }
	[_indexPathToItems removeAllObjects];

    // Delete all the sections
    for (NSUInteger section = 0; section < [_fetchedResultsController.sections count]; section++) {
        id<NSFetchedResultsSectionInfo> sectionInfo = [_fetchedResultsController.sections objectAtIndex:section];
        [self controller:_fetchedResultsController didChangeSection:sectionInfo atIndex:section forChangeType:NSFetchedResultsChangeDelete];
    }

    // TODO: Looks like we are not handling section inserts/deletes properly...
    NSLog(@"Section count before the performFetch: %d", [_fetchedResultsController.sections count]);

	NSError* error = nil;
    [_fetchedResultsController.fetchRequest setPredicate:predicate];
	BOOL success = [_fetchedResultsController performFetch:&error];
	if (!success) {
		RKLogError(@"performFetch failed with error: %@", [error localizedDescription]);
	}

    NSLog(@"Section count after the performFetch: %d", [_fetchedResultsController.sections count]);
    // Add the sections back

    for (NSUInteger section = 0; section < [_fetchedResultsController.sections count]; section++) {
        id<NSFetchedResultsSectionInfo> sectionInfo = [_fetchedResultsController.sections objectAtIndex:section];
        [self controller:_fetchedResultsController didChangeSection:sectionInfo atIndex:section forChangeType:NSFetchedResultsChangeInsert];
        for (id object in sectionInfo.objects) {
            NSUInteger row = [sectionInfo.objects indexOfObject:object];
            RKManagedObjectTTTableItem* item = [self tableItemForManagedObject:object];
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:row inSection:section];
            [_indexPathToItems setObject:item forKey:indexPath];
            [self didInsertObject:item atIndexPath:indexPath];
        }
    }

    // TODO: If there are no sections left we should have an empty state...

    [self endUpdates];
}

- (void)changeSortDescriptorsForFetchRequest:(NSArray*)sortDescriptors {
	[NSFetchedResultsController deleteCacheWithName:_fetchedResultsController.cacheName];
	[_indexPathToItems removeAllObjects];

	[_fetchedResultsController.fetchRequest setSortDescriptors:sortDescriptors];

	NSError* error;
	BOOL success = [_fetchedResultsController performFetch:&error];
	if (!success) {
		RKLogError(@"performFetch failed with error: %@", [error localizedDescription]);
	}
	[self didChange];
}

- (RKManagedObjectTTTableItem*)tableItemForManagedObject:(NSManagedObject*)object {
	RKManagedObjectTTTableItem* item = [RKManagedObjectTTTableItem itemWithManagedObject:object];

	if ([_delegate respondsToSelector:@selector(didCreateTableItem:)]) {
		[_delegate didCreateTableItem:item];
	}

	return item;
}

- (void)addHeaderTableItem:(TTTableItem*)tableItem {
	[_headerItems addObject:tableItem];

	NSIndexPath* headerIndexPath = [NSIndexPath indexPathForRow:([_headerItems count] - 1)
													  inSection:0];
	[self didInsertObject:tableItem
			  atIndexPath:headerIndexPath];
}

- (void)removeHeaderTableItem:(TTTableItem*)tableItem {
	NSUInteger index = [_headerItems indexOfObject:tableItem];
	if (index !=  NSNotFound) {
		[_headerItems removeObject:tableItem];

		NSIndexPath* headerIndexPath = [NSIndexPath indexPathForRow:index
														  inSection:0];
		[self didDeleteObject:tableItem
				  atIndexPath:headerIndexPath];
	}
}

- (void)removeHeaderTableItems {
	if ([_headerItems count] > 0) {
		[self beginUpdates];

		for (TTTableItem* item in _headerItems) {
			NSUInteger index = [_headerItems indexOfObject:item];
			NSIndexPath* headerIndexPath = [NSIndexPath indexPathForRow:index
															  inSection:0];
			[self didDeleteObject:item
					  atIndexPath:headerIndexPath];
		}
		[_headerItems removeAllObjects];

		[self endUpdates];
	}
}

- (void)replaceHeaderTableItem:(TTTableItem*)tableItem withTableItem:(TTTableItem*)newTableItem {
	NSUInteger index = [_headerItems indexOfObject:tableItem];
	if (index != NSNotFound) {
		[_headerItems removeObjectAtIndex:index];
		[_headerItems insertObject:newTableItem
						   atIndex:index];

		NSIndexPath* headerIndexPath = [NSIndexPath indexPathForRow:index
														  inSection:0];
		[self didUpdateObject:newTableItem
				  atIndexPath:headerIndexPath];
	}
}

- (void)addFooterTableItem:(TTTableItem*)tableItem {
	[_footerItems addObject:tableItem];
	NSUInteger section = [[_fetchedResultsController sections] count] - 1;
	id <NSFetchedResultsSectionInfo> sectionInfo = [[_fetchedResultsController sections] objectAtIndex:section];

	NSIndexPath* footerIndexPath = [NSIndexPath indexPathForRow:([sectionInfo numberOfObjects] + [_footerItems count] - 1)
													  inSection:section];
	[self didInsertObject:tableItem
			  atIndexPath:footerIndexPath];
}

- (void)removeFooterTableItem:(TTTableItem*)tableItem {
	NSUInteger index = [_footerItems indexOfObject:tableItem];
	if (index !=  NSNotFound) {
		[_footerItems removeObject:tableItem];

		NSUInteger section = [[_fetchedResultsController sections] count] - 1;
		id <NSFetchedResultsSectionInfo> sectionInfo = [[_fetchedResultsController sections] objectAtIndex:section];

		NSIndexPath* footerIndexPath = [NSIndexPath indexPathForRow:([sectionInfo numberOfObjects] + index)
														  inSection:section];
		[self didDeleteObject:tableItem
				  atIndexPath:footerIndexPath];
	}
}

- (void)removeFooterTableItems {
	if ([_footerItems count] > 0) {
		[self beginUpdates];

		for (TTTableItem* item in _footerItems) {
			NSUInteger index = [_footerItems indexOfObject:item];
			NSIndexPath* footerIndexPath = [NSIndexPath indexPathForRow:index
															  inSection:([[_fetchedResultsController sections] count] - 1)];
			[self didDeleteObject:item
					  atIndexPath:footerIndexPath];
		}
		[_footerItems removeAllObjects];

		[self endUpdates];
	}
}

- (void)replaceFooterTableItem:(TTTableItem*)tableItem withTableItem:(TTTableItem*)newTableItem {
	NSUInteger index = [_footerItems indexOfObject:tableItem];
	if (index != NSNotFound) {
		[_footerItems removeObjectAtIndex:index];
		[_footerItems insertObject:newTableItem
						   atIndex:index];

		NSUInteger section = [[_fetchedResultsController sections] count] - 1;
		id <NSFetchedResultsSectionInfo> sectionInfo = [[_fetchedResultsController sections] objectAtIndex:section];

		NSIndexPath* footerIndexPath = [NSIndexPath indexPathForRow:([sectionInfo numberOfObjects] + index)
														  inSection:section];
		[self didUpdateObject:newTableItem
				  atIndexPath:footerIndexPath];
	}
}

- (id<NSFetchedResultsSectionInfo>)sectionInfoForSection:(NSInteger)section {
	id <NSFetchedResultsSectionInfo> sectionInfo = [_fetchedResultsController.sections objectAtIndex:section];
	return sectionInfo;
}

- (NSManagedObject*)managedObjectForIndexPath:(NSIndexPath*)indexPath {
	id <NSFetchedResultsSectionInfo> sectionInfo = [[_fetchedResultsController sections] objectAtIndex:indexPath.section];
	NSIndexPath* adjIndexPath = [NSIndexPath indexPathForRow:indexPath.row
												   inSection:indexPath.section];

	if (indexPath.section == 0) {
		if ([sectionInfo numberOfObjects] == 0 && _emptyItem) {
			return nil;

		} else if ([_headerItems count] > 0) {

			if (indexPath.row < [_headerItems count]) {
				return nil;
			}
			adjIndexPath = [NSIndexPath indexPathForRow:(indexPath.row - [_headerItems count])
											  inSection:indexPath.section];
		}
	} else if (indexPath.section == ([[_fetchedResultsController sections] count] - 1) &&
			   [_footerItems count] > 0 && indexPath.row >= ([sectionInfo numberOfObjects] - 1)) {

		return nil;
	}

	return (NSManagedObject*)[_fetchedResultsController objectAtIndexPath:adjIndexPath];
}


#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView {
    RKLogTrace(@"numberOfSectionsInTableView: %d (%@)", [[_fetchedResultsController sections] count], [[_fetchedResultsController sections] valueForKey:@"name"]);
	return [[_fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[_fetchedResultsController sections] objectAtIndex:section];
	if (section == 0) {
		if ([sectionInfo numberOfObjects] == 0 && _emptyItem) {
			return 1;
		}
		return ([sectionInfo numberOfObjects] + [_headerItems count]);
	} else if (section == [[_fetchedResultsController sections] count] - 1) {
		return ([sectionInfo numberOfObjects] + [_footerItems count]);
	}
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath {
	id object = [self tableView:tableView objectForRowAtIndexPath:indexPath];

	Class cellClass = [self tableView:tableView cellClassForObject:object];
	const char* className = class_getName(cellClass);
	NSString* identifier = [[NSString alloc] initWithBytesNoCopy:(char*)className
														  length:strlen(className)
														encoding:NSASCIIStringEncoding
													freeWhenDone:NO];

	UITableViewCell* cell = (UITableViewCell*)[tableView dequeueReusableCellWithIdentifier:identifier];
	if (cell == nil) {
		cell = [[[cellClass alloc] initWithStyle:UITableViewCellStyleDefault
								 reuseIdentifier:identifier] autorelease];
	}
	[identifier release];

	if ([cell isKindOfClass:[TTTableViewCell class]]) {
		[(TTTableViewCell*)cell setObject:object];
	}

	[self tableView:tableView cell:cell willAppearAtIndexPath:indexPath];

	return cell;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[_fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo name];
}

- (NSArray*)sectionIndexTitlesForTableView:(UITableView*)tableView {
	if (tableView.style == UITableViewStylePlain && _showSectionIndexTitles) {
		return [_fetchedResultsController sectionIndexTitles];
	}
	return nil;
}

- (NSInteger)tableView:(UITableView*)tableView sectionForSectionIndexTitle:(NSString*)title atIndex:(NSInteger)index {
	if (tableView.style == UITableViewStylePlain && _showSectionIndexTitles) {
		return [_fetchedResultsController sectionForSectionIndexTitle:title atIndex:index];
	}
	return 0;
}

- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath*)indexPath {
    return _allowSwipeToDelete;
}

- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath {
	RKManagedObjectTTTableItem* item = (RKManagedObjectTTTableItem*)[self tableView:tableView objectForRowAtIndexPath:indexPath];
	NSManagedObject* managedObject = item.managedObject;

	if ([_delegate respondsToSelector:@selector(commitEditingStyle:forManagedObject:)]) {
		[_delegate commitEditingStyle:editingStyle forManagedObject:managedObject];
	}

	BOOL performDelete = YES;
	if ([_delegate respondsToSelector:@selector(shouldUpdateManagedObject:)]) {
		performDelete = [_delegate shouldUpdateManagedObject:managedObject];
	}

	if (_allowSwipeToDelete &&
        performDelete &&
        editingStyle == UITableViewCellEditingStyleDelete) {

		RKObjectMapping* mapping = [[RKObjectManager sharedManager].mappingProvider objectMappingForClass:[managedObject class]];
		if ([mapping isKindOfClass:[RKManagedObjectMapping class]]) {
			RKManagedObjectMapping* managedObjectMapping = (RKManagedObjectMapping*)mapping;
			NSString* primaryKeyAttribute = managedObjectMapping.primaryKeyAttribute;

			if ([managedObject valueForKeyPath:primaryKeyAttribute]) {
				[[RKObjectManager sharedManager] deleteObject:managedObject delegate:self];
			} else {
				[managedObject.managedObjectContext deleteObject:managedObject];
			}
			[_indexPathToItems removeObjectForKey:indexPath];
		}
	}
}


#pragma mark -
#pragma mark TTTableViewDataSource

- (id)tableView:(UITableView*)tableView objectForRowAtIndexPath:(NSIndexPath*)indexPath {
	id <NSFetchedResultsSectionInfo> sectionInfo = [[_fetchedResultsController sections] objectAtIndex:indexPath.section];
	NSIndexPath* adjIndexPath = [NSIndexPath indexPathForRow:indexPath.row
												   inSection:indexPath.section];

	if (indexPath.section == 0) {
		if ([sectionInfo numberOfObjects] == 0 && _emptyItem) {
			return _emptyItem;

		} else if ([_headerItems count] > 0) {

			if (indexPath.row < [_headerItems count]) {
				return [_headerItems objectAtIndex:indexPath.row];
			}
			adjIndexPath = [NSIndexPath indexPathForRow:(indexPath.row - [_headerItems count])
											  inSection:indexPath.section];
		}
	} else if (indexPath.section == ([[_fetchedResultsController sections] count] - 1) &&
			   [_footerItems count] > 0 && indexPath.row >= ([sectionInfo numberOfObjects] - 1)) {

		return [_footerItems objectAtIndex:(indexPath.row - [sectionInfo numberOfObjects])];
	}

	RKManagedObjectTTTableItem* item = [_indexPathToItems objectForKey:adjIndexPath];
	if (item == nil) {
		item = [self tableItemForManagedObject:[_fetchedResultsController objectAtIndexPath:adjIndexPath]];
		[_indexPathToItems setObject:item forKey:adjIndexPath];
	} else {
        // Ensure the table item is pointing at the correct managed object. If there has been an insert, the object indexes
        // may well have shifted
        item.managedObject = [_fetchedResultsController objectAtIndexPath:adjIndexPath];
    }
	return item;
}

- (NSIndexPath*)tableView:(UITableView*)tableView indexPathForObject:(id)object {
	/**
	 * TODO: We have indexPath issues here in cases of header/footer/empty items
	 */
	RKManagedObjectTTTableItem* item = (RKManagedObjectTTTableItem*)object;
	return [_fetchedResultsController indexPathForObject:item.managedObject];
}

- (NSIndexPath*)tableView:(UITableView*)tableView willUpdateObject:(id)object atIndexPath:(NSIndexPath*)indexPath {
	return indexPath;
}

- (NSIndexPath*)tableView:(UITableView*)tableView willInsertObject:(id)object atIndexPath:(NSIndexPath*)indexPath {
	return indexPath;
}

- (NSIndexPath*)tableView:(UITableView*)tableView willRemoveObject:(id)object atIndexPath:(NSIndexPath*)indexPath {
	return indexPath;
}

- (UIImage*)imageForError:(NSError*)error {
	if ([self isRKOfflineError:error]) {
		return nil;
	}
    return [super imageForError:error];
}

- (NSString*)titleForError:(NSError*)error {
	if ([self isRKOfflineError:error]) {
		return nil;
	}
	return [super titleForError:error];
}

- (NSString*)subtitleForError:(NSError*)error {
	if ([self isRKOfflineError:error]) {
		return nil;
	}
	return [super subtitleForError:error];
}


#pragma mark -
#pragma mark TTModel

- (NSMutableArray*)delegates {
	if (nil == _modelDelegates) {
		_modelDelegates = TTCreateNonRetainingArray();
	}
	return _modelDelegates;
}

- (BOOL)isLoaded {
	return (_fetchedResultsController.fetchedObjects != nil);
}

- (BOOL)isLoading {
	return _isLoading;
}

- (BOOL)isLoadingMore {
	return NO;
}

- (BOOL)isOutdated {
	NSTimeInterval sinceNow = [self.loadedTime timeIntervalSinceNow];
	return (![self isLoading] && ((sinceNow == 0.0) || (-sinceNow > _refreshRate)));
}

- (void)cancel {
	[[RKRequestQueue sharedQueue] cancelRequestsWithDelegate:self];
	_isLoading = NO;
	[self didCancelLoad];
}

- (void)invalidate:(BOOL)erase {
	[self clearLoadedTime];
}

- (void)load:(TTURLRequestCachePolicy)cachePolicy more:(BOOL)more {
	if (cachePolicy == TTURLRequestCachePolicyNetwork) {
		RKObjectLoader* objectLoader = [[RKObjectManager sharedManager] objectLoaderWithResourcePath:_resourcePath
																							delegate:self];
		objectLoader.backgroundPolicy = RKRequestBackgroundPolicyContinue;

		BOOL shouldSendObjectLoader = YES;
		if ([_delegate respondsToSelector:@selector(shouldSendObjectLoader:)]) {
			shouldSendObjectLoader = [_delegate shouldSendObjectLoader:objectLoader];
		}

		if (shouldSendObjectLoader) {
			_isLoading = YES;
			[self didStartLoad];
			[objectLoader send];
		}
	} else {
		_isLoading = YES;
		[self didStartLoad];

		NSError* error;
		BOOL success = [_fetchedResultsController performFetch:&error];
		if (!success) {
			RKLogError(@"performFetch failed with error: %@", [error localizedDescription]);
			_isLoading = NO;
			[self didFailLoadWithError:error];
		} else {
			_isLoading = NO;
			[self didFinishLoad];
		}
	}
}

- (NSDate*)loadedTime {
	return [[NSUserDefaults standardUserDefaults] objectForKey:_resourcePath];
}

- (void)didStartLoad {
	[_modelDelegates perform:@selector(modelDidStartLoad:)
				  withObject:self];
}

- (void)didFinishLoad {
	[_modelDelegates perform:@selector(modelDidFinishLoad:)
				  withObject:self];
}

- (void)didFailLoadWithError:(NSError*)error {
	[_modelDelegates perform:@selector(model:didFailLoadWithError:)
				  withObject:self
				  withObject:error];
}

- (void)didCancelLoad {
	[_modelDelegates perform:@selector(modelDidCancelLoad:)
				  withObject:self];
}

- (void)beginUpdates {
	[_modelDelegates perform:@selector(modelDidBeginUpdates:)
				  withObject:self];
}

- (void)endUpdates {
	[_modelDelegates perform:@selector(modelDidEndUpdates:)
				  withObject:self];
}

- (void)didUpdateObject:(id)object atIndexPath:(NSIndexPath*)indexPath {
	[_modelDelegates perform:@selector(model:didUpdateObject:atIndexPath:)
				  withObject:self
				  withObject:object
				  withObject:indexPath];
}

- (void)didInsertObject:(id)object atIndexPath:(NSIndexPath*)indexPath {
	[_modelDelegates perform:@selector(model:didInsertObject:atIndexPath:)
				  withObject:self
				  withObject:object
				  withObject:indexPath];
}

- (void)didDeleteObject:(id)object atIndexPath:(NSIndexPath*)indexPath {
	[_modelDelegates perform:@selector(model:didDeleteObject:atIndexPath:)
				  withObject:self
				  withObject:object
				  withObject:indexPath];
}

- (void)didChange {
	[_modelDelegates perform:@selector(modelDidChange:)
				  withObject:self];
}

#pragma mark -
#pragma mark NSFetchedResultsControllerDelegate

- (BOOL)shouldShowEmptyItem {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[_fetchedResultsController sections] objectAtIndex:0];
    RKLogTrace(@"Determining if the empty item should be shown. Section 0: numberOfObjects = %d. Empty item = %@", [sectionInfo numberOfObjects], _emptyItem);
	return ([sectionInfo numberOfObjects] == 0 && _emptyItem);
}

- (void)controllerWillChangeContent:(NSFetchedResultsController*)controller {
    RKLogTrace(@"Beginning updates for fetchedResultsController. Current section count = %d (resource path: %@)", [[controller sections] count], _resourcePath);
    _showingEmptyItemAtBeginUpdates = [self shouldShowEmptyItem];
	[self beginUpdates];
}

- (void)controller:(NSFetchedResultsController*)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo
		   atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {

	switch (type) {
		case NSFetchedResultsChangeInsert:
            if (sectionIndex == 0) {
                RKLogTrace(@"Skipping insert for section 0 as it always exists... ");
            } else {
                [self didInsertObject:nil
                          atIndexPath:[NSIndexPath indexPathWithIndex:sectionIndex]];
            }
			break;

		case NSFetchedResultsChangeDelete:
            [self didDeleteObject:nil
                      atIndexPath:[NSIndexPath indexPathWithIndex:sectionIndex]];
			break;

		default:
			RKLogTrace(@"Encountered unexpected section changeType: %d", type);
			break;
	}
}

- (void)controller:(NSFetchedResultsController*)controller didChangeObject:(id)anObject
	   atIndexPath:(NSIndexPath*)indexPath forChangeType:(NSFetchedResultsChangeType)type
	  newIndexPath:(NSIndexPath*)newIndexPath {

	NSIndexPath* adjIndexPath = [NSIndexPath indexPathForRow:indexPath.row
												   inSection:indexPath.section];
	NSIndexPath* adjNewIndexPath = [NSIndexPath indexPathForRow:newIndexPath.row
													  inSection:newIndexPath.section];

	if ([_headerItems count] > 0 && indexPath.section == 0) {
		adjIndexPath = [NSIndexPath indexPathForRow:(indexPath.row + [_headerItems count])
										  inSection:indexPath.section];
		adjNewIndexPath = [NSIndexPath indexPathForRow:(newIndexPath.row + [_headerItems count])
													inSection:newIndexPath.section];
	}

	switch(type) {
		case NSFetchedResultsChangeInsert:
			[self didInsertObject:anObject atIndexPath:adjNewIndexPath];
			break;

		case NSFetchedResultsChangeDelete:
			[self didDeleteObject:anObject atIndexPath:adjIndexPath];
			break;

		case NSFetchedResultsChangeUpdate:
			[self didUpdateObject:anObject atIndexPath:adjIndexPath];
			break;

		case NSFetchedResultsChangeMove:
			[self didDeleteObject:anObject atIndexPath:adjIndexPath];
			[self didInsertObject:anObject atIndexPath:adjNewIndexPath];
			break;

		default:
			RKLogTrace(@"Encountered unexpected object changeType: %d", type);
			break;

	}
}

- (NSIndexPath*)indexPathForEmptyItem {
	if ([_headerItems count] > 0) {
		return [NSIndexPath indexPathForRow:(0 + [_headerItems count])
                                  inSection:0];
	}

    return [NSIndexPath indexPathForRow:0 inSection:0];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController*)controller {
    if (_showingEmptyItemAtBeginUpdates && ![self shouldShowEmptyItem]) {
        // We were showing an empty item at the start but shouldn't any more, let's delete the item
        [self didDeleteObject:nil atIndexPath:[self indexPathForEmptyItem]];
    } else if (!_showingEmptyItemAtBeginUpdates && [self shouldShowEmptyItem]) {
        [self didInsertObject:nil atIndexPath:[self indexPathForEmptyItem]];
    }

    RKLogTrace(@"Ending updates for fetchedResultsController. New section count = %d (resource path: %@)", [[controller sections] count], _resourcePath);
	[self endUpdates];
}

#pragma mark -
#pragma mark RKObjectLoaderDelegate

- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObjects:(NSArray*)objects {
	if ([objectLoader isGET]) {
		[self saveLoadedTime];

	} else if ([objectLoader isDELETE] && [objectLoader.targetObject isKindOfClass:[NSManagedObject class]]) {
		NSManagedObject* managedObject = (NSManagedObject*)objectLoader.targetObject;
		[managedObject.managedObjectContext deleteObject:managedObject];
	}
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error {
	if ([objectLoader isGET]) {
		_isLoading = NO;
		[self didFailLoadWithError:error];
	}
	RKLogDebug(@"Model Loader Request failed with error: %@", [error localizedDescription]);
}

- (void)objectLoaderDidLoadUnexpectedResponse:(RKObjectLoader*)objectLoader {
	if ([objectLoader isGET]) {
		_isLoading = NO;

		// TODO: pass error message?
		NSError* error = [NSError errorWithDomain:RKErrorDomain code:RKRequestUnexpectedResponseError userInfo:nil];
		[self didFailLoadWithError:error];
	}
	RKLogDebug(@"Model Loader Request failed with unexpected error");
}

- (void)objectLoaderDidFinishLoading:(RKObjectLoader*)objectLoader {
    if ([objectLoader isGET]) {
        _isLoading = NO;
		[self didFinishLoad];
    }
    RKLogDebug(@"Model Loader Request finished successfully");
}

#pragma mark -
#pragma mark RKRequestManagedObjectTTDataSource (Private)

- (void)clearLoadedTime {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:_resourcePath];
}

- (void)saveLoadedTime {
	[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:_resourcePath];
}

- (BOOL)isRKOfflineError:(NSError*)error {
	return ([[error domain] isEqualToString:RKErrorDomain] && [error code] == RKRequestBaseURLOfflineError);
}

@end
