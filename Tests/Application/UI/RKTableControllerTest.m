//
//  RKTableControllerTest.m
//  RestKit
//
//  Created by Blake Watters on 8/3/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKTableController.h"
#import "RKTableSection.h"
#import "RKTestUser.h"
#import "RKMappableObject.h"
#import "RKAbstractTableController_Internals.h"

// Expose the object loader delegate for testing purposes...
@interface RKTableController () <RKObjectLoaderDelegate>
- (void)animationDidStopAddingSwipeView:(NSString*)animationID finished:(NSNumber*)finished context:(void*)context;
@end

@interface RKTestTableControllerDelegate : NSObject <RKTableControllerDelegate>

@property (nonatomic, assign) NSTimeInterval timeout;
@property (nonatomic, assign) BOOL awaitingResponse;

+ (id)tableControllerDelegate;
- (void)waitForLoad;
@end

@implementation RKTestTableControllerDelegate

@synthesize timeout = _timeout;
@synthesize awaitingResponse = _awaitingResponse;

+ (id)tableControllerDelegate {
    return [[self new] autorelease];
}

- (id)init {
    self = [super init];
	if (self) {
		_timeout = 3;
		_awaitingResponse = NO;
	}

	return self;
}

- (void)waitForLoad {
    _awaitingResponse = YES;
	NSDate* startDate = [NSDate date];

	while (_awaitingResponse) {
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
		if ([[NSDate date] timeIntervalSinceDate:startDate] > self.timeout) {
			[NSException raise:nil format:@"*** Operation timed out after %f seconds...", self.timeout];
			_awaitingResponse = NO;
		}
	}
}

#pragma RKTableControllerDelegate methods

- (void)tableControllerDidFinishLoad:(RKAbstractTableController*)tableController {
    _awaitingResponse = NO;
}

- (void)tableController:(RKAbstractTableController*)tableController didFailLoadWithError:(NSError *)error {
    _awaitingResponse = NO;
}

// NOTE - Delegate methods below are implemented to allow trampoline through
// OCMock expectations

- (void)tableControllerDidStartLoad:(RKAbstractTableController*)tableController {}
- (void)tableControllerDidBecomeEmpty:(RKAbstractTableController*)tableController {}
- (void)tableController:(RKAbstractTableController*)tableController willLoadTableWithObjectLoader:(RKObjectLoader*)objectLoader {}
- (void)tableController:(RKAbstractTableController*)tableController didLoadTableWithObjectLoader:(RKObjectLoader*)objectLoader {}
- (void)tableControllerDidCancelLoad:(RKAbstractTableController*)tableController {}
- (void)tableController:(RKAbstractTableController*)tableController willBeginEditing:(id)object atIndexPath:(NSIndexPath*)indexPath {}
- (void)tableController:(RKAbstractTableController*)tableController didEndEditing:(id)object atIndexPath:(NSIndexPath*)indexPath {}
- (void)tableController:(RKAbstractTableController*)tableController didInsertSection:(RKTableSection*)section atIndex:(NSUInteger)sectionIndex {}
- (void)tableController:(RKAbstractTableController*)tableController didRemoveSection:(RKTableSection*)section atIndex:(NSUInteger)sectionIndex {}
- (void)tableController:(RKAbstractTableController*)tableController didInsertObject:(id)object atIndexPath:(NSIndexPath*)indexPath {}
- (void)tableController:(RKAbstractTableController*)tableController didUpdateObject:(id)object atIndexPath:(NSIndexPath*)indexPath {}
- (void)tableController:(RKAbstractTableController*)tableController didDeleteObject:(id)object atIndexPath:(NSIndexPath*)indexPath {}
- (void)tableController:(RKAbstractTableController*)tableController willAddSwipeView:(UIView*)swipeView toCell:(UITableViewCell*)cell forObject:(id)object {}
- (void)tableController:(RKAbstractTableController*)tableController willRemoveSwipeView:(UIView*)swipeView fromCell:(UITableViewCell*)cell forObject:(id)object {}

@end

@interface RKTableControllerSpecTableViewController : UITableViewController
@end

@implementation RKTableControllerSpecTableViewController
@end

@interface RKTableControllerSpecViewController : UIViewController
@end

@implementation RKTableControllerSpecViewController
@end

@interface RKTestUserTableViewCell : UITableViewCell
@end

@implementation RKTestUserTableViewCell
@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface RKTableControllerTest : SenTestCase {
    NSAutoreleasePool *_autoreleasePool;
}

@end

@implementation RKTableControllerTest

- (void)setUp {
    // Ensure the fixture bundle is configured
    NSBundle *fixtureBundle = [NSBundle bundleWithIdentifier:@"org.restkit.Application-Tests"];
    [RKTestFixture setFixtureBundle:fixtureBundle];

//    [RKObjectManager setSharedManager:nil];
//    _autoreleasePool = [[NSAutoreleasePool alloc] init];
}

- (void)tearDown {
//    [_autoreleasePool drain];
//    _autoreleasePool = nil;
}

- (void)testInitializeWithATableViewController {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    assertThat(viewController.tableView, is(notNilValue()));
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    assertThat(tableController.viewController, is(equalTo(viewController)));
    assertThat(tableController.tableView, is(equalTo(viewController.tableView)));
}

- (void)testInitializeWithATableViewAndViewController {
    UITableView* tableView = [UITableView new];
    RKTableControllerSpecViewController* viewController = [RKTableControllerSpecViewController new];
    RKTableController* tableController = [RKTableController tableControllerWithTableView:tableView forViewController:viewController];
    assertThat(tableController.viewController, is(equalTo(viewController)));
    assertThat(tableController.tableView, is(equalTo(tableView)));
}

- (void)testAlwaysHaveAtLeastOneSection {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    assertThat(viewController.tableView, is(notNilValue()));
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    assertThatInt(tableController.sectionCount, is(equalToInt(1)));
}

- (void)testDisconnectFromTheTableViewOnDealloc {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    assertThatInt(tableController.sectionCount, is(equalToInt(1)));
    [pool drain];
    assertThat(viewController.tableView.delegate, is(nilValue()));
    assertThat(viewController.tableView.dataSource, is(nilValue()));
}

- (void)testNotDisconnectFromTheTableViewIfDelegateOrDataSourceAreNotSelf {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [[RKTableController alloc] initWithTableView:viewController.tableView viewController:viewController];
    viewController.tableView.delegate = viewController;
    viewController.tableView.dataSource = viewController;
    assertThatInt(tableController.sectionCount, is(equalToInt(1)));
    [tableController release];
    assertThat(viewController.tableView.delegate, isNot(nilValue()));
    assertThat(viewController.tableView.dataSource, isNot(nilValue()));
}

#pragma mark - Section Management

- (void)testAddASection {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    RKTableSection* section = [RKTableSection section];
    RKTestTableControllerDelegate* delegate = [RKTestTableControllerDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                  didInsertSection:section
                                                           atIndex:1];
    tableController.delegate = mockDelegate;
    [tableController addSection:section];
    assertThatInt([tableController.sections count], is(equalToInt(2)));
    [mockDelegate verify];
}

- (void)testConnectTheSectionToTheTableModelOnAdd {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    RKTableSection* section = [RKTableSection section];
    RKTestTableControllerDelegate* delegate = [RKTestTableControllerDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                  didInsertSection:section
                                                           atIndex:1];
    tableController.delegate = mockDelegate;
    [tableController addSection:section];
    assertThat(section.tableController, is(equalTo(tableController)));
    [mockDelegate verify];
}

- (void)testConnectTheSectionToTheCellMappingsOfTheTableModelWhenNil {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    RKTableSection* section = [RKTableSection section];
    RKTestTableControllerDelegate* delegate = [RKTestTableControllerDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                  didInsertSection:section
                                                           atIndex:1];
    tableController.delegate = mockDelegate;
    assertThat(section.cellMappings, is(nilValue()));
    [tableController addSection:section];
    assertThat(section.cellMappings, is(equalTo(tableController.cellMappings)));
    [mockDelegate verify];
}

- (void)testNotConnectTheSectionToTheCellMappingsOfTheTableModelWhenNonNil {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    RKTableSection* section = [RKTableSection section];
    RKTestTableControllerDelegate* delegate = [RKTestTableControllerDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                  didInsertSection:section
                                                           atIndex:1];
    tableController.delegate = mockDelegate;
    section.cellMappings = [NSMutableDictionary dictionary];
    [tableController addSection:section];
    assertThatBool(section.cellMappings == tableController.cellMappings, is(equalToBool(NO)));
    [mockDelegate verify];
}

- (void)testCountTheSections {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    RKTableSection* section = [RKTableSection section];
    RKTestTableControllerDelegate* delegate = [RKTestTableControllerDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                  didInsertSection:section
                                                           atIndex:1];
    tableController.delegate = mockDelegate;
    [tableController addSection:section];
    assertThatInt(tableController.sectionCount, is(equalToInt(2)));
    [mockDelegate verify];
}

- (void)testRemoveASection {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    RKTableSection* section = [RKTableSection section];
    RKTestTableControllerDelegate* delegate = [RKTestTableControllerDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                  didInsertSection:section
                                                           atIndex:1];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                  didRemoveSection:section
                                                           atIndex:1];
    tableController.delegate = mockDelegate;
    [tableController addSection:section];
    assertThatInt(tableController.sectionCount, is(equalToInt(2)));
    [tableController removeSection:section];
    assertThatInt(tableController.sectionCount, is(equalToInt(1)));
    [mockDelegate verify];
}

- (void)testNotLetRemoveTheLastSection {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    RKTableSection* section = [RKTableSection section];
    RKTestTableControllerDelegate* delegate = [RKTestTableControllerDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                  didInsertSection:section
                                                           atIndex:1];
    tableController.delegate = mockDelegate;
    [tableController addSection:section];
    assertThatInt(tableController.sectionCount, is(equalToInt(2)));
    [tableController removeSection:section];
    [mockDelegate verify];
}

- (void)testInsertASectionAtASpecificIndex {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    RKTableSection* referenceSection = [RKTableSection section];
    RKTestTableControllerDelegate* delegate = [RKTestTableControllerDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                  didInsertSection:referenceSection
                                                           atIndex:2];
    [tableController addSection:[RKTableSection section]];
    [tableController addSection:[RKTableSection section]];
    [tableController addSection:[RKTableSection section]];
    [tableController addSection:[RKTableSection section]];
    tableController.delegate = mockDelegate;
    [tableController insertSection:referenceSection atIndex:2];
    assertThatInt(tableController.sectionCount, is(equalToInt(6)));
    assertThat([tableController.sections objectAtIndex:2], is(equalTo(referenceSection)));
    [mockDelegate verify];
}

