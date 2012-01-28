//
//  RKAbstractTableController.m
//  RestKit
//
//  Created by Jeff Arena on 8/11/11.
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

#import "RKAbstractTableController.h"
#import "RKAbstractTableController_Internals.h"
#import "../ObjectMapping/RKObjectMappingOperation.h"
#import "../Support/RKLog.h"
#import "../Support/RKError.h"
#import "../Network/RKReachabilityObserver.h"
#import "UIView+FindFirstResponder.h"
#import "RKRefreshGestureRecognizer.h"

// Define logging component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitUI

/**
 Bounce pixels define how many pixels the cell swipe view is
 moved during the bounce animation
 */
#define BOUNCE_PIXELS 5.0

//const NSUInteger RKTableControllerOverlayViewTag = 123456789;
NSString* const RKTableControllerDidStartLoadNotification = @"RKTableControllerDidStartLoadNotification";
NSString* const RKTableControllerDidFinishLoadNotification = @"RKTableControllerDidFinishLoadNotification";
NSString* const RKTableControllerDidLoadObjectsNotification = @"RKTableControllerDidLoadObjectsNotification";
NSString* const RKTableControllerDidLoadEmptyNotification = @"RKTableControllerDidLoadEmptyNotification";
NSString* const RKTableControllerDidLoadErrorNotification = @"RKTableControllerDidLoadErrorNotification";
NSString* const RKTableControllerDidBecomeOnline = @"RKTableControllerDidBecomeOnline";
NSString* const RKTableControllerDidBecomeOffline = @"RKTableControllerDidBecomeOffline";

static NSString* lastUpdatedDateDictionaryKey = @"lastUpdatedDateDictionaryKey";

@implementation RKAbstractTableController

@synthesize delegate = _delegate;
@synthesize viewController = _viewController;
@synthesize tableView = _tableView;
@synthesize sections = _sections;
@synthesize defaultRowAnimation = _defaultRowAnimation;

@synthesize objectLoader = _objectLoader;
@synthesize objectManager = _objectManager;
@synthesize cellMappings = _cellMappings;
@synthesize autoRefreshFromNetwork = _autoRefreshFromNetwork;
@synthesize autoRefreshRate = _autoRefreshRate;

@synthesize empty = _empty;
@synthesize loading = _loading;
@synthesize loaded = _loaded;
@synthesize online = _online;
@synthesize error = _error;

@synthesize imageForEmpty = _imageForEmpty;
@synthesize imageForError = _imageForError;
@synthesize imageForOffline = _imageForOffline;
@synthesize loadingView = _loadingView;

@synthesize variableHeightRows = _variableHeightRows;
@synthesize showsHeaderRowsWhenEmpty = _showsHeaderRowsWhenEmpty;
@synthesize showsFooterRowsWhenEmpty = _showsFooterRowsWhenEmpty;
@synthesize pullToRefreshEnabled = _pullToRefreshEnabled;
@synthesize headerItems = _headerItems;
@synthesize footerItems = _footerItems;
@synthesize canEditRows = _canEditRows;
@synthesize canMoveRows = _canMoveRows;
@synthesize autoResizesForKeyboard = _autoResizesForKeyboard;
@synthesize emptyItem = _emptyItem;

@synthesize cellSwipeViewsEnabled = _cellSwipeViewsEnabled;
@synthesize cellSwipeView = _cellSwipeView;
@synthesize swipeCell = _swipeCell;
@synthesize animatingCellSwipe = _animatingCellSwipe;
@synthesize swipeDirection = _swipeDirection;
@synthesize swipeObject = _swipeObject;

@synthesize showsOverlayImagesModally = _modalOverlay;
@synthesize overlayFrame = _overlayFrame;
@synthesize tableOverlayView = _tableOverlayView;
@synthesize stateOverlayImageView = _stateOverlayImageView;
@synthesize cache = _cache;

#pragma mark - Instantiation

+ (id)tableControllerWithTableView:(UITableView*)tableView 
                forViewController:(UIViewController*)viewController {
    return [[[self alloc] initWithTableView:tableView viewController:viewController] autorelease];
}

+ (id)tableControllerForTableViewController:(UITableViewController*)tableViewController {
    return [self tableControllerWithTableView:tableViewController.tableView 
                           forViewController:tableViewController];
}

- (id)initWithTableView:(UITableView*)theTableView viewController:(UIViewController*)theViewController {
    NSAssert(theTableView, @"Cannot initialize a table view model with a nil tableView");
    NSAssert(theViewController, @"Cannot initialize a table view model with a nil viewController");
    self = [self init];
    if (self) {
        self.tableView = theTableView;
        self.viewController = theViewController;
        self.variableHeightRows = NO;
        self.defaultRowAnimation = UITableViewRowAnimationFade;
        self.overlayFrame = CGRectZero;
        self.showsOverlayImagesModally = YES;
    }
    
    return self;
}

- (id)init {
    self = [super init];
    if (self) {
        if ([self isMemberOfClass:[RKAbstractTableController class]]) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException 
                                           reason:[NSString stringWithFormat:@"%@ is abstract. Instantiate one its subclasses instead.",
                                                   NSStringFromClass([self class])]
                                         userInfo:nil];
        }
        
        _sections = [NSMutableArray new];
        self.objectManager = [RKObjectManager sharedManager];
        _cellMappings = [RKTableViewCellMappings new];
        
        _headerItems = [NSMutableArray new];
        _footerItems = [NSMutableArray new];
        _showsHeaderRowsWhenEmpty = YES;
        _showsFooterRowsWhenEmpty = YES;

        // Setup autoRefreshRate to (effectively) never
        _autoRefreshFromNetwork = NO;
        _autoRefreshRate = NSTimeIntervalSince1970;

        // Setup key-value observing
        [self addObserver:self 
               forKeyPath:@"loading" 
                  options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                  context:nil];
        [self addObserver:self 
               forKeyPath:@"loaded" 
                  options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                  context:nil];        
        [self addObserver:self 
               forKeyPath:@"empty" 
                  options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                  context:nil];
        [self addObserver:self 
               forKeyPath:@"error" 
                  options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                  context:nil];
        [self addObserver:self 
               forKeyPath:@"online" 
                  options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                  context:nil];
    }
    return self;
}

