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

@interface TTSectionedDataSource : TTTableViewDataSource {
  NSMutableArray* _sections;
  NSMutableArray* _items;
}

@property (nonatomic, retain) NSMutableArray* items;
@property (nonatomic, retain) NSMutableArray* sections;

/**
 * Objects should be in this format:
 *
 *   @"section title", item, item, @"section title", item, item, ...
 *
 * Where item is generally a type of TTTableItem.
 */
+ (TTSectionedDataSource*)dataSourceWithObjects:(id)object,...;

/**
 * Objects should be in this format:
 *
 *   @"section title", arrayOfItems, @"section title", arrayOfItems, ...
 *
 * Where arrayOfItems is generally an array of items of type TTTableItem.
 */
+ (TTSectionedDataSource*)dataSourceWithArrays:(id)object,...;

/**
 *  @param items
 *
 *    An array of arrays, where each array is the contents of a
 *    section, to be listed under the section title held in the
 *    corresponding index of the `section` array.
 *
 *  @param sections
 *
 *    An array of strings, where each string is the title
 *    of a section.
 *
 *  The items and sections arrays should be of equal length.
 */
+ (TTSectionedDataSource*)dataSourceWithItems:(NSArray*)items sections:(NSArray*)sections;

- (id)initWithItems:(NSArray*)items sections:(NSArray*)sections;

- (NSIndexPath*)indexPathOfItemWithUserInfo:(id)userInfo;

- (void)removeItemAtIndexPath:(NSIndexPath*)indexPath;
- (BOOL)removeItemAtIndexPath:(NSIndexPath*)indexPath andSectionIfEmpty:(BOOL)andSection;

@end
