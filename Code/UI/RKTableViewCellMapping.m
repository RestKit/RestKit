//
//  RKTableViewCellMapping.m
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

#import "RKTableViewCellMapping.h"
#import "RKLog.h"

// Define logging component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitUI

/**
 A simple class for wrapping blocks into target/action
 invocations that can be used with UIControl events
 */
typedef void(^RKControlBlockActionBlock)(id sender);
@interface RKControlBlockAction : NSObject {
@private
    RKControlBlockActionBlock _actionBlock;
}

@property (nonatomic, readonly) SEL actionSelector;

+ (id)actionWithBlock:(void(^)(id sender))block;
- (id)initWithBlock:(void(^)(id sender))block;

/**
 The target action to use when wrapping a block
 */
- (void)actionForControlEvent:(id)sender;

@end

@implementation RKControlBlockAction

+ (id)actionWithBlock:(void(^)(id sender))block
{
    return [[[self alloc] initWithBlock:block] autorelease];
}

- (id)initWithBlock:(void(^)(id sender))block
{
    self = [self init];
    if (self) {
        _actionBlock = Block_copy(block);
    }

    return self;
}

- (void)actionForControlEvent:(id)sender
{
    _actionBlock(sender);
}

- (SEL)actionSelector
{
    return @selector(actionForControlEvent:);
}

- (void)dealloc
{
    Block_release(_actionBlock);
    [super dealloc];
}

@end

@implementation RKTableViewCellMapping

@synthesize reuseIdentifier = _reuseIdentifier;
@synthesize style = _style;
@synthesize accessoryType = _accessoryType;
@synthesize selectionStyle = _selectionStyle;
@synthesize onSelectCellForObjectAtIndexPath = _onSelectCellForObjectAtIndexPath;
@synthesize onSelectCell = _onSelectCell;
@synthesize onCellWillAppearForObjectAtIndexPath = _onCellWillAppearForObjectAtIndexPath;
@synthesize heightOfCellForObjectAtIndexPath = _heightOfCellForObjectAtIndexPath;
@synthesize onTapAccessoryButtonForObjectAtIndexPath = _onTapAccessoryButtonForObjectAtIndexPath;
@synthesize titleForDeleteButtonForObjectAtIndexPath = _titleForDeleteButtonForObjectAtIndexPath;
@synthesize editingStyleForObjectAtIndexPath = _editingStyleForObjectAtIndexPath;
@synthesize targetIndexPathForMove = _targetIndexPathForMove;
@synthesize rowHeight = _rowHeight;
@synthesize deselectsRowOnSelection = _deselectsRowOnSelection;
@synthesize managesCellAttributes;

+ (id)cellMapping
{
    return [self mappingForClass:[UITableViewCell class]];
}

+ (id)cellMappingForReuseIdentifier:(NSString *)reuseIdentifier
{
    RKTableViewCellMapping *cellMapping = [self cellMapping];
    cellMapping.reuseIdentifier = reuseIdentifier;
    return cellMapping;
}

+ (id)defaultCellMapping
{
    RKTableViewCellMapping *cellMapping = [self cellMapping];
    [cellMapping addDefaultMappings];
    return cellMapping;
}

+ (id)cellMappingUsingBlock:(void (^)(RKTableViewCellMapping *))block
{
    RKTableViewCellMapping *cellMapping = [self cellMapping];
    block(cellMapping);
    return cellMapping;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.cellClass = [UITableViewCell class];
        self.style = UITableViewCellStyleDefault;
        self.managesCellAttributes = NO;
        _accessoryType = UITableViewCellAccessoryNone;
        _selectionStyle = UITableViewCellSelectionStyleBlue;
        self.rowHeight = 44;
        self.deselectsRowOnSelection = YES;
        _prepareCellBlocks = [NSMutableArray new];
    }

    return self;
}

- (void)addDefaultMappings
{
    [self mapKeyPath:@"text" toAttribute:@"textLabel.text"];
    [self mapKeyPath:@"detailText" toAttribute:@"detailTextLabel.text"];
    [self mapKeyPath:@"image" toAttribute:@"imageView.image"];
}

- (void)dealloc
{
    [_reuseIdentifier release];
    [_prepareCellBlocks release];
    Block_release(_onSelectCell);
    Block_release(_onSelectCellForObjectAtIndexPath);
    Block_release(_onCellWillAppearForObjectAtIndexPath);
    Block_release(_heightOfCellForObjectAtIndexPath);
    Block_release(_onTapAccessoryButtonForObjectAtIndexPath);
    Block_release(_titleForDeleteButtonForObjectAtIndexPath);
    Block_release(_editingStyleForObjectAtIndexPath);
    Block_release(_targetIndexPathForMove);
    [super dealloc];
}

- (NSMutableArray *)prepareCellBlocks
{
    return _prepareCellBlocks;
}

