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
#import "Three20UI/TTViewController.h"

// Network
#import "Three20Network/TTModelDelegate.h"

@protocol TTModel;

/**
 * A view controller that manages a model in addition to a view.
 */
@interface TTModelViewController : TTViewController <TTModelDelegate> {
  id<TTModel> _model;
  NSError*    _modelError;

  struct {
    unsigned int isModelDidRefreshInvalid:1;
    unsigned int isModelWillLoadInvalid:1;
    unsigned int isModelDidLoadInvalid:1;
    unsigned int isModelDidLoadFirstTimeInvalid:1;
    unsigned int isModelDidShowFirstTimeInvalid:1;
    unsigned int isViewInvalid:1;
    unsigned int isViewSuspended:1;
    unsigned int isUpdatingView:1;
    unsigned int isShowingEmpty:1;
    unsigned int isShowingLoading:1;
    unsigned int isShowingModel:1;
    unsigned int isShowingError:1;
  } _flags;
}

@property (nonatomic, retain) id<TTModel> model;

/**
 * An error that occurred while trying to load content.
 */
@property (nonatomic, retain) NSError* modelError;

/**
 * Creates the model that the controller manages.
 */
- (void)createModel;

/**
 * Releases the current model and forces the creation of a new model.
 */
- (void)invalidateModel;

/**
 * Indicates whether the model has been created.
 */
- (BOOL)isModelCreated;

/**
 * Indicates that data should be loaded from the model.
 *
 * Do not call this directly.  Subclasses should implement this method.
 */
- (BOOL)shouldLoad;

/**
 * Indicates that data should be reloaded from the model.
 *
 * Do not call this directly.  Subclasses should implement this method.
 */
- (BOOL)shouldReload;

/**
 * Indicates that more data should be loaded from the model.
 *
 * Do not call this directly.  Subclasses should implement this method.
 */
- (BOOL)shouldLoadMore;

/**
 * Tests if it is possible to show the model.
 *
 * After a model has loaded, this method is called to test whether or not to set the model
 * has content that can be shown.  If you return NO, showEmpty: will be called, and if you
 * return YES, showModel: will be called.
 */
- (BOOL)canShowModel;

/**
 * Reloads data from the model.
 */
- (void)reload;

/**
 * Reloads data from the model if it has become out of date.
 */
- (void)reloadIfNeeded;

/**
 * Refreshes the model state and loads new data if necessary.
 */
- (void)refresh;

/**
 * Begins a multi-stage update.
 *
 * You can call this method to make complicated updates more efficient, and to condense
 * multiple changes to your model into a single visual change.  Call endUpdate when you are done
 * to update the view with all of your changes.
 */
- (void)beginUpdates;

/**
 * Ends a multi-stage model update and updates the view to reflect the model.
 *
 * You can call this method to make complicated updates more efficient, and to condense
 * multiple changes to your model into a single visual change.
 */
- (void)endUpdates;

/**
 * Indicates that the model has changed and schedules the view to be updated to reflect it.
 */
- (void)invalidateView;

/**
 * Immediately creates, loads, and displays the model (if it was not already).
 */
- (void)updateView;

/**
 * Called when the model is refreshed.
 *
 * Subclasses should override this function update parts of the view that may need to changed
 * when there is a new model, or something about the existing model changes.
 */
- (void)didRefreshModel;

/**
 * Called before the model is asked to load itself.
 *
 * This is not called until after the view has loaded.  If your model starts loading before
 * the view is loaded, this will still be called, but not until after the view is loaded.
 *
 * The default implementation of this method does nothing. Subclasses may override this method
 * to take an appropriate action.
 */
- (void)willLoadModel;

/**
 * Called after the model has loaded, just before it is to be displayed.
 *
 * This is not called until after the view has loaded.  If your model finishes loading before
 * the view is loaded, this will still be called, but not until after the view is loaded.
 *
 * If you refresh a model which is already loaded, this will be called, but the firstTime
 * argument will be false.
 *
 * The default implementation of this method does nothing. Subclasses may override this method
 * to take an appropriate action.
 */
- (void)didLoadModel:(BOOL)firstTime;

/**
 * Called just after a model has been loaded and displayed.
 *
 * The default implementation of this method does nothing. Subclasses may override this method
 * to take an appropriate action.
 */
- (void)didShowModel:(BOOL)firstTime;

/**
 * Shows views to represent the loaded model's content.
 *
 * The default implementation of this method does nothing. Subclasses may override this method
 * to take an appropriate action.
 */
- (void)showModel:(BOOL)show;

/**
 * Shows views to represent the model loading.
 *
 * The default implementation of this method does nothing. Subclasses may override this method
 * to take an appropriate action.
 */
- (void)showLoading:(BOOL)show;

/**
 * Shows views to represent an empty model.
 *
 * The default implementation of this method does nothing. Subclasses may override this method
 * to take an appropriate action.
 */
- (void)showEmpty:(BOOL)show;

/**
 * Shows views to represent an error that occurred while loading the model.
 */
- (void)showError:(BOOL)show;

@end
