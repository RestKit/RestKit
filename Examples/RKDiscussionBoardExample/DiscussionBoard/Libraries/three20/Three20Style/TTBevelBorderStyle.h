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

@interface TTBevelBorderStyle : TTStyle {
  UIColor*  _highlight;
  UIColor*  _shadow;
  CGFloat   _width;
  NSInteger _lightSource;
}

@property (nonatomic, retain) UIColor*  highlight;
@property (nonatomic, retain) UIColor*  shadow;
@property (nonatomic)         CGFloat   width;
@property (nonatomic)         NSInteger lightSource;

+ (TTBevelBorderStyle*)styleWithColor:(UIColor*)color width:(CGFloat)width next:(TTStyle*)next;

+ (TTBevelBorderStyle*)styleWithHighlight:(UIColor*)highlight shadow:(UIColor*)shadow
                                    width:(CGFloat)width lightSource:(NSInteger)lightSource next:(TTStyle*)next;

@end