- (void)dealloc {
    // Disconnect from the tableView
    if (_tableView.delegate == self) _tableView.delegate = nil;    
    if (_tableView.dataSource == self) _tableView.dataSource = nil;

    // Remove overlay and pull-to-refresh subviews
    [_stateOverlayImageView removeFromSuperview];
    [_stateOverlayImageView release];
    _stateOverlayImageView = nil;
    [_tableOverlayView removeFromSuperview];
    [_tableOverlayView release];
    _tableOverlayView = nil;

    // Remove observers
    [self removeObserver:self forKeyPath:@"loading"];
    [self removeObserver:self forKeyPath:@"loaded"];
    [self removeObserver:self forKeyPath:@"empty"];
    [self removeObserver:self forKeyPath:@"error"];
    [self removeObserver:self forKeyPath:@"online"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [_objectManager.client.requestQueue cancelRequestsWithDelegate:self];
    _objectLoader.delegate = nil;
    _objectLoader = nil;

    [_sections release];
    [_cellMappings release];
    [_headerItems release];
    [_footerItems release];
    [_cellSwipeView release];
    [_swipeCell release];
    [_swipeObject release];
    [_emptyItem release];
    [super dealloc];
}

- (void)setTableView:(UITableView *)tableView {
    NSAssert(tableView, @"Cannot assign a nil tableView to the model");
    _tableView = tableView;
    _tableView.delegate = self;
    _tableView.dataSource = self;
}

- (void)setViewController:(UIViewController *)viewController {
    _viewController = viewController;
    
    if ([viewController isKindOfClass:[UITableViewController class]]) {
        self.tableView = [(UITableViewController*)viewController tableView];
    }
}

- (void)setObjectManager:(RKObjectManager *)objectManager {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    // Remove observers
    if (_objectManager) {
        [notificationCenter removeObserver:self                                                         
                                      name:RKObjectManagerDidBecomeOfflineNotification                                                       
                                    object:_objectManager];
        [notificationCenter removeObserver:self                                     
                                      name:RKObjectManagerDidBecomeOnlineNotification                                       
                                    object:_objectManager];
    }
    
    _objectManager = objectManager;
    
    // Set observers
    [notificationCenter addObserver:self                                              
                           selector:@selector(objectManagerConnectivityDidChange:)                            
                               name:RKObjectManagerDidBecomeOnlineNotification                                
                             object:objectManager];
    [notificationCenter addObserver:self 
                           selector:@selector(objectManagerConnectivityDidChange:)                            
                               name:RKObjectManagerDidBecomeOfflineNotification                                
                             object:objectManager];
    
    // Initialize online/offline state (if it is known)
    if (objectManager.networkStatus != RKObjectManagerNetworkStatusUnknown) {
        self.online = objectManager.isOnline;
    }
}

- (void)setAutoResizesForKeyboard:(BOOL)autoResizesForKeyboard {
    if (_autoResizesForKeyboard != autoResizesForKeyboard) {
        _autoResizesForKeyboard = autoResizesForKeyboard;
        if (_autoResizesForKeyboard) {
            // Register for Keyboard notifications
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(resizeTableViewForKeyboard:)
                                                         name:UIKeyboardWillShowNotification
                                                       object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(resizeTableViewForKeyboard:)
                                                         name:UIKeyboardWillHideNotification
                                                       object:nil];
        } else {
            [[NSNotificationCenter defaultCenter] removeObserver:self];
        }
    }
}

- (void)setAutoRefreshFromNetwork:(BOOL)autoRefreshFromNetwork {
    if (_autoRefreshFromNetwork != autoRefreshFromNetwork) {
        _autoRefreshFromNetwork = autoRefreshFromNetwork;
        if (_autoRefreshFromNetwork) {
            NSString* cachePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0]
                                   stringByAppendingPathComponent:@"RKAbstractTableControllerCache"];
            _cache = [[RKCache alloc] initWithCachePath:cachePath subDirectories:nil];
        } else {
            if (_cache) {
                [_cache invalidateAll];
                [_cache release];
                _cache = nil;
            }
        }
    }
}

- (void)objectManagerConnectivityDidChange:(NSNotification *)notification {
    RKLogTrace(@"%@ received network status change notification: %@", self, [notification name]);
    self.online = self.objectManager.isOnline;
}

#pragma mark - Managing Sections

- (NSUInteger)sectionCount {
    return [_sections count];
}

- (NSUInteger)rowCount {
    return [[_sections valueForKeyPath:@"@sum.rowCount"] intValue];
}

- (RKTableSection *)sectionAtIndex:(NSUInteger)index {
    return [_sections objectAtIndex:index];
}

- (NSUInteger)indexForSection:(RKTableSection *)section {
    NSAssert(section, @"Cannot return index for a nil section");
    return [_sections indexOfObject:section];
}

- (RKTableSection *)sectionWithHeaderTitle:(NSString *)title {
    for (RKTableSection* section in _sections) {
        if ([section.headerTitle isEqualToString:title]) {
            return section;
        }
    }
    
    return nil;
}

- (UITableViewCell *)cellForObjectAtIndexPath:(NSIndexPath *)indexPath {
    RKTableSection* section = [self sectionAtIndex:indexPath.section];
    id mappableObject = [section objectAtIndex:indexPath.row];
    RKTableViewCellMapping* cellMapping = [self.cellMappings cellMappingForObject:mappableObject];
    NSAssert(cellMapping, @"Cannot build a tableView cell for object %@: No cell mapping defined for objects of type '%@'", mappableObject, NSStringFromClass([mappableObject class]));
    
    UITableViewCell* cell = [cellMapping mappableObjectForData:self.tableView];
    NSAssert(cell, @"Cell mapping failed to dequeue or allocate a tableViewCell for object: %@", mappableObject);
    
    // Map the object state into the cell
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

#pragma mark - UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView*)theTableView {
    NSAssert(theTableView == self.tableView, @"numberOfSectionsInTableView: invoked with inappropriate tableView: %@", theTableView);
    RKLogTrace(@"%@ numberOfSectionsInTableView = %d", self, self.sectionCount);
    return self.sectionCount;
}

- (NSInteger)tableView:(UITableView*)theTableView numberOfRowsInSection:(NSInteger)section {
    NSAssert(theTableView == self.tableView, @"tableView:numberOfRowsInSection: invoked with inappropriate tableView: %@", theTableView);
    RKLogTrace(@"%@ numberOfRowsInSection:%d = %d", self, section, self.sectionCount);
    return [[_sections objectAtIndex:section] rowCount];
}

- (UITableViewCell *)tableView:(UITableView*)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSAssert(theTableView == self.tableView, @"tableView:cellForRowAtIndexPath: invoked with inappropriate tableView: %@", theTableView);
    UITableViewCell* cell = [self cellForObjectAtIndexPath:indexPath];
    
    RKLogTrace(@"%@ cellForRowAtIndexPath:%@ = %@", self, indexPath, cell);
    return cell;
}

- (NSString*)tableView:(UITableView*)theTableView titleForHeaderInSection:(NSInteger)section {
    NSAssert(theTableView == self.tableView, @"tableView:titleForHeaderInSection: invoked with inappropriate tableView: %@", theTableView);
    return [[_sections objectAtIndex:section] headerTitle];
}

- (NSString*)tableView:(UITableView*)theTableView titleForFooterInSection:(NSInteger)section {
    NSAssert(theTableView == self.tableView, @"tableView:titleForFooterInSection: invoked with inappropriate tableView: %@", theTableView);
    return [[_sections objectAtIndex:section] footerTitle];
}

