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

// Style
#import "Three20Style/TTStyledTextDelegate.h"

@class TTStyledText;
@class TTStyledElement;
@class TTStyledBoxFrame;
@class TTStyle;

/**
 * A view that can display styled text.
 */
@interface TTStyledTextLabel : UIView <TTStyledTextDelegate> {
  TTStyledText*     _text;

  UIColor*          _textColor;
  UIColor*          _highlightedTextColor;
  UIFont*           _font;
  UITextAlignment   _textAlignment;

  UIEdgeInsets      _contentInset;

  BOOL              _highlighted;
  TTStyledElement*  _highlightedNode;
  TTStyledBoxFrame* _highlightedFrame;

  NSMutableArray*   _accessibilityElements;
}

/**
 * The styled text displayed by the label.
 */
@property (nonatomic, retain) TTStyledText* text;

/**
 * A shortcut for setting the text property to an HTML string.
 */
@property (nonatomic, copy) NSString* html;

/**
 * The font of the text.
 */
@property (nonatomic, retain) UIFont* font;

/**
 * The color of the text.
 */
@property (nonatomic, retain) UIColor* textColor;

/**
 * The highlight color applied to the text.
 */
@property (nonatomic, retain) UIColor* highlightedTextColor;

/**
 * The alignment of the text. (NOT YET IMPLEMENTED)
 */
@property (nonatomic) UITextAlignment textAlignment;

/**
 * The inset of the edges around the text.
 *
 * This will increase the size of the label when sizeToFit is called.
 */
@property (nonatomic) UIEdgeInsets contentInset;

/**
 * A Boolean value indicating whether the receiver should be drawn with a highlight.
 */
@property (nonatomic) BOOL highlighted;

/**
 * The link node which is being touched and highlighted by the user.
 */
@property (nonatomic, retain) TTStyledElement* highlightedNode;

@end
