//
//  RKFetchedResultsTableControllerSpec.m
//  RestKit
//
//  Created by Jeff Arena on 8/12/11.
//  Copyright 2011 RestKit. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKFetchedResultsTableController.h"
#import "RKManagedObjectStore.h"
#import "RKManagedObjectMapping.h"
#import "RKHuman.h"
#import "RKManagedObjectCache.h"
#import "RKAbstractTableController_Internals.h"

// Expose the object loader delegate for testing purposes...
@interface RKFetchedResultsTableController () <RKObjectLoaderDelegate>

- (BOOL)isHeaderSection:(NSUInteger)section;
- (BOOL)isHeaderRow:(NSUInteger)row;
- (BOOL)isFooterSection:(NSUInteger)section;
- (BOOL)isFooterRow:(NSUInteger)row;
- (BOOL)isEmptySection:(NSUInteger)section;
- (BOOL)isEmptyRow:(NSUInteger)row;
- (BOOL)isHeaderIndexPath:(NSIndexPath*)indexPath;
- (BOOL)isFooterIndexPath:(NSIndexPath*)indexPath;
- (BOOL)isEmptyItemIndexPath:(NSIndexPath*)indexPath;
- (NSIndexPath*)fetchedResultsIndexPathForIndexPath:(NSIndexPath*)indexPath;

@end

@interface RKFetchedResultsTableControllerSpecViewController : UIViewController
@end

@implementation RKFetchedResultsTableControllerSpecViewController
@end

@interface RKFetchedResultsTableControllerSpec : RKSpec <RKSpecUI> {
    NSAutoreleasePool *_autoreleasePool;
}

@end

@implementation RKFetchedResultsTableControllerSpec

- (void)before {
    _autoreleasePool = [NSAutoreleasePool new];
}

- (void)after {
    [_autoreleasePool drain];
    _autoreleasePool = nil;
}

- (void)bootstrapStoreAndCache {
    RKLogConfigureByName("RestKit/UI", RKLogLevelTrace);
    RKManagedObjectStore* store = RKSpecNewManagedObjectStore();
    RKManagedObjectMapping* humanMapping = [RKManagedObjectMapping mappingForEntityWithName:@"RKHuman" inManagedObjectStore:store];
    [humanMapping mapKeyPath:@"id" toAttribute:@"railsID"];
    [humanMapping mapAttributes:@"name", nil];
    humanMapping.primaryKeyAttribute = @"railsID";

    [RKHuman truncateAll];
    assertThatInt([RKHuman count:nil], is(equalToInt(0)));
    RKHuman* blake = [RKHuman createEntity];
    blake.railsID = [NSNumber numberWithInt:1234];
    blake.name = @"blake";
    RKHuman* other = [RKHuman createEntity];
    other.railsID = [NSNumber numberWithInt:5678];
    other.name = @"other";
    NSError* error = [store save];
    assertThat(error, is(nilValue()));
    assertThatInt([RKHuman count:nil], is(equalToInt(2)));

    RKObjectManager* objectManager = RKSpecNewObjectManager();
    [objectManager.mappingProvider setMapping:humanMapping forKeyPath:@"human"];
    objectManager.objectStore = store;

    id mockObjectCache = [OCMockObject mockForProtocol:@protocol(RKManagedObjectCache)];
    [[[mockObjectCache stub] andReturn:[RKHuman requestAllSortedBy:@"name" ascending:YES]] fetchRequestForResourcePath:@"/JSON/humans/all.json"];
    objectManager.objectStore.managedObjectCache = mockObjectCache;
}

- (void)bootstrapEmptyStoreAndCache {
    RKLogConfigureByName("RestKit/UI", RKLogLevelTrace);
    RKManagedObjectStore* store = RKSpecNewManagedObjectStore();
    RKManagedObjectMapping* humanMapping = [RKManagedObjectMapping mappingForEntityWithName:@"RKHuman" inManagedObjectStore:store];
    [humanMapping mapKeyPath:@"id" toAttribute:@"railsID"];
    [humanMapping mapAttributes:@"name", nil];
    humanMapping.primaryKeyAttribute = @"railsID";

    [RKHuman truncateAll];
    assertThatInt([RKHuman count:nil], is(equalToInt(0)));

    RKObjectManager* objectManager = RKSpecNewObjectManager();
    [objectManager.mappingProvider setMapping:humanMapping forKeyPath:@"human"];
    objectManager.objectStore = store;

    id mockObjectCache = [OCMockObject niceMockForProtocol:@protocol(RKManagedObjectCache)];
    [[[mockObjectCache stub] andReturn:[RKHuman requestAllSortedBy:@"name" ascending:YES]] fetchRequestForResourcePath:@"/JSON/humans/all.json"];
    [[[mockObjectCache stub] andReturn:[RKHuman requestAllSortedBy:@"name" ascending:YES]] fetchRequestForResourcePath:@"/empty/array"];
    objectManager.objectStore.managedObjectCache = mockObjectCache;
}

