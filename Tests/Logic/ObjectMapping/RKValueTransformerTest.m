//
//  RKValueTransformerTest.m
//  RestKit
//
//  Created by Samuel E. Giddins on 6/13/13.
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

#import "RKTestEnvironment.h"
#import "RKValueTransformers.h"

// Used to test subclass raising
@interface RKIncompleteValueTransformer : RKValueTransformer
@end

@implementation RKIncompleteValueTransformer
@end

@interface RKValueTransformerTest : SenTestCase
@end

@implementation RKValueTransformerTest

#pragma mark - Abstract Class Tests

- (void)testThatDirectInstantiationOfRKValueTransformerRaises
{
    expect(^{ [RKValueTransformer new]; }).to.raiseWithReason(NSInternalInconsistencyException, @"`RKValueTransformer` is abstract and cannot be directly instantiated. Instantiate a subclass implementation instead.");
}

- (void)testThatIncompleteSubclassesRaiseOnTransformation
{
    RKIncompleteValueTransformer *incompleteTransformer = [RKIncompleteValueTransformer new];
    expect(^{ [incompleteTransformer transformValue:nil toValue:nil ofClass:Nil error:nil]; }).to.raiseWithReason(NSInternalInconsistencyException, @"`RKValueTransformer` subclasses must provide a concrete implementation of `transformValue:toValue:ofClass:error:`.");
}

#pragma mark - Default Transformers

#pragma mark String to URL

- (void)testStringToURLTransformerValidationSuccessFromStringToURL
{
    RKValueTransformer *valueTransformer = [RKValueTransformer stringToURLValueTransformer];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSString class] toClass:[NSURL class]];
    expect(success).to.beTruthy();
}

- (void)testStringToURLTransformerValidationSuccessFromURLToString
{
    RKValueTransformer *valueTransformer = [RKValueTransformer stringToURLValueTransformer];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSString class] toClass:[NSURL class]];
    expect(success).to.beTruthy();
}

- (void)testStringToURLTransformerValidationFailure
{
    RKValueTransformer *valueTransformer = [RKValueTransformer stringToURLValueTransformer];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSNumber class] toClass:[NSURL class]];
    expect(success).to.beFalsy();
}

- (void)testStringToURLTransformerTransformationSuccessFromStringToURL
{
    RKValueTransformer *valueTransformer = [RKValueTransformer stringToURLValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@"http://restkit.org" toValue:&value ofClass:[NSURL class] error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beInstanceOf([NSURL class]);
    expect(value).to.equal([NSURL URLWithString:@"http://restkit.org"]);
}

- (void)testStringToURLTransformerTransformationSuccessFromURLToString
{
    RKValueTransformer *valueTransformer = [RKValueTransformer stringToURLValueTransformer];
    NSString *value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:[NSURL URLWithString:@"http://restkit.org"] toValue:&value ofClass:[NSString class] error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSString class]);
    expect(value).to.equal(@"http://restkit.org");
}

- (void)testStringToURLTransformerFailureWithUntransformableInputValue
{
    RKValueTransformer *valueTransformer = [RKValueTransformer stringToURLValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@12345 toValue:&value ofClass:[NSString class] error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorUntransformableInputValue);
}

- (void)testStringToURLTransformerFailureWithInvalidInputValue
{
    RKValueTransformer *valueTransformer = [RKValueTransformer stringToURLValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@":*7vxck#sf#adsa" toValue:&value ofClass:[NSURL class] error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorTransformationFailed);
}

- (void)testStringToURLTransformerFailureWithInvalidDestinationClass
{
    RKValueTransformer *valueTransformer = [RKValueTransformer stringToURLValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@"http://restkit.org" toValue:&value ofClass:[NSData class] error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorUnsupportedOutputClass);
}

#pragma mark Number to String

- (void)testNumberToStringTransformerValidationSuccessFromStringToNumber
{
    RKValueTransformer *valueTransformer = [RKValueTransformer numberToStringValueTransformer];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSString class] toClass:[NSNumber class]];
    expect(success).to.beTruthy();
}

- (void)testNumberToStringTransformerValidationFromNumberToString
{
    RKValueTransformer *valueTransformer = [RKValueTransformer numberToStringValueTransformer];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSNumber class] toClass:[NSString class]];
    expect(success).to.beTruthy();
}

- (void)testNumberToStringTransformerValidationFailure
{
    RKValueTransformer *valueTransformer = [RKValueTransformer numberToStringValueTransformer];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSNumber class] toClass:[NSNumber class]];
    expect(success).to.beFalsy();
}

- (void)testNumberToStringTransformerTransformationSuccessFromStringToNumber
{
    RKValueTransformer *valueTransformer = [RKValueTransformer numberToStringValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@"12345" toValue:&value  ofClass:[NSNumber class] error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSNumber class]);
    expect(value).to.equal(@12345);
}

- (void)testNumberToStringTransformerTransformationSuccessFromNumberToString
{
    RKValueTransformer *valueTransformer = [RKValueTransformer numberToStringValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@12345 toValue:&value ofClass:[NSString class] error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSString class]);
    expect(value).to.equal(@"12345");
}

- (void)testNumberToStringTransformerTransformationSuccessFromStringToBooleanNumber
{
    RKValueTransformer *valueTransformer = [RKValueTransformer numberToStringValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@12345 toValue:&value ofClass:[NSString class] error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSString class]);
    expect(value).to.equal(@"12345");
}

- (void)testNumberToStringTransformerTransformationSuccessFromBooleanNumberToString
{
    RKValueTransformer *valueTransformer = [RKValueTransformer numberToStringValueTransformer];
    id value = nil;
    NSError *error = nil;
    [valueTransformer transformValue:[NSNumber numberWithBool:YES] toValue:&value ofClass:[NSString class] error:&error];
    expect(value).to.equal(@"true");
    [valueTransformer transformValue:[NSNumber numberWithBool:NO] toValue:&value ofClass:[NSString class] error:&error];
    expect(value).to.equal(@"false");
}

