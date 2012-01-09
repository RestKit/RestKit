//
//  RKFetchedResultsTableController.m
//  RestKit
//
//  Created by Blake Watters on 8/2/11.
//  Copyright (c) 2011 RestKit.
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
#import "RKFetchedResultsTableController.h"
#import "RKAbstractTableController_Internals.h"
#import "RKManagedObjectStore.h"
#import "NSManagedObject+ActiveRecord.h"
#import "RKObjectMappingOperation.h"
#import "RKManagedObjectMapping.h"
#import "../Support/RKLog.h"

// Define logging component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitUI

@interface RKFetchedResultsTableController ()
- (void)performFetch;
@end

@implementation RKFetchedResultsTableController

@synthesize fetchedResultsController = _fetchedResultsController;
@synthesize resourcePath = _resourcePath;
@synthesize heightForHeaderInSection = _heightForHeaderInSection;
@synthesize onViewForHeaderInSection = _onViewForHeaderInSection;
@synthesize predicate = _predicate;
@synthesize sortDescriptors = _sortDescriptors;
@synthesize sectionNameKeyPath = _sectionNameKeyPath;
@synthesize cacheName = _cacheName;
@synthesize showsSectionIndexTitles = _showsSectionIndexTitles;
@synthesize sortSelector = _sortSelector;
@synthesize sortComparator = _sortComparator;

- (void)dealloc {
	_fetchedResultsController.delegate = nil;
	[_fetchedResultsController release];
	_fetchedResultsController = nil;
    [_resourcePath release];
    _resourcePath = nil;
    [_predicate release];
    _predicate = nil;
    [_sortDescriptors release];
    _sortDescriptors = nil;
    [_sectionNameKeyPath release];
    _sectionNameKeyPath = nil;
    [_cacheName release];
    _cacheName = nil;
    [_arraySortedFetchedObjects release];
    _arraySortedFetchedObjects = nil;
    Block_release(_onViewForHeaderInSection);
    Block_release(_sortComparator);
    [super dealloc];
}

#pragma mark - Helpers

- (void)performFetch {
    // TODO: We could be doing a KVO on the predicate/sortDescriptors/sectionKeyPath and intelligently deleting the cache
    [NSFetchedResultsController deleteCacheWithName:_fetchedResultsController.cacheName];
    
    NSError* error;
    BOOL success = [_fetchedResultsController performFetch:&error];
    if (!success) {
        self.error = error;
        RKLogError(@"performFetch failed with error: %@", [error localizedDescription]);
    } else {
        RKLogTrace(@"performFetch completed successfully");
    }
}

- (BOOL)isHeaderSection:(NSUInteger)section {
    return (section == 0);
}

- (BOOL)isHeaderRow:(NSUInteger)row {
    BOOL isHeaderRow = NO;
    NSUInteger headerItemCount = [self.headerItems count];
    if ([self isEmpty] && self.emptyItem) {
        isHeaderRow = (row > 0 && row <= headerItemCount);
    } else {
        isHeaderRow = (row < headerItemCount);
    }
    return isHeaderRow;
}

- (BOOL)isFooterSection:(NSUInteger)section {
    return (section == ([self sectionCount] - 1));
}

- (BOOL)isFooterRow:(NSUInteger)row {
    NSUInteger sectionIndex = ([self sectionCount] - 1);
    id <NSFetchedResultsSectionInfo> sectionInfo = [[_fetchedResultsController sections] objectAtIndex:sectionIndex];
    NSUInteger nonFooterRowCount = [sectionInfo numberOfObjects];
    if (sectionIndex == 0) {
        nonFooterRowCount += (![self isEmpty] || self.showsHeaderRowsWhenEmpty) ? [self.headerItems count] : 0;
        nonFooterRowCount += ([self isEmpty] && self.emptyItem) ? 1 : 0;
    }
    return (row > (nonFooterRowCount - 1));
}

- (BOOL)isHeaderIndexPath:(NSIndexPath *)indexPath {
    return ((! [self isEmpty] || self.showsHeaderRowsWhenEmpty) &&
            [self.headerItems count] > 0 &&
            [self isHeaderSection:indexPath.section] &&
            [self isHeaderRow:indexPath.row]);
}

