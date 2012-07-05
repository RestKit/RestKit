//
//  RKKeyboardScroller.m
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

#import "RKKeyboardScroller.h"
#import "RKLog.h"
#import "UIView+FindFirstResponder.h"

// Define logging component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitUI

@interface RKKeyboardScroller ()

@property (nonatomic, retain, readwrite) UIViewController *viewController;
@property (nonatomic, retain, readwrite) UIScrollView *scrollView;
@end

@implementation RKKeyboardScroller

@synthesize viewController = _viewController;
@synthesize scrollView = _scrollView;

- (id)init
{
    RKLogError(@"Failed to call designated initialized initWithViewController:");
    [self doesNotRecognizeSelector:_cmd];
    [self release];
    return nil;
}

- (id)initWithViewController:(UIViewController *)viewController scrollView:(UIScrollView *)scrollView
{
    NSAssert(viewController, @"%@ must be instantiated with a viewController.", [self class]);
    NSAssert(scrollView, @"%@ must be instantiated with a scrollView.", [self class]);

    self = [super init];
    if (self) {
        self.viewController = viewController;
        self.scrollView = scrollView;

        // Register for Keyboard notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleKeyboardNotification:)
                                                     name:UIKeyboardWillShowNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleKeyboardNotification:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
    }

    return self;
}

- (void)dealloc
{
    self.viewController = nil;
    self.scrollView = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [super dealloc];
}

- (void)handleKeyboardNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];

    CGRect keyboardEndFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat heightForViewShift = keyboardEndFrame.size.height;
    RKLogTrace(@"keyboardEndFrame.size.height=%f, heightForViewShift=%f",
               keyboardEndFrame.size.height, heightForViewShift);

    CGFloat bottomBarOffset = 0.0;
    UINavigationController *navigationController = self.viewController.navigationController;
    if (navigationController && navigationController.toolbar && !navigationController.toolbarHidden) {
        bottomBarOffset += navigationController.toolbar.frame.size.height;
        RKLogTrace(@"Found a visible toolbar. Reducing size of heightForViewShift by=%f", bottomBarOffset);
    }

    UITabBarController *tabBarController = self.viewController.tabBarController;
    if (tabBarController && tabBarController.tabBar && !self.viewController.hidesBottomBarWhenPushed) {
        bottomBarOffset += tabBarController.tabBar.frame.size.height;
        RKLogTrace(@"Found a visible tabBar. Reducing size of heightForViewShift by=%f", bottomBarOffset);
    }

    if ([[notification name] isEqualToString:UIKeyboardWillShowNotification]) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.2];

        UIEdgeInsets contentInsets = UIEdgeInsetsMake(0, 0, (heightForViewShift - bottomBarOffset), 0);
        self.scrollView.contentInset = contentInsets;
        self.scrollView.scrollIndicatorInsets = contentInsets;

        CGRect nonKeyboardRect = self.scrollView.frame;
        nonKeyboardRect.size.height -= heightForViewShift;
        RKLogTrace(@"Searching for a firstResponder not inside our nonKeyboardRect (%f, %f, %f, %f)",
                   nonKeyboardRect.origin.x, nonKeyboardRect.origin.y,
                   nonKeyboardRect.size.width, nonKeyboardRect.size.height);

        UIView *firstResponder = [self.scrollView findFirstResponder];
        if (firstResponder) {
            CGRect firstResponderFrame = firstResponder.frame;
            RKLogTrace(@"Found firstResponder=%@ at (%f, %f, %f, %f)", firstResponder,
                       firstResponderFrame.origin.x, firstResponderFrame.origin.y,
                       firstResponderFrame.size.width, firstResponderFrame.size.width);

            if (![firstResponder.superview isEqual:self.scrollView]) {
                firstResponderFrame = [firstResponder.superview convertRect:firstResponderFrame toView:self.scrollView];
                RKLogTrace(@"firstResponder (%@) frame is not in viewToBeResized's coordinate system. Coverted to (%f, %f, %f, %f)",
                           firstResponder, firstResponderFrame.origin.x, firstResponderFrame.origin.y,
                           firstResponderFrame.size.width, firstResponderFrame.size.height);
            }

            if (!CGRectContainsPoint(nonKeyboardRect, firstResponderFrame.origin)) {
                RKLogTrace(@"firstResponder (%@) is underneath keyboard. Beginning scroll of tableView to show", firstResponder);
                [self.scrollView scrollRectToVisible:firstResponderFrame animated:YES];
            }
        }
        [UIView commitAnimations];

    } else if ([[notification name] isEqualToString:UIKeyboardWillHideNotification]) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.2];
        UIEdgeInsets contentInsets = UIEdgeInsetsZero;
        self.scrollView.contentInset = contentInsets;
        self.scrollView.scrollIndicatorInsets = contentInsets;
        [UIView commitAnimations];
    }
}

@end