- (void)testNumberToStringTransformerTransformationSuccessFromBooleanStringToNumber
{
    RKValueTransformer *valueTransformer = [RKValueTransformer numberToStringValueTransformer];
    id value = nil;
    NSError *error = nil;
    
    // True
    [valueTransformer transformValue:@"true" toValue:&value ofClass:[NSNumber class] error:&error];
    expect(value).to.equal([NSNumber numberWithBool:YES]);
    [valueTransformer transformValue:@"TRUE" toValue:&value ofClass:[NSNumber class] error:&error];
    expect(value).to.equal([NSNumber numberWithBool:YES]);
    [valueTransformer transformValue:@"t" toValue:&value ofClass:[NSNumber class]error:&error];
    expect(value).to.equal([NSNumber numberWithBool:YES]);
    [valueTransformer transformValue:@"T" toValue:&value ofClass:[NSNumber class]error:&error];
    expect(value).to.equal([NSNumber numberWithBool:YES]);
    [valueTransformer transformValue:@"yes" toValue:&value ofClass:[NSNumber class]error:&error];
    expect(value).to.equal([NSNumber numberWithBool:YES]);
    [valueTransformer transformValue:@"YES" toValue:&value ofClass:[NSNumber class]error:&error];
    expect(value).to.equal([NSNumber numberWithBool:YES]);
    [valueTransformer transformValue:@"y" toValue:&value ofClass:[NSNumber class] error:&error];
    expect(value).to.equal([NSNumber numberWithBool:YES]);
    [valueTransformer transformValue:@"Y" toValue:&value ofClass:[NSNumber class] error:&error];
    expect(value).to.equal([NSNumber numberWithBool:YES]);
    
    // False
    [valueTransformer transformValue:@"false" toValue:&value ofClass:[NSNumber class] error:&error];
    expect(value).to.equal([NSNumber numberWithBool:NO]);
    [valueTransformer transformValue:@"FALSE" toValue:&value ofClass:[NSNumber class] error:&error];
    expect(value).to.equal([NSNumber numberWithBool:NO]);
    [valueTransformer transformValue:@"f" toValue:&value ofClass:[NSNumber class] error:&error];
    expect(value).to.equal([NSNumber numberWithBool:NO]);
    [valueTransformer transformValue:@"F" toValue:&value ofClass:[NSNumber class] error:&error];
    expect(value).to.equal([NSNumber numberWithBool:NO]);
    [valueTransformer transformValue:@"no" toValue:&value ofClass:[NSNumber class] error:&error];
    expect(value).to.equal([NSNumber numberWithBool:NO]);
    [valueTransformer transformValue:@"NO" toValue:&value ofClass:[NSNumber class] error:&error];
    expect(value).to.equal([NSNumber numberWithBool:NO]);
    [valueTransformer transformValue:@"f" toValue:&value ofClass:[NSNumber class] error:&error];
    expect(value).to.equal([NSNumber numberWithBool:NO]);
    [valueTransformer transformValue:@"F" toValue:&value ofClass:[NSNumber class] error:&error];
    expect(value).to.equal([NSNumber numberWithBool:NO]);
}

- (void)testNumberToStringTransformerFailureWithUntransformableInputValue
{
    RKValueTransformer *valueTransformer = [RKValueTransformer numberToStringValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@[] toValue:&value ofClass:[NSNumber class] error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorUntransformableInputValue);
}

- (void)testNumberToStringTransformerTransformsNonsenseStringToZero
{
    RKValueTransformer *valueTransformer = [RKValueTransformer numberToStringValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@":*7vxck#sf#adsa" toValue:&value ofClass:[NSNumber class] error:&error];
    expect(success).to.beTruthy();
    expect(value).to.equal(0);
}

- (void)testNumberToStringTransformerFailureWithInvalidDestinationClass
{
    RKValueTransformer *valueTransformer = [RKValueTransformer numberToStringValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@12345 toValue:&value ofClass:[NSData class] error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorUnsupportedOutputClass);
}

#pragma mark Array to Ordered Set

- (void)testArrayToOrderedSetTransformerValidationSuccessFromArrayToOrderedSet
{
    RKValueTransformer *valueTransformer = [RKValueTransformer arrayToOrderedSetValueTransformer];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSArray class] toClass:[NSOrderedSet class]];
    expect(success).to.beTruthy();
}

- (void)testArrayToOrderedSetTransformerValidationSuccessFromOrderedSetToArray
{
    RKValueTransformer *valueTransformer = [RKValueTransformer arrayToOrderedSetValueTransformer];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSArray class] toClass:[NSOrderedSet class]];
    expect(success).to.beTruthy();
}

- (void)testArrayToOrderedSetTransformerValidationFailure
{
    RKValueTransformer *valueTransformer = [RKValueTransformer arrayToOrderedSetValueTransformer];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSNumber class] toClass:[NSOrderedSet class]];
    expect(success).to.beFalsy();
}

- (void)testArrayToOrderedSetTransformerTransformationSuccessFromArrayToOrderedSet
{
    RKValueTransformer *valueTransformer = [RKValueTransformer arrayToOrderedSetValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@[ @"one", @"two", @"three" ] toValue:&value ofClass:[NSOrderedSet class] error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSOrderedSet class]);
    expect(value).to.equal(([NSOrderedSet orderedSetWithArray:@[ @"one", @"two", @"three" ]]));
}

- (void)testArrayToOrderedSetTransformerTransformationSuccessFromOrderedSetToArray
{
    RKValueTransformer *valueTransformer = [RKValueTransformer arrayToOrderedSetValueTransformer];
    NSString *value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:[NSOrderedSet orderedSetWithArray:@[ @"one", @"two", @"three" ]] toValue:&value ofClass:[NSArray class] error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSArray class]);
    expect(value).to.equal((@[ @"one", @"two", @"three" ]));
}

- (void)testArrayToOrderedSetTransformerFailureWithUntransformableInputValue
{
    RKValueTransformer *valueTransformer = [RKValueTransformer arrayToOrderedSetValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@12345 toValue:&value ofClass:[NSOrderedSet class] error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorUntransformableInputValue);
}

- (void)testArrayToOrderedSetTransformerFailureWithInvalidDestinationClass
{
    RKValueTransformer *valueTransformer = [RKValueTransformer arrayToOrderedSetValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@[] toValue:&value ofClass:[NSData class] error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorUnsupportedOutputClass);
}

#pragma mark Array to Set

- (void)testArrayToSetTransformerValidationSuccessFromArrayToSet
{
    RKValueTransformer *valueTransformer = [RKValueTransformer arrayToSetValueTransformer];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSArray class] toClass:[NSSet class]];
    expect(success).to.beTruthy();
}

- (void)testArrayToSetTransformerValidationSuccessFromSetToArray
{
    RKValueTransformer *valueTransformer = [RKValueTransformer arrayToSetValueTransformer];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSArray class] toClass:[NSSet class]];
    expect(success).to.beTruthy();
}

- (void)testArrayToSetTransformerValidationFailure
{
    RKValueTransformer *valueTransformer = [RKValueTransformer arrayToSetValueTransformer];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSNumber class] toClass:[NSSet class]];
    expect(success).to.beFalsy();
}

- (void)testArrayToSetTransformerTransformationSuccessFromArrayToSet
{
    RKValueTransformer *valueTransformer = [RKValueTransformer arrayToSetValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@[ @"one", @"two", @"three" ] toValue:&value ofClass:[NSSet class] error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSSet class]);
    expect(value).to.equal(([NSSet setWithArray:@[ @"one", @"two", @"three" ]]));
}

