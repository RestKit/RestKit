//
//  RKTableControllerTestDelegate.m
//  RestKit
//
//  Created by Blake Watters on 5/23/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTableControllerTestDelegate.h"
#import "RKLog.h"

#if TARGET_OS_IPHONE

@implementation RKAbstractTableControllerTestDelegate

@synthesize timeout = _timeout;
@synthesize awaitingResponse = _awaitingResponse;
@synthesize cancelled = _cancelled;

+ (id)tableControllerDelegate
{
    return [[self new] autorelease];
}

- (id)init
{
    self = [super init];
    if (self) {
        _timeout = 1.0;
        _awaitingResponse = NO;
        _cancelled = NO;
    }

    return self;
}

- (void)waitForLoad
{
    _awaitingResponse = YES;
    NSDate *startDate = [NSDate date];

    while (_awaitingResponse) {
        RKLogTrace(@"Awaiting response = %d", _awaitingResponse);
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
        if ([[NSDate date] timeIntervalSinceDate:startDate] > self.timeout) {
            NSLog(@"%@: Timed out!!!", self);
            _awaitingResponse = NO;
            [NSException raise:nil format:@"*** Operation timed out after %f seconds...", self.timeout];
        }
    }
}

#pragma RKTableControllerDelegate methods

- (void)tableControllerDidFinishLoad:(RKAbstractTableController *)tableController
{
    _awaitingResponse = NO;
}

- (void)tableController:(RKAbstractTableController *)tableController didFailLoadWithError:(NSError *)error
{
    _awaitingResponse = NO;
}

- (void)tableControllerDidCancelLoad:(RKAbstractTableController *)tableController
{
    _awaitingResponse = NO;
    _cancelled = YES;
}

- (void)tableControllerDidFinalizeLoad:(RKAbstractTableController *)tableController
{
    _awaitingResponse = NO;
}

// NOTE - Delegate methods below are implemented to allow trampoline through
// OCMock expectations

- (void)tableControllerDidStartLoad:(RKAbstractTableController *)tableController
{}

- (void)tableControllerDidBecomeEmpty:(RKAbstractTableController *)tableController
{}

- (void)tableController:(RKAbstractTableController *)tableController willLoadTableWithObjectLoader:(RKObjectLoader *)objectLoader
{}

- (void)tableController:(RKAbstractTableController *)tableController didLoadTableWithObjectLoader:(RKObjectLoader *)objectLoader
{}

- (void)tableController:(RKAbstractTableController *)tableController willBeginEditing:(id)object atIndexPath:(NSIndexPath *)indexPath
{}

- (void)tableController:(RKAbstractTableController *)tableController didEndEditing:(id)object atIndexPath:(NSIndexPath *)indexPath
{}

- (void)tableController:(RKAbstractTableController *)tableController didInsertSection:(RKTableSection *)section atIndex:(NSUInteger)sectionIndex
{}

- (void)tableController:(RKAbstractTableController *)tableController didRemoveSection:(RKTableSection *)section atIndex:(NSUInteger)sectionIndex
{}

- (void)tableController:(RKAbstractTableController *)tableController didInsertObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{}

- (void)tableController:(RKAbstractTableController *)tableController didUpdateObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{}

- (void)tableController:(RKAbstractTableController *)tableController didDeleteObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{}

- (void)tableController:(RKAbstractTableController *)tableController willAddSwipeView:(UIView *)swipeView toCell:(UITableViewCell *)cell forObject:(id)object
{}

- (void)tableController:(RKAbstractTableController *)tableController willRemoveSwipeView:(UIView *)swipeView fromCell:(UITableViewCell *)cell forObject:(id)object
{}

- (void)tableController:(RKTableController *)tableController didLoadObjects:(NSArray *)objects inSection:(NSUInteger)sectionIndex
{}

- (void)tableController:(RKAbstractTableController *)tableController willDisplayCell:(UITableViewCell *)cell forObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{}

- (void)tableController:(RKAbstractTableController *)tableController didSelectCell:(UITableViewCell *)cell forObject:(id)object atIndexPath:(NSIndexPath *)indexPath
{}

@end

@implementation RKTableControllerTestDelegate

- (void)tableController:(RKTableController *)tableController didLoadObjects:(NSArray *)objects inSection:(RKTableSection *)section
{}

@end

@implementation RKFetchedResultsTableControllerTestDelegate

- (void)tableController:(RKFetchedResultsTableController *)tableController didInsertSectionAtIndex:(NSUInteger)sectionIndex
{}

- (void)tableController:(RKFetchedResultsTableController *)tableController didDeleteSectionAtIndex:(NSUInteger)sectionIndex
{}

@end

#endif
