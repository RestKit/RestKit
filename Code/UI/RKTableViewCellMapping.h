//
//  RKTableViewCellMapping.h
//  RestKit
//
//  Created by Blake Watters on 8/4/11.
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

#import <UIKit/UIKit.h>
#import "RKObjectMapping.h"

/** @name Cell Mapping Block Callbacks **/

typedef void(^RKTableViewCellForObjectAtIndexPathBlock)(UITableViewCell *cell, id object, NSIndexPath *indexPath);
typedef CGFloat(^RKTableViewHeightOfCellForObjectAtIndexPathBlock)(id object, NSIndexPath *indexPath);
typedef void(^RKTableViewAccessoryButtonTappedForObjectAtIndexPathBlock)(UITableViewCell *cell, id object, NSIndexPath *indexPath);
typedef NSString *(^RKTableViewTitleForDeleteButtonForObjectAtIndexPathBlock)(UITableViewCell *cell, id object, NSIndexPath *indexPath);
typedef UITableViewCellEditingStyle(^RKTableViewEditingStyleForObjectAtIndexPathBlock)(UITableViewCell *cell, id object, NSIndexPath *indexPath);
typedef NSIndexPath *(^RKTableViewTargetIndexPathForMoveBlock)(UITableViewCell *cell, id object, NSIndexPath *sourceIndexPath, NSIndexPath *destIndexPath);
typedef void(^RKTableViewAnonymousBlock)();
typedef void(^RKTableViewCellBlock)(UITableViewCell *cell);

/**
 Defines a RestKit object mapping suitable for mapping generic
 objects into UITableViewCell derived classes or cells loaded from
 NIBs. The cell mapping leverages RestKit's object mapping engine to
 dynamically map keyPaths in your object model into properties on the
 table cell view.

 Cell mappings are used to drive table view cells within an RKTableController
 derived class. The cell mapping does not require any specific implementation
 on the target cell classes beyond exposure of the configurable UIView's via
 KVC properties.

 @see RKTableController
 */
@interface RKTableViewCellMapping : RKObjectMapping {
@protected
    NSMutableArray *_prepareCellBlocks;
}

/**
 The UITableViewCell subclass that this mapping will target. This
 is an alias for the objectClass property defined on the base mapping
 provided here to make things more explicit.

 @default [GGImageButtonTableViewCell class]
 @see objectClass
 */
@property (nonatomic, assign) Class cellClass;

/**
 Convenience accessor for setting the cellClass attribute via a string
 rather than a class instance. This will typically save you from having
 to #import the header file for your target cells in your table view controller

 @default @"GGImageButtonTableViewCell"
 @see cellClass
 */
@property (nonatomic, assign) NSString *cellClassName;

/**
 A reuse identifier for cells created using this mapping. These cells will be
 dequeued and reused within the table view for optimal performance. By default,
 a reuseIdentifier is set for you when you assign an object class to the mapping.
 You can override this behavior if you have multiple cells representing the same types
 of objects within the table view and need to pool the cells differently.

 @default NSStringFromClass(self.objectClass)
 */
@property (nonatomic, retain) NSString *reuseIdentifier;

/**
 A Boolean value that determines whether the cell mapping manages basic cell
 attributes (accessoryType, selectionStyle, etc.) or defers to a Storyboard/XIB
 for defining basic cell attributes.

 Setting the accessoryType or selectionStyle will set the value to YES.

 **Default**: NO
 */
@property (nonatomic, assign) BOOL managesCellAttributes;

/**
 The cell style to use for cells created with this mapping

 @default UITableViewCellStyleDefault
 */
@property (nonatomic, assign) UITableViewCellStyle style;

/**
 The cell accessory type to use for cells created with this mapping

 @default UITableViewCellAccessoryNone
 */
@property (nonatomic, assign) UITableViewCellAccessoryType accessoryType;

/**
 The cell selection style to use for cells created with this mapping

 @default UITableViewCellSelectionStyleBlue
 */
@property (nonatomic, assign) UITableViewCellSelectionStyle selectionStyle;

/**
 Whether the tableController should call deselectRowAtIndexPath:animated:
 on the tableView when a cell is selected.

 @default YES
 */
@property (nonatomic, assign) BOOL deselectsRowOnSelection;

/**
 The row height to use for cells created with this mapping.
 Use of this property requires that RKTableController instance you are
 using the mapping to build cells for has been configured with variableHeightRows = YES

 This value is mutually exclusive of the heightOfCellForObjectAtIndexPath property
 and will be ignored if you assign a block to perform dynamic row height calculations.

 **Default**: 44
 */
@property (nonatomic, assign) CGFloat rowHeight;

/** @name Cell Events **/

/**
 Invoked when the user has touched a cell corresponding to an object. The block
 is invoked with a reference to both the UITableViewCell that was touched and the
 object the cell is representing.
 */