- (BOOL)tableView:(UITableView*)theTableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    NSAssert(theTableView == self.tableView, @"tableView:canEditRowAtIndexPath: invoked with inappropriate tableView: %@", theTableView);
    return _canEditRows;
}

- (BOOL)tableView:(UITableView*)theTableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    NSAssert(theTableView == self.tableView, @"tableView:canMoveRowAtIndexPath: invoked with inappropriate tableView: %@", theTableView);
    return _canMoveRows;
}

#pragma mark - Cell Mappings

- (void)mapObjectsWithClass:(Class)objectClass toTableCellsWithMapping:(RKTableViewCellMapping*)cellMapping {
    // TODO: Should we raise an exception/throw a warning if you are doing class mapping for a type
    // that implements a cellMapping instance method? Maybe a class declaration overrides 
    [_cellMappings setCellMapping:cellMapping forClass:objectClass];
}

- (id)objectForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSAssert(indexPath, @"Cannot lookup object with a nil indexPath");
    RKTableSection* section = [self sectionAtIndex:indexPath.section];
    return [section objectAtIndex:indexPath.row];
}

- (RKTableViewCellMapping*)cellMappingForObjectAtIndexPath:(NSIndexPath *)indexPath {
    NSAssert(indexPath, @"Cannot lookup cell mapping for object with a nil indexPath");
    id object = [self objectForRowAtIndexPath:indexPath];
    return [self.cellMappings cellMappingForObject:object];
}

- (UITableViewCell *)cellForObject:(id)object {
    NSIndexPath *indexPath = [self indexPathForObject:object];
    return indexPath ? [self cellForObjectAtIndexPath:indexPath] : nil;
}

// TODO: unit test...
// TODO: This needs to be updated to take into account header & footer rows...
- (NSIndexPath *)indexPathForObject:(id)object {
    NSUInteger sectionIndex = 0;
    for (RKTableSection *section in self.sections) {
        NSUInteger rowIndex = 0;
        for (id rowObject in section.objects) {
            if ([rowObject isEqual:object]) {
                return [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
            }
            
            rowIndex++;
        }
        sectionIndex++;
    }
    
    return nil;
}

#pragma mark - Header and Footer Rows

- (void)addHeaderRowForItem:(RKTableItem*)tableItem {
    [_headerItems addObject:tableItem];
}

- (void)addFooterRowForItem:(RKTableItem*)tableItem {
    [_footerItems addObject:tableItem];
}

- (void)addHeaderRowWithMapping:(RKTableViewCellMapping *)cellMapping {
    RKTableItem* tableItem = [RKTableItem tableItem];
    tableItem.cellMapping = cellMapping;
    [self addHeaderRowForItem:tableItem];
}

- (void)addFooterRowWithMapping:(RKTableViewCellMapping *)cellMapping {
    RKTableItem* tableItem = [RKTableItem tableItem];
    tableItem.cellMapping = cellMapping;
    [self addFooterRowForItem:tableItem];
}

- (void)removeAllHeaderRows {
    [_headerItems removeAllObjects];
}

- (void)removeAllFooterRows {
    [_footerItems removeAllObjects];
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView*)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSAssert(theTableView == self.tableView, @"tableView:didSelectRowAtIndexPath: invoked with inappropriate tableView: %@", theTableView);
    RKLogTrace(@"%@: Row at indexPath %@ selected for tableView %@", self, indexPath, theTableView);
    
    id object = [self objectForRowAtIndexPath:indexPath];
    
    // NOTE: Do NOT use cellForObjectAtIndexPath here. See https://gist.github.com/eafbb641d37bb7137759
    UITableViewCell* cell = [theTableView cellForRowAtIndexPath:indexPath];
    RKTableViewCellMapping* cellMapping = [_cellMappings cellMappingForObject:object];
    
    // NOTE: Handle deselection first as the onSelectCell processing may result in the tableView
    // being reloaded and our instances invalidated
    if (cellMapping.deselectsRowOnSelection) {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    
    if (cellMapping.onSelectCell) {
        cellMapping.onSelectCell();
    }
    
    if (cellMapping.onSelectCellForObjectAtIndexPath) {
        RKLogTrace(@"%@: Invoking onSelectCellForObjectAtIndexPath block with cellMapping %@ for object %@ at indexPath = %@", self, cell, object, indexPath);
        cellMapping.onSelectCellForObjectAtIndexPath(cell, object, indexPath);
    }        
}

- (void)tableView:(UITableView *)theTableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSAssert(theTableView == self.tableView, @"tableView:didSelectRowAtIndexPath: invoked with inappropriate tableView: %@", theTableView);
    cell.hidden = NO;
    id mappableObject = [self objectForRowAtIndexPath:indexPath];
    RKTableViewCellMapping* cellMapping = [self.cellMappings cellMappingForObject:mappableObject];
    if (cellMapping.onCellWillAppearForObjectAtIndexPath) {
        cellMapping.onCellWillAppearForObjectAtIndexPath(cell, mappableObject, indexPath);
    }
    
    // Informal protocol
    // TODO: Needs documentation!!!
    SEL willDisplaySelector = @selector(willDisplayInTableViewCell:);
    if ([mappableObject respondsToSelector:willDisplaySelector]) {
        [mappableObject performSelector:willDisplaySelector withObject:cell];
    }
    
    // Handle hiding header/footer rows when empty
    if ([self isEmpty]) {
        if (! self.showsHeaderRowsWhenEmpty && [_headerItems containsObject:mappableObject]) {
            cell.hidden = YES;
        }
        
        if (! self.showsFooterRowsWhenEmpty && [_footerItems containsObject:mappableObject]) {
            cell.hidden = YES;
        }
    } else {
        if (self.emptyItem && [self.emptyItem isEqual:mappableObject]) {
            cell.hidden = YES;
        }
    }
}

// Variable height support

- (CGFloat)tableView:(UITableView *)theTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.variableHeightRows) {
        RKTableViewCellMapping* cellMapping = [self cellMappingForObjectAtIndexPath:indexPath];

        if (cellMapping.heightOfCellForObjectAtIndexPath) {
            id object = [self objectForRowAtIndexPath:indexPath];
            CGFloat height = cellMapping.heightOfCellForObjectAtIndexPath(object, indexPath);
            RKLogTrace(@"Variable row height configured for tableView. Height via block invocation for row at indexPath '%@' = %f", indexPath, cellMapping.rowHeight);
            return height;
        } else {
            RKLogTrace(@"Variable row height configured for tableView. Height for row at indexPath '%@' = %f", indexPath, cellMapping.rowHeight);
            return cellMapping.rowHeight;
        }
    }
    
    RKLogTrace(@"Uniform row height configured for tableView. Table view row height = %f", self.tableView.rowHeight);
    return self.tableView.rowHeight;
}

