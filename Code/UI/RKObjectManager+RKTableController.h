//
//  RKObjectManager+RKTableController.h
//  RestKit
//
//  Created by Blake Watters on 2/23/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKObjectManager.h"

#if TARGET_OS_IPHONE

@class RKTableController, RKFetchedResultsTableController;

/**
 Provides extensions to RKObjectManager for instantiating RKTableController instances
 */
@interface RKObjectManager (RKTableController)

/**
 Creates and returns a table controller object capable of loading remote object representations
 into a UITableView using the RestKit object mapping engine for a given table view controller.

 @param tableViewController A UITableViewController to instantiate a table controller for
 @return An RKTableController instance ready to drive the table view for the provided tableViewController.
 */
- (RKTableController *)tableControllerForTableViewController:(UITableViewController *)tableViewController;

/**
 Creates and returns a table controller object capable of loading remote object representations
 into a UITableView using the RestKit object mapping engine for a given table view and view controller.

 @param tableView The UITableView object that table controller with acts as the delegate and data source for.
 @param viewController The UIViewController that owns the specified tableView.
 @return An RKTableController instance ready to drive the table view for the provided tableViewController.
 */
- (RKTableController *)tableControllerWithTableView:(UITableView *)tableView forViewController:(UIViewController *)viewController;

/**
 Creates and returns a fetched results table controller object capable of loading remote object representations
 stored in Core Data into a UITableView using the RestKit object mapping engine for a given table view controller.

 @param tableViewController A UITableViewController to instantiate a table controller for
 @return An RKFetchedResultsTableController instance ready to drive the table view for the provided tableViewController.
 */
- (RKFetchedResultsTableController *)fetchedResultsTableControllerForTableViewController:(UITableViewController *)tableViewController;

/**
 Creates and returns a table controller object capable of loading remote object representations
 stored in Core Data into a UITableView using the RestKit object mapping engine for a given table view and view controller.

 @param tableView The UITableView object that table controller with acts as the delegate and data source for.
 @param viewController The UIViewController that owns the specified tableView.
 @return An RKFetchedResultsTableController instance ready to drive the table view for the provided tableViewController.
 */
- (RKFetchedResultsTableController *)fetchedResultsTableControllerWithTableView:(UITableView *)tableView forViewController:(UIViewController *)viewController;

@end

#endif
