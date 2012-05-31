//
//  RKControlTableItem.h
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

#import "RKTableItem.h"

// TODO: Add note that any cell class used with an RKControlTableItem
// must have a control property to be auto-linked to the control in the table item
@interface RKControlTableItem : RKTableItem

@property (nonatomic, retain) UIControl *control;

/** @name Convenience Accessors */

@property (nonatomic, readonly) UIButton *button;
@property (nonatomic, readonly) UITextField *textField;
@property (nonatomic, readonly) UISwitch *switchControl;
@property (nonatomic, readonly) UISlider *slider;
@property (nonatomic, readonly) UILabel *label;

+ (id)tableItemWithControl:(UIControl *)control;

/**
 Return the value from the control as an object. This will wrap
 any primitive values into an appropriate object for use in mapping.
 */
- (id)controlValue;

@end
