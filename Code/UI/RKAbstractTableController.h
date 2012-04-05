//
//  RKAbstractTableController.h
//  RestKit
//
//  Created by Jeff Arena on 8/11/11.
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

#if TARGET_OS_IPHONE

#import <UIKit/UIKit.h>
#import "RKTableSection.h"
#import "RKTableViewCellMappings.h"
#import "RKTableItem.h"
#import "RKObjectManager.h"
#import "RKObjectMapping.h"
#import "RKObjectLoader.h"

/** @name Constants */

/** Posted when the table view model starts loading */
extern NSString* const RKTableControllerDidStartLoadNotification;

/** Posted when the table view model finishes loading */
extern NSString* const RKTableControllerDidFinishLoadNotification;

/** Posted when the table view model has loaded objects into the table view */
extern NSString* const RKTableControllerDidLoadObjectsNotification;

/** Posted when the table view model has loaded an empty collection of objects into the table view */
extern NSString* const RKTableControllerDidLoadEmptyNotification;

/** Posted when the table view model has loaded an error */
extern NSString* const RKTableControllerDidLoadErrorNotification;

/** Posted when the table view model has transitioned from offline to online */
extern NSString* const RKTableControllerDidBecomeOnline;

/** Posted when the table view model has transitioned from online to offline */
extern NSString* const RKTableControllerDidBecomeOffline;

@protocol RKTableControllerDelegate;

/**
 RestKit's table view abstraction leverages the object mapping engine to transform
 local objects into UITableViewCell representations. The table view model encapsulates
 the functionality of a UITableView dataSource and delegate into a single reusable
 component.
 */
@interface RKAbstractTableController : NSObject <UITableViewDataSource, UITableViewDelegate> {
  @protected
    UIView *_tableOverlayView;
    UIImageView *_stateOverlayImageView;
    UIView *_pullToRefreshHeaderView;
    RKCache *_cache;
}

/////////////////////////////////////////////////////////////////////////
/// @name Configuring the Table Controller
/////////////////////////////////////////////////////////////////////////

@property (nonatomic, assign)   id<RKTableControllerDelegate> delegate;
@property (nonatomic, readonly) UIViewController* viewController;
@property (nonatomic, readonly) UITableView* tableView;
@property (nonatomic, readonly) NSMutableArray* sections;
@property (nonatomic, assign)   UITableViewRowAnimation defaultRowAnimation;

@property (nonatomic, assign)   BOOL pullToRefreshEnabled;
@property (nonatomic, assign)   BOOL canEditRows;
@property (nonatomic, assign)   BOOL canMoveRows;
@property (nonatomic, assign)   BOOL autoResizesForKeyboard;

/////////////////////////////////////////////////////////////////////////
/// @name Instantiation
/////////////////////////////////////////////////////////////////////////

+ (id)tableControllerWithTableView:(UITableView*)tableView
                forViewController:(UIViewController*)viewController;

+ (id)tableControllerForTableViewController:(UITableViewController*)tableViewController;

- (id)initWithTableView:(UITableView*)tableView
         viewController:(UIViewController*)viewController;

/////////////////////////////////////////////////////////////////////////
/// @name Object to Table View Cell Mappings
/////////////////////////////////////////////////////////////////////////

@property (nonatomic, retain) RKTableViewCellMappings* cellMappings;

- (void)mapObjectsWithClass:(Class)objectClass toTableCellsWithMapping:(RKTableViewCellMapping*)cellMapping;
- (void)mapObjectsWithClassName:(NSString *)objectClassName toTableCellsWithMapping:(RKTableViewCellMapping*)cellMapping;
- (id)objectForRowAtIndexPath:(NSIndexPath *)indexPath;
- (RKTableViewCellMapping*)cellMappingForObjectAtIndexPath:(NSIndexPath *)indexPath;

/**
 Return the index path of the object within the table
 */
- (NSIndexPath *)indexPathForObject:(id)object;
- (UITableViewCell *)cellForObject:(id)object;

/////////////////////////////////////////////////////////////////////////
/// @name Header and Footer Rows
/////////////////////////////////////////////////////////////////////////

- (void)addHeaderRowForItem:(RKTableItem *)tableItem;
- (void)addFooterRowForItem:(RKTableItem *)tableItem;
- (void)addHeaderRowWithMapping:(RKTableViewCellMapping *)cellMapping;
- (void)addFooterRowWithMapping:(RKTableViewCellMapping *)cellMapping;
- (void)removeAllHeaderRows;
- (void)removeAllFooterRows;

