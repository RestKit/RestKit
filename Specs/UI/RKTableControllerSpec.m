//
//  RKTableControllerSpec.m
//  RestKit
//
//  Created by Blake Watters on 8/3/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKTableController.h"
#import "RKTableSection.h"
#import "RKSpecUser.h"
#import "RKMappableObject.h"
#import "RKAbstractTableController_Internals.h"

// Expose the object loader delegate for testing purposes...
@interface RKTableController () <RKObjectLoaderDelegate>
- (void)animationDidStopAddingSwipeView:(NSString*)animationID finished:(NSNumber*)finished context:(void*)context;
@end

@interface RKSpecTableViewModelDelegate : NSObject <RKTableControllerDelegate>

@property (nonatomic, assign) NSTimeInterval timeout;
@property (nonatomic, assign) BOOL awaitingResponse;

+ (id)tableViewModelDelegate;
- (void)waitForLoad;
@end

@implementation RKSpecTableViewModelDelegate

@synthesize timeout = _timeout;
@synthesize awaitingResponse = _awaitingResponse;

+ (id)tableViewModelDelegate {
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

- (void)tableViewModelDidFinishLoad:(RKAbstractTableController*)tableViewModel {
    _awaitingResponse = NO;
}

- (void)tableViewModel:(RKAbstractTableController*)tableViewModel didFailLoadWithError:(NSError *)error {
    _awaitingResponse = NO;
}

// NOTE - Delegate methods below are implemented to allow trampoline through
// OCMock expectations

- (void)tableViewModelDidStartLoad:(RKAbstractTableController*)tableViewModel {}
- (void)tableViewModelDidBecomeEmpty:(RKAbstractTableController*)tableViewModel {}
- (void)tableViewModel:(RKAbstractTableController*)tableViewModel willLoadTableWithObjectLoader:(RKObjectLoader*)objectLoader {}
- (void)tableViewModel:(RKAbstractTableController*)tableViewModel didLoadTableWithObjectLoader:(RKObjectLoader*)objectLoader {}
- (void)tableViewModelDidCancelLoad:(RKAbstractTableController*)tableViewModel {}
- (void)tableViewModel:(RKAbstractTableController*)tableViewModel willBeginEditing:(id)object atIndexPath:(NSIndexPath*)indexPath {}
- (void)tableViewModel:(RKAbstractTableController*)tableViewModel didEndEditing:(id)object atIndexPath:(NSIndexPath*)indexPath {}
- (void)tableViewModel:(RKAbstractTableController*)tableViewModel didInsertSection:(RKTableSection*)section atIndex:(NSUInteger)sectionIndex {}
- (void)tableViewModel:(RKAbstractTableController*)tableViewModel didRemoveSection:(RKTableSection*)section atIndex:(NSUInteger)sectionIndex {}
- (void)tableViewModel:(RKAbstractTableController*)tableViewModel didInsertObject:(id)object atIndexPath:(NSIndexPath*)indexPath {}
- (void)tableViewModel:(RKAbstractTableController*)tableViewModel didUpdateObject:(id)object atIndexPath:(NSIndexPath*)indexPath {}
- (void)tableViewModel:(RKAbstractTableController*)tableViewModel didDeleteObject:(id)object atIndexPath:(NSIndexPath*)indexPath {}
- (void)tableViewModel:(RKAbstractTableController*)tableViewModel willAddSwipeView:(UIView*)swipeView toCell:(UITableViewCell*)cell forObject:(id)object {}
- (void)tableViewModel:(RKAbstractTableController*)tableViewModel willRemoveSwipeView:(UIView*)swipeView fromCell:(UITableViewCell*)cell forObject:(id)object {}

@end

@interface RKTableControllerSpecTableViewController : UITableViewController
@end

@implementation RKTableControllerSpecTableViewController
@end

@interface RKTableControllerSpecViewController : UIViewController
@end

@implementation RKTableControllerSpecViewController
@end

@interface RKSpecUserTableViewCell : UITableViewCell
@end

@implementation RKSpecUserTableViewCell
@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface RKTableControllerSpec : RKSpec <RKSpecUI> {
    NSAutoreleasePool *_autoreleasePool;
}

@end

@implementation RKTableControllerSpec

- (void)beforeAll {
    RKLogConfigureByName("RestKit/UI", RKLogLevelTrace);
}

- (void)before {
    [RKObjectManager setSharedManager:nil];
    _autoreleasePool = [[NSAutoreleasePool alloc] init];
}

- (void)after {
    [_autoreleasePool drain];
    _autoreleasePool = nil;
}

- (void)itShouldInitializeWithATableViewController {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    assertThat(viewController.tableView, is(notNilValue()));
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    assertThat(tableViewModel.viewController, is(equalTo(viewController)));
    assertThat(tableViewModel.tableView, is(equalTo(viewController.tableView)));
}

- (void)itShouldInitializeWithATableViewAndViewController {
    UITableView* tableView = [UITableView new];
    RKTableControllerSpecViewController* viewController = [RKTableControllerSpecViewController new];
    RKTableController* tableViewModel = [RKTableController tableControllerWithTableView:tableView forViewController:viewController];
    assertThat(tableViewModel.viewController, is(equalTo(viewController)));
    assertThat(tableViewModel.tableView, is(equalTo(tableView)));
}

- (void)itShouldAlwaysHaveAtLeastOneSection {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    assertThat(viewController.tableView, is(notNilValue()));
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    assertThatInt(tableViewModel.sectionCount, is(equalToInt(1)));
}

- (void)itShouldDisconnectFromTheTableViewOnDealloc {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    assertThatInt(tableViewModel.sectionCount, is(equalToInt(1)));
    [pool drain];
    assertThat(viewController.tableView.delegate, is(nilValue()));
    assertThat(viewController.tableView.dataSource, is(nilValue()));
}

- (void)itShouldNotDisconnectFromTheTableViewIfDelegateOrDataSourceAreNotSelf {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [[RKTableController alloc] initWithTableView:viewController.tableView viewController:viewController];
    viewController.tableView.delegate = viewController;
    viewController.tableView.dataSource = viewController;
    assertThatInt(tableViewModel.sectionCount, is(equalToInt(1)));
    [tableViewModel release];
    assertThat(viewController.tableView.delegate, isNot(nilValue()));
    assertThat(viewController.tableView.dataSource, isNot(nilValue()));
}

#pragma mark - Section Management

- (void)itShouldAddASection {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    RKTableSection* section = [RKTableSection section];
    RKSpecTableViewModelDelegate* delegate = [RKSpecTableViewModelDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModel:tableViewModel
                                                  didInsertSection:section
                                                           atIndex:1];
    tableViewModel.delegate = mockDelegate;
    [tableViewModel addSection:section];
    assertThatInt([tableViewModel.sections count], is(equalToInt(2)));
    [mockDelegate verify];
}

- (void)itShouldConnectTheSectionToTheTableModelOnAdd {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    RKTableSection* section = [RKTableSection section];
    RKSpecTableViewModelDelegate* delegate = [RKSpecTableViewModelDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModel:tableViewModel
                                                  didInsertSection:section
                                                           atIndex:1];
    tableViewModel.delegate = mockDelegate;
    [tableViewModel addSection:section];
    assertThat(section.tableViewModel, is(equalTo(tableViewModel)));
    [mockDelegate verify];
}

- (void)itShouldConnectTheSectionToTheCellMappingsOfTheTableModelWhenNil {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    RKTableSection* section = [RKTableSection section];
    RKSpecTableViewModelDelegate* delegate = [RKSpecTableViewModelDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModel:tableViewModel
                                                  didInsertSection:section
                                                           atIndex:1];
    tableViewModel.delegate = mockDelegate;
    assertThat(section.cellMappings, is(nilValue()));
    [tableViewModel addSection:section];
    assertThat(section.cellMappings, is(equalTo(tableViewModel.cellMappings)));
    [mockDelegate verify];
}

- (void)itShouldNotConnectTheSectionToTheCellMappingsOfTheTableModelWhenNonNil {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    RKTableSection* section = [RKTableSection section];
    RKSpecTableViewModelDelegate* delegate = [RKSpecTableViewModelDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModel:tableViewModel
                                                  didInsertSection:section
                                                           atIndex:1];
    tableViewModel.delegate = mockDelegate;
    section.cellMappings = [NSMutableDictionary dictionary];
    [tableViewModel addSection:section];
    assertThatBool(section.cellMappings == tableViewModel.cellMappings, is(equalToBool(NO)));
    [mockDelegate verify];
}

- (void)itShouldCountTheSections {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    RKTableSection* section = [RKTableSection section];
    RKSpecTableViewModelDelegate* delegate = [RKSpecTableViewModelDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModel:tableViewModel
                                                  didInsertSection:section
                                                           atIndex:1];
    tableViewModel.delegate = mockDelegate;
    [tableViewModel addSection:section];
    assertThatInt(tableViewModel.sectionCount, is(equalToInt(2)));
    [mockDelegate verify];
}

- (void)itShouldRemoveASection {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    RKTableSection* section = [RKTableSection section];
    RKSpecTableViewModelDelegate* delegate = [RKSpecTableViewModelDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModel:tableViewModel
                                                  didInsertSection:section
                                                           atIndex:1];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModel:tableViewModel
                                                  didRemoveSection:section
                                                           atIndex:1];
    tableViewModel.delegate = mockDelegate;
    [tableViewModel addSection:section];
    assertThatInt(tableViewModel.sectionCount, is(equalToInt(2)));
    [tableViewModel removeSection:section];
    assertThatInt(tableViewModel.sectionCount, is(equalToInt(1)));
    [mockDelegate verify];
}

- (void)itShouldNotLetRemoveTheLastSection {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    RKTableSection* section = [RKTableSection section];
    RKSpecTableViewModelDelegate* delegate = [RKSpecTableViewModelDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModel:tableViewModel
                                                  didInsertSection:section
                                                           atIndex:1];
    tableViewModel.delegate = mockDelegate;
    [tableViewModel addSection:section];
    assertThatInt(tableViewModel.sectionCount, is(equalToInt(2)));
    [tableViewModel removeSection:section];
    [mockDelegate verify];
}

- (void)itShouldInsertASectionAtASpecificIndex {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    RKTableSection* referenceSection = [RKTableSection section];
    RKSpecTableViewModelDelegate* delegate = [RKSpecTableViewModelDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModel:tableViewModel
                                                  didInsertSection:referenceSection
                                                           atIndex:2];
    [tableViewModel addSection:[RKTableSection section]];
    [tableViewModel addSection:[RKTableSection section]];
    [tableViewModel addSection:[RKTableSection section]];
    [tableViewModel addSection:[RKTableSection section]];
    tableViewModel.delegate = mockDelegate;
    [tableViewModel insertSection:referenceSection atIndex:2];
    assertThatInt(tableViewModel.sectionCount, is(equalToInt(6)));
    assertThat([tableViewModel.sections objectAtIndex:2], is(equalTo(referenceSection)));
    [mockDelegate verify];
}

