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

@protocol TTTableViewDataSource;
@class TTTableViewController;

extern const int kTTSearchBarBackgroundTag;

/**
 * Shows search results using a TTTableViewController.
 *
 * This extends the standard search display controller so that you can search a Three20 model.
 * Searches that hit the internet and return asynchronously can provide feedback to the
 * about the status of the remote search using TTModel's loading interface, and
 * TTTableViewController's status views.
 */
@interface TTSearchDisplayController : UISearchDisplayController <UISearchDisplayDelegate> {
  TTTableViewController*  _searchResultsViewController;
  NSTimer*                _pauseTimer;
  BOOL                    _pausesBeforeSearching;

  id<UITableViewDelegate> _searchResultsDelegate2;
}

@property (nonatomic, retain) TTTableViewController* searchResultsViewController;
@property (nonatomic)         BOOL                   pausesBeforeSearching;

@end