- (CGFloat)tableView:(UITableView*)theTableView heightForHeaderInSection:(NSInteger)sectionIndex {
    NSAssert(theTableView == self.tableView, @"heightForHeaderInSection: invoked with inappropriate tableView: %@", theTableView);
    RKTableSection* section = [self sectionAtIndex:sectionIndex];
    return section.headerHeight;
}

- (CGFloat)tableView:(UITableView*)theTableView heightForFooterInSection:(NSInteger)sectionIndex {
    NSAssert(theTableView == self.tableView, @"heightForFooterInSection: invoked with inappropriate tableView: %@", theTableView);
    RKTableSection* section = [self sectionAtIndex:sectionIndex];
    return section.footerHeight;
}

- (UIView*)tableView:(UITableView*)theTableView viewForHeaderInSection:(NSInteger)sectionIndex {
    NSAssert(theTableView == self.tableView, @"viewForHeaderInSection: invoked with inappropriate tableView: %@", theTableView);
    RKTableSection* section = [self sectionAtIndex:sectionIndex];
    return section.headerView;
}

- (UIView*)tableView:(UITableView*)theTableView viewForFooterInSection:(NSInteger)sectionIndex {
    NSAssert(theTableView == self.tableView, @"viewForFooterInSection: invoked with inappropriate tableView: %@", theTableView);
    RKTableSection* section = [self sectionAtIndex:sectionIndex];
    return section.footerView;
}

- (void)tableView:(UITableView*)theTableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    RKTableViewCellMapping* cellMapping = [self cellMappingForObjectAtIndexPath:indexPath];
    if (cellMapping.onTapAccessoryButtonForObjectAtIndexPath) {
        RKLogTrace(@"Found a block for tableView:accessoryButtonTappedForRowWithIndexPath: Executing...");
        UITableViewCell* cell = [self tableView:self.tableView cellForRowAtIndexPath:indexPath];
        id object = [self objectForRowAtIndexPath:indexPath];
        cellMapping.onTapAccessoryButtonForObjectAtIndexPath(cell, object, indexPath);
    }
}

- (NSString*)tableView:(UITableView*)theTableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    RKTableViewCellMapping* cellMapping = [self cellMappingForObjectAtIndexPath:indexPath];
    if (cellMapping.titleForDeleteButtonForObjectAtIndexPath) {
        RKLogTrace(@"Found a block for tableView:titleForDeleteConfirmationButtonForRowAtIndexPath: Executing...");
        UITableViewCell* cell = [self tableView:self.tableView cellForRowAtIndexPath:indexPath];
        id object = [self objectForRowAtIndexPath:indexPath];
        return cellMapping.titleForDeleteButtonForObjectAtIndexPath(cell, object, indexPath);
    }
    return NSLocalizedString(@"Delete", nil);
}

- (UITableViewCellEditingStyle)tableView:(UITableView*)theTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_canEditRows) {
        RKTableViewCellMapping* cellMapping = [self cellMappingForObjectAtIndexPath:indexPath];
        UITableViewCell* cell = [self tableView:self.tableView cellForRowAtIndexPath:indexPath];
        if (cellMapping.editingStyleForObjectAtIndexPath) {
            RKLogTrace(@"Found a block for tableView:editingStyleForRowAtIndexPath: Executing...");
            id object = [self objectForRowAtIndexPath:indexPath];
            return cellMapping.editingStyleForObjectAtIndexPath(cell, object, indexPath);
        }
        return UITableViewCellEditingStyleDelete;
    }
    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView*)theTableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.delegate respondsToSelector:@selector(tableController:didEndEditing:atIndexPath:)]) {
        id object = [self objectForRowAtIndexPath:indexPath];
        [self.delegate tableController:self didEndEditing:object atIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView*)theTableView willBeginEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.delegate respondsToSelector:@selector(tableController:willBeginEditing:atIndexPath:)]) {
        id object = [self objectForRowAtIndexPath:indexPath];
        [self.delegate tableController:self willBeginEditing:object atIndexPath:indexPath];
    }
}

- (NSIndexPath *)tableView:(UITableView*)theTableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    if (_canMoveRows) {
        RKTableViewCellMapping* cellMapping = [self cellMappingForObjectAtIndexPath:sourceIndexPath];
        if (cellMapping.targetIndexPathForMove) {
            RKLogTrace(@"Found a block for tableView:targetIndexPathForMoveFromRowAtIndexPath:toProposedIndexPath: Executing...");
            UITableViewCell* cell = [self tableView:self.tableView cellForRowAtIndexPath:sourceIndexPath];
            id object = [self objectForRowAtIndexPath:sourceIndexPath];
            return cellMapping.targetIndexPathForMove(cell, object, sourceIndexPath, proposedDestinationIndexPath);
        }
    }
    return proposedDestinationIndexPath;
}

- (NSIndexPath *)tableView:(UITableView*)theTableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self removeSwipeView:YES];
    return indexPath;
}

#pragma mark - Network Table Loading

- (void)loadTableFromResourcePath:(NSString*)resourcePath {
    NSAssert(self.objectManager, @"Cannot perform a network load without an object manager");
    [self loadTableWithObjectLoader:[self.objectManager objectLoaderWithResourcePath:resourcePath delegate:nil]];
}

- (void)loadTableFromResourcePath:(NSString *)resourcePath usingBlock:(void (^)(RKObjectLoader*))block {
    RKObjectLoader* theObjectLoader = [self.objectManager objectLoaderWithResourcePath:resourcePath delegate:nil];
    block(theObjectLoader);
    [self loadTableWithObjectLoader:theObjectLoader];
}

- (void)loadTableWithObjectLoader:(RKObjectLoader*)theObjectLoader {
    NSAssert(theObjectLoader, @"Cannot perform a network load without an object loader");
    if (! [self.objectLoader isEqual:theObjectLoader]) {
        theObjectLoader.delegate = self;
        self.objectLoader = theObjectLoader;
    }
    if ([self.delegate respondsToSelector:@selector(tableController:willLoadTableWithObjectLoader:)]) {
        [self.delegate tableController:self willLoadTableWithObjectLoader:self.objectLoader];
    }
    if (self.objectLoader.queue && ![self.objectLoader.queue containsRequest:self.objectLoader]) {
        [self.objectLoader.queue addRequest:self.objectLoader];
    }
}

- (void)cancelLoad {
    [self.objectLoader cancel];
}

- (NSDate*)lastUpdatedDate {
    if (_autoRefreshFromNetwork) {
        NSAssert(_cache, @"Found a nil cache when trying to read our last loaded time");
        NSDictionary* lastUpdatedDates = [_cache dictionaryForCacheKey:lastUpdatedDateDictionaryKey];
        RKLogTrace(@"Last updated dates dictionary retrieved from tableController cache: %@", lastUpdatedDates);
        if (lastUpdatedDates) {
            NSAssert(self.objectLoader, @"Found a nil objectLoader when attempting to retrieve our last loaded time");
            NSString* absoluteURLString = [self.objectLoader.URL absoluteString];
            NSNumber* lastUpdatedTimeIntervalSince1970 = (NSNumber*)[lastUpdatedDates objectForKey:absoluteURLString];
            if (absoluteURLString && lastUpdatedTimeIntervalSince1970) {
                return [NSDate dateWithTimeIntervalSince1970:[lastUpdatedTimeIntervalSince1970 doubleValue]];
            }
        }
    }
    return nil;
}