- (void)itShouldRemoveASectionByIndex {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    RKTableSection* section = [RKTableSection section];
    RKSpecTableViewModelDelegate* delegate = [RKSpecTableViewModelDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModel:tableViewModel
                                                  didInsertSection:section
                                                           atIndex:1];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModel:tableViewModel
                                                  didRemoveSection:section
                                                           atIndex:1];
    tableViewModel.delegate = mockDelegate;
    [tableViewModel addSection:section];
    assertThatInt(tableViewModel.sectionCount, is(equalToInt(2)));
    [tableViewModel removeSectionAtIndex:1];
    assertThatInt(tableViewModel.sectionCount, is(equalToInt(1)));
    [mockDelegate verify];
}

- (void)itShouldRaiseAnExceptionWhenAttemptingToRemoveTheLastSection {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    NSException* exception = nil;
    @try {
        [tableViewModel removeSectionAtIndex:0];
    }
    @catch (NSException *e) {
        exception = e;
    }
    @finally {
        assertThat(exception, isNot(nilValue()));
    }
}

- (void)itShouldReturnTheSectionAtAGivenIndex {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    RKTableSection* referenceSection = [RKTableSection section];
    RKSpecTableViewModelDelegate* delegate = [RKSpecTableViewModelDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModel:tableViewModel
                                                  didInsertSection:referenceSection
                                                           atIndex:2];
    [tableViewModel addSection:[RKTableSection section]];
    [tableViewModel addSection:[RKTableSection section]];
    [tableViewModel addSection:[RKTableSection section]];
    [tableViewModel addSection:[RKTableSection section]];
    tableViewModel.delegate = mockDelegate;
    [tableViewModel insertSection:referenceSection atIndex:2];
    assertThatInt(tableViewModel.sectionCount, is(equalToInt(6)));
    assertThat([tableViewModel sectionAtIndex:2], is(equalTo(referenceSection)));
    [mockDelegate verify];
}

- (void)itShouldRemoveAllSections {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    RKSpecTableViewModelDelegate* delegate = [RKSpecTableViewModelDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModel:tableViewModel
                                                  didInsertSection:OCMOCK_ANY
                                                           atIndex:0];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModel:tableViewModel
                                                  didInsertSection:OCMOCK_ANY
                                                           atIndex:1];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModel:tableViewModel
                                                  didInsertSection:OCMOCK_ANY
                                                           atIndex:2];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModel:tableViewModel
                                                  didInsertSection:OCMOCK_ANY
                                                           atIndex:3];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModel:tableViewModel
                                                  didInsertSection:OCMOCK_ANY
                                                           atIndex:4];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModel:tableViewModel
                                                  didRemoveSection:OCMOCK_ANY
                                                           atIndex:0];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModel:tableViewModel
                                                  didRemoveSection:OCMOCK_ANY
                                                           atIndex:1];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModel:tableViewModel
                                                  didRemoveSection:OCMOCK_ANY
                                                           atIndex:2];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModel:tableViewModel
                                                  didRemoveSection:OCMOCK_ANY
                                                           atIndex:3];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModel:tableViewModel
                                                  didRemoveSection:OCMOCK_ANY
                                                           atIndex:4];
    tableViewModel.delegate = mockDelegate;
    [tableViewModel addSection:[RKTableSection section]];
    [tableViewModel addSection:[RKTableSection section]];
    [tableViewModel addSection:[RKTableSection section]];
    [tableViewModel addSection:[RKTableSection section]];
    assertThatInt(tableViewModel.sectionCount, is(equalToInt(5)));
    [tableViewModel removeAllSections];
    assertThatInt(tableViewModel.sectionCount, is(equalToInt(1)));
    [mockDelegate verify];
}

- (void)itShouldReturnASectionByHeaderTitle {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    [tableViewModel addSection:[RKTableSection section]];
    [tableViewModel addSection:[RKTableSection section]];
    RKTableSection* titledSection = [RKTableSection section];
    titledSection.headerTitle = @"Testing";
    [tableViewModel addSection:titledSection];
    [tableViewModel addSection:[RKTableSection section]];
    assertThat([tableViewModel sectionWithHeaderTitle:@"Testing"], is(equalTo(titledSection)));
}

- (void)itShouldNotifyTheTableViewOnSectionInsertion {
    RKTableControllerSpecViewController *viewController = [RKTableControllerSpecViewController new];
    id mockTableView = [OCMockObject niceMockForClass:[UITableView class]];
    RKTableController *tableViewModel = [RKTableController tableControllerWithTableView:mockTableView forViewController:viewController];
    [[mockTableView expect] insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:tableViewModel.defaultRowAnimation];
    [tableViewModel addSection:[RKTableSection section]];
    [mockTableView verify];
}

- (void)itShouldNotifyTheTableViewOnSectionRemoval {
    RKTableControllerSpecViewController *viewController = [RKTableControllerSpecViewController new];
    id mockTableView = [OCMockObject niceMockForClass:[UITableView class]];
    RKTableController *tableViewModel = [RKTableController tableControllerWithTableView:mockTableView forViewController:viewController];
    [[mockTableView expect] insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:tableViewModel.defaultRowAnimation];
    [[mockTableView expect] deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:tableViewModel.defaultRowAnimation];
    RKTableSection *section = [RKTableSection section];
    [tableViewModel addSection:section];
    [tableViewModel removeSection:section];
    [mockTableView verify];
}

- (void)itShouldNotifyTheTableOfSectionRemovalAndReaddWhenRemovingAllSections {
    RKTableControllerSpecViewController *viewController = [RKTableControllerSpecViewController new];
    id mockTableView = [OCMockObject niceMockForClass:[UITableView class]];
    RKTableController *tableViewModel = [RKTableController tableControllerWithTableView:mockTableView forViewController:viewController];
    [[mockTableView expect] deleteSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:tableViewModel.defaultRowAnimation];
    [[mockTableView expect] deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:tableViewModel.defaultRowAnimation];
    [[mockTableView expect] insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:tableViewModel.defaultRowAnimation];
    RKTableSection *section = [RKTableSection section];
    [tableViewModel addSection:section];
    [tableViewModel removeAllSections];
    [mockTableView verify];
}

#pragma mark - UITableViewDataSource specs

- (void)itShouldRaiseAnExceptionIfSentAMessageWithATableViewItIsNotBoundTo {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
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
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    assertThatInt([tableViewModel numberOfSectionsInTableView:viewController.tableView], is(equalToInt(1)));
    [tableViewModel addSection:[RKTableSection section]];
    assertThatInt([tableViewModel numberOfSectionsInTableView:viewController.tableView], is(equalToInt(2)));
}

- (void)itShouldReturnTheNumberOfRowsInSectionInTableView {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    assertThatInt([tableViewModel tableView:viewController.tableView numberOfRowsInSection:0], is(equalToInt(0)));
    NSArray* objects = [NSArray arrayWithObject:@"one"];
    [tableViewModel loadObjects:objects];
    assertThatInt([tableViewModel tableView:viewController.tableView numberOfRowsInSection:0], is(equalToInt(1)));
}

- (void)itShouldReturnTheHeaderTitleForSection {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    RKTableSection* section = [RKTableSection section];
    [tableViewModel addSection:section];
    assertThat([tableViewModel tableView:viewController.tableView titleForHeaderInSection:1], is(nilValue()));
    section.headerTitle = @"RestKit!";
    assertThat([tableViewModel tableView:viewController.tableView titleForHeaderInSection:1], is(equalTo(@"RestKit!")));
}

- (void)itShouldReturnTheTitleForFooterInSection {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    RKTableSection* section = [RKTableSection section];
    [tableViewModel addSection:section];
    assertThat([tableViewModel tableView:viewController.tableView titleForFooterInSection:1], is(nilValue()));
    section.footerTitle = @"RestKit!";
    assertThat([tableViewModel tableView:viewController.tableView titleForFooterInSection:1], is(equalTo(@"RestKit!")));
}

- (void)itShouldReturnTheNumberOfRowsAcrossAllSections {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    RKTableSection* section = [RKTableSection section];
    id sectionMock = [OCMockObject partialMockForObject:section];
    NSUInteger rowCount = 5;
    [[[sectionMock stub] andReturnValue:OCMOCK_VALUE(rowCount)] rowCount];
    [tableViewModel addSection:section];
    assertThatInt(tableViewModel.rowCount, is(equalToInt(5)));
}

- (void)itShouldReturnTheTableViewCellForRowAtIndexPath {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    RKTableItem* item = [RKTableItem tableItemWithText:@"Test!" detailText:@"Details!" image:nil];
    [tableViewModel loadTableItems:[NSArray arrayWithObject:item] inSection:0 withMapping:[RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
        // Detail text label won't appear with default style...
        cellMapping.style = UITableViewCellStyleValue1;
        [cellMapping addDefaultMappings];
    }]];
    UITableViewCell* cell = [tableViewModel tableView:tableViewModel.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThat(cell.textLabel.text, is(equalTo(@"Test!")));
    assertThat(cell.detailTextLabel.text, is(equalTo(@"Details!")));

}

#pragma mark - Table Cell Mapping

- (void)itShouldInitializeCellMappings {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    assertThat(tableViewModel.cellMappings, is(notNilValue()));
}

- (void)itShouldRegisterMappingsForObjectsToTableViewCell {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    assertThat([tableViewModel.cellMappings cellMappingForClass:[RKSpecUser class]], is(nilValue()));
    [tableViewModel mapObjectsWithClass:[RKSpecUser class] toTableCellsWithMapping:[RKTableViewCellMapping cellMapping]];
    RKObjectMapping* mapping = [tableViewModel.cellMappings cellMappingForClass:[RKSpecUser class]];
    assertThat(mapping, isNot(nilValue()));
    assertThatBool([mapping.objectClass isSubclassOfClass:[UITableViewCell class]], is(equalToBool(YES)));
}

- (void)itShouldDefaultTheReuseIdentifierToTheNameOfTheObjectClass {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    assertThat([tableViewModel.cellMappings cellMappingForClass:[RKSpecUser class]], is(nilValue()));
    RKTableViewCellMapping* cellMapping = [RKTableViewCellMapping cellMapping];
    [tableViewModel mapObjectsWithClass:[RKSpecUser class] toTableCellsWithMapping:cellMapping];
    assertThat(cellMapping.reuseIdentifier, is(equalTo(@"RKSpecUser")));
}

- (void)itShouldReturnTheObjectForARowAtIndexPath {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    RKSpecUser* user = [RKSpecUser user];
    [tableViewModel loadObjects:[NSArray arrayWithObject:user]];
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    assertThatBool(user == [tableViewModel objectForRowAtIndexPath:indexPath], is(equalToBool(YES)));
}

