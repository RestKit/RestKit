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

@protocol TTWebControllerDelegate;

@interface TTWebController : TTModelViewController <UIWebViewDelegate, UIActionSheetDelegate> {
@protected
  UIWebView*        _webView;

  UIToolbar*        _toolbar;

  UIView*           _headerView;

  UIBarButtonItem*  _backButton;
  UIBarButtonItem*  _forwardButton;
  UIBarButtonItem*  _refreshButton;
  UIBarButtonItem*  _stopButton;
  UIBarButtonItem*  _actionButton;
  UIBarButtonItem*  _activityItem;

  NSURL*            _loadingURL;
  
  UIActionSheet*    _actionSheet;

  id<TTWebControllerDelegate> _delegate;
}

/**
 * The current web view URL. If the web view is currently loading a URL, then the loading URL is
 * returned instead.
 */
@property (nonatomic, readonly) NSURL*  URL;

/**
 * A view that is inserted at the top of the web view, within the scroller.
 */
@property (nonatomic, retain)   UIView* headerView;

/**
 * The web controller delegate, currently does nothing.
 */
@property (nonatomic, assign)   id<TTWebControllerDelegate> delegate;

/**
 * Navigate to the given URL.
 */
- (void)openURL:(NSURL*)URL;

/**
 * Load the given request using UIWebView's loadRequest:.
 *
 * @param request  A URL request identifying the location of the content to load.
 */
- (void)openRequest:(NSURLRequest*)request;

@end


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@protocol TTWebControllerDelegate <NSObject>
// XXXjoe Need to make this similar to UIWebViewDelegate
@end
