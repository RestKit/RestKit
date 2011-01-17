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

#import <UIKit/UIKit.h>

// Network
#import "Three20Network/TTURLRequestDelegate.h"

@class TTButton;
@class TTStyle;

@protocol TTImageViewDelegate;

@interface TTButtonContent : NSObject <TTURLRequestDelegate> {
  TTButton*     _button;
  NSString*     _title;
  NSString*     _imageURL;
  UIImage*      _image;
  TTStyle*      _style;
  TTURLRequest* _request;

  id<TTImageViewDelegate> _delegate;
}

@property (nonatomic, copy)   NSString* title;
@property (nonatomic, copy)   NSString* imageURL;
@property (nonatomic, retain) UIImage*  image;
@property (nonatomic, retain) TTStyle*  style;
@property (nonatomic, assign) id<TTImageViewDelegate> delegate;

- (id)initWithButton:(TTButton*)button;

- (void)reload;
- (void)stopLoading;

@end
