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
#import "Three20UI/TTModelViewController.h"
#import "Three20UI/TTScrollViewDelegate.h"
#import "Three20UI/TTScrollViewDataSource.h"
#import "Three20UI/TTThumbsViewControllerDelegate.h"

@protocol TTPhotoSource;
@class TTScrollView;
@class TTPhotoView;
@class TTStyle;

@interface TTPhotoViewController : TTModelViewController <
  TTScrollViewDelegate,
  TTScrollViewDataSource,
  TTThumbsViewControllerDelegate
> {
  id<TTPhoto>       _centerPhoto;
  NSInteger         _centerPhotoIndex;

  UIView*           _innerView;
  TTScrollView*     _scrollView;
  TTPhotoView*      _photoStatusView;

  UIToolbar*        _toolbar;
  UIBarButtonItem*  _nextButton;
  UIBarButtonItem*  _previousButton;

  TTStyle*          _captionStyle;

  UIImage*          _defaultImage;

  NSString*         _statusText;

  NSTimer*          _slideshowTimer;
  NSTimer*          _loadTimer;

  BOOL              _delayLoad;

  TTThumbsViewController* _thumbsController;

  id<TTPhotoSource> _photoSource;
}

/**
 * The source of a sequential photo collection that will be displayed.
 */
@property (nonatomic, retain) id<TTPhotoSource> photoSource;

/**
 * The photo that is currently visible and centered.
 *
 * You can assign this directly to change the photoSource to the one that contains the photo.
 */
@property (nonatomic, retain) id<TTPhoto> centerPhoto;

/**
 * The index of the currently visible photo.
 *
 * Because centerPhoto can be nil while waiting for the source to load the photo, this property
 * must be maintained even though centerPhoto has its own index property.
 */
@property (nonatomic, readonly) NSInteger centerPhotoIndex;

/**
 * The default image to show before a photo has been loaded.
 */
@property (nonatomic, retain) UIImage* defaultImage;

/**
 * The style to use for the caption label.
 */
@property (nonatomic, retain) TTStyle* captionStyle;

- (id)initWithPhoto:(id<TTPhoto>)photo;
- (id)initWithPhotoSource:(id<TTPhotoSource>)photoSource;

/**
 * Creates a photo view for a new page.
 *
 * Do not call this directly. It is meant to be overriden by subclasses.
 */
- (TTPhotoView*)createPhotoView;

/**
 * Creates the thumbnail controller used by the "See All" button.
 *
 * Do not call this directly. It is meant to be overriden by subclasses.
 */
- (TTThumbsViewController*)createThumbsViewController;

/**
 * Sent to the controller after it moves from one photo to another.
 */
- (void)didMoveToPhoto:(id<TTPhoto>)photo fromPhoto:(id<TTPhoto>)fromPhoto;

/**
 * Shows or hides an activity label on top of the photo.
 */
- (void)showActivity:(NSString*)title;

@end
