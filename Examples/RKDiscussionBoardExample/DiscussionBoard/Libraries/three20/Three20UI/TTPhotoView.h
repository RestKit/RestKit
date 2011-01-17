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

// UI
#import "Three20UI/TTImageView.h"
#import "Three20UI/TTPhotoVersion.h"
#import "Three20UI/TTImageViewDelegate.h"

@protocol TTPhoto;
@class TTLabel;

@interface TTPhotoView : TTImageView <TTImageViewDelegate> {
  id <TTPhoto>              _photo;
  UIActivityIndicatorView*  _statusSpinner;

  TTLabel* _statusLabel;
  TTLabel* _captionLabel;
  TTStyle* _captionStyle;

  TTPhotoVersion _photoVersion;

  BOOL _hidesExtras;
  BOOL _hidesCaption;
}

@property (nonatomic, retain) id<TTPhoto> photo;
@property (nonatomic, retain) TTStyle*    captionStyle;
@property (nonatomic)         BOOL        hidesExtras;
@property (nonatomic)         BOOL        hidesCaption;

- (BOOL)loadPreview:(BOOL)fromNetwork;
- (void)loadImage;

- (void)showProgress:(CGFloat)progress;
- (void)showStatus:(NSString*)text;

@end