- (void)testRemoveASectionByIndex {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    RKTableSection* section = [RKTableSection section];
    RKTestTableControllerDelegate* delegate = [RKTestTableControllerDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                  didInsertSection:section
                                                           atIndex:1];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                  didRemoveSection:section
                                                           atIndex:1];
    tableController.delegate = mockDelegate;
    [tableController addSection:section];
    assertThatInt(tableController.sectionCount, is(equalToInt(2)));
    [tableController removeSectionAtIndex:1];
    assertThatInt(tableController.sectionCount, is(equalToInt(1)));
    [mockDelegate verify];
}

- (void)testRaiseAnExceptionWhenAttemptingToRemoveTheLastSection {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    NSException* exception = nil;
    @try {
        [tableController removeSectionAtIndex:0];
    }
    @catch (NSException *e) {
        exception = e;
    }
    @finally {
        assertThat(exception, isNot(nilValue()));
    }
}

- (void)testReturnTheSectionAtAGivenIndex {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    RKTableSection* referenceSection = [RKTableSection section];
    RKTestTableControllerDelegate* delegate = [RKTestTableControllerDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                  didInsertSection:referenceSection
                                                           atIndex:2];
    [tableController addSection:[RKTableSection section]];
    [tableController addSection:[RKTableSection section]];
    [tableController addSection:[RKTableSection section]];
    [tableController addSection:[RKTableSection section]];
    tableController.delegate = mockDelegate;
    [tableController insertSection:referenceSection atIndex:2];
    assertThatInt(tableController.sectionCount, is(equalToInt(6)));
    assertThat([tableController sectionAtIndex:2], is(equalTo(referenceSection)));
    [mockDelegate verify];
}

- (void)testRemoveAllSections {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    RKTestTableControllerDelegate* delegate = [RKTestTableControllerDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                  didInsertSection:OCMOCK_ANY
                                                           atIndex:0];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                  didInsertSection:OCMOCK_ANY
                                                           atIndex:1];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                  didInsertSection:OCMOCK_ANY
                                                           atIndex:2];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                  didInsertSection:OCMOCK_ANY
                                                           atIndex:3];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                  didInsertSection:OCMOCK_ANY
                                                           atIndex:4];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                  didRemoveSection:OCMOCK_ANY
                                                           atIndex:0];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                  didRemoveSection:OCMOCK_ANY
                                                           atIndex:1];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                  didRemoveSection:OCMOCK_ANY
                                                           atIndex:2];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                  didRemoveSection:OCMOCK_ANY
                                                           atIndex:3];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                  didRemoveSection:OCMOCK_ANY
                                                           atIndex:4];
    tableController.delegate = mockDelegate;
    [tableController addSection:[RKTableSection section]];
    [tableController addSection:[RKTableSection section]];
    [tableController addSection:[RKTableSection section]];
    [tableController addSection:[RKTableSection section]];
    assertThatInt(tableController.sectionCount, is(equalToInt(5)));
    [tableController removeAllSections];
    assertThatInt(tableController.sectionCount, is(equalToInt(1)));
    [mockDelegate verify];
}

- (void)testReturnASectionByHeaderTitle {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    [tableController addSection:[RKTableSection section]];
    [tableController addSection:[RKTableSection section]];
    RKTableSection* titledSection = [RKTableSection section];
    titledSection.headerTitle = @"Testing";
    [tableController addSection:titledSection];
    [tableController addSection:[RKTableSection section]];
    assertThat([tableController sectionWithHeaderTitle:@"Testing"], is(equalTo(titledSection)));
}

- (void)testNotifyTheTableViewOnSectionInsertion {
    RKTableControllerSpecViewController *viewController = [RKTableControllerSpecViewController new];
    id mockTableView = [OCMockObject niceMockForClass:[UITableView class]];
    RKTableController *tableController = [RKTableController tableControllerWithTableView:mockTableView forViewController:viewController];
    [[mockTableView expect] insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:tableController.defaultRowAnimation];
    [tableController addSection:[RKTableSection section]];
    [mockTableView verify];
}

- (void)testNotifyTheTableViewOnSectionRemoval {
    RKTableControllerSpecViewController *viewController = [RKTableControllerSpecViewController new];
    id mockTableView = [OCMockObject niceMockForClass:[UITableView class]];
    RKTableController *tableController = [RKTableController tableControllerWithTableView:mockTableView forViewController:viewController];
    [[mockTableView expect] insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:tableController.defaultRowAnimation];
    [[mockTableView expect] deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:tableController.defaultRowAnimation];
    RKTableSection *section = [RKTableSection section];
    [tableController addSection:section];
    [tableController removeSection:section];
    [mockTableView verify];
}

- (void)testNotifyTheTableOfSectionRemovalAndReaddWhenRemovingAllSections {
    RKTableControllerSpecViewController *viewController = [RKTableControllerSpecViewController new];
    id mockTableView = [OCMockObject niceMockForClass:[UITableView class]];
    RKTableController *tableController = [RKTableController tableControllerWithTableView:mockTableView forViewController:viewController];
    [[mockTableView expect] deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:tableController.defaultRowAnimation];
    [[mockTableView expect] deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:tableController.defaultRowAnimation];
    [[mockTableView expect] insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:tableController.defaultRowAnimation];
    RKTableSection *section = [RKTableSection section];
    [tableController addSection:section];
    [tableController removeAllSections];
    [mockTableView verify];
}

#pragma mark - UITableViewDataSource specs

- (void)testRaiseAnExceptionIfSentAMessageWithATableViewItIsNotBoundTo {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    NSException* exception = nil;
    @try {
        [tableController numberOfSectionsInTableView:[UITableView new]];
    }
    @catch (NSException* e) {
        exception = e;
    }
    @finally {
        assertThat(exception, is(notNilValue()));
    }
}

- (void)testReturnTheNumberOfSectionsInTableView {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    assertThatInt([tableController numberOfSectionsInTableView:viewController.tableView], is(equalToInt(1)));
    [tableController addSection:[RKTableSection section]];
    assertThatInt([tableController numberOfSectionsInTableView:viewController.tableView], is(equalToInt(2)));
}

- (void)testReturnTheNumberOfRowsInSectionInTableView {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    assertThatInt([tableController tableView:viewController.tableView numberOfRowsInSection:0], is(equalToInt(0)));
    NSArray* objects = [NSArray arrayWithObject:@"one"];
    [tableController loadObjects:objects];
    assertThatInt([tableController tableView:viewController.tableView numberOfRowsInSection:0], is(equalToInt(1)));
}

- (void)testReturnTheHeaderTitleForSection {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    RKTableSection* section = [RKTableSection section];
    [tableController addSection:section];
    assertThat([tableController tableView:viewController.tableView titleForHeaderInSection:1], is(nilValue()));
    section.headerTitle = @"RestKit!";
    assertThat([tableController tableView:viewController.tableView titleForHeaderInSection:1], is(equalTo(@"RestKit!")));
}

- (void)testReturnTheTitleForFooterInSection {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    RKTableSection* section = [RKTableSection section];
    [tableController addSection:section];
    assertThat([tableController tableView:viewController.tableView titleForFooterInSection:1], is(nilValue()));
    section.footerTitle = @"RestKit!";
    assertThat([tableController tableView:viewController.tableView titleForFooterInSection:1], is(equalTo(@"RestKit!")));
}

- (void)testReturnTheNumberOfRowsAcrossAllSections {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    RKTableSection* section = [RKTableSection section];
    id sectionMock = [OCMockObject partialMockForObject:section];
    NSUInteger rowCount = 5;
    [[[sectionMock stub] andReturnValue:OCMOCK_VALUE(rowCount)] rowCount];
    [tableController addSection:section];
    assertThatInt(tableController.rowCount, is(equalToInt(5)));
}

- (void)testReturnTheTableViewCellForRowAtIndexPath {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    RKTableItem* item = [RKTableItem tableItemWithText:@"Test!" detailText:@"Details!" image:nil];
    [tableController loadTableItems:[NSArray arrayWithObject:item] inSection:0 withMapping:[RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
        // Detail text label won't appear with default style...
        cellMapping.style = UITableViewCellStyleValue1;
        [cellMapping addDefaultMappings];
    }]];
    UITableViewCell* cell = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThat(cell.textLabel.text, is(equalTo(@"Test!")));
    assertThat(cell.detailTextLabel.text, is(equalTo(@"Details!")));

}

#pragma mark - Table Cell Mapping

- (void)testInitializeCellMappings {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    assertThat(tableController.cellMappings, is(notNilValue()));
}

- (void)testRegisterMappingsForObjectsToTableViewCell {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    assertThat([tableController.cellMappings cellMappingForClass:[RKTestUser class]], is(nilValue()));
    [tableController mapObjectsWithClass:[RKTestUser class] toTableCellsWithMapping:[RKTableViewCellMapping cellMapping]];
    RKObjectMapping* mapping = [tableController.cellMappings cellMappingForClass:[RKTestUser class]];
    assertThat(mapping, isNot(nilValue()));
    assertThatBool([mapping.objectClass isSubclassOfClass:[UITableViewCell class]], is(equalToBool(YES)));
}

- (void)testDefaultTheReuseIdentifierToTheNameOfTheObjectClass {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    assertThat([tableController.cellMappings cellMappingForClass:[RKTestUser class]], is(nilValue()));
    RKTableViewCellMapping* cellMapping = [RKTableViewCellMapping cellMapping];
    [tableController mapObjectsWithClass:[RKTestUser class] toTableCellsWithMapping:cellMapping];
    assertThat(cellMapping.reuseIdentifier, is(equalTo(@"UITableViewCell")));
}

- (void)testDefaultTheReuseIdentifierToTheNameOfTheObjectClassWhenCreatingMappingWithBlockSyntax {
    RKTableControllerSpecTableViewController *viewController = [RKTableControllerSpecTableViewController new];
    RKTableController *tableController = [RKTableController tableControllerForTableViewController:viewController];
    assertThat([tableController.cellMappings cellMappingForClass:[RKTestUser class]], is(nilValue()));
    RKTableViewCellMapping *cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
        cellMapping.cellClass = [RKTestUserTableViewCell class];
    }];
    [tableController mapObjectsWithClass:[RKTestUser class] toTableCellsWithMapping:cellMapping];
    assertThat(cellMapping.reuseIdentifier, is(equalTo(@"RKTestUserTableViewCell")));
}

