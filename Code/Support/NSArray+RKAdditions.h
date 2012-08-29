//
//  NSArray+RKAdditions.h
//  RestKit
//
//  Created by Blake Watters on 4/10/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
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

#import <Foundation/Foundation.h>

/**
 Provides useful additions to the NSArray interface.
 */
@interface NSArray (RKAdditions)

/**
 Evaluates a given key path against the receiving array, divides the array entries into
 sections grouped by the value for the key path, and returns an aggregate array of arrays
 containing the sections. The receiving array is assumed to be sorted.

 @param keyPath The key path of the value to group the entries by.
 @returns An array of section arrays, with each section containing a group of objects sharing
 the same value for the given key path.
 */
- (NSArray *)sectionsGroupedByKeyPath:(NSString *)keyPath;

@end
