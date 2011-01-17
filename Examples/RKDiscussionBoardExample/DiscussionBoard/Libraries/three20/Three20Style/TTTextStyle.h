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
#import "Three20Style/TTStyle.h"

@interface TTTextStyle : TTStyle {
  UIFont*   _font;
  UIColor*  _color;

  UIColor*  _shadowColor;
  CGSize    _shadowOffset;

  CGFloat   _minimumFontSize;
  NSInteger _numberOfLines;

  UITextAlignment                   _textAlignment;
  UIControlContentVerticalAlignment _verticalAlignment;

  UILineBreakMode _lineBreakMode;
}

@property (nonatomic, retain) UIFont*   font;
@property (nonatomic, retain) UIColor*  color;

@property (nonatomic, retain) UIColor*  shadowColor;
@property (nonatomic)         CGSize    shadowOffset;

@property (nonatomic)         CGFloat   minimumFontSize;
@property (nonatomic)         NSInteger numberOfLines;

@property (nonatomic)         UITextAlignment                   textAlignment;
@property (nonatomic)         UIControlContentVerticalAlignment verticalAlignment;

@property (nonatomic)         UILineBreakMode lineBreakMode;

+ (TTTextStyle*)styleWithFont:(UIFont*)font next:(TTStyle*)next;
+ (TTTextStyle*)styleWithColor:(UIColor*)color next:(TTStyle*)next;
+ (TTTextStyle*)styleWithFont:(UIFont*)font color:(UIColor*)color next:(TTStyle*)next;
+ (TTTextStyle*)styleWithFont:(UIFont*)font color:(UIColor*)color
                textAlignment:(UITextAlignment)textAlignment next:(TTStyle*)next;
+ (TTTextStyle*)styleWithFont:(UIFont*)font color:(UIColor*)color
                  shadowColor:(UIColor*)shadowColor shadowOffset:(CGSize)shadowOffset
                         next:(TTStyle*)next;
+ (TTTextStyle*)styleWithFont:(UIFont*)font color:(UIColor*)color
              minimumFontSize:(CGFloat)minimumFontSize
                  shadowColor:(UIColor*)shadowColor shadowOffset:(CGSize)shadowOffset
                         next:(TTStyle*)next;
+ (TTTextStyle*)styleWithFont:(UIFont*)font color:(UIColor*)color
              minimumFontSize:(CGFloat)minimumFontSize
                  shadowColor:(UIColor*)shadowColor shadowOffset:(CGSize)shadowOffset
                textAlignment:(UITextAlignment)textAlignment
            verticalAlignment:(UIControlContentVerticalAlignment)verticalAlignment
                lineBreakMode:(UILineBreakMode)lineBreakMode numberOfLines:(NSInteger)numberOfLines
                         next:(TTStyle*)next;

@end