- (BOOL)isAutoRefreshNeeded {
    BOOL isAutoRefreshNeeded = NO;
    if (_autoRefreshFromNetwork) {
        isAutoRefreshNeeded = YES;
        NSDate* lastUpdatedDate = [self lastUpdatedDate];
        RKLogTrace(@"Last updated: %@", lastUpdatedDate);
        if (lastUpdatedDate) {
            RKLogTrace(@"-timeIntervalSinceNow=%f, autoRefreshRate=%f",
                       -[lastUpdatedDate timeIntervalSinceNow], _autoRefreshRate);
            isAutoRefreshNeeded = (-[lastUpdatedDate timeIntervalSinceNow] > _autoRefreshRate);
        }
    }
    return isAutoRefreshNeeded;
}

#pragma mark - RKRequestDelegate & RKObjectLoaderDelegate methods

- (void)requestDidStartLoad:(RKRequest*)request {
    RKLogTrace(@"tableController %@ started loading.", self);
    self.loading = YES;
}

- (void)requestDidCancelLoad:(RKRequest*)request {
    RKLogTrace(@"tableController %@ cancelled loading.", self);
    self.loading = NO;
    
    if ([self.delegate respondsToSelector:@selector(tableControllerDidCancelLoad:)]) {
        [self.delegate tableControllerDidCancelLoad:self];
    }
}

- (void)requestDidTimeout:(RKRequest*)request {
    RKLogTrace(@"tableController %@ timed out while loading.", self);
    self.loading = NO;
}

- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response {
    RKLogTrace(@"tableController %@ finished loading.", self);

    // Updated the lastUpdatedDate dictionary using the URL of the request
    if (self.autoRefreshFromNetwork) {
        NSAssert(_cache, @"Found a nil cache when trying to save our last loaded time");
        NSMutableDictionary* lastUpdatedDates = [[_cache dictionaryForCacheKey:lastUpdatedDateDictionaryKey] mutableCopy];
        if (lastUpdatedDates) {
            [_cache invalidateEntry:lastUpdatedDateDictionaryKey];
        } else {
            lastUpdatedDates = [[NSMutableDictionary alloc] init];
        }
        NSNumber* timeIntervalSince1970 = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
        RKLogTrace(@"Setting timeIntervalSince1970=%@ for URL %@", timeIntervalSince1970, [request.URL absoluteString]);
        [lastUpdatedDates setObject:timeIntervalSince1970
                             forKey:[request.URL absoluteString]];
        [_cache writeDictionary:lastUpdatedDates withCacheKey:lastUpdatedDateDictionaryKey];
        [lastUpdatedDates release];
    }
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
    RKLogError(@"tableController %@ failed network load with error: %@", self, error);
    self.error = error;
    [self didFinishLoad];
}

- (void)objectLoaderDidFinishLoading:(RKObjectLoader *)objectLoader {
    if ([self.delegate respondsToSelector:@selector(tableController:didLoadTableWithObjectLoader:)]) {
        [self.delegate tableController:self didLoadTableWithObjectLoader:objectLoader];
    }

    [self.objectLoader reset];
    [self didFinishLoad];
}

- (void)didFinishLoad {
    self.empty = [self isEmpty];
    self.loading = [self.objectLoader isLoading]; // Mutate loading state after we have adjusted empty
    self.loaded = YES;

    // Setup offline image state based on current online/offline state
    [self updateOfflineImageForOnlineState:[self isOnline]];

    [self resetOverlayView];
    
    if (self.delegate && [_delegate respondsToSelector:@selector(tableControllerDidFinishFinalLoad:)])
        [_delegate performSelector:@selector(tableControllerDidFinishFinalLoad:)];
}

#pragma mark - Table Overlay Views

// Adds an overlay view above the table
- (void)addToOverlayView:(UIView *)view modally:(BOOL)modally {
    if (! _tableOverlayView) {
        CGRect overlayFrame = CGRectIsEmpty(self.overlayFrame) ? self.tableView.frame : self.overlayFrame;
        _tableOverlayView = [[UIView alloc] initWithFrame:overlayFrame];
        _tableOverlayView.autoresizesSubviews = YES;
        _tableOverlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
        NSInteger tableIndex = [_tableView.superview.subviews indexOfObject:_tableView];
        if (tableIndex != NSNotFound) {
            [_tableView.superview addSubview:_tableOverlayView];
        }
    }
    
    // When modal, we enable user interaction to catch & discard events on the overlay and its subviews
    _tableOverlayView.userInteractionEnabled = modally;
    view.userInteractionEnabled = modally;

    if (CGRectIsEmpty(view.frame)) {
        view.frame = _tableOverlayView.bounds;

        // Center it in the overlay
        view.center = _tableOverlayView.center;
    }

    [_tableOverlayView addSubview:view];
}

- (void)resetOverlayView {
    if (_stateOverlayImageView && _stateOverlayImageView.image == nil) {
        [_stateOverlayImageView removeFromSuperview];
    }
    if (_tableOverlayView && _tableOverlayView.subviews.count == 0) {
        [_tableOverlayView removeFromSuperview];
        [_tableOverlayView release];
        _tableOverlayView = nil;
    }
}

- (void)addSubviewOverTableView:(UIView *)view {
    NSInteger tableIndex = [_tableView.superview.subviews
                            indexOfObject:_tableView];
    if (NSNotFound != tableIndex) {
        [_tableView.superview addSubview:view];
    }
}

- (BOOL)removeImageFromOverlay:(UIImage *)image {
    if (image && _stateOverlayImageView.image == image) {
        _stateOverlayImageView.image = nil;
        return YES;
    }
    return NO;
}

- (void)showImageInOverlay:(UIImage *)image {
    NSAssert(self.tableView, @"Cannot add an overlay image to a nil tableView");
    if (! _stateOverlayImageView) {
        _stateOverlayImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _stateOverlayImageView.opaque = YES;
        _stateOverlayImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
        _stateOverlayImageView.contentMode = UIViewContentModeCenter;
    }
    _stateOverlayImageView.image = image;
    [self addToOverlayView:_stateOverlayImageView modally:self.showsOverlayImagesModally];
}

- (void)removeImageOverlay {
    _stateOverlayImageView.image = nil;
    [_stateOverlayImageView removeFromSuperview];
    [self resetOverlayView];
}

- (void)setImageForEmpty:(UIImage*)imageForEmpty {
    [imageForEmpty retain];
    BOOL imageRemoved = [self removeImageFromOverlay:_imageForEmpty];
    [_imageForEmpty release];
    _imageForEmpty = imageForEmpty;
    if (imageRemoved) [self showImageInOverlay:_imageForEmpty];
}