- (void)itShouldLoadWithATableViewControllerAndResourcePath {
    [self bootstrapStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    [tableViewModel loadTable];

    assertThat(tableViewModel.viewController, is(equalTo(viewController)));
    assertThat(tableViewModel.tableView, is(equalTo(tableView)));
    assertThat(tableViewModel.resourcePath, is(equalTo(@"/JSON/humans/all.json")));
}

- (void)itShouldLoadWithATableViewControllerAndResourcePathAndPredicateAndSortDescriptors {
    [self bootstrapStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    NSPredicate* predicate = [NSPredicate predicateWithValue:TRUE];
    NSArray* sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name"
                                                                                      ascending:YES]];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    tableViewModel.predicate = predicate;
    tableViewModel.sortDescriptors = sortDescriptors;
    [tableViewModel loadTable];

    assertThat(tableViewModel.viewController, is(equalTo(viewController)));
    assertThat(tableViewModel.tableView, is(equalTo(tableView)));
    assertThat(tableViewModel.resourcePath, is(equalTo(@"/JSON/humans/all.json")));
    assertThat(tableViewModel.fetchRequest, is(notNilValue()));
    assertThat([tableViewModel.fetchRequest predicate], is(equalTo(predicate)));
    assertThat([tableViewModel.fetchRequest sortDescriptors], is(equalTo(sortDescriptors)));
}

- (void)itShouldLoadWithATableViewControllerAndResourcePathAndSectionNameAndCacheName {
    [self bootstrapStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    tableViewModel.sectionNameKeyPath = @"name";
    tableViewModel.cacheName = @"allHumansCache";
    [tableViewModel loadTable];

    assertThat(tableViewModel.viewController, is(equalTo(viewController)));
    assertThat(tableViewModel.tableView, is(equalTo(tableView)));
    assertThat(tableViewModel.resourcePath, is(equalTo(@"/JSON/humans/all.json")));
    assertThat(tableViewModel.fetchRequest, is(notNilValue()));
    assertThat(tableViewModel.fetchedResultsController.sectionNameKeyPath, is(equalTo(@"name")));
    assertThat(tableViewModel.fetchedResultsController.cacheName, is(equalTo(@"allHumansCache")));
}

- (void)itShouldLoadWithAllParams {
    [self bootstrapStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    NSPredicate* predicate = [NSPredicate predicateWithValue:TRUE];
    NSArray* sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name"
                                                                                      ascending:YES]];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    tableViewModel.predicate = predicate;
    tableViewModel.sortDescriptors = sortDescriptors;
    tableViewModel.sectionNameKeyPath = @"name";
    tableViewModel.cacheName = @"allHumansCache";
    [tableViewModel loadTable];

    assertThat(tableViewModel.viewController, is(equalTo(viewController)));
    assertThat(tableViewModel.tableView, is(equalTo(tableView)));
    assertThat(tableViewModel.resourcePath, is(equalTo(@"/JSON/humans/all.json")));
    assertThat(tableViewModel.fetchRequest, is(notNilValue()));
    assertThat([tableViewModel.fetchRequest predicate], is(equalTo(predicate)));
    assertThat([tableViewModel.fetchRequest sortDescriptors], is(equalTo(sortDescriptors)));
    assertThat(tableViewModel.fetchedResultsController.sectionNameKeyPath, is(equalTo(@"name")));
    assertThat(tableViewModel.fetchedResultsController.cacheName, is(equalTo(@"allHumansCache")));
}

