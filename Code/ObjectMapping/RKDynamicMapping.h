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
#import "RKObjectMappingMatcher.h"

/**
 The `RKDynamicMapping` class is an `RKMapping` subclass that provides an interface for deferring the decision about how a given object representation is to be mapped until run time. This enables many interesting mapping strategies, such as mapping similarly structured data differently and constructing object mappings at run time by examining the data being mapped.

 ## Configuring Mapping Selection

 Dynamic mappings support the selection of the concrete object mapping in one of two ways:

 1. Through the use of a mapping selection block configured by `setObjectMappingForRepresentationBlock:`. When configured, the block is called with a reference to the current object representation being mapped and is expected to return an `RKObjectMapping` object. Returning `nil` declines the mapping of the representation.
 1. Through the configuration of one of more `RKObjectMappingMatcher` objects. The matchers are consulted in registration order and the first matcher to return an object mapping is used to map the matched representation.

 When both a mapping selection block and matchers are configured on a `RKDynamicMapping` object, the matcher objects are consulted first and if none match, the selection block is invoked.

 ## Using Matcher Objects

 The `RKObjectMappingMatcher` class provides an interface for evaluating a key path or predicate based match and returning an appropriate object mapping. Matchers can be added to the `RKDynamicMapping` objects to declaratively describe a particular mapping strategy.

 For example, suppose that we have a JSON fragment for a person that we want to map differently based on the gender of the person. When the gender is 'male', we want to use the Boy class and when then the gender is 'female' we want to use the Girl class. The JSON might look something like this:

    [ { "name": "Blake", "gender": "male" }, { "name": "Sarah", "gender": "female" } ]

 We might define configure the dynamic mapping like so:

    RKDynamicMapping *mapping = [RKDynamicMapping new];
    RKObjectMapping *boyMapping = [RKObjectMapping mappingForClass:[Boy class]];
    RKObjectMapping *girlMapping = [RKObjectMapping mappingForClass:[Girl class]];
    [mapping addMatcher:[RKObjectMappingMatcher matcherWithKeyPath:@"gender" expectedValue:@"male" objectMapping:boyMapping]];
    [mapping addMatcher:[RKObjectMappingMatcher matcherWithKeyPath:@"gender" expectedValue:@"female" objectMapping:girlMapping]];

 When evaluated, the matchers will invoke `valueForKeyPath:@"gender"` against each dictionary in the array of object representations and apply the appropriate object mapping for each representation. This would return a mapping result containing an array of two objects, one an instance of the `Boy` class and the other an instance of the `Girl` class.

 ## HTTP Integration

 Dynamic mappings can be used to map HTTP requests and responses by adding them to an `RKRequestDescriptor` or `RKResponseDescriptor` objects.
 */
@interface RKDynamicMapping : RKMapping

///------------------------------------------
/// @name Configuring Block Mapping Selection
///------------------------------------------

/**
 Sets a block to be invoked to determine the appropriate concrete object mapping with which to map an object representation.

 @param block The block object to invoke to select the object mapping with which to map the given object representation. The block returns an object mapping and accepts a single parameter: the object representation being mapped.
 */
- (void)setObjectMappingForRepresentationBlock:(RKObjectMapping *(^)(id representation))block;

/**
 Returns the array of matchers objects added to the receiver.
 */
@property (nonatomic, strong, readonly) NSArray *matchers;

/**
 Adds a matcher to the receiver.

 If the matcher has already been added to the receiver, then adding it again moves it to the top of the matcher stack.

 @param matcher The matcher to add to the receiver.
 */
- (void)addMatcher:(RKObjectMappingMatcher *)matcher;

/**
 Removes a matcher from the receiver.

 If the matcher has already been added to the receiver, then adding it again moves it to the top of the matcher stack.

 @param matcher The matcher to remove from the receiver.
 */
- (void)removeMatcher:(RKObjectMappingMatcher *)matcher;

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

 This method searches the stack of registered matchers and then executes the block, if any, set by `setObjectMappingForRepresentationBlock:`. If `nil` is returned, then mapping for the representation is declined and it will not be mapped.

 @param representation The object representation that being mapped dynamically for which to determine the appropriate concrete mapping.
 @return The object mapping to be used to map the given object representation.
 */
- (RKObjectMapping *)objectMappingForRepresentation:(id)representation;

@end
