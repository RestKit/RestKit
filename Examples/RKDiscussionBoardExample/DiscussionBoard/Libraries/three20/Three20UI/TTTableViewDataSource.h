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
#import "Three20Network/TTModel.h"

@protocol TTTableViewDataSource <UITableViewDataSource, TTModel, UISearchDisplayDelegate>

/**
 * Optional method to return a model object to delegate the TTModel protocol to.
 */
@property (nonatomic, retain) id<TTModel> model;

+ (NSArray*)lettersForSectionsWithSearch:(BOOL)search summary:(BOOL)summary;

- (id)tableView:(UITableView*)tableView objectForRowAtIndexPath:(NSIndexPath*)indexPath;

- (Class)tableView:(UITableView*)tableView cellClassForObject:(id)object;

- (NSString*)tableView:(UITableView*)tableView labelForObject:(id)object;

- (NSIndexPath*)tableView:(UITableView*)tableView indexPathForObject:(id)object;

- (void)tableView:(UITableView*)tableView cell:(UITableViewCell*)cell
        willAppearAtIndexPath:(NSIndexPath*)indexPath;

/**
 * Informs the data source that its model loaded.
 *
 * That would be a good time to prepare the freshly loaded data for use in the table view.
 */
- (void)tableViewDidLoadModel:(UITableView*)tableView;

- (NSString*)titleForLoading:(BOOL)reloading;

- (UIImage*)imageForEmpty;

- (NSString*)titleForEmpty;

- (NSString*)subtitleForEmpty;

- (UIImage*)imageForError:(NSError*)error;

- (NSString*)titleForError:(NSError*)error;

- (NSString*)subtitleForError:(NSError*)error;

@optional

- (NSIndexPath*)tableView:(UITableView*)tableView willUpdateObject:(id)object
                atIndexPath:(NSIndexPath*)indexPath;

- (NSIndexPath*)tableView:(UITableView*)tableView willInsertObject:(id)object
                atIndexPath:(NSIndexPath*)indexPath;

- (NSIndexPath*)tableView:(UITableView*)tableView willRemoveObject:(id)object
                atIndexPath:(NSIndexPath*)indexPath;

- (void)search:(NSString*)text;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////

@interface TTTableViewDataSource : NSObject <TTTableViewDataSource> {
  id<TTModel> _model;
}

@end

///////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * A datasource that is eternally loading.  Useful when you are in between data sources and
 * want to show the impression of loading until your actual data source is available.
 */
@interface TTTableViewInterstitialDataSource : TTTableViewDataSource <TTModel>
@end