- (void)itShouldAlwaysHaveAtLeastOneSection {
    [self bootstrapStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    [tableViewModel loadTable];

    assertThatInt(tableViewModel.sectionCount, is(equalToInt(1)));
}

#pragma mark - Section Management

- (void)itShouldProperlyCountSections {
    [self bootstrapStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    tableViewModel.sectionNameKeyPath = @"name";
    [tableViewModel loadTable];
    assertThatInt(tableViewModel.sectionCount, is(equalToInt(2)));
}

- (void)itShouldProperlyCountRows {
    [self bootstrapStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    [tableViewModel loadTable];
    assertThatInt([tableViewModel rowCount], is(equalToInt(2)));
}

- (void)itShouldProperlyCountRowsWithHeaderItems {
    [self bootstrapStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    [tableViewModel addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableViewModel loadTable];
    assertThatInt([tableViewModel rowCount], is(equalToInt(3)));
}

- (void)itShouldProperlyCountRowsWithEmptyItemWhenEmpty {
    [self bootstrapEmptyStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    [tableViewModel setEmptyItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableViewModel loadTable];
    assertThatInt([tableViewModel rowCount], is(equalToInt(1)));
}

- (void)itShouldProperlyCountRowsWithEmptyItemWhenFull {
    [self bootstrapStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    [tableViewModel setEmptyItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableViewModel loadTable];
    assertThatInt([tableViewModel rowCount], is(equalToInt(2)));
}

- (void)itShouldProperlyCountRowsWithHeaderAndEmptyItemsWhenEmptyDontShowHeaders {
    [self bootstrapEmptyStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    [tableViewModel addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    tableViewModel.showsHeaderRowsWhenEmpty = NO;
    [tableViewModel setEmptyItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableViewModel loadTable];
    assertThatInt([tableViewModel rowCount], is(equalToInt(1)));
}

- (void)itShouldProperlyCountRowsWithHeaderAndEmptyItemsWhenEmptyShowHeaders {
    [self bootstrapEmptyStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    [tableViewModel addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    tableViewModel.showsHeaderRowsWhenEmpty = YES;
    [tableViewModel setEmptyItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableViewModel loadTable];
    assertThatInt([tableViewModel rowCount], is(equalToInt(2)));
}

- (void)itShouldProperlyCountRowsWithHeaderAndEmptyItemsWhenFull {
    [self bootstrapStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    [tableViewModel addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableViewModel setEmptyItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableViewModel loadTable];
    assertThatInt([tableViewModel rowCount], is(equalToInt(3)));
}

#pragma mark - UITableViewDataSource specs

- (void)itShouldRaiseAnExceptionIfSentAMessageWithATableViewItIsNotBoundTo {
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel = [RKFetchedResultsTableController tableControllerWithTableView:tableView forViewController:viewController];
    NSException* exception = nil;
    @try {
        [tableViewModel numberOfSectionsInTableView:[UITableView new]];
    }
    @catch (NSException* e) {
        exception = e;
    }
    @finally {
        assertThat(exception, is(notNilValue()));
    }
}

- (void)itShouldReturnTheNumberOfSectionsInTableView {
    [self bootstrapStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    tableViewModel.sectionNameKeyPath = @"name";
    [tableViewModel loadTable];

    assertThatInt([tableViewModel numberOfSectionsInTableView:tableView], is(equalToInt(2)));
}

- (void)itShouldReturnTheNumberOfRowsInSectionInTableView {
    [self bootstrapStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    [tableViewModel loadTable];

    assertThatInt([tableViewModel tableView:tableView numberOfRowsInSection:0], is(equalToInt(2)));
}

- (void)itShouldReturnTheHeaderTitleForSection {
    [self bootstrapStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    tableViewModel.sectionNameKeyPath = @"name";
    [tableViewModel loadTable];

    assertThat([tableViewModel tableView:tableView titleForHeaderInSection:1], is(equalTo(@"other")));
}

- (void)itShouldReturnTheTableViewCellForRowAtIndexPath {
    [self bootstrapStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    [tableViewModel loadTable];

    RKTableViewCellMapping* cellMapping = [RKTableViewCellMapping mappingForClass:[UITableViewCell class]];
    [cellMapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
    RKTableViewCellMappings* mappings = [RKTableViewCellMappings new];
    [mappings setCellMapping:cellMapping forClass:[RKHuman class]];
    tableViewModel.cellMappings = mappings;

    UITableViewCell* cell = [tableViewModel tableView:tableViewModel.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThat(cell.textLabel.text, is(equalTo(@"blake")));
}

#pragma mark - Table Cell Mapping

- (void)itShouldReturnTheObjectForARowAtIndexPath {
    [self bootstrapStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    [tableViewModel loadTable];

    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    RKHuman* blake = [RKHuman findFirstByAttribute:@"name" withValue:@"blake"];
    assertThatBool(blake == [tableViewModel objectForRowAtIndexPath:indexPath], is(equalToBool(YES)));
}

#pragma mark - Editing

- (void)itShouldFireADeleteRequestWhenTheCanEditRowsPropertyIsSet {
    [self bootstrapStoreAndCache];
    [[RKObjectManager sharedManager].router routeClass:[RKHuman class]
                                        toResourcePath:@"/humans/(railsID)"
                                             forMethod:RKRequestMethodDELETE];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    tableViewModel.canEditRows = YES;
    [tableViewModel loadTable];

    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:1 inSection:0];
    NSIndexPath* deleteIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    RKHuman* blake = [RKHuman findFirstByAttribute:@"name" withValue:@"blake"];
    RKHuman* other = [RKHuman findFirstByAttribute:@"name" withValue:@"other"];

    assertThatInt([tableViewModel rowCount], is(equalToInt(2)));
    assertThat([tableViewModel objectForRowAtIndexPath:indexPath], is(equalTo(other)));
    assertThat([tableViewModel objectForRowAtIndexPath:deleteIndexPath], is(equalTo(blake)));
    BOOL delegateCanEdit = [tableViewModel tableView:tableViewModel.tableView
                               canEditRowAtIndexPath:deleteIndexPath];
    assertThatBool(delegateCanEdit, is(equalToBool(YES)));

//    RKSpecNotificationObserver* observer = [RKSpecNotificationObserver notificationObserverForNotificationName:RKRequestDidLoadResponseNotification];
    [RKSpecNotificationObserver waitForNotificationWithName:RKRequestDidLoadResponseNotification usingBlock:^{
        [tableViewModel tableView:tableViewModel.tableView
               commitEditingStyle:UITableViewCellEditingStyleDelete
                forRowAtIndexPath:deleteIndexPath];
    }];
//    observer.timeout = 30;

    assertThatInt([tableViewModel rowCount], is(equalToInt(1)));
    assertThat([tableViewModel objectForRowAtIndexPath:deleteIndexPath], is(equalTo(other)));
    assertThatBool([blake isDeleted], is(equalToBool(YES)));
}

- (void)itShouldLocallyCommitADeleteWhenTheCanEditRowsPropertyIsSet {
    [self bootstrapStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    tableViewModel.canEditRows = YES;
    [tableViewModel loadTable];

    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    NSIndexPath* deleteIndexPath = [NSIndexPath indexPathForRow:1 inSection:0];
    RKHuman* blake = [RKHuman findFirstByAttribute:@"name" withValue:@"blake"];
    RKHuman* other = [RKHuman findFirstByAttribute:@"name" withValue:@"other"];
    blake.railsID = nil;
    other.railsID = nil;

    NSError* error = nil;
    [blake.managedObjectContext save:&error];
    assertThat(error, is(nilValue()));

    assertThatInt([tableViewModel rowCount], is(equalToInt(2)));
    assertThat([tableViewModel objectForRowAtIndexPath:indexPath], is(equalTo(blake)));
    assertThat([tableViewModel objectForRowAtIndexPath:deleteIndexPath], is(equalTo(other)));
    BOOL delegateCanEdit = [tableViewModel tableView:tableViewModel.tableView
                               canEditRowAtIndexPath:deleteIndexPath];
    assertThatBool(delegateCanEdit, is(equalToBool(YES)));
    [tableViewModel tableView:tableViewModel.tableView
           commitEditingStyle:UITableViewCellEditingStyleDelete
            forRowAtIndexPath:deleteIndexPath];
    assertThatInt([tableViewModel rowCount], is(equalToInt(1)));
    assertThat([tableViewModel objectForRowAtIndexPath:indexPath], is(equalTo(blake)));
}

- (void)itShouldNotCommitADeletionWhenTheCanEditRowsPropertyIsNotSet {
    [self bootstrapStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    [tableViewModel loadTable];

    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    RKHuman* blake = [RKHuman findFirstByAttribute:@"name" withValue:@"blake"];
    RKHuman* other = [RKHuman findFirstByAttribute:@"name" withValue:@"other"];

    assertThatInt([tableViewModel rowCount], is(equalToInt(2)));
    BOOL delegateCanEdit = [tableViewModel tableView:tableViewModel.tableView
                               canEditRowAtIndexPath:indexPath];
    assertThatBool(delegateCanEdit, is(equalToBool(NO)));
    [tableViewModel tableView:tableViewModel.tableView
           commitEditingStyle:UITableViewCellEditingStyleDelete
            forRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    assertThatInt([tableViewModel rowCount], is(equalToInt(2)));
    assertThat([tableViewModel objectForRowAtIndexPath:indexPath], is(equalTo(blake)));
    assertThat([tableViewModel objectForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]],
               is(equalTo(other)));
}

- (void)itShouldDoNothingToCommitAnInsertionWhenTheCanEditRowsPropertyIsSet {
    [self bootstrapStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    tableViewModel.canEditRows = YES;
    [tableViewModel loadTable];

    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    RKHuman* blake = [RKHuman findFirstByAttribute:@"name" withValue:@"blake"];
    RKHuman* other = [RKHuman findFirstByAttribute:@"name" withValue:@"other"];

    assertThatInt([tableViewModel rowCount], is(equalToInt(2)));
    BOOL delegateCanEdit = [tableViewModel tableView:tableViewModel.tableView
                               canEditRowAtIndexPath:indexPath];
    assertThatBool(delegateCanEdit, is(equalToBool(YES)));
    [tableViewModel tableView:tableViewModel.tableView
           commitEditingStyle:UITableViewCellEditingStyleInsert
            forRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    assertThatInt([tableViewModel rowCount], is(equalToInt(2)));
    assertThat([tableViewModel objectForRowAtIndexPath:indexPath], is(equalTo(blake)));
    assertThat([tableViewModel objectForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]],
               is(equalTo(other)));
}

- (void)itShouldNotMoveARowWhenTheCanMoveRowsPropertyIsSet {
    [self bootstrapStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    tableViewModel.canMoveRows = YES;
    [tableViewModel loadTable];

    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    RKHuman* blake = [RKHuman findFirstByAttribute:@"name" withValue:@"blake"];
    RKHuman* other = [RKHuman findFirstByAttribute:@"name" withValue:@"other"];

    assertThatInt([tableViewModel rowCount], is(equalToInt(2)));
    BOOL delegateCanMove = [tableViewModel tableView:tableViewModel.tableView
                               canMoveRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatBool(delegateCanMove, is(equalToBool(YES)));
    [tableViewModel tableView:tableViewModel.tableView
           moveRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                  toIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    assertThatInt([tableViewModel rowCount], is(equalToInt(2)));
    assertThat([tableViewModel objectForRowAtIndexPath:indexPath], is(equalTo(blake)));
    assertThat([tableViewModel objectForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]],
               is(equalTo(other)));
}

#pragma mark - Header, Footer, and Empty Rows

- (void)itShouldDetermineIfASectionIndexIsAHeaderSection {
    [self bootstrapEmptyStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    [tableViewModel loadTable];
    assertThatBool([tableViewModel isHeaderSection:0], is(equalToBool(YES)));
    assertThatBool([tableViewModel isHeaderSection:1], is(equalToBool(NO)));
    assertThatBool([tableViewModel isHeaderSection:2], is(equalToBool(NO)));
}

- (void)itShouldDetermineIfARowIndexIsAHeaderRow {
    [self bootstrapStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    [tableViewModel addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableViewModel loadTable];
    assertThatBool([tableViewModel isHeaderRow:0], is(equalToBool(YES)));
    assertThatBool([tableViewModel isHeaderRow:1], is(equalToBool(NO)));
    assertThatBool([tableViewModel isHeaderRow:2], is(equalToBool(NO)));
}

- (void)itShouldDetermineIfASectionIndexIsAFooterSectionSingleSection {
    [self bootstrapStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    [tableViewModel addFooterRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableViewModel loadTable];
    assertThatBool([tableViewModel isFooterSection:0], is(equalToBool(YES)));
    assertThatBool([tableViewModel isFooterSection:1], is(equalToBool(NO)));
    assertThatBool([tableViewModel isFooterSection:2], is(equalToBool(NO)));
}

- (void)itShouldDetermineIfASectionIndexIsAFooterSectionMultipleSections {
    [self bootstrapStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    tableViewModel.sectionNameKeyPath = @"name";
    [tableViewModel addFooterRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableViewModel loadTable];
    assertThatBool([tableViewModel isFooterSection:0], is(equalToBool(NO)));
    assertThatBool([tableViewModel isFooterSection:1], is(equalToBool(YES)));
    assertThatBool([tableViewModel isFooterSection:2], is(equalToBool(NO)));
}

- (void)itShouldDetermineIfARowIndexIsAFooterRow {
    [self bootstrapStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    [tableViewModel addFooterRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableViewModel loadTable];
    assertThatBool([tableViewModel isFooterRow:0], is(equalToBool(NO)));
    assertThatBool([tableViewModel isFooterRow:1], is(equalToBool(NO)));
    assertThatBool([tableViewModel isFooterRow:2], is(equalToBool(YES)));
}

- (void)itShouldDetermineIfASectionIndexIsAnEmptySection {
    [self bootstrapEmptyStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    [tableViewModel loadTable];
    assertThatBool([tableViewModel isEmptySection:0], is(equalToBool(YES)));
    assertThatBool([tableViewModel isEmptySection:1], is(equalToBool(NO)));
    assertThatBool([tableViewModel isEmptySection:2], is(equalToBool(NO)));
}

- (void)itShouldDetermineIfARowIndexIsAnEmptyRow {
    [self bootstrapEmptyStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    [tableViewModel loadTable];
    assertThatBool([tableViewModel isEmptyRow:0], is(equalToBool(YES)));
    assertThatBool([tableViewModel isEmptyRow:1], is(equalToBool(NO)));
    assertThatBool([tableViewModel isEmptyRow:2], is(equalToBool(NO)));
}

- (void)itShouldDetermineIfAnIndexPathIsAHeaderIndexPath {
    [self bootstrapStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    [tableViewModel addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableViewModel loadTable];
    assertThatBool([tableViewModel isHeaderIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], is(equalToBool(YES)));
    assertThatBool([tableViewModel isHeaderIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalToBool(NO)));
    assertThatBool([tableViewModel isHeaderIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]], is(equalToBool(NO)));
    assertThatBool([tableViewModel isHeaderIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]], is(equalToBool(NO)));
    assertThatBool([tableViewModel isHeaderIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]], is(equalToBool(NO)));
    assertThatBool([tableViewModel isHeaderIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]], is(equalToBool(NO)));
}

- (void)itShouldDetermineIfAnIndexPathIsAFooterIndexPath {
    [self bootstrapStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    [tableViewModel addFooterRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableViewModel loadTable];
    assertThatBool([tableViewModel isFooterIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], is(equalToBool(NO)));
    assertThatBool([tableViewModel isFooterIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalToBool(NO)));
    assertThatBool([tableViewModel isFooterIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]], is(equalToBool(YES)));
    assertThatBool([tableViewModel isFooterIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]], is(equalToBool(NO)));
    assertThatBool([tableViewModel isFooterIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]], is(equalToBool(NO)));
    assertThatBool([tableViewModel isFooterIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]], is(equalToBool(NO)));
}

- (void)itShouldDetermineIfAnIndexPathIsAnEmptyIndexPathSingleSectionEmptyItemOnly {
    [self bootstrapEmptyStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    [tableViewModel setEmptyItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableViewModel loadTable];
    assertThatBool([tableViewModel isEmptyItemIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], is(equalToBool(YES)));
    assertThatBool([tableViewModel isEmptyItemIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalToBool(NO)));
    assertThatBool([tableViewModel isEmptyItemIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]], is(equalToBool(NO)));
    assertThatBool([tableViewModel isEmptyItemIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]], is(equalToBool(NO)));
    assertThatBool([tableViewModel isEmptyItemIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]], is(equalToBool(NO)));
    assertThatBool([tableViewModel isEmptyItemIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]], is(equalToBool(NO)));
}

- (void)itShouldConvertAnIndexPathForHeaderRows {
    [self bootstrapStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    [tableViewModel addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableViewModel loadTable];
    assertThat([tableViewModel fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:0])));
    assertThat([tableViewModel fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:0])));
    assertThat([tableViewModel fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:1 inSection:0])));
    assertThat([tableViewModel fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:2 inSection:0])));
}

- (void)itShouldConvertAnIndexPathForFooterRowsSingleSection {
    [self bootstrapStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    [tableViewModel addFooterRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableViewModel loadTable];
    assertThat([tableViewModel fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:0])));
    assertThat([tableViewModel fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:1 inSection:0])));
    assertThat([tableViewModel fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:2 inSection:0])));
}

- (void)itShouldConvertAnIndexPathForFooterRowsMultipleSections {
    [self bootstrapStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    tableViewModel.sectionNameKeyPath = @"name";
    [tableViewModel addFooterRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableViewModel loadTable];
    assertThat([tableViewModel fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:0])));
    assertThat([tableViewModel fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:1 inSection:0])));
    assertThat([tableViewModel fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:1])));
    assertThat([tableViewModel fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]], is(equalTo([NSIndexPath indexPathForRow:1 inSection:1])));
}

- (void)itShouldConvertAnIndexPathForEmptyRow {
    [self bootstrapStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    [tableViewModel setEmptyItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableViewModel loadTable];
    assertThat([tableViewModel fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:0])));
    assertThat([tableViewModel fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:1 inSection:0])));
    assertThat([tableViewModel fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:2 inSection:0])));
    assertThat([tableViewModel fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:3 inSection:0])));
}

