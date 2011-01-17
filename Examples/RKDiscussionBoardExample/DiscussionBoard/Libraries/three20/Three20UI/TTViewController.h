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

#import "Three20UINavigator/TTNavigatorViewController.h"

@class TTTableViewController;
@class TTSearchDisplayController;

/**
 * A view controller with some useful additions.
 */
@interface TTViewController : TTNavigatorViewController {
@protected
  TTSearchDisplayController* _searchController;
}

/**
 * A view controller used to display the contents of the search display controller.
 *
 * If you assign a view controller to this property, it will automatically create a search
 * display controller which you can access through this view controller's searchDisplaController
 * property.  You can then take the searchBar from that controller and add it to your views. The
 * search bar will then search the data source of the view controller that you assigned here.
 */
@property (nonatomic, retain) TTTableViewController* searchViewController;

/**
 * Forcefully initiates garbage collection. You may call this in your didReceiveMemoryWarning
 * message if you are worried about garbage collection memory consumption.
 *
 * See Articles/UI/GarbageCollection.mdown for a more detailed discussion.
 */
+ (void)doGarbageCollection;

@end
