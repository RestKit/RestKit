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
 * A view controller with some useful additions.
 */
@interface TTBaseViewController : UIViewController {
@protected
  NSDictionary*     _frozenState;
  UIBarStyle        _navigationBarStyle;
  UIColor*          _navigationBarTintColor;
  UIStatusBarStyle  _statusBarStyle;

  BOOL _isViewAppearing;
  BOOL _hasViewAppeared;
  BOOL _autoresizesForKeyboard;
}

/**
 * The style of the navigation bar when this view controller is pushed onto
 * a navigation controller.
 *
 * @default UIBarStyleDefault
 */
@property (nonatomic) UIBarStyle navigationBarStyle;

/**
 * The color of the navigation bar when this view controller is pushed onto
 * a navigation controller.
 *
 * @default TTSTYLEVAR(navigationBarTintColor)
 */
@property (nonatomic, retain) UIColor* navigationBarTintColor;

/**
 * The style of the status bar when this view controller is appearing.
 *
 * @default UIStatusBarStyleDefault
 */
@property (nonatomic) UIStatusBarStyle statusBarStyle;

/**
 * The view has appeared at least once and hasn't been removed due to a memory warning.
 */
@property (nonatomic, readonly) BOOL hasViewAppeared;

/**
 * The view is about to appear and has not appeared yet.
 */
@property (nonatomic, readonly) BOOL isViewAppearing;

/**
 * Determines if the view will be resized automatically to fit the keyboard.
 */
@property (nonatomic) BOOL autoresizesForKeyboard;


/**
 * Sent to the controller before the keyboard slides in.
 */
- (void)keyboardWillAppear:(BOOL)animated withBounds:(CGRect)bounds;

/**
 * Sent to the controller before the keyboard slides out.
 */
- (void)keyboardWillDisappear:(BOOL)animated withBounds:(CGRect)bounds;

/**
 * Sent to the controller after the keyboard has slid in.
 */
- (void)keyboardDidAppear:(BOOL)animated withBounds:(CGRect)bounds;

/**
 * Sent to the controller after the keyboard has slid out.
 */
- (void)keyboardDidDisappear:(BOOL)animated withBounds:(CGRect)bounds;


@end
