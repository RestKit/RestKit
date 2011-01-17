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

@class TTStyle;

/**
 * TTPageControl is a version of UIPageControl which allows you to style the dots.
 */
@interface TTPageControl : UIControl {
  NSInteger _numberOfPages;
  NSInteger _currentPage;

  NSString* _dotStyle;
  TTStyle*  _normalDotStyle;
  TTStyle*  _currentDotStyle;

  BOOL      _hidesForSinglePage;
}

@property (nonatomic)       NSInteger numberOfPages;
@property (nonatomic)       NSInteger currentPage;
@property (nonatomic, copy) NSString* dotStyle;

/**
 * Set to YES to hide the pagecontrol if only one page is present
 *
 * @default NO
 */
@property (nonatomic)       BOOL      hidesForSinglePage;

@end
