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

@class TTActionSheetController;

/**
 * Inherits the UIActionSheetDelegate protocol and adds TTNavigator support.
 */
@protocol TTActionSheetControllerDelegate <UIActionSheetDelegate>
@optional

/**
 * Sent to the delegate after an action sheet is dismissed from the screen.
 *
 * This method is invoked after the animation ends and the view is hidden.
 *
 * If this method is not implemented, the default action is to open the given URL.
 * If this method is implemented and returns NO, then the caller will not navigate to the given
 * URL.
 *
 * @param controller  The controller that was dismissed.
 * @param buttonIndex The index of the button that was clicked. The button indices start at 0. If
 *                    this is the cancel button index, the action sheet is canceling. If -1, the
 *                    cancel button index is not set.
 * @param URL         The URL of the selected button.
 *
 * @return YES to open the given URL with TTOpenURL.
 */
- (BOOL)actionSheetController: (TTActionSheetController*)controller
    didDismissWithButtonIndex: (NSInteger)buttonIndex
                          URL: (NSString*)URL;

@end