- (BOOL)isFooterIndexPath:(NSIndexPath *)indexPath {
    return ((! [self isEmpty] || self.showsFooterRowsWhenEmpty) &&
            [self.footerItems count] > 0 &&
            [self isFooterSection:indexPath.section] &&
            [self isFooterRow:indexPath.row]);
}

- (BOOL)isEmptySection:(NSUInteger)section {
    return (section == 0);
}

- (BOOL)isEmptyRow:(NSUInteger)row {
    return (row == 0);
}

- (BOOL)isEmptyItemIndexPath:(NSIndexPath *)indexPath {
    return ([self isEmpty] && self.emptyItem &&
            [self isEmptySection:indexPath.section] &&
            [self isEmptyRow:indexPath.row]);
}

- (NSIndexPath *)emptyItemIndexPath {
    return [NSIndexPath indexPathForRow:0 inSection:0];
}

- (NSIndexPath *)fetchedResultsIndexPathForIndexPath:(NSIndexPath *)indexPath {
    if (([self isEmpty] && self.emptyItem &&
         [self isEmptySection:indexPath.section] &&
         ! [self isEmptyRow:indexPath.row]) ||
        ((! [self isEmpty] || self.showsHeaderRowsWhenEmpty) &&
         [self.headerItems count] > 0 &&
        [self isHeaderSection:indexPath.section] &&
        ! [self isHeaderRow:indexPath.row])) {
            NSUInteger adjustedRowIndex = indexPath.row;
            if (![self isEmpty] || self.showsHeaderRowsWhenEmpty) {
                adjustedRowIndex -= [self.headerItems count];
            }
            adjustedRowIndex -= ([self isEmpty] && self.emptyItem) ? 1 : 0;
            return [NSIndexPath indexPathForRow:adjustedRowIndex
                                  inSection:indexPath.section];
    }
    return indexPath;
}

- (NSIndexPath *)indexPathForFetchedResultsIndexPath:(NSIndexPath *)indexPath {
    if (([self isEmpty] && self.emptyItem &&
         [self isEmptySection:indexPath.section] &&
         ! [self isEmptyRow:indexPath.row]) ||
        ((! [self isEmpty] || self.showsHeaderRowsWhenEmpty) &&
         [self.headerItems count] > 0 &&
         [self isHeaderSection:indexPath.section])) {
            NSUInteger adjustedRowIndex = indexPath.row;
            if (![self isEmpty] || self.showsHeaderRowsWhenEmpty) {
                adjustedRowIndex += [self.headerItems count];
            }
            adjustedRowIndex += ([self isEmpty] && self.emptyItem) ? 1 : 0;
            return [NSIndexPath indexPathForRow:adjustedRowIndex
                                      inSection:indexPath.section];
    }
    return indexPath;
}

#pragma mark - Public

- (NSFetchRequest*)fetchRequest {
	return _fetchedResultsController.fetchRequest;
}

- (void)loadTable {
    RKManagedObjectStore* store = [RKObjectManager sharedManager].objectStore;
    NSAssert(store.managedObjectCache != nil, @"Attempted to load RKFetchedResultsTableController with nil RKManageObjectCache");

    NSFetchRequest* cacheFetchRequest = [store.managedObjectCache fetchRequestForResourcePath:_resourcePath];
    NSAssert(cacheFetchRequest != nil, @"Attempted to load RKFetchedResultsTableController with nil fetchRequest for resourcePath %@", _resourcePath);

    if (_predicate) {
        [cacheFetchRequest setPredicate:_predicate];
    }
    if (_sortDescriptors) {
        [cacheFetchRequest setSortDescriptors:_sortDescriptors];
    }

    [_fetchedResultsController setDelegate:nil];
    [_fetchedResultsController release];
    _fetchedResultsController = nil;

    _fetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:cacheFetchRequest
                                        managedObjectContext:[NSManagedObject managedObjectContext]
                                          sectionNameKeyPath:_sectionNameKeyPath
                                                   cacheName:_cacheName];
    _fetchedResultsController.delegate = self;

    [self performFetch];

    [_arraySortedFetchedObjects release];
    _arraySortedFetchedObjects = nil;

    if (_sortSelector || _sortComparator) {
        if (_sortSelector) {
            _arraySortedFetchedObjects = [[_fetchedResultsController.fetchedObjects sortedArrayUsingSelector:_sortSelector] retain];
        } else if (_sortComparator) {
            _arraySortedFetchedObjects = [[_fetchedResultsController.fetchedObjects sortedArrayUsingComparator:_sortComparator] retain];
        }
    }

    [self.tableView reloadData];
    [self didFinishLoad];
    
    if ([self isAutoRefreshNeeded] && [self isOnline] &&
        ![self.objectLoader isLoading] &&
        ![self.objectLoader.queue containsRequest:self.objectLoader]) {
        [self performSelector:@selector(loadTableFromNetwork) withObject:nil afterDelay:0];
    }
}

