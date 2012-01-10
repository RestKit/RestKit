//
//  RKTableViewCellMapping.m
//  RestKit
//
//  Created by Blake Watters on 8/4/11.
//  Copyright (c) 2011 RestKit.
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
#import "../Support/RKLog.h"

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

+ (id)actionWithBlock:(void(^)(id sender))block {
    return [[[self alloc] initWithBlock:block] autorelease];
}

- (id)initWithBlock:(void(^)(id sender))block {
    self = [self init];
    if (self) {
        _actionBlock = Block_copy(block);
    }
    
    return self;
}

- (void)actionForControlEvent:(id)sender {
    _actionBlock(sender);
}

- (SEL)actionSelector {
    return @selector(actionForControlEvent:);
}

- (void)dealloc {
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

// TODO: Figure out nib support...

+ (id)cellMapping {
    return [self mappingForClass:[UITableViewCell class]];
}

+ (id)cellMappingUsingBlock:(void (^)(RKTableViewCellMapping*))block {
    RKTableViewCellMapping* cellMapping = [self cellMapping];
    block(cellMapping);
    return cellMapping;
}

- (id)init {
    self = [super init];
    if (self) {
        self.cellClass = [UITableViewCell class];
        self.style = UITableViewCellStyleDefault;
        self.accessoryType = UITableViewCellAccessoryNone;
        self.selectionStyle = UITableViewCellSelectionStyleBlue;
        self.rowHeight = 44; // TODO: Should row height be an informal protocol on cells???
        self.deselectsRowOnSelection = YES;
        _prepareCellBlocks = [NSMutableArray new];
    }
    
    return self;
}

- (void)addDefaultMappings {
    [self mapKeyPath:@"text" toAttribute:@"textLabel.text"];
    [self mapKeyPath:@"detailText" toAttribute:@"detailTextLabel.text"];
    [self mapKeyPath:@"image" toAttribute:@"imageView.image"];
}

- (void)dealloc {
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

- (NSMutableArray *)prepareCellBlocks {
    return _prepareCellBlocks;
}

- (id)copyWithZone:(NSZone *)zone {
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
    
    for (NSValue *blockValue in [self prepareCellBlocks]) {
        [copy addPrepareCellBlock:[blockValue pointerValue]];
    }
    
    return copy;
}


- (id)mappableObjectForData:(UITableView*)tableView {
    NSAssert([tableView isKindOfClass:[UITableView class]], @"Expected to be invoked with a tableView as the data. Got %@", tableView);
    // TODO: Support for non-dequeueable cells???
    RKLogTrace(@"About to dequeue reusable cell using self.reuseIdentifier=%@", self.reuseIdentifier);
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:self.reuseIdentifier];
    if (! cell) {
        cell = [[[self.objectClass alloc] initWithStyle:self.style 
                                       reuseIdentifier:self.reuseIdentifier] autorelease];
    }    
    cell.accessoryType = self.accessoryType;
    cell.selectionStyle = self.selectionStyle;
    
    // Fire the prepare callbacks
    for (NSValue *value in _prepareCellBlocks) {
        __block void (^prepareCellBlock)(id sender) = [value pointerValue];
        prepareCellBlock(cell);
    }
    
    return cell;
}

- (void)setObjectClass:(Class)objectClass {
    NSAssert([objectClass isSubclassOfClass:[UITableViewCell class]], @"Cell mappings can only target classes that inherit from UITableViewCell");
    [super setObjectClass:objectClass];
}

- (void)setCellClass:(Class)cellClass {
    [self setObjectClass:cellClass];
}

- (NSString*)cellClassName {
    return NSStringFromClass(self.cellClass);
}

- (void)setCellClassName:(NSString *)cellClassName {
    self.cellClass = NSClassFromString(cellClassName);
}

- (Class)cellClass {
    return [self objectClass];
}

- (NSString *)reuseIdentifier {
    return _reuseIdentifier ? _reuseIdentifier : NSStringFromClass(self.objectClass);
}

#pragma mark - Control Action Helpers

- (void)addPrepareCellBlock:(void (^)(UITableViewCell *cell))block {
    NSValue *value = [NSValue valueWithPointer:Block_copy(block)];
    [_prepareCellBlocks addObject:value];
    // TODO: WTF? We can't use blocks naturally...
//    [_prepareCellBlocks addObject:Block_copy(block)];
}

- (void)addTarget:(id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents toControlAtKeyPath:(NSString *)keyPath {
    [self addPrepareCellBlock:^(UITableViewCell *cell) {
        UIControl *control = [cell valueForKeyPath:keyPath];
        if (control) {
            [control addTarget:target action:action forControlEvents:controlEvents];
        } else {
            // TODO: Logging...
        }
    }];
}

- (void)addTarget:(id)target action:(SEL)action forTouchEventToControlAtKeyPath:(NSString *)keyPath {
    [self addTarget:target action:action forControlEvents:UIControlEventTouchUpInside toControlAtKeyPath:keyPath];
}

- (void)addBlockAction:(void (^)(id sender))block forControlEvents:(UIControlEvents)controlEvents toControlAtKeyPath:(NSString *)keyPath {
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

- (void)addBlockAction:(void (^)(id sender))block forTouchEventToControlAtKeyPath:(NSString *)keyPath {
    [self addBlockAction:block forControlEvents:UIControlEventTouchUpInside toControlAtKeyPath:keyPath];
}

#pragma mark - Block setters

// NOTE: We get crashes when relying on just the copy property. Using Block_copy ensures
// correct behavior

- (void)setOnSelectCell:(RKTableViewAnonymousBlock)onSelectCell {
    if (_onSelectCell) {
        Block_release(_onSelectCell);
        _onSelectCell = nil;
    }
    _onSelectCell = Block_copy(onSelectCell);
}

- (void)setOnSelectCellForObjectAtIndexPath:(RKTableViewCellForObjectAtIndexPathBlock)onSelectCellForObjectAtIndexPath {
    if (_onSelectCellForObjectAtIndexPath) {
        Block_release(_onSelectCellForObjectAtIndexPath);
        _onSelectCellForObjectAtIndexPath = nil;
    }
    _onSelectCellForObjectAtIndexPath = Block_copy(onSelectCellForObjectAtIndexPath);
}

- (void)setOnCellWillAppearForObjectAtIndexPath:(RKTableViewCellForObjectAtIndexPathBlock)onCellWillAppearForObjectAtIndexPath {
    if (_onCellWillAppearForObjectAtIndexPath) {
        Block_release(_onCellWillAppearForObjectAtIndexPath);
        _onCellWillAppearForObjectAtIndexPath = nil;
    }
    _onCellWillAppearForObjectAtIndexPath = Block_copy(onCellWillAppearForObjectAtIndexPath);
}

- (void)setHeightOfCellForObjectAtIndexPath:(RKTableViewHeightOfCellForObjectAtIndexPathBlock)heightOfCellForObjectAtIndexPath {
    if (_heightOfCellForObjectAtIndexPath) {
        Block_release(_heightOfCellForObjectAtIndexPath);
        _heightOfCellForObjectAtIndexPath = nil;
    }
    _heightOfCellForObjectAtIndexPath = Block_copy(heightOfCellForObjectAtIndexPath);
}

- (void)setOnTapAccessoryButtonForObjectAtIndexPath:(RKTableViewAccessoryButtonTappedForObjectAtIndexPathBlock)onTapAccessoryButtonForObjectAtIndexPath {
    if (_onTapAccessoryButtonForObjectAtIndexPath) {
        Block_release(_onTapAccessoryButtonForObjectAtIndexPath);
        _onTapAccessoryButtonForObjectAtIndexPath = nil;
    }
    _onTapAccessoryButtonForObjectAtIndexPath = Block_copy(onTapAccessoryButtonForObjectAtIndexPath);
}

- (void)setTitleForDeleteButtonForObjectAtIndexPath:(RKTableViewTitleForDeleteButtonForObjectAtIndexPathBlock)titleForDeleteButtonForObjectAtIndexPath {
    if (_titleForDeleteButtonForObjectAtIndexPath) {
        Block_release(_titleForDeleteButtonForObjectAtIndexPath);
        _titleForDeleteButtonForObjectAtIndexPath = nil;
    }
    _titleForDeleteButtonForObjectAtIndexPath = Block_copy(titleForDeleteButtonForObjectAtIndexPath);
}

- (void)setEditingStyleForObjectAtIndexPath:(RKTableViewEditingStyleForObjectAtIndexPathBlock)editingStyleForObjectAtIndexPath {
    if (_editingStyleForObjectAtIndexPath) {
        Block_release(_editingStyleForObjectAtIndexPath);
        _editingStyleForObjectAtIndexPath = nil;
    }
    _editingStyleForObjectAtIndexPath = Block_copy(editingStyleForObjectAtIndexPath);
}

- (void)setTargetIndexPathForMove:(RKTableViewTargetIndexPathForMoveBlock)targetIndexPathForMove {
    if (_targetIndexPathForMove) {
        Block_release(_targetIndexPathForMove);
        _targetIndexPathForMove = nil;
    }
    _targetIndexPathForMove = Block_copy(targetIndexPathForMove);
}

@end