- (void)testArrayToSetTransformerTransformationSuccessFromSetToArray
{
    RKValueTransformer *valueTransformer = [RKValueTransformer arrayToSetValueTransformer];
    NSString *value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:[NSSet setWithArray:@[ @"one", @"two", @"three" ]] toValue:&value ofClass:[NSSet class] error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSArray class]);
    expect(value).to.equal((@[ @"one", @"two", @"three" ]));
}

- (void)testArrayToSetTransformerFailureWithUntransformableInputValue
{
    RKValueTransformer *valueTransformer = [RKValueTransformer arrayToSetValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@12345 toValue:&value ofClass:[NSArray class] error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorUntransformableInputValue);
}

- (void)testArrayToSetTransformerFailureWithInvalidDestinationClass
{
    RKValueTransformer *valueTransformer = [RKValueTransformer arrayToSetValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@[] toValue:&value ofClass:[NSData class] error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorUnsupportedOutputClass);
}

#pragma mark Decimal Number to String

- (void)testDecimalNumberToStringTransformerValidationSuccessFromDecimalNumberToString
{
    RKValueTransformer *valueTransformer = [RKValueTransformer decimalNumberToStringValueTransformer];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSDecimalNumber class] toClass:[NSString class]];
    expect(success).to.beTruthy();
}

- (void)testDecimalNumberToStringTransformerValidationSuccessFromStringToDecimalNumber
{
    RKValueTransformer *valueTransformer = [RKValueTransformer decimalNumberToStringValueTransformer];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSString class] toClass:[NSDecimalNumber class]];
    expect(success).to.beTruthy();
}

- (void)testDecimalNumberToStringTransformerValidationFailure
{
    RKValueTransformer *valueTransformer = [RKValueTransformer decimalNumberToStringValueTransformer];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSNumber class] toClass:[NSString class]];
    expect(success).to.beFalsy();
}

- (void)testDecimalNumberToStringTransformerTransformationSuccessFromDecimalNumberToString
{
    RKValueTransformer *valueTransformer = [RKValueTransformer decimalNumberToStringValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:[NSDecimalNumber decimalNumberWithString:@"123456.7890"] toValue:&value ofClass:[NSString class] error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSString class]);
    expect(value).to.equal(@"123456.789");
}

- (void)testDecimalNumberToStringTransformerTransformationSuccessFromStringToDecimalNumber
{
    RKValueTransformer *valueTransformer = [RKValueTransformer decimalNumberToStringValueTransformer];
    NSString *value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@"123456.7890" toValue:&value ofClass:[NSDecimalNumber class] error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSDecimalNumber class]);
    expect(value).to.equal([NSDecimalNumber decimalNumberWithString:@"123456.7890"]);
}

- (void)testDecimalNumberToStringTransformerFailureWithUntransformableInputValue
{
    RKValueTransformer *valueTransformer = [RKValueTransformer decimalNumberToStringValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@[] toValue:&value ofClass:[NSString class] error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorUntransformableInputValue);
}

- (void)testDecimalNumberToStringTransformerFailureWithTransformationFailure
{
    RKValueTransformer *valueTransformer = [RKValueTransformer decimalNumberToStringValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@"abdskjfsdkfjs" toValue:&value ofClass:[NSDecimalNumber class] error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorTransformationFailed);
}

- (void)testDecimalNumberToStringTransformerFailureWithInvalidDestinationClass
{
    RKValueTransformer *valueTransformer = [RKValueTransformer decimalNumberToStringValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@"12345.00" toValue:&value ofClass:[NSData class] error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorUnsupportedOutputClass);
}

#pragma mark Decimal Number to Number

- (void)testDecimalNumberToNumberTransformerValidationSuccessFromDecimalNumberToNumber
{
    RKValueTransformer *valueTransformer = [RKValueTransformer decimalNumberToNumberValueTransformer];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSDecimalNumber class] toClass:[NSNumber class]];
    expect(success).to.beTruthy();
}

- (void)testDecimalNumberToNumberTransformerValidationSuccessFromNumberToDecimalNumber
{
    RKValueTransformer *valueTransformer = [RKValueTransformer decimalNumberToNumberValueTransformer];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSNumber class] toClass:[NSDecimalNumber class]];
    expect(success).to.beTruthy();
}

- (void)testDecimalNumberToNumberTransformerValidationFailure
{
    RKValueTransformer *valueTransformer = [RKValueTransformer decimalNumberToNumberValueTransformer];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSNumber class] toClass:[NSNumber class]];
    expect(success).to.beFalsy();
}

- (void)testDecimalNumberToNumberTransformerTransformationSuccessFromDecimalNumberToNumber
{
    RKValueTransformer *valueTransformer = [RKValueTransformer decimalNumberToNumberValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:[NSDecimalNumber decimalNumberWithString:@"123456.7890"] toValue:&value ofClass:[NSNumber class] error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSNumber class]);
    expect(value).to.equal([NSDecimalNumber decimalNumberWithString:@"123456.7890"]);
}

- (void)testDecimalNumberToNumberTransformerTransformationSuccessFromNumberToDecimalNumber
{
    RKValueTransformer *valueTransformer = [RKValueTransformer decimalNumberToNumberValueTransformer];
    NSNumber *value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@123456.7890 toValue:&value ofClass:[NSDecimalNumber class] error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSDecimalNumber class]);
    expect(value).to.equal([NSDecimalNumber decimalNumberWithString:@"123456.7890"]);
}

- (void)testDecimalNumberToNumberTransformerFailureWithUntransformableInputValue
{
    RKValueTransformer *valueTransformer = [RKValueTransformer decimalNumberToNumberValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@[] toValue:&value ofClass:[NSNumber class] error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorUntransformableInputValue);
}

- (void)testDecimalNumberToNumberTransformerFailureWithInvalidDestinationClass
{
    RKValueTransformer *valueTransformer = [RKValueTransformer decimalNumberToNumberValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@12345 toValue:&value ofClass:[NSData class] error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorUnsupportedOutputClass);
}

#pragma mark Null

- (void)testNullTransformerValidationSuccessFromObjectToObject
{
    RKValueTransformer *valueTransformer = [RKValueTransformer nullValueTransformer];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSObject class] toClass:[NSObject class]];
    expect(success).to.beTruthy();
}

- (void)testNullTransformerTransformationSuccessFromNullToNil
{
    RKValueTransformer *valueTransformer = [RKValueTransformer nullValueTransformer];
    NSNumber *value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:[NSNull null] toValue:&value ofClass:Nil error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beNil();
}