- (void)setImageForError:(UIImage*)imageForError {
    [imageForError retain];
    BOOL imageRemoved = [self removeImageFromOverlay:_imageForError];
    [_imageForError release];
    _imageForError = imageForError;
    if (imageRemoved) [self showImageInOverlay:_imageForError];
}

- (void)setImageForOffline:(UIImage*)imageForOffline {
    [imageForOffline retain];
    BOOL imageRemoved = [self removeImageFromOverlay:_imageForOffline];
    [_imageForOffline release];
    _imageForOffline = imageForOffline;
    if (imageRemoved) [self showImageInOverlay:_imageForOffline];
}

- (void)setLoadingView:(UIView*)loadingView {
    [loadingView retain];
    BOOL viewRemoved = (_loadingView.superview != nil);
    [_loadingView removeFromSuperview];
    [self resetOverlayView];
    [_loadingView release];
    _loadingView = loadingView;
    if (viewRemoved) [self addToOverlayView:_loadingView modally:NO];
}

#pragma mark - KVO & Model States

- (BOOL)isLoading {
    return self.loading;
}

- (BOOL)isLoaded {
    return self.loaded;
}

- (BOOL)isOnline {
    return self.online;
}

- (BOOL)isError {
    return _error != nil;
}

- (BOOL)isEmpty {
    NSUInteger nonRowItemsCount = [_headerItems count] + [_footerItems count];
    nonRowItemsCount += _emptyItem ? 1 : 0;
    BOOL isEmpty = (self.rowCount - nonRowItemsCount) == 0;
    RKLogTrace(@"Determined isEmpty = %@. self.rowCount = %d with %d nonRowItems in the table", isEmpty ? @"YES" : @"NO", self.rowCount, nonRowItemsCount);
    return isEmpty;
}

- (void)isLoadingDidChangeTo:(BOOL)isLoading {
    if (isLoading) {
        // Remove any current state to allow drawing of the loading view
        [self removeImageOverlay];
        
        // Clear the error state
        self.error = nil;
        self.empty = NO;
        
        if ([self.delegate respondsToSelector:@selector(tableControllerDidStartLoad:)]) {
            [self.delegate tableControllerDidStartLoad:self];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:RKTableControllerDidStartLoadNotification object:self];
        
        if (self.loadingView) {
            [self addToOverlayView:self.loadingView modally:NO];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(tableControllerDidFinishLoad:)]) {
            [self.delegate tableControllerDidFinishLoad:self];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:RKTableControllerDidFinishLoadNotification object:self];
        
        if (self.loadingView) {
            [self.loadingView removeFromSuperview];
            [self resetOverlayView];
        }

        [self resetPullToRefreshRecognizer];
    }
    
    // We don't want any image overlays applied until loading is finished
    _stateOverlayImageView.hidden = isLoading;
}

- (void)isLoadedDidChangeTo:(BOOL)isLoaded {
    if (isLoaded) {
        RKLogDebug(@"%@: is now loaded.", self);
    } else {
        RKLogDebug(@"%@: is NOT loaded.", self);
    }        
}

- (void)errorDidChangeTo:(BOOL)isError {
    if (isError) {
        if ([self.delegate respondsToSelector:@selector(tableController:didFailLoadWithError:)]) {
            [self.delegate tableController:self didFailLoadWithError:self.error];
        }
        
        NSDictionary* userInfo = [NSDictionary dictionaryWithObject:self.error forKey:RKErrorNotificationErrorKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:RKTableControllerDidLoadErrorNotification object:self userInfo:userInfo];
        
        if (self.imageForError) {
            [self showImageInOverlay:self.imageForError];
        }
    } else {
        [self removeImageFromOverlay:self.imageForError];
    }
}

- (void)isEmptyDidChangeTo:(BOOL)isEmpty {
    if (isEmpty) {
        // TODO: maybe this should be didLoadEmpty?
        if ([self.delegate respondsToSelector:@selector(tableControllerDidBecomeEmpty:)]) {
            [self.delegate tableControllerDidBecomeEmpty:self];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:RKTableControllerDidLoadEmptyNotification object:self];
        
        if (self.imageForEmpty) {
            [self showImageInOverlay:self.imageForEmpty];
        }
    } else {
        if (self.imageForEmpty) {
            [self removeImageFromOverlay:self.imageForEmpty];
        }
    }
}

- (void)updateOfflineImageForOnlineState:(BOOL)isOnline {
    if (isOnline) {
        [self removeImageFromOverlay:self.imageForOffline];
    } else {
        if (self.imageForOffline) {
            [self showImageInOverlay:self.imageForOffline];
        }
    }
}

- (void)isOnlineDidChangeTo:(BOOL)isOnline {
    if (isOnline) {
        // We just transitioned to online
        if ([self.delegate respondsToSelector:@selector(tableControllerDidBecomeOnline:)]) {
            [self.delegate tableControllerDidBecomeOnline:self];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:RKTableControllerDidBecomeOnline object:self];
    } else {
        // We just transitioned to offline
        if ([self.delegate respondsToSelector:@selector(tableControllerDidBecomeOffline:)]) {
            [self.delegate tableControllerDidBecomeOffline:self];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:RKTableControllerDidBecomeOffline object:self];
    }

    [self updateOfflineImageForOnlineState:isOnline];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    BOOL newValue = NO;
    BOOL oldValue = NO;
    if ([keyPath isEqualToString:@"loading"]) {
        newValue = [[change valueForKey:NSKeyValueChangeNewKey] boolValue];
        oldValue = [[change valueForKey:NSKeyValueChangeOldKey] boolValue];
        if (newValue != oldValue) [self isLoadingDidChangeTo:newValue];
    } else if ([keyPath isEqualToString:@"loaded"]) {
        newValue = [[change valueForKey:NSKeyValueChangeNewKey] boolValue];
        oldValue = [[change valueForKey:NSKeyValueChangeOldKey] boolValue];
        if (newValue != oldValue) [self isLoadedDidChangeTo:newValue];
    } else if ([keyPath isEqualToString:@"error"]) {
        newValue = (! [[change valueForKey:NSKeyValueChangeNewKey] isEqual:[NSNull null]]);
        oldValue = (! [[change valueForKey:NSKeyValueChangeOldKey] isEqual:[NSNull null]]);
        if (newValue != oldValue) [self errorDidChangeTo:newValue];
    } else if ([keyPath isEqualToString:@"empty"]) {
        newValue = [[change valueForKey:NSKeyValueChangeNewKey] boolValue];
        oldValue = [[change valueForKey:NSKeyValueChangeOldKey] boolValue];
        if (newValue != oldValue) [self isEmptyDidChangeTo:newValue];
    } else if ([keyPath isEqualToString:@"online"]) {
        newValue = [[change valueForKey:NSKeyValueChangeNewKey] boolValue];
        oldValue = [[change valueForKey:NSKeyValueChangeOldKey] boolValue];
        if (newValue != oldValue) [self isOnlineDidChangeTo:newValue];
    }
    
    RKLogTrace(@"Key-value observation triggered for keyPath '%@'. Old value = %d, new value = %d", keyPath, oldValue, newValue);
}

