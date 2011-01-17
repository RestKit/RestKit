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

#import "Three20UINavigator/TTBaseNavigator.h"

/**
 * Shortcut for calling [[TTNavigator navigator] openURL:]
 */
UIViewController* TTOpenURL(NSString* URL);

/**
 * A URL-based navigation system with built-in persistence.
 * Add support for model-based controllers and implement the legacy global instance accessor.
 */
@interface TTNavigator : TTBaseNavigator {
}

+ (TTNavigator*)navigator;

/**
 * Reloads the content in the visible view controller.
 */
- (void)reload;

@end