- (void)testNullTransformerFailureWithUntransformableInputValue
{
    RKValueTransformer *valueTransformer = [RKValueTransformer nullValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@12345 toValue:&value ofClass:Nil error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorUntransformableInputValue);
}

- (void)testDecimalNumberToNumberTransformerSucceedsWithAnyOutputClass
{
    RKValueTransformer *valueTransformer = [RKValueTransformer nullValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:[NSNull null] toValue:&value ofClass:[NSData class] error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beNil();
}

#pragma mark Keyed Archiving

- (void)testKeyedArchivingTransformerValidationSuccessFromNSCodingCompliantToData
{
    RKValueTransformer *valueTransformer = [RKValueTransformer keyedArchivingValueTransformer];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSDictionary class] toClass:[NSData class]];
    expect(success).to.beTruthy();
}

- (void)testKeyedArchivingTransformerValidationSuccessFromDataToNSCodingCompliant
{
    RKValueTransformer *valueTransformer = [RKValueTransformer keyedArchivingValueTransformer];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSData class] toClass:[NSDictionary class]];
    expect(success).to.beTruthy();
}

- (void)testKeyedArchivingTransformerValidationFailure
{
    RKValueTransformer *valueTransformer = [RKValueTransformer keyedArchivingValueTransformer];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSData class] toClass:[NSObject class]];
    expect(success).to.beFalsy();
}

- (void)testKeyedArchivingTransformerSuccessFromDataToDictionary
{
    RKValueTransformer *valueTransformer = [RKValueTransformer keyedArchivingValueTransformer];
    NSDictionary *dictionary = @{ @"key": @"value" };
    NSData *data = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:dictionary toValue:&data ofClass:[NSData class] error:&error];
    expect(success).to.beTruthy();
    expect(data).notTo.beNil();
    id<NSCoding> decodedObject = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    expect(decodedObject).to.equal(dictionary);
}

- (void)testKeyedArchivingTransformerSuccessFromDictionaryToData
{
    RKValueTransformer *valueTransformer = [RKValueTransformer keyedArchivingValueTransformer];
    NSDictionary *dictionary = @{ @"key": @"value" };
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dictionary];
    NSError *error = nil;
    id<NSCoding> result = nil;
    BOOL success = [valueTransformer transformValue:data toValue:&result ofClass:[NSDictionary class] error:&error];
    expect(success).to.beTruthy();
    expect(result).notTo.beNil();
    expect(result).to.equal(dictionary);
}

- (void)testKeyedArchivingTransformerFailureWithInvalidInputValue
{
    RKValueTransformer *valueTransformer = [RKValueTransformer keyedArchivingValueTransformer];
    id<NSCoding> result = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:[NSObject new] toValue:&result ofClass:[NSData class] error:&error];
    expect(success).to.beFalsy();
    expect(result).to.beNil();
    expect(error.code).to.equal(RKValueTransformationErrorUntransformableInputValue);
}

- (void)testKeyedArchivingTransformerFailureWithNonDecodableData
{
    RKValueTransformer *valueTransformer = [RKValueTransformer keyedArchivingValueTransformer];
    id<NSCoding> result = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:[@"this is invalid" dataUsingEncoding:NSUTF8StringEncoding] toValue:&result ofClass:[NSDictionary class] error:&error];
    expect(success).to.beFalsy();
    expect(result).to.beNil();
    expect(error.code).to.equal(RKValueTransformationErrorTransformationFailed);
}

- (void)testKeyedArchivingTransformerFailureWithInvalidDestinationClass
{
    RKValueTransformer *valueTransformer = [RKValueTransformer keyedArchivingValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@{ @"key": @"value" } toValue:&value ofClass:[NSString class] error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorUnsupportedOutputClass);
}

- (void)testKeyedArchivingTransformerFailureDueToDesintationTypeMismatch
{
    RKValueTransformer *valueTransformer = [RKValueTransformer keyedArchivingValueTransformer];
    id value = nil;
    NSError *error = nil;
    NSDictionary *dictionary = @{ @"key": @"value" };
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dictionary];
    BOOL success = [valueTransformer transformValue:data toValue:&value ofClass:[NSArray class] error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorTransformationFailed);
}

#pragma mark - Time Interval Since 1970 to Date

- (void)testTimeIntervalSince1970ToDateValueTransformerValidationSuccessFromNumberToDate
{
    RKValueTransformer *valueTransformer = [RKValueTransformer timeIntervalSince1970ToDateValueTransformer];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSNumber class] toClass:[NSDate class]];
    expect(success).to.beTruthy();
}

- (void)testTimeIntervalSince1970ToDateValueTransformerValidationSuccessFromStringToDate
{
    RKValueTransformer *valueTransformer = [RKValueTransformer timeIntervalSince1970ToDateValueTransformer];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSString class] toClass:[NSDate class]];
    expect(success).to.beTruthy();
}

- (void)testTimeIntervalSince1970ToDateValueTransformerValidationSuccessFromDateToNumber
{
    RKValueTransformer *valueTransformer = [RKValueTransformer timeIntervalSince1970ToDateValueTransformer];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSDate class] toClass:[NSNumber class]];
    expect(success).to.beTruthy();
}

- (void)testTimeIntervalSince1970ToDateValueTransformerValidationSuccessFromDateToString
{
    RKValueTransformer *valueTransformer = [RKValueTransformer timeIntervalSince1970ToDateValueTransformer];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSDate class] toClass:[NSString class]];
    expect(success).to.beTruthy();
}

- (void)testTimeIntervalSince1970ToDateValueTransformerValidationFailure
{
    RKValueTransformer *valueTransformer = [RKValueTransformer timeIntervalSince1970ToDateValueTransformer];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSNumber class] toClass:[NSURL class]];
    expect(success).to.beFalsy();
}

- (void)testTimeIntervalSince1970ToDateValueTransformerTransformationSuccessFromNumberToDate
{
    RKValueTransformer *valueTransformer = [RKValueTransformer timeIntervalSince1970ToDateValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@0 toValue:&value ofClass:[NSDate class] error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSDate class]);
    expect([value description]).to.equal(@"1970-01-01 00:00:00 +0000");
}

- (void)testTimeIntervalSince1970ToDateValueTransformerTransformationSuccessFromStringToDate
{
    RKValueTransformer *valueTransformer = [RKValueTransformer timeIntervalSince1970ToDateValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@"0" toValue:&value ofClass:[NSDate class] error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSDate class]);
    expect([value description]).to.equal(@"1970-01-01 00:00:00 +0000");
}

