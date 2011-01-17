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
#import "Three20UINavigator/TTURLPattern.h"
#import "Three20UINavigator/TTNavigationMode.h"

@interface TTURLNavigatorPattern : TTURLPattern {
  Class             _targetClass;
  id                _targetObject;
  TTNavigationMode  _navigationMode;
  NSString*         _parentURL;
  NSInteger         _transition;
  NSInteger         _argumentCount;
}

@property (nonatomic, assign)   Class             targetClass;
@property (nonatomic, assign)   id                targetObject;
@property (nonatomic, readonly) TTNavigationMode  navigationMode;
@property (nonatomic, copy)     NSString*         parentURL;
@property (nonatomic, assign)   NSInteger         transition;
@property (nonatomic, assign)   NSInteger         argumentCount;
@property (nonatomic, readonly) BOOL              isUniversal;
@property (nonatomic, readonly) BOOL              isFragment;

- (id)initWithTarget:(id)target;
- (id)initWithTarget:(id)target mode:(TTNavigationMode)navigationMode;

- (void)compile;

- (BOOL)matchURL:(NSURL*)URL;

- (id)invoke:(id)target withURL:(NSURL*)URL query:(NSDictionary*)query;
- (id)createObjectFromURL:(NSURL*)URL query:(NSDictionary*)query;

@end
