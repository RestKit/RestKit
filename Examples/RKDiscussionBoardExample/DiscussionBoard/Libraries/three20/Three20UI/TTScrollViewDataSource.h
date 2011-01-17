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

@class TTScrollView;

@protocol TTScrollViewDataSource <NSObject>

- (NSInteger)numberOfPagesInScrollView:(TTScrollView*)scrollView;

/**
 * Gets a view to display for the page at the given index.
 *
 * You do not need to position or size the view as that is done for you later.  You should
 * call dequeueReusablePage first, and only create a new view if it returns nil.
 */
- (UIView*)scrollView:(TTScrollView*)scrollView pageAtIndex:(NSInteger)pageIndex;

/**
 * Gets the natural size of the page.
 *
 * The actual width and height are not as important as the ratio between width and height.
 *
 * If the size is not specified, then the size of the page is used.
 */
- (CGSize)scrollView:(TTScrollView*)scrollView sizeOfPageAtIndex:(NSInteger)pageIndex;

@end