- (void)testTimeIntervalSince1970ToDateValueTransformerTransformationSuccessFromDateToNumber
{
    RKValueTransformer *valueTransformer = [RKValueTransformer timeIntervalSince1970ToDateValueTransformer];
    id value = nil;
    NSError *error = nil;
    NSDate *inputValue = [NSDate dateWithTimeIntervalSince1970:0];
    BOOL success = [valueTransformer transformValue:inputValue toValue:&value ofClass:[NSNumber class] error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSNumber class]);
    expect(value).to.equal(0);
}

- (void)testTimeIntervalSince1970ToDateValueTransformerTransformationSuccessFromDateToString
{
    RKValueTransformer *valueTransformer = [RKValueTransformer timeIntervalSince1970ToDateValueTransformer];
    id value = nil;
    NSError *error = nil;
    NSDate *inputValue = [NSDate dateWithTimeIntervalSince1970:0];
    BOOL success = [valueTransformer transformValue:inputValue toValue:&value ofClass:[NSString class] error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSString class]);
    expect(value).to.equal(@"0");
}

- (void)testTimeIntervalSince1970ToDateValueTransformerFailureWithUntransformableInputValue
{
    RKValueTransformer *valueTransformer = [RKValueTransformer timeIntervalSince1970ToDateValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@[] toValue:&value ofClass:[NSString class] error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorUntransformableInputValue);
}

- (void)testTimeIntervalSince1970ToDateValueTransformerFailureWithInvalidInputValue
{
    RKValueTransformer *valueTransformer = [RKValueTransformer timeIntervalSince1970ToDateValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@":*7vxck#sf#adsa" toValue:&value ofClass:[NSDate class] error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorTransformationFailed);
}

- (void)testTimeIntervalSince1970ToDateValueTransformerFailureWithInvalidDestinationClass
{
    RKValueTransformer *valueTransformer = [RKValueTransformer timeIntervalSince1970ToDateValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@"http://restkit.org" toValue:&value ofClass:[NSData class] error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorUnsupportedOutputClass);
}

#pragma mark Mutable Value

- (void)testMutableValueTransformerValidationSuccessFromString
{
    RKValueTransformer *valueTransformer = [RKValueTransformer mutableValueTransformer];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSString class] toClass:[NSMutableString class]];
    expect(success).to.beTruthy();
}

- (void)testMutableValueTransformerValidationSuccessFromArray
{
    RKValueTransformer *valueTransformer = [RKValueTransformer mutableValueTransformer];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSArray class] toClass:[NSMutableArray class]];
    expect(success).to.beTruthy();
}

- (void)testMutableValueTransformerValidationSuccessFromSet
{
    RKValueTransformer *valueTransformer = [RKValueTransformer mutableValueTransformer];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSSet class] toClass:[NSMutableSet class]];
    expect(success).to.beTruthy();
}

- (void)testMutableValueTransformerValidationFailure
{
    RKValueTransformer *valueTransformer = [RKValueTransformer mutableValueTransformer];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSNumber class] toClass:[NSURL class]];
    expect(success).to.beFalsy();
}

- (void)testMutableValueTransformerTransformationSuccessFromString
{
    RKValueTransformer *valueTransformer = [RKValueTransformer mutableValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@"http://restkit.org" toValue:&value ofClass:[NSMutableString class] error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSMutableString class]);
    expect(value).to.equal([NSMutableString stringWithString:@"http://restkit.org"]);
}

- (void)testMutableValueTransformerTransformationSuccessFromArray
{
    RKValueTransformer *valueTransformer = [RKValueTransformer mutableValueTransformer];
    NSString *value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@[ @"one", @"two" ] toValue:&value ofClass:[NSMutableArray class] error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSMutableArray class]);
    expect(value).to.equal(([NSMutableArray arrayWithObjects:@"one", @"two", nil]));
}

- (void)testMutableValueTransformerFailureWithUntransformableInputValue
{
    RKValueTransformer *valueTransformer = [RKValueTransformer mutableValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@12345 toValue:&value ofClass:[NSString class] error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorUntransformableInputValue);
}

- (void)testMutableValueTransformerFailureWithInvalidDestinationClass
{
    RKValueTransformer *valueTransformer = [RKValueTransformer mutableValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@"http://restkit.org" toValue:&value ofClass:[NSData class] error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorUnsupportedOutputClass);
}

#pragma mark Copyable Object to NSDictionary

- (void)testKeyOfDictionaryValueTransformerValidationSuccessFromCopyableToDictionary
{
    RKValueTransformer *valueTransformer = [RKValueTransformer keyOfDictionaryValueTransformer];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSString class] toClass:[NSDictionary class]];
    expect(success).to.beTruthy();
}

- (void)testKeyOfDictionaryValueTransformerValidationSuccessFromCopyableToMutableDictionary
{
    RKValueTransformer *valueTransformer = [RKValueTransformer keyOfDictionaryValueTransformer];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSString class] toClass:[NSMutableDictionary class]];
    expect(success).to.beTruthy();
}

- (void)testKeyOfDictionaryValueTransformerValidationFailure
{
    RKValueTransformer *valueTransformer = [RKValueTransformer keyOfDictionaryValueTransformer];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSObject class] toClass:[NSDictionary class]];
    expect(success).to.beFalsy();
}

- (void)testKeyOfDictionaryValueTransformerTransformationSuccessFromStringToDictionary
{
    RKValueTransformer *valueTransformer = [RKValueTransformer keyOfDictionaryValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@"key" toValue:&value ofClass:[NSDictionary class] error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSDictionary class]);
    expect(value).to.equal(@{ @"key": @{}});
}

- (void)testKeyOfDictionaryValueTransformerTransformationSuccessFromStringToNSMutableDictionary
{
    RKValueTransformer *valueTransformer = [RKValueTransformer keyOfDictionaryValueTransformer];
    NSString *value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@"key" toValue:&value ofClass:[NSMutableDictionary class] error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSMutableDictionary class]);
    expect(value).to.equal(([@{ @"key": [@{} mutableCopy] } mutableCopy]));
}

- (void)testKeyOfDictionaryValueTransformerFailureWithUntransformableInputValue
{
    RKValueTransformer *valueTransformer = [RKValueTransformer keyOfDictionaryValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:[NSObject new] toValue:&value ofClass:[NSDictionary class] error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorUntransformableInputValue);
}

- (void)testKeyOfDictionaryValueTransformerFailureWithInvalidDestinationClass
{
    RKValueTransformer *valueTransformer = [RKValueTransformer keyOfDictionaryValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@"key" toValue:&value ofClass:[NSNumber class] error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorUnsupportedOutputClass);
}

@end

static RKBlockValueTransformer *RKTestValueTransformerWithOutputValue(id staticOutputValue)
{
    return [RKBlockValueTransformer valueTransformerWithValidationBlock:nil transformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, Class outputValueClass, NSError *__autoreleasing *error) {
        *outputValue = staticOutputValue;
        return YES;
    }];
}

