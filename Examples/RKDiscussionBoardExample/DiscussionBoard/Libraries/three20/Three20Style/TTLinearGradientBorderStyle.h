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

@interface TTLinearGradientBorderStyle : TTStyle {
  UIColor*  _color1;
  UIColor*  _color2;
  CGFloat   _location1;
  CGFloat   _location2;
  CGFloat   _width;
}

@property (nonatomic, retain) UIColor*  color1;
@property (nonatomic, retain) UIColor*  color2;
@property (nonatomic)         CGFloat   location1;
@property (nonatomic)         CGFloat   location2;
@property (nonatomic)         CGFloat   width;

+ (TTLinearGradientBorderStyle*)styleWithColor1:(UIColor*)color1 color2:(UIColor*)color2
                                          width:(CGFloat)width next:(TTStyle*)next;
+ (TTLinearGradientBorderStyle*)styleWithColor1:(UIColor*)color1 location1:(CGFloat)location1
                                         color2:(UIColor*)color2 location2:(CGFloat)location2
                                          width:(CGFloat)width next:(TTStyle*)next;

@end
