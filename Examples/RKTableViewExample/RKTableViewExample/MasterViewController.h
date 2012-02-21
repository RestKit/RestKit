//
//  MasterViewController.h
//  RKTableViewExample
//
//  Created by Blake Watters on 8/2/11.
//  Copyright 2011 RestKit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <RestKit/RestKit.h>
#import <RestKit/UI.h>

@interface MasterViewController : UITableViewController <RKTableControllerDelegate, NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (strong, nonatomic) RKTableController *tableController;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
