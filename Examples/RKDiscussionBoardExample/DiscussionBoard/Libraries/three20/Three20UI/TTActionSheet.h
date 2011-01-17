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

/**
 * [private] A subclassed UIActionSheet that retains the popup view controller.
 *
 * This is a leightweight subclass whose sole additional purpose is to retain the popup view
 * controller.
 *
 * @internal Questions to be answered:
 *  - Why is this necessary? Can we get by without this subclass?
 */
@interface TTActionSheet : UIActionSheet {
@protected
  UIViewController* _popupViewController;
}

@property (nonatomic, retain) UIViewController* popupViewController;

@end