- (void)itShouldConvertAnIndexPathForHeaderFooterRowsSingleSection {
    [self bootstrapStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    [tableViewModel addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableViewModel addFooterRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableViewModel loadTable];
    assertThat([tableViewModel fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:0])));
    assertThat([tableViewModel fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:0])));
    assertThat([tableViewModel fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:1 inSection:0])));
    assertThat([tableViewModel fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:2 inSection:0])));
}

- (void)itShouldConvertAnIndexPathForHeaderFooterRowsMultipleSections {
    [self bootstrapStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    tableViewModel.sectionNameKeyPath = @"name";
    [tableViewModel addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableViewModel addFooterRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableViewModel loadTable];
    assertThat([tableViewModel fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:0])));
    assertThat([tableViewModel fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:0])));
    assertThat([tableViewModel fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:1])));
    assertThat([tableViewModel fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]], is(equalTo([NSIndexPath indexPathForRow:1 inSection:1])));
    assertThat([tableViewModel fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]], is(equalTo([NSIndexPath indexPathForRow:2 inSection:1])));
}

- (void)itShouldConvertAnIndexPathForHeaderFooterEmptyRowsSingleSection {
    [self bootstrapStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    [tableViewModel addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableViewModel addFooterRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableViewModel setEmptyItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableViewModel loadTable];
    assertThat([tableViewModel fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:0])));
    assertThat([tableViewModel fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:1 inSection:0])));
    assertThat([tableViewModel fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:2 inSection:0])));
    assertThat([tableViewModel fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:4 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:3 inSection:0])));
    assertThat([tableViewModel fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:5 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:4 inSection:0])));
}

