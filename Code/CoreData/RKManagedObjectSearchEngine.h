//
//  RKManagedObjectSearchEngine.h
//  RestKit
//
//  Created by Jeff Arena on 3/31/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
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

#import "RKSearchEngine.h"

@interface RKManagedObjectSearchEngine : NSObject

/**
 * The type of searching to perform. Can be either RKSearchModeAnd or RKSearchModeOr.
 *
 * Defaults to RKSearchModeOr
 */
@property (nonatomic, assign) RKSearchMode mode;

/**
 * Construct a new search engine
 */
+ (id)searchEngine;

/**
 * Normalize and tokenize the provided string into an NSArray.
 * Note that returned value may contain entries of empty strings.
 */
+ (NSArray *)tokenizedNormalizedString:(NSString *)string;

/**
 * Generate a predicate for the supplied search term against
 * searchableAttributes (defined for an RKSearchableManagedObject)
 */
- (NSPredicate *)predicateForSearch:(NSString *)searchText;

@end
