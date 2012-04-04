//
//  RKTableController.m
//  RestKit
//
//  Created by Blake Watters on 8/1/11.
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

#import "RKTableController.h"
#import "RKAbstractTableController_Internals.h"
#import "RKLog.h"
#import "RKFormSection.h"

// Define logging component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitUI

@implementation RKTableController

@synthesize form = _form;

#pragma mark - Instantiation

- (id)init {
    self = [super init];
    if (self) {
        [self addObserver:self
               forKeyPath:@"sections"
                  options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                  context:nil];

        RKTableSection* section = [RKTableSection section];
        [self addSection:section];
    }

    return self;
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"sections"];
    [_form release];

    [super dealloc];
}

#pragma mark - Managing Sections

// KVO-compliant proxy object for section mutations
- (NSMutableArray *)sectionsProxy {
    return [self mutableArrayValueForKey:@"sections"];
}

- (void)addSectionsObject:(id)section {
    [self.sections addObject:section];
}

- (void)insertSections:(NSArray *)objects atIndexes:(NSIndexSet *)indexes {
    [self.sections insertObjects:objects atIndexes:indexes];
}

- (void)removeSectionsAtIndexes:(NSIndexSet *)indexes {
    [self.sections removeObjectsAtIndexes:indexes];
}

- (void)replaceObjectsAtIndexes:(NSIndexSet *)indexes withObjects:(NSArray *)objects {
    [self.sections replaceObjectsAtIndexes:indexes withObjects:objects];
}

- (void)addSection:(RKTableSection *)section {
    NSAssert(section, @"Cannot insert a nil section");
    section.tableController = self;
    if (! section.cellMappings) {
        section.cellMappings = self.cellMappings;
    }

    [[self sectionsProxy] addObject:section];

    // TODO: move into KVO?
    if ([self.delegate respondsToSelector:@selector(tableController:didInsertSection:atIndex:)]) {
        [self.delegate tableController:self didInsertSection:section atIndex:[self.sections indexOfObject:section]];
    }
}

- (void)addSectionUsingBlock:(void (^)(RKTableSection *section))block {
    [self addSection:[RKTableSection sectionUsingBlock:block]];
}

- (void)removeSection:(RKTableSection *)section {
    NSAssert(section, @"Cannot remove a nil section");
    if ([self.sections containsObject:section] && self.sectionCount == 1) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"Tables must always have at least one section"
                                     userInfo:nil];
    }
    NSUInteger index = [self.sections indexOfObject:section];
    if ([self.delegate respondsToSelector:@selector(tableController:didRemoveSection:atIndex:)]) {
        [self.delegate tableController:self didRemoveSection:section atIndex:index];
    }
    [[self sectionsProxy] removeObject:section];
}

- (void)insertSection:(RKTableSection *)section atIndex:(NSUInteger)index {
    NSAssert(section, @"Cannot insert a nil section");
    section.tableController = self;
    [[self sectionsProxy] insertObject:section atIndex:index];

    if ([self.delegate respondsToSelector:@selector(tableController:didInsertSection:atIndex:)]) {
        [self.delegate tableController:self didInsertSection:section atIndex:index];
    }
}

- (void)removeSectionAtIndex:(NSUInteger)index {
    if (index < self.sectionCount && self.sectionCount == 1) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:@"Tables must always have at least one section"
                                     userInfo:nil];
    }
    RKTableSection* section = [self.sections objectAtIndex:index];
    if ([self.delegate respondsToSelector:@selector(tableController:didRemoveSection:atIndex:)]) {
        [self.delegate tableController:self didRemoveSection:section atIndex:index];
    }
    [[self sectionsProxy] removeObjectAtIndex:index];
}

- (void)removeAllSections:(BOOL)recreateFirstSection {
    NSUInteger sectionCount = [self.sections count];
    for (NSUInteger index = 0; index < sectionCount; index++) {
        RKTableSection* section = [self.sections objectAtIndex:index];
        if ([self.delegate respondsToSelector:@selector(tableController:didRemoveSection:atIndex:)]) {
            [self.delegate tableController:self didRemoveSection:section atIndex:index];
        }
    }
    [[self sectionsProxy] removeAllObjects];

    if (recreateFirstSection) {
        [self addSection:[RKTableSection section]];
    }
}

- (void)removeAllSections {
    [self removeAllSections:YES];
}

- (void)updateTableViewUsingBlock:(void (^)())block {
    [self.tableView beginUpdates];
    block();
    [self.tableView endUpdates];
}

#pragma mark - Static Tables

