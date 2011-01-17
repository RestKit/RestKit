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
#import "Three20UI/TTPopupViewController.h"
#import "Three20UI/TTTextEditorDelegate.h"

@protocol TTTextBarDelegate;
@class TTButton;
@class TTView;

@interface TTTextBarController : TTPopupViewController <TTTextEditorDelegate> {
@protected
  id                _result;
  NSString*         _defaultText;
  TTView*           _textBar;
  TTTextEditor*     _textEditor;
  TTButton*         _postButton;
  UIView*           _footerBar;
  CGFloat           _originTop;
  UIBarButtonItem*  _previousRightBarButtonItem;

  id <TTTextBarDelegate> _delegate;
}

@property (nonatomic, readonly) TTTextEditor* textEditor;
@property (nonatomic, readonly) TTButton*     postButton;
@property (nonatomic, retain)   UIView*       footerBar;

@property (nonatomic, assign)   id <TTTextBarDelegate> delegate;

/**
 * Posts the text to delegates, who have to actually do something with it.
 */
- (void)post;

/**
 * Cancels the controller, but confirms with the user if they have entered text.
 */
- (void)cancel;

/**
 * Dismisses the controller with a resulting that is sent to the delegate.
 */
- (void)dismissWithResult:(id)result animated:(BOOL)animated;

/**
 * Notifies the user of an error and resets the editor to normal.
 */
- (void)failWithError:(NSError*)error;

/**
 * The users has entered text and posted it.
 *
 * Subclasses can implement this to handle the text before it is sent to the delegate. The
 * default returns NO.
 *
 * @return YES if the controller should be dismissed immediately.
 */
- (BOOL)willPostText:(NSString*)text;

- (NSString*)titleForActivity;

- (NSString*)titleForError:(NSError*)error;


@end
