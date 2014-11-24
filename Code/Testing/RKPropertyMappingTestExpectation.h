//
//  RKPropertyMappingTestExpectation.h
//  RestKit
//
//  Created by Blake Watters on 2/17/12.
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

@class RKMapping, RKPropertyMapping, RKPropertyMappingTestExpectation;

/**
 @typedef RKMappingTestExpectationEvaluationBlock

 @param expectation The expectation object itself. This is passed so that there is a reference available at the time of evaluation.
 @param mapping The property mapping object that occurred for the source and destination key paths of the expectation. Will be an instance of `RKAttributeMapping, `RKRelationshipMapping`, or `RKConnectionMapping`.
 @param mappedValue The value that was mapped.
 @param error A pointer to an error object that is to be set in the event that the expectation evaluates negatively. If left to `nil`, a generic error will be generated.
 */
typedef BOOL (^RKMappingTestExpectationEvaluationBlock)(RKPropertyMappingTestExpectation *expectation, RKPropertyMapping *mapping, id mappedValue, NSError **error);

/**
 An `RKMappingTestExpectation` object defines an expected mapping event that should occur during the execution of a `RKMappingTest`.

 @see `RKMappingTest`
 */
@interface RKPropertyMappingTestExpectation : NSObject

///----------------------------
/// @name Creating Expectations
///----------------------------

/**
 Creates and returns a new expectation specifying that a key path in a source object should be mapped to another key path on a destination object. The value mapped is not evaluated.

 @param sourceKeyPath A key path on the source object that should be mapped.
 @param destinationKeyPath A key path on the destination object that should be mapped onto.
 @return An expectation specifying that sourceKeyPath should be mapped to destinationKeyPath.
 */
+ (instancetype)expectationWithSourceKeyPath:(NSString *)sourceKeyPath destinationKeyPath:(NSString *)destinationKeyPath;

/**
 Creates and returns a new expectation specifying that a key path in a source object should be mapped to another key path on a destination object with a given value.

 @param sourceKeyPath A key path on the source object that should be mapped.
 @param destinationKeyPath A key path on the destination object that should be mapped onto.
 @param value The value that is expected to be assigned to the destination object at destinationKeyPath.
 @return An expectation specifying that sourceKeyPath should be mapped to destinationKeyPath with value.
 */
+ (instancetype)expectationWithSourceKeyPath:(NSString *)sourceKeyPath destinationKeyPath:(NSString *)destinationKeyPath value:(id)value;

/**
 Creates and returns a new expectation specifying that a key path in a source object should be mapped to another key path on a destinaton object and that the attribute mapping and value should evaluate to true with a given block.

 @param sourceKeyPath A key path on the source object that should be mapped.
 @param destinationKeyPath A key path on the destination object that should be mapped onto.
 @param evaluationBlock A block with which to evaluate the success of the mapping.
 @return An expectation specifying that sourceKeyPath should be mapped to destinationKeyPath with value.
 */
+ (instancetype)expectationWithSourceKeyPath:(NSString *)sourceKeyPath destinationKeyPath:(NSString *)destinationKeyPath evaluationBlock:(RKMappingTestExpectationEvaluationBlock)evaluationBlock;

/**
 Creates and returns a new expectation specifying that a key path in a source object should be mapped to another key path on a destinaton object using a specific object mapping for the relationship.

 @param sourceKeyPath A key path on the source object that should be mapped.
 @param destinationKeyPath A key path on the destination object that should be mapped onto.
 @param mapping An object mapping that is expected to be used for mapping the nested relationship.
 @return An expectation specifying that sourceKeyPath should be mapped to destinationKeyPath using a specific object mapping.
 */
+ (instancetype)expectationWithSourceKeyPath:(NSString *)sourceKeyPath destinationKeyPath:(NSString *)destinationKeyPath mapping:(RKMapping *)mapping;

///-------------------------
/// @name Expectation Values
///-------------------------

/**
 Returns a keyPath on the source object that a value should be mapped from.
 */
@property (nonatomic, copy, readonly) NSString *sourceKeyPath;

/**
 Returns a keyPath on the destination object that a value should be mapped to.
 */
@property (nonatomic, copy, readonly) NSString *destinationKeyPath;

/**
 Returns the expected value that should be set to the destinationKeyPath of the destination object.
 */
@property (nonatomic, strong, readonly) id value;

/**
 A block used to evaluate if the expectation has been satisfied.

 The block accepts three arguments, an `RKPropertyMapping` object denoting the attribute or relationship that was mapped, the mapped value, and a pointer to an error object that is to be set if the block evaluates negatively, and returns a Boolean value indicating if the mapping satisfies the expectations of the block.
 */
@property (nonatomic, copy, readonly) RKMappingTestExpectationEvaluationBlock evaluationBlock;

/**
 Returns the expected object mapping to be used for mapping a nested relationship.
 */
@property (nonatomic, strong, readonly) RKMapping *mapping;

/**
 Returns a string summary of the expected keyPath mapping within the expectation

 @return A string describing the expected sourceKeyPath to destinationKeyPath mapping.
 */
@property (nonatomic, readonly, copy) NSString *summary;

@end