- (void)itShouldReturnTheCellMappingForTheRowAtIndexPath {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    RKTableViewCellMapping* cellMapping = [RKTableViewCellMapping cellMapping];
    [tableViewModel mapObjectsWithClass:[RKSpecUser class] toTableCellsWithMapping:cellMapping];
    [tableViewModel loadObjects:[NSArray arrayWithObject:[RKSpecUser user]]];
    NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    assertThat([tableViewModel cellMappingForObjectAtIndexPath:indexPath], is(equalTo(cellMapping)));
}

- (void)itShouldReturnATableViewCellForTheObjectAtAGivenIndexPath {
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
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:tableViewController];
    [tableViewModel insertSection:section atIndex:0];
    tableViewModel.cellMappings = mappings;

    UITableViewCell* cell = [tableViewModel cellForObjectAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThat(cell, isNot(nilValue()));
    assertThat(cell.textLabel.text, is(equalTo(@"Testing!!")));
}

- (void)itShouldChangeTheReuseIdentifierWhenMutatedWithinTheBlockInitializer {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    assertThat([tableViewModel.cellMappings cellMappingForClass:[RKSpecUser class]], is(nilValue()));
    [tableViewModel mapObjectsWithClass:[RKSpecUser class] toTableCellsWithMapping:[RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping *cellMapping) {
        cellMapping.cellClass = [RKSpecUserTableViewCell class];
        cellMapping.reuseIdentifier = @"RKSpecUserOverride";
    }]];
    RKTableViewCellMapping* userCellMapping = [tableViewModel.cellMappings cellMappingForClass:[RKSpecUser class]];
    assertThat(userCellMapping, isNot(nilValue()));
    assertThat(userCellMapping.reuseIdentifier, is(equalTo(@"RKSpecUserOverride")));
}

#pragma mark - Static Object Loading

- (void)itShouldLoadAnArrayOfObjects {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    NSArray* objects = [NSArray arrayWithObject:@"one"];
    assertThat([tableViewModel sectionAtIndex:0].objects, is(empty()));
    [tableViewModel loadObjects:objects];
    assertThat([tableViewModel sectionAtIndex:0].objects, is(equalTo(objects)));
}

- (void)itShouldLoadAnArrayOfObjectsToTheSpecifiedSection {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    [tableViewModel addSection:[RKTableSection section]];
    NSArray* objects = [NSArray arrayWithObject:@"one"];
    assertThat([tableViewModel sectionAtIndex:1].objects, is(empty()));
    [tableViewModel loadObjects:objects inSection:1];
    assertThat([tableViewModel sectionAtIndex:1].objects, is(equalTo(objects)));
}

