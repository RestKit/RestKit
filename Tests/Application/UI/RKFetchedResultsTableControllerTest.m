//
//  RKFetchedResultsTableControllerTest.m
//  RestKit
//
//  Created by Jeff Arena on 8/12/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKFetchedResultsTableController.h"
#import "RKManagedObjectStore.h"
#import "RKManagedObjectMapping.h"
#import "RKHuman.h"
#import "RKEvent.h"
#import "RKAbstractTableController_Internals.h"
#import "RKManagedObjectCaching.h"
#import "RKTableControllerTestDelegate.h"

// Expose the object loader delegate for testing purposes...
@interface RKFetchedResultsTableController () <RKObjectLoaderDelegate>

- (BOOL)isHeaderSection:(NSUInteger)section;
- (BOOL)isHeaderRow:(NSUInteger)row;
- (BOOL)isFooterSection:(NSUInteger)section;
- (BOOL)isFooterRow:(NSUInteger)row;
- (BOOL)isEmptySection:(NSUInteger)section;
- (BOOL)isEmptyRow:(NSUInteger)row;
- (BOOL)isHeaderIndexPath:(NSIndexPath *)indexPath;
- (BOOL)isFooterIndexPath:(NSIndexPath *)indexPath;
- (BOOL)isEmptyItemIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)fetchedResultsIndexPathForIndexPath:(NSIndexPath *)indexPath;

@end

@interface RKFetchedResultsTableControllerSpecViewController : UITableViewController
@end

@implementation RKFetchedResultsTableControllerSpecViewController
@end

@interface RKFetchedResultsTableControllerTest : RKTestCase
@end

@implementation RKFetchedResultsTableControllerTest

- (void)setUp
{
    [RKTestFactory setUp];

    [[[[UIApplication sharedApplication] windows] objectAtIndex:0] setRootViewController:nil];
}

- (void)tearDown
{
    [RKTestFactory tearDown];
}

- (void)bootstrapStoreAndCache
{
    RKManagedObjectStore *store = [RKTestFactory managedObjectStore];
    RKManagedObjectMapping *humanMapping = [RKManagedObjectMapping mappingForEntityWithName:@"RKHuman" inManagedObjectStore:store];
    [humanMapping mapKeyPath:@"id" toAttribute:@"railsID"];
    [humanMapping mapAttributes:@"name", nil];
    humanMapping.primaryKeyAttribute = @"railsID";

    [RKHuman truncateAll];
    assertThatInt([RKHuman count:nil], is(equalToInt(0)));
    RKHuman *blake = [RKHuman createEntity];
    blake.railsID = [NSNumber numberWithInt:1234];
    blake.name = @"blake";
    RKHuman *other = [RKHuman createEntity];
    other.railsID = [NSNumber numberWithInt:5678];
    other.name = @"other";
    NSError *error = nil;
    [store save:&error];
    assertThat(error, is(nilValue()));
    assertThatInt([RKHuman count:nil], is(equalToInt(2)));

    RKObjectManager *objectManager = [RKTestFactory objectManager];
    [objectManager.mappingProvider setMapping:humanMapping forKeyPath:@"human"];
    objectManager.objectStore = store;

    [objectManager.mappingProvider setObjectMapping:humanMapping forResourcePathPattern:@"/JSON/humans/all\\.json" withFetchRequestBlock:^NSFetchRequest *(NSString *resourcePath) {
        return [RKHuman requestAllSortedBy:@"name" ascending:YES];
    }];
}

- (void)bootstrapNakedObjectStoreAndCache
{
    RKManagedObjectStore *store = [RKTestFactory managedObjectStore];
    RKManagedObjectMapping *eventMapping = [RKManagedObjectMapping mappingForClass:[RKEvent class] inManagedObjectStore:store];
    [eventMapping mapKeyPath:@"event_id" toAttribute:@"eventID"];
    [eventMapping mapKeyPath:@"type" toAttribute:@"eventType"];
    [eventMapping mapAttributes:@"location", @"summary", nil];
    eventMapping.primaryKeyAttribute = @"eventID";
    [RKEvent truncateAll];

    assertThatInt([RKEvent count:nil], is(equalToInt(0)));
    RKEvent *nakedEvent = [RKEvent createEntity];
    nakedEvent.eventID = @"RK4424";
    nakedEvent.eventType = @"Concert";
    nakedEvent.location = @"Performance Hall";
    nakedEvent.summary = @"Shindig";
    NSError *error = nil;
    [store save:&error];
    assertThat(error, is(nilValue()));
    assertThatInt([RKEvent count:nil], is(equalToInt(1)));

    RKObjectManager *objectManager = [RKTestFactory objectManager];
    [objectManager.mappingProvider addObjectMapping:eventMapping];
    objectManager.objectStore = store;

    id mockMappingProvider = [OCMockObject partialMockForObject:objectManager.mappingProvider];
    [[[mockMappingProvider stub] andReturn:[RKEvent requestAllSortedBy:@"eventType" ascending:YES]] fetchRequestForResourcePath:@"/JSON/NakedEvents.json"];
}

