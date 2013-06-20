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

typedef enum {
    RKSetAssignmentPolicy,       // Set the relationship to the new value and leave the existing objects alone, breaking the relationship to existing objects at the destination. This is the default policy for `RKRelationshipMapping`.
    RKReplaceAssignmentPolicy,  // Set the relationship to the new value and destroy the previous value, replacing the existing objects at the destination of the relationship.
    RKUnionAssignmentPolicy,    // Set the relationship to the union of the existing value and the new value being assigned. Only applicable for to-many relationships.
} RKAssignmentPolicy;

/**
 The `RKRelationshipMapping` class is used to describe relationships of a class in an `RKObjectMapping` or an entity in an `RKEntityMapping` object.

 `RKRelationshipMapping` extends `RKPropertyMapping` to describe features specific to relationships, including the `RKMapping` object describing how to map the destination object.
 
 Relationship mappings are described in terms of a source key path, which identifies a key in the parent object representation under which the data for the relationship is nested, and a destination key path, which specifies the key path at which the mapped object is to be assigned on the parent entity. The key paths of the property mappings of the `RKMapping` object in the relationship mapping are evaluated against the nested object representationship at the source key path.
 
 ## Mapping a Non-nested Relationship from the Parent Representation
 
 It can often be desirable to map data for a relationship directly from the parent object representation, rather than under a nested key path. When a relationship mapping is constructed with a `nil` value for the source key path, then the `RKMapping` object is evaluated against the parent representation.
 
 ## Assignment Policy
 
 When mapping a relationship, the typical desired behavior is to set the destination of the relationship to the newly mapped values from the object representation being processed. There are times in which it is desirable to use different assignment behaviors. The way in which the relationship is assigned can be controlled by the assignmentPolicy property. There are currently three distinct assignment policies available:
 
 1. `RKSetAssignmentPolicy` - Instructs the mapper to assign the new destination value to the relationship directly. No further action is taken and the relationship to the old objects is broken. This is the default assignment policy.
 1. `RKReplaceAssignmentPolicy` - Instructs the mapper to assign the new destination value to the relationship and delete any existing object or objects at the destination. The deletion behavior is contextual based on the type of objects being mapped (i.e. Core Data vs NSObject) and is delegated to the mapping operation data source.
 1. `RKUnionAssignmentPolicy` - Instructs the mapper to build a new value for the relationship by unioning the existing value with the new value and set the combined value to the relationship. The union assignment policy is only appropriate for use with a to-many relationship.
 
 */
@interface RKRelationshipMapping : RKPropertyMapping

///--------------------------------------
/// @name Creating a Relationship Mapping
///--------------------------------------

/**
 Creates and returns a new relationship mapping object describing how to transform a related object representation at `sourceKeyPath` to a new representation at `destinationKeyPath` using the given mapping.

 The mapping may describe a to-one or a to-many relationship. The appropriate handling of the source representation is deferred until run-time and is determined by performing reflection on the data retrieved from the source object representation by sending a `valueForKeyPath:` message where the key path is the value given in `sourceKeyPath`. If an `NSArray`, `NSSet` or `NSOrderedSet` object is returned, the related object representation is processed as a to-many collection. Otherwise the representation is considered to be a to-one.

 @param sourceKeyPath A key path from which to retrieve data in the source object representation that is to be mapped as a relationship. If `nil`, then the mapping is performed directly against the parent object representation.
 @param destinationKeyPath The key path on the destination object to set the object mapped results.
 @param mapping A mapping object describing how to map the data retrieved from `sourceKeyPath` that is to be set on `destinationKeyPath`.
 */
+ (instancetype)relationshipMappingFromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath withMapping:(RKMapping *)mapping;

///----------------------------------------
/// @name Accessing the Destination Mapping
///----------------------------------------

/**
 An `RKMapping` object describing how to map the object representation at `sourceKeyPath` to a new represenation at `destinationKeyPath`.
 */
@property (nonatomic, strong, readonly) RKMapping *mapping;

///----------------------------------------
/// @name Configuring the Assignment Policy
///----------------------------------------

/**
 The assignment policy to use when applying the relationship mapping.
 
 The assignment policy determines how a relationship is set when there are existing objects at the destination of the relationship. The existing values can be disconnected from the parent and left in the graph (`RKSetAssignmentPolicy`), deleted and replaced by the new value (`RKReplaceAssignmentPolicy`), or the new value can be unioned with the existing objects to create a new combined value (`RKUnionAssignmentPolicy`).
 
 **Default**: `RKSetAssignmentPolicy`
 */
@property (nonatomic, assign) RKAssignmentPolicy assignmentPolicy;

@end
