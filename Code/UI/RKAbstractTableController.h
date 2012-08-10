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
#import "RKTableViewCellMappings.h"
#import "RKTableItem.h"
#import "RKObjectManager.h"
#import "RKObjectMapping.h"
#import "RKObjectLoader.h"

///-----------------------------------------------------------------------------
/// @name Constants
///-----------------------------------------------------------------------------

/**
 Posted when the table controller starts loading.
 */
extern NSString * const RKTableControllerDidStartLoadNotification;

/**
 Posted when the table controller finishes loading.
 */
extern NSString * const RKTableControllerDidFinishLoadNotification;

/**
 Posted when the table controller has loaded objects into the table view.
 */
extern NSString * const RKTableControllerDidLoadObjectsNotification;

/**
 Posted when the table controller has loaded an empty collection of objects into the table view.
 */
extern NSString * const RKTableControllerDidLoadEmptyNotification;

/**
 Posted when the table controller has loaded an error.
 */
extern NSString * const RKTableControllerDidLoadErrorNotification;

/**
 Posted when the table controller has transitioned from an offline to online state.
 */
extern NSString * const RKTableControllerDidBecomeOnline;

/**
 Posted when the table controller has transitioned from an online to an offline state.
 */
extern NSString * const RKTableControllerDidBecomeOffline;

@protocol RKAbstractTableControllerDelegate;

/**
 @enum RKTableControllerState

 @constant RKTableControllerStateNormal Indicates that the table has
 loaded normally and is displaying cell content. It is not loading content,
 is not empty, has not loaded an error, and is not offline.

 @constant RKTableControllerStateLoading Indicates that the table controller
 is loading content from a remote source.

 @constant RKTableControllerStateEmpty Indicates that the table controller has
 retrieved an empty collection of objects.

 @constant RKTableControllerStateError Indicates that the table controller has
 encountered an error while attempting to load.

 @constant RKTableControllerStateOffline Indicates that the table controller is
 offline and cannot perform network access.

 @constant RKTableControllerStateNotYetLoaded Indicates that the table controller is
 has not yet attempted a load and state is unknown.
 */
enum RKTableControllerState {
    RKTableControllerStateNormal        = 0,
    RKTableControllerStateLoading       = 1 << 1,
    RKTableControllerStateEmpty         = 1 << 2,
    RKTableControllerStateError         = 1 << 3,
    RKTableControllerStateOffline       = 1 << 4,
    RKTableControllerStateNotYetLoaded  = 0xFF000000
};
typedef NSUInteger RKTableControllerState;

/**
 RKAbstractTableController is an abstract base class for concrete table controller classes.
 A table controller object acts as both the delegate and data source for a UITableView
 object and leverages the RestKit object mapping engine to transform local domain models
 into UITableViewCell representations. Concrete implementations are provided for the
 display of static table views and Core Data backed fetched results controller basied
 table views.
 */
@interface RKAbstractTableController : NSObject <UITableViewDataSource, UITableViewDelegate>

///-----------------------------------------------------------------------------
/// @name Configuring the Table Controller
///-----------------------------------------------------------------------------

@property (nonatomic, assign)   id<RKAbstractTableControllerDelegate> delegate;
@property (nonatomic, readonly) UIViewController *viewController;
@property (nonatomic, readonly) UITableView *tableView;
@property (nonatomic, assign)   UITableViewRowAnimation defaultRowAnimation;

@property (nonatomic, assign)   BOOL pullToRefreshEnabled;
@property (nonatomic, assign)   BOOL canEditRows;
@property (nonatomic, assign)   BOOL canMoveRows;
@property (nonatomic, assign)   BOOL autoResizesForKeyboard;

///-----------------------------------------------------------------------------
/// @name Instantiation
///-----------------------------------------------------------------------------

+ (id)tableControllerWithTableView:(UITableView *)tableView
                 forViewController:(UIViewController *)viewController;

+ (id)tableControllerForTableViewController:(UITableViewController *)tableViewController;

- (id)initWithTableView:(UITableView *)tableView
         viewController:(UIViewController *)viewController;

///-----------------------------------------------------------------------------
/// @name Object to Table View Cell Mappings
///-----------------------------------------------------------------------------

@property (nonatomic, retain) RKTableViewCellMappings *cellMappings;

- (void)mapObjectsWithClass:(Class)objectClass toTableCellsWithMapping:(RKTableViewCellMapping *)cellMapping;
- (void)mapObjectsWithClassName:(NSString *)objectClassName toTableCellsWithMapping:(RKTableViewCellMapping *)cellMapping;
- (id)objectForRowAtIndexPath:(NSIndexPath *)indexPath;
- (RKTableViewCellMapping *)cellMappingForObjectAtIndexPath:(NSIndexPath *)indexPath;