- (void)bootstrapEmptyStoreAndCache
{
    RKManagedObjectStore *store = [RKTestFactory managedObjectStore];
    RKManagedObjectMapping *humanMapping = [RKManagedObjectMapping mappingForEntityWithName:@"RKHuman" inManagedObjectStore:store];
    [humanMapping mapKeyPath:@"id" toAttribute:@"railsID"];
    [humanMapping mapAttributes:@"name", nil];
    humanMapping.primaryKeyAttribute = @"railsID";

    [RKHuman truncateAll];
    assertThatInt([RKHuman count:nil], is(equalToInt(0)));

    RKObjectManager *objectManager = [RKTestFactory objectManager];
    [objectManager.mappingProvider setMapping:humanMapping forKeyPath:@"human"];
    objectManager.objectStore = store;

    id mockMappingProvider = [OCMockObject partialMockForObject:objectManager.mappingProvider];
    [[[mockMappingProvider stub] andReturn:[RKHuman requestAllSortedBy:@"name" ascending:YES]] fetchRequestForResourcePath:@"/JSON/humans/all.json"];
    [[[mockMappingProvider stub] andReturn:[RKHuman requestAllSortedBy:@"name" ascending:YES]] fetchRequestForResourcePath:@"/empty/array"];
}

- (void)stubObjectManagerToOnline
{
    RKObjectManager *objectManager = [RKObjectManager sharedManager];
    id mockManager = [OCMockObject partialMockForObject:objectManager];
    [mockManager setExpectationOrderMatters:YES];
    RKObjectManagerNetworkStatus networkStatus = RKObjectManagerNetworkStatusOnline;
    [[[mockManager stub] andReturnValue:OCMOCK_VALUE(networkStatus)] networkStatus];
    BOOL online = YES; // Initial online state for table
    [[[mockManager stub] andReturnValue:OCMOCK_VALUE(online)] isOnline];
}

- (void)testLoadWithATableViewControllerAndResourcePath
{
    [self bootstrapStoreAndCache];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController = [RKFetchedResultsTableController tableControllerForTableViewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController loadTable];

    assertThat(tableController.viewController, is(equalTo(viewController)));
    assertThat(tableController.tableView, is(equalTo(viewController.tableView)));
    assertThat(tableController.resourcePath, is(equalTo(@"/JSON/humans/all.json")));
}

- (void)testLoadWithATableViewControllerAndResourcePathFromNakedObjects
{
    [self bootstrapNakedObjectStoreAndCache];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController = [RKFetchedResultsTableController tableControllerForTableViewController:viewController];
    tableController.resourcePath = @"/JSON/NakedEvents.json";
    [tableController setObjectMappingForClass:[RKEvent class]];
    [tableController loadTable];

    assertThat(tableController.viewController, is(equalTo(viewController)));
    assertThat(tableController.tableView, is(equalTo(viewController.tableView)));
    assertThat(tableController.resourcePath, is(equalTo(@"/JSON/NakedEvents.json")));

    RKTableViewCellMapping *cellMapping = [RKTableViewCellMapping mappingForClass:[UITableViewCell class]];
    [cellMapping mapKeyPath:@"summary" toAttribute:@"textLabel.text"];
    RKTableViewCellMappings *mappings = [RKTableViewCellMappings new];
    [mappings setCellMapping:cellMapping forClass:[RKEvent class]];
    tableController.cellMappings = mappings;

    UITableViewCell *cell = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThat(cell.textLabel.text, is(equalTo(@"Shindig")));
}


- (void)testLoadWithATableViewControllerAndResourcePathAndPredicateAndSortDescriptors
{
    [self bootstrapStoreAndCache];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    NSPredicate *predicate = [NSPredicate predicateWithValue:TRUE];
    NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name"
                                                                                      ascending:YES]];
    RKFetchedResultsTableController *tableController = [RKFetchedResultsTableController tableControllerForTableViewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    tableController.predicate = predicate;
    tableController.sortDescriptors = sortDescriptors;
    [tableController loadTable];

    assertThat(tableController.viewController, is(equalTo(viewController)));
    assertThat(tableController.resourcePath, is(equalTo(@"/JSON/humans/all.json")));
    assertThat(tableController.fetchRequest, is(notNilValue()));
    assertThat([tableController.fetchRequest predicate], is(equalTo(predicate)));
    assertThat([tableController.fetchRequest sortDescriptors], is(equalTo(sortDescriptors)));
}

