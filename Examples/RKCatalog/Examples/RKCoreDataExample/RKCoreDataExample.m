//
//  RKCoreDataExample.m
//  RKCatalog
//
//  Created by Blake Watters on 4/21/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <RestKit/CoreData.h>
#import "RKCoreDataExample.h"

@interface Article : NSManagedObject {
}

@property (nonatomic, retain) NSNumber* articleID;
@property (nonatomic, retain) NSString* title;
@property (nonatomic, retain) NSString* body;

@end

@implementation Article

@dynamic articleID;
@dynamic title;
@dynamic body;

@end

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -

@implementation RKCoreDataExample

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        RKObjectManager* manager = [RKObjectManager objectManagerWithBaseURL:@"http://restkit.org"];
        manager.objectStore = [RKManagedObjectStore objectStoreWithStoreFilename:@"RKCoreDataExample.sqlite"];
        [RKObjectManager setSharedManager:manager];
        
        // Create some starter objects if the database is empty
        if ([Article count:nil] == 0) {
            for (int i = 1; i <= 5; i++) {
                Article* article = [Article object];
                article.articleID = [NSNumber numberWithInt:i];
                article.title = [NSString stringWithFormat:@"Article %d", i];
                article.body = @"This is the body";
                
                // Persist the object store
                [manager.objectStore save];
            }
        }
        
        NSArray* items = [NSArray arrayWithObjects:@"All", @"Sorted", @"By Predicate", @"By ID", nil];
        _segmentedControl = [[UISegmentedControl alloc] initWithItems:items];
        _segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
        _segmentedControl.momentary = NO;
        [_segmentedControl addTarget:self action:@selector(updateTableView) forControlEvents:UIControlEventValueChanged];
        _segmentedControl.selectedSegmentIndex = 0;
    }
    
    return self;
}

- (void)dealloc {
    [_articles release];
    [_segmentedControl release];
    [super dealloc];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 35;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {    
    return _segmentedControl;
}

- (NSFetchRequest*)fetchRequestForSelectedSegment {
    NSFetchRequest* fetchRequest = [Article fetchRequest];
    NSPredicate* predicate = nil;
    
    switch (_segmentedControl.selectedSegmentIndex) {
        // All objects
        case 0:
            // An empty fetch request will return all objects
            // Duplicates the functionality of [Article allObjects]
            break;
        
        // Sorted
        case 1:;
            NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:NO];
            [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
            break;
        
        // By Predicate
        case 2:
            // Duplicates functionality of calling [Article objectsWithPredicate:predicate];
            predicate = [NSPredicate predicateWithFormat:@"title CONTAINS[c] %@", @"2"];
            [fetchRequest setPredicate:predicate];
            break;
        
        // By ID
        case 3:
            // Duplicates functionality of [Article findByAttribute:@"articleID" withValue:[NSNumber numberWithInt:3]];
            predicate = [NSPredicate predicateWithFormat:@"%K = %d", @"articleID", 3];
            [fetchRequest setPredicate:predicate];
            break;
            
        default:            
            break;
    }
    
    return fetchRequest;
}

- (void)updateTableView {
    [_articles release];
    NSFetchRequest* fetchRequest = [self fetchRequestForSelectedSegment];
    _articles = [[Article objectsWithFetchRequest:fetchRequest] retain];
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_articles count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ArticleCell"];
    if (nil == cell) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ArticleCell"] autorelease];
    }
    
    Article* article = [_articles objectAtIndex:indexPath.row];
    cell.textLabel.text = article.title;
    cell.detailTextLabel.text = article.body;
    
    return cell;
}

@end
