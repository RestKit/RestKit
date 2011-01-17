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

@class TTTabItem;
@class TTTab;
@class TTImageView;
@class TTLabel;

@protocol TTTabDelegate;

@interface TTTabBar : TTView {
  NSString*       _tabStyle;

  NSInteger       _selectedTabIndex;
  NSArray*        _tabItems;
  NSMutableArray* _tabViews;

  id<TTTabDelegate> _delegate;
}

@property (nonatomic, copy)     NSString*   tabStyle;

@property (nonatomic, assign)   TTTabItem*  selectedTabItem;
@property (nonatomic, assign)   TTTab*      selectedTabView;
@property (nonatomic)           NSInteger   selectedTabIndex;

@property (nonatomic, retain)   NSArray*    tabItems;
@property (nonatomic, readonly) NSArray*    tabViews;

@property (nonatomic, assign)   id<TTTabDelegate> delegate;

- (id)initWithFrame:(CGRect)frame;

- (void)showTabAtIndex:(NSInteger)tabIndex;
- (void)hideTabAtIndex:(NSInteger)tabIndex;

@end