- (id)copyWithZone:(NSZone *)zone
{
    RKTableViewCellMapping *copy = [super copyWithZone:zone];
    copy.reuseIdentifier = self.reuseIdentifier;
    copy.style = self.style;
    copy.accessoryType = self.accessoryType;
    copy.selectionStyle = self.selectionStyle;
    copy.onSelectCellForObjectAtIndexPath = self.onSelectCellForObjectAtIndexPath;
    copy.onSelectCell = self.onSelectCell;
    copy.onCellWillAppearForObjectAtIndexPath = self.onCellWillAppearForObjectAtIndexPath;
    copy.heightOfCellForObjectAtIndexPath = self.heightOfCellForObjectAtIndexPath;
    copy.onTapAccessoryButtonForObjectAtIndexPath = self.onTapAccessoryButtonForObjectAtIndexPath;
    copy.titleForDeleteButtonForObjectAtIndexPath = self.titleForDeleteButtonForObjectAtIndexPath;
    copy.editingStyleForObjectAtIndexPath = self.editingStyleForObjectAtIndexPath;
    copy.targetIndexPathForMove = self.targetIndexPathForMove;
    copy.rowHeight = self.rowHeight;

    @synchronized(_prepareCellBlocks) {
        for (void (^block)(UITableViewCell *) in _prepareCellBlocks) {
            void (^blockCopy)(UITableViewCell *cell) = [block copy];
            [copy addPrepareCellBlock:blockCopy];
            [blockCopy release];
        }
    }

    return copy;
}


- (id)mappableObjectForData:(UITableView *)tableView
{
    NSAssert([tableView isKindOfClass:[UITableView class]], @"Expected to be invoked with a tableView as the data. Got %@", tableView);
    RKLogTrace(@"About to dequeue reusable cell using self.reuseIdentifier=%@", self.reuseIdentifier);
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:self.reuseIdentifier];
    if (! cell) {
        cell = [[[self.objectClass alloc] initWithStyle:self.style
                                       reuseIdentifier:self.reuseIdentifier] autorelease];
    }

    if (self.managesCellAttributes) {
        cell.accessoryType = self.accessoryType;
        cell.selectionStyle = self.selectionStyle;
    }

    // Fire the prepare callbacks
    for (void (^block)(UITableViewCell *) in _prepareCellBlocks) {
        block(cell);
    }

    return cell;
}

- (void)setSelectionStyle:(UITableViewCellSelectionStyle)selectionStyle
{
    self.managesCellAttributes = YES;
    _selectionStyle = selectionStyle;
}

- (void)setAccessoryType:(UITableViewCellAccessoryType)accessoryType
{
    self.managesCellAttributes = YES;
    _accessoryType = accessoryType;
}

- (void)setObjectClass:(Class)objectClass
{
    NSAssert([objectClass isSubclassOfClass:[UITableViewCell class]], @"Cell mappings can only target classes that inherit from UITableViewCell");
    [super setObjectClass:objectClass];
}

- (void)setCellClass:(Class)cellClass
{
    [self setObjectClass:cellClass];
}

- (NSString *)cellClassName
{
    return NSStringFromClass(self.cellClass);
}

- (void)setCellClassName:(NSString *)cellClassName
{
    self.cellClass = NSClassFromString(cellClassName);
}

- (Class)cellClass
{
    return [self objectClass];
}

- (NSString *)reuseIdentifier
{
    return _reuseIdentifier ? _reuseIdentifier : NSStringFromClass(self.objectClass);
}

#pragma mark - Control Action Helpers

- (void)addPrepareCellBlock:(void (^)(UITableViewCell *cell))block
{
    void (^blockCopy)(UITableViewCell *cell) = [block copy];
    [_prepareCellBlocks addObject:blockCopy];
    [blockCopy release];
}

- (void)addTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents toControlAtKeyPath:(NSString *)keyPath
{
    [self addPrepareCellBlock:^(UITableViewCell *cell) {
        UIControl *control = [cell valueForKeyPath:keyPath];
        if (control) {
            [control addTarget:target action:action forControlEvents:controlEvents];
        } else {
            // TODO: Logging...
        }
    }];
}

- (void)addTarget:(id)target action:(SEL)action forTouchEventToControlAtKeyPath:(NSString *)keyPath
{
    [self addTarget:target action:action forControlEvents:UIControlEventTouchUpInside toControlAtKeyPath:keyPath];
}

- (void)addBlockAction:(void (^)(id sender))block forControlEvents:(UIControlEvents)controlEvents toControlAtKeyPath:(NSString *)keyPath
{
    [self addPrepareCellBlock:^(UITableViewCell *cell) {
        RKControlBlockAction *blockAction = [RKControlBlockAction actionWithBlock:block];
        UIControl *control = [cell valueForKeyPath:keyPath];
        if (control) {
            [control addTarget:blockAction action:blockAction.actionSelector forControlEvents:controlEvents];
        } else {
            // TODO: Logging...
        }
    }];
}

- (void)addBlockAction:(void (^)(id sender))block forTouchEventToControlAtKeyPath:(NSString *)keyPath
{
    [self addBlockAction:block forControlEvents:UIControlEventTouchUpInside toControlAtKeyPath:keyPath];
}

@end