- (void)testLoadWithATableViewControllerAndResourcePathAndSectionNameAndCacheName
{
    [self bootstrapStoreAndCache];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController = [RKFetchedResultsTableController tableControllerForTableViewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    tableController.sectionNameKeyPath = @"name";
    tableController.cacheName = @"allHumansCache";
    [tableController loadTable];

    assertThat(tableController.viewController, is(equalTo(viewController)));
    assertThat(tableController.resourcePath, is(equalTo(@"/JSON/humans/all.json")));
    assertThat(tableController.fetchRequest, is(notNilValue()));
    assertThat(tableController.fetchedResultsController.sectionNameKeyPath, is(equalTo(@"name")));
    assertThat(tableController.fetchedResultsController.cacheName, is(equalTo(@"allHumansCache")));
}

- (void)testLoadWithAllParams
{
    [self bootstrapStoreAndCache];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    NSPredicate *predicate = [NSPredicate predicateWithValue:TRUE];
    NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name"
                                                                                      ascending:YES]];
    RKFetchedResultsTableController *tableController = [RKFetchedResultsTableController tableControllerForTableViewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    tableController.predicate = predicate;
    tableController.sortDescriptors = sortDescriptors;
    tableController.sectionNameKeyPath = @"name";
    tableController.cacheName = @"allHumansCache";
    [tableController loadTable];

    assertThat(tableController.viewController, is(equalTo(viewController)));
    assertThat(tableController.resourcePath, is(equalTo(@"/JSON/humans/all.json")));
    assertThat(tableController.fetchRequest, is(notNilValue()));
    assertThat([tableController.fetchRequest predicate], is(equalTo(predicate)));
    assertThat([tableController.fetchRequest sortDescriptors], is(equalTo(sortDescriptors)));
    assertThat(tableController.fetchedResultsController.sectionNameKeyPath, is(equalTo(@"name")));
    assertThat(tableController.fetchedResultsController.cacheName, is(equalTo(@"allHumansCache")));
}

- (void)testAlwaysHaveAtLeastOneSection
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController loadTable];

    assertThatInt(tableController.sectionCount, is(equalToInt(1)));
}

#pragma mark - Section Management

- (void)testProperlyCountSections
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    tableController.sectionNameKeyPath = @"name";
    [tableController loadTable];
    assertThatInt(tableController.sectionCount, is(equalToInt(2)));
}

- (void)testProperlyCountRows
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController loadTable];
    assertThatInt([tableController rowCount], is(equalToInt(2)));
}

- (void)testProperlyCountRowsWithHeaderItems
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThatInt([tableController rowCount], is(equalToInt(3)));
}

- (void)testProperlyCountRowsWithEmptyItemWhenEmpty
{
    [self bootstrapEmptyStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController setEmptyItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThatInt([tableController rowCount], is(equalToInt(1)));
}

- (void)testProperlyCountRowsWithEmptyItemWhenFull
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController setEmptyItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThatInt([tableController rowCount], is(equalToInt(2)));
}

- (void)testProperlyCountRowsWithHeaderAndEmptyItemsWhenEmptyDontShowHeaders
{
    [self bootstrapEmptyStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    tableController.showsHeaderRowsWhenEmpty = NO;
    [tableController setEmptyItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThatInt([tableController rowCount], is(equalToInt(1)));
}

- (void)testProperlyCountRowsWithHeaderAndEmptyItemsWhenEmptyShowHeaders
{
    [self bootstrapEmptyStoreAndCache];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController = [RKFetchedResultsTableController tableControllerForTableViewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    tableController.showsHeaderRowsWhenEmpty = YES;
    [tableController setEmptyItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThatInt([tableController rowCount], is(equalToInt(2)));
}

- (void)testProperlyCountRowsWithHeaderAndEmptyItemsWhenFull
{
    [self bootstrapStoreAndCache];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController = [RKFetchedResultsTableController tableControllerForTableViewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController setEmptyItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThatInt([tableController rowCount], is(equalToInt(3)));
}

#pragma mark - UITableViewDataSource specs

- (void)testRaiseAnExceptionIfSentAMessageWithATableViewItIsNotBoundTo
{
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController = [RKFetchedResultsTableController tableControllerWithTableView:tableView forViewController:viewController];
    NSException *exception = nil;
    @try {
        [tableController numberOfSectionsInTableView:[UITableView new]];
    }
    @catch (NSException *e) {
        exception = e;
    }
    @finally {
        assertThat(exception, is(notNilValue()));
    }
}

- (void)testReturnTheNumberOfSectionsInTableView
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    tableController.sectionNameKeyPath = @"name";
    [tableController loadTable];

    assertThatInt([tableController numberOfSectionsInTableView:tableView], is(equalToInt(2)));
}

- (void)testReturnTheNumberOfRowsInSectionInTableView
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController loadTable];

    assertThatInt([tableController tableView:tableView numberOfRowsInSection:0], is(equalToInt(2)));
}

- (void)testReturnTheHeaderTitleForSection
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    tableController.sectionNameKeyPath = @"name";
    [tableController loadTable];

    assertThat([tableController tableView:tableView titleForHeaderInSection:1], is(equalTo(@"other")));
}

- (void)testReturnTheTableViewCellForRowAtIndexPath
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController loadTable];

    RKTableViewCellMapping *cellMapping = [RKTableViewCellMapping mappingForClass:[UITableViewCell class]];
    [cellMapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
    RKTableViewCellMappings *mappings = [RKTableViewCellMappings new];
    [mappings setCellMapping:cellMapping forClass:[RKHuman class]];
    tableController.cellMappings = mappings;

    UITableViewCell *cell = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThat(cell.textLabel.text, is(equalTo(@"blake")));
}

