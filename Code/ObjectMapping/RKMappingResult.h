//
//  RKMappingResult.h
//  RestKit
//
//  Created by Blake Watters on 5/7/11.
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

#import <Foundation/Foundation.h>

/**
 The `RKMappingResult` class represents the aggregate object mapping results returned by an `RKMapperOperation` object. The mapping result provides a thin interface on top of an `NSDictionary` and provides convenient interfaces for accessing the mapping results in various representations.
 */
@interface RKMappingResult : NSObject

///----------------------------------------
/// @name Creating a Mapping Result
///----------------------------------------

/**
 Initializes the receiver with a dictionary of mapped key paths and object values.

 @param dictionary A dictionary wherein the keys represent mapped key paths and the values represent the objects mapped at those key paths. Cannot be nil.
 @return The receiver, initialized with the given dictionary.
 */
- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

///----------------------------------------
/// @name Retrieving Result Representations
///----------------------------------------

/**
 Returns a representation of the mapping result as a dictionary.

 The keys of the returned dictionary will correspond to the mapped key paths in the source object representation and the values will be the mapped objects. The returned value is a copy of the dictionary that was used to initialize the mapping result.

 @return A dictionary containing the mapping results.
 */
- (NSDictionary *)dictionary;

/**
 Returns a representation of the mapping result as a single object by returning the first mapped value from the aggregate array of mapped objects.

 The mapping result is coerced into a single object by retrieving all mapped objects and returning the first object. If the mapping result is empty, `nil` is returned.

 @return The first object contained in the mapping result.
 */
@property (nonatomic, readonly, strong) id firstObject;

/**
 Returns a representation of the mapping result as an array of objects.

 The array returned is a flattened collection of all mapped object values contained in the underlying dictionary result representation. No guarantee is made as to the ordering of objects within the returned collection when more than one key path was mapped, as `NSDictionary` objects are unordered,

 @return An array containing the objects contained in the mapping result.
 */
- (NSArray *)array;

/**
 Returns a representation of the mapping result as a set of objects.

 The set returned is a flattened collection of all mapped object values contained in the underlying dictionary result representation.

 @return A set containing the objects contained in the mapping result.
 */
@property (nonatomic, readonly, copy) NSSet *set;

///----------------------------------------
/// @name Counting Entries
///----------------------------------------

/**
 Returns a count of the number of objects contained in the mapping result. This is an aggregate count of all objects across all mapped key paths in the result.

 @return A count of the number of mapped objects in the mapping result.
 */
@property (nonatomic, readonly) NSUInteger count;

@end