- (void)testReturnTheObjectForARowAtIndexPath {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    RKTestUser* user = [RKTestUser user];
    [tableController loadObjects:[NSArray arrayWithObject:user]];
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    assertThatBool(user == [tableController objectForRowAtIndexPath:indexPath], is(equalToBool(YES)));
}

- (void)testReturnTheCellMappingForTheRowAtIndexPath {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    RKTableViewCellMapping* cellMapping = [RKTableViewCellMapping cellMapping];
    [tableController mapObjectsWithClass:[RKTestUser class] toTableCellsWithMapping:cellMapping];
    [tableController loadObjects:[NSArray arrayWithObject:[RKTestUser user]]];
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    assertThat([tableController cellMappingForObjectAtIndexPath:indexPath], is(equalTo(cellMapping)));
}

- (void)testReturnATableViewCellForTheObjectAtAGivenIndexPath {
    RKMappableObject* object = [RKMappableObject new];
    object.stringTest = @"Testing!!";
    RKTableViewCellMapping* cellMapping = [RKTableViewCellMapping mappingForClass:[UITableViewCell class]];
    [cellMapping mapKeyPath:@"stringTest" toAttribute:@"textLabel.text"];
    NSArray* objects = [NSArray arrayWithObject:object];
    RKTableViewCellMappings* mappings = [RKTableViewCellMappings new];
    [mappings setCellMapping:cellMapping forClass:[RKMappableObject class]];
    RKTableSection* section = [RKTableSection sectionForObjects:objects withMappings:mappings];
    UITableViewController* tableViewController = [UITableViewController new];
    tableViewController.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0,0,0,0) style:UITableViewStylePlain];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:tableViewController];
    [tableController insertSection:section atIndex:0];
    tableController.cellMappings = mappings;

    UITableViewCell* cell = [tableController cellForObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThat(cell, isNot(nilValue()));
    assertThat(cell.textLabel.text, is(equalTo(@"Testing!!")));
}

- (void)testChangeTheReuseIdentifierWhenMutatedWithinTheBlockInitializer {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    assertThat([tableController.cellMappings cellMappingForClass:[RKTestUser class]], is(nilValue()));
    [tableController mapObjectsWithClass:[RKTestUser class] toTableCellsWithMapping:[RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
        cellMapping.cellClass = [RKTestUserTableViewCell class];
        cellMapping.reuseIdentifier = @"RKTestUserOverride";
    }]];
    RKTableViewCellMapping* userCellMapping = [tableController.cellMappings cellMappingForClass:[RKTestUser class]];
    assertThat(userCellMapping, isNot(nilValue()));
    assertThat(userCellMapping.reuseIdentifier, is(equalTo(@"RKTestUserOverride")));
}

#pragma mark - Static Object Loading

- (void)testLoadAnArrayOfObjects {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    NSArray* objects = [NSArray arrayWithObject:@"one"];
    assertThat([tableController sectionAtIndex:0].objects, is(empty()));
    [tableController loadObjects:objects];
    assertThat([tableController sectionAtIndex:0].objects, is(equalTo(objects)));
}

- (void)testLoadAnArrayOfObjectsToTheSpecifiedSection {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    [tableController addSection:[RKTableSection section]];
    NSArray* objects = [NSArray arrayWithObject:@"one"];
    assertThat([tableController sectionAtIndex:1].objects, is(empty()));
    [tableController loadObjects:objects inSection:1];
    assertThat([tableController sectionAtIndex:1].objects, is(equalTo(objects)));
}

- (void)testLoadAnArrayOfTableItems {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    NSArray* tableItems = [RKTableItem tableItemsFromStrings:@"One", @"Two", @"Three", nil];
    [tableController loadTableItems:tableItems];
    assertThatBool([tableController isLoaded], is(equalToBool(YES)));
    assertThatInt(tableController.rowCount, is(equalToInt(3)));
    UITableViewCell* cellOne = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UITableViewCell* cellTwo = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    UITableViewCell* cellThree = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    assertThat(cellOne.textLabel.text, is(equalTo(@"One")));
    assertThat(cellTwo.textLabel.text, is(equalTo(@"Two")));
    assertThat(cellThree.textLabel.text, is(equalTo(@"Three")));
}

- (void)testAllowYouToTriggerAnEmptyLoad {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    assertThatBool([tableController isLoaded], is(equalToBool(NO)));
    [tableController loadEmpty];
    assertThatBool([tableController isLoaded], is(equalToBool(YES)));
    assertThatBool([tableController isEmpty], is(equalToBool(YES)));
}

#pragma mark - Network Load

