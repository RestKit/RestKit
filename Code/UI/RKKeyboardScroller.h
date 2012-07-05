//
//  RKKeyboardScroller.h
//  RestKit
//
//  Created by Blake Watters on 7/5/12.
//  Copyright (c) 2012 RestKit, Inc. All rights reserved.
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

/**
 RKKeyboardScroller objects provide support for the automatic adjustment of views
 contained with a UIScrollView (or dervied classes, such as a UITableView) in response
 to the appearance or disappearance of the keyboard. The scroller adjusts the content
 inset of the scroll view being observed to accommodate the pixels consumed by the keyboard.
 It also tracks the first responder and scrolls it into the visible field if obscured by
 the appearance of the keyboard.
 */
@interface RKKeyboardScroller : NSObject

/**
 The view controller containing the target scroll view within its managed view hierarchy.
 */
@property (nonatomic, retain, readonly) UIViewController *viewController;

/**
 The scroll view that is to be scrolled in response to the appearance and disappearance of
 the keyboard.
 */
@property (nonatomic, retain, readonly) UIScrollView *scrollView;

/**
 Instantiates the receiver with a view controller and scroll view that is to be scrolled
 in response to keyboard notifications.

 @param viewController The view controller object that should have its view resized.
 @param scrollView The scroll view that is to be scrolled in response to the keyboard
 @return The receiver, initialized with the given view controller.
 */
- (id)initWithViewController:(UIViewController *)viewController scrollView:(UIScrollView *)scrollView;

@end

#endif
