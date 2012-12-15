//
//  RKRelationshipMapping.h
//  RestKit
//
//  Created by Blake Watters on 5/4/11.
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

#import "RKPropertyMapping.h"

@class RKMapping;

/**
 The `RKRelationshipMapping` class is used to describe relationships of a class in an `RKObjectMapping` or an entity in an `RKEntityMapping` object.

 `RKRelationshipMapping` extends `RKPropertyMapping` to describe features specific to relationships, including the `RKMapping` object describing how to map the destination object.
 */
@interface RKRelationshipMapping : RKPropertyMapping

///--------------------------------------
/// @name Creating a Relationship Mapping
///--------------------------------------

/**
 Creates and returns a new relationship mapping object describing how to transform a related object representation at `sourceKeyPath` to a new representation at `destinationKeyPath` using the given mapping.

 The mapping may describe a to-one or a to-many relationship. The appropriate handling of the source representation is deferred until run-time and is determined by performing reflection on the data retrieved from the source object representation by sending a `valueForKeyPath:` message where the key path is the value given in `sourceKeyPath`. If an `NSArray`, `NSSet` or `NSOrderedSet` object is returned, the related object representation is processed as a to-many collection. Otherwise the representation is considered to be a to-one.

 @param sourceKeyPath A key path from which to retrieve data in the source object representation that is to be mapped as a relationship.
 @param destinationKeyPath The key path on the destination object to set the object mapped results.
 @param mapping A mapping object describing how to map the data retrieved from `sourceKeyPath` that is to be set on `destinationKeyPath`.
 */
+ (RKRelationshipMapping *)relationshipMappingFromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath withMapping:(RKMapping *)mapping;

///----------------------------------------
/// @name Accessing the Destination Mapping
///----------------------------------------

/**
 An `RKMapping` object describing how to map the object representation at `sourceKeyPath` to a new represenation at `destinationKeyPath`.
 */
@property (nonatomic, strong, readonly) RKMapping *mapping;

@end
