//
//  RKMappingTest.h
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

#import <Foundation/Foundation.h>
#import "RKMappingOperation.h"
#import "RKPropertyMappingTestExpectation.h"

@protocol RKMappingOperationDataSource, RKManagedObjectCaching;

///----------------
/// @name Constants
///----------------

/**
 The domain for all errors constructed by the `RKMappingTest` class.
 */
extern NSString * const RKMappingTestErrorDomain;

/**
 Name of an exception that occurs when an `RKMappingTest` object fails verification. Raised by `verifyExpectation`.
 */
extern NSString * const RKMappingTestVerificationFailureException;

/**
 Mapping Test Errors
 */
enum {
    RKMappingTestUnsatisfiedExpectationError,   // An expected mapping event did not occur
    RKMappingTestEvaluationBlockError,          // An evaluation block returned `NO` when evaluating a mapping event
    RKMappingTestValueInequalityError,          // A value was not equal to the expected value
    RKMappingTestMappingMismatchError,          // A mapping occurred using an unexpected `RKObjectMapping` object
};

/**
 @define RKMappingTestExpectationTestCondition
 @abstract Tests a condition and returns `NO` and error if it is not true.
 @discussion This is a useful macro when constructing mapping test evaluation blocks. It will test a condition and return `NO` as well as construct an error. This is meant to be used **only** within the body of a `RKMappingTestExpectationEvaluationBlock` object.
 @param condition The condition to test.
 @param errorCode An error code in the RKMappingTestErrorDomain indicating the nature of the failure.
 @param error The NSError object to put the error string into. May be nil, but should usually be the error parameter from the expectation evaluation block.
 @param ... A string describing the error.
 */
#define RKMappingTestCondition(condition, errorCode, error, ...) ({ \
if (!(condition)) { \
if (error) { \
*error = [NSError errorWithDomain:RKMappingTestErrorDomain code:errorCode userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:__VA_ARGS__], NSLocalizedDescriptionKey, nil]]; \
} \
return NO; \
} \
})

/**
 The `RKMappingTestEvent` object for the mapping event which failed to satify the expectation.
 */
extern NSString * const RKMappingTestEventErrorKey;

/**
 The `RKMappingTestExpectation` object which was not satisfied by a mapping event.
 */
extern NSString * const RKMappingTestExpectationErrorKey;

/**
 An `RKMappingTest` object provides support for unit testing a RestKit object mapping operation by evaluation expectations against events recorded during an object mapping operation.
 */
@interface RKMappingTest : NSObject

///---------------------
/// @name Creating Tests
///---------------------

/**
 Creates and returns a new test for a given object mapping, source object and destination
 object.

 @param mapping The mapping being tested.
 @param sourceObject The source object being mapped from.
 @param destinationObject The destionation object being to.
 @return A new mapping test object for a mapping, a source object and a destination object.
 */
+ (instancetype)testForMapping:(RKMapping *)mapping sourceObject:(id)sourceObject destinationObject:(id)destinationObject;

/**
 Initializes the receiver with a given object mapping, source object, and destination object.

 @param mapping The mapping being tested.
 @param sourceObject The source object being mapped from.
 @param destinationObject The destionation object being to.
 @return The receiver, initialized with mapping, sourceObject and destinationObject.
 */
- (id)initWithMapping:(RKMapping *)mapping sourceObject:(id)sourceObject destinationObject:(id)destinationObject;

///----------------------------
/// @name Managing Expectations
///----------------------------

/**
 Adds an expectation to the receiver to be evaluated during verification.

 @param expectation An expectation object to evaluate during test verification. Must be an instance of `RKPropertyMappingTestExpectation` or `RKConnectionTestExpectation`.
 @see `RKMappingTestExpectation`
 @see `verifiesOnExpect`
 */
- (void)addExpectation:(id)expectation;

/**
 Evaluates the given expectation against the mapping test and returns a Boolean value indicating if the expectation is met by the receiver.
 
 Invocation of this method will implicitly invoke `performMapping` if the mapping has not yet been performed.
 
 @param expectation The expectation to evaluate against the receiver. Must be an intance of either `RKPropertyMappingTestExpectation` or `RKConnectionTestExpectation`.
 @param error A pointer to an `NSError` object to be set describing the failure in the event that the expectation is not met.
 @return `YES` if the expectation is met, else `NO`.
 */
- (BOOL)evaluateExpectation:(id)expectation error:(NSError **)error;

///------------------------
/// @name Verifying Results
///------------------------

/**
 Performs the object mapping operation and records any mapping events that occur. The mapping events can be verified against expectation through a subsequent call to verify.

 @exception NSInternalInconsistencyException Raises an `NSInternalInconsistencyException` if mapping fails.
 */
- (void)performMapping;

/**
 Verifies that the mapping is configured correctly by performing an object mapping operation and ensuring that all expectations are met.

 @exception RKMappingTestVerificationFailureException Raises an `RKMappingTestVerificationFailureException` exception if mapping fails or any expectation is not satisfied.
 */
- (void)verify;

/**
 Evaluates the expectations and returns a Boolean value indicating if all expectations are satisfied.

 Invocation of this method will implicitly invoke `performMapping` if the mapping has not yet been performed.

 @return `YES` if all expectations were met, else `NO`.
 */
- (BOOL)evaluate;

///-------------------------
/// @name Test Configuration
///-------------------------

/**
 The mapping under test. Can be either an `RKObjectMapping` or `RKDynamicMapping` object.
 */
@property (nonatomic, strong, readonly) RKMapping *mapping;

/**
 A data source for the mapping operation.

 If `nil`, an appropriate data source will be constructed for you using the available configuration of the receiver.
 */
@property (nonatomic, strong) id<RKMappingOperationDataSource> mappingOperationDataSource;

/**
 A key path to apply to the source object to specify the location of the root of the data under test. Useful when testing subsets of a larger payload or object graph.

 **Default**: `nil`
 */
@property (nonatomic, copy) NSString *rootKeyPath;

/**
 The source object being mapped from.
 */
@property (nonatomic, strong, readonly) id sourceObject;

/**
 The destionation object being mapped to.

 If `nil`, the mapping test will instantiate a destination object to perform the mapping by invoking `[self.mappingOperationDataSource objectForMappableContent:self.sourceObject mapping:self.mapping]` to obtain a new object from the data source and then assign the object as the value for the destinationObject property.

 @see `mappingOperationDataSource`
 */
@property (nonatomic, strong, readonly) id destinationObject;

#ifdef _COREDATADEFINES_H

///----------------------------
/// @name Core Data Integration
///----------------------------

/**
 The managed object context within which to perform the mapping test. Required if testing an `RKEntityMapping` object and an appropriate `mappingOperationDataSource` has not been configured.
 
 When the `mappingOperationDataSource` property is `nil` and the test targets an entity mapping, this context is used to configure an `RKManagedObjectMappingOperationDataSource` object for the purpose of executing the test.
 */
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

/**
 The managed object cache to use when performing a mapping test.
 
 If the value of this property is `nil` and the test targets an entity mapping, an instance of `RKFetchRequestManagedObjectCache` will be constructed and used as the cache for the purposes of testing.
 */
@property (nonatomic, strong) id<RKManagedObjectCaching> managedObjectCache;

#endif // _COREDATADEFINES_H

@end
