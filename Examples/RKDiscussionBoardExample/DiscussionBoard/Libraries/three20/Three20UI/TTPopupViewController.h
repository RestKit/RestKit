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

// UI
#import "Three20UI/TTModelViewController.h"

/**
 * A view controller which, when displayed modally, inserts its view over the parent controller.
 *
 * Normally, displaying a modal view controller will completely hide the underlying view
 * controller, and even remove its view from the view hierarchy.  Popup view controllers allow
 * you to present a "modal" view which overlaps the parent view controller but does not
 * necessarily hide it.
 *
 * This class is meant to be subclassed, not used directly.
 */
@interface TTPopupViewController : TTModelViewController {
}

- (void)showInView:(UIView*)view animated:(BOOL)animated;
- (void)dismissPopupViewControllerAnimated:(BOOL)animated;

@end
