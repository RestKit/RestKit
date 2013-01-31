//
//  RKForeignKeyConnectionDescription.h
//  RestKit
//
//  Created by Marius Rackwitz on 21.01.13.
//  Copyright (c) 2013 RestKit. All rights reserved.
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

#import "RKConnectionDescription.h"

///-----------------------------------------------
/// @name Connecting Relationships by Foreign Keys
///-----------------------------------------------

/**
 Provides support for connecting a relationship by keeping relational backend connections synchronized
 */
@interface RKForeignKeyConnectionDescription : RKConnectionDescription

/**
 The dictionary of attributes specifying how attributes on the source entity for the relationship correspond to attributes on the destination entity.
 */
@property (nonatomic, copy, readonly) NSDictionary *attributes;

/**
 Initializes the receiver with a given relationship and a dictionary of attributes specifying how to connect the relationship.
 
 @param relationship The relationship to be connected.
 @param sourceToDestinationEntityAttributes A dictionary specifying how attributes on the source entity correspond to attributes on the destination entity.
 @return The receiver, initialized with the given relationship and attributes.
 */
- (id)initWithRelationship:(NSRelationshipDescription *)relationship attributes:(NSDictionary *)attributes;

@end
