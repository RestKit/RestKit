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
#import "Three20UI/TTView.h"

@protocol TTTableViewDataSource;
@protocol TTSearchTextFieldDelegate;

@class TTSearchTextField;
@class TTButton;

@interface TTSearchBar : TTView {
  TTSearchTextField*  _searchField;
  TTView*             _boxView;
  TTButton*           _cancelButton;

  UIColor*            _tintColor;
  TTStyle*            _textFieldStyle;

  BOOL _showsCancelButton;
  BOOL _showsSearchIcon;
}

@property (nonatomic, copy)     NSString*       text;
@property (nonatomic, copy)     NSString*       placeholder;
@property (nonatomic, readonly) UITableView*    tableView;
@property (nonatomic, readonly) TTView*         boxView;
@property (nonatomic, retain)   UIColor*        tintColor;
@property (nonatomic, retain)   UIColor*        textColor;
@property (nonatomic, retain)   UIFont*         font;
@property (nonatomic, retain)   TTStyle*        textFieldStyle;
@property (nonatomic)           UIReturnKeyType returnKeyType;
@property (nonatomic)           CGFloat         rowHeight;
@property (nonatomic, readonly) BOOL            editing;

@property (nonatomic)           BOOL searchesAutomatically;
@property (nonatomic)           BOOL showsCancelButton;
@property (nonatomic)           BOOL showsDoneButton;
@property (nonatomic)           BOOL showsDarkScreen;
@property (nonatomic)           BOOL showsSearchIcon;

@property (nonatomic, retain)   id<TTTableViewDataSource> dataSource;
@property (nonatomic, assign)   id<UITextFieldDelegate> delegate;

- (void)search;

- (void)showSearchResults:(BOOL)show;

@end
