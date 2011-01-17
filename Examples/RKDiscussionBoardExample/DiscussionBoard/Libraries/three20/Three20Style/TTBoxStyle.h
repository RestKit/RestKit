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
#import "Three20Style/TTPosition.h"

@interface TTBoxStyle : TTStyle {
  UIEdgeInsets  _margin;
  UIEdgeInsets  _padding;
  CGSize        _minSize;
  TTPosition    _position;
}

@property (nonatomic) UIEdgeInsets  margin;
@property (nonatomic) UIEdgeInsets  padding;
@property (nonatomic) CGSize        minSize;
@property (nonatomic) TTPosition    position;

+ (TTBoxStyle*)styleWithMargin:(UIEdgeInsets)margin next:(TTStyle*)next;
+ (TTBoxStyle*)styleWithPadding:(UIEdgeInsets)padding next:(TTStyle*)next;
+ (TTBoxStyle*)styleWithFloats:(TTPosition)position next:(TTStyle*)next;
+ (TTBoxStyle*)styleWithMargin:(UIEdgeInsets)margin padding:(UIEdgeInsets)padding
                          next:(TTStyle*)next;
+ (TTBoxStyle*)styleWithMargin:(UIEdgeInsets)margin padding:(UIEdgeInsets)padding
                       minSize:(CGSize)minSize position:(TTPosition)position next:(TTStyle*)next;

@end
