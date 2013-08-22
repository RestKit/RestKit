//
//  RKValueTransformers.h
//  RestKit
//
//  Created by Blake Watters on 8/18/13.
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

#import <Foundation/Foundation.h>
#import "RKISO8601DateFormatter.h"

/**
 Objects wish to perform transformation on values as part of a RestKit object mapping operation much adopt the `RKValueTransforming` protocol. Value transformers must introspect a given input value to determine if they are capable of performing a transformation and if so, perform the transformation and assign the new value to the given pointer to an output value and return `YES` or else construct an error describing the failure and return `NO`. Value transformers may also optionally implement a validation method that enables callers to determine if a given value transformer object is capable of performing a transformation on an input value.
 */
@protocol RKValueTransforming <NSObject>

@required

/**
 Transforms a given value into a new representation.
 
 Attempts to perform a transformation of a given value into a new representation and returns a Boolean value indicating if the transformation was successful. Transformers are responsible for introspecting their input values before attempting to perform the transformation. If the transformation cannot be performed, then the transformer must construct an `NSError` object describing the nature of the failure else a warning will be emitted.
 
 @param inputValue The value to be transformed.
 @param outputValue A pointer to an `id` object that will be assigned to the transformed representation. May be assigned to `nil` if that is the result of the transformation.
 @param outputValueClass The class of the `outputValue` variable. Specifies the expected type of a successful transformation. May be `nil` to indicate that the type is unknown or unimportant.
 @param error A pointer to an `NSError` object that must be assigned to a newly constructed `NSError` object if the transformation cannot be performed.
 @return A Boolean value indicating if the transformation was successful. This is used to determine whether another transformer should be given an opportunity to attempt a transformation.
 */
- (BOOL)transformValue:(id)inputValue toValue:(id *)outputValue ofClass:(Class)outputValueClass error:(NSError **)error;

@optional

/**
 Asks the transformer if it is capable of performing a transformation from a given class into a new representation of another given class. 
 
 This is an optional method that need only be implemented by transformers that are tightly bound to values with specific types.
 
 @param inputValueClass The `Class` of an input value being inspected.
 @param outputValueClass The `Class` of an output value being inspected.
 @return `YES` if the receiver can perform a transformation between the given source and destination classes.
 */
// TODO: should this be `validateTransformationFromValue:toClass:` instead?
- (BOOL)validateTransformationFromClass:(Class)inputValueClass toClass:(Class)outputValueClass;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

typedef NS_ENUM(NSUInteger, RKValueTransformationError) {
    RKValueTransformationErrorUntransformableInputValue     = 3000,     // The input value was determined to be unacceptable and no transformation was performed.
    RKValueTransformationErrorUnsupportedOutputClass        = 3001,     // The specified class type for the output value is unsupported and no transformation was performed.
    RKValueTransformationErrorTransformationFailed          = 3002      // A transformation was attempted, but failed.
};

/**
 Tests if a given input value is of an expected class and returns a failure if it is not.
 
 This macro is useful for quickly verifying that a transformer can work with a given input value by checking if the value is an instance of an expected class. On failure, the macro constructs an error describing the class mismatch.
 
 @param inputValue The input value to test.
 @param expectedClass The expected class or array of classes of the input value.
 @param error A pointer to an `NSError` object in which to assign a newly constructed error if the test fails. Cannot be `nil`.
 */
#define RKValueTransformerTestInputValueIsKindOfClass(inputValue, expectedClass, error) ({ \
    NSArray *supportedClasses = [expectedClass isKindOfClass:[NSArray class]] ? (NSArray *)expectedClass : @[ expectedClass ];\
    BOOL success = NO; \
    for (Class supportedClass in supportedClasses) {\
        if ([inputValue isKindOfClass:supportedClass]) { \
            success = YES; \
            break; \
        }; \
    } \
    if (! success) { \
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Expected an `inputValue` of type `%@`, but got a `%@`.", expectedClass, [inputValue class]] };\
        *error = [NSError errorWithDomain:RKErrorDomain code:RKValueTransformationErrorUntransformableInputValue userInfo:userInfo]; \
        return NO; \
    } \
})

/**
 Tests if a given output value class is of an expected class and returns a failure if it is not.
 
 This macro is useful for quickly verifying that a transformer can work with a given input value by checking if the value is an instance of an expected class. On failure, the macro constructs an error describing the class mismatch.
 
 @param outputValueClass The input value to test.
 @param expectedClass The expected class or array of classes of the input value.
 @param error A pointer to an `NSError` object in which to assign a newly constructed error if the test fails. Cannot be `nil`.
 */
#define RKValueTransformerTestOutputValueClassIsSubclassOfClass(outputValueClass, expectedClass, error) ({ \
NSArray *supportedClasses = [expectedClass isKindOfClass:[NSArray class]] ? (NSArray *)expectedClass : @[ expectedClass ];\
BOOL success = NO; \
for (Class supportedClass in supportedClasses) {\
if ([outputValueClass isSubclassOfClass:supportedClass]) { \
success = YES; \
break; \
}; \
} \
if (! success) { \
NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Expected an `outputValueClass` of type `%@`, but got a `%@`.", expectedClass, outputValueClass] };\
*error = [NSError errorWithDomain:RKErrorDomain code:RKValueTransformationErrorUnsupportedOutputClass userInfo:userInfo]; \
return NO; \
} \
})

/**
 Tests a condition to evaluate the success of an attempted value transformation and returns a failure if it is not true.
 
 This macro is useful for quickly verifying that an attempted transformation was successful. If the condition is not true, than an error is constructed describing the failure.
 
 @param condition The condition to test.
 @param expectedClass The expected class of the input value.
 @param error A pointer to an `NSError` object in which to assign a newly constructed error if the test fails. Cannot be `nil`.
 @param ... A string describing what the failure was that occurred. This may be a format string with additional arguments.
 */
#define RKValueTransformerTestTransformation(condition, error, ...) ({ \
if (! (condition)) { \
NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: [NSString stringWithFormat:__VA_ARGS__] };\
*error = [NSError errorWithDomain:RKErrorDomain code:RKValueTransformationErrorTransformationFailed userInfo:userInfo]; \
return NO; \
} \
})