@property (nonatomic, copy) RKTableViewCellForObjectAtIndexPathBlock onSelectCellForObjectAtIndexPath;

/**
 Invoked when the user has touched a cell configured with this mapping. The block is invoked
 without any arguments. This is useful for one-off touch events where you do not care about
 the content in which the selection took place.

 @see onSelectCellForObjectAtIndexPath
 */
@property (nonatomic, copy) RKTableViewAnonymousBlock onSelectCell;

/**
 A block to invoke when a table view cell created with this mapping is going to appear in the table.
 The block will be invoked with the UITableViewCell, an id reference to the mapped object being
 represented in the cell, and the NSIndexPath for the row position the cell will be appearing at.

 This is a good moment to perform any customization to the cell before it becomes visible in the table view.
 */
@property (nonatomic, copy) RKTableViewCellForObjectAtIndexPathBlock onCellWillAppearForObjectAtIndexPath;

/**
 A block to invoke when the table view is measuring the height of the UITableViewCell.
 The block will be invoked with the UITableViewCell, an id reference to the mapped object being
 represented in the cell, and the NSIndexPath for the row position the cell will be appearing at.
 */
@property (nonatomic, copy) RKTableViewHeightOfCellForObjectAtIndexPathBlock heightOfCellForObjectAtIndexPath;

/**
 A block to invoke when the accessory button for a given cell is tapped by the user.
 The block will be invoked with the UITableViewCell, an id reference to the mapped object being
 represented in the cell, and the NSIndexPath for the row position the cell will be appearing at.
 */
@property (nonatomic, copy) RKTableViewAccessoryButtonTappedForObjectAtIndexPathBlock onTapAccessoryButtonForObjectAtIndexPath;

/**
 A block to invoke when the table view is determining the title for the delete confirmation button.
 The block will be invoked with the UITableViewCell, an id reference to the mapped object being
 represented in the cell, and the NSIndexPath for the row position the cell will be appearing at.
 */
@property (nonatomic, copy) RKTableViewTitleForDeleteButtonForObjectAtIndexPathBlock titleForDeleteButtonForObjectAtIndexPath;

/**
 A block to invoke when the table view is determining the editing style for a given row.
 The block will be invoked with the UITableViewCell, an id reference to the mapped object being
 represented in the cell, and the NSIndexPath for the row position the cell will be appearing at.
 */
@property (nonatomic, copy) RKTableViewEditingStyleForObjectAtIndexPathBlock editingStyleForObjectAtIndexPath;

@property (nonatomic, copy) RKTableViewTargetIndexPathForMoveBlock targetIndexPathForMove;

/**
 Returns a new auto-released mapping targeting UITableViewCell
 */
+ (id)cellMapping;

/**
 Returns a new auto-released mapping targeting UITableViewCell with the specified reuseIdentifier
 */
+ (id)cellMappingForReuseIdentifier:(NSString *)reuseIdentifier;

/**
 Creates and returns an RKTableCellMapping instance configured with the default cell mappings.

 @return An RKTableCellMapping instance with default mappings applied.
 @see [RKTableCellMapping addDefaultMappings]
 */
+ (id)defaultCellMapping;

/**
 Returns a new auto-released object mapping targeting UITableViewCell. The mapping
 will be yielded to the block for configuration.
 */
+ (id)cellMappingUsingBlock:(void (^)(RKTableViewCellMapping *cellMapping))block;

/**
 Sets up default mappings connecting common properties to their UITableViewCell counterparts as follows:

     [self mapKeyPath:@"text" toAttribute:@"textLabel.text"];
     [self mapKeyPath:@"detailText" toAttribute:@"detailTextLabel.text"];
     [self mapKeyPath:@"image" toAttribute:@"imageView.image"];

 These properties are exposed on the RKTableItem class for convenience in quickly building static
 table views/

 @see RKTableItem
 */
- (void)addDefaultMappings;

/**
 Configure a block to be invoked whenever a cell is prepared for use with this mapping.
 The block will be invoked each time a cell is either initialized or dequeued for reuse.
 */
- (void)addPrepareCellBlock:(void (^)(UITableViewCell *cell))block;

/** @name Configuring Control Actions */
// TODO: Docs!!!

- (void)addTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents toControlAtKeyPath:(NSString *)keyPath;
- (void)addTarget:(id)target action:(SEL)action forTouchEventToControlAtKeyPath:(NSString *)keyPath;
- (void)addBlockAction:(void (^)(id sender))block forControlEvents:(UIControlEvents)controlEvents toControlAtKeyPath:(NSString *)keyPath;
- (void)addBlockAction:(void (^)(id sender))block forTouchEventToControlAtKeyPath:(NSString *)keyPath;

@end
