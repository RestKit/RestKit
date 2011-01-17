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
#import "Three20UI/TTTableViewDataSource.h"

@protocol TTPhotoSource;
@protocol TTThumbsTableViewCellDelegate;

@interface TTThumbsDataSource : TTTableViewDataSource {
  id<TTPhotoSource>                 _photoSource;
  id<TTThumbsTableViewCellDelegate> _delegate;
}

@property (nonatomic, retain) id<TTPhotoSource>                 photoSource;
@property (nonatomic, assign) id<TTThumbsTableViewCellDelegate> delegate;

- (id)initWithPhotoSource: (id<TTPhotoSource>)photoSource
                 delegate: (id<TTThumbsTableViewCellDelegate>)delegate;

@end