#pragma mark - Table Cell Mapping

- (void)testReturnTheObjectForARowAtIndexPath
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController loadTable];

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    RKHuman *blake = [RKHuman findFirstByAttribute:@"name" withValue:@"blake"];
    assertThatBool(blake == [tableController objectForRowAtIndexPath:indexPath], is(equalToBool(YES)));
    [tableController release];
}

#pragma mark - Editing

- (void)testFireADeleteRequestWhenTheCanEditRowsPropertyIsSet
{
    [self bootstrapStoreAndCache];
    [self stubObjectManagerToOnline];
    [[RKObjectManager sharedManager].router routeClass:[RKHuman class]
                                        toResourcePath:@"/humans/:railsID"
                                             forMethod:RKRequestMethodDELETE];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController = [RKFetchedResultsTableController tableControllerForTableViewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    tableController.canEditRows = YES;
    RKTableViewCellMapping *cellMapping = [RKTableViewCellMapping cellMapping];
    [cellMapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
    [tableController mapObjectsWithClass:[RKHuman class] toTableCellsWithMapping:cellMapping];
    [tableController loadTable];

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1 inSection:0];
    NSIndexPath *deleteIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    RKHuman *blake = [RKHuman findFirstByAttribute:@"name" withValue:@"blake"];
    RKHuman *other = [RKHuman findFirstByAttribute:@"name" withValue:@"other"];

    assertThatInt([tableController rowCount], is(equalToInt(2)));
    assertThat([tableController objectForRowAtIndexPath:indexPath], is(equalTo(other)));
    assertThat([tableController objectForRowAtIndexPath:deleteIndexPath], is(equalTo(blake)));
    BOOL delegateCanEdit = [tableController tableView:tableController.tableView
                                canEditRowAtIndexPath:deleteIndexPath];
    assertThatBool(delegateCanEdit, is(equalToBool(YES)));

    [RKTestNotificationObserver waitForNotificationWithName:RKRequestDidLoadResponseNotification usingBlock:^{
        [tableController tableView:tableController.tableView
                commitEditingStyle:UITableViewCellEditingStyleDelete
                 forRowAtIndexPath:deleteIndexPath];
    }];

    assertThatInt([tableController rowCount], is(equalToInt(1)));
    assertThat([tableController objectForRowAtIndexPath:deleteIndexPath], is(equalTo(other)));
    assertThatBool([blake isDeleted], is(equalToBool(YES)));
}

- (void)testLocallyCommitADeleteWhenTheCanEditRowsPropertyIsSet
{
    [self bootstrapStoreAndCache];
    [self stubObjectManagerToOnline];

    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    tableController.canEditRows = YES;
    [tableController loadTable];

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    NSIndexPath *deleteIndexPath = [NSIndexPath indexPathForRow:1 inSection:0];
    RKHuman *blake = [RKHuman findFirstByAttribute:@"name" withValue:@"blake"];
    RKHuman *other = [RKHuman findFirstByAttribute:@"name" withValue:@"other"];
    blake.railsID = nil;
    other.railsID = nil;

    NSError *error = nil;
    [blake.managedObjectContext save:&error];
    assertThat(error, is(nilValue()));

    assertThatInt([tableController rowCount], is(equalToInt(2)));
    assertThat([tableController objectForRowAtIndexPath:indexPath], is(equalTo(blake)));
    assertThat([tableController objectForRowAtIndexPath:deleteIndexPath], is(equalTo(other)));
    BOOL delegateCanEdit = [tableController tableView:tableController.tableView
                                canEditRowAtIndexPath:deleteIndexPath];
    assertThatBool(delegateCanEdit, is(equalToBool(YES)));
    [tableController tableView:tableController.tableView
            commitEditingStyle:UITableViewCellEditingStyleDelete
             forRowAtIndexPath:deleteIndexPath];
    assertThatInt([tableController rowCount], is(equalToInt(1)));
    assertThat([tableController objectForRowAtIndexPath:indexPath], is(equalTo(blake)));
}

- (void)testNotCommitADeletionWhenTheCanEditRowsPropertyIsNotSet
{
    [self bootstrapStoreAndCache];
    [self stubObjectManagerToOnline];

    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController loadTable];

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    RKHuman *blake = [RKHuman findFirstByAttribute:@"name" withValue:@"blake"];
    RKHuman *other = [RKHuman findFirstByAttribute:@"name" withValue:@"other"];

    assertThatInt([tableController rowCount], is(equalToInt(2)));
    BOOL delegateCanEdit = [tableController tableView:tableController.tableView
                                canEditRowAtIndexPath:indexPath];
    assertThatBool(delegateCanEdit, is(equalToBool(NO)));
    [tableController tableView:tableController.tableView
            commitEditingStyle:UITableViewCellEditingStyleDelete
             forRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    assertThatInt([tableController rowCount], is(equalToInt(2)));
    assertThat([tableController objectForRowAtIndexPath:indexPath], is(equalTo(blake)));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]],
               is(equalTo(other)));
}

