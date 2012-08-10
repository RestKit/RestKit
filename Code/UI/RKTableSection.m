//
//  RKTableViewSection.m
//  RestKit
//
//  Created by Blake Watters on 8/2/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "RKTableSection.h"
#import "RKTableController.h"
#import "RKTableViewCellMapping.h"
#import "RKLog.h"

// Define logging component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitUI

@implementation RKTableSection

@synthesize objects = _objects;
@synthesize cellMappings = _cellMappings;
@synthesize tableController = _tableController;
@synthesize headerTitle = _headerTitle;
@synthesize footerTitle = _footerTitle;
@synthesize headerHeight = _headerHeight;
@synthesize footerHeight = _footerHeight;
@synthesize headerView = _headerView;
@synthesize footerView = _footerView;

+ (id)section
{
    return [[self new] autorelease];
}

+ (id)sectionUsingBlock:(void (^)(RKTableSection *))block
{
    RKTableSection *section = [self section];
    block(section);
    return section;
}

+ (id)sectionForObjects:(NSArray *)objects withMappings:(RKTableViewCellMappings *)cellMappings
{
    return [self sectionUsingBlock:^(RKTableSection *section) {
        section.objects = objects;
        section.cellMappings = cellMappings;
    }];
}

- (id)init
{
    self = [super init];
    if (self) {
        _objects = [NSMutableArray new];
        _headerHeight = 0;
        _footerHeight = 0;
    }

    return self;
}

- (void)dealloc
{
    [_objects release];
    [_cellMappings release];
    [_headerTitle release];
    [_footerTitle release];
    [_headerView release];
    [_footerView release];
    [super dealloc];
}

- (void)setObjects:(NSArray *)objects
{
    if (! [objects isMemberOfClass:[NSMutableArray class]]) {
        NSMutableArray *mutableObjects = [objects mutableCopy];
        [_objects release];
        _objects = mutableObjects;
    } else {
        [objects retain];
        [_objects release];
        _objects = (NSMutableArray *)objects;
    }
}

- (NSUInteger)rowCount
{
    return [_objects count];
}

- (id)objectAtIndex:(NSUInteger)rowIndex
{
    return [_objects objectAtIndex:rowIndex];
}

- (UITableView *)tableView
{
    return _tableController.tableView;
}

- (void)insertObject:(id)object atIndex:(NSUInteger)index
{
    [(NSMutableArray *)_objects insertObject:object atIndex:index];

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index
                                                inSection:[_tableController indexForSection:self]];
    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                          withRowAnimation:_tableController.defaultRowAnimation];

    if ([_tableController.delegate respondsToSelector:@selector(tableController:didInsertObject:atIndexPath:)]) {
        [_tableController.delegate tableController:_tableController didInsertObject:object atIndexPath:indexPath];
    }
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
    id object = [self objectAtIndex:index];
    [(NSMutableArray *)_objects removeObjectAtIndex:index];

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index
                                                inSection:[_tableController indexForSection:self]];
    [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                          withRowAnimation:_tableController.defaultRowAnimation];

    if ([_tableController.delegate respondsToSelector:@selector(tableController:didDeleteObject:atIndexPath:)]) {
        [_tableController.delegate tableController:_tableController didDeleteObject:object atIndexPath:indexPath];
    }
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)object
{
    [(NSMutableArray *)_objects replaceObjectAtIndex:index withObject:object];

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index
                                                inSection:[_tableController indexForSection:self]];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                          withRowAnimation:_tableController.defaultRowAnimation];

    if ([_tableController.delegate respondsToSelector:@selector(tableController:didUpdateObject:atIndexPath:)]) {
        [_tableController.delegate tableController:_tableController didUpdateObject:object atIndexPath:indexPath];
    }
}

- (void)moveObjectAtIndex:(NSUInteger)sourceIndex toIndex:(NSUInteger)destinationIndex
{
    [self.tableView beginUpdates];
    id object = [[self objectAtIndex:sourceIndex] retain];
    [self removeObjectAtIndex:sourceIndex];
    [self insertObject:object atIndex:destinationIndex];
    [object release];
    [self.tableView endUpdates];

    // TODO: Should use moveRowAtIndexPath: when on iOS 5
}

@end