- (NSArray*)objectsWithHeaderAndFooters:(NSArray *)objects forSection:(NSUInteger)sectionIndex {
    NSMutableArray* mutableObjects = [objects mutableCopy];
    if (sectionIndex == 0) {
        if ([self.headerItems count] > 0) {
            [mutableObjects insertObjects:self.headerItems atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.headerItems.count)]];
        }
        if (self.emptyItem) {
            [mutableObjects insertObject:self.emptyItem atIndex:0];
        }
    }

    if (sectionIndex == (self.sectionCount - 1) && [self.footerItems count] > 0) {
        [mutableObjects addObjectsFromArray:self.footerItems];
    }

    return [mutableObjects autorelease];
}

// TODO: NOTE - Everything currently needs to pass through this method to pick up header/footer rows...
- (void)loadObjects:(NSArray *)objects inSection:(NSUInteger)sectionIndex {
    // Clear any existing error state from the table
    self.error = nil;

    RKTableSection* section = [self sectionAtIndex:sectionIndex];
    section.objects = [self objectsWithHeaderAndFooters:objects forSection:sectionIndex];
    for (NSUInteger index = 0; index < [section.objects count]; index++) {
        if ([self.delegate respondsToSelector:@selector(tableController:didInsertObject:atIndexPath:)]) {
            [self.delegate tableController:self
                          didInsertObject:[section objectAtIndex:index]
                              atIndexPath:[NSIndexPath indexPathForRow:index inSection:sectionIndex]];
        }
    }

    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:self.defaultRowAnimation];

    // TODO: We should probably not be making this call in cases where we were
    // loaded via a network API, as we are duplicating cleanup effort that
    // already exists across our RKRequestDelegate & RKObjectLoaderDelegate methods
    [self didFinishLoad];
}

- (void)loadObjects:(NSArray *)objects {
    [self loadObjects:objects inSection:0];
}

- (void)loadEmpty {
    [self removeAllSections:YES];
    [self loadObjects:[NSArray array]];
}

- (void)loadTableItems:(NSArray *)tableItems inSection:(NSUInteger)sectionIndex {
    for (RKTableItem *tableItem in tableItems) {
        if ([tableItem.cellMapping.attributeMappings count] == 0) {
            [tableItem.cellMapping addDefaultMappings];
        }
    }

    [self loadObjects:tableItems inSection:sectionIndex];
}

- (void)loadTableItems:(NSArray *)tableItems
             inSection:(NSUInteger)sectionIndex
             withMapping:(RKTableViewCellMapping *)cellMapping {
    NSAssert(tableItems, @"Cannot load a nil collection of table items");
    NSAssert(sectionIndex < self.sectionCount, @"Cannot load table items into a section that does not exist");
    NSAssert(cellMapping, @"Cannot load table items without a cell mapping");
    for (RKTableItem* tableItem in tableItems) {
        tableItem.cellMapping = cellMapping;
    }
    [self loadTableItems:tableItems inSection:sectionIndex];
}

- (void)loadTableItems:(NSArray *)tableItems withMapping:(RKTableViewCellMapping *)cellMapping {
    [self loadTableItems:tableItems inSection:0 withMapping:cellMapping];
}

- (void)loadTableItems:(NSArray *)tableItems {
    [self loadTableItems:tableItems inSection:0];
}

- (void)loadTableItems:(NSArray *)tableItems withMappingBlock:(void (^)(RKTableViewCellMapping*))block {
    [self loadTableItems:tableItems inSection:0 withMapping:[RKTableViewCellMapping cellMappingUsingBlock:block]];
}

#pragma mark - Network Table Loading

- (void)loadTableFromResourcePath:(NSString*)resourcePath {
    NSAssert(self.objectManager, @"Cannot perform a network load without an object manager");
    [self loadTableWithObjectLoader:[self.objectManager loaderWithResourcePath:resourcePath]];
}

- (void)loadTableFromResourcePath:(NSString *)resourcePath usingBlock:(void (^)(RKObjectLoader *loader))block {
    RKObjectLoader* theObjectLoader = [self.objectManager loaderWithResourcePath:resourcePath];
    block(theObjectLoader);
    [self loadTableWithObjectLoader:theObjectLoader];
}

#pragma mark - Forms