/////////////////////////////////////////////////////////////////////////
/// @name RESTful Table Loading
/////////////////////////////////////////////////////////////////////////

/**
 The object manager instance this table view model is associated with.

 This instance is used for creating object loaders when loading Network
 tables and provides the managed object store used for Core Data tables.
 Online/offline state is also determined by watching for reachability
 notifications generated from the object manager.

 **Default**: The shared manager instance `[RKObjectManager sharedManager]`
 */
@property (nonatomic, assign) RKObjectManager *objectManager;
@property (nonatomic, assign) BOOL autoRefreshFromNetwork;
@property (nonatomic, assign) NSTimeInterval autoRefreshRate;

- (void)loadTableWithObjectLoader:(RKObjectLoader *)objectLoader;
- (void)cancelLoad;
- (BOOL)isAutoRefreshNeeded;

/////////////////////////////////////////////////////////////////////////
/// @name Model State Views
/////////////////////////////////////////////////////////////////////////

- (BOOL)isLoading;
- (BOOL)isLoaded;
- (BOOL)isEmpty;
- (BOOL)isOnline;

@property (nonatomic, readonly) BOOL isError;
@property (nonatomic, readonly, retain) NSError* error;

/**
 An image to overlay onto the table when the table view
 does not have any row data to display. It will be centered
 within the table view
 */
// TODO: Should be emptyImage
@property (nonatomic, retain) UIImage* imageForEmpty;

/**
 An image to overlay onto the table when a load operation
 has encountered an error. It will be centered
 within the table view.
 */
// TODO: Should be errorImage
@property (nonatomic, retain) UIImage* imageForError;

/**
 An image to overlay onto the table with when the user does
 not have connectivity to the Internet

 @see RKReachabilityObserver
 */
// TODO: Should be offlineImage
@property (nonatomic, retain) UIImage* imageForOffline;

/**
 A UIView to add to the table overlay during loading. It
 will be positioned directly in the center of the table view.

 The loading view is always presented non-modally.
 */
@property (nonatomic, retain) UIView*  loadingView;

/**
 A rectangle configuring the dimensions for the overlay view that is
 applied to the table view during display of the loading view and
 state overlay images (offline/error/empty). By default, the overlay
 view will be auto-sized to cover the entire table. This can result in
 an inaccessible table UI if you have embedded controls within the header
 or footer views of your table. You can adjust the frame of the overlay
 precisely by configuring the overlayFrame property.
 */
@property (nonatomic, assign) CGRect overlayFrame;

/**
 When YES, the image view added to the table overlay for displaying table
 state (i.e. for offline, error and empty) will be displayed modally
 and prevent any interaction with the table.

 **Default**: YES
 */
@property (nonatomic, assign) BOOL showsOverlayImagesModally;

// Default NO
@property (nonatomic, assign) BOOL variableHeightRows;
@property (nonatomic, assign) BOOL showsHeaderRowsWhenEmpty;
@property (nonatomic, assign) BOOL showsFooterRowsWhenEmpty;
@property (nonatomic, retain) RKTableItem* emptyItem;

/////////////////////////////////////////////////////////////////////////
/// @name Managing Sections
/////////////////////////////////////////////////////////////////////////

/** The number of sections in the model. */
@property (nonatomic, readonly) NSUInteger sectionCount;

/** The number of rows across all sections in the model. */
@property (nonatomic, readonly) NSUInteger rowCount;

/** Returns the section at the specified index.
 *	@param index Must be less than the total number of sections. */
- (RKTableSection *)sectionAtIndex:(NSUInteger)index;

/** Returns the first section with the specified header title.
 *	@param title The header title. */
- (RKTableSection *)sectionWithHeaderTitle:(NSString *)title;

/** Returns the index of the specified section.
 *	@param section Must be a valid non nil RKTableViewSection.
 *	@return If section is not found, method returns NSNotFound. */
- (NSUInteger)indexForSection:(RKTableSection *)section;

/** Returns the UITableViewCell created by applying the specified
 *  mapping operation to the object identified by indexPath.
 *  @param indexPath The indexPath in the tableView for which a cell
 *  is needed. */
- (UITableViewCell *)cellForObjectAtIndexPath:(NSIndexPath *)indexPath;

/////////////////////////////////////////////////////////////////////////
/// @name Managing Swipe View
/////////////////////////////////////////////////////////////////////////