- (void)itShouldLoadAnArrayOfTableItems {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    NSArray* tableItems = [RKTableItem tableItemsFromStrings:@"One", @"Two", @"Three", nil];
    [tableViewModel loadTableItems:tableItems];
    assertThatBool([tableViewModel isLoaded], is(equalToBool(YES)));
    assertThatInt(tableViewModel.rowCount, is(equalToInt(3)));
    UITableViewCell* cellOne = [tableViewModel tableView:tableViewModel.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UITableViewCell* cellTwo = [tableViewModel tableView:tableViewModel.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    UITableViewCell* cellThree = [tableViewModel tableView:tableViewModel.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    assertThat(cellOne.textLabel.text, is(equalTo(@"One")));
    assertThat(cellTwo.textLabel.text, is(equalTo(@"Two")));
    assertThat(cellThree.textLabel.text, is(equalTo(@"Three")));
}

- (void)itShouldAllowYouToTriggerAnEmptyLoad {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    assertThatBool([tableViewModel isLoaded], is(equalToBool(NO)));
    [tableViewModel loadEmpty];
    assertThatBool([tableViewModel isLoaded], is(equalToBool(YES)));
    assertThatBool([tableViewModel isEmpty], is(equalToBool(YES)));
}

#pragma mark - Network Load

- (void)itShouldLoadCollectionOfObjectsAndMapThemIntoTableViewCells {
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    objectManager.client.cachePolicy = RKRequestCachePolicyNone;
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    tableViewModel.objectManager = objectManager;
    [tableViewModel mapObjectsWithClass:[RKSpecUser class] toTableCellsWithMapping:[RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* mapping) {
        mapping.cellClass = [RKSpecUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];
    RKSpecTableViewModelDelegate* delegate = [RKSpecTableViewModelDelegate tableViewModelDelegate];
    delegate.timeout = 10;
    tableViewModel.delegate = delegate;
    [tableViewModel loadTableFromResourcePath:@"/JSON/users.json" usingBlock:^(RKObjectLoader* objectLoader) {
        objectLoader.objectMapping = [RKObjectMapping mappingForClass:[RKSpecUser class] usingBlock:^(RKObjectMapping* mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [delegate waitForLoad];
    assertThatBool([tableViewModel isLoaded], is(equalToBool(YES)));
    assertThatInt(tableViewModel.rowCount, is(equalToInt(3)));
}

- (void)itShouldSetTheModelToTheLoadedStateIfObjectsAreLoadedSuccessfully {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    assertThatBool([tableViewModel isLoaded], is(equalToBool(NO)));
    NSArray* objects = [NSArray arrayWithObject:[RKSpecUser new]];
    id mockLoader = [OCMockObject mockForClass:[RKObjectLoader class]];
    [tableViewModel objectLoader:mockLoader didLoadObjects:objects];
    assertThatBool([tableViewModel isLoading], is(equalToBool(NO)));
    assertThatBool([tableViewModel isLoaded], is(equalToBool(YES)));
}

- (void)itShouldSetTheModelToErrorStateIfTheObjectLoaderFailsWithAnError {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    id mockObjectLoader = [OCMockObject niceMockForClass:[RKObjectLoader class]];
    NSError* error = [NSError errorWithDomain:@"Test" code:0 userInfo:nil];
    [tableViewModel objectLoader:mockObjectLoader didFailWithError:error];
    assertThatBool([tableViewModel isLoading], is(equalToBool(NO)));
    assertThatBool([tableViewModel isLoaded], is(equalToBool(YES)));
    assertThatBool([tableViewModel isError], is(equalToBool(YES)));
    assertThatBool([tableViewModel isEmpty], is(equalToBool(YES)));
}

- (void)itShouldSetTheModelToAnEmptyStateIfTheObjectLoaderReturnsAnEmptyCollection {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    assertThatBool([tableViewModel isLoaded], is(equalToBool(NO)));
    NSArray* objects = [NSArray array];
    id mockLoader = [OCMockObject mockForClass:[RKObjectLoader class]];
    [tableViewModel objectLoader:mockLoader didLoadObjects:objects];
    assertThatBool([tableViewModel isLoading], is(equalToBool(NO)));
    assertThatBool([tableViewModel isEmpty], is(equalToBool(YES)));
}

- (void)itShouldSetTheModelToALoadedStateEvenIfTheObjectLoaderReturnsAnEmptyCollection {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    assertThatBool([tableViewModel isLoaded], is(equalToBool(NO)));
    NSArray* objects = [NSArray array];
    id mockLoader = [OCMockObject mockForClass:[RKObjectLoader class]];
    [tableViewModel objectLoader:mockLoader didLoadObjects:objects];
    assertThatBool([tableViewModel isLoading], is(equalToBool(NO)));
    assertThatBool([tableViewModel isEmpty], is(equalToBool(YES)));
    assertThatBool([tableViewModel isLoaded], is(equalToBool(YES)));
}

- (void)itShouldEnterTheLoadingStateWhenTheRequestStartsLoading {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    assertThatBool([tableViewModel isLoaded], is(equalToBool(NO)));
    assertThatBool([tableViewModel isLoading], is(equalToBool(NO)));
    id mockLoader = [OCMockObject mockForClass:[RKObjectLoader class]];
    [tableViewModel requestDidStartLoad:mockLoader];
    assertThatBool([tableViewModel isLoading], is(equalToBool(YES)));
}

- (void)itShouldExitTheLoadingStateWhenTheRequestFinishesLoading {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    assertThatBool([tableViewModel isLoaded], is(equalToBool(NO)));
    assertThatBool([tableViewModel isLoading], is(equalToBool(NO)));
    id mockLoader = [OCMockObject mockForClass:[RKObjectLoader class]];
    [tableViewModel requestDidStartLoad:mockLoader];
    assertThatBool([tableViewModel isLoading], is(equalToBool(YES)));
    [tableViewModel objectLoaderDidFinishLoading:mockLoader];
    assertThatBool([tableViewModel isLoading], is(equalToBool(NO)));
}

- (void)itShouldClearTheLoadingStateWhenARequestIsCancelled {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    assertThatBool([tableViewModel isLoaded], is(equalToBool(NO)));
    assertThatBool([tableViewModel isLoading], is(equalToBool(NO)));
    id mockLoader = [OCMockObject mockForClass:[RKObjectLoader class]];
    [tableViewModel requestDidStartLoad:mockLoader];
    assertThatBool([tableViewModel isLoading], is(equalToBool(YES)));
    [tableViewModel requestDidCancelLoad:mockLoader];
    assertThatBool([tableViewModel isLoading], is(equalToBool(NO)));
}

- (void)itShouldClearTheLoadingStateWhenARequestTimesOut {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    assertThatBool([tableViewModel isLoaded], is(equalToBool(NO)));
    assertThatBool([tableViewModel isLoading], is(equalToBool(NO)));
    id mockLoader = [OCMockObject mockForClass:[RKObjectLoader class]];
    [tableViewModel requestDidStartLoad:mockLoader];
    assertThatBool([tableViewModel isLoading], is(equalToBool(YES)));
    [tableViewModel requestDidTimeout:mockLoader];
    assertThatBool([tableViewModel isLoading], is(equalToBool(NO)));
}

- (void)itShouldDoSomethingWhenTheRequestLoadsAnUnexpectedResponse {
    RKLogCritical(@"PENDING - Undefined Behavior!!!");
}

#pragma mark - RKTableViewDelegate specs

- (void)itShouldNotifyTheDelegateWhenLoadingStarts {
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    tableViewModel.objectManager = objectManager;
    [tableViewModel mapObjectsWithClass:[RKSpecUser class] toTableCellsWithMapping:[RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* mapping) {
        mapping.cellClass = [RKSpecUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];
    id mockDelegate = [OCMockObject partialMockForObject:[RKSpecTableViewModelDelegate new]];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModelDidStartLoad:tableViewModel];
    tableViewModel.delegate = mockDelegate;
    [tableViewModel loadTableFromResourcePath:@"/JSON/users.json" usingBlock:^(RKObjectLoader* objectLoader) {
        objectLoader.objectMapping = [RKObjectMapping mappingForClass:[RKSpecUser class] usingBlock:^(RKObjectMapping* mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [mockDelegate waitForLoad];
    [mockDelegate verify];
}

- (void)itShouldNotifyTheDelegateWhenLoadingFinishes {
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    tableViewModel.objectManager = objectManager;
    [tableViewModel mapObjectsWithClass:[RKSpecUser class] toTableCellsWithMapping:[RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* mapping) {
        mapping.cellClass = [RKSpecUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];
    RKSpecTableViewModelDelegate* delegate = [RKSpecTableViewModelDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModelDidFinishLoad:tableViewModel];
    tableViewModel.delegate = mockDelegate;
    [tableViewModel loadTableFromResourcePath:@"/JSON/users.json" usingBlock:^(RKObjectLoader* objectLoader) {
        objectLoader.objectMapping = [RKObjectMapping mappingForClass:[RKSpecUser class] usingBlock:^(RKObjectMapping* mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [mockDelegate waitForLoad];
    [mockDelegate verify];
}

- (void)itShouldNotifyTheDelegateWhenAnErrorOccurs {
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    tableViewModel.objectManager = objectManager;
    [tableViewModel mapObjectsWithClass:[RKSpecUser class] toTableCellsWithMapping:[RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* mapping) {
        mapping.cellClass = [RKSpecUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];
    RKSpecTableViewModelDelegate* delegate = [RKSpecTableViewModelDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModel:tableViewModel didFailLoadWithError:OCMOCK_ANY];
    tableViewModel.delegate = mockDelegate;
    [tableViewModel loadTableFromResourcePath:@"/fail" usingBlock:^(RKObjectLoader* objectLoader) {
        objectLoader.objectMapping = [RKObjectMapping mappingForClass:[RKSpecUser class] usingBlock:^(RKObjectMapping* mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [mockDelegate waitForLoad];
    [mockDelegate verify];
}

- (void)itShouldNotifyTheDelegateWhenAnEmptyCollectionIsLoaded {
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    objectManager.client.cachePolicy = RKRequestCachePolicyNone;
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    tableViewModel.objectManager = objectManager;
    [tableViewModel mapObjectsWithClass:[RKSpecUser class] toTableCellsWithMapping:[RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* mapping) {
        mapping.cellClass = [RKSpecUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];
    RKSpecTableViewModelDelegate* delegate = [RKSpecTableViewModelDelegate new];
    delegate.timeout = 5;
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModelDidBecomeEmpty:tableViewModel];
    tableViewModel.delegate = mockDelegate;
    [tableViewModel loadTableFromResourcePath:@"/empty/array" usingBlock:^(RKObjectLoader* objectLoader) {
        objectLoader.objectMapping = [RKObjectMapping mappingForClass:[RKSpecUser class] usingBlock:^(RKObjectMapping* mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [mockDelegate waitForLoad];
    [mockDelegate verify];
}

- (void)itShouldNotifyTheDelegateWhenModelWillLoadWithObjectLoader {
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    tableViewModel.objectManager = objectManager;
    [tableViewModel mapObjectsWithClass:[RKSpecUser class] toTableCellsWithMapping:[RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* mapping) {
        mapping.cellClass = [RKSpecUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];
    RKSpecTableViewModelDelegate* delegate = [RKSpecTableViewModelDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModel:tableViewModel willLoadTableWithObjectLoader:OCMOCK_ANY];
    tableViewModel.delegate = mockDelegate;
    [tableViewModel loadTableFromResourcePath:@"/empty/array" usingBlock:^(RKObjectLoader* objectLoader) {
        objectLoader.objectMapping = [RKObjectMapping mappingForClass:[RKSpecUser class] usingBlock:^(RKObjectMapping* mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [mockDelegate waitForLoad];
    [mockDelegate verify];
}

- (void)itShouldNotifyTheDelegateWhenModelDidLoadWithObjectLoader {
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    tableViewModel.objectManager = objectManager;
    [tableViewModel mapObjectsWithClass:[RKSpecUser class] toTableCellsWithMapping:[RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* mapping) {
        mapping.cellClass = [RKSpecUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];
    RKSpecTableViewModelDelegate* delegate = [RKSpecTableViewModelDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModel:tableViewModel didLoadTableWithObjectLoader:OCMOCK_ANY];
    tableViewModel.delegate = mockDelegate;
    [tableViewModel loadTableFromResourcePath:@"/empty/array" usingBlock:^(RKObjectLoader* objectLoader) {
        objectLoader.objectMapping = [RKObjectMapping mappingForClass:[RKSpecUser class] usingBlock:^(RKObjectMapping* mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [mockDelegate waitForLoad];
    [mockDelegate verify];
}

- (void)itShouldNotifyTheDelegateWhenModelDidCancelLoad {
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    tableViewModel.objectManager = objectManager;
    [tableViewModel mapObjectsWithClass:[RKSpecUser class] toTableCellsWithMapping:[RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* mapping) {
        mapping.cellClass = [RKSpecUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];
    RKSpecTableViewModelDelegate* delegate = [RKSpecTableViewModelDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModelDidCancelLoad:tableViewModel];
    tableViewModel.delegate = mockDelegate;
    [tableViewModel loadTableFromResourcePath:@"/empty/array" usingBlock:^(RKObjectLoader* objectLoader) {
        objectLoader.objectMapping = [RKObjectMapping mappingForClass:[RKSpecUser class] usingBlock:^(RKObjectMapping* mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [tableViewModel cancelLoad];
    [mockDelegate waitForLoad];
    [mockDelegate verify];
}

- (void)itShouldNotifyTheDelegateWhenDidEndEditingARow {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    RKTableItem* tableItem = [RKTableItem tableItem];
    RKSpecTableViewModelDelegate* delegate = [RKSpecTableViewModelDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModel:tableViewModel
                                                     didEndEditing:OCMOCK_ANY
                                                       atIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    tableViewModel.delegate = mockDelegate;
    [tableViewModel loadTableItems:[NSArray arrayWithObject:tableItem]];
    [tableViewModel tableView:tableViewModel.tableView didEndEditingRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [mockDelegate verify];
}

- (void)itShouldNotifyTheDelegateWhenWillBeginEditingARow {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    RKTableItem* tableItem = [RKTableItem tableItem];
    RKSpecTableViewModelDelegate* delegate = [RKSpecTableViewModelDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModel:tableViewModel
                                                  willBeginEditing:OCMOCK_ANY
                                                       atIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    tableViewModel.delegate = mockDelegate;
    [tableViewModel loadTableItems:[NSArray arrayWithObject:tableItem]];
    [tableViewModel tableView:tableViewModel.tableView willBeginEditingRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [mockDelegate verify];
}

- (void)itShouldNotifyTheDelegateWhenAnObjectIsInserted {
    NSArray* objects = [NSArray arrayWithObject:@"first object"];
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    RKSpecTableViewModelDelegate* delegate = [RKSpecTableViewModelDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModel:tableViewModel
                                                   didInsertObject:@"first object"
                                                       atIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModel:tableViewModel
                                                   didInsertObject:@"new object"
                                                       atIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    tableViewModel.delegate = mockDelegate;
    [tableViewModel loadObjects:objects];
    assertThat([tableViewModel objectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]],
               is(equalTo(@"first object")));
    [[tableViewModel.sections objectAtIndex:0] insertObject:@"new object" atIndex:1];
    assertThat([[tableViewModel.sections objectAtIndex:0] objectAtIndex:0], is(equalTo(@"first object")));
    assertThat([[tableViewModel.sections objectAtIndex:0] objectAtIndex:1], is(equalTo(@"new object")));
    [mockDelegate verify];
}

- (void)itShouldNotifyTheDelegateWhenAnObjectIsUpdated {
    NSArray* objects = [NSArray arrayWithObjects:@"first object", @"second object", nil];
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    RKSpecTableViewModelDelegate* delegate = [RKSpecTableViewModelDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModel:tableViewModel
                                                   didInsertObject:@"first object"
                                                       atIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModel:tableViewModel
                                                   didInsertObject:@"second object"
                                                       atIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModel:tableViewModel
                                                   didUpdateObject:@"new second object"
                                                       atIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    tableViewModel.delegate = mockDelegate;
    [tableViewModel loadObjects:objects];
    assertThat([[tableViewModel.sections objectAtIndex:0] objectAtIndex:0], is(equalTo(@"first object")));
    assertThat([[tableViewModel.sections objectAtIndex:0] objectAtIndex:1], is(equalTo(@"second object")));
    [[tableViewModel.sections objectAtIndex:0] replaceObjectAtIndex:1 withObject:@"new second object"];
    assertThat([[tableViewModel.sections objectAtIndex:0] objectAtIndex:1], is(equalTo(@"new second object")));
    [mockDelegate verify];
}

- (void)itShouldNotifyTheDelegateWhenAnObjectIsDeleted {
    NSArray* objects = [NSArray arrayWithObjects:@"first object", @"second object", nil];
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    RKSpecTableViewModelDelegate* delegate = [RKSpecTableViewModelDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModel:tableViewModel
                                                   didInsertObject:@"first object"
                                                       atIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModel:tableViewModel
                                                   didInsertObject:@"second object"
                                                       atIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModel:tableViewModel
                                                   didDeleteObject:@"second object"
                                                       atIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    tableViewModel.delegate = mockDelegate;
    [tableViewModel loadObjects:objects];
    assertThat([[tableViewModel.sections objectAtIndex:0] objectAtIndex:0], is(equalTo(@"first object")));
    assertThat([[tableViewModel.sections objectAtIndex:0] objectAtIndex:1], is(equalTo(@"second object")));
    [[tableViewModel.sections objectAtIndex:0] removeObjectAtIndex:1];
    assertThat([[tableViewModel.sections objectAtIndex:0] objectAtIndex:0], is(equalTo(@"first object")));
    [mockDelegate verify];
}

#pragma mark - Notifications

- (void)itShouldPostANotificationWhenLoadingStarts {
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    tableViewModel.objectManager = objectManager;
    [tableViewModel mapObjectsWithClass:[RKSpecUser class] toTableCellsWithMapping:[RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* mapping) {
        mapping.cellClass = [RKSpecUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];
    id observerMock = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:observerMock name:RKTableControllerDidStartLoadNotification object:tableViewModel];
    [[observerMock expect] notificationWithName:RKTableControllerDidStartLoadNotification object:tableViewModel];
    RKSpecTableViewModelDelegate* delegate = [RKSpecTableViewModelDelegate new];
    tableViewModel.delegate = delegate;
    [tableViewModel loadTableFromResourcePath:@"/JSON/users.json" usingBlock:^(RKObjectLoader* objectLoader) {
        objectLoader.objectMapping = [RKObjectMapping mappingForClass:[RKSpecUser class] usingBlock:^(RKObjectMapping* mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [delegate waitForLoad];
    [observerMock verify];
}

- (void)itShouldPostANotificationWhenLoadingFinishes {
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    tableViewModel.objectManager = objectManager;
    [tableViewModel mapObjectsWithClass:[RKSpecUser class] toTableCellsWithMapping:[RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* mapping) {
        mapping.cellClass = [RKSpecUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];

    id observerMock = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:observerMock name:RKTableControllerDidFinishLoadNotification object:tableViewModel];
    [[observerMock expect] notificationWithName:RKTableControllerDidFinishLoadNotification object:tableViewModel];
    RKSpecTableViewModelDelegate* delegate = [RKSpecTableViewModelDelegate new];
    tableViewModel.delegate = delegate;

    [tableViewModel loadTableFromResourcePath:@"/JSON/users.json" usingBlock:^(RKObjectLoader* objectLoader) {
        objectLoader.objectMapping = [RKObjectMapping mappingForClass:[RKSpecUser class] usingBlock:^(RKObjectMapping* mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [delegate waitForLoad];
    [observerMock verify];
}

- (void)itShouldPostANotificationWhenAnErrorOccurs {
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    tableViewModel.objectManager = objectManager;
    [tableViewModel mapObjectsWithClass:[RKSpecUser class] toTableCellsWithMapping:[RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* mapping) {
        mapping.cellClass = [RKSpecUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];

    id observerMock = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:observerMock name:RKTableControllerDidLoadErrorNotification object:tableViewModel];
    [[observerMock expect] notificationWithName:RKTableControllerDidLoadErrorNotification object:tableViewModel userInfo:OCMOCK_ANY];
    RKSpecTableViewModelDelegate* delegate = [RKSpecTableViewModelDelegate new];
    tableViewModel.delegate = delegate;

    [tableViewModel loadTableFromResourcePath:@"/fail" usingBlock:^(RKObjectLoader* objectLoader) {
        objectLoader.objectMapping = [RKObjectMapping mappingForClass:[RKSpecUser class] usingBlock:^(RKObjectMapping* mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [delegate waitForLoad];
    [observerMock verify];
}

- (void)itShouldPostANotificationWhenAnEmptyCollectionIsLoaded {
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    objectManager.client.cachePolicy = RKRequestCachePolicyNone;
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    tableViewModel.objectManager = objectManager;
    [tableViewModel mapObjectsWithClass:[RKSpecUser class] toTableCellsWithMapping:[RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* mapping) {
        mapping.cellClass = [RKSpecUserTableViewCell class];
        [mapping mapKeyPath:@"name" toAttribute:@"textLabel.text"];
        [mapping mapKeyPath:@"nickName" toAttribute:@"detailTextLabel.text"];
    }]];

    id observerMock = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:observerMock name:RKTableControllerDidLoadEmptyNotification object:tableViewModel];
    [[observerMock expect] notificationWithName:RKTableControllerDidLoadEmptyNotification object:tableViewModel];
    RKSpecTableViewModelDelegate* delegate = [RKSpecTableViewModelDelegate new];
    tableViewModel.delegate = delegate;
    [tableViewModel loadTableFromResourcePath:@"/empty/array" usingBlock:^(RKObjectLoader* objectLoader) {
        objectLoader.objectMapping = [RKObjectMapping mappingForClass:[RKSpecUser class] usingBlock:^(RKObjectMapping* mapping) {
            [mapping mapAttributes:@"name", nil];
        }];
    }];
    [delegate waitForLoad];
    [observerMock verify];
}

#pragma mark - State Views

- (void)itShouldPermitYouToOverlayAnImageOnTheTable {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    UIImage* image = [UIImage imageNamed:@"blake.png"];
    [tableViewModel showImageInOverlay:image];
    UIImageView* imageView = tableViewModel.stateOverlayImageView;
    assertThat(imageView, isNot(nilValue()));
    assertThat(imageView.image, is(equalTo(image)));
}

- (void)itShouldPermitYouToRemoveAnImageOverlayFromTheTable {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    UIImage* image = [UIImage imageNamed:@"blake.png"];
    [tableViewModel showImageInOverlay:image];
    assertThat([tableViewModel.tableView.superview subviews], isNot(empty()));
    [tableViewModel removeImageOverlay];
    assertThat([tableViewModel.tableView.superview subviews], is(nilValue()));
}

- (void)itShouldTriggerDisplayOfTheErrorViewOnTransitionToErrorState {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    UIImage* image = [UIImage imageNamed:@"blake.png"];
    tableViewModel.imageForError = image;
    id mockError = [OCMockObject mockForClass:[NSError class]];
    [tableViewModel objectLoader:nil didFailWithError:mockError];
    assertThatBool([tableViewModel isError], is(equalToBool(YES)));
    UIImageView* imageView = tableViewModel.stateOverlayImageView;
    assertThat(imageView, isNot(nilValue()));
    assertThat(imageView.image, is(equalTo(image)));
}

- (void)itShouldTriggerHidingOfTheErrorViewOnTransitionOutOfTheErrorState {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    UIImage* image = [UIImage imageNamed:@"blake.png"];
    tableViewModel.imageForError = image;
    id mockError = [OCMockObject niceMockForClass:[NSError class]];
    [tableViewModel objectLoader:nil didFailWithError:mockError];
    assertThatBool([tableViewModel isError], is(equalToBool(YES)));
    UIImageView* imageView = tableViewModel.stateOverlayImageView;
    assertThat(imageView, isNot(nilValue()));
    assertThat(imageView.image, is(equalTo(image)));
    [tableViewModel loadTableItems:[NSArray arrayWithObject:[RKTableItem tableItem]]];
    assertThat(tableViewModel.error, is(nilValue()));
    assertThat(tableViewModel.stateOverlayImageView.image, is(nilValue()));
}

- (void)itShouldTriggerDisplayOfTheEmptyViewOnTransitionToEmptyState {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    UIImage* image = [UIImage imageNamed:@"blake.png"];
    tableViewModel.imageForEmpty = image;
    [tableViewModel loadEmpty];
    assertThatBool([tableViewModel isEmpty], is(equalToBool(YES)));
    UIImageView* imageView = tableViewModel.stateOverlayImageView;
    assertThat(imageView, isNot(nilValue()));
    assertThat(imageView.image, is(equalTo(image)));
}

- (void)itShouldTriggerHidingOfTheEmptyViewOnTransitionOutOfTheEmptyState {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    UIImage* image = [UIImage imageNamed:@"blake.png"];
    tableViewModel.imageForEmpty = image;
    [tableViewModel loadEmpty];
    assertThatBool([tableViewModel isEmpty], is(equalToBool(YES)));
    UIImageView* imageView = tableViewModel.stateOverlayImageView;
    assertThat(imageView, isNot(nilValue()));
    assertThat(imageView.image, is(equalTo(image)));
    [tableViewModel loadTableItems:[NSArray arrayWithObject:[RKTableItem tableItem]]];
    assertThat(tableViewModel.stateOverlayImageView.image, is(nilValue()));
}

- (void)itShouldTriggerDisplayOfTheLoadingViewOnTransitionToTheLoadingState {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    UIActivityIndicatorView* spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    tableViewModel.loadingView = spinner;
    [tableViewModel setValue:[NSNumber numberWithBool:YES] forKey:@"loading"];
    UIView* view = [tableViewModel.tableOverlayView.subviews lastObject];
    assertThatBool(view == spinner, is(equalToBool(YES)));
}

- (void)itShouldTriggerHidingOfTheLoadingViewOnTransitionOutOfTheLoadingState {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    UIActivityIndicatorView* spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    tableViewModel.loadingView = spinner;
    [tableViewModel setValue:[NSNumber numberWithBool:YES] forKey:@"loading"];
    UIView* loadingView = [tableViewModel.tableOverlayView.subviews lastObject];
    assertThatBool(loadingView == spinner, is(equalToBool(YES)));
    [tableViewModel setValue:[NSNumber numberWithBool:NO] forKey:@"loading"];
    loadingView = [tableViewModel.tableOverlayView.subviews lastObject];
    assertThat(loadingView, is(nilValue()));
}

#pragma mark - Header, Footer, and Empty Rows

- (void)itShouldShowHeaderRows {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    [tableViewModel addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    NSArray* tableItems = [RKTableItem tableItemsFromStrings:@"One", @"Two", @"Three", nil];
    [tableViewModel loadTableItems:tableItems];
    assertThatBool([tableViewModel isLoaded], is(equalToBool(YES)));
    assertThatInt(tableViewModel.rowCount, is(equalToInt(4)));
    UITableViewCell* cellOne = [tableViewModel tableView:tableViewModel.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UITableViewCell* cellTwo = [tableViewModel tableView:tableViewModel.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    UITableViewCell* cellThree = [tableViewModel tableView:tableViewModel.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    UITableViewCell* cellFour = [tableViewModel tableView:tableViewModel.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
    assertThat(cellOne.textLabel.text, is(equalTo(@"Header")));
    assertThat(cellTwo.textLabel.text, is(equalTo(@"One")));
    assertThat(cellThree.textLabel.text, is(equalTo(@"Two")));
    assertThat(cellFour.textLabel.text, is(equalTo(@"Three")));
    [tableViewModel tableView:tableViewModel.tableView willDisplayCell:cellOne forRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [tableViewModel tableView:tableViewModel.tableView willDisplayCell:cellTwo forRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    [tableViewModel tableView:tableViewModel.tableView willDisplayCell:cellThree forRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    [tableViewModel tableView:tableViewModel.tableView willDisplayCell:cellFour forRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
    assertThatBool(cellOne.hidden, is(equalToBool(NO)));
    assertThatBool(cellTwo.hidden, is(equalToBool(NO)));
    assertThatBool(cellThree.hidden, is(equalToBool(NO)));
    assertThatBool(cellFour.hidden, is(equalToBool(NO)));
}

- (void)itShouldShowFooterRows {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    [tableViewModel addFooterRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    NSArray* tableItems = [RKTableItem tableItemsFromStrings:@"One", @"Two", @"Three", nil];
    [tableViewModel loadTableItems:tableItems];
    assertThatBool([tableViewModel isLoaded], is(equalToBool(YES)));
    assertThatInt(tableViewModel.rowCount, is(equalToInt(4)));
    UITableViewCell* cellOne = [tableViewModel tableView:tableViewModel.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UITableViewCell* cellTwo = [tableViewModel tableView:tableViewModel.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    UITableViewCell* cellThree = [tableViewModel tableView:tableViewModel.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    UITableViewCell* cellFour = [tableViewModel tableView:tableViewModel.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
    assertThat(cellOne.textLabel.text, is(equalTo(@"One")));
    assertThat(cellTwo.textLabel.text, is(equalTo(@"Two")));
    assertThat(cellThree.textLabel.text, is(equalTo(@"Three")));
    assertThat(cellFour.textLabel.text, is(equalTo(@"Footer")));
    [tableViewModel tableView:tableViewModel.tableView willDisplayCell:cellOne forRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [tableViewModel tableView:tableViewModel.tableView willDisplayCell:cellTwo forRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    [tableViewModel tableView:tableViewModel.tableView willDisplayCell:cellThree forRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    [tableViewModel tableView:tableViewModel.tableView willDisplayCell:cellFour forRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
    assertThatBool(cellOne.hidden, is(equalToBool(NO)));
    assertThatBool(cellTwo.hidden, is(equalToBool(NO)));
    assertThatBool(cellThree.hidden, is(equalToBool(NO)));
    assertThatBool(cellFour.hidden, is(equalToBool(NO)));
}

- (void)itShouldHideHeaderRowsWhenEmptyWhenPropertyIsNotSet {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    [tableViewModel addHeaderRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Header";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    tableViewModel.showsHeaderRowsWhenEmpty = NO;
    [tableViewModel loadEmpty];
    assertThatBool([tableViewModel isLoaded], is(equalToBool(YES)));
    assertThatInt(tableViewModel.rowCount, is(equalToInt(1)));
    assertThatBool([tableViewModel isEmpty], is(equalToBool(YES)));
    UITableViewCell* cellOne = [tableViewModel tableView:tableViewModel.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThat(cellOne.textLabel.text, is(equalTo(@"Header")));
    [tableViewModel tableView:tableViewModel.tableView willDisplayCell:cellOne forRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatBool(cellOne.hidden, is(equalToBool(YES)));
}

- (void)itShouldHideFooterRowsWhenEmptyWhenPropertyIsNotSet {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    [tableViewModel addFooterRowForItem:[RKTableItem tableItemUsingBlock:^(RKTableItem* tableItem) {
        tableItem.text = @"Footer";
        tableItem.cellMapping = [RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
            [cellMapping addDefaultMappings];
        }];
    }]];
    tableViewModel.showsFooterRowsWhenEmpty = NO;
    [tableViewModel loadEmpty];
    assertThatBool([tableViewModel isLoaded], is(equalToBool(YES)));
    assertThatInt(tableViewModel.rowCount, is(equalToInt(1)));
    assertThatBool([tableViewModel isEmpty], is(equalToBool(YES)));
    UITableViewCell* cellOne = [tableViewModel tableView:tableViewModel.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThat(cellOne.textLabel.text, is(equalTo(@"Footer")));
    [tableViewModel tableView:tableViewModel.tableView willDisplayCell:cellOne forRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatBool(cellOne.hidden, is(equalToBool(YES)));
}

- (void)itShouldRemoveHeaderAndFooterCountsWhenDeterminingIsEmpty {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
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
    tableViewModel.showsFooterRowsWhenEmpty = NO;
    tableViewModel.showsHeaderRowsWhenEmpty = NO;
    [tableViewModel loadEmpty];
    assertThatBool([tableViewModel isLoaded], is(equalToBool(YES)));
    assertThatInt(tableViewModel.rowCount, is(equalToInt(3)));
    assertThatBool([tableViewModel isEmpty], is(equalToBool(YES)));
}

- (void)itShouldNotShowTheEmptyItemWhenTheTableIsNotEmpty {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
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
    NSArray* tableItems = [RKTableItem tableItemsFromStrings:@"One", @"Two", @"Three", nil];
    [tableViewModel loadTableItems:tableItems];
    assertThatBool([tableViewModel isLoaded], is(equalToBool(YES)));
    assertThatInt(tableViewModel.rowCount, is(equalToInt(6)));
    UITableViewCell* cellOne = [tableViewModel tableView:tableViewModel.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UITableViewCell* cellTwo = [tableViewModel tableView:tableViewModel.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    UITableViewCell* cellThree = [tableViewModel tableView:tableViewModel.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    UITableViewCell* cellFour = [tableViewModel tableView:tableViewModel.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
    UITableViewCell* cellFive = [tableViewModel tableView:tableViewModel.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:0]];
    UITableViewCell* cellSix = [tableViewModel tableView:tableViewModel.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:5 inSection:0]];
    assertThat(cellOne.textLabel.text, is(equalTo(@"Empty")));
    assertThat(cellTwo.textLabel.text, is(equalTo(@"Header")));
    assertThat(cellThree.textLabel.text, is(equalTo(@"One")));
    assertThat(cellFour.textLabel.text, is(equalTo(@"Two")));
    assertThat(cellFive.textLabel.text, is(equalTo(@"Three")));
    assertThat(cellSix.textLabel.text, is(equalTo(@"Footer")));
    [tableViewModel tableView:tableViewModel.tableView willDisplayCell:cellOne forRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [tableViewModel tableView:tableViewModel.tableView willDisplayCell:cellTwo forRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    [tableViewModel tableView:tableViewModel.tableView willDisplayCell:cellThree forRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    [tableViewModel tableView:tableViewModel.tableView willDisplayCell:cellFour forRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
    [tableViewModel tableView:tableViewModel.tableView willDisplayCell:cellFive forRowAtIndexPath:[NSIndexPath indexPathForRow:4 inSection:0]];
    [tableViewModel tableView:tableViewModel.tableView willDisplayCell:cellSix forRowAtIndexPath:[NSIndexPath indexPathForRow:5 inSection:0]];
    assertThatBool(cellOne.hidden, is(equalToBool(YES)));
    assertThatBool(cellTwo.hidden, is(equalToBool(NO)));
    assertThatBool(cellThree.hidden, is(equalToBool(NO)));
    assertThatBool(cellFour.hidden, is(equalToBool(NO)));
    assertThatBool(cellFive.hidden, is(equalToBool(NO)));
    assertThatBool(cellSix.hidden, is(equalToBool(NO)));
}

- (void)itShouldShowTheEmptyItemWhenTheTableIsEmpty {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
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
    [tableViewModel loadEmpty];
    assertThatBool([tableViewModel isLoaded], is(equalToBool(YES)));
    assertThatInt(tableViewModel.rowCount, is(equalToInt(3)));
    assertThatBool([tableViewModel isEmpty], is(equalToBool(YES)));
    UITableViewCell* cellOne = [tableViewModel tableView:tableViewModel.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UITableViewCell* cellTwo = [tableViewModel tableView:tableViewModel.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    UITableViewCell* cellThree = [tableViewModel tableView:tableViewModel.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    assertThat(cellOne.textLabel.text, is(equalTo(@"Empty")));
    assertThat(cellTwo.textLabel.text, is(equalTo(@"Header")));
    assertThat(cellThree.textLabel.text, is(equalTo(@"Footer")));
    [tableViewModel tableView:tableViewModel.tableView willDisplayCell:cellOne forRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [tableViewModel tableView:tableViewModel.tableView willDisplayCell:cellTwo forRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    [tableViewModel tableView:tableViewModel.tableView willDisplayCell:cellThree forRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    assertThatBool(cellOne.hidden, is(equalToBool(NO)));
    assertThatBool(cellTwo.hidden, is(equalToBool(YES)));
    assertThatBool(cellThree.hidden, is(equalToBool(YES)));
}

- (void)itShouldShowTheEmptyItemPlusHeadersAndFootersWhenTheTableIsEmpty {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
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
    [tableViewModel loadEmpty];
    assertThatBool([tableViewModel isLoaded], is(equalToBool(YES)));
    assertThatInt(tableViewModel.rowCount, is(equalToInt(3)));
    assertThatBool([tableViewModel isEmpty], is(equalToBool(YES)));
    UITableViewCell* cellOne = [tableViewModel tableView:tableViewModel.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    UITableViewCell* cellTwo = [tableViewModel tableView:tableViewModel.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    UITableViewCell* cellThree = [tableViewModel tableView:tableViewModel.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    assertThat(cellOne.textLabel.text, is(equalTo(@"Empty")));
    assertThat(cellTwo.textLabel.text, is(equalTo(@"Header")));
    assertThat(cellThree.textLabel.text, is(equalTo(@"Footer")));
    [tableViewModel tableView:tableViewModel.tableView willDisplayCell:cellOne forRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    [tableViewModel tableView:tableViewModel.tableView willDisplayCell:cellTwo forRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    [tableViewModel tableView:tableViewModel.tableView willDisplayCell:cellThree forRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    assertThatBool(cellOne.hidden, is(equalToBool(NO)));
    assertThatBool(cellTwo.hidden, is(equalToBool(NO)));
    assertThatBool(cellThree.hidden, is(equalToBool(NO)));
}

#pragma mark - UITableViewDelegate specs

- (void)itShouldInvokeTheOnSelectCellForObjectAtIndexPathBlockHandler {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    RKTableItem* tableItem = [RKTableItem tableItem];
    __block BOOL dispatched = NO;
    [tableViewModel loadTableItems:[NSArray arrayWithObject:tableItem] withMapping:[RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
        cellMapping.onSelectCellForObjectAtIndexPath = ^(UITableViewCell* cell, id object, NSIndexPath* indexPath) {
            dispatched = YES;
        };
    }]];
    [tableViewModel tableView:tableViewModel.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
     assertThatBool(dispatched, is(equalToBool(YES)));
}

- (void)itShouldInvokeTheOnCellWillAppearForObjectAtIndexPathBlockHandler {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    RKTableItem* tableItem = [RKTableItem tableItem];
    __block BOOL dispatched = NO;
    [tableViewModel loadTableItems:[NSArray arrayWithObject:tableItem] withMapping:[RKTableViewCellMapping cellMappingUsingBlock:^(RKTableViewCellMapping* cellMapping) {
        cellMapping.onCellWillAppearForObjectAtIndexPath = ^(UITableViewCell* cell, id object, NSIndexPath* indexPath) {
            dispatched = YES;
        };
    }]];
    id mockCell = [OCMockObject niceMockForClass:[UITableViewCell class]];
    [tableViewModel tableView:tableViewModel.tableView willDisplayCell:mockCell forRowAtIndexPath:[NSIndexPath  indexPathForRow:0 inSection:0]];
    assertThatBool(dispatched, is(equalToBool(YES)));
}

- (void)itShouldOptionallyHideHeaderRowsWhenTheyAppearAndTheTableIsEmpty {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    tableViewModel.showsHeaderRowsWhenEmpty = NO;
    RKTableItem* tableItem = [RKTableItem tableItem];
    [tableViewModel addHeaderRowForItem:tableItem];
    [tableViewModel loadEmpty];
    id mockCell = [OCMockObject niceMockForClass:[UITableViewCell class]];
    [[mockCell expect] setHidden:YES];
    [tableViewModel tableView:tableViewModel.tableView willDisplayCell:mockCell forRowAtIndexPath:[NSIndexPath  indexPathForRow:0 inSection:0]];
    [mockCell verify];
}

- (void)itShouldOptionallyHideFooterRowsWhenTheyAppearAndTheTableIsEmpty {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    tableViewModel.showsFooterRowsWhenEmpty = NO;
    RKTableItem* tableItem = [RKTableItem tableItem];
    [tableViewModel addFooterRowForItem:tableItem];
    [tableViewModel loadEmpty];
    id mockCell = [OCMockObject niceMockForClass:[UITableViewCell class]];
    [[mockCell expect] setHidden:YES];
    [tableViewModel tableView:tableViewModel.tableView willDisplayCell:mockCell forRowAtIndexPath:[NSIndexPath  indexPathForRow:0 inSection:0]];
    [mockCell verify];
}

- (void)itShouldInvokeABlockCallbackWhenTheCellAccessoryButtonIsTapped {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    RKTableItem* tableItem = [RKTableItem tableItem];
    __block BOOL dispatched = NO;
    [tableViewModel loadTableItems:[NSArray arrayWithObject:tableItem] withMappingBlock:^(RKTableViewCellMapping* cellMapping) {
        cellMapping.onTapAccessoryButtonForObjectAtIndexPath = ^(UITableViewCell* cell, id object, NSIndexPath* indexPath) {
            dispatched = YES;
        };
    }];
    [tableViewModel tableView:tableViewModel.tableView accessoryButtonTappedForRowWithIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatBool(dispatched, is(equalToBool(YES)));
}

- (void)itShouldInvokeABlockCallbackWhenTheDeleteConfirmationButtonTitleIsDetermined {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    RKTableItem* tableItem = [RKTableItem tableItem];
    NSString* deleteTitle = @"Delete Me";
    [tableViewModel loadTableItems:[NSArray arrayWithObject:tableItem] withMappingBlock:^(RKTableViewCellMapping* cellMapping) {
        cellMapping.titleForDeleteButtonForObjectAtIndexPath = ^ NSString*(UITableViewCell* cell, id object, NSIndexPath* indexPath) {
            return deleteTitle;
        };
    }];
    NSString* delegateTitle = [tableViewModel tableView:tableViewModel.tableView
      titleForDeleteConfirmationButtonForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThat(delegateTitle, is(equalTo(deleteTitle)));
}

- (void)itShouldInvokeABlockCallbackWhenCellEditingStyleIsDetermined {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    tableViewModel.canEditRows = YES;
    RKTableItem* tableItem = [RKTableItem tableItem];
    [tableViewModel loadTableItems:[NSArray arrayWithObject:tableItem] withMappingBlock:^(RKTableViewCellMapping* cellMapping) {
        cellMapping.editingStyleForObjectAtIndexPath = ^ UITableViewCellEditingStyle(UITableViewCell* cell, id object, NSIndexPath* indexPath) {
            return UITableViewCellEditingStyleInsert;
        };
    }];
    UITableViewCellEditingStyle delegateStyle = [tableViewModel tableView:tableViewModel.tableView
                                            editingStyleForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatInt(delegateStyle, is(equalToInt(UITableViewCellEditingStyleInsert)));
}

- (void)itShouldInvokeABlockCallbackWhenACellIsMoved {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    tableViewModel.canMoveRows = YES;
    RKTableItem* tableItem = [RKTableItem tableItem];
    NSIndexPath* moveToIndexPath = [NSIndexPath indexPathForRow:2 inSection:0];
    [tableViewModel loadTableItems:[NSArray arrayWithObject:tableItem] withMappingBlock:^(RKTableViewCellMapping* cellMapping) {
        cellMapping.targetIndexPathForMove = ^ NSIndexPath*(UITableViewCell* cell, id object, NSIndexPath* sourceIndexPath, NSIndexPath* destinationIndexPath) {
            return moveToIndexPath;
        };
    }];
    NSIndexPath* delegateIndexPath = [tableViewModel tableView:tableViewModel.tableView
                      targetIndexPathForMoveFromRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]toProposedIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    assertThat(delegateIndexPath, is(equalTo(moveToIndexPath)));
}

#pragma mark Variable Height Rows

- (void)itShouldReturnTheRowHeightConfiguredOnTheTableViewWhenVariableHeightRowsIsDisabled {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    tableViewModel.variableHeightRows = NO;
    tableViewModel.tableView.rowHeight = 55;
    RKTableItem* tableItem = [RKTableItem tableItem];
    [tableViewModel loadTableItems:[NSArray arrayWithObject:tableItem] withMappingBlock:^(RKTableViewCellMapping* cellMapping) {
        cellMapping.rowHeight = 200;
    }];
    CGFloat height = [tableViewModel tableView:tableViewModel.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatFloat(height, is(equalToFloat(55)));
}

- (void)itShouldReturnTheHeightFromTheTableCellMappingWhenVariableHeightRowsAreEnabled {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    tableViewModel.variableHeightRows = YES;
    tableViewModel.tableView.rowHeight = 55;
    RKTableItem* tableItem = [RKTableItem tableItem];
    [tableViewModel loadTableItems:[NSArray arrayWithObject:tableItem] withMappingBlock:^(RKTableViewCellMapping* cellMapping) {
        cellMapping.rowHeight = 200;
    }];
    CGFloat height = [tableViewModel tableView:tableViewModel.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatFloat(height, is(equalToFloat(200)));
}

- (void)itShouldInvokeAnBlockCallbackToDetermineTheCellHeightWhenVariableHeightRowsAreEnabled {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    tableViewModel.variableHeightRows = YES;
    tableViewModel.tableView.rowHeight = 55;
    RKTableItem* tableItem = [RKTableItem tableItem];
    [tableViewModel loadTableItems:[NSArray arrayWithObject:tableItem] withMappingBlock:^(RKTableViewCellMapping* cellMapping) {
        cellMapping.rowHeight = 200;
        cellMapping.heightOfCellForObjectAtIndexPath = ^ CGFloat(UITableViewCell* cell, id object, NSIndexPath* indexPath) { return 150; };
    }];
    CGFloat height = [tableViewModel tableView:tableViewModel.tableView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatFloat(height, is(equalToFloat(150)));
}

#pragma mark - Editing

- (void)itShouldAllowEditingWhenTheCanEditRowsPropertyIsSet {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    tableViewModel.canEditRows = YES;
    RKTableItem* tableItem = [RKTableItem tableItem];
    [tableViewModel loadTableItems:[NSArray arrayWithObject:tableItem]];
    BOOL delegateCanEdit = [tableViewModel tableView:tableViewModel.tableView
                               canEditRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatBool(delegateCanEdit, is(equalToBool(YES)));
}

- (void)itShouldCommitADeletionWhenTheCanEditRowsPropertyIsSet {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    tableViewModel.canEditRows = YES;
    [tableViewModel loadObjects:[NSArray arrayWithObjects:@"First Object", @"Second Object", nil]];
    assertThatInt([tableViewModel rowCount], is(equalToInt(2)));
    BOOL delegateCanEdit = [tableViewModel tableView:tableViewModel.tableView
                               canEditRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatBool(delegateCanEdit, is(equalToBool(YES)));
    [tableViewModel tableView:tableViewModel.tableView
           commitEditingStyle:UITableViewCellEditingStyleDelete
            forRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    assertThatInt([tableViewModel rowCount], is(equalToInt(1)));
    assertThat([tableViewModel objectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]],
               is(equalTo(@"First Object")));
}

- (void)itShouldNotCommitADeletionWhenTheCanEditRowsPropertyIsNotSet {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    [tableViewModel loadObjects:[NSArray arrayWithObjects:@"First Object", @"Second Object", nil]];
    assertThatInt([tableViewModel rowCount], is(equalToInt(2)));
    BOOL delegateCanEdit = [tableViewModel tableView:tableViewModel.tableView
                               canEditRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatBool(delegateCanEdit, is(equalToBool(NO)));
    [tableViewModel tableView:tableViewModel.tableView
           commitEditingStyle:UITableViewCellEditingStyleDelete
            forRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    assertThatInt([tableViewModel rowCount], is(equalToInt(2)));
    assertThat([tableViewModel objectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]],
               is(equalTo(@"First Object")));
    assertThat([tableViewModel objectForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]],
               is(equalTo(@"Second Object")));
}

- (void)itShouldDoNothingToCommitAnInsertionWhenTheCanEditRowsPropertyIsSet {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    tableViewModel.canEditRows = YES;
    [tableViewModel loadObjects:[NSArray arrayWithObjects:@"First Object", @"Second Object", nil]];
    assertThatInt([tableViewModel rowCount], is(equalToInt(2)));
    BOOL delegateCanEdit = [tableViewModel tableView:tableViewModel.tableView
                               canEditRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatBool(delegateCanEdit, is(equalToBool(YES)));
    [tableViewModel tableView:tableViewModel.tableView
           commitEditingStyle:UITableViewCellEditingStyleInsert
            forRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
    assertThatInt([tableViewModel rowCount], is(equalToInt(2)));
    assertThat([tableViewModel objectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]],
               is(equalTo(@"First Object")));
    assertThat([tableViewModel objectForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]],
               is(equalTo(@"Second Object")));
}

- (void)itShouldAllowMovingWhenTheCanMoveRowsPropertyIsSet {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    tableViewModel.canMoveRows = YES;
    RKTableItem* tableItem = [RKTableItem tableItem];
    [tableViewModel loadTableItems:[NSArray arrayWithObject:tableItem]];
    BOOL delegateCanMove = [tableViewModel tableView:tableViewModel.tableView
                               canMoveRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatBool(delegateCanMove, is(equalToBool(YES)));
}

- (void)itShouldMoveARowWithinASectionWhenTheCanMoveRowsPropertyIsSet {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    tableViewModel.canMoveRows = YES;
    [tableViewModel loadObjects:[NSArray arrayWithObjects:@"First Object", @"Second Object", nil]];
    assertThatInt([tableViewModel rowCount], is(equalToInt(2)));
    BOOL delegateCanMove = [tableViewModel tableView:tableViewModel.tableView
                               canMoveRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatBool(delegateCanMove, is(equalToBool(YES)));
    [tableViewModel tableView:tableViewModel.tableView
           moveRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                  toIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    assertThatInt([tableViewModel rowCount], is(equalToInt(2)));
    assertThat([tableViewModel objectForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]],
               is(equalTo(@"First Object")));
    assertThat([tableViewModel objectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]],
               is(equalTo(@"Second Object")));
}

- (void)itShouldMoveARowAcrossSectionsWhenTheCanMoveRowsPropertyIsSet {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    tableViewModel.canMoveRows = YES;
    [tableViewModel loadObjects:[NSArray arrayWithObjects:@"First Object", @"Second Object", nil]];
    assertThatInt([tableViewModel rowCount], is(equalToInt(2)));
    assertThatInt([tableViewModel sectionCount], is(equalToInt(1)));
    BOOL delegateCanMove = [tableViewModel tableView:tableViewModel.tableView
                               canMoveRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatBool(delegateCanMove, is(equalToBool(YES)));
    [tableViewModel tableView:tableViewModel.tableView
           moveRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                  toIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
    assertThatInt([tableViewModel rowCount], is(equalToInt(2)));
    assertThatInt([tableViewModel sectionCount], is(equalToInt(2)));
    assertThat([tableViewModel objectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]],
               is(equalTo(@"First Object")));
    assertThat([tableViewModel objectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]],
               is(equalTo(@"Second Object")));
}

- (void)itShouldNotMoveARowWhenTheCanMoveRowsPropertyIsNotSet {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    [tableViewModel loadObjects:[NSArray arrayWithObjects:@"First Object", @"Second Object", nil]];
    assertThatInt([tableViewModel rowCount], is(equalToInt(2)));
    BOOL delegateCanMove = [tableViewModel tableView:tableViewModel.tableView
                               canMoveRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatBool(delegateCanMove, is(equalToBool(NO)));
    [tableViewModel tableView:tableViewModel.tableView
           moveRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
                  toIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    assertThatInt([tableViewModel rowCount], is(equalToInt(2)));
    assertThat([tableViewModel objectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]],
               is(equalTo(@"First Object")));
    assertThat([tableViewModel objectForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]],
               is(equalTo(@"Second Object")));
}

#pragma mark - Reachability Integration

- (void)itShouldTransitionToTheOnlineStateWhenAReachabilityNoticeIsReceived {
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    id mockManager = [OCMockObject partialMockForObject:objectManager];
    BOOL online = YES;
    [[[mockManager stub] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    tableViewModel.objectManager = objectManager;
    [[NSNotificationCenter defaultCenter] postNotificationName:RKObjectManagerDidBecomeOnlineNotification object:objectManager];
    assertThatBool(tableViewModel.isOnline, is(equalToBool(YES)));
}

- (void)itShouldTransitionToTheOfflineStateWhenAReachabilityNoticeIsReceived {
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    id mockManager = [OCMockObject partialMockForObject:objectManager];
    BOOL online = NO;
    [[[mockManager stub] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    tableViewModel.objectManager = objectManager;
    [[NSNotificationCenter defaultCenter] postNotificationName:RKObjectManagerDidBecomeOfflineNotification object:objectManager];
    assertThatBool(tableViewModel.isOnline, is(equalToBool(NO)));
}

- (void)itShouldNotifyTheDelegateOnTransitionToOffline {
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    id mockManager = [OCMockObject partialMockForObject:objectManager];
    [mockManager setExpectationOrderMatters:YES];
    RKObjectManagerNetworkStatus networkStatus = RKObjectManagerNetworkStatusOnline;
    [[[mockManager stub] andReturnValue:OCMOCK_VALUE(networkStatus)] networkStatus];
    BOOL online = YES; // Initial online state for table
    [[[mockManager expect] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    online = NO; // After the notification is posted
    [[[mockManager expect] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    id mockDelegate = [OCMockObject mockForProtocol:@protocol(RKTableControllerDelegate)];
    [[mockDelegate expect] tableViewModelDidBecomeOffline:tableViewModel];
    tableViewModel.delegate = mockDelegate;
    [[NSNotificationCenter defaultCenter] postNotificationName:RKObjectManagerDidBecomeOfflineNotification object:objectManager];
    [mockDelegate verify];
}

- (void)itShouldPostANotificationOnTransitionToOffline {
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    id mockManager = [OCMockObject partialMockForObject:objectManager];
    [mockManager setExpectationOrderMatters:YES];
    RKObjectManagerNetworkStatus networkStatus = RKObjectManagerNetworkStatusOnline;
    [[[mockManager stub] andReturnValue:OCMOCK_VALUE(networkStatus)] networkStatus];
    BOOL online = YES; // Initial online state for table
    [[[mockManager expect] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    online = NO; // After the notification is posted
    [[[mockManager expect] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];

    id observerMock = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:observerMock name:RKTableControllerDidBecomeOffline object:tableViewModel];
    [[observerMock expect] notificationWithName:RKTableControllerDidBecomeOffline object:tableViewModel];

    [[NSNotificationCenter defaultCenter] postNotificationName:RKObjectManagerDidBecomeOfflineNotification object:objectManager];
    [observerMock verify];
}

- (void)itShouldNotifyTheDelegateOnTransitionToOnline {
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    id mockManager = [OCMockObject partialMockForObject:objectManager];
    BOOL online = YES;
    [[[mockManager stub] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    tableViewModel.objectManager = objectManager;
    id mockDelegate = [OCMockObject mockForProtocol:@protocol(RKTableControllerDelegate)];
    [[mockDelegate expect] tableViewModelDidBecomeOnline:tableViewModel];
    tableViewModel.delegate = mockDelegate;
    [[NSNotificationCenter defaultCenter] postNotificationName:RKObjectManagerDidBecomeOnlineNotification object:objectManager];
    [mockDelegate verify];
}

- (void)itShouldPostANotificationOnTransitionToOnline {
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    id mockManager = [OCMockObject partialMockForObject:objectManager];
    BOOL online = YES;
    [[[mockManager stub] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    tableViewModel.objectManager = objectManager;

    id observerMock = [OCMockObject observerMock];
    [[NSNotificationCenter defaultCenter] addMockObserver:observerMock name:RKTableControllerDidBecomeOnline object:tableViewModel];
    [[observerMock expect] notificationWithName:RKTableControllerDidBecomeOnline object:tableViewModel];

    [[NSNotificationCenter defaultCenter] postNotificationName:RKObjectManagerDidBecomeOnlineNotification object:objectManager];
    [observerMock verify];
}

- (void)itShouldShowTheOfflineImageOnTransitionToOffline {
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    id mockManager = [OCMockObject partialMockForObject:objectManager];
    [mockManager setExpectationOrderMatters:YES];
    RKObjectManagerNetworkStatus networkStatus = RKObjectManagerNetworkStatusOnline;
    [[[mockManager stub] andReturnValue:OCMOCK_VALUE(networkStatus)] networkStatus];
    BOOL online = YES; // Initial online state for table
    [[[mockManager expect] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    online = NO; // After the notification is posted
    [[[mockManager expect] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    UIImage* image = [UIImage imageNamed:@"blake.png"];
    tableViewModel.imageForOffline = image;

    [[NSNotificationCenter defaultCenter] postNotificationName:RKObjectManagerDidBecomeOfflineNotification object:objectManager];
    assertThatBool(tableViewModel.isOnline, is(equalToBool(NO)));
    UIImageView* imageView = tableViewModel.stateOverlayImageView;
    assertThat(imageView, isNot(nilValue()));
    assertThat(imageView.image, is(equalTo(image)));
}

- (void)itShouldRemoveTheOfflineImageOnTransitionToOnlineFromOffline {
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    id mockManager = [OCMockObject partialMockForObject:objectManager];
    [mockManager setExpectationOrderMatters:YES];
    RKObjectManagerNetworkStatus networkStatus = RKObjectManagerNetworkStatusOnline;
    [[[mockManager stub] andReturnValue:OCMOCK_VALUE(networkStatus)] networkStatus];
    BOOL online = YES; // Initial online state for table
    [[[mockManager expect] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    online = NO; // After the notification is posted
    [[[mockManager expect] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    UIImage* image = [UIImage imageNamed:@"blake.png"];
    tableViewModel.imageForOffline = image;

    [[NSNotificationCenter defaultCenter] postNotificationName:RKObjectManagerDidBecomeOfflineNotification object:objectManager];
    assertThatBool(tableViewModel.isOnline, is(equalToBool(NO)));
    UIImageView* imageView = tableViewModel.stateOverlayImageView;
    assertThat(imageView, isNot(nilValue()));
    assertThat(imageView.image, is(equalTo(image)));

    online = YES;
    [[[mockManager expect] andReturnValue:OCMOCK_VALUE(online)] isOnline];
    [[NSNotificationCenter defaultCenter] postNotificationName:RKObjectManagerDidBecomeOnlineNotification object:objectManager];
    assertThatBool(tableViewModel.isOnline, is(equalToBool(YES)));
    imageView = tableViewModel.stateOverlayImageView;
    assertThat(imageView.image, is(nilValue()));
}

#pragma mark - Swipe Menus

- (void)itShouldAllowSwipeMenusWhenTheSwipeViewsEnabledPropertyIsSet {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    tableViewModel.cellSwipeViewsEnabled = YES;
    RKTableItem* tableItem = [RKTableItem tableItem];
    [tableViewModel loadTableItems:[NSArray arrayWithObject:tableItem]];
    assertThatBool(tableViewModel.canEditRows, is(equalToBool(NO)));
    assertThatBool(tableViewModel.cellSwipeViewsEnabled, is(equalToBool(YES)));
}

- (void)itShouldNotAllowEditingWhenTheSwipeViewsEnabledPropertyIsSet {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    tableViewModel.cellSwipeViewsEnabled = YES;
    RKTableItem* tableItem = [RKTableItem tableItem];
    [tableViewModel loadTableItems:[NSArray arrayWithObject:tableItem]];
    BOOL delegateCanEdit = [tableViewModel tableView:tableViewModel.tableView
                               canEditRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    assertThatBool(delegateCanEdit, is(equalToBool(NO)));
}

- (void)itShouldRaiseAnExceptionWhenEnablingSwipeViewsWhenTheCanEditRowsPropertyIsSet {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    tableViewModel.canEditRows = YES;

    NSException* exception = nil;
    @try {
        tableViewModel.cellSwipeViewsEnabled = YES;
    }
    @catch (NSException *e) {
        exception = e;
    }
    @finally {
        assertThat(exception, isNot(nilValue()));
    }
}

- (void)itShouldCallTheDelegateBeforeShowingTheSwipeView {
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    tableViewModel.cellSwipeViewsEnabled = YES;
    RKTableItem* tableItem = [RKTableItem tableItem];
    RKSpecTableViewModelDelegate* delegate = [RKSpecTableViewModelDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModel:tableViewModel
                                                  willAddSwipeView:OCMOCK_ANY
                                                            toCell:OCMOCK_ANY
                                                         forObject:OCMOCK_ANY];
    tableViewModel.delegate = mockDelegate;
    [tableViewModel loadTableItems:[NSArray arrayWithObject:tableItem]];
    [tableViewModel addSwipeViewTo:[RKSpecUserTableViewCell new]
                        withObject:@"object"
                         direction:UISwipeGestureRecognizerDirectionRight];
    [mockDelegate verify];
}

- (void)itShouldCallTheDelegateBeforeHidingTheSwipeView {
    RKLogConfigureByName("RestKit/UI", RKLogLevelTrace);
    RKTableControllerSpecTableViewController* viewController = [RKTableControllerSpecTableViewController new];
    RKTableController* tableViewModel = [RKTableController tableViewModelForTableViewController:viewController];
    tableViewModel.cellSwipeViewsEnabled = YES;
    RKTableItem* tableItem = [RKTableItem tableItem];
    RKSpecTableViewModelDelegate* delegate = [RKSpecTableViewModelDelegate new];
    id mockDelegate = [OCMockObject partialMockForObject:delegate];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModel:tableViewModel
                                                  willAddSwipeView:OCMOCK_ANY
                                                            toCell:OCMOCK_ANY
                                                         forObject:OCMOCK_ANY];
    [[[mockDelegate expect] andForwardToRealObject] tableViewModel:tableViewModel
                                               willRemoveSwipeView:OCMOCK_ANY
                                                          fromCell:OCMOCK_ANY
                                                         forObject:OCMOCK_ANY];
    tableViewModel.delegate = mockDelegate;
    [tableViewModel loadTableItems:[NSArray arrayWithObject:tableItem]];
    [tableViewModel addSwipeViewTo:[RKSpecUserTableViewCell new]
                        withObject:@"object"
                         direction:UISwipeGestureRecognizerDirectionRight];
    [tableViewModel animationDidStopAddingSwipeView:nil
                                           finished:nil
                                            context:nil];
    [tableViewModel removeSwipeView:YES];
    [mockDelegate verify];
}

@end
