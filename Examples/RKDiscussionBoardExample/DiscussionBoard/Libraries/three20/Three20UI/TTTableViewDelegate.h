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

@class TTTableViewController;

/**
 * A default table view delegate implementation.
 *
 * This implementation takes care of measuring rows for you, opening URLs when the user
 * selects a cell, and suspending image loading to increase performance while the user is
 * scrolling the table.  TTTableViewController automatically assigns an instance of this
 * delegate class to your table, but you can override the createDelegate method there to provide
 * a delegate implementation of your own.
 *
 * If you would like to change the background color of the section headers, specify the
 * tableHeaderTintColor property in your global style sheet.
 *
 * This is also where the table view menu is hidden if the user starts scrolling.
 *
 * TODO(jverkoey 04/13/2010): Rename this object because it's not a protocol, and therefor
 * shouldn't be affixed the "Delegate" title.
 */
@interface TTTableViewDelegate : NSObject <UITableViewDelegate> {
  TTTableViewController*  _controller;
  NSMutableDictionary*    _headers;
}

- (id)initWithController:(TTTableViewController*)controller;

@property (nonatomic, readonly) TTTableViewController* controller;

@end
