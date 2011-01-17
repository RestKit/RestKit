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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum {
  TTActivityLabelStyleWhite,
  TTActivityLabelStyleGray,
  TTActivityLabelStyleBlackBox,
  TTActivityLabelStyleBlackBezel,
  TTActivityLabelStyleBlackBanner,
  TTActivityLabelStyleWhiteBezel,
  TTActivityLabelStyleWhiteBox
} TTActivityLabelStyle;

@class TTView;
@class TTButton;

@interface TTActivityLabel : UIView {
  TTActivityLabelStyle      _style;

  TTView*                   _bezelView;
  UIProgressView*           _progressView;
  UIActivityIndicatorView*  _activityIndicator;
  UILabel*                  _label;

  float                     _progress;
  BOOL                      _smoothesProgress;
  NSTimer*                  _smoothTimer;
}

@property (nonatomic, readonly) TTActivityLabelStyle style;

@property (nonatomic, assign)   NSString* text;
@property (nonatomic, assign)   UIFont*   font;

@property (nonatomic)           float     progress;
@property (nonatomic)           BOOL      isAnimating;
@property (nonatomic)           BOOL      smoothesProgress;

- (id)initWithFrame:(CGRect)frame style:(TTActivityLabelStyle)style;
- (id)initWithFrame:(CGRect)frame style:(TTActivityLabelStyle)style text:(NSString*)text;
- (id)initWithStyle:(TTActivityLabelStyle)style;

@end