/**
 Return the index path of the object within the table
 */
- (NSIndexPath *)indexPathForObject:(id)object;
- (UITableViewCell *)cellForObject:(id)object;
- (void)reloadRowForObject:(id)object withRowAnimation:(UITableViewRowAnimation)rowAnimation;

///-----------------------------------------------------------------------------
/// @name Header and Footer Rows
///-----------------------------------------------------------------------------

- (void)addHeaderRowForItem:(RKTableItem *)tableItem;
- (void)addFooterRowForItem:(RKTableItem *)tableItem;
- (void)addHeaderRowWithMapping:(RKTableViewCellMapping *)cellMapping;
- (void)addFooterRowWithMapping:(RKTableViewCellMapping *)cellMapping;
- (void)removeAllHeaderRows;
- (void)removeAllFooterRows;

///-----------------------------------------------------------------------------
/// @name RESTful Table Loading
///-----------------------------------------------------------------------------

/**
 The object manager instance this table controller is associated with.

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

///-----------------------------------------------------------------------------
/// @name Inspecting Table State
///-----------------------------------------------------------------------------

/**
 The current state of the table controller. Note that the controller may be in more
 than one state (e.g. loading | empty).
 */
@property (nonatomic, readonly, assign) RKTableControllerState state;

/**
 An error object that was encountered as the result of an attempt to load
 the table. Will return a value when the table is in the error state,
 otherwise nil.
 */
@property (nonatomic, readonly, retain) NSError *error;

/**
 Returns a Boolean value indicating if the table controller is currently
 loading content.
 */
- (BOOL)isLoading;

/**
 Returns a Boolean value indicating if the table controller has attempted
 a load and transitioned into any state.
 */
- (BOOL)isLoaded;

/**
 Returns a Boolean value indicating if the table controller has loaded an
 empty set of content.

 When YES and there is not an empty item configured, the table controller
 will optionally display an empty image overlayed on top of the table view.

 **NOTE**: It is possible for an empty table controller to display cells
 witin the managed table view in the event an empty item or header/footer
 rows are configured.

 @see imageForEmpty
 */
- (BOOL)isEmpty;

/**
 Returns a Boolean value indicating if the table controller is online
 and network operations may be performed.
 */
- (BOOL)isOnline;

/**
 Returns a Boolean value indicating if the table controller is offline.

 When YES, the table controller will optionally display an offline image
 overlayed on top of the table view.

 @see imageForOffline
 */
- (BOOL)isOffline;

/**
 Returns a Boolean value indicating if the table controller encountered
 an error while attempting to load.

 When YES, the table controller will optionally display an error image
 overlayed on top of the table view.

 @see imageForError
 */
- (BOOL)isError;

///-----------------------------------------------------------------------------
/// @name Model State Views
///-----------------------------------------------------------------------------

/**
 An image to overlay onto the table when the table view
 does not have any row data to display. It will be centered
 within the table view.
 */
@property (nonatomic, retain) UIImage *imageForEmpty;

/**
 An image to overlay onto the table when a load operation
 has encountered an error. It will be centered
 within the table view.
 */
@property (nonatomic, retain) UIImage *imageForError;

/**
 An image to overlay onto the table with when the user does
 not have connectivity to the Internet.

 @see RKReachabilityObserver
 */
@property (nonatomic, retain) UIImage *imageForOffline;

/**
 A UIView to add to the table overlay during loading. It
 will be positioned directly in the center of the table view.

 The loading view is always presented non-modally.
 */
@property (nonatomic, retain) UIView *loadingView;

/**
 Returns the image, if any, configured for display when the table controller
 is in the given state.

 **NOTE** This method accepts a single state value.

 @param state The table controller state
 @return The image for the specified state, else nil. Always returns nil for
 RKTableControllerStateNormal, RKTableControllerStateLoading and RKTableControllerStateLoading.
 */
- (UIImage *)imageForState:(RKTableControllerState)state;

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
 The image currently displayed within the overlay view.
 */
@property (nonatomic, readonly) UIImage *overlayImage;

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
@property (nonatomic, retain) RKTableItem *emptyItem;

///-----------------------------------------------------------------------------
/// @name Managing Sections
///-----------------------------------------------------------------------------

/**
 The number of sections in the table.
 */
@property (nonatomic, readonly) NSUInteger sectionCount;

/**
 The number of rows across all sections in the model.
 */