@interface RKCompoundValueTransformerTest : SenTestCase
@end

@implementation RKCompoundValueTransformerTest

- (void)testAddingValueTransformer
{
    RKCompoundValueTransformer *compoundValueTransformer = [RKCompoundValueTransformer new];
    expect([compoundValueTransformer numberOfValueTransformers]).to.equal(0);
    [compoundValueTransformer addValueTransformer:RKTestValueTransformerWithOutputValue(@"OK")];
    expect([compoundValueTransformer numberOfValueTransformers]).to.equal(1);
}

- (void)testRemovingValueTransformer
{
    RKCompoundValueTransformer *compoundValueTransformer = [RKCompoundValueTransformer new];
    expect([compoundValueTransformer numberOfValueTransformers]).to.equal(0);
    RKValueTransformer *addedTransformer = RKTestValueTransformerWithOutputValue(@"OK");
    [compoundValueTransformer addValueTransformer:addedTransformer];
    expect([compoundValueTransformer numberOfValueTransformers]).to.equal(1);
    [compoundValueTransformer removeValueTransformer:RKTestValueTransformerWithOutputValue(@"invalid")];
    expect([compoundValueTransformer numberOfValueTransformers]).to.equal(1);
    [compoundValueTransformer removeValueTransformer:addedTransformer];
    expect([compoundValueTransformer numberOfValueTransformers]).to.equal(0);
}

- (void)testInsertingValueTransformer
{
    RKCompoundValueTransformer *compoundValueTransformer = [RKCompoundValueTransformer new];
    RKValueTransformer *firstTransformer = RKTestValueTransformerWithOutputValue(@"1");
    [compoundValueTransformer addValueTransformer:firstTransformer];
    RKValueTransformer *secondTransformer = RKTestValueTransformerWithOutputValue(@"2");
    [compoundValueTransformer addValueTransformer:secondTransformer];
    RKValueTransformer *thirdTransformer = RKTestValueTransformerWithOutputValue(@"3");
    [compoundValueTransformer insertValueTransformer:thirdTransformer atIndex:0];
    NSArray *valueTransformers = [compoundValueTransformer valueTransformersForTransformingFromClass:Nil toClass:Nil];
    expect(valueTransformers[0]).to.equal(thirdTransformer);
}

- (void)testRetrievingValueTransformersBySourceToDestinationClass
{
    RKCompoundValueTransformer *compoundValueTransformer = [RKCompoundValueTransformer new];
    RKValueTransformer *stringToValueTransformer = [RKBlockValueTransformer valueTransformerWithValidationBlock:^BOOL(__unsafe_unretained Class sourceClass, __unsafe_unretained Class destinationClass) {
        return [sourceClass isSubclassOfClass:[NSString class]] && [destinationClass isSubclassOfClass:[NSValue class]];
    } transformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, __unsafe_unretained Class outputClass, NSError *__autoreleasing *error) {
        return NO;
    }];
    [compoundValueTransformer addValueTransformer:stringToValueTransformer];
    RKValueTransformer *stringToNumberTransformer = [RKBlockValueTransformer valueTransformerWithValidationBlock:^BOOL(__unsafe_unretained Class sourceClass, __unsafe_unretained Class destinationClass) {
        return [sourceClass isSubclassOfClass:[NSString class]] && [destinationClass isSubclassOfClass:[NSNumber class]];
    } transformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, __unsafe_unretained Class outputClass, NSError *__autoreleasing *error) {
        return NO;
    }];
    [compoundValueTransformer addValueTransformer:stringToNumberTransformer];
    RKValueTransformer *stringToDecimalNumberTransformer = [RKBlockValueTransformer valueTransformerWithValidationBlock:^BOOL(__unsafe_unretained Class sourceClass, __unsafe_unretained Class destinationClass) {
        return [sourceClass isSubclassOfClass:[NSString class]] && [destinationClass isSubclassOfClass:[NSDecimalNumber class]];
    } transformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, __unsafe_unretained Class outputClass, NSError *__autoreleasing *error) {
        return NO;
    }];
    [compoundValueTransformer addValueTransformer:stringToDecimalNumberTransformer];
    RKValueTransformer *numberToStringValueTransformer = [RKBlockValueTransformer valueTransformerWithValidationBlock:^BOOL(__unsafe_unretained Class sourceClass, __unsafe_unretained Class destinationClass) {
        return [sourceClass isSubclassOfClass:[NSNumber class]] && [destinationClass isSubclassOfClass:[NSString class]];
    } transformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, __unsafe_unretained Class outputClass, NSError *__autoreleasing *error) {
        return NO;
    }];
    [compoundValueTransformer addValueTransformer:numberToStringValueTransformer];
    
    expect([compoundValueTransformer valueTransformersForTransformingFromClass:[NSString class] toClass:[NSValue class]]).to.equal((@[ stringToValueTransformer ]));
    expect([compoundValueTransformer valueTransformersForTransformingFromClass:[NSString class] toClass:[NSNumber class]]).to.equal((@[ stringToValueTransformer, stringToNumberTransformer ]));
    expect([compoundValueTransformer valueTransformersForTransformingFromClass:[NSString class] toClass:[NSDecimalNumber class]]).to.equal((@[ stringToValueTransformer, stringToNumberTransformer, stringToDecimalNumberTransformer ]));
    expect([compoundValueTransformer valueTransformersForTransformingFromClass:[NSNumber class] toClass:[NSString class]]).to.equal((@[ numberToStringValueTransformer ]));
    expect([compoundValueTransformer valueTransformersForTransformingFromClass:[NSNumber class] toClass:[NSArray class]]).to.beEmpty();
}

#pragma mark RKValueTransforming