- (void)testDoNothingToCommitAnInsertionWhenTheCanEditRowsPropertyIsSet
{
    [self bootstrapStoreAndCache];
    [self stubObjectManagerToOnline];

    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    tableController.canEditRows = YES;
    [tableController loadTable];

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    RKHuman *blake = [RKHuman findFirstByAttribute:@"name" withValue:@"blake"];
    RKHuman *other = [RKHuman findFirstByAttribute:@"name" withValue:@"other"];

    assertThatInt([tableController rowCount], is(equalToInt(2)));
    BOOL delegateCanEdit = [tableController tableView:tableController.tableView
                                canEditRowAtIndexPath:indexPath];
    assertThatBool(delegateCanEdit, is(equalToBool(YES)));
    [tableController tableView:tableController.tableView
            commitEditingStyle:UITableViewCellEditingStyleInsert
             forRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    assertThatInt([tableController rowCount], is(equalToInt(2)));
    assertThat([tableController objectForRowAtIndexPath:indexPath], is(equalTo(blake)));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]],
               is(equalTo(other)));
}

- (void)testNotMoveARowWhenTheCanMoveRowsPropertyIsSet
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    tableController.canMoveRows = YES;
    [tableController loadTable];

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    RKHuman *blake = [RKHuman findFirstByAttribute:@"name" withValue:@"blake"];
    RKHuman *other = [RKHuman findFirstByAttribute:@"name" withValue:@"other"];

    assertThatInt([tableController rowCount], is(equalToInt(2)));
    BOOL delegateCanMove = [tableController tableView:tableController.tableView
                                canMoveRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatBool(delegateCanMove, is(equalToBool(YES)));
    [tableController tableView:tableController.tableView
            moveRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                   toIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    assertThatInt([tableController rowCount], is(equalToInt(2)));
    assertThat([tableController objectForRowAtIndexPath:indexPath], is(equalTo(blake)));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]],
               is(equalTo(other)));
}

#pragma mark - Header, Footer, and Empty Rows

- (void)testDetermineIfASectionIndexIsAHeaderSection
{
    [self bootstrapEmptyStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController loadTable];
    assertThatBool([tableController isHeaderSection:0], is(equalToBool(YES)));
    assertThatBool([tableController isHeaderSection:1], is(equalToBool(NO)));
    assertThatBool([tableController isHeaderSection:2], is(equalToBool(NO)));
}

- (void)testDetermineIfARowIndexIsAHeaderRow
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThatBool([tableController isHeaderRow:0], is(equalToBool(YES)));
    assertThatBool([tableController isHeaderRow:1], is(equalToBool(NO)));
    assertThatBool([tableController isHeaderRow:2], is(equalToBool(NO)));
}

- (void)testDetermineIfASectionIndexIsAFooterSectionSingleSection
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController addFooterRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThatBool([tableController isFooterSection:0], is(equalToBool(YES)));
    assertThatBool([tableController isFooterSection:1], is(equalToBool(NO)));
    assertThatBool([tableController isFooterSection:2], is(equalToBool(NO)));
}

- (void)testDetermineIfASectionIndexIsAFooterSectionMultipleSections
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    tableController.sectionNameKeyPath = @"name";
    [tableController addFooterRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThatBool([tableController isFooterSection:0], is(equalToBool(NO)));
    assertThatBool([tableController isFooterSection:1], is(equalToBool(YES)));
    assertThatBool([tableController isFooterSection:2], is(equalToBool(NO)));
}

- (void)testDetermineIfARowIndexIsAFooterRow
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController addFooterRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThatBool([tableController isFooterRow:0], is(equalToBool(NO)));
    assertThatBool([tableController isFooterRow:1], is(equalToBool(NO)));
    assertThatBool([tableController isFooterRow:2], is(equalToBool(YES)));
}

- (void)testDetermineIfASectionIndexIsAnEmptySection
{
    [self bootstrapEmptyStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController loadTable];
    assertThatBool([tableController isEmptySection:0], is(equalToBool(YES)));
    assertThatBool([tableController isEmptySection:1], is(equalToBool(NO)));
    assertThatBool([tableController isEmptySection:2], is(equalToBool(NO)));
}

- (void)testDetermineIfARowIndexIsAnEmptyRow
{
    [self bootstrapEmptyStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController loadTable];
    assertThatBool([tableController isEmptyRow:0], is(equalToBool(YES)));
    assertThatBool([tableController isEmptyRow:1], is(equalToBool(NO)));
    assertThatBool([tableController isEmptyRow:2], is(equalToBool(NO)));
}

