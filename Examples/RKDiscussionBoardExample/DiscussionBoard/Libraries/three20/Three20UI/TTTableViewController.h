//
// Copyright 2009-2010 Facebook
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

// UI
#import "Three20UI/TTModelViewController.h"

@protocol TTTableViewDataSource;
@class TTActivityLabel;

@interface TTTableViewController : TTModelViewController {
  UITableView*  _tableView;
  UIView*       _tableBannerView;
  UIView*       _tableOverlayView;
  UIView*       _loadingView;
  UIView*       _errorView;
  UIView*       _emptyView;

  NSTimer*      _bannerTimer;

  UIView*           _menuView;
  UITableViewCell*  _menuCell;

  UITableViewStyle        _tableViewStyle;

  UIInterfaceOrientation  _lastInterfaceOrientation;

  BOOL _variableHeightRows;
  BOOL _showTableShadows;

  id<TTTableViewDataSource> _dataSource;
  id<UITableViewDelegate>   _tableDelegate;
}

@property (nonatomic, retain) IBOutlet UITableView* tableView;

/**
 * A view that is displayed as a banner at the bottom of the table view.
 */
@property (nonatomic, retain) UIView* tableBannerView;

/**
 * A view that is displayed over the table view.
 */
@property (nonatomic, retain) UIView* tableOverlayView;

@property (nonatomic, retain) UIView* loadingView;
@property (nonatomic, retain) UIView* errorView;
@property (nonatomic, retain) UIView* emptyView;

@property (nonatomic, readonly) UIView* menuView;

/**
 * The data source used to populate the table view.
 *
 * Setting dataSource has the side effect of also setting model to the value of the
 * dataSource's model property.
 */
@property (nonatomic, retain) id<TTTableViewDataSource> dataSource;

/**
 * The style of the table view.
 */
@property (nonatomic) UITableViewStyle tableViewStyle;

/**
 * Indicates if the table should support non-fixed row heights.
 */
@property (nonatomic) BOOL variableHeightRows;

/**
 * When enabled, draws gutter shadows above the first table item and below the last table item.
 *
 * Known issues: When there aren't enough cell items to fill the screen, the table view draws
 * empty cells for the remaining space. This causes the bottom shadow to appear out of place.
 */
@property (nonatomic) BOOL showTableShadows;

/**
 * Initializes and returns a controller having the given style.
 */
- (id)initWithStyle:(UITableViewStyle)style;

/**
 * Creates an delegate for the table view.
 *
 * Subclasses can override this to provide their own table delegate implementation.
 */
- (id<UITableViewDelegate>)createDelegate;

/**
 * Sets the view that is displayed at the bottom of the table view with an optional animation.
 */
- (void)setTableBannerView:(UIView*)tableBannerView animated:(BOOL)animated;

/**
 * Shows a menu over a table cell.
 */
- (void)showMenu:(UIView*)view forCell:(UITableViewCell*)cell animated:(BOOL)animated;

/**
 * Hides the currently visible table cell menu.
 */
- (void)hideMenu:(BOOL)animated;

/**
 * Tells the controller that the user selected an object in the table.
 *
 * By default, the object's URLValue will be opened in TTNavigator, if it has one. If you don't
 * want this to be happen, be sure to override this method and be sure not to call super.
 */
- (void)didSelectObject:(id)object atIndexPath:(NSIndexPath*)indexPath;

/**
 * Asks if a URL from that user touched in the table should be opened.
 */
- (BOOL)shouldOpenURL:(NSString*)URL;

/**
 * Tells the controller that the user began dragging the table view.
 */
- (void)didBeginDragging;

/**
 * Tells the controller that the user stopped dragging the table view.
 */
- (void)didEndDragging;

/**
 * The rectangle where the overlay view should appear.
 */
- (CGRect)rectForOverlayView;

/**
 * The rectangle where the banner view should appear.
 */
- (CGRect)rectForBannerView;

@end
