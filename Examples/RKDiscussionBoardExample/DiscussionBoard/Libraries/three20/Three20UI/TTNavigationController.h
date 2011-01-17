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

#import "Three20UINavigator/TTBaseNavigationController.h"

@interface TTNavigationController : TTBaseNavigationController {

}

/**
 * Pushes a view controller with a transition other than the standard sliding animation.
 */
- (void)pushViewController: (UIViewController*)controller
    animatedWithTransition: (UIViewAnimationTransition)transition;

/**
 * Pops a view controller with a transition other than the standard sliding animation.
 */
- (UIViewController*)popViewControllerAnimatedWithTransition:(UIViewAnimationTransition)transition;


@end