#pragma mark - Pull to Refresh

- (RKRefreshGestureRecognizer *)pullToRefreshGestureRecognizer {
    RKRefreshGestureRecognizer *refreshRecognizer = nil;
    for (RKRefreshGestureRecognizer *recognizer in self.tableView.gestureRecognizers) {
        if ([recognizer isKindOfClass:[RKRefreshGestureRecognizer class]]) {
            refreshRecognizer = recognizer;
            break;
        }
    }
    return refreshRecognizer;
}

- (void)setPullToRefreshEnabled:(BOOL)pullToRefreshEnabled {
    RKRefreshGestureRecognizer *recognizer = nil;
    if (pullToRefreshEnabled) {
        recognizer = [[[RKRefreshGestureRecognizer alloc] initWithTarget:self action:@selector(pullToRefreshStateChanged:)] autorelease];
        [self.tableView addGestureRecognizer:recognizer];
    }
    else {
        recognizer = [self pullToRefreshGestureRecognizer];
        if (recognizer)
            [self.tableView removeGestureRecognizer:recognizer];
    }
    _pullToRefreshEnabled = pullToRefreshEnabled;
}

- (void)pullToRefreshStateChanged:(UIGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateRecognized) {
        if ([self pullToRefreshDataSourceIsLoading:gesture])
            return;
        RKLogDebug(@"%@: pull to refresh triggered from gesture: %@", self, gesture);
        if (self.objectLoader) {
            [self.objectLoader reset];
            [self.objectLoader send];
        }
    }
}

- (void)resetPullToRefreshRecognizer {
    RKRefreshGestureRecognizer* recognizer = [self pullToRefreshGestureRecognizer];
    if (recognizer)
        [recognizer setRefreshState:RKRefreshIdle];
}

- (BOOL)pullToRefreshDataSourceIsLoading:(UIGestureRecognizer*)gesture {
	// If we have already been loaded and we are loading again, a refresh is taking place...
	return [self isLoaded] && [self isLoading] && [self isOnline];
}

- (NSDate*)pullToRefreshDataSourceLastUpdated:(UIGestureRecognizer*)gesture {
    NSDate* dataSourceLastUpdated = [self lastUpdatedDate];
    return dataSourceLastUpdated ? dataSourceLastUpdated : [NSDate date];
}

#pragma mark - Cell Swipe Menu Methods

- (void)setupSwipeGestureRecognizers {
    // Setup a right swipe gesture recognizer
    UISwipeGestureRecognizer* rightSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];
    rightSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    [self.tableView addGestureRecognizer:rightSwipeGestureRecognizer];
    [rightSwipeGestureRecognizer release];

    // Setup a left swipe gesture recognizer
    UISwipeGestureRecognizer* leftSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft:)];
    leftSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.tableView addGestureRecognizer:leftSwipeGestureRecognizer];
    [leftSwipeGestureRecognizer release];
}

- (void)removeSwipeGestureRecognizers {
    for (UIGestureRecognizer* recognizer in self.tableView.gestureRecognizers) {
        if ([recognizer isKindOfClass:[UISwipeGestureRecognizer class]]) {
            [self.tableView removeGestureRecognizer:recognizer];
        }
    }
}

- (void)setCanEditRows:(BOOL)canEditRows {
    NSAssert(!_cellSwipeViewsEnabled, @"Table model cannot be made editable when cell swipe menus are enabled");
    _canEditRows = canEditRows;
}

- (void)setCellSwipeViewsEnabled:(BOOL)cellSwipeViewsEnabled {
    NSAssert(!_canEditRows, @"Cell swipe menus cannot be enabled for editable tableModels");
    if (cellSwipeViewsEnabled) {
        [self setupSwipeGestureRecognizers];
    } else {
        [self removeSwipeView:YES];
        [self removeSwipeGestureRecognizers];
    }
    _cellSwipeViewsEnabled = cellSwipeViewsEnabled;
}

- (void)swipe:(UISwipeGestureRecognizer*)recognizer direction:(UISwipeGestureRecognizerDirection)direction {
    if (_cellSwipeViewsEnabled && recognizer && recognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint location = [recognizer locationInView:self.tableView];
        NSIndexPath* indexPath = [self.tableView indexPathForRowAtPoint:location];
        UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
        id object = [self objectForRowAtIndexPath:indexPath];

        if (cell.frame.origin.x != 0) {
            [self removeSwipeView:YES];
            return;
        }

        [self removeSwipeView:NO];

        if (cell != _swipeCell && !_animatingCellSwipe) {
            [self addSwipeViewTo:cell withObject:object direction:direction];
        }
    }
}

- (void)swipeLeft:(UISwipeGestureRecognizer*)recognizer {
    [self swipe:recognizer direction:UISwipeGestureRecognizerDirectionLeft];
}

- (void)swipeRight:(UISwipeGestureRecognizer*)recognizer {
    [self swipe:recognizer direction:UISwipeGestureRecognizerDirectionRight];
}

- (void)addSwipeViewTo:(UITableViewCell *)cell withObject:(id)object direction:(UISwipeGestureRecognizerDirection)direction {
    if (_cellSwipeViewsEnabled) {
        NSAssert(cell, @"Cannot process swipe view with nil cell");
        NSAssert(object, @"Cannot process swipe view with nil object");

        _cellSwipeView.frame = cell.frame;

        if ([self.delegate respondsToSelector:@selector(tableController:willAddSwipeView:toCell:forObject:)]) {
            [self.delegate tableController:self
                         willAddSwipeView:_cellSwipeView
                                   toCell:cell
                                forObject:object];
        }

        [self.tableView insertSubview:_cellSwipeView belowSubview:cell];

        _swipeCell = [cell retain];
        _swipeObject = [object retain];
        _swipeDirection = direction;

        CGRect cellFrame = cell.frame;

        _cellSwipeView.frame = CGRectMake(0, cellFrame.origin.y, cellFrame.size.width, cellFrame.size.height);

        _animatingCellSwipe = YES;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.2];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(animationDidStopAddingSwipeView:finished:context:)];

        cell.frame = CGRectMake(direction == UISwipeGestureRecognizerDirectionRight ? cellFrame.size.width : -cellFrame.size.width, cellFrame.origin.y, cellFrame.size.width, cellFrame.size.height);
        [UIView commitAnimations];
    }
}

- (void)animationDidStopAddingSwipeView:(NSString*)animationID finished:(NSNumber*)finished context:(void*)context {
    _animatingCellSwipe = NO;
}