- (void)setSortSelector:(SEL)sortSelector {
    NSAssert(_sectionNameKeyPath == nil, @"Attempted to sort fetchedObjects across multiple sections");
    NSAssert(_sortComparator == nil, @"Attempted to sort fetchedObjects with a sortSelector when a sortComparator already exists");
    _sortSelector = sortSelector;
}

- (void)setSortComparator:(NSComparator)sortComparator {
    NSAssert(_sectionNameKeyPath == nil, @"Attempted to sort fetchedObjects across multiple sections");
    NSAssert(_sortSelector == nil, @"Attempted to sort fetchedObjects with a sortComparator when a sortSelector already exists");
    if (_sortComparator) {
        Block_release(_sortComparator);
        _sortComparator = nil;
    }
    _sortComparator = Block_copy(sortComparator);
}

- (void)setSectionNameKeyPath:(NSString*)sectionNameKeyPath {
    NSAssert(_sortSelector == nil, @"Attempted to create a sectioned fetchedResultsController when a sortSelector is present");
    NSAssert(_sortComparator == nil, @"Attempted to create a sectioned fetchedResultsController when a sortComparator is present");
    [sectionNameKeyPath retain];
    [_sectionNameKeyPath release];
    _sectionNameKeyPath = sectionNameKeyPath;
}

- (void)setResourcePath:(NSString*)resourcePath {
    [_resourcePath release];
    _resourcePath = [resourcePath copy];
    self.objectLoader = [self.objectManager objectLoaderWithResourcePath:_resourcePath delegate:self];
}

- (void)setObjectMappingForClass:(Class)objectClass {
    NSParameterAssert(objectClass != NULL);
    NSAssert(self.objectLoader != NULL, @"Resource path (and thus object loader) must be set before setting object mapping.");
    NSAssert(self.objectManager != NULL, @"Object manager must exist before setting object mapping.");
	self.objectLoader.objectMapping = [self.objectManager.mappingProvider objectMappingForClass:objectClass];
}

#pragma mark - Managing Sections

- (NSUInteger)sectionCount {
	return [[_fetchedResultsController sections] count];
}

- (NSUInteger)rowCount {
    NSUInteger fetchedItemCount = [[_fetchedResultsController fetchedObjects] count];
    NSUInteger nonFetchedItemCount = 0;
    if (fetchedItemCount == 0) {
        nonFetchedItemCount += self.emptyItem ? 1 : 0;
        nonFetchedItemCount += self.showsHeaderRowsWhenEmpty ? [self.headerItems count] : 0;
        nonFetchedItemCount += self.showsFooterRowsWhenEmpty ? [self.footerItems count] : 0;
    } else {
        nonFetchedItemCount += [self.headerItems count];
        nonFetchedItemCount += [self.footerItems count];
    }
    return (fetchedItemCount + nonFetchedItemCount);
}

