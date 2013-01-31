//
//  RKKeyPathConnectionDescription.h
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

///-------------------------------------------
/// @name Connecting Relationships by Key Path
///-------------------------------------------

/**
 Provides support for connecting a relationship by traversing the object graph
 */
@interface RKKeyPathConnectionDescription : RKConnectionDescription

/**
 The key path that is to be evaluated to obtain the value for the relationship.
 */
@property (nonatomic, copy, readonly) NSString *keyPath;

/**
 Initializes the receiver with a given relationship and key path.
 
 @param relationship The relationship to be connected.
 @param keyPath The key path from which to read the value that is to be set for the relationship.
 @return The receiver, initialized with the given relationship and key path.
 */
- (id)initWithRelationship:(NSRelationshipDescription *)relationship keyPath:(NSString *)keyPath;

@end
