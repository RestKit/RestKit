//
//  RKMappingTestExpectation.h
//  RestKit
//
//  Created by Blake Watters on 2/17/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKObjectAttributeMapping.h"

/**
 An RKMappingTestExpectation defines an expected mapping event that should
 occur during the execution of a RKMappingTest.

 @see RKMappingTest
 */
@interface RKMappingTestExpectation : NSObject

///-----------------------------------------------------------------------------
/// @name Creating Expectations
///-----------------------------------------------------------------------------

/**
 Creates and returns a new expectation specifying that a key path in a source object should be
 mapped to another key path on a destination object. The value mapped is not evaluated.

 @param sourceKeyPath A key path on the source object that should be mapped.
 @param destinationKeyPath A key path on the destination object that should be mapped onto.
 @return An expectation specifying that sourceKeyPath should be mapped to destionationKeyPath.
 */
+ (RKMappingTestExpectation *)expectationWithSourceKeyPath:(NSString *)sourceKeyPath destinationKeyPath:(NSString *)destinationKeyPath;

/**
 Creates and returns a new expectation specifying that a key path in a source object should be
 mapped to another key path on a destination object with a given value.

 @param sourceKeyPath A key path on the source object that should be mapped.
 @param destinationKeyPath A key path on the destination object that should be mapped onto.
 @param value The value that is expected to be assigned to the destination object at destinationKeyPath.
 @return An expectation specifying that sourceKeyPath should be mapped to destionationKeyPath with value.
 */
+ (RKMappingTestExpectation *)expectationWithSourceKeyPath:(NSString *)sourceKeyPath destinationKeyPath:(NSString *)destinationKeyPath value:(id)value;

/**
 Creates and returns a new expectation specifying that a key path in a source object should be
 mapped to another key path on a destinaton object and that the attribute mapping and value should
 evaluate to true with a given block.

 @param sourceKeyPath A key path on the source object that should be mapped.
 @param destinationKeyPath A key path on the destination object that should be mapped onto.
 @param evaluationBlock A block with which to evaluate the success of the mapping.
 @return An expectation specifying that sourceKeyPath should be mapped to destionationKeyPath with value.
 */
+ (RKMappingTestExpectation *)expectationWithSourceKeyPath:(NSString *)sourceKeyPath destinationKeyPath:(NSString *)destinationKeyPath evaluationBlock:(BOOL (^)(RKObjectAttributeMapping *mapping, id value))evaluationBlock;

///-----------------------------------------------------------------------------
/// @name Expectation Values
///-----------------------------------------------------------------------------

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
 */
@property (nonatomic, copy, readonly) BOOL (^evaluationBlock)(RKObjectAttributeMapping *mapping, id value);

/**
 Returns a string summary of the expected keyPath mapping within the expectation

 @return A string describing the expected sourceKeyPath to destinationKeyPath mapping.
 */
- (NSString *)mappingDescription;

@end