- (void)testValidatingValueTransformation
{
    RKCompoundValueTransformer *compoundValueTransformer = [RKCompoundValueTransformer new];
    RKValueTransformer *stringToValueTransformer = [RKBlockValueTransformer valueTransformerWithValidationBlock:^BOOL(__unsafe_unretained Class sourceClass, __unsafe_unretained Class destinationClass) {
        return [sourceClass isSubclassOfClass:[NSString class]] && [destinationClass isSubclassOfClass:[NSValue class]];
    } transformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, __unsafe_unretained Class outputClass, NSError *__autoreleasing *error) {
        return NO;
    }];
    [compoundValueTransformer addValueTransformer:stringToValueTransformer];
    RKValueTransformer *stringToNumberTransformer = [RKBlockValueTransformer valueTransformerWithValidationBlock:^BOOL(__unsafe_unretained Class sourceClass, __unsafe_unretained Class destinationClass) {
        return [sourceClass isSubclassOfClass:[NSString class]] && [destinationClass isSubclassOfClass:[NSNumber class]];
    } transformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, __unsafe_unretained Class outputClass, NSError *__autoreleasing *error) {
        return NO;
    }];
    [compoundValueTransformer addValueTransformer:stringToNumberTransformer];
    RKValueTransformer *stringToDecimalNumberTransformer = [RKBlockValueTransformer valueTransformerWithValidationBlock:^BOOL(__unsafe_unretained Class sourceClass, __unsafe_unretained Class destinationClass) {
        return [sourceClass isSubclassOfClass:[NSString class]] && [destinationClass isSubclassOfClass:[NSDecimalNumber class]];
    } transformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, __unsafe_unretained Class outputClass, NSError *__autoreleasing *error) {
        return NO;
    }];
    [compoundValueTransformer addValueTransformer:stringToDecimalNumberTransformer];
    RKValueTransformer *numberToStringValueTransformer = [RKBlockValueTransformer valueTransformerWithValidationBlock:^BOOL(__unsafe_unretained Class sourceClass, __unsafe_unretained Class destinationClass) {
        return [sourceClass isSubclassOfClass:[NSNumber class]] && [destinationClass isSubclassOfClass:[NSString class]];
    } transformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, __unsafe_unretained Class outputClass, NSError *__autoreleasing *error) {
        return NO;
    }];
    [compoundValueTransformer addValueTransformer:numberToStringValueTransformer];
    
    expect([compoundValueTransformer validateTransformationFromClass:[NSString class] toClass:[NSValue class]]).to.beTruthy();
    expect([compoundValueTransformer validateTransformationFromClass:[NSString class] toClass:[NSNumber class]]).to.beTruthy();
    expect([compoundValueTransformer validateTransformationFromClass:[NSString class] toClass:[NSDecimalNumber class]]).to.beTruthy();
    expect([compoundValueTransformer validateTransformationFromClass:[NSNumber class] toClass:[NSString class]]).to.beTruthy();
    expect([compoundValueTransformer validateTransformationFromClass:[NSString class] toClass:[NSData class]]).to.beFalsy();
}

- (void)testTransformingValueSuccessfully
{
    RKCompoundValueTransformer *compoundValueTransformer = [RKCompoundValueTransformer new];
    RKValueTransformer *firstTransformer = RKTestValueTransformerWithOutputValue(@"1");
    [compoundValueTransformer addValueTransformer:firstTransformer];
    NSString *outputValue;
    NSError *error = nil;
    BOOL success = [compoundValueTransformer transformValue:@"2" toValue:&outputValue ofClass:[NSString class] error:&error];
    expect(success).to.beTruthy();
    expect(outputValue).to.equal(@"1");
}

- (void)testTransformingValueSuccessfullyRespectsOrderingOfTransformers
{
    RKCompoundValueTransformer *compoundValueTransformer = [RKCompoundValueTransformer new];
    [compoundValueTransformer addValueTransformer:RKTestValueTransformerWithOutputValue(@"1")];
    [compoundValueTransformer addValueTransformer:RKTestValueTransformerWithOutputValue(@"2")];
    [compoundValueTransformer insertValueTransformer:RKTestValueTransformerWithOutputValue(@"3") atIndex:0];
    NSString *outputValue;
    NSError *error = nil;
    BOOL success = [compoundValueTransformer transformValue:@"2" toValue:&outputValue ofClass:[NSString class] error:&error];
    expect(success).to.beTruthy();
    expect(outputValue).to.equal(@"3");
}

- (void)testTransformingValueFailsWithError
{
    RKCompoundValueTransformer *compoundValueTransformer = [RKCompoundValueTransformer new];
    [compoundValueTransformer addValueTransformer:[RKBlockValueTransformer valueTransformerWithValidationBlock:nil transformationBlock:^BOOL(id inputValue, __autoreleasing id *outputValue, __unsafe_unretained Class outputClass, NSError *__autoreleasing *error) {
        // Always fails
        RKValueTransformerTestTransformation(NO, error, @"This is an underlying error.");
        return YES;
    }]];
    NSString *outputValue;
    NSError *error = nil;
    BOOL success = [compoundValueTransformer transformValue:@"2" toValue:&outputValue ofClass:[NSString class] error:&error];
    expect(success).to.beFalsy();
    expect(outputValue).to.beNil();
    expect(error.code).to.equal(RKValueTransformationErrorTransformationFailed);
    expect(error.localizedDescription).to.equal(@"Failed transformation of value '2' to NSString: none of the 1 value transformers consulted were successful.");
}

#pragma mark NSCopying

- (void)testCopying
{
    RKCompoundValueTransformer *compoundValueTransformer = [RKCompoundValueTransformer new];
    RKValueTransformer *firstTransformer = RKTestValueTransformerWithOutputValue(@"1");
    [compoundValueTransformer addValueTransformer:firstTransformer];
    RKValueTransformer *secondTransformer = RKTestValueTransformerWithOutputValue(@"2");
    [compoundValueTransformer addValueTransformer:secondTransformer];
    RKCompoundValueTransformer *copiedTransformer = [compoundValueTransformer copy];
    expect(copiedTransformer).notTo.beNil();
    NSArray *valueTransformers = [copiedTransformer valueTransformersForTransformingFromClass:Nil toClass:Nil];
    expect(valueTransformers).to.equal((@[ firstTransformer, secondTransformer ]));
}

#pragma mark NSFastEnumeration

- (void)testFastEnumeration
{
    RKCompoundValueTransformer *compoundValueTransformer = [RKCompoundValueTransformer new];
    RKValueTransformer *firstTransformer = RKTestValueTransformerWithOutputValue(@"1");
    [compoundValueTransformer addValueTransformer:firstTransformer];
    RKValueTransformer *secondTransformer = RKTestValueTransformerWithOutputValue(@"2");
    [compoundValueTransformer addValueTransformer:secondTransformer];
    NSMutableArray *enumeratedTransformers = [NSMutableArray new];
    for (id<RKValueTransforming> valueTransformer in compoundValueTransformer) {
        [enumeratedTransformers addObject:valueTransformer];
    }
    expect(enumeratedTransformers).to.equal((@[ firstTransformer, secondTransformer ]));
}

@end

@interface RKValueTransformers_NSNumberFormatterTests : SenTestCase
@end

@implementation RKValueTransformers_NSNumberFormatterTests

- (void)testValidationFromStringToNumber
{
    NSNumberFormatter *valueTransformer = [NSNumberFormatter new];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSString class] toClass:[NSNumber class]];
    expect(success).to.beTruthy();
}

