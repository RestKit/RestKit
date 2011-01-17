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

@interface UIViewController (TTNavigator)

/**
 * The default initializer sent to view controllers opened through TTNavigator.
 */
- (id)initWithNavigatorURL:(NSURL*)URL query:(NSDictionary*)query;

/**
 * The current URL that this view controller represents.
 */
@property (nonatomic, readonly) NSString* navigatorURL;

/**
 * The URL that was used to load this controller through TTNavigator.
 *
 * Do not ever change the value of this property.  TTNavigator will assign this
 * when creating your view controller, and it expects it to remain constant throughout
 * the view controller's life.  You can override navigatorURL if you want to specify
 * a different URL for your view controller to use when persisting and restoring it.
 */
@property (nonatomic, copy) NSString* originalNavigatorURL;

/**
 * A temporary holding place for persisted view state waiting to be restored.
 *
 * While restoring controllers, TTURLMap will assign this the dictionary created by persistView.
 * Ultimately, this state is bound for the restoreView call, but it is up to subclasses to
 * call restoreView at the appropriate time -- usually after the view has been created.
 *
 * After you've restored the state, you should set frozenState to nil.
 */
@property (nonatomic, retain) NSDictionary* frozenState;

/**
 * Forcefully initiates garbage collection. You may call this in your didReceiveMemoryWarning
 * message if you are worried about garbage collection memory consumption.
 *
 * See Articles/UI/GarbageCollection.mdown for a more detailed discussion.
 */
+ (void)doNavigatorGarbageCollection;

@end
