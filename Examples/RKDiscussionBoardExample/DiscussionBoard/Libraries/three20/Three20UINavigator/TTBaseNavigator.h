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

#import "Three20UINavigator/TTNavigatorPersistenceMode.h"

@protocol TTNavigatorDelegate;
@class TTURLAction;
@class TTURLMap;
@class TTURLPattern;

/**
 * A URL-based navigation system with built-in persistence.
 */
@interface TTBaseNavigator : NSObject {
  TTURLMap*                   _URLMap;

  UIWindow*                   _window;

  UIViewController*           _rootViewController;
  NSMutableArray*             _delayedControllers;

  TTNavigatorPersistenceMode  _persistenceMode;
  NSTimeInterval              _persistenceExpirationAge;

  BOOL                        _delayCount;

  BOOL                        _supportsShakeToReload;
  BOOL                        _opensExternalURLs;

  id<TTNavigatorDelegate>     _delegate;
}

/**
 * The URL map used to translate between URLs and view controllers.
 *
 * @see TTURLMap
 */
@property (nonatomic, readonly) TTURLMap* URLMap;

/**
 * The window that contains the view controller hierarchy.
 *
 * By default retrieves the keyWindow. If there is no keyWindow, creates a new
 * TTNavigatorWindow.
 */
@property (nonatomic, retain) UIWindow* window;

/**
 * The controller that is at the root of the view controller hierarchy.
 */
@property (nonatomic, readonly) UIViewController* rootViewController;

/**
 * The currently visible view controller.
 */
@property (nonatomic, readonly) UIViewController* visibleViewController;

/**
 * The view controller that is currently on top of the navigation stack.
 *
 * This differs from visibleViewController in that it ignores things like search
 * display controllers which are visible, but not part of navigation.
 */
@property (nonatomic, readonly) UIViewController* topViewController;

/**
 * The URL of the currently visible view controller;
 *
 * Setting this property will open a new URL.
 */
@property (nonatomic, copy) NSString* URL;

/**
 * How view controllers are automatically persisted on termination and restored on launch.
 *
 * @default TTNavigatorPersistenceModeNone
 */
@property (nonatomic) TTNavigatorPersistenceMode persistenceMode;

/**
 * The age at which persisted view controllers are too old to be restored.
 *
 * In some cases, it is a good practice not to restore really old navigation paths, because
 * the user probably won't remember how they got there, and would prefer to start from the
 * beginning.
 *
 * Set this to 0 to restore from any age.
 *
 * @default 0
 */
@property (nonatomic) NSTimeInterval persistenceExpirationAge;

/**
 * Causes the current view controller to be reloaded when shaking the phone.
 *
 * @default NO
 */
@property (nonatomic) BOOL supportsShakeToReload;

/**
 * Allows URLs to be opened externally if they don't match any patterns.
 *
 * @default NO
 */
@property (nonatomic) BOOL opensExternalURLs;

/**
 * Indicates that we are asking controllers to delay heavy operations until a later time.
 *
 * @default NO
 */
@property (nonatomic, readonly) BOOL isDelayed;

@property (nonatomic, assign) id<TTNavigatorDelegate> delegate;


+ (TTBaseNavigator*)globalNavigator;
+ (void)setGlobalNavigator:(TTBaseNavigator*)navigator;

/**
 * Load and display the view controller with a pattern that matches the URL.
 *
 * This method replaces all other openURL methods by using the chainable TTURLAction object.
 *
 * If there is not yet a rootViewController, the view controller loaded with this URL
 * will be assigned as the rootViewController and inserted into the keyWindow. If there is not
 * a keyWindow, a UIWindow will be created and displayed.
 *
 * Example TTURLAction initialization:
 * [[TTURLAction actionWithURLPath:@"tt://some/path"]
 *                   applyAnimated:YES]
 *
 * Each apply* method on the TTURLAction object returns self, allowing you to chain methods
 * when initializing the object. This allows for a flexible method that requires a shifting set
 * of parameters that have specific defaults. The old openURL* methods are being phased out, so
 * please start using openURLAction instead.
 */
- (UIViewController*)openURLAction:(TTURLAction*)URLAction;

/**
 * Opens a sequence of URLs.
 *
 * @return The view controller of the last opened URL.
 */
- (UIViewController*)openURLs:(NSString*)URL,...;

/**
 * Gets a view controller for the URL without opening it.
 *
 * @return The view controller mapped to URL.
 */
- (UIViewController*)viewControllerForURL:(NSString*)URL;

/**
 * Gets a view controller for the URL without opening it.
 *
 * @return The view controller mapped to URL.
 */
- (UIViewController*)viewControllerForURL:(NSString*)URL query:(NSDictionary*)query;

/**
 * Gets a view controller for the URL without opening it.
 *
 * @return The view controller mapped to URL.
 */
- (UIViewController*)viewControllerForURL:(NSString*)URL query:(NSDictionary*)query
                                  pattern:(TTURLPattern**)pattern;

/**
 * Tells the navigator to delay heavy operations.
 *
 * Initializing controllers can be very expensive, so if you are going to do some animation
 * while this might be happening, this will tell controllers created through the navigator
 * that they should hold off so as not to slow down the operations.
 */
- (void)beginDelay;

/**
 * Tells controllers that were created during the delay to finish what they were planning to do.
 */
- (void)endDelay;

/**
 * Cancels the delay without notifying delayed controllers.
 */
- (void)cancelDelay;

/**
 * Persists all view controllers to user defaults.
 */
- (void)persistViewControllers;

/**
 * Restores all view controllers from user defaults and returns the last one.
 */
- (UIViewController*)restoreViewControllers;

/**
 * Persists a view controller's state and recursively persists the next view controller after it.
 *
 * Do not call this directly except from within a view controller that is being directed
 * by the app map to persist itself.
 */
- (void)persistController:(UIViewController*)controller path:(NSMutableArray*)path;

/**
 * Removes all view controllers from the window and releases them.
 */
- (void)removeAllViewControllers;

/**
 * Gets a navigation path which can be used to locate an object.
 */
- (NSString*)pathForObject:(id)object;

/**
 * Finds an object using its navigation path.
 */
- (id)objectForPath:(NSString*)path;

/**
 * Erases all data stored in user defaults.
 */
- (void)resetDefaults;

@end