- (void)testValidationFromNumberToString
{
    NSNumberFormatter *valueTransformer = [NSNumberFormatter new];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSNumber class] toClass:[NSString class]];
    expect(success).to.beTruthy();
}

- (void)testValidationFailure
{
    NSNumberFormatter *valueTransformer = [NSNumberFormatter new];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSURL class] toClass:[NSString class]];
    expect(success).to.beFalsy();
}

- (void)testTransformationFromNumberToString
{
    NSNumberFormatter *valueTransformer = [NSNumberFormatter new];
    valueTransformer.numberStyle = NSNumberFormatterCurrencyStyle;
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@932480932840923 toValue:&value ofClass:[NSString class] error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSString class]);
    expect(value).to.equal(@"$932,480,932,840,923.00");
}

- (void)testTransformationFromStringToNumber
{
    NSNumberFormatter *valueTransformer = [NSNumberFormatter new];
    valueTransformer.numberStyle = NSNumberFormatterCurrencyStyle;
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@"$932,480,932,840,923.00" toValue:&value ofClass:[NSNumber class] error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSNumber class]);
    expect(value).to.equal(@932480932840923);
}

- (void)testTransformationFailureWithUntransformableInputValue
{
    NSNumberFormatter *valueTransformer = [NSNumberFormatter new];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@[] toValue:&value ofClass:[NSString class] error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorUntransformableInputValue);
}

- (void)testTransformationFailureFailureWithInvalidInputValue
{
    NSNumberFormatter *valueTransformer = [NSNumberFormatter new];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@":*7vxck#sf#adsa" toValue:&value ofClass:[NSNumber class] error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorTransformationFailed);
}

- (void)testTransformationFailureWithInvalidDestinationClass
{
    NSNumberFormatter *valueTransformer = [NSNumberFormatter new];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@"http://restkit.org" toValue:&value ofClass:[NSData class] error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorUnsupportedOutputClass);
}

@end

@interface RKValueTransformers_NSDateFormatterTests : SenTestCase
@end

@implementation RKValueTransformers_NSDateFormatterTests

- (void)testValidationFromStringToDate
{
    NSDateFormatter *valueTransformer = [NSDateFormatter new];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSString class] toClass:[NSDate class]];
    expect(success).to.beTruthy();
}

- (void)testValidationFromDateToString
{
    NSDateFormatter *valueTransformer = [NSDateFormatter new];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSDate class] toClass:[NSString class]];
    expect(success).to.beTruthy();
}

- (void)testValidationFailure
{
    NSDateFormatter *valueTransformer = [NSDateFormatter new];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSURL class] toClass:[NSString class]];
    expect(success).to.beFalsy();
}

- (void)testTransformationFromDateToString
{
    NSDateFormatter *valueTransformer = [NSDateFormatter new];
    valueTransformer.dateStyle = NSDateFormatterFullStyle;
    valueTransformer.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    valueTransformer.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:[NSDate dateWithTimeIntervalSince1970:0] toValue:&value ofClass:[NSString class] error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSString class]);
    expect(value).to.equal(@"Thursday, January 1, 1970");
}

- (void)testTransformationFromStringToDAte
{
    NSDateFormatter *valueTransformer = [NSDateFormatter new];
    valueTransformer.dateStyle = NSDateFormatterFullStyle;
    valueTransformer.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    valueTransformer.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@"Thursday, January 1, 1970" toValue:&value ofClass:[NSDate class] error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSDate class]);
    expect([value description]).to.equal(@"1970-01-01 00:00:00 +0000");
}

- (void)testTransformationFailureWithUntransformableInputValue
{
    NSDateFormatter *valueTransformer = [NSDateFormatter new];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@[] toValue:&value ofClass:[NSString class] error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorUntransformableInputValue);
}

- (void)testTransformationFailureFailureWithInvalidInputValue
{
    NSDateFormatter *valueTransformer = [NSDateFormatter new];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@":*7vxck#sf#adsa" toValue:&value ofClass:[NSDate class] error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorTransformationFailed);
}

- (void)testTransformationFailureWithInvalidDestinationClass
{
    NSDateFormatter *valueTransformer = [NSDateFormatter new];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@"http://restkit.org" toValue:&value ofClass:[NSData class] error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorUnsupportedOutputClass);
}

@end

@interface RKValueTransformers_RKISO8601DateFormatterTests : SenTestCase
@end

@implementation RKValueTransformers_RKISO8601DateFormatterTests

- (void)testValidationFromStringToDate
{
    RKISO8601DateFormatter *valueTransformer = [RKISO8601DateFormatter new];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSString class] toClass:[NSDate class]];
    expect(success).to.beTruthy();
}

- (void)testValidationFromDateToString
{
    RKISO8601DateFormatter *valueTransformer = [RKISO8601DateFormatter new];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSDate class] toClass:[NSString class]];
    expect(success).to.beTruthy();
}

- (void)testValidationFailure
{
    RKISO8601DateFormatter *valueTransformer = [RKISO8601DateFormatter new];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSURL class] toClass:[NSString class]];
    expect(success).to.beFalsy();
}

- (void)testTransformationFromDateToString
{
    RKISO8601DateFormatter *valueTransformer = [RKISO8601DateFormatter new];
    valueTransformer.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    valueTransformer.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    valueTransformer.includeTime = YES;
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:[NSDate dateWithTimeIntervalSince1970:0] toValue:&value ofClass:[NSString class] error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSString class]);
    expect(value).to.equal(@"1970-01-01T00:00:00Z");
}

- (void)testTransformationFromStringToDAte
{
    RKISO8601DateFormatter *valueTransformer = [RKISO8601DateFormatter new];
    valueTransformer.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    valueTransformer.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    valueTransformer.includeTime = YES;
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@"1970-01-01T00:00:00Z" toValue:&value ofClass:[NSDate class] error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSDate class]);
    expect([value description]).to.equal(@"1970-01-01 00:00:00 +0000");
}

- (void)testTransformationFailureWithUntransformableInputValue
{
    RKISO8601DateFormatter *valueTransformer = [RKISO8601DateFormatter new];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@[] toValue:&value ofClass:[NSString class] error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorUntransformableInputValue);
}

- (void)testTransformationFailureFailureWithInvalidInputValue
{
    RKISO8601DateFormatter *valueTransformer = [RKISO8601DateFormatter new];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@":*7vxck#sf#adsa" toValue:&value ofClass:[NSDate class] error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorTransformationFailed);
}

- (void)testTransformationFailureWithInvalidDestinationClass
{
    RKISO8601DateFormatter *valueTransformer = [RKISO8601DateFormatter new];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@"http://restkit.org" toValue:&value ofClass:[NSData class] error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorUnsupportedOutputClass);
}

@end


// test objectToCollectionValueTransformer, mutableValueTransformer
