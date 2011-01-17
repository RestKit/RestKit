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
#import "Three20Style/TTStyleDelegate.h"

@protocol TTImageViewDelegate;

@interface TTButton : UIControl <TTStyleDelegate> {
  NSMutableDictionary*  _content;
  UIFont*               _font;
  BOOL                  _isVertical;

  id<TTImageViewDelegate> _imageDelegate;
}

@property (nonatomic, retain) UIFont* font;
@property (nonatomic)         BOOL    isVertical;

// This must be set before you call setImage:
@property (nonatomic, assign) id<TTImageViewDelegate> imageDelegate;

+ (TTButton*)buttonWithStyle:(NSString*)selector;
+ (TTButton*)buttonWithStyle:(NSString*)selector title:(NSString*)title;

- (NSString*)titleForState:(UIControlState)state;
- (void)setTitle:(NSString*)title forState:(UIControlState)state;

- (NSString*)imageForState:(UIControlState)state;
- (void)setImage:(NSString*)title forState:(UIControlState)state;

- (TTStyle*)styleForState:(UIControlState)state;
- (void)setStyle:(TTStyle*)style forState:(UIControlState)state;

/**
 * Sets the styles for all control states using a single style selector.
 *
 * The method for the selector must accept a single argument for the control state.  It will
 * be called to return a style for each of the different control states.
 */
- (void)setStylesWithSelector:(NSString*)selector;

- (void)suspendLoadingImages:(BOOL)suspended;

- (CGRect)rectForImage;

@end
