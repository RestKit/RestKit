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

@interface TTImageStyle : TTStyle {
  NSString*         _imageURL;
  UIImage*          _image;
  UIImage*          _defaultImage;

  CGSize            _size;

  UIViewContentMode _contentMode;
}

@property (nonatomic, copy)   NSString* imageURL;
@property (nonatomic, retain) UIImage*  image;
@property (nonatomic, retain) UIImage*  defaultImage;
@property (nonatomic)         CGSize    size;

@property (nonatomic)         UIViewContentMode contentMode;

+ (TTImageStyle*)styleWithImageURL:(NSString*)imageURL next:(TTStyle*)next;
+ (TTImageStyle*)styleWithImageURL:(NSString*)imageURL defaultImage:(UIImage*)defaultImage
                              next:(TTStyle*)next;
+ (TTImageStyle*)styleWithImageURL:(NSString*)imageURL defaultImage:(UIImage*)defaultImage
                       contentMode:(UIViewContentMode)contentMode
                              size:(CGSize)size next:(TTStyle*)next;
+ (TTImageStyle*)styleWithImage:(UIImage*)image next:(TTStyle*)next;
+ (TTImageStyle*)styleWithImage:(UIImage*)image defaultImage:(UIImage*)defaultImage
                           next:(TTStyle*)next;
+ (TTImageStyle*)styleWithImage:(UIImage*)image defaultImage:(UIImage*)defaultImage
                    contentMode:(UIViewContentMode)contentMode
                           size:(CGSize)size next:(TTStyle*)next;

@end