- (UITableViewCell *)cellForObjectAtIndexPath:(NSIndexPath *)indexPath {
    id mappableObject = [self objectForRowAtIndexPath:indexPath];
    NSAssert(mappableObject, @"Cannot build a tableView cell without an object");

    RKTableViewCellMapping* cellMapping = [self.cellMappings cellMappingForObject:mappableObject];
    NSAssert(cellMapping, @"Cannot build a tableView cell for object %@: No cell mapping defined for objects of type '%@'", mappableObject, NSStringFromClass([mappableObject class]));

    UITableViewCell* cell = [cellMapping mappableObjectForData:self.tableView];
    NSAssert(cell, @"Cell mapping failed to dequeue or allocatate a tableViewCell for object: %@", mappableObject);
    RKObjectMappingOperation* mappingOperation = [[RKObjectMappingOperation alloc] initWithSourceObject:mappableObject destinationObject:cell mapping:cellMapping];
    NSError* error = nil;
    BOOL success = [mappingOperation performMapping:&error];
    [mappingOperation release];
    // NOTE: If there is no mapping work performed, but no error is generated then
    // we consider the operation a success. It is common for table cells to not contain
    // any dynamically mappable content (i.e. header/footer rows, banners, etc.)
    if (success == NO && error != nil) {
        RKLogError(@"Failed to generate table cell for object: %@", error);
        return nil;
    }

    return cell;
}

- (NSIndexPath *)indexPathForObject:(id)object {
    if ([object isKindOfClass:[NSManagedObject class]]) {
        return [_fetchedResultsController indexPathForObject:object];
    }
    return nil;
}

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView*)theTableView {
    NSAssert(theTableView == self.tableView, @"numberOfSectionsInTableView: invoked with inappropriate tableView: %@", theTableView);
    RKLogTrace(@"numberOfSectionsInTableView: %d (%@)", [[_fetchedResultsController sections] count], [[_fetchedResultsController sections] valueForKey:@"name"]);
	return [[_fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView*)theTableView numberOfRowsInSection:(NSInteger)section {
    NSAssert(theTableView == self.tableView, @"tableView:numberOfRowsInSection: invoked with inappropriate tableView: %@", theTableView);
    RKLogTrace(@"%@ numberOfRowsInSection:%d = %d", self, section, self.sectionCount);
    id <NSFetchedResultsSectionInfo> sectionInfo = [[_fetchedResultsController sections] objectAtIndex:section];
    NSUInteger numberOfRows = [sectionInfo numberOfObjects];

    if ([self isHeaderSection:section]) {
        numberOfRows += (![self isEmpty] || self.showsHeaderRowsWhenEmpty) ? [self.headerItems count] : 0;
        numberOfRows += ([self isEmpty] && self.emptyItem) ? 1 : 0;

    } else if ([self isFooterSection:section]) {
        numberOfRows += [self.footerItems count];
    }
    return numberOfRows;
}

- (NSString*)tableView:(UITableView*)theTableView titleForHeaderInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[_fetchedResultsController sections] objectAtIndex:section];
    return [sectionInfo name];
}

- (NSString*)tableView:(UITableView*)theTableView titleForFooterInSection:(NSInteger)section {
    NSAssert(theTableView == self.tableView, @"tableView:titleForFooterInSection: invoked with inappropriate tableView: %@", theTableView);
    return nil;
}

- (NSArray*)sectionIndexTitlesForTableView:(UITableView*)theTableView {
	if (theTableView.style == UITableViewStylePlain && self.showsSectionIndexTitles) {
		return [_fetchedResultsController sectionIndexTitles];
	}
	return nil;
}

- (NSInteger)tableView:(UITableView*)theTableView sectionForSectionIndexTitle:(NSString*)title atIndex:(NSInteger)index {
	if (theTableView.style == UITableViewStylePlain && self.showsSectionIndexTitles) {
		return [_fetchedResultsController sectionForSectionIndexTitle:title atIndex:index];
	}
	return 0;
}

