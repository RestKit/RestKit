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
#import "Three20Style/TTShape.h"

@interface TTRoundedRectangleShape : TTShape {
  CGFloat _topLeftRadius;
  CGFloat _topRightRadius;
  CGFloat _bottomRightRadius;
  CGFloat _bottomLeftRadius;
}

@property (nonatomic) CGFloat topLeftRadius;
@property (nonatomic) CGFloat topRightRadius;
@property (nonatomic) CGFloat bottomRightRadius;
@property (nonatomic) CGFloat bottomLeftRadius;

+ (TTRoundedRectangleShape*)shapeWithRadius:(CGFloat)radius;

+ (TTRoundedRectangleShape*)shapeWithTopLeft:(CGFloat)topLeft topRight:(CGFloat)topRight
                                 bottomRight:(CGFloat)bottomRight bottomLeft:(CGFloat)bottomLeft;

@end
