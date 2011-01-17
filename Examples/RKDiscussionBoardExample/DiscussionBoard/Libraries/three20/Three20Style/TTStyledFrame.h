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

@class TTStyledElement;
@class TTStyledFrame;
@class TTStyledBoxFrame;

@interface TTStyledFrame : NSObject {
  TTStyledElement*  _element;
  TTStyledFrame*    _nextFrame;
  CGRect            _bounds;
}

/**
 * The element that contains the frame.
 */
@property (nonatomic, readonly) TTStyledElement* element;

/**
 * The next in the linked list of frames.
 */
@property (nonatomic, retain) TTStyledFrame* nextFrame;

/**
 * The bounds of the content that is displayed by this frame.
 */
@property (nonatomic) CGRect bounds;

@property (nonatomic) CGFloat x;
@property (nonatomic) CGFloat y;
@property (nonatomic) CGFloat width;
@property (nonatomic) CGFloat height;

- (UIFont*)font;

- (id)initWithElement:(TTStyledElement*)element;

/**
 * Draws the frame.
 */
- (void)drawInRect:(CGRect)rect;

- (TTStyledBoxFrame*)hitTest:(CGPoint)point;

@end