@property (nonatomic, readonly) NSUInteger rowCount;

/**
 Returns the number of rows in the section at the given index.

 @param index The index of the section to return the row count for.
 @returns The number of rows contained within the section with the given index.
 @raises NSInvalidArgumentException Raised if index is greater than or
    equal to the total number of sections in the table.
 */
- (NSUInteger)numberOfRowsInSection:(NSUInteger)index;

/**
 Returns the UITableViewCell created by applying the specified
 mapping operation to the object identified by indexPath.

 @param indexPath The indexPath in the tableView for which a cell is needed.
 */
- (UITableViewCell *)cellForObjectAtIndexPath:(NSIndexPath *)indexPath;

///-----------------------------------------------------------------------------
/// @name Managing Swipe View
///-----------------------------------------------------------------------------

@property (nonatomic, assign)   BOOL cellSwipeViewsEnabled;
@property (nonatomic, retain)   UIView *cellSwipeView;
@property (nonatomic, readonly) UITableViewCell *swipeCell;
@property (nonatomic, readonly) id swipeObject;
@property (nonatomic, readonly) BOOL animatingCellSwipe;
@property (nonatomic, readonly) UISwipeGestureRecognizerDirection swipeDirection;

- (void)addSwipeViewTo:(UITableViewCell *)cell withObject:(id)object direction:(UISwipeGestureRecognizerDirection)direction;
- (void)removeSwipeView:(BOOL)animated;

@end

@protocol RKAbstractTableControllerDelegate <NSObject>

@optional

// Network
- (void)tableController:(RKAbstractTableController *)tableController willLoadTableWithObjectLoader:(RKObjectLoader *)objectLoader;
- (void)tableController:(RKAbstractTableController *)tableController didLoadTableWithObjectLoader:(RKObjectLoader *)objectLoader;

// Basic States
- (void)tableControllerDidStartLoad:(RKAbstractTableController *)tableController;

/**
 Sent when the table view has transitioned out of the loading state regardless of outcome
 */
- (void)tableControllerDidFinishLoad:(RKAbstractTableController *)tableController;
- (void)tableController:(RKAbstractTableController *)tableController didFailLoadWithError:(NSError *)error;
- (void)tableControllerDidCancelLoad:(RKAbstractTableController *)tableController;

/**
 Sent to the delegate when the controller is really and truly finished loading/updating, whether from the network or from Core Data,
 or from static data, ... this happens in didFinishLoading
 */
- (void)tableControllerDidFinalizeLoad:(RKAbstractTableController *)tableController;

/**
 Sent to the delegate when the content of the table view has become empty
 */
- (void)tableControllerDidBecomeEmpty:(RKAbstractTableController *)tableController;

/**
 Sent to the delegate when the table controller has transitioned from offline to online
 */
- (void)tableControllerDidBecomeOnline:(RKAbstractTableController *)tableController;

/**
 Sent to the delegate when the table controller has transitioned from online to offline
 */
- (void)tableControllerDidBecomeOffline:(RKAbstractTableController *)tableController;

// Objects
- (void)tableController:(RKAbstractTableController *)tableController didInsertObject:(id)object atIndexPath:(NSIndexPath *)indexPath;
- (void)tableController:(RKAbstractTableController *)tableController didUpdateObject:(id)object atIndexPath:(NSIndexPath *)indexPath;
- (void)tableController:(RKAbstractTableController *)tableController didDeleteObject:(id)object atIndexPath:(NSIndexPath *)indexPath;

// Editing
- (void)tableController:(RKAbstractTableController *)tableController willBeginEditing:(id)object atIndexPath:(NSIndexPath *)indexPath;
- (void)tableController:(RKAbstractTableController *)tableController didEndEditing:(id)object atIndexPath:(NSIndexPath *)indexPath;

// Swipe Views
- (void)tableController:(RKAbstractTableController *)tableController willAddSwipeView:(UIView *)swipeView toCell:(UITableViewCell *)cell forObject:(id)object;
- (void)tableController:(RKAbstractTableController *)tableController willRemoveSwipeView:(UIView *)swipeView fromCell:(UITableViewCell *)cell forObject:(id)object;

// Cells
- (void)tableController:(RKAbstractTableController *)tableController willDisplayCell:(UITableViewCell *)cell forObject:(id)object atIndexPath:(NSIndexPath *)indexPath;
- (void)tableController:(RKAbstractTableController *)tableController didSelectCell:(UITableViewCell *)cell forObject:(id)object atIndexPath:(NSIndexPath *)indexPath;

@end

#endif // TARGET_OS_IPHONE
