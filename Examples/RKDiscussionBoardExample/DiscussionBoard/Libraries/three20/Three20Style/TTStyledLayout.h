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
@class TTStyledNode;
@class TTStyledElement;
@class TTStyledFrame;
@class TTStyledBoxFrame;
@class TTStyledInlineFrame;

@interface TTStyledLayout : NSObject {
  CGFloat _x;
  CGFloat _width;
  CGFloat _height;
  CGFloat _lineWidth;
  CGFloat _lineHeight;
  CGFloat _minX;
  CGFloat _floatLeftWidth;
  CGFloat _floatRightWidth;
  CGFloat _floatHeight;

  TTStyledFrame*        _rootFrame;
  TTStyledFrame*        _lineFirstFrame;
  TTStyledInlineFrame*  _inlineFrame;
  TTStyledBoxFrame*     _topFrame;
  TTStyledFrame*        _lastFrame;

  UIFont* _font;
  UIFont* _boldFont;
  UIFont* _italicFont;

  TTStyle*      _linkStyle;
  TTStyledNode* _rootNode;
  TTStyledNode* _lastNode;

  NSMutableArray* _invalidImages;
}

@property (nonatomic)           CGFloat         width;
@property (nonatomic)           CGFloat         height;
@property (nonatomic, retain)   UIFont*         font;
@property (nonatomic, readonly) TTStyledFrame*  rootFrame;
@property (nonatomic, retain)   NSMutableArray* invalidImages;

- (id)initWithRootNode:(TTStyledNode*)rootNode;
- (id)initWithX:(CGFloat)x width:(CGFloat)width height:(CGFloat)height;

- (void)layout:(TTStyledNode*)node;
- (void)layout:(TTStyledNode*)node container:(TTStyledElement*)element;

@end