- (void)loadForm:(RKForm *)form {
    [form retain];
    [_form release];
    _form = form;

    // The form replaces the content in the table
    [self removeAllSections:NO];

    [form willLoadInTableController:self];
    for (RKFormSection *section in form.sections) {
        NSUInteger sectionIndex = [form.sections indexOfObject:section];
        section.objects = [self objectsWithHeaderAndFooters:section.objects forSection:sectionIndex];
        [self addSection:(RKTableSection *)section];
    }

    // TODO: How to handle animating loading a replacement form?
//    if (self.loaded) {
//        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [form.sections count] - 1)];
//        [self.tableView reloadSections:indexSet withRowAnimation:self.defaultRowAnimation];
//    }

    [self didFinishLoad];
    [form didLoadInTableController:self];
}

#pragma mark - UITableViewDataSource methods

- (void)tableView:(UITableView*)theTableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSAssert(theTableView == self.tableView, @"tableView:commitEditingStyle:forRowAtIndexPath: invoked with inappropriate tableView: %@", theTableView);
    if (self.canEditRows) {
        if (editingStyle == UITableViewCellEditingStyleDelete) {
            RKTableSection* section = [self.sections objectAtIndex:indexPath.section];
            [section removeObjectAtIndex:indexPath.row];

        } else if (editingStyle == UITableViewCellEditingStyleInsert) {
            // TODO: Anything we need to do here, since we do not have the object to insert?
        }
    }
}

- (void)tableView:(UITableView*)theTableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destIndexPath {
    NSAssert(theTableView == self.tableView, @"tableView:moveRowAtIndexPath:toIndexPath: invoked with inappropriate tableView: %@", theTableView);
    if (self.canMoveRows) {
        if (sourceIndexPath.section == destIndexPath.section) {
            RKTableSection* section = [self.sections objectAtIndex:sourceIndexPath.section];
            [section moveObjectAtIndex:sourceIndexPath.row toIndex:destIndexPath.row];

        } else {
            [self.tableView beginUpdates];
            RKTableSection* sourceSection = [self.sections objectAtIndex:sourceIndexPath.section];
            id object = [[sourceSection objectAtIndex:sourceIndexPath.row] retain];
            [sourceSection removeObjectAtIndex:sourceIndexPath.row];

            RKTableSection* destinationSection = nil;
            if (destIndexPath.section < [self sectionCount]) {
                destinationSection = [self.sections objectAtIndex:destIndexPath.section];
            } else {
                destinationSection = [RKTableSection section];
                [self insertSection:destinationSection atIndex:destIndexPath.section];
            }
            [destinationSection insertObject:object atIndex:destIndexPath.row];
            [object release];
            [self.tableView endUpdates];
        }
    }
}

#pragma mark - RKRequestDelegate & RKObjectLoaderDelegate methods

- (void)objectLoader:(RKObjectLoader *)loader didLoadObjects:(NSArray *)objects {
    // TODO: Could not get the KVO to work without a boolean property...
    // TODO: Need to figure out how to group the objects into sections
    // TODO: Apply any sorting...

    // Load them into the first section for now
    [self loadObjects:objects inSection:0];
}

- (void)reloadRowForObject:(id)object withRowAnimation:(UITableViewRowAnimation)rowAnimation {
    // TODO: Find the indexPath of the object...
    NSIndexPath *indexPath = [self indexPathForObject:object];
    if (indexPath) {
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:rowAnimation];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    if ([keyPath isEqualToString:@"sections"]) {
        // No table view to inform...
        if (! self.tableView) {
            return;
        }

        NSIndexSet *changedSectionIndexes = [change objectForKey:NSKeyValueChangeIndexesKey];
        NSAssert(changedSectionIndexes, @"Received a KVO notification for settings property without an NSKeyValueChangeIndexesKey");
        if ([[change objectForKey:NSKeyValueChangeKindKey] intValue] == NSKeyValueChangeInsertion) {
            // Section(s) Inserted
            [self.tableView insertSections:changedSectionIndexes withRowAnimation:self.defaultRowAnimation];

            // TODO: Add observers on the sections objects...

        } else if ([[change objectForKey:NSKeyValueChangeKindKey] intValue] == NSKeyValueChangeRemoval) {
            // Section(s) Deleted
            [self.tableView deleteSections:changedSectionIndexes withRowAnimation:self.defaultRowAnimation];

            // TODO: Remove observers on the sections objects...
        } else if ([[change objectForKey:NSKeyValueChangeKindKey] intValue] == NSKeyValueChangeReplacement) {
            // Section(s) Replaced
            [self.tableView reloadSections:changedSectionIndexes withRowAnimation:self.defaultRowAnimation];

            // TODO: Remove observers on the sections objects...
        }
    }

    // TODO: KVO should be used for managing the row level manipulations on the table view as well...
}

@end
