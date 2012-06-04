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
#import "RKObjectMappingOperation.h"
#import "RKMappingTestExpectation.h"

/**
 An RKMappingTest object provides support for unit testing
 a RestKit object mapping operation by evaluation expectations
 against events recorded during an object mapping operation.
 */
@interface RKMappingTest : NSObject

///-----------------------------------------------------------------------------
/// @name Creating Tests
///-----------------------------------------------------------------------------

/**
 Creates and returns a new test for a given object mapping and source object.

 @param mapping The object mapping being tested.
 @param sourceObject The source object being mapped.
 @return A new mapping test object for a mapping and sourceObject.
 */
+ (RKMappingTest *)testForMapping:(RKObjectMapping *)mapping object:(id)sourceObject;

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

///-----------------------------------------------------------------------------
/// @name Setting Expectations
///-----------------------------------------------------------------------------

/**
 Creates and adds an expectation that a key path on the source object will be mapped to a new
 key path on the destination object.

 @param sourceKeyPath A key path on the sourceObject that should be mapped from.
 @param destinationKeyPath A key path on the destinationObject that should be mapped to.
 @see RKObjectMappingTestExpectation
 */
- (void)expectMappingFromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath;

/**
 Creates and adds an expectation that a key path on the source object will be mapped to a new
 key path on the destination object with a given value.

 @param sourceKeyPath A key path on the sourceObject that should be mapped from.
 @param destinationKeyPath A key path on the destinationObject that should be mapped from.
 @param value A value that is expected to be assigned to destinationKeyPath on the destinationObject.
 @see RKObjectMappingTestExpectation
 */
- (void)expectMappingFromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath withValue:(id)value;

/**
 Creates and adds an expectation that a key path on the source object will be mapped to a new
 key path on the destination object with a value that passes a given test block.

 @param sourceKeyPath A key path on the sourceObject that should be mapped from.
 @param destinationKeyPath A key path on the destinationObject that should be mapped to.
 @param evaluationBlock A block with which to evaluate the success of the mapping.
 @see RKObjectMappingTestExpectation
 */
- (void)expectMappingFromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath passingTest:(BOOL (^)(RKObjectAttributeMapping *mapping, id value))evaluationBlock;

/**
 Adds an expectation to the receiver to be evaluated during verification.

 If the receiver has been configured with verifiesOnExpect = YES, the mapping
 operation is performed immediately and the expectation is evaluated.

 @param expectation An expectation object to evaluate during test verification.
 @see RKObjectMappingTestExpectation
 @see verifiesOnExpect
 */
- (void)addExpectation:(RKMappingTestExpectation *)expectation;

///-----------------------------------------------------------------------------
/// @name Verifying Results
///-----------------------------------------------------------------------------

/**
 Performs the object mapping operation and records any mapping events that occur. The
 mapping events can be verified against expectation through a subsequent call to verify.

 @exception NSInternalInconsistencyException Raises an
 NSInternalInconsistencyException if mapping fails.
 */
- (void)performMapping;

/**
 Verifies that the mapping is configured correctly by performing an object mapping operation
 and ensuring that all expectations are met.

 @exception NSInternalInconsistencyException Raises an
 NSInternalInconsistencyException if mapping fails or any expectation is not satisfied.
 */
- (void)verify;

///-----------------------------------------------------------------------------
/// @name Test Configuration
///-----------------------------------------------------------------------------

/**
 The object mapping under test.
 */
@property (nonatomic, strong, readonly) RKObjectMapping *mapping;

/**
 A key path to apply to the source object to specify the location of the root
 of the data under test. Useful when testing subsets of a larger payload or
 object graph.

 **Default**: nil
 */
@property (nonatomic, copy) NSString *rootKeyPath;

/**
 The source object being mapped from.
 */
@property (nonatomic, strong, readonly) id sourceObject;

/**
 The destionation object being mapped to.

 If nil, the mapping test will instantiate a destination object to perform the mapping
 by invoking `[self.mapping mappableObjectForData:self.sourceObject]` and set the
 new object as the value for the destinationObject property.

 @see [RKObjectMapping mappableObjectForData:]
 */
@property (nonatomic, strong, readonly) id destinationObject;

/**
 A Boolean value that determines if expectations should be verified immediately
 when added to the receiver.

 **Default**: NO
 */
@property (nonatomic, assign) BOOL verifiesOnExpect;

@end
