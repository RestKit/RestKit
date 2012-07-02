//
//  RKObjectManager+RKTableController.m
//  RestKit
//
//  Created by Blake Watters on 2/23/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKObjectManager+RKTableController.h"

#if TARGET_OS_IPHONE

#import "RKTableController.h"
#import "RKFetchedResultsTableController.h"

@implementation RKObjectManager (RKTableController)

- (RKTableController *)tableControllerForTableViewController:(UITableViewController *)tableViewController
{
    RKTableController *tableController = [RKTableController tableControllerForTableViewController:tableViewController];
    tableController.objectManager = self;
    return tableController;
}

- (RKTableController *)tableControllerWithTableView:(UITableView *)tableView forViewController:(UIViewController *)viewController
{
    RKTableController *tableController = [RKTableController tableControllerWithTableView:tableView forViewController:viewController];
    tableController.objectManager = self;
    return tableController;
}

- (RKFetchedResultsTableController *)fetchedResultsTableControllerForTableViewController:(UITableViewController *)tableViewController
{
    RKFetchedResultsTableController *tableController = [RKFetchedResultsTableController tableControllerForTableViewController:tableViewController];
    tableController.objectManager = self;
    return tableController;
}

- (RKFetchedResultsTableController *)fetchedResultsTableControllerWithTableView:(UITableView *)tableView forViewController:(UIViewController *)viewController
{
    RKFetchedResultsTableController *tableController = [RKFetchedResultsTableController tableControllerWithTableView:tableView forViewController:viewController];
    return tableController;
}

@end

#endif