- (void)itShouldConvertAnIndexPathForHeaderFooterEmptyRowsMultipleSections {
    [self bootstrapStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    tableViewModel.sectionNameKeyPath = @"name";
    [tableViewModel addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableViewModel addFooterRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableViewModel setEmptyItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableViewModel loadTable];
    assertThat([tableViewModel fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:0])));
    assertThat([tableViewModel fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:1])));
    assertThat([tableViewModel fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]], is(equalTo([NSIndexPath indexPathForRow:1 inSection:1])));
    assertThat([tableViewModel fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]], is(equalTo([NSIndexPath indexPathForRow:2 inSection:1])));
}

- (void)itShouldConvertAnIndexPathForHeaderEmptyRows {
    [self bootstrapStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    [tableViewModel addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableViewModel setEmptyItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableViewModel loadTable];
    assertThat([tableViewModel fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:0])));
    assertThat([tableViewModel fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:1 inSection:0])));
    assertThat([tableViewModel fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:2 inSection:0])));
}

- (void)itShouldShowHeaderRows {
    [self bootstrapStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    RKTableItem* headerRow = [RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }];
    [tableViewModel addHeaderRowForItem:headerRow];
    tableViewModel.showsHeaderRowsWhenEmpty = NO;
    tableViewModel.showsFooterRowsWhenEmpty = NO;
    [tableViewModel loadTable];

    RKHuman* blake = [RKHuman findFirstByAttribute:@"name" withValue:@"blake"];
    RKHuman* other = [RKHuman findFirstByAttribute:@"name" withValue:@"other"];

    assertThatInt([tableViewModel rowCount], is(equalToInt(3)));
    assertThat([tableViewModel objectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], is(equalTo(headerRow)));
    assertThat([tableViewModel objectForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalTo(blake)));
    assertThat([tableViewModel objectForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]],
               is(equalTo(other)));
}

