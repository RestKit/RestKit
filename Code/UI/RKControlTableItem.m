//
//  RKControlTableItem.m
//  RestKit
//
//  Created by Blake Watters on 8/22/11.
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

#import "RKControlTableItem.h"
#import "RKTableViewCellMapping.h"
#import "RKControlTableViewCell.h"

@implementation RKControlTableItem

@synthesize control = _control;

+ (id)tableItemWithControl:(UIControl *)control
{
    RKControlTableItem *tableItem = [self tableItem];
    tableItem.control = control;
    return tableItem;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.cellMapping.selectionStyle = UITableViewCellSelectionStyleNone;
        self.cellMapping.accessoryType = UITableViewCellAccessoryNone;
        self.cellMapping.cellClass = [RKControlTableViewCell class];

        // Link the UITableViewCell for this table item with the control
        [self.cellMapping addPrepareCellBlock:^(UITableViewCell *cell) {
            if ([cell respondsToSelector:@selector(setControl:)]) {
                [cell setValue:self.control forKey:@"control"];
            }
        }];
    }

    return self;
}

- (void)dealloc
{
    [_control release];
    [super dealloc];
}

- (void)setControl:(UIControl *)control
{
    NSAssert(control, @"Cannot add a nil control to a RKControlTableItem");
    [control retain];
    [_control release];
    _control = control;
}

#pragma mark - Convenience Accessors

- (UIButton *)button
{
    return ([self.control isKindOfClass:[UIButton class]]) ? (UIButton *)self.control : nil;
}

- (UITextField *)textField
{
    return ([self.control isKindOfClass:[UITextField class]]) ? (UITextField *)self.control : nil;
}

- (UISwitch *)switchControl
{
    return ([self.control isKindOfClass:[UISwitch class]]) ? (UISwitch *)self.control : nil;
}

- (UISlider *)slider
{
    return ([self.control isKindOfClass:[UISlider class]]) ? (UISlider *)self.control : nil;
}

- (UILabel *)label
{
    return ([self.control isKindOfClass:[UILabel class]]) ? (UILabel *)self.control : nil;
}

// TODO: What if we replace this with a protocol that enables KVC
// via the 'controlValue' property for the common types to allow pluggability?
- (id)controlValue
{
    if ([self.control isKindOfClass:[UIButton class]]) {
        return nil;
    } else if ([self.control isKindOfClass:[UITextField class]]) {
        return self.textField.text;
    } else if ([self.control isKindOfClass:[UISlider class]]) {
        return [NSNumber numberWithFloat:self.slider.value];
    } else if ([self.control isKindOfClass:[UISwitch class]]) {
        return [NSNumber numberWithBool:self.switchControl.isOn];
    }

    return nil;
}

@end