@property (nonatomic, assign)   BOOL cellSwipeViewsEnabled;
@property (nonatomic, retain)   UIView* cellSwipeView;
@property (nonatomic, readonly) UITableViewCell* swipeCell;
@property (nonatomic, readonly) id swipeObject;
@property (nonatomic, readonly) BOOL animatingCellSwipe;
@property (nonatomic, readonly) UISwipeGestureRecognizerDirection swipeDirection;

- (void)addSwipeViewTo:(UITableViewCell *)cell withObject:(id)object direction:(UISwipeGestureRecognizerDirection)direction;
- (void)removeSwipeView:(BOOL)animated;

@end

@protocol RKTableControllerDelegate <NSObject>

@optional

// Network
- (void)tableController:(RKAbstractTableController *)tableController willLoadTableWithObjectLoader:(RKObjectLoader*)objectLoader;
- (void)tableController:(RKAbstractTableController *)tableController didLoadTableWithObjectLoader:(RKObjectLoader*)objectLoader;

// Basic States
- (void)tableControllerDidStartLoad:(RKAbstractTableController *)tableController;

/** Sent when the table view has transitioned out of the loading state regardless of outcome **/
- (void)tableControllerDidFinishLoad:(RKAbstractTableController *)tableController;
- (void)tableController:(RKAbstractTableController *)tableController didFailLoadWithError:(NSError*)error;
- (void)tableControllerDidCancelLoad:(RKAbstractTableController *)tableController;
- (void)tableController:(RKAbstractTableController *)tableController didLoadObjects:(NSArray*)objects inSection:(NSUInteger)sectionIndex;

/** Sent to the delegate when the controller is really and truly finished loading/updating, whether from the network or from Core Data, or from static data, ... this happens in didFinishLoading
 **/
- (void)tableControllerDidFinishFinalLoad:(RKAbstractTableController *)tableController;

/**
 Sent to the delegate when the content of the table view has become empty
 */
- (void)tableControllerDidBecomeEmpty:(RKAbstractTableController *)tableController; // didLoadEmpty???

/**
 Sent to the delegate when the table view model has transitioned from offline to online
 */
- (void)tableControllerDidBecomeOnline:(RKAbstractTableController *)tableController;

/**
 Sent to the delegate when the table view model has transitioned from online to offline
 */
- (void)tableControllerDidBecomeOffline:(RKAbstractTableController *)tableController;

// Sections
- (void)tableController:(RKAbstractTableController *)tableController didInsertSection:(RKTableSection *)section atIndex:(NSUInteger)sectionIndex;
- (void)tableController:(RKAbstractTableController *)tableController didRemoveSection:(RKTableSection *)section atIndex:(NSUInteger)sectionIndex;

// Objects
- (void)tableController:(RKAbstractTableController *)tableController didInsertObject:(id)object atIndexPath:(NSIndexPath *)indexPath;
- (void)tableController:(RKAbstractTableController *)tableController didUpdateObject:(id)object atIndexPath:(NSIndexPath *)indexPath;
- (void)tableController:(RKAbstractTableController *)tableController didDeleteObject:(id)object atIndexPath:(NSIndexPath *)indexPath;

// Editing
- (void)tableController:(RKAbstractTableController *)tableController willBeginEditing:(id)object atIndexPath:(NSIndexPath *)indexPath;
- (void)tableController:(RKAbstractTableController *)tableController didEndEditing:(id)object atIndexPath:(NSIndexPath *)indexPath;

// Swipe Views
- (void)tableController:(RKAbstractTableController *)tableController willAddSwipeView:(UIView*)swipeView toCell:(UITableViewCell *)cell forObject:(id)object;
- (void)tableController:(RKAbstractTableController *)tableController willRemoveSwipeView:(UIView*)swipeView fromCell:(UITableViewCell *)cell forObject:(id)object;

// BELOW NOT YET IMPLEMENTED

// Cells
- (void)tableController:(RKAbstractTableController *)tableController willDisplayCell:(UITableViewCell *)cell forObject:(id)object atIndexPath:(NSIndexPath *)indexPath;
- (void)tableController:(RKAbstractTableController *)tableController didSelectCell:(UITableViewCell *)cell forObject:(id)object atIndexPath:(NSIndexPath *)indexPath;

// Objects
- (void)tableControllerDidBeginUpdates:(RKAbstractTableController *)tableController;
- (void)tableControllerDidEndUpdates:(RKAbstractTableController *)tableController;

@end

#endif // TARGET_OS_IPHONE