- (void)testDetermineIfAnIndexPathIsAHeaderIndexPath
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThatBool([tableController isHeaderIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], is(equalToBool(YES)));
    assertThatBool([tableController isHeaderIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalToBool(NO)));
    assertThatBool([tableController isHeaderIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]], is(equalToBool(NO)));
    assertThatBool([tableController isHeaderIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]], is(equalToBool(NO)));
    assertThatBool([tableController isHeaderIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]], is(equalToBool(NO)));
    assertThatBool([tableController isHeaderIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]], is(equalToBool(NO)));
}

- (void)testDetermineIfAnIndexPathIsAFooterIndexPath
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController addFooterRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThatBool([tableController isFooterIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], is(equalToBool(NO)));
    assertThatBool([tableController isFooterIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalToBool(NO)));
    assertThatBool([tableController isFooterIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]], is(equalToBool(YES)));
    assertThatBool([tableController isFooterIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]], is(equalToBool(NO)));
    assertThatBool([tableController isFooterIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]], is(equalToBool(NO)));
    assertThatBool([tableController isFooterIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]], is(equalToBool(NO)));
}

- (void)testDetermineIfAnIndexPathIsAnEmptyIndexPathSingleSectionEmptyItemOnly
{
    [self bootstrapEmptyStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController setEmptyItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThatBool([tableController isEmptyItemIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], is(equalToBool(YES)));
    assertThatBool([tableController isEmptyItemIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalToBool(NO)));
    assertThatBool([tableController isEmptyItemIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]], is(equalToBool(NO)));
    assertThatBool([tableController isEmptyItemIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]], is(equalToBool(NO)));
    assertThatBool([tableController isEmptyItemIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]], is(equalToBool(NO)));
    assertThatBool([tableController isEmptyItemIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]], is(equalToBool(NO)));
}

- (void)testConvertAnIndexPathForHeaderRows
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:1 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:2 inSection:0])));
}

- (void)testConvertAnIndexPathForFooterRowsSingleSection
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController addFooterRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:1 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:2 inSection:0])));
}

- (void)testConvertAnIndexPathForFooterRowsMultipleSections
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    tableController.sectionNameKeyPath = @"name";
    [tableController addFooterRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:1 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:1])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]], is(equalTo([NSIndexPath indexPathForRow:1 inSection:1])));
}

- (void)testConvertAnIndexPathForEmptyRow
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController setEmptyItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:1 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:2 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:3 inSection:0])));
}

- (void)testConvertAnIndexPathForHeaderFooterRowsSingleSection
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController addFooterRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:1 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:2 inSection:0])));
}

- (void)testConvertAnIndexPathForHeaderFooterRowsMultipleSections
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    tableController.sectionNameKeyPath = @"name";
    [tableController addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController addFooterRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:1])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]], is(equalTo([NSIndexPath indexPathForRow:1 inSection:1])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]], is(equalTo([NSIndexPath indexPathForRow:2 inSection:1])));
}

- (void)testConvertAnIndexPathForHeaderFooterEmptyRowsSingleSection
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController addFooterRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController setEmptyItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:1 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:2 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:4 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:3 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:5 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:4 inSection:0])));
}

- (void)testConvertAnIndexPathForHeaderFooterEmptyRowsMultipleSections
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    tableController.sectionNameKeyPath = @"name";
    [tableController addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController addFooterRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController setEmptyItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:1])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]], is(equalTo([NSIndexPath indexPathForRow:1 inSection:1])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:2 inSection:1]], is(equalTo([NSIndexPath indexPathForRow:2 inSection:1])));
}

- (void)testConvertAnIndexPathForHeaderEmptyRows
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController setEmptyItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController loadTable];
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:0 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:1 inSection:0])));
    assertThat([tableController fetchedResultsIndexPathForIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]], is(equalTo([NSIndexPath indexPathForRow:2 inSection:0])));
}

- (void)testShowHeaderRows
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    RKTableItem *headerRow = [RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }];
    [tableController addHeaderRowForItem:headerRow];
    tableController.showsHeaderRowsWhenEmpty = NO;
    tableController.showsFooterRowsWhenEmpty = NO;
    [tableController loadTable];

    RKHuman *blake = [RKHuman findFirstByAttribute:@"name" withValue:@"blake"];
    RKHuman *other = [RKHuman findFirstByAttribute:@"name" withValue:@"other"];

    assertThatInt([tableController rowCount], is(equalToInt(3)));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], is(equalTo(headerRow)));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalTo(blake)));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]],
               is(equalTo(other)));
}

- (void)testShowFooterRows
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    RKTableItem *footerRow = [RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }];
    [tableController addFooterRowForItem:footerRow];
    tableController.showsHeaderRowsWhenEmpty = NO;
    tableController.showsFooterRowsWhenEmpty = NO;
    [tableController loadTable];

    RKHuman *blake = [RKHuman findFirstByAttribute:@"name" withValue:@"blake"];
    RKHuman *other = [RKHuman findFirstByAttribute:@"name" withValue:@"other"];

    assertThatInt([tableController rowCount], is(equalToInt(3)));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], is(equalTo(blake)));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalTo(other)));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]],
               is(equalTo(footerRow)));
}