- (void)removeSwipeView:(BOOL)animated {
    if (!_cellSwipeViewsEnabled || !_swipeCell || _animatingCellSwipe) {
        RKLogTrace(@"Exiting early with _cellSwipeViewsEnabled=%d, _swipCell=%@, _animatingCellSwipe=%d",
                   _cellSwipeViewsEnabled, _swipeCell, _animatingCellSwipe);
        return;
    }

    if ([self.delegate respondsToSelector:@selector(tableController:willRemoveSwipeView:fromCell:forObject:)]) {
        [self.delegate tableController:self
                     willRemoveSwipeView:_cellSwipeView
                            fromCell:_swipeCell
                            forObject:_swipeObject];
    }

    if (animated) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.2];
        if (_swipeDirection == UISwipeGestureRecognizerDirectionRight) {
            _swipeCell.frame = CGRectMake(BOUNCE_PIXELS, _swipeCell.frame.origin.y, _swipeCell.frame.size.width, _swipeCell.frame.size.height);
        } else {
            _swipeCell.frame = CGRectMake(-BOUNCE_PIXELS, _swipeCell.frame.origin.y, _swipeCell.frame.size.width, _swipeCell.frame.size.height);
        }
        _animatingCellSwipe = YES;
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(animationDidStopOne:finished:context:)];
        [UIView commitAnimations];
    } else {
        [_cellSwipeView removeFromSuperview];
        _swipeCell.frame = CGRectMake(0,_swipeCell.frame.origin.y,_swipeCell.frame.size.width, _swipeCell.frame.size.height);
        [_swipeCell release];
        _swipeCell = nil;
    }
}

- (void)animationDidStopOne:(NSString*)animationID finished:(NSNumber*)finished context:(void*)context {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.2];
    if (_swipeDirection == UISwipeGestureRecognizerDirectionRight) {
        _swipeCell.frame = CGRectMake(BOUNCE_PIXELS*2, _swipeCell.frame.origin.y, _swipeCell.frame.size.width, _swipeCell.frame.size.height);
    } else {
        _swipeCell.frame = CGRectMake(-BOUNCE_PIXELS*2, _swipeCell.frame.origin.y, _swipeCell.frame.size.width, _swipeCell.frame.size.height);
    }
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStopTwo:finished:context:)];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    [UIView commitAnimations];
}

- (void)animationDidStopTwo:(NSString*)animationID finished:(NSNumber*)finished context:(void*)context {
    [UIView commitAnimations];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.2];
    if (_swipeDirection == UISwipeGestureRecognizerDirectionRight) {
        _swipeCell.frame = CGRectMake(0, _swipeCell.frame.origin.y, _swipeCell.frame.size.width, _swipeCell.frame.size.height);
    } else {
        _swipeCell.frame = CGRectMake(0, _swipeCell.frame.origin.y, _swipeCell.frame.size.width, _swipeCell.frame.size.height);
    }
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStopThree:finished:context:)];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    [UIView commitAnimations];
}

- (void)animationDidStopThree:(NSString*)animationID finished:(NSNumber*)finished context:(void*)context {
    _animatingCellSwipe = NO;
    [_swipeCell release];
    _swipeCell = nil;
    [_cellSwipeView removeFromSuperview];
}

#pragma mark UIScrollViewDelegate methods

- (void)scrollViewWillBeginDragging:(UIScrollView*)scrollView {
    [self removeSwipeView:YES];
}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    [self removeSwipeView:NO];
    return YES;
}

#pragma mark - Keyboard Notification methods

- (void)resizeTableViewForKeyboard:(NSNotification*)notification {
    NSAssert(_autoResizesForKeyboard, @"Errantly receiving keyboard notifications while autoResizesForKeyboard=NO");
    NSDictionary* userInfo = [notification userInfo];

    CGRect keyboardEndFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat heightForViewShift = keyboardEndFrame.size.height;
    RKLogTrace(@"keyboardEndFrame.size.height=%f, heightForViewShift=%f",
               keyboardEndFrame.size.height, heightForViewShift);

    CGFloat bottomBarOffset = 0.0;
    UINavigationController* navigationController = self.viewController.navigationController;
    if (navigationController && navigationController.toolbar && !navigationController.toolbarHidden) {
        bottomBarOffset += navigationController.toolbar.frame.size.height;
        RKLogTrace(@"Found a visible toolbar. Reducing size of heightForViewShift by=%f", bottomBarOffset);
    }

    UITabBarController* tabBarController = self.viewController.tabBarController;
    if (tabBarController && tabBarController.tabBar && !self.viewController.hidesBottomBarWhenPushed) {
        bottomBarOffset += tabBarController.tabBar.frame.size.height;
        RKLogTrace(@"Found a visible tabBar. Reducing size of heightForViewShift by=%f", bottomBarOffset);
    }

    if ([[notification name] isEqualToString:UIKeyboardWillShowNotification]) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.2];
        UIEdgeInsets contentInsets = UIEdgeInsetsMake(0, 0, (heightForViewShift - bottomBarOffset), 0);
        self.tableView.contentInset = contentInsets;
        self.tableView.scrollIndicatorInsets = contentInsets;

        CGRect nonKeyboardRect = self.tableView.frame;
        nonKeyboardRect.size.height -= heightForViewShift;
        RKLogTrace(@"Searching for a firstResponder not inside our nonKeyboardRect (%f, %f, %f, %f)",
                   nonKeyboardRect.origin.x, nonKeyboardRect.origin.y,
                   nonKeyboardRect.size.width, nonKeyboardRect.size.height);

        UIView* firstResponder = [self.tableView findFirstResponder];
        if (firstResponder) {
            CGRect firstResponderFrame = firstResponder.frame;
            RKLogTrace(@"Found firstResponder=%@ at (%f, %f, %f, %f)", firstResponder,
                       firstResponderFrame.origin.x, firstResponderFrame.origin.y,
                       firstResponderFrame.size.width, firstResponderFrame.size.width);

            if (![firstResponder.superview isEqual:self.tableView]) {
                firstResponderFrame = [firstResponder.superview convertRect:firstResponderFrame toView:self.tableView];
                RKLogTrace(@"firstResponder (%@) frame is not in tableView's coordinate system. Coverted to (%f, %f, %f, %f)",
                           firstResponder, firstResponderFrame.origin.x, firstResponderFrame.origin.y,
                           firstResponderFrame.size.width, firstResponderFrame.size.height);
            }

            if (!CGRectContainsPoint(nonKeyboardRect, firstResponderFrame.origin)) {
                RKLogTrace(@"firstResponder (%@) is underneath keyboard. Beginning scroll of tableView to show", firstResponder);
                [self.tableView scrollRectToVisible:firstResponderFrame animated:YES];
            }
        }
        [UIView commitAnimations];

    } else if ([[notification name] isEqualToString:UIKeyboardWillHideNotification]) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.2];
        UIEdgeInsets contentInsets = UIEdgeInsetsZero;
        self.tableView.contentInset = contentInsets;
        self.tableView.scrollIndicatorInsets = contentInsets;
        [UIView commitAnimations];
    }
}

@end
