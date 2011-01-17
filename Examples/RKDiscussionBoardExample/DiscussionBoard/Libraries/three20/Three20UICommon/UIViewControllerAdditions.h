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

@interface UIViewController (TTCategory)

/**
 * Determines whether a controller is primarily a container of other controllers.
 *
 * @default NO
 */
@property (nonatomic, readonly) BOOL canContainControllers;

/**
 * Whether or not this controller should ever be counted as the "top" view controller. This is
 * used for the purposes of determining which controllers should have modal controllers presented
 * within them.
 *
 * @default YES; subclasses may override to NO if they so desire.
 */
@property (nonatomic, readonly) BOOL canBeTopViewController;

/**
 * The view controller that contains this view controller.
 *
 * This is just like parentViewController, except that it is not readonly.  This property offers
 * custom UIViewController subclasses the chance to tell TTNavigator how to follow the hierarchy
 * of view controllers.
 */
@property (nonatomic, retain) UIViewController* superController;

/**
 * The child of this view controller which is most visible.
 *
 * This would be the selected view controller of a tab bar controller, or the top
 * view controller of a navigation controller.  This property offers custom UIViewController
 * subclasses the chance to tell TTNavigator how to follow the hierarchy of view controllers.
 */
- (UIViewController*)topSubcontroller;

/**
 * The view controller that comes before this one in a navigation controller's history.
 *
 * This is an App Store-compatible version of previousViewController.
 */
- (UIViewController*)ttPreviousViewController;

/**
 * The view controller that comes after this one in a navigation controller's history.
 */
- (UIViewController*)nextViewController;

/**
 * A popup view controller that is presented on top of this view controller.
 */
@property (nonatomic, retain) UIViewController* popupViewController;

/**
 * Displays a controller inside this controller.
 *
 * TTURLMap uses this to display newly created controllers.  The default does nothing --
 * UIViewController categories and subclasses should implement to display the controller
 * in a manner specific to them.
 */
- (void)addSubcontroller:(UIViewController*)controller animated:(BOOL)animated
        transition:(UIViewAnimationTransition)transition;

/**
 * Dismisses a view controller using the opposite transition it was presented with.
 */
- (void)removeFromSupercontroller;
- (void)removeFromSupercontrollerAnimated:(BOOL)animated;

/**
 * Brings a controller that is a child of this controller to the front.
 *
 * TTURLMap uses this to display controllers that exist already, but may not be visible.
 * The default does nothing -- UIViewController categories and subclasses should implement
 * to display the controller in a manner specific to them.
 */
- (void)bringControllerToFront:(UIViewController*)controller animated:(BOOL)animated;

/**
 * Gets a key that can be used to identify a subcontroller in subcontrollerForKey.
 */
- (NSString*)keyForSubcontroller:(UIViewController*)controller;

/**
 * Gets a subcontroller with the key that was returned from keyForSubcontroller.
 */
- (UIViewController*)subcontrollerForKey:(NSString*)key;

/**
 * Persists aspects of the view state to a dictionary that can later be used to restore it.
 *
 * This will be called when TTNavigator is persisting the navigation history so that it
 * can later be restored.  This usually happens when the app quits, or when there is a low
 * memory warning.
 *
 * Return NO to avoid adding this controller to the navigation history.
 *
 * Default return value: YES
 */
- (BOOL)persistView:(NSMutableDictionary*)state;

/**
 * Restores aspects of the view state from a dictionary populated by persistView.
 *
 * This will be called when TTNavigator is restoring the navigation history.  This may
 * happen after launch, or when the controller appears again after a low memory warning.
 */
- (void)restoreView:(NSDictionary*)state;

/**
 * XXXjoe Not documenting this in the hopes that I can eliminate it ;)
 */
- (void)persistNavigationPath:(NSMutableArray*)path;

/**
 * Finishes initializing the controller after a TTNavigator-coordinated delay.
 *
 * If the controller was created in between calls to TTNavigator beginDelay and endDelay, then
 * this will be called after endDelay.
 */
- (void)delayDidEnd;

/**
 * Shows or hides the navigation and status bars.
 */
- (void)showBars:(BOOL)show animated:(BOOL)animated;

/**
 * Shortcut for its animated-optional cousin.
 */
- (void)dismissModalViewController;

/**
 * Forcefully initiates garbage collection. You may call this in your didReceiveMemoryWarning
 * message if you are worried about garbage collection memory consumption.
 *
 * See Articles/UI/GarbageCollection.mdown for a more detailed discussion.
 */
+ (void)doCommonGarbageCollection;

@end