- (void)testHideHeaderRowsWhenEmptyWhenPropertyIsNotSet
{
    [self bootstrapEmptyStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    tableController.showsHeaderRowsWhenEmpty = NO;
    tableController.showsFooterRowsWhenEmpty = NO;
    [tableController loadTable];

    assertThatBool(tableController.isLoaded, is(equalToBool(YES)));
    assertThatInt([tableController rowCount], is(equalToInt(0)));
    assertThatBool(tableController.isEmpty, is(equalToBool(YES)));
}

- (void)testHideFooterRowsWhenEmptyWhenPropertyIsNotSet
{
    [self bootstrapEmptyStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController addFooterRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    tableController.showsHeaderRowsWhenEmpty = NO;
    tableController.showsFooterRowsWhenEmpty = NO;
    [tableController loadTable];

    assertThatBool(tableController.isLoaded, is(equalToBool(YES)));
    assertThatInt([tableController rowCount], is(equalToInt(0)));
    assertThatBool(tableController.isEmpty, is(equalToBool(YES)));
}

- (void)testRemoveHeaderAndFooterCountsWhenDeterminingIsEmpty
{
    [self bootstrapEmptyStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController addFooterRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController setEmptyItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    tableController.showsHeaderRowsWhenEmpty = NO;
    tableController.showsFooterRowsWhenEmpty = NO;
    [tableController loadTable];

    assertThatBool(tableController.isLoaded, is(equalToBool(YES)));
    assertThatInt([tableController rowCount], is(equalToInt(1)));
    assertThatBool(tableController.isEmpty, is(equalToBool(YES)));
}

- (void)testNotShowTheEmptyItemWhenTheTableIsNotEmpty
{
    [self bootstrapStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";

    RKTableItem *headerRow = [RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }];
    [tableController addHeaderRowForItem:headerRow];

    RKTableItem *footerRow = [RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }];
    [tableController addFooterRowForItem:footerRow];

    RKTableItem *emptyItem = [RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }];
    [tableController setEmptyItem:emptyItem];
    tableController.showsHeaderRowsWhenEmpty = NO;
    tableController.showsFooterRowsWhenEmpty = NO;
    [tableController loadTable];

    RKHuman *blake = [RKHuman findFirstByAttribute:@"name" withValue:@"blake"];
    RKHuman *other = [RKHuman findFirstByAttribute:@"name" withValue:@"other"];

    assertThatInt([tableController rowCount], is(equalToInt(4)));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]], is(equalTo(headerRow)));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]], is(equalTo(blake)));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]], is(equalTo(other)));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]],
               is(equalTo(footerRow)));
}

