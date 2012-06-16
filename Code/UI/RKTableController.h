//
//  RKTableController.h
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

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import "RKAbstractTableController.h"
#import "RKTableSection.h"
#import "RKTableViewCellMappings.h"
#import "RKTableItem.h"
#import "RKForm.h"
#import "RKObjectManager.h"
#import "RKObjectMapping.h"
#import "RKObjectLoader.h"

@protocol RKTableControllerDelegate <RKAbstractTableControllerDelegate>

@optional

- (void)tableController:(RKTableController *)tableController didLoadObjects:(NSArray *)objects inSection:(RKTableSection *)section;

@end

@interface RKTableController : RKAbstractTableController

@property (nonatomic, assign) id<RKTableControllerDelegate> delegate;

///-----------------------------------------------------------------------------
/// @name Static Tables
///-----------------------------------------------------------------------------

- (void)loadObjects:(NSArray *)objects;
- (void)loadObjects:(NSArray *)objects inSection:(NSUInteger)sectionIndex;
- (void)loadEmpty;

/**
 Load an array of RKTableItems into table cells of the specified class. A table cell
 mapping will be constructed on your behalf and yielded to the block for configuration.
 After the block is invoked, the objects will be loaded into the specified section.
 */
// TODO: Update comments...
- (void)loadTableItems:(NSArray *)tableItems withMapping:(RKTableViewCellMapping *)cellMapping;
- (void)loadTableItems:(NSArray *)tableItems
             inSection:(NSUInteger)sectionIndex
           withMapping:(RKTableViewCellMapping *)cellMapping;

/**
 Load an array of RKTableItem objects into the table using the default
 RKTableViewCellMapping. An instance of the cell mapping will be created on your
 behalf and configured with the default table view cell attribute mappings.

 @param tableItems An array of RKTableItem instances to load into the table

 @see RKTableItem
 @see [RKTableViewCellMapping addDefaultMappings]
 */
- (void)loadTableItems:(NSArray *)tableItems;

/**
 Load an array of RKTableItem objects into the specified section with the table using the default
 RKTableViewCellMapping. An instance of the cell mapping will be created on your
 behalf and configured with the default table view cell attribute mappings.

 @param tableItems An array of RKTableItem instances to load into the table
 @param sectionIndex The section to load the table items into. Must be less than sectionCount.

 @see RKTableItem
 @see [RKTableViewCellMapping addDefaultMappings]
 */
- (void)loadTableItems:(NSArray *)tableItems inSection:(NSUInteger)sectionIndex;

///-----------------------------------------------------------------------------
/** @name Network Tables */
///-----------------------------------------------------------------------------

- (void)loadTableFromResourcePath:(NSString *)resourcePath;
- (void)loadTableFromResourcePath:(NSString *)resourcePath usingBlock:(void (^)(RKObjectLoader *objectLoader))block;

///-----------------------------------------------------------------------------
/** @name Forms */
///-----------------------------------------------------------------------------

/**
 The form that the table has been loaded with (if any)
 */
@property (nonatomic, retain, readonly) RKForm *form;

/**
 Loads the table with the contents of the specified form object.
 Forms are used to build content entry and editing interfaces for objects.

 @see RKForm
 */
- (void)loadForm:(RKForm *)form;

///-----------------------------------------------------------------------------
/// @name Managing Sections
///-----------------------------------------------------------------------------

@property (nonatomic, readonly) NSMutableArray *sections;

/**
 The key path on the loaded objects used to determine the section they belong to.
 */
@property (nonatomic, copy) NSString *sectionNameKeyPath;

/**
 Returns the section at the specified index.
 @param index Must be less than the total number of sections.
 */
- (RKTableSection *)sectionAtIndex:(NSUInteger)index;

/**
 Returns the first section with the specified header title.
 @param title The header title.
 */
- (RKTableSection *)sectionWithHeaderTitle:(NSString *)title;

/**
 Returns the index of the specified section.

 @param section Must be a valid non nil RKTableViewSection.
 @return The index of the given section if contained within the receiver, otherwise NSNotFound.
 */
- (NSUInteger)indexForSection:(RKTableSection *)section;

// Coalesces a series of table view updates performed within the block into
// a single animation using beginUpdates: and endUpdates: on the table view
// TODO: Move to super-class?
- (void)updateTableViewUsingBlock:(void (^)())block;

/** Adds a new section to the model.
 * @param section Must be a valid non nil RKTableViewSection. */
// NOTE: connects cellMappings if section.cellMappings is nil...
- (void)addSection:(RKTableSection *)section;

/** Inserts a new section at the specified index.
 * @param section Must be a valid non nil RKTableViewSection.
 * @param index Must be less than the total number of sections. */
- (void)insertSection:(RKTableSection *)section atIndex:(NSUInteger)index;

/** Removes the specified section from the model.
 * @param section The section to remove. */
- (void)removeSection:(RKTableSection *)section;

/** Removes the section at the specified index from the model.
 * @param index Must be less than the total number of section. */
- (void)removeSectionAtIndex:(NSUInteger)index;

/** Removes all sections from the model. */
// NOTE: Adds a new section 0
- (void)removeAllSections;
- (void)removeAllSections:(BOOL)recreateFirstSection;

@end

#endif // TARGET_OS_IPHONE
