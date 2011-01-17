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

#import <UIKit/UIKit.h>

// Network
#import "Three20Network/TTURLRequestDelegate.h"

@protocol TTStyledTextDelegate;
@class TTStyledNode;
@class TTStyledFrame;
@class TTStyledBoxFrame;

@interface TTStyledText : NSObject <TTURLRequestDelegate> {
  TTStyledNode*   _rootNode;
  TTStyledFrame*  _rootFrame;
  UIFont*         _font;
  CGFloat         _width;
  CGFloat         _height;
  NSMutableArray* _invalidImages;
  NSMutableArray* _imageRequests;

  id<TTStyledTextDelegate> _delegate;
}

@property (nonatomic, assign) id<TTStyledTextDelegate> delegate;

/**
 * The first in the sequence of nodes that contain the styled text.
 */
@property (nonatomic, retain) TTStyledNode* rootNode;

/**
 * The first in the sequence of frames of text calculated by the layout.
 */
@property (nonatomic, readonly) TTStyledFrame* rootFrame;

/**
 * The font that will be used to measure and draw all text.
 */
@property (nonatomic, retain) UIFont* font;

/**
 * The width that the text should be constrained to fit within.
 */
@property (nonatomic) CGFloat width;

/**
 * The height of the text.
 *
 * The height is automatically calculated based on the width and the size of word-wrapped text.
 */
@property (nonatomic, readonly) CGFloat height;

/**
 * Indicates if the text needs layout to recalculate its size.
 */
@property (nonatomic, readonly) BOOL needsLayout;

/**
 * Images that require loading
 */
@property (nonatomic, readonly) NSMutableArray* invalidImages;

/**
 * Constructs styled text with XHTML tags turned into style nodes.
 *
 * Only the following XHTML tags are supported: b, i, img, a.  The source must
 * be a well-formed XHTML fragment.  You do not need to enclose the source in an tag --
 * it can be any string with XHTML tags throughout.
 */
+ (TTStyledText*)textFromXHTML:(NSString*)source;
+ (TTStyledText*)textFromXHTML:(NSString*)source lineBreaks:(BOOL)lineBreaks URLs:(BOOL)URLs;

/**
 * Constructs styled text with all URLs transformed into links.
 *
 * Only URLs are parsed, not HTML markup. URLs are turned into links.
 */
+ (TTStyledText*)textWithURLs:(NSString*)source;
+ (TTStyledText*)textWithURLs:(NSString*)source lineBreaks:(BOOL)lineBreaks;

- (id)initWithNode:(TTStyledNode*)rootNode;

- (void)layoutFrames;

- (void)layoutIfNeeded;

/**
 * Called to indicate that the layout needs to be re-calculated.
 */
- (void)setNeedsLayout;

/**
 * Draws the text at a point.
 */
- (void)drawAtPoint:(CGPoint)point;

/**
 * Draws the text at a point with optional highlighting.
 *
 * If highlighted is YES, text colors will be ignored and all text will be drawn in the same color.
 */
- (void)drawAtPoint:(CGPoint)point highlighted:(BOOL)highlighted;

/**
 * Determines which frame is intersected by a point.
 */
- (TTStyledBoxFrame*)hitTest:(CGPoint)point;

/**
 * Finds the frame that represents the node.
 *
 * If multiple frames represent a node, such as an inline frame with line breaks, the
 * first frame in the sequence will be returned.
 */
- (TTStyledFrame*)getFrameForNode:(TTStyledNode*)node;

- (void)addChild:(TTStyledNode*)child;

- (void)addText:(NSString*)text;

- (void)insertChild:(TTStyledNode*)child atIndex:(NSInteger)index;

- (TTStyledNode*)getElementByClassName:(NSString*)className;

@end
