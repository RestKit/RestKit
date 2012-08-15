//
//  RKCoreDataExample.m
//  RKCatalog
//
//  Created by Blake Watters on 4/21/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import <RestKit/CoreData.h>
#import "RKCoreDataExample.h"

@interface Article : NSManagedObject {
}

@property (nonatomic, retain) NSNumber *articleID;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *body;

@end

@implementation Article

@dynamic articleID;
@dynamic title;
@dynamic body;

@end

@interface RKCoreDataExample ()
@property (nonatomic, readwrite, retain) NSArray *articles;
@property (nonatomic, readwrite, retain) UISegmentedControl *segmentedControl;
@end

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation RKCoreDataExample

@synthesize articles = _articles;
@synthesize segmentedControl = _segmentedControl;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        NSURL *baseURL = [NSURL URLWithString:@"http://restkit.org"];
        RKObjectManager *manager = [RKObjectManager managerWithBaseURL:baseURL];
        
        // Create the managed object store and add a SQLite persistent store
        NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
        RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:managedObjectModel];
        NSString *storePath = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"RKCoreDataExample.sqlite"];
        NSError *error;
        NSPersistentStore *persistentStore = [managedObjectStore addSQLitePersistentStoreAtPath:storePath fromSeedDatabaseAtPath:nil error:&error];
        NSAssert(persistentStore, @"Failed to create SQLite store at path %@ due to error: %@", storePath, error);
        manager.managedObjectStore = managedObjectStore;
        [managedObjectStore release];
        
        // Once we are done with configuration, ask the store to create the primary and main queue contexts
        [managedObjectStore createManagedObjectContexts];
        
        [RKManagedObjectStore setDefaultStore:managedObjectStore];
        [RKObjectManager setSharedManager:manager];

        // Create some starter objects if the database is empty
        NSUInteger count = [managedObjectStore.mainQueueManagedObjectContext countForEntityForName:@"Article" predicate:nil error:&error];
        if (count == 0) {
            for (int i = 1; i <= 5; i++) {
                Article *article = [managedObjectStore.mainQueueManagedObjectContext insertNewObjectForEntityForName:@"Article"];
                article.articleID = [NSNumber numberWithInt:i];
                article.title = [NSString stringWithFormat:@"Article %d", i];
                article.body = @"This is the body";
            }
            
            // Persist the new objects
            BOOL success = [managedObjectStore.mainQueueManagedObjectContext saveToPersistentStore:&error];
            NSAssert(success, @"Failed to persist manged object context due to error: %@", error);
        }

        NSArray *items = [NSArray arrayWithObjects:@"All", @"Sorted", @"By Predicate", @"By ID", nil];
        self.segmentedControl = [[[UISegmentedControl alloc] initWithItems:items] autorelease];
        self.segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
        self.segmentedControl.momentary = NO;
        [self.segmentedControl addTarget:self action:@selector(updateTableView) forControlEvents:UIControlEventValueChanged];
        self.segmentedControl.selectedSegmentIndex = 0;
    }

    return self;
}

- (void)dealloc
{
    [_articles release];
    [_segmentedControl release];
    [super dealloc];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 35;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return _segmentedControl;
}

- (NSFetchRequest *)fetchRequestForSelectedSegment
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Article"];
    NSPredicate *predicate = nil;

    switch (_segmentedControl.selectedSegmentIndex) {
        // All objects
        case 0:
            // An empty fetch request will return all objects
            break;

        // Sorted
        case 1:;
            NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:NO];
            [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
            break;

        // By Predicate
        case 2:
            predicate = [NSPredicate predicateWithFormat:@"title CONTAINS[c] %@", @"2"];
            [fetchRequest setPredicate:predicate];
            break;

        // By ID
        case 3:
            predicate = [NSPredicate predicateWithFormat:@"%K = %d", @"articleID", 3];
            [fetchRequest setPredicate:predicate];
            break;

        default:
            break;
    }

    return fetchRequest;
}

- (void)updateTableView
{
    NSError *error;
    NSFetchRequest *fetchRequest = [self fetchRequestForSelectedSegment];
    self.articles = [[RKManagedObjectStore defaultStore].mainQueueManagedObjectContext executeFetchRequest:fetchRequest error:&error];
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_articles count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ArticleCell"];
    if (nil == cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ArticleCell"] autorelease];
    }

    Article *article = [_articles objectAtIndex:indexPath.row];
    cell.textLabel.text = article.title;
    cell.detailTextLabel.text = article.body;

    return cell;
}

@end
