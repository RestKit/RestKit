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
#import "Three20UI/TTTableItem.h"

@interface TTTableLinkedItem : TTTableItem {
  // If a URL is specified, TTNavigator will be used. Otherwise, the delegate+selector will
  // be invoked.
  NSString* _URL;
  NSString* _accessoryURL;

  id        _delegate;
  SEL       _selector;
}

@property (nonatomic, copy) 	NSString* URL;
@property (nonatomic, copy)   NSString* accessoryURL;
@property (nonatomic, assign) id        delegate;
@property (nonatomic, assign) SEL       selector;

@end
