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
#import "Three20Style/TTStyledElement.h"

@interface TTStyledImageNode : TTStyledElement {
  NSString* _URL;
  UIImage*  _image;
  UIImage*  _defaultImage;
  CGFloat   _width;
  CGFloat   _height;
}

@property (nonatomic, retain) NSString* URL;
@property (nonatomic, retain) UIImage*  image;
@property (nonatomic, retain) UIImage*  defaultImage;
@property (nonatomic)         CGFloat   width;
@property (nonatomic)         CGFloat   height;

- (id)initWithURL:(NSString*)URL;

@end
