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
#import "Three20Style/TTStyledFrame.h"

@class TTStyledTextNode;

@interface TTStyledTextFrame : TTStyledFrame {
  TTStyledTextNode* _node;
  NSString*         _text;
  UIFont*           _font;
}

/**
 * The node represented by the frame.
 */
@property (nonatomic, readonly) TTStyledTextNode* node;

/**
 * The text that is displayed by this frame.
 */
@property (nonatomic, readonly) NSString* text;

/**
 * The font that is used to measure and display the text of this frame.
 */
@property (nonatomic, retain) UIFont* font;

- (id)initWithText:(NSString*)text element:(TTStyledElement*)element node:(TTStyledTextNode*)node;

@end
