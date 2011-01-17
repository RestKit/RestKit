//
// Copyright 2009-2010 Facebook
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class TTPickerTextField;
@class TTMessageController;

/**
 * The base class for all fields used by the TTMessageController.
 */
@interface TTMessageField : NSObject {
  NSString* _title;
  BOOL      _required;
}

/**
 * The title of this field, which will be rendered along with the field's
 * contents.
 */
@property (nonatomic, copy) NSString* title;

/**
 * If true, the user must supply a value for this field before they will be
 * able to send their message.
 */
@property (nonatomic) BOOL required;

- (id)initWithTitle:(NSString*)title required:(BOOL)required;

- (TTPickerTextField*)createViewForController:(TTMessageController*)controller;

- (id)persistField:(UITextField*)textField;

- (void)restoreField:(UITextField*)textField withData:(id)data;

@end
