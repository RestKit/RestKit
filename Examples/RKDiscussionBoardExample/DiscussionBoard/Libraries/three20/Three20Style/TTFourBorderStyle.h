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

@interface TTFourBorderStyle : TTStyle {
  UIColor*  _top;
  UIColor*  _right;
  UIColor*  _bottom;
  UIColor*  _left;
  CGFloat   _width;
}

@property (nonatomic, retain) UIColor*  top;
@property (nonatomic, retain) UIColor*  right;
@property (nonatomic, retain) UIColor*  bottom;
@property (nonatomic, retain) UIColor*  left;
@property (nonatomic)         CGFloat   width;

+ (TTFourBorderStyle*)styleWithTop:(UIColor*)top right:(UIColor*)right bottom:(UIColor*)bottom
                              left:(UIColor*)left width:(CGFloat)width next:(TTStyle*)next;
+ (TTFourBorderStyle*)styleWithTop:(UIColor*)top width:(CGFloat)width next:(TTStyle*)next;
+ (TTFourBorderStyle*)styleWithRight:(UIColor*)right width:(CGFloat)width next:(TTStyle*)next;
+ (TTFourBorderStyle*)styleWithBottom:(UIColor*)bottom width:(CGFloat)width next:(TTStyle*)next;
+ (TTFourBorderStyle*)styleWithLeft:(UIColor*)left width:(CGFloat)width next:(TTStyle*)next;

@end
