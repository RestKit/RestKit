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

@protocol TTScrollViewDelegate <NSObject>

@required

- (void)scrollView:(TTScrollView*)scrollView didMoveToPageAtIndex:(NSInteger)pageIndex;

@optional

- (void)scrollViewWillRotate: (TTScrollView*)scrollView
               toOrientation: (UIInterfaceOrientation)orientation;

- (void)scrollViewDidRotate:(TTScrollView*)scrollView;

- (void)scrollViewWillBeginDragging:(TTScrollView*)scrollView;

- (void)scrollViewDidEndDragging:(TTScrollView*)scrollView willDecelerate:(BOOL)willDecelerate;

- (void)scrollViewWillBeginDecelerating:(TTScrollView*)scrollView;

- (void)scrollViewDidEndDecelerating:(TTScrollView*)scrollView;

- (BOOL)scrollViewShouldZoom:(TTScrollView*)scrollView;

- (void)scrollViewDidBeginZooming:(TTScrollView*)scrollView;

- (void)scrollViewDidEndZooming:(TTScrollView*)scrollView;

- (void)scrollView:(TTScrollView*)scrollView touchedDown:(UITouch*)touch;

- (void)scrollView:(TTScrollView*)scrollView touchedUpInside:(UITouch*)touch;

- (void)scrollView:(TTScrollView*)scrollView tapped:(UITouch*)touch;

- (void)scrollViewDidBeginHolding:(TTScrollView*)scrollView;

- (void)scrollViewDidEndHolding:(TTScrollView*)scrollView;

- (BOOL)scrollView:(TTScrollView*)scrollView
  shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation;

@end
