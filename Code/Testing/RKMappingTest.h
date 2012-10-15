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
#import <CoreData/CoreData.h>
#import "RKMappingOperation.h"
#import "RKMappingTestExpectation.h"

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
    RKMappingTestValueInequalityError,          // A mapped value was not equal to the expected value
    RKMappingTestMappingMismatchError,          // A mapping occurred using an unexpected `RKObjectMapping` object
};

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

 @param mapping The object mapping being tested.
 @param sourceObject The source object being mapped from.
 @param destinationObject The destionation object being to.
 @return A new mapping test object for a mapping, a source object and a destination object.
 */
+ (RKMappingTest *)testForMapping:(RKObjectMapping *)mapping sourceObject:(id)sourceObject destinationObject:(id)destinationObject;

/**
 Initializes the receiver with a given object mapping, source object, and destination object.

 @param mapping The object mapping being tested.
 @param sourceObject The source object being mapped from.
 @param destinationObject The destionation object being to.
 @return The receiver, initialized with mapping, sourceObject and destinationObject.
 */
- (id)initWithMapping:(RKObjectMapping *)mapping sourceObject:(id)sourceObject destinationObject:(id)destinationObject;

///---------------------------
/// @name Setting Expectations
///---------------------------

/**
 Creates and adds an expectation that a key path on the source object will be mapped to a new key path on the destination object.

 @param sourceKeyPath A key path on the sourceObject that should be mapped from.
 @param destinationKeyPath A key path on the destinationObject that should be mapped to.
 @see `RKMappingTestExpectation`
 */
- (void)expectMappingFromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath;

/**
 Creates and adds an expectation that a key path on the source object will be mapped to a new key path on the destination object with a given value.

 @param sourceKeyPath A key path on the sourceObject that should be mapped from.
 @param destinationKeyPath A key path on the destinationObject that should be mapped from.
 @param value A value that is expected to be assigned to destinationKeyPath on the destinationObject.
 @see `RKMappingTestExpectation`
 */
- (void)expectMappingFromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath withValue:(id)value;

/**
 Creates and adds an expectation that a key path on the source object will be mapped to a new key path on the destination object with a value that passes a given test block.

 @param sourceKeyPath A key path on the sourceObject that should be mapped from.
 @param destinationKeyPath A key path on the destinationObject that should be mapped to.
 @param evaluationBlock A block with which to evaluate the success of the mapping.
 @see `RKMappingTestExpectation`
 */
- (void)expectMappingFromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath passingTest:(RKMappingTestExpectationEvaluationBlock)evaluationBlock;

/**
 Creates and adds an expectation that a key path on the source object will be mapped to a new key path on the destination object using the given object mapping.

 @param sourceKeyPath A key path on the sourceObject that should be mapped from.
 @param destinationKeyPath A key path on the destinationObject that should be mapped to.
 @param mapping An object mapping that should be used for mapping the source key path.
 @see `RKMappingTestExpectation`
 */
- (void)expectMappingFromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath usingMapping:(RKMapping *)mapping;

/**
 Adds an expectation to the receiver to be evaluated during verification.

 If the receiver has been configured with `verifiesOnExpect = YES`, the mapping operation is performed immediately and the expectation is evaluated.

 @param expectation An expectation object to evaluate during test verification.
 @see `RKMappingTestExpectation`
 @see `verifiesOnExpect`
 */
- (void)addExpectation:(RKMappingTestExpectation *)expectation;

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

/**
 Evaluates the given expectation against the mapping test and returns a Boolean value indicating if the expectation is met by the receiver.

 Invocation of this method will implicitly invoke `performMapping` if the mapping has not yet been performed.

 @param expectation The expectation to evaluate against the receiver.
 @param error A pointer to an `NSError` object to be set describing the failure in the event that the expectation is not met.
 @return `YES` if the expectation is met, else `NO`.
 */
- (BOOL)evaluateExpectation:(RKMappingTestExpectation *)expectation error:(NSError **)error;

///-------------------------
/// @name Test Configuration
///-------------------------

/**
 The object mapping under test.
 */
@property (nonatomic, strong, readonly) RKObjectMapping *mapping;

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

/**
 A Boolean value that determines if expectations should be verified immediately when added to the receiver.

 **Default**: `NO`
 */
@property (nonatomic, assign) BOOL verifiesOnExpect;

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

@end
