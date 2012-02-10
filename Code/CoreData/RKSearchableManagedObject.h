//
//  RKSearchableManagedObject.h
//  RestKit
//
//  Created by Jeff Arena on 3/31/11.
//  Copyright 2009 RestKit
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "NSManagedObject+ActiveRecord.h"
#import "RKManagedObjectSearchEngine.h"

@class RKSearchWord;

@interface RKSearchableManagedObject : NSManagedObject {
}

@property (nonatomic, retain) NSSet* searchWords;

// NOTE: Can only be attributes, not keyPaths
+ (NSArray*)searchableAttributes;

+ (NSPredicate*)predicateForSearchWithText:(NSString*)searchText searchMode:(RKSearchMode)mode;

- (void)refreshSearchWords;

@end


@interface RKSearchableManagedObject (SearchWordsAccessors)

- (void)addSearchWordsObject:(RKSearchWord*)searchWord;
- (void)removeSearchWordsObject:(RKSearchWord*)searchWord;
- (void)addSearchWords:(NSSet*)searchWords;
- (void)removeSearchWords:(NSSet*)searchWords;

@end