- (void)itShouldShowFooterRows {
    [self bootstrapStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    RKTableItem* footerRow = [RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }];
    [tableViewModel addFooterRowForItem:footerRow];
    tableViewModel.showsHeaderRowsWhenEmpty = NO;
    tableViewModel.showsFooterRowsWhenEmpty = NO;
    [tableViewModel loadTable];

    RKHuman* blake = [RKHuman findFirstByAttribute:@"name" withValue:@"blake"];
    RKHuman* other = [RKHuman findFirstByAttribute:@"name" withValue:@"other"];

    assertThatInt([tableViewModel rowCount], is(equalToInt(3)));
    assertThat([tableViewModel objectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], is(equalTo(blake)));
    assertThat([tableViewModel objectForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalTo(other)));
    assertThat([tableViewModel objectForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]],
               is(equalTo(footerRow)));
}

- (void)itShouldHideHeaderRowsWhenEmptyWhenPropertyIsNotSet {
    [self bootstrapEmptyStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    [tableViewModel addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    tableViewModel.showsHeaderRowsWhenEmpty = NO;
    tableViewModel.showsFooterRowsWhenEmpty = NO;
    [tableViewModel loadTable];

    assertThatBool(tableViewModel.isLoaded, is(equalToBool(YES)));
    assertThatInt([tableViewModel rowCount], is(equalToInt(0)));
    assertThatBool(tableViewModel.isEmpty, is(equalToBool(YES)));
}

- (void)itShouldHideFooterRowsWhenEmptyWhenPropertyIsNotSet {
    [self bootstrapEmptyStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    [tableViewModel addFooterRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    tableViewModel.showsHeaderRowsWhenEmpty = NO;
    tableViewModel.showsFooterRowsWhenEmpty = NO;
    [tableViewModel loadTable];

    assertThatBool(tableViewModel.isLoaded, is(equalToBool(YES)));
    assertThatInt([tableViewModel rowCount], is(equalToInt(0)));
    assertThatBool(tableViewModel.isEmpty, is(equalToBool(YES)));
}

- (void)itShouldRemoveHeaderAndFooterCountsWhenDeterminingIsEmpty {
    [self bootstrapEmptyStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    [tableViewModel addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableViewModel addFooterRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableViewModel setEmptyItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    tableViewModel.showsHeaderRowsWhenEmpty = NO;
    tableViewModel.showsFooterRowsWhenEmpty = NO;
    [tableViewModel loadTable];

    assertThatBool(tableViewModel.isLoaded, is(equalToBool(YES)));
    assertThatInt([tableViewModel rowCount], is(equalToInt(1)));
    assertThatBool(tableViewModel.isEmpty, is(equalToBool(YES)));
}

- (void)itShouldNotShowTheEmptyItemWhenTheTableIsNotEmpty {
    [self bootstrapStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";

    RKTableItem* headerRow = [RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }];
    [tableViewModel addHeaderRowForItem:headerRow];

    RKTableItem* footerRow = [RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }];
    [tableViewModel addFooterRowForItem:footerRow];

    RKTableItem* emptyItem = [RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }];
    [tableViewModel setEmptyItem:emptyItem];
    tableViewModel.showsHeaderRowsWhenEmpty = NO;
    tableViewModel.showsFooterRowsWhenEmpty = NO;
    [tableViewModel loadTable];

    RKHuman* blake = [RKHuman findFirstByAttribute:@"name" withValue:@"blake"];
    RKHuman* other = [RKHuman findFirstByAttribute:@"name" withValue:@"other"];

    assertThatInt([tableViewModel rowCount], is(equalToInt(4)));
    assertThat([tableViewModel objectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], is(equalTo(headerRow)));
    assertThat([tableViewModel objectForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalTo(blake)));
    assertThat([tableViewModel objectForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]], is(equalTo(other)));
    assertThat([tableViewModel objectForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]],
               is(equalTo(footerRow)));
}

- (void)itShouldShowTheEmptyItemWhenTheTableIsEmpty {
    [self bootstrapEmptyStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    [tableViewModel addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableViewModel addFooterRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableViewModel setEmptyItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    tableViewModel.showsHeaderRowsWhenEmpty = NO;
    tableViewModel.showsFooterRowsWhenEmpty = NO;
    [tableViewModel loadTable];

    assertThatBool(tableViewModel.isLoaded, is(equalToBool(YES)));
    assertThatInt([tableViewModel rowCount], is(equalToInt(1)));
    assertThatBool(tableViewModel.isEmpty, is(equalToBool(YES)));
}

- (void)itShouldShowTheEmptyItemPlusHeadersAndFootersWhenTheTableIsEmpty {
    [self bootstrapEmptyStoreAndCache];
    UITableView* tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                               viewController:viewController];
    tableViewModel.resourcePath = @"/JSON/humans/all.json";
    [tableViewModel addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableViewModel addFooterRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableViewModel setEmptyItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    tableViewModel.showsHeaderRowsWhenEmpty = YES;
    tableViewModel.showsFooterRowsWhenEmpty = YES;
    [tableViewModel loadTable];

    assertThatBool(tableViewModel.isLoaded, is(equalToBool(YES)));
    assertThatInt([tableViewModel rowCount], is(equalToInt(3)));
    assertThatBool(tableViewModel.isEmpty, is(equalToBool(YES)));
}

- (void)itShouldShowTheEmptyImageAfterLoadingAnEmptyCollectionIntoAnEmptyFetch {
    [self bootstrapEmptyStoreAndCache];
    
    RKObjectManager *objectManager = [RKObjectManager sharedManager];
    id mockManager = [OCMockObject partialMockForObject:objectManager];
    [mockManager setExpectationOrderMatters:YES];
    RKObjectManagerNetworkStatus networkStatus = RKObjectManagerNetworkStatusOnline;
    [[[mockManager stub] andReturnValue:OCMOCK_VALUE(networkStatus)] networkStatus];
    BOOL online = YES; // Initial online state for table
    [[[mockManager stub] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    
    UITableView* tableView = [UITableView new];
    
    RKFetchedResultsTableControllerSpecViewController* viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController* tableViewModel = [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                                                                viewController:viewController];
    tableViewModel.imageForEmpty = [UIImage imageNamed:@"blake.png"];
    tableViewModel.resourcePath = @"/empty/array";
    tableViewModel.autoRefreshFromNetwork = YES;
    [tableViewModel.cache invalidateAll];
    
    RKLogConfigureByName("RestKit/Network", RKLogLevelTrace);
    [RKSpecNotificationObserver waitForNotificationWithName:RKTableControllerDidFinishLoadNotification usingBlock:^{
        [tableViewModel loadTable];
    }];
    assertThatBool(tableViewModel.isLoaded, is(equalToBool(YES)));
    assertThatInt([tableViewModel rowCount], is(equalToInt(0)));
    assertThatBool(tableViewModel.isEmpty, is(equalToBool(YES)));
    assertThat(tableViewModel.stateOverlayImageView.image, is(notNilValue()));    
}

@end