- (void)tableView:(UITableView*)theTableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSAssert(theTableView == self.tableView, @"tableView:commitEditingStyle:forRowAtIndexPath: invoked with inappropriate tableView: %@", theTableView);
	if (self.canEditRows && editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObject* managedObject = [self objectForRowAtIndexPath:indexPath];
		RKObjectMapping* mapping = [[RKObjectManager sharedManager].mappingProvider objectMappingForClass:[managedObject class]];
		if ([mapping isKindOfClass:[RKManagedObjectMapping class]]) {
			RKManagedObjectMapping* managedObjectMapping = (RKManagedObjectMapping*)mapping;
			NSString* primaryKeyAttribute = managedObjectMapping.primaryKeyAttribute;

			if ([managedObject valueForKeyPath:primaryKeyAttribute]) {
                RKLogTrace(@"About to fire a delete request for managedObject: %@", managedObject);
				[[RKObjectManager sharedManager] deleteObject:managedObject delegate:self];
			} else {
                RKLogTrace(@"About to locally delete managedObject: %@", managedObject);
				[managedObject.managedObjectContext deleteObject:managedObject];

                NSError* error = nil;
                [managedObject.managedObjectContext save:&error];
                if (error) {
                    RKLogError(@"Failed to save managedObjectContext after a delete with error: %@", error);
                }
			}
		}
	}
}

- (void)tableView:(UITableView*)theTableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destIndexPath {
    NSAssert(theTableView == self.tableView, @"tableView:moveRowAtIndexPath:toIndexPath: invoked with inappropriate tableView: %@", theTableView);
}

- (BOOL)tableView:(UITableView*)theTableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    NSAssert(theTableView == self.tableView, @"tableView:canEditRowAtIndexPath: invoked with inappropriate tableView: %@", theTableView);
    return self.canEditRows && [self isOnline] && !([self isHeaderIndexPath:indexPath] || [self isFooterIndexPath:indexPath] || [self isEmptyItemIndexPath:indexPath]);
}

- (BOOL)tableView:(UITableView*)theTableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    NSAssert(theTableView == self.tableView, @"tableView:canMoveRowAtIndexPath: invoked with inappropriate tableView: %@", theTableView);
    return self.canMoveRows && !([self isHeaderIndexPath:indexPath] || [self isFooterIndexPath:indexPath] || [self isEmptyItemIndexPath:indexPath]);
}

#pragma mark - UITableViewDelegate methods

- (CGFloat)tableView:(UITableView*)theTableView heightForHeaderInSection:(NSInteger)section {
    NSAssert(theTableView == self.tableView, @"heightForHeaderInSection: invoked with inappropriate tableView: %@", theTableView);
    return _heightForHeaderInSection;
}

- (CGFloat)tableView:(UITableView*)theTableView heightForFooterInSection:(NSInteger)sectionIndex {
    NSAssert(theTableView == self.tableView, @"heightForFooterInSection: invoked with inappropriate tableView: %@", theTableView);
    return 0;
}

- (UIView*)tableView:(UITableView*)theTableView viewForHeaderInSection:(NSInteger)section {
    NSAssert(theTableView == self.tableView, @"viewForHeaderInSection: invoked with inappropriate tableView: %@", theTableView);
    if (_onViewForHeaderInSection) {
        NSString* sectionTitle = [self tableView:self.tableView titleForHeaderInSection:section];
        if (sectionTitle) {
            return _onViewForHeaderInSection(section, sectionTitle);
        }
    }
    return nil;
}

- (UIView*)tableView:(UITableView*)theTableView viewForFooterInSection:(NSInteger)sectionIndex {
    NSAssert(theTableView == self.tableView, @"viewForFooterInSection: invoked with inappropriate tableView: %@", theTableView);
    return nil;
}

#pragma mark - Cell Mappings