////////////////////////////////////////////////////////////////////////////////////////////////////

@class RKCompoundValueTransformer;

/**
 The `RKValueTransformer` class provides a concrete implementation of the `RKValueTransforming` protocol using blocks to provide the implementation of the transformer. It additionally encapsulates accessors for the default value transformer implementations that are provided with RestKit.
 */
@interface RKValueTransformer : NSObject <RKValueTransforming>

///---------------------------------
/// @name Create a Block Transformer
///---------------------------------

/**
 Creates and returns a new value transformer with the given validation and transformation blocks. The blocks are used to provide the implementation of the corresponding methods from the `RKValueTransforming` protocol.
 
 @param validationBlock A block that evaluates whether the transformer can perform a transformation between a given pair of input and output classes.
 */
+ (instancetype)valueTransformerWithValidationBlock:(BOOL (^)(Class inputValueClass, Class outputValueClass))validationBlock
                                transformationBlock:(BOOL (^)(id inputValue, id *outputValue, Class outputClass, NSError **error))transformationBlock;

///--------------------------------------
/// @name Retrieving Default Transformers
///--------------------------------------

// NOTE: alphabetize by convention???

+ (instancetype)stringToURLValueTransformer;
+ (instancetype)numberToStringValueTransformer;
+ (instancetype)dateToNumberValueTransformer;
+ (instancetype)arrayToOrderedSetValueTransformer;
+ (instancetype)arrayToSetValueTransformer;
+ (instancetype)decimalNumberToNumberValueTransformer;
+ (instancetype)decimalNumberToStringValueTransformer;
+ (instancetype)nullValueTransformer; // TODO: nullToNilValueTransformer??? NOTE: Only transforms `[NSNull null]` to `nil`.
+ (instancetype)keyedArchivingValueTransformer;

// NOTE: Supports `NSDate` <-> (`NSString` | `NSNumber`) using time interval since the UNIX epoch. Numbers are treated as doubles to support fractional seconds
+ (instancetype)timeIntervalSince1970ToDateValueTransformer;

// TODO: stringValueTransformer:
// TODO: objectToCollectionValueTransformer... Can this be handled with this architecture?? Probably has to be done via a compound transformer...

+ (RKCompoundValueTransformer *)defaultValueTransformer;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@interface RKCompoundValueTransformer : NSObject <RKValueTransforming, NSCopying, NSFastEnumeration>

+ (instancetype)compoundValueTransformerWithValueTransformers:(NSArray *)valueTransformers;

- (void)addValueTransformer:(id<RKValueTransforming>)valueTransformer;
- (void)removeValueTransformer:(id<RKValueTransforming>)valueTransformer;
- (void)insertValueTransformer:(id<RKValueTransforming>)valueTransformer atIndex:(NSUInteger)index; // performs a move or insert

- (NSUInteger)numberOfValueTransformers;

// Note: pass `Nil` `Nil` to get all of them
- (NSArray *)valueTransformersForTransformingFromClass:(Class)sourceClass toClass:(Class)destinationClass;

@end

// Adopts `RKValueTransforming` to provide transformation from `NSString` <-> `NSNumber`
@interface NSNumberFormatter (RKValueTransformers) <RKValueTransforming>
@end

// Adopts `RKValueTransforming` to provide transformation from `NSString` <-> `NSNumber`
@interface NSDateFormatter (RKValueTransformers) <RKValueTransforming>
@end

@interface RKISO8601DateFormatter (RKValueTransformers) <RKValueTransforming>
@end


// TODO: Eliminate
@interface RKDateToStringValueTransformer : NSObject <RKValueTransforming>
@end
