//
//  RKDynamicMapping.h
//  RestKit
//
//  Created by Blake Watters on 7/28/11.
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

#import "RKMapping.h"
#import "RKObjectMapping.h"

typedef RKObjectMapping *(^RKDynamicMappingDelegateBlock)(id representation);

/**
 Defines a dynamic object mapping that determines the appropriate concrete object mapping to apply at mapping time. This allows you to map very similar payloads differently depending on the type of data contained therein.
 */
@interface RKDynamicMapping : RKMapping

///------------------------------------
/// @name Configuring Mapping Selection
///------------------------------------

/**
 Sets a block to be invoked to determine the appropriate concrete object mapping with which to map an object representation.

 @param block The block object to invoke to select the object mapping with which to map the given object representation.
 */
- (void)setObjectMappingForRepresentationBlock:(RKDynamicMappingDelegateBlock)block;

/**
 Defines a dynamic mapping rule stating that when the value of the key property matches the specified value, the given mapping should be used to map the representation.

 For example, suppose that we have a JSON fragment for a person that we want to map differently based on the gender of the person. When the gender is 'male', we want to use the Boy class and when then the gender is 'female' we want to use the Girl class. We might define our dynamic mapping like so:

    RKDynamicMapping *mapping = [RKDynamicMapping new];
    [mapping setObjectMapping:boyMapping whenValueOfKeyPath:@"gender" isEqualTo:@"male"];
    [mapping setObjectMapping:girlMapping whenValueOfKeyPath:@"gender" isEqualTo:@"female"];

 @param objectMapping The mapping to be used when the value at the given key path is equal to the given value.
 @param keyPath The key path to retrieve the comparison value from in the object representation being mapped.
 @param value The value to be compared with the value at `keyPath`. If they are equal, the `objectMapping` will be used to map the representation.
 */
- (void)setObjectMapping:(RKObjectMapping *)objectMapping whenValueOfKeyPath:(NSString *)keyPath isEqualTo:(id)value;

/**
 Returns an array of object mappings that have been registered with the receiver.
 
 @return An array of `RKObjectMapping` objects registered with the receiver.
 */
@property (nonatomic, readonly) NSArray *objectMappings;

///-----------------------------------------------------------------
/// @name Retrieving the Object Mapping for an Object Representation
///-----------------------------------------------------------------

/**
 Invoked by the `RKMapperOperation` and `RKMappingOperation` to determine the appropriate `RKObjectMapping` to use when mapping the given object representation.

 @param representation The object representation that being mapped dynamically for which to determine the appropriate concrete mapping.
 @return The object mapping to be used to map the given object representation.
 */
- (RKObjectMapping *)objectMappingForRepresentation:(id)representation;

@end