- (id)objectForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isEmptyItemIndexPath:indexPath]) {
        return self.emptyItem;

    } else if ([self isHeaderIndexPath:indexPath]) {
        NSUInteger row = (self.empty && self.emptyItem) ? (indexPath.row - 1) : indexPath.row;
        return [self.headerItems objectAtIndex:row];

    } else if ([self isFooterIndexPath:indexPath]) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[_fetchedResultsController sections] objectAtIndex:indexPath.section];
        NSUInteger footerRow = (indexPath.row - sectionInfo.numberOfObjects);
        if (indexPath.section == 0) {
            footerRow -= (![self isEmpty] || self.showsHeaderRowsWhenEmpty) ? [self.headerItems count] : 0;
            footerRow -= ([self isEmpty] && self.emptyItem) ? 1 : 0;
        }
        return [self.footerItems objectAtIndex:footerRow];

    } else if (_sortSelector || _sortComparator) {
        return [_arraySortedFetchedObjects objectAtIndex:[self fetchedResultsIndexPathForIndexPath:indexPath].row];
    }
    return [_fetchedResultsController objectAtIndexPath:[self fetchedResultsIndexPathForIndexPath:indexPath]];
}

#pragma mark - Network Table Loading

- (void)loadTableFromNetwork {
    NSAssert(self.objectManager, @"Cannot perform a network load without an object manager");
    NSAssert(self.objectLoader, @"Cannot perform a network load when a network load is already in-progress");
    RKLogTrace(@"About to loadTableWithObjectLoader...");
    [self loadTableWithObjectLoader:self.objectLoader];
}

#pragma mark - KVO & Model States

- (BOOL)isEmpty {
    NSUInteger fetchedObjectsCount = [[_fetchedResultsController fetchedObjects] count];
    BOOL isEmpty = (fetchedObjectsCount == 0);
    RKLogTrace(@"Determined isEmpty = %@. fetchedObjects count = %d", isEmpty ? @"YES" : @"NO", fetchedObjectsCount);
    return isEmpty;
}

#pragma mark - NSFetchedResultsControllerDelegate methods

- (void)controllerWillChangeContent:(NSFetchedResultsController*)controller {
    RKLogTrace(@"Beginning updates for fetchedResultsController (%@). Current section count = %d (resource path: %@)", controller, [[controller sections] count], _resourcePath);
    [self.tableView beginUpdates];
    _isEmptyBeforeAnimation = [self isEmpty];
}

- (void)controller:(NSFetchedResultsController*)controller
  didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo
		   atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type {

	switch (type) {
		case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
			break;

		case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
			break;

		default:
			RKLogTrace(@"Encountered unexpected section changeType: %d", type);
			break;
	}
}

- (void)controller:(NSFetchedResultsController*)controller
   didChangeObject:(id)anObject
	   atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
	  newIndexPath:(NSIndexPath *)newIndexPath {

    NSIndexPath* adjIndexPath = [self indexPathForFetchedResultsIndexPath:indexPath];
    NSIndexPath* adjNewIndexPath = [self indexPathForFetchedResultsIndexPath:newIndexPath];

    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:adjNewIndexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:adjIndexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeUpdate:
            /**
             TODO: Missing a call to a replacement for configureCell:atIndexPath: which updates
             the contents of a given cell with the information from a managed object
             at a given index path in the fetched results controller
             */
            break;

        case NSFetchedResultsChangeMove:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:adjIndexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:adjNewIndexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];
            break;

		default:
			RKLogTrace(@"Encountered unexpected object changeType: %d", type);
			break;
	}
}

- (void)controllerDidChangeContent:(NSFetchedResultsController*)controller {
    RKLogTrace(@"Ending updates for fetchedResultsController (%@). New section count = %d (resource path: %@)",
               controller, [[controller sections] count], _resourcePath);
    if (self.emptyItem && ![self isEmpty] && _isEmptyBeforeAnimation) {
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[self emptyItemIndexPath]]
                                                       withRowAnimation:UITableViewRowAnimationFade];
    }
	[self.tableView endUpdates];    
    [self didFinishLoad];
}

#pragma mark - Block setters

// NOTE: We get crashes when relying on just the copy property. Using Block_copy ensures
// correct behavior
- (void)setOnViewForHeaderInSection:(RKFetchedResultsTableViewViewForHeaderInSectionBlock)onViewForHeaderInSection {
    if (_onViewForHeaderInSection) {
        Block_release(_onViewForHeaderInSection);
        _onViewForHeaderInSection = nil;
    }
    _onViewForHeaderInSection = Block_copy(onViewForHeaderInSection);
}

@end
