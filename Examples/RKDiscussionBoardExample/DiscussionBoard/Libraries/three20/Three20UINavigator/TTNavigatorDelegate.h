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

@class TTBaseNavigator;

@protocol TTNavigatorDelegate <NSObject>
@optional

/**
 * Asks if the URL should be opened and allows the delegate to prevent it.
 * See -navigator:URLToOpen: for a superset of functionality
 */
- (BOOL)navigator:(TTBaseNavigator*)navigator shouldOpenURL:(NSURL*)URL;

/**
 * Asks if the URL should be opened and allows the delegate to return a different URL to open
 * instead. A return value of nil indicates the URL should not be opened.
 *
 * This is a superset of the functionality of -navigator:shouldOpenURL:. Returning YES from that
 * method is equivalent to returning URL from this method.
 */
- (NSURL*)navigator:(TTBaseNavigator*)navigator URLToOpen:(NSURL*)URL;

/**
 * The URL is about to be opened in a controller.
 *
 * If the controller argument is nil, the URL is going to be opened externally.
 */
- (void)navigator:(TTBaseNavigator*)navigator willOpenURL:(NSURL*)URL
 inViewController:(UIViewController*)controller;

@end