- (void)testLoadCollectionOfObjectsAndMapThemIntoTableViewCells {
    RKObjectManager* objectManager = RKTestNewObjectManager();
    objectManager.client.cachePolicy = RKRequestCachePolicyNone;
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = objectManager;
    [tableController mapObjectsWithClass:[RKTestUser class] toTableCellsWithMapping:[RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* mapping) {
        mapping.cellClass = [RKTestUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];
    RKTestTableControllerDelegate* delegate = [RKTestTableControllerDelegate tableControllerDelegate];
    delegate.timeout = 10;
    tableController.delegate = delegate;
    [tableController loadTableFromResourcePath:@"/JSON/users.json" usingBlock:^(RKObjectLoader* objectLoader) {
        objectLoader.objectMapping = [RKObjectMapping mappingForClass:[RKTestUser class] usingBlock:^(RKObjectMapping* mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [delegate waitForLoad];
    assertThatBool([tableController isLoaded], is(equalToBool(YES)));
    assertThatInt(tableController.rowCount, is(equalToInt(3)));
}

- (void)testSetTheModelToTheLoadedStateIfObjectsAreLoadedSuccessfully {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    assertThatBool([tableController isLoaded], is(equalToBool(NO)));
    NSArray* objects = [NSArray arrayWithObject:[RKTestUser new]];
    id mockLoader = [OCMockObject mockForClass:[RKObjectLoader class]];
    [tableController objectLoader:mockLoader didLoadObjects:objects];
    assertThatBool([tableController isLoading], is(equalToBool(NO)));
    assertThatBool([tableController isLoaded], is(equalToBool(YES)));
}

- (void)testSetTheModelToErrorStateIfTheObjectLoaderFailsWithAnError {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    id mockObjectLoader = [OCMockObject niceMockForClass:[RKObjectLoader class]];
    NSError* error = [NSError errorWithDomain:@"Test" code:0 userInfo:nil];
    [tableController objectLoader:mockObjectLoader didFailWithError:error];
    assertThatBool([tableController isLoading], is(equalToBool(NO)));
    assertThatBool([tableController isLoaded], is(equalToBool(YES)));
    assertThatBool([tableController isError], is(equalToBool(YES)));
    assertThatBool([tableController isEmpty], is(equalToBool(YES)));
}

- (void)testSetTheModelToAnEmptyStateIfTheObjectLoaderReturnsAnEmptyCollection {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    assertThatBool([tableController isLoaded], is(equalToBool(NO)));
    NSArray* objects = [NSArray array];
    id mockLoader = [OCMockObject mockForClass:[RKObjectLoader class]];
    [tableController objectLoader:mockLoader didLoadObjects:objects];
    assertThatBool([tableController isLoading], is(equalToBool(NO)));
    assertThatBool([tableController isEmpty], is(equalToBool(YES)));
}

- (void)testSetTheModelToALoadedStateEvenIfTheObjectLoaderReturnsAnEmptyCollection {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    assertThatBool([tableController isLoaded], is(equalToBool(NO)));
    NSArray* objects = [NSArray array];
    id mockLoader = [OCMockObject mockForClass:[RKObjectLoader class]];
    [tableController objectLoader:mockLoader didLoadObjects:objects];
    assertThatBool([tableController isLoading], is(equalToBool(NO)));
    assertThatBool([tableController isEmpty], is(equalToBool(YES)));
    assertThatBool([tableController isLoaded], is(equalToBool(YES)));
}

- (void)testEnterTheLoadingStateWhenTheRequestStartsLoading {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    assertThatBool([tableController isLoaded], is(equalToBool(NO)));
    assertThatBool([tableController isLoading], is(equalToBool(NO)));
    id mockLoader = [OCMockObject mockForClass:[RKObjectLoader class]];
    [tableController requestDidStartLoad:mockLoader];
    assertThatBool([tableController isLoading], is(equalToBool(YES)));
}

- (void)testExitTheLoadingStateWhenTheRequestFinishesLoading {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    assertThatBool([tableController isLoaded], is(equalToBool(NO)));
    assertThatBool([tableController isLoading], is(equalToBool(NO)));
    id mockLoader = [OCMockObject mockForClass:[RKObjectLoader class]];
    [tableController requestDidStartLoad:mockLoader];
    assertThatBool([tableController isLoading], is(equalToBool(YES)));
    [tableController objectLoaderDidFinishLoading:mockLoader];
    assertThatBool([tableController isLoading], is(equalToBool(NO)));
}

- (void)testClearTheLoadingStateWhenARequestIsCancelled {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    assertThatBool([tableController isLoaded], is(equalToBool(NO)));
    assertThatBool([tableController isLoading], is(equalToBool(NO)));
    id mockLoader = [OCMockObject mockForClass:[RKObjectLoader class]];
    [tableController requestDidStartLoad:mockLoader];
    assertThatBool([tableController isLoading], is(equalToBool(YES)));
    [tableController requestDidCancelLoad:mockLoader];
    assertThatBool([tableController isLoading], is(equalToBool(NO)));
}

- (void)testClearTheLoadingStateWhenARequestTimesOut {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    assertThatBool([tableController isLoaded], is(equalToBool(NO)));
    assertThatBool([tableController isLoading], is(equalToBool(NO)));
    id mockLoader = [OCMockObject mockForClass:[RKObjectLoader class]];
    [tableController requestDidStartLoad:mockLoader];
    assertThatBool([tableController isLoading], is(equalToBool(YES)));
    [tableController requestDidTimeout:mockLoader];
    assertThatBool([tableController isLoading], is(equalToBool(NO)));
}

- (void)testDoSomethingWhenTheRequestLoadsAnUnexpectedResponse {
    RKLogCritical(@"PENDING - Undefined Behavior!!!");
}

#pragma mark - RKTableViewDelegate specs

- (void)testNotifyTheDelegateWhenLoadingStarts {
    RKObjectManager* objectManager = RKTestNewObjectManager();
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = objectManager;
    [tableController mapObjectsWithClass:[RKTestUser class] toTableCellsWithMapping:[RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* mapping) {
        mapping.cellClass = [RKTestUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];
    id mockDelegate = [OCMockObject partialMockForObject:[RKTestTableControllerDelegate new]];
    [[[mockDelegate expect] andForwardToRealObject] tableControllerDidStartLoad:tableController];
    tableController.delegate = mockDelegate;
    [tableController loadTableFromResourcePath:@"/JSON/users.json" usingBlock:^(RKObjectLoader* objectLoader) {
        objectLoader.objectMapping = [RKObjectMapping mappingForClass:[RKTestUser class] usingBlock:^(RKObjectMapping* mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [mockDelegate waitForLoad];
    [mockDelegate verify];
}

- (void)testNotifyTheDelegateWhenLoadingFinishes {
    RKObjectManager* objectManager = RKTestNewObjectManager();
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = objectManager;
    [tableController mapObjectsWithClass:[RKTestUser class] toTableCellsWithMapping:[RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* mapping) {
        mapping.cellClass = [RKTestUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];
    RKTestTableControllerDelegate* delegate = [RKTestTableControllerDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableControllerDidFinishLoad:tableController];
    tableController.delegate = mockDelegate;
    [tableController loadTableFromResourcePath:@"/JSON/users.json" usingBlock:^(RKObjectLoader* objectLoader) {
        objectLoader.objectMapping = [RKObjectMapping mappingForClass:[RKTestUser class] usingBlock:^(RKObjectMapping* mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [mockDelegate waitForLoad];
    [mockDelegate verify];
}

- (void)testNotifyTheDelegateWhenAnErrorOccurs {
    RKObjectManager* objectManager = RKTestNewObjectManager();
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = objectManager;
    [tableController mapObjectsWithClass:[RKTestUser class] toTableCellsWithMapping:[RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* mapping) {
        mapping.cellClass = [RKTestUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];
    RKTestTableControllerDelegate* delegate = [RKTestTableControllerDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController didFailLoadWithError:OCMOCK_ANY];
    tableController.delegate = mockDelegate;
    [tableController loadTableFromResourcePath:@"/fail" usingBlock:^(RKObjectLoader* objectLoader) {
        objectLoader.objectMapping = [RKObjectMapping mappingForClass:[RKTestUser class] usingBlock:^(RKObjectMapping* mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [mockDelegate waitForLoad];
    [mockDelegate verify];
}

- (void)testNotifyTheDelegateWhenAnEmptyCollectionIsLoaded {
    RKObjectManager* objectManager = RKTestNewObjectManager();
    objectManager.client.cachePolicy = RKRequestCachePolicyNone;
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = objectManager;
    [tableController mapObjectsWithClass:[RKTestUser class] toTableCellsWithMapping:[RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* mapping) {
        mapping.cellClass = [RKTestUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];
    RKTestTableControllerDelegate* delegate = [RKTestTableControllerDelegate new];
    delegate.timeout = 5;
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableControllerDidBecomeEmpty:tableController];
    tableController.delegate = mockDelegate;
    [tableController loadTableFromResourcePath:@"/empty/array" usingBlock:^(RKObjectLoader* objectLoader) {
        objectLoader.objectMapping = [RKObjectMapping mappingForClass:[RKTestUser class] usingBlock:^(RKObjectMapping* mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [mockDelegate waitForLoad];
    [mockDelegate verify];
}

- (void)testNotifyTheDelegateWhenModelWillLoadWithObjectLoader {
    RKObjectManager* objectManager = RKTestNewObjectManager();
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = objectManager;
    [tableController mapObjectsWithClass:[RKTestUser class] toTableCellsWithMapping:[RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* mapping) {
        mapping.cellClass = [RKTestUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];
    RKTestTableControllerDelegate* delegate = [RKTestTableControllerDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController willLoadTableWithObjectLoader:OCMOCK_ANY];
    tableController.delegate = mockDelegate;
    [tableController loadTableFromResourcePath:@"/empty/array" usingBlock:^(RKObjectLoader* objectLoader) {
        objectLoader.objectMapping = [RKObjectMapping mappingForClass:[RKTestUser class] usingBlock:^(RKObjectMapping* mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [mockDelegate waitForLoad];
    [mockDelegate verify];
}

- (void)testNotifyTheDelegateWhenModelDidLoadWithObjectLoader {
    RKObjectManager* objectManager = RKTestNewObjectManager();
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = objectManager;
    [tableController mapObjectsWithClass:[RKTestUser class] toTableCellsWithMapping:[RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* mapping) {
        mapping.cellClass = [RKTestUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];
    RKTestTableControllerDelegate* delegate = [RKTestTableControllerDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController didLoadTableWithObjectLoader:OCMOCK_ANY];
    tableController.delegate = mockDelegate;
    [tableController loadTableFromResourcePath:@"/empty/array" usingBlock:^(RKObjectLoader* objectLoader) {
        objectLoader.objectMapping = [RKObjectMapping mappingForClass:[RKTestUser class] usingBlock:^(RKObjectMapping* mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [mockDelegate waitForLoad];
    [mockDelegate verify];
}

- (void)testNotifyTheDelegateWhenModelDidCancelLoad {
    RKObjectManager* objectManager = RKTestNewObjectManager();
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = objectManager;
    [tableController mapObjectsWithClass:[RKTestUser class] toTableCellsWithMapping:[RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* mapping) {
        mapping.cellClass = [RKTestUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];
    RKTestTableControllerDelegate* delegate = [RKTestTableControllerDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableControllerDidCancelLoad:tableController];
    tableController.delegate = mockDelegate;
    [tableController loadTableFromResourcePath:@"/empty/array" usingBlock:^(RKObjectLoader* objectLoader) {
        objectLoader.objectMapping = [RKObjectMapping mappingForClass:[RKTestUser class] usingBlock:^(RKObjectMapping* mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [tableController cancelLoad];
    [mockDelegate waitForLoad];
    [mockDelegate verify];
}

- (void)testNotifyTheDelegateWhenDidEndEditingARow {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    RKTableItem* tableItem = [RKTableItem tableItem];
    RKTestTableControllerDelegate* delegate = [RKTestTableControllerDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                     didEndEditing:OCMOCK_ANY
                                                       atIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    tableController.delegate = mockDelegate;
    [tableController loadTableItems:[NSArray arrayWithObject:tableItem]];
    [tableController tableView:tableController.tableView didEndEditingRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [mockDelegate verify];
}

- (void)testNotifyTheDelegateWhenWillBeginEditingARow {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    RKTableItem* tableItem = [RKTableItem tableItem];
    RKTestTableControllerDelegate* delegate = [RKTestTableControllerDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                  willBeginEditing:OCMOCK_ANY
                                                       atIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    tableController.delegate = mockDelegate;
    [tableController loadTableItems:[NSArray arrayWithObject:tableItem]];
    [tableController tableView:tableController.tableView willBeginEditingRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [mockDelegate verify];
}

- (void)testNotifyTheDelegateWhenAnObjectIsInserted {
    NSArray* objects = [NSArray arrayWithObject:@"first object"];
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    RKTestTableControllerDelegate* delegate = [RKTestTableControllerDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                   didInsertObject:@"first object"
                                                       atIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                   didInsertObject:@"new object"
                                                       atIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    tableController.delegate = mockDelegate;
    [tableController loadObjects:objects];
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]],
               is(equalTo(@"first object")));
    [[tableController.sections objectAtIndex:0] insertObject:@"new object" atIndex:1];
    assertThat([[tableController.sections objectAtIndex:0] objectAtIndex:0], is(equalTo(@"first object")));
    assertThat([[tableController.sections objectAtIndex:0] objectAtIndex:1], is(equalTo(@"new object")));
    [mockDelegate verify];
}

- (void)testNotifyTheDelegateWhenAnObjectIsUpdated {
    NSArray* objects = [NSArray arrayWithObjects:@"first object", @"second object", nil];
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    RKTestTableControllerDelegate* delegate = [RKTestTableControllerDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                   didInsertObject:@"first object"
                                                       atIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                   didInsertObject:@"second object"
                                                       atIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                   didUpdateObject:@"new second object"
                                                       atIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    tableController.delegate = mockDelegate;
    [tableController loadObjects:objects];
    assertThat([[tableController.sections objectAtIndex:0] objectAtIndex:0], is(equalTo(@"first object")));
    assertThat([[tableController.sections objectAtIndex:0] objectAtIndex:1], is(equalTo(@"second object")));
    [[tableController.sections objectAtIndex:0] replaceObjectAtIndex:1 withObject:@"new second object"];
    assertThat([[tableController.sections objectAtIndex:0] objectAtIndex:1], is(equalTo(@"new second object")));
    [mockDelegate verify];
}

- (void)testNotifyTheDelegateWhenAnObjectIsDeleted {
    NSArray* objects = [NSArray arrayWithObjects:@"first object", @"second object", nil];
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    RKTestTableControllerDelegate* delegate = [RKTestTableControllerDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                   didInsertObject:@"first object"
                                                       atIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                   didInsertObject:@"second object"
                                                       atIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                   didDeleteObject:@"second object"
                                                       atIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    tableController.delegate = mockDelegate;
    [tableController loadObjects:objects];
    assertThat([[tableController.sections objectAtIndex:0] objectAtIndex:0], is(equalTo(@"first object")));
    assertThat([[tableController.sections objectAtIndex:0] objectAtIndex:1], is(equalTo(@"second object")));
    [[tableController.sections objectAtIndex:0] removeObjectAtIndex:1];
    assertThat([[tableController.sections objectAtIndex:0] objectAtIndex:0], is(equalTo(@"first object")));
    [mockDelegate verify];
}

#pragma mark - Notifications

- (void)testPostANotificationWhenLoadingStarts {
    RKObjectManager* objectManager = RKTestNewObjectManager();
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = objectManager;
    [tableController mapObjectsWithClass:[RKTestUser class] toTableCellsWithMapping:[RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* mapping) {
        mapping.cellClass = [RKTestUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];
    id observerMock = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:observerMock name:RKTableControllerDidStartLoadNotification object:tableController];
    [[observerMock expect] notificationWithName:RKTableControllerDidStartLoadNotification object:tableController];
    RKTestTableControllerDelegate* delegate = [RKTestTableControllerDelegate new];
    tableController.delegate = delegate;
    [tableController loadTableFromResourcePath:@"/JSON/users.json" usingBlock:^(RKObjectLoader* objectLoader) {
        objectLoader.objectMapping = [RKObjectMapping mappingForClass:[RKTestUser class] usingBlock:^(RKObjectMapping* mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [delegate waitForLoad];
    [observerMock verify];
}

- (void)testPostANotificationWhenLoadingFinishes {
    RKObjectManager* objectManager = RKTestNewObjectManager();
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = objectManager;
    [tableController mapObjectsWithClass:[RKTestUser class] toTableCellsWithMapping:[RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* mapping) {
        mapping.cellClass = [RKTestUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];

    id observerMock = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:observerMock name:RKTableControllerDidFinishLoadNotification object:tableController];
    [[observerMock expect] notificationWithName:RKTableControllerDidFinishLoadNotification object:tableController];
    RKTestTableControllerDelegate* delegate = [RKTestTableControllerDelegate new];
    tableController.delegate = delegate;

    [tableController loadTableFromResourcePath:@"/JSON/users.json" usingBlock:^(RKObjectLoader* objectLoader) {
        objectLoader.objectMapping = [RKObjectMapping mappingForClass:[RKTestUser class] usingBlock:^(RKObjectMapping* mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [delegate waitForLoad];
    [observerMock verify];
}

- (void)testPostANotificationWhenAnErrorOccurs {
    RKObjectManager* objectManager = RKTestNewObjectManager();
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = objectManager;
    [tableController mapObjectsWithClass:[RKTestUser class] toTableCellsWithMapping:[RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* mapping) {
        mapping.cellClass = [RKTestUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];

    id observerMock = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:observerMock name:RKTableControllerDidLoadErrorNotification object:tableController];
    [[observerMock expect] notificationWithName:RKTableControllerDidLoadErrorNotification object:tableController userInfo:OCMOCK_ANY];
    RKTestTableControllerDelegate* delegate = [RKTestTableControllerDelegate new];
    tableController.delegate = delegate;

    [tableController loadTableFromResourcePath:@"/fail" usingBlock:^(RKObjectLoader* objectLoader) {
        objectLoader.objectMapping = [RKObjectMapping mappingForClass:[RKTestUser class] usingBlock:^(RKObjectMapping* mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [delegate waitForLoad];
    [observerMock verify];
}

- (void)testPostANotificationWhenAnEmptyCollectionIsLoaded {
    RKObjectManager* objectManager = RKTestNewObjectManager();
    objectManager.client.cachePolicy = RKRequestCachePolicyNone;
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = objectManager;
    [tableController mapObjectsWithClass:[RKTestUser class] toTableCellsWithMapping:[RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* mapping) {
        mapping.cellClass = [RKTestUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];

    id observerMock = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:observerMock name:RKTableControllerDidLoadEmptyNotification object:tableController];
    [[observerMock expect] notificationWithName:RKTableControllerDidLoadEmptyNotification object:tableController];
    RKTestTableControllerDelegate* delegate = [RKTestTableControllerDelegate new];
    tableController.delegate = delegate;
    [tableController loadTableFromResourcePath:@"/empty/array" usingBlock:^(RKObjectLoader* objectLoader) {
        objectLoader.objectMapping = [RKObjectMapping mappingForClass:[RKTestUser class] usingBlock:^(RKObjectMapping* mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [delegate waitForLoad];
    [observerMock verify];
}

#pragma mark - State Views

- (void)testPermitYouToOverlayAnImageOnTheTable {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    UIImage* image = [RKTestFixture imageWithContentsOfFixture:@"blake.png"];
    [tableController showImageInOverlay:image];
    UIImageView* imageView = tableController.stateOverlayImageView;
    assertThat(imageView, isNot(nilValue()));
    assertThat(imageView.image, is(equalTo(image)));
}

- (void)testPermitYouToRemoveAnImageOverlayFromTheTable {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    UIImage* image = [RKTestFixture imageWithContentsOfFixture:@"blake.png"];
    [tableController showImageInOverlay:image];
    assertThat([tableController.tableView.superview subviews], isNot(empty()));
    [tableController removeImageOverlay];
    assertThat([tableController.tableView.superview subviews], is(nilValue()));
}

- (void)testTriggerDisplayOfTheErrorViewOnTransitionToErrorState {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    UIImage* image = [RKTestFixture imageWithContentsOfFixture:@"blake.png"];
    tableController.imageForError = image;
    id mockError = [OCMockObject mockForClass:[NSError class]];
    [tableController objectLoader:nil didFailWithError:mockError];
    assertThatBool([tableController isError], is(equalToBool(YES)));
    UIImageView* imageView = tableController.stateOverlayImageView;
    assertThat(imageView, isNot(nilValue()));
    assertThat(imageView.image, is(equalTo(image)));
}

- (void)testTriggerHidingOfTheErrorViewOnTransitionOutOfTheErrorState {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    UIImage* image = [RKTestFixture imageWithContentsOfFixture:@"blake.png"];
    tableController.imageForError = image;
    id mockError = [OCMockObject niceMockForClass:[NSError class]];
    [tableController objectLoader:nil didFailWithError:mockError];
    assertThatBool([tableController isError], is(equalToBool(YES)));
    UIImageView* imageView = tableController.stateOverlayImageView;
    assertThat(imageView, isNot(nilValue()));
    assertThat(imageView.image, is(equalTo(image)));
    [tableController loadTableItems:[NSArray arrayWithObject:[RKTableItem tableItem]]];
    assertThat(tableController.error, is(nilValue()));
    assertThat(tableController.stateOverlayImageView.image, is(nilValue()));
}

- (void)testTriggerDisplayOfTheEmptyViewOnTransitionToEmptyState {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    UIImage* image = [RKTestFixture imageWithContentsOfFixture:@"blake.png"];
    tableController.imageForEmpty = image;
    [tableController loadEmpty];
    assertThatBool([tableController isEmpty], is(equalToBool(YES)));
    UIImageView* imageView = tableController.stateOverlayImageView;
    assertThat(imageView, isNot(nilValue()));
    assertThat(imageView.image, is(equalTo(image)));
}

- (void)testTriggerHidingOfTheEmptyViewOnTransitionOutOfTheEmptyState {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    UIImage* image = [RKTestFixture imageWithContentsOfFixture:@"blake.png"];
    tableController.imageForEmpty = image;
    [tableController loadEmpty];
    assertThatBool([tableController isEmpty], is(equalToBool(YES)));
    UIImageView* imageView = tableController.stateOverlayImageView;
    assertThat(imageView, isNot(nilValue()));
    assertThat(imageView.image, is(equalTo(image)));
    [tableController loadTableItems:[NSArray arrayWithObject:[RKTableItem tableItem]]];
    assertThat(tableController.stateOverlayImageView.image, is(nilValue()));
}

- (void)testTriggerDisplayOfTheLoadingViewOnTransitionToTheLoadingState {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    UIActivityIndicatorView* spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    tableController.loadingView = spinner;
    [tableController setValue:[NSNumber numberWithBool:YES] forKey:@"loading"];
    UIView* view = [tableController.tableOverlayView.subviews lastObject];
    assertThatBool(view == spinner, is(equalToBool(YES)));
}

- (void)testTriggerHidingOfTheLoadingViewOnTransitionOutOfTheLoadingState {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    UIActivityIndicatorView* spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    tableController.loadingView = spinner;
    [tableController setValue:[NSNumber numberWithBool:YES] forKey:@"loading"];
    UIView* loadingView = [tableController.tableOverlayView.subviews lastObject];
    assertThatBool(loadingView == spinner, is(equalToBool(YES)));
    [tableController setValue:[NSNumber numberWithBool:NO] forKey:@"loading"];
    loadingView = [tableController.tableOverlayView.subviews lastObject];
    assertThat(loadingView, is(nilValue()));
}

#pragma mark - Header, Footer, and Empty Rows

- (void)testShowHeaderRows {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    [tableController addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    NSArray* tableItems = [RKTableItem tableItemsFromStrings:@"One", @"Two", @"Three", nil];
    [tableController loadTableItems:tableItems];
    assertThatBool([tableController isLoaded], is(equalToBool(YES)));
    assertThatInt(tableController.rowCount, is(equalToInt(4)));
    UITableViewCell* cellOne = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UITableViewCell* cellTwo = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    UITableViewCell* cellThree = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    UITableViewCell* cellFour = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
    assertThat(cellOne.textLabel.text, is(equalTo(@"Header")));
    assertThat(cellTwo.textLabel.text, is(equalTo(@"One")));
    assertThat(cellThree.textLabel.text, is(equalTo(@"Two")));
    assertThat(cellFour.textLabel.text, is(equalTo(@"Three")));
    [tableController tableView:tableController.tableView willDisplayCell:cellOne forRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [tableController tableView:tableController.tableView willDisplayCell:cellTwo forRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    [tableController tableView:tableController.tableView willDisplayCell:cellThree forRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    [tableController tableView:tableController.tableView willDisplayCell:cellFour forRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
    assertThatBool(cellOne.hidden, is(equalToBool(NO)));
    assertThatBool(cellTwo.hidden, is(equalToBool(NO)));
    assertThatBool(cellThree.hidden, is(equalToBool(NO)));
    assertThatBool(cellFour.hidden, is(equalToBool(NO)));
}

- (void)testShowFooterRows {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    [tableController addFooterRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    NSArray* tableItems = [RKTableItem tableItemsFromStrings:@"One", @"Two", @"Three", nil];
    [tableController loadTableItems:tableItems];
    assertThatBool([tableController isLoaded], is(equalToBool(YES)));
    assertThatInt(tableController.rowCount, is(equalToInt(4)));
    UITableViewCell* cellOne = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UITableViewCell* cellTwo = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    UITableViewCell* cellThree = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    UITableViewCell* cellFour = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
    assertThat(cellOne.textLabel.text, is(equalTo(@"One")));
    assertThat(cellTwo.textLabel.text, is(equalTo(@"Two")));
    assertThat(cellThree.textLabel.text, is(equalTo(@"Three")));
    assertThat(cellFour.textLabel.text, is(equalTo(@"Footer")));
    [tableController tableView:tableController.tableView willDisplayCell:cellOne forRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [tableController tableView:tableController.tableView willDisplayCell:cellTwo forRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    [tableController tableView:tableController.tableView willDisplayCell:cellThree forRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    [tableController tableView:tableController.tableView willDisplayCell:cellFour forRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
    assertThatBool(cellOne.hidden, is(equalToBool(NO)));
    assertThatBool(cellTwo.hidden, is(equalToBool(NO)));
    assertThatBool(cellThree.hidden, is(equalToBool(NO)));
    assertThatBool(cellFour.hidden, is(equalToBool(NO)));
}

- (void)testHideHeaderRowsWhenEmptyWhenPropertyIsNotSet {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    [tableController addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    tableController.showsHeaderRowsWhenEmpty = NO;
    [tableController loadEmpty];
    assertThatBool([tableController isLoaded], is(equalToBool(YES)));
    assertThatInt(tableController.rowCount, is(equalToInt(1)));
    assertThatBool([tableController isEmpty], is(equalToBool(YES)));
    UITableViewCell* cellOne = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThat(cellOne.textLabel.text, is(equalTo(@"Header")));
    [tableController tableView:tableController.tableView willDisplayCell:cellOne forRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatBool(cellOne.hidden, is(equalToBool(YES)));
}

- (void)testHideFooterRowsWhenEmptyWhenPropertyIsNotSet {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    [tableController addFooterRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    tableController.showsFooterRowsWhenEmpty = NO;
    [tableController loadEmpty];
    assertThatBool([tableController isLoaded], is(equalToBool(YES)));
    assertThatInt(tableController.rowCount, is(equalToInt(1)));
    assertThatBool([tableController isEmpty], is(equalToBool(YES)));
    UITableViewCell* cellOne = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThat(cellOne.textLabel.text, is(equalTo(@"Footer")));
    [tableController tableView:tableController.tableView willDisplayCell:cellOne forRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatBool(cellOne.hidden, is(equalToBool(YES)));
}

- (void)testRemoveHeaderAndFooterCountsWhenDeterminingIsEmpty {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    [tableController addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController addFooterRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController setEmptyItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    tableController.showsFooterRowsWhenEmpty = NO;
    tableController.showsHeaderRowsWhenEmpty = NO;
    [tableController loadEmpty];
    assertThatBool([tableController isLoaded], is(equalToBool(YES)));
    assertThatInt(tableController.rowCount, is(equalToInt(3)));
    assertThatBool([tableController isEmpty], is(equalToBool(YES)));
}

- (void)testNotShowTheEmptyItemWhenTheTableIsNotEmpty {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    [tableController addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController addFooterRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController setEmptyItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    NSArray* tableItems = [RKTableItem tableItemsFromStrings:@"One", @"Two", @"Three", nil];
    [tableController loadTableItems:tableItems];
    assertThatBool([tableController isLoaded], is(equalToBool(YES)));
    assertThatInt(tableController.rowCount, is(equalToInt(6)));
    UITableViewCell* cellOne = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UITableViewCell* cellTwo = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    UITableViewCell* cellThree = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    UITableViewCell* cellFour = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
    UITableViewCell* cellFive = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:0]];
    UITableViewCell* cellSix = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:5 inSection:0]];
    assertThat(cellOne.textLabel.text, is(equalTo(@"Empty")));
    assertThat(cellTwo.textLabel.text, is(equalTo(@"Header")));
    assertThat(cellThree.textLabel.text, is(equalTo(@"One")));
    assertThat(cellFour.textLabel.text, is(equalTo(@"Two")));
    assertThat(cellFive.textLabel.text, is(equalTo(@"Three")));
    assertThat(cellSix.textLabel.text, is(equalTo(@"Footer")));
    [tableController tableView:tableController.tableView willDisplayCell:cellOne forRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [tableController tableView:tableController.tableView willDisplayCell:cellTwo forRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    [tableController tableView:tableController.tableView willDisplayCell:cellThree forRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    [tableController tableView:tableController.tableView willDisplayCell:cellFour forRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
    [tableController tableView:tableController.tableView willDisplayCell:cellFive forRowAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:0]];
    [tableController tableView:tableController.tableView willDisplayCell:cellSix forRowAtIndexPath:[NSIndexPath indexPathForRow:5 inSection:0]];
    assertThatBool(cellOne.hidden, is(equalToBool(YES)));
    assertThatBool(cellTwo.hidden, is(equalToBool(NO)));
    assertThatBool(cellThree.hidden, is(equalToBool(NO)));
    assertThatBool(cellFour.hidden, is(equalToBool(NO)));
    assertThatBool(cellFive.hidden, is(equalToBool(NO)));
    assertThatBool(cellSix.hidden, is(equalToBool(NO)));
}

- (void)testShowTheEmptyItemWhenTheTableIsEmpty {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    [tableController addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController addFooterRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController setEmptyItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    tableController.showsHeaderRowsWhenEmpty = NO;
    tableController.showsFooterRowsWhenEmpty = NO;
    [tableController loadEmpty];
    assertThatBool([tableController isLoaded], is(equalToBool(YES)));
    assertThatInt(tableController.rowCount, is(equalToInt(3)));
    assertThatBool([tableController isEmpty], is(equalToBool(YES)));
    UITableViewCell* cellOne = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UITableViewCell* cellTwo = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    UITableViewCell* cellThree = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    assertThat(cellOne.textLabel.text, is(equalTo(@"Empty")));
    assertThat(cellTwo.textLabel.text, is(equalTo(@"Header")));
    assertThat(cellThree.textLabel.text, is(equalTo(@"Footer")));
    [tableController tableView:tableController.tableView willDisplayCell:cellOne forRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [tableController tableView:tableController.tableView willDisplayCell:cellTwo forRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    [tableController tableView:tableController.tableView willDisplayCell:cellThree forRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    assertThatBool(cellOne.hidden, is(equalToBool(NO)));
    assertThatBool(cellTwo.hidden, is(equalToBool(YES)));
    assertThatBool(cellThree.hidden, is(equalToBool(YES)));
}

- (void)testShowTheEmptyItemPlusHeadersAndFootersWhenTheTableIsEmpty {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    [tableController addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController addFooterRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    [tableController setEmptyItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Empty";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    tableController.showsHeaderRowsWhenEmpty = YES;
    tableController.showsFooterRowsWhenEmpty = YES;
    [tableController loadEmpty];
    assertThatBool([tableController isLoaded], is(equalToBool(YES)));
    assertThatInt(tableController.rowCount, is(equalToInt(3)));
    assertThatBool([tableController isEmpty], is(equalToBool(YES)));
    UITableViewCell* cellOne = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UITableViewCell* cellTwo = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    UITableViewCell* cellThree = [tableController tableView:tableController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    assertThat(cellOne.textLabel.text, is(equalTo(@"Empty")));
    assertThat(cellTwo.textLabel.text, is(equalTo(@"Header")));
    assertThat(cellThree.textLabel.text, is(equalTo(@"Footer")));
    [tableController tableView:tableController.tableView willDisplayCell:cellOne forRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [tableController tableView:tableController.tableView willDisplayCell:cellTwo forRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    [tableController tableView:tableController.tableView willDisplayCell:cellThree forRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    assertThatBool(cellOne.hidden, is(equalToBool(NO)));
    assertThatBool(cellTwo.hidden, is(equalToBool(NO)));
    assertThatBool(cellThree.hidden, is(equalToBool(NO)));
}

#pragma mark - UITableViewDelegate specs

- (void)testInvokeTheOnSelectCellForObjectAtIndexPathBlockHandler {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    RKTableItem* tableItem = [RKTableItem tableItem];
    __block BOOL dispatched = NO;
    [tableController loadTableItems:[NSArray arrayWithObject:tableItem] withMapping:[RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
        cellMapping.onSelectCellForObjectAtIndexPath = ^(UITableViewCell* cell, id object, NSIndexPath* indexPath) {
            dispatched = YES;
        };
    }]];
    [tableController tableView:tableController.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
     assertThatBool(dispatched, is(equalToBool(YES)));
}

- (void)testInvokeTheOnCellWillAppearForObjectAtIndexPathBlockHandler {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    RKTableItem* tableItem = [RKTableItem tableItem];
    __block BOOL dispatched = NO;
    [tableController loadTableItems:[NSArray arrayWithObject:tableItem] withMapping:[RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
        cellMapping.onCellWillAppearForObjectAtIndexPath = ^(UITableViewCell* cell, id object, NSIndexPath* indexPath) {
            dispatched = YES;
        };
    }]];
    id mockCell = [OCMockObject niceMockForClass:[UITableViewCell class]];
    [tableController tableView:tableController.tableView willDisplayCell:mockCell forRowAtIndexPath:[NSIndexPath  indexPathForRow:0 inSection:0]];
    assertThatBool(dispatched, is(equalToBool(YES)));
}

- (void)testOptionallyHideHeaderRowsWhenTheyAppearAndTheTableIsEmpty {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    tableController.showsHeaderRowsWhenEmpty = NO;
    RKTableItem* tableItem = [RKTableItem tableItem];
    [tableController addHeaderRowForItem:tableItem];
    [tableController loadEmpty];
    id mockCell = [OCMockObject niceMockForClass:[UITableViewCell class]];
    [[mockCell expect] setHidden:YES];
    [tableController tableView:tableController.tableView willDisplayCell:mockCell forRowAtIndexPath:[NSIndexPath  indexPathForRow:0 inSection:0]];
    [mockCell verify];
}

- (void)testOptionallyHideFooterRowsWhenTheyAppearAndTheTableIsEmpty {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    tableController.showsFooterRowsWhenEmpty = NO;
    RKTableItem* tableItem = [RKTableItem tableItem];
    [tableController addFooterRowForItem:tableItem];
    [tableController loadEmpty];
    id mockCell = [OCMockObject niceMockForClass:[UITableViewCell class]];
    [[mockCell expect] setHidden:YES];
    [tableController tableView:tableController.tableView willDisplayCell:mockCell forRowAtIndexPath:[NSIndexPath  indexPathForRow:0 inSection:0]];
    [mockCell verify];
}

- (void)testInvokeABlockCallbackWhenTheCellAccessoryButtonIsTapped {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    RKTableItem* tableItem = [RKTableItem tableItem];
    __block BOOL dispatched = NO;
    [tableController loadTableItems:[NSArray arrayWithObject:tableItem] withMappingBlock:^(RKTableViewCellMapping* cellMapping) {
        cellMapping.onTapAccessoryButtonForObjectAtIndexPath = ^(UITableViewCell* cell, id object, NSIndexPath* indexPath) {
            dispatched = YES;
        };
    }];
    [tableController tableView:tableController.tableView accessoryButtonTappedForRowWithIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatBool(dispatched, is(equalToBool(YES)));
}

- (void)testInvokeABlockCallbackWhenTheDeleteConfirmationButtonTitleIsDetermined {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    RKTableItem* tableItem = [RKTableItem tableItem];
    NSString* deleteTitle = @"Delete Me";
    [tableController loadTableItems:[NSArray arrayWithObject:tableItem] withMappingBlock:^(RKTableViewCellMapping* cellMapping) {
        cellMapping.titleForDeleteButtonForObjectAtIndexPath = ^ NSString*(UITableViewCell* cell, id object, NSIndexPath* indexPath) {
            return deleteTitle;
        };
    }];
    NSString* delegateTitle = [tableController tableView:tableController.tableView
      titleForDeleteConfirmationButtonForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThat(delegateTitle, is(equalTo(deleteTitle)));
}

- (void)testInvokeABlockCallbackWhenCellEditingStyleIsDetermined {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    tableController.canEditRows = YES;
    RKTableItem* tableItem = [RKTableItem tableItem];
    [tableController loadTableItems:[NSArray arrayWithObject:tableItem] withMappingBlock:^(RKTableViewCellMapping* cellMapping) {
        cellMapping.editingStyleForObjectAtIndexPath = ^ UITableViewCellEditingStyle(UITableViewCell* cell, id object, NSIndexPath* indexPath) {
            return UITableViewCellEditingStyleInsert;
        };
    }];
    UITableViewCellEditingStyle delegateStyle = [tableController tableView:tableController.tableView
                                            editingStyleForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatInt(delegateStyle, is(equalToInt(UITableViewCellEditingStyleInsert)));
}

- (void)testInvokeABlockCallbackWhenACellIsMoved {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    tableController.canMoveRows = YES;
    RKTableItem* tableItem = [RKTableItem tableItem];
    NSIndexPath* moveToIndexPath = [NSIndexPath indexPathForRow:2 inSection:0];
    [tableController loadTableItems:[NSArray arrayWithObject:tableItem] withMappingBlock:^(RKTableViewCellMapping* cellMapping) {
        cellMapping.targetIndexPathForMove = ^ NSIndexPath*(UITableViewCell* cell, id object, NSIndexPath* sourceIndexPath, NSIndexPath* destinationIndexPath) {
            return moveToIndexPath;
        };
    }];
    NSIndexPath* delegateIndexPath = [tableController tableView:tableController.tableView
                      targetIndexPathForMoveFromRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]toProposedIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    assertThat(delegateIndexPath, is(equalTo(moveToIndexPath)));
}

#pragma mark Variable Height Rows

- (void)testReturnTheRowHeightConfiguredOnTheTableViewWhenVariableHeightRowsIsDisabled {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    tableController.variableHeightRows = NO;
    tableController.tableView.rowHeight = 55;
    RKTableItem* tableItem = [RKTableItem tableItem];
    [tableController loadTableItems:[NSArray arrayWithObject:tableItem] withMappingBlock:^(RKTableViewCellMapping* cellMapping) {
        cellMapping.rowHeight = 200;
    }];
    CGFloat height = [tableController tableView:tableController.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatFloat(height, is(equalToFloat(55)));
}

- (void)testReturnTheHeightFromTheTableCellMappingWhenVariableHeightRowsAreEnabled {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    tableController.variableHeightRows = YES;
    tableController.tableView.rowHeight = 55;
    RKTableItem* tableItem = [RKTableItem tableItem];
    [tableController loadTableItems:[NSArray arrayWithObject:tableItem] withMappingBlock:^(RKTableViewCellMapping* cellMapping) {
        cellMapping.rowHeight = 200;
    }];
    CGFloat height = [tableController tableView:tableController.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatFloat(height, is(equalToFloat(200)));
}

- (void)testInvokeAnBlockCallbackToDetermineTheCellHeightWhenVariableHeightRowsAreEnabled {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    tableController.variableHeightRows = YES;
    tableController.tableView.rowHeight = 55;
    RKTableItem* tableItem = [RKTableItem tableItem];
    [tableController loadTableItems:[NSArray arrayWithObject:tableItem] withMappingBlock:^(RKTableViewCellMapping* cellMapping) {
        cellMapping.rowHeight = 200;
        cellMapping.heightOfCellForObjectAtIndexPath = ^ CGFloat(id object, NSIndexPath* indexPath) { return 150; };
    }];
    CGFloat height = [tableController tableView:tableController.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatFloat(height, is(equalToFloat(150)));
}

#pragma mark - Editing

- (void)testAllowEditingWhenTheCanEditRowsPropertyIsSet {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    tableController.canEditRows = YES;
    RKTableItem* tableItem = [RKTableItem tableItem];
    [tableController loadTableItems:[NSArray arrayWithObject:tableItem]];
    BOOL delegateCanEdit = [tableController tableView:tableController.tableView
                               canEditRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatBool(delegateCanEdit, is(equalToBool(YES)));
}

- (void)testCommitADeletionWhenTheCanEditRowsPropertyIsSet {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    tableController.canEditRows = YES;
    [tableController loadObjects:[NSArray arrayWithObjects:@"First Object", @"Second Object", nil]];
    assertThatInt([tableController rowCount], is(equalToInt(2)));
    BOOL delegateCanEdit = [tableController tableView:tableController.tableView
                               canEditRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatBool(delegateCanEdit, is(equalToBool(YES)));
    [tableController tableView:tableController.tableView
           commitEditingStyle:UITableViewCellEditingStyleDelete
            forRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    assertThatInt([tableController rowCount], is(equalToInt(1)));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]],
               is(equalTo(@"First Object")));
}

- (void)testNotCommitADeletionWhenTheCanEditRowsPropertyIsNotSet {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    [tableController loadObjects:[NSArray arrayWithObjects:@"First Object", @"Second Object", nil]];
    assertThatInt([tableController rowCount], is(equalToInt(2)));
    BOOL delegateCanEdit = [tableController tableView:tableController.tableView
                               canEditRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatBool(delegateCanEdit, is(equalToBool(NO)));
    [tableController tableView:tableController.tableView
           commitEditingStyle:UITableViewCellEditingStyleDelete
            forRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    assertThatInt([tableController rowCount], is(equalToInt(2)));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]],
               is(equalTo(@"First Object")));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]],
               is(equalTo(@"Second Object")));
}

- (void)testDoNothingToCommitAnInsertionWhenTheCanEditRowsPropertyIsSet {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    tableController.canEditRows = YES;
    [tableController loadObjects:[NSArray arrayWithObjects:@"First Object", @"Second Object", nil]];
    assertThatInt([tableController rowCount], is(equalToInt(2)));
    BOOL delegateCanEdit = [tableController tableView:tableController.tableView
                               canEditRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatBool(delegateCanEdit, is(equalToBool(YES)));
    [tableController tableView:tableController.tableView
           commitEditingStyle:UITableViewCellEditingStyleInsert
            forRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    assertThatInt([tableController rowCount], is(equalToInt(2)));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]],
               is(equalTo(@"First Object")));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]],
               is(equalTo(@"Second Object")));
}

- (void)testAllowMovingWhenTheCanMoveRowsPropertyIsSet {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    tableController.canMoveRows = YES;
    RKTableItem* tableItem = [RKTableItem tableItem];
    [tableController loadTableItems:[NSArray arrayWithObject:tableItem]];
    BOOL delegateCanMove = [tableController tableView:tableController.tableView
                               canMoveRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatBool(delegateCanMove, is(equalToBool(YES)));
}

- (void)testMoveARowWithinASectionWhenTheCanMoveRowsPropertyIsSet {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    tableController.canMoveRows = YES;
    [tableController loadObjects:[NSArray arrayWithObjects:@"First Object", @"Second Object", nil]];
    assertThatInt([tableController rowCount], is(equalToInt(2)));
    BOOL delegateCanMove = [tableController tableView:tableController.tableView
                               canMoveRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatBool(delegateCanMove, is(equalToBool(YES)));
    [tableController tableView:tableController.tableView
           moveRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                  toIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    assertThatInt([tableController rowCount], is(equalToInt(2)));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]],
               is(equalTo(@"First Object")));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]],
               is(equalTo(@"Second Object")));
}

- (void)testMoveARowAcrossSectionsWhenTheCanMoveRowsPropertyIsSet {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    tableController.canMoveRows = YES;
    [tableController loadObjects:[NSArray arrayWithObjects:@"First Object", @"Second Object", nil]];
    assertThatInt([tableController rowCount], is(equalToInt(2)));
    assertThatInt([tableController sectionCount], is(equalToInt(1)));
    BOOL delegateCanMove = [tableController tableView:tableController.tableView
                               canMoveRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatBool(delegateCanMove, is(equalToBool(YES)));
    [tableController tableView:tableController.tableView
           moveRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                  toIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
    assertThatInt([tableController rowCount], is(equalToInt(2)));
    assertThatInt([tableController sectionCount], is(equalToInt(2)));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]],
               is(equalTo(@"First Object")));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]],
               is(equalTo(@"Second Object")));
}

- (void)testNotMoveARowWhenTheCanMoveRowsPropertyIsNotSet {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    [tableController loadObjects:[NSArray arrayWithObjects:@"First Object", @"Second Object", nil]];
    assertThatInt([tableController rowCount], is(equalToInt(2)));
    BOOL delegateCanMove = [tableController tableView:tableController.tableView
                               canMoveRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatBool(delegateCanMove, is(equalToBool(NO)));
    [tableController tableView:tableController.tableView
           moveRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                  toIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    assertThatInt([tableController rowCount], is(equalToInt(2)));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]],
               is(equalTo(@"First Object")));
    assertThat([tableController objectForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]],
               is(equalTo(@"Second Object")));
}

#pragma mark - Reachability Integration

- (void)testTransitionToTheOnlineStateWhenAReachabilityNoticeIsReceived {
    RKObjectManager* objectManager = RKTestNewObjectManager();
    id mockManager = [OCMockObject partialMockForObject:objectManager];
    BOOL online = YES;
    [[[mockManager stub] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = objectManager;
    [[NSNotificationCenter defaultCenter] postNotificationName:RKObjectManagerDidBecomeOnlineNotification object:objectManager];
    assertThatBool(tableController.isOnline, is(equalToBool(YES)));
}

- (void)testTransitionToTheOfflineStateWhenAReachabilityNoticeIsReceived {
    RKObjectManager* objectManager = RKTestNewObjectManager();
    id mockManager = [OCMockObject partialMockForObject:objectManager];
    BOOL online = NO;
    [[[mockManager stub] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = objectManager;
    [[NSNotificationCenter defaultCenter] postNotificationName:RKObjectManagerDidBecomeOfflineNotification object:objectManager];
    assertThatBool(tableController.isOnline, is(equalToBool(NO)));
}

- (void)testNotifyTheDelegateOnTransitionToOffline {
    RKObjectManager* objectManager = RKTestNewObjectManager();
    id mockManager = [OCMockObject partialMockForObject:objectManager];
    [mockManager setExpectationOrderMatters:YES];
    RKObjectManagerNetworkStatus networkStatus = RKObjectManagerNetworkStatusOnline;
    [[[mockManager stub] andReturnValue:OCMOCK_VALUE(networkStatus)] networkStatus];
    BOOL online = YES; // Initial online state for table
    [[[mockManager expect] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    online = NO; // After the notification is posted
    [[[mockManager expect] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    id mockDelegate = [OCMockObject mockForProtocol:@protocol(RKTableControllerDelegate)];
    [[mockDelegate expect] tableControllerDidBecomeOffline:tableController];
    tableController.delegate = mockDelegate;
    [[NSNotificationCenter defaultCenter] postNotificationName:RKObjectManagerDidBecomeOfflineNotification object:objectManager];
    [mockDelegate verify];
}

- (void)testPostANotificationOnTransitionToOffline {
    RKObjectManager* objectManager = RKTestNewObjectManager();
    id mockManager = [OCMockObject partialMockForObject:objectManager];
    [mockManager setExpectationOrderMatters:YES];
    RKObjectManagerNetworkStatus networkStatus = RKObjectManagerNetworkStatusOnline;
    [[[mockManager stub] andReturnValue:OCMOCK_VALUE(networkStatus)] networkStatus];
    BOOL online = YES; // Initial online state for table
    [[[mockManager expect] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    online = NO; // After the notification is posted
    [[[mockManager expect] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];

    id observerMock = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:observerMock name:RKTableControllerDidBecomeOffline object:tableController];
    [[observerMock expect] notificationWithName:RKTableControllerDidBecomeOffline object:tableController];

    [[NSNotificationCenter defaultCenter] postNotificationName:RKObjectManagerDidBecomeOfflineNotification object:objectManager];
    [observerMock verify];
}

- (void)testNotifyTheDelegateOnTransitionToOnline {
    RKObjectManager* objectManager = RKTestNewObjectManager();
    id mockManager = [OCMockObject partialMockForObject:objectManager];
    BOOL online = YES;
    [[[mockManager stub] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = objectManager;
    id mockDelegate = [OCMockObject mockForProtocol:@protocol(RKTableControllerDelegate)];
    [[mockDelegate expect] tableControllerDidBecomeOnline:tableController];
    tableController.delegate = mockDelegate;
    [[NSNotificationCenter defaultCenter] postNotificationName:RKObjectManagerDidBecomeOnlineNotification object:objectManager];
    [mockDelegate verify];
    [mockManager release];
    [mockDelegate release];
}

- (void)testPostANotificationOnTransitionToOnline {
    RKObjectManager* objectManager = RKTestNewObjectManager();
    id mockManager = [OCMockObject partialMockForObject:objectManager];
    BOOL online = YES;
    [[[mockManager stub] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    tableController.objectManager = objectManager;

    id observerMock = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:observerMock name:RKTableControllerDidBecomeOnline object:tableController];
    [[observerMock expect] notificationWithName:RKTableControllerDidBecomeOnline object:tableController];

    [[NSNotificationCenter defaultCenter] postNotificationName:RKObjectManagerDidBecomeOnlineNotification object:objectManager];
    [observerMock verify];
}

- (void)testShowTheOfflineImageOnTransitionToOffline {
    RKObjectManager* objectManager = RKTestNewObjectManager();
    id mockManager = [OCMockObject partialMockForObject:objectManager];
    [mockManager setExpectationOrderMatters:YES];
    RKObjectManagerNetworkStatus networkStatus = RKObjectManagerNetworkStatusOnline;
    [[[mockManager stub] andReturnValue:OCMOCK_VALUE(networkStatus)] networkStatus];
    BOOL online = YES; // Initial online state for table
    [[[mockManager expect] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    online = NO; // After the notification is posted
    [[[mockManager expect] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    UIImage* image = [RKTestFixture imageWithContentsOfFixture:@"blake.png"];
    tableController.imageForOffline = image;

    [[NSNotificationCenter defaultCenter] postNotificationName:RKObjectManagerDidBecomeOfflineNotification object:objectManager];
    assertThatBool(tableController.isOnline, is(equalToBool(NO)));
    UIImageView* imageView = tableController.stateOverlayImageView;
    assertThat(imageView, isNot(nilValue()));
    assertThat(imageView.image, is(equalTo(image)));
}

- (void)testRemoveTheOfflineImageOnTransitionToOnlineFromOffline {
    RKObjectManager* objectManager = RKTestNewObjectManager();
    id mockManager = [OCMockObject partialMockForObject:objectManager];
    [mockManager setExpectationOrderMatters:YES];
    RKObjectManagerNetworkStatus networkStatus = RKObjectManagerNetworkStatusOnline;
    [[[mockManager stub] andReturnValue:OCMOCK_VALUE(networkStatus)] networkStatus];
    BOOL online = YES; // Initial online state for table
    [[[mockManager expect] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    online = NO; // After the notification is posted
    [[[mockManager expect] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    UIImage* image = [RKTestFixture imageWithContentsOfFixture:@"blake.png"];
    tableController.imageForOffline = image;

    [[NSNotificationCenter defaultCenter] postNotificationName:RKObjectManagerDidBecomeOfflineNotification object:objectManager];
    assertThatBool(tableController.isOnline, is(equalToBool(NO)));
    UIImageView* imageView = tableController.stateOverlayImageView;
    assertThat(imageView, isNot(nilValue()));
    assertThat(imageView.image, is(equalTo(image)));

    online = YES;
    [[[mockManager expect] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    [[NSNotificationCenter defaultCenter] postNotificationName:RKObjectManagerDidBecomeOnlineNotification object:objectManager];
    assertThatBool(tableController.isOnline, is(equalToBool(YES)));
    imageView = tableController.stateOverlayImageView;
    assertThat(imageView.image, is(nilValue()));
}

#pragma mark - Swipe Menus

- (void)testAllowSwipeMenusWhenTheSwipeViewsEnabledPropertyIsSet {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    tableController.cellSwipeViewsEnabled = YES;
    RKTableItem* tableItem = [RKTableItem tableItem];
    [tableController loadTableItems:[NSArray arrayWithObject:tableItem]];
    assertThatBool(tableController.canEditRows, is(equalToBool(NO)));
    assertThatBool(tableController.cellSwipeViewsEnabled, is(equalToBool(YES)));
}

- (void)testNotAllowEditingWhenTheSwipeViewsEnabledPropertyIsSet {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    tableController.cellSwipeViewsEnabled = YES;
    RKTableItem* tableItem = [RKTableItem tableItem];
    [tableController loadTableItems:[NSArray arrayWithObject:tableItem]];
    BOOL delegateCanEdit = [tableController tableView:tableController.tableView
                               canEditRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatBool(delegateCanEdit, is(equalToBool(NO)));
}

- (void)testRaiseAnExceptionWhenEnablingSwipeViewsWhenTheCanEditRowsPropertyIsSet {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    tableController.canEditRows = YES;

    NSException* exception = nil;
    @try {
        tableController.cellSwipeViewsEnabled = YES;
    }
    @catch (NSException *e) {
        exception = e;
    }
    @finally {
        assertThat(exception, isNot(nilValue()));
    }
}

- (void)testCallTheDelegateBeforeShowingTheSwipeView {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    tableController.cellSwipeViewsEnabled = YES;
    RKTableItem* tableItem = [RKTableItem tableItem];
    RKTestTableControllerDelegate* delegate = [RKTestTableControllerDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                  willAddSwipeView:OCMOCK_ANY
                                                            toCell:OCMOCK_ANY
                                                         forObject:OCMOCK_ANY];
    tableController.delegate = mockDelegate;
    [tableController loadTableItems:[NSArray arrayWithObject:tableItem]];
    [tableController addSwipeViewTo:[RKTestUserTableViewCell new]
                        withObject:@"object"
                         direction:UISwipeGestureRecognizerDirectionRight];
    [mockDelegate verify];
}

- (void)testCallTheDelegateBeforeHidingTheSwipeView {
//    RKLogConfigureByName("RestKit/UI", RKLogLevelTrace);
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableController = [RKTableController tableControllerForTableViewController:viewController];
    tableController.cellSwipeViewsEnabled = YES;
    RKTableItem* tableItem = [RKTableItem tableItem];
    RKTestTableControllerDelegate* delegate = [RKTestTableControllerDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                                  willAddSwipeView:OCMOCK_ANY
                                                            toCell:OCMOCK_ANY
                                                         forObject:OCMOCK_ANY];
    [[[mockDelegate expect] andForwardToRealObject] tableController:tableController
                                               willRemoveSwipeView:OCMOCK_ANY
                                                          fromCell:OCMOCK_ANY
                                                         forObject:OCMOCK_ANY];
    tableController.delegate = mockDelegate;
    [tableController loadTableItems:[NSArray arrayWithObject:tableItem]];
    [tableController addSwipeViewTo:[RKTestUserTableViewCell new]
                        withObject:@"object"
                         direction:UISwipeGestureRecognizerDirectionRight];
    [tableController animationDidStopAddingSwipeView:nil
                                           finished:nil
                                            context:nil];
    [tableController removeSwipeView:YES];
    [mockDelegate verify];
}

@end