- (void)testShowTheEmptyItemWhenTheTableIsEmpty
{
    [self bootstrapEmptyStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController addFooterRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController setEmptyItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    tableController.showsHeaderRowsWhenEmpty = NO;
    tableController.showsFooterRowsWhenEmpty = NO;
    [tableController loadTable];

    assertThatBool(tableController.isLoaded, is(equalToBool(YES)));
    assertThatInt([tableController rowCount], is(equalToInt(1)));
    assertThatBool(tableController.isEmpty, is(equalToBool(YES)));
}

- (void)testShowTheEmptyItemPlusHeadersAndFootersWhenTheTableIsEmpty
{
    [self bootstrapEmptyStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/humans/all.json";
    [tableController addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController addFooterRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController setEmptyItem:[RKTableItem tableItemUsingBlock:^(RKTableItem *tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    tableController.showsHeaderRowsWhenEmpty = YES;
    tableController.showsFooterRowsWhenEmpty = YES;
    [tableController loadTable];

    assertThatBool(tableController.isLoaded, is(equalToBool(YES)));
    assertThatInt([tableController rowCount], is(equalToInt(3)));
    assertThatBool(tableController.isEmpty, is(equalToBool(YES)));
}

- (void)testShowTheEmptyImageAfterLoadingAnEmptyCollectionIntoAnEmptyFetch
{
    [self bootstrapEmptyStoreAndCache];
    [self stubObjectManagerToOnline];

    UITableView *tableView = [UITableView new];

    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController = [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                                                                   viewController:viewController];

    UIImage *image = [RKTestFixture imageWithContentsOfFixture:@"blake.png"];

    tableController.imageForEmpty = image;
    tableController.resourcePath = @"/empty/array";
    tableController.autoRefreshFromNetwork = YES;
    [tableController.cache invalidateAll];

    [RKTestNotificationObserver waitForNotificationWithName:RKTableControllerDidFinishLoadNotification usingBlock:^{
        [tableController loadTable];
    }];
    assertThatBool(tableController.isLoaded, is(equalToBool(YES)));
    assertThatInt([tableController rowCount], is(equalToInt(0)));
    assertThatBool(tableController.isEmpty, is(equalToBool(YES)));
    assertThat(tableController.stateOverlayImageView.image, is(notNilValue()));
}

- (void)testPostANotificationWhenObjectsAreLoaded
{
    [self bootstrapNakedObjectStoreAndCache];
    UITableView *tableView = [UITableView new];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:tableView
                                                viewController:viewController];
    tableController.resourcePath = @"/JSON/NakedEvents.json";
    [tableController setObjectMappingForClass:[RKEvent class]];

    id observerMock = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:observerMock name:RKTableControllerDidLoadObjectsNotification object:tableController];
    [[observerMock expect] notificationWithName:RKTableControllerDidLoadObjectsNotification object:tableController];
    [tableController loadTable];
    [observerMock verify];
}

#pragma mark - Delegate Methods

- (void)testDelegateIsInformedOnInsertSection
{
    [self bootstrapStoreAndCache];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:viewController.tableView viewController:viewController];
    RKTableViewCellMapping *cellMapping = [RKTableViewCellMapping cellMapping];
    [cellMapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
    [tableController mapObjectsWithClass:[RKHuman class] toTableCellsWithMapping:cellMapping];
    tableController.resourcePath = @"/JSON/humans/all.json";
    tableController.cacheName = @"allHumansCache";

    RKFetchedResultsTableControllerTestDelegate *delegate = [RKFetchedResultsTableControllerTestDelegate tableControllerDelegate];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[mockDelegate expect] tableController:tableController didInsertSectionAtIndex:0];
    tableController.delegate = mockDelegate;
    [[[[UIApplication sharedApplication] windows] objectAtIndex:0] setRootViewController:viewController];
    [tableController loadTable];
    assertThatInt([tableController rowCount], is(equalToInt(2)));
    assertThatInt([tableController sectionCount], is(equalToInt(1)));
    [mockDelegate verify];
}

- (void)testDelegateIsInformedOfDidStartLoad
{
    [self bootstrapStoreAndCache];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:viewController.tableView viewController:viewController];
    RKTableViewCellMapping *cellMapping = [RKTableViewCellMapping cellMapping];
    [cellMapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
    [tableController mapObjectsWithClass:[RKHuman class] toTableCellsWithMapping:cellMapping];
    tableController.resourcePath = @"/JSON/humans/all.json";
    tableController.cacheName = @"allHumansCache";

    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKFetchedResultsTableControllerDelegate)];
    [[mockDelegate expect] tableControllerDidStartLoad:tableController];
    tableController.delegate = mockDelegate;
    [[[[UIApplication sharedApplication] windows] objectAtIndex:0] setRootViewController:viewController];
    [tableController loadTable];
    [mockDelegate verify];
}

- (void)testDelegateIsInformedOfDidFinishLoad
{
    [self bootstrapStoreAndCache];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:viewController.tableView viewController:viewController];
    RKTableViewCellMapping *cellMapping = [RKTableViewCellMapping cellMapping];
    [cellMapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
    [tableController mapObjectsWithClass:[RKHuman class] toTableCellsWithMapping:cellMapping];
    tableController.resourcePath = @"/JSON/humans/all.json";
    tableController.cacheName = @"allHumansCache";

    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKFetchedResultsTableControllerDelegate)];
    [[mockDelegate expect] tableControllerDidFinishLoad:tableController];
    tableController.delegate = mockDelegate;
    [[[[UIApplication sharedApplication] windows] objectAtIndex:0] setRootViewController:viewController];
    [tableController loadTable];
    [mockDelegate verify];
}

- (void)testDelegateIsInformedOfDidInsertObjectAtIndexPath
{
    [self bootstrapStoreAndCache];
    RKFetchedResultsTableControllerSpecViewController *viewController = [RKFetchedResultsTableControllerSpecViewController new];
    RKFetchedResultsTableController *tableController =
    [[RKFetchedResultsTableController alloc] initWithTableView:viewController.tableView viewController:viewController];
    RKTableViewCellMapping *cellMapping = [RKTableViewCellMapping cellMapping];
    [cellMapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
    [tableController mapObjectsWithClass:[RKHuman class] toTableCellsWithMapping:cellMapping];
    tableController.resourcePath = @"/JSON/humans/all.json";
    tableController.cacheName = @"allHumansCache";

    id mockDelegate = [OCMockObject niceMockForProtocol:@protocol(RKFetchedResultsTableControllerDelegate)];
    [[mockDelegate expect] tableController:tableController didInsertObject:OCMOCK_ANY atIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [[mockDelegate expect] tableController:tableController didInsertObject:OCMOCK_ANY atIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    tableController.delegate = mockDelegate;
    [[[[UIApplication sharedApplication] windows] objectAtIndex:0] setRootViewController:viewController];
    [tableController loadTable];
    [mockDelegate verify];
}

@end
