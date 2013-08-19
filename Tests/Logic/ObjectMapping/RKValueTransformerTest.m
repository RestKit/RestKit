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

@interface RKValueTransformerTest : SenTestCase
@end

@implementation RKValueTransformerTest

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
    BOOL success = [valueTransformer transformValue:@"http://restkit.org" toValue:&value error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beInstanceOf([NSURL class]);
    expect(value).to.equal([NSURL URLWithString:@"http://restkit.org"]);
}

- (void)testStringToURLTransformerTransformationSuccessFromURLToString
{
    RKValueTransformer *valueTransformer = [RKValueTransformer stringToURLValueTransformer];
    NSString *value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:[NSURL URLWithString:@"http://restkit.org"] toValue:&value error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSString class]);
    expect(value).to.equal(@"http://restkit.org");
}

- (void)testStringToURLTransformerFailureWithUntransformableInputValue
{
    RKValueTransformer *valueTransformer = [RKValueTransformer stringToURLValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@12345 toValue:&value error:&error];
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
    BOOL success = [valueTransformer transformValue:@":*7vxck#sf#adsa" toValue:&value error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorTransformationFailed);
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
    BOOL success = [valueTransformer transformValue:@"12345" toValue:&value error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSNumber class]);
    expect(value).to.equal(@12345);
}

- (void)testNumberToStringTransformerTransformationSuccessFromNumberToString
{
    RKValueTransformer *valueTransformer = [RKValueTransformer numberToStringValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@12345 toValue:&value error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSString class]);
    expect(value).to.equal(@"12345");
}

- (void)testNumberToStringTransformerTransformationSuccessFromStringToBooleanNumber
{
    RKValueTransformer *valueTransformer = [RKValueTransformer numberToStringValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@12345 toValue:&value error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSString class]);
    expect(value).to.equal(@"12345");
}

- (void)testNumberToStringTransformerTransformationSuccessFromBooleanNumberToString
{
    RKValueTransformer *valueTransformer = [RKValueTransformer numberToStringValueTransformer];
    id value = nil;
    NSError *error = nil;
    [valueTransformer transformValue:[NSNumber numberWithBool:YES] toValue:&value error:&error];
    expect(value).to.equal(@"true");
    [valueTransformer transformValue:[NSNumber numberWithBool:NO] toValue:&value error:&error];
    expect(value).to.equal(@"false");
}

- (void)testNumberToStringTransformerTransformationSuccessFromBooleanStringToNumber
{
    RKValueTransformer *valueTransformer = [RKValueTransformer numberToStringValueTransformer];
    id value = nil;
    NSError *error = nil;
    
    // True
    [valueTransformer transformValue:@"true" toValue:&value error:&error];
    expect(value).to.equal([NSNumber numberWithBool:YES]);
    [valueTransformer transformValue:@"TRUE" toValue:&value error:&error];
    expect(value).to.equal([NSNumber numberWithBool:YES]);
    [valueTransformer transformValue:@"t" toValue:&value error:&error];
    expect(value).to.equal([NSNumber numberWithBool:YES]);
    [valueTransformer transformValue:@"T" toValue:&value error:&error];
    expect(value).to.equal([NSNumber numberWithBool:YES]);
    [valueTransformer transformValue:@"yes" toValue:&value error:&error];
    expect(value).to.equal([NSNumber numberWithBool:YES]);
    [valueTransformer transformValue:@"YES" toValue:&value error:&error];
    expect(value).to.equal([NSNumber numberWithBool:YES]);
    [valueTransformer transformValue:@"y" toValue:&value error:&error];
    expect(value).to.equal([NSNumber numberWithBool:YES]);
    [valueTransformer transformValue:@"Y" toValue:&value error:&error];
    expect(value).to.equal([NSNumber numberWithBool:YES]);
    
    // False
    [valueTransformer transformValue:@"false" toValue:&value error:&error];
    expect(value).to.equal([NSNumber numberWithBool:NO]);
    [valueTransformer transformValue:@"FALSE" toValue:&value error:&error];
    expect(value).to.equal([NSNumber numberWithBool:NO]);
    [valueTransformer transformValue:@"f" toValue:&value error:&error];
    expect(value).to.equal([NSNumber numberWithBool:NO]);
    [valueTransformer transformValue:@"F" toValue:&value error:&error];
    expect(value).to.equal([NSNumber numberWithBool:NO]);
    [valueTransformer transformValue:@"no" toValue:&value error:&error];
    expect(value).to.equal([NSNumber numberWithBool:NO]);
    [valueTransformer transformValue:@"NO" toValue:&value error:&error];
    expect(value).to.equal([NSNumber numberWithBool:NO]);
    [valueTransformer transformValue:@"f" toValue:&value error:&error];
    expect(value).to.equal([NSNumber numberWithBool:NO]);
    [valueTransformer transformValue:@"F" toValue:&value error:&error];
    expect(value).to.equal([NSNumber numberWithBool:NO]);
}

- (void)testNumberToStringTransformerFailureWithUntransformableInputValue
{
    RKValueTransformer *valueTransformer = [RKValueTransformer numberToStringValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@[] toValue:&value error:&error];
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
    BOOL success = [valueTransformer transformValue:@":*7vxck#sf#adsa" toValue:&value error:&error];
    expect(success).to.beTruthy();
    expect(value).to.equal(0);
}

#pragma mark Date to Number

- (void)testDateToNumberTransformerValidationSuccessFromDateToNumber
{
    RKValueTransformer *valueTransformer = [RKValueTransformer dateToNumberValueTransformer];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSDate class] toClass:[NSNumber class]];
    expect(success).to.beTruthy();
}

- (void)testDateToNumberTransformerValidationSuccessFromNumberToDate
{
    RKValueTransformer *valueTransformer = [RKValueTransformer dateToNumberValueTransformer];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSNumber class] toClass:[NSDate class]];
    expect(success).to.beTruthy();
}

- (void)testDateToNumberTransformerValidationFailure
{
    RKValueTransformer *valueTransformer = [RKValueTransformer dateToNumberValueTransformer];
    BOOL success = [valueTransformer validateTransformationFromClass:[NSNumber class] toClass:[NSURL class]];
    expect(success).to.beFalsy();
}

- (void)testDateToNumberTransformerTransformationSuccessFromDateToNumber
{
    RKValueTransformer *valueTransformer = [RKValueTransformer dateToNumberValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:[NSDate dateWithTimeIntervalSince1970:0] toValue:&value error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSNumber class]);
    expect(value).to.equal(@0);
}

- (void)testDateToNumberTransformerTransformationSuccessFromNumberToDate
{
    RKValueTransformer *valueTransformer = [RKValueTransformer dateToNumberValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@([[NSDate dateWithTimeIntervalSince1970:0] timeIntervalSince1970]) toValue:&value error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSDate class]);
    expect(value).to.equal([NSDate dateWithTimeIntervalSince1970:0]);
}

- (void)testDateToNumberTransformerFailureWithUntransformableInputValue
{
    RKValueTransformer *valueTransformer = [RKValueTransformer dateToNumberValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@"invalid" toValue:&value error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorUntransformableInputValue);
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
    BOOL success = [valueTransformer transformValue:@[ @"one", @"two", @"three" ] toValue:&value error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSOrderedSet class]);
    expect(value).to.equal(([NSOrderedSet orderedSetWithArray:@[ @"one", @"two", @"three" ]]));
}

- (void)testArrayToOrderedSetTransformerTransformationSuccessFromOrderedSetToArray
{
    RKValueTransformer *valueTransformer = [RKValueTransformer arrayToOrderedSetValueTransformer];
    NSString *value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:[NSOrderedSet orderedSetWithArray:@[ @"one", @"two", @"three" ]] toValue:&value error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSArray class]);
    expect(value).to.equal((@[ @"one", @"two", @"three" ]));
}

- (void)testArrayToOrderedSetTransformerFailureWithUntransformableInputValue
{
    RKValueTransformer *valueTransformer = [RKValueTransformer arrayToOrderedSetValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@12345 toValue:&value error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorUntransformableInputValue);
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
    BOOL success = [valueTransformer transformValue:@[ @"one", @"two", @"three" ] toValue:&value error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSSet class]);
    expect(value).to.equal(([NSSet setWithArray:@[ @"one", @"two", @"three" ]]));
}

- (void)testArrayToSetTransformerTransformationSuccessFromSetToArray
{
    RKValueTransformer *valueTransformer = [RKValueTransformer arrayToSetValueTransformer];
    NSString *value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:[NSSet setWithArray:@[ @"one", @"two", @"three" ]] toValue:&value error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSArray class]);
    expect(value).to.equal((@[ @"one", @"two", @"three" ]));
}

- (void)testArrayToSetTransformerFailureWithUntransformableInputValue
{
    RKValueTransformer *valueTransformer = [RKValueTransformer arrayToSetValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@12345 toValue:&value error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorUntransformableInputValue);
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
    BOOL success = [valueTransformer transformValue:[NSDecimalNumber decimalNumberWithString:@"123456.7890"] toValue:&value error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSString class]);
    expect(value).to.equal(@"123456.789");
}

- (void)testDecimalNumberToStringTransformerTransformationSuccessFromStringToDecimalNumber
{
    RKValueTransformer *valueTransformer = [RKValueTransformer decimalNumberToStringValueTransformer];
    NSString *value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@"123456.7890" toValue:&value error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSDecimalNumber class]);
    expect(value).to.equal([NSDecimalNumber decimalNumberWithString:@"123456.7890"]);
}

- (void)testDecimalNumberToStringTransformerFailureWithUntransformableInputValue
{
    RKValueTransformer *valueTransformer = [RKValueTransformer decimalNumberToStringValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@[] toValue:&value error:&error];
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
    BOOL success = [valueTransformer transformValue:@"abdskjfsdkfjs" toValue:&value error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorTransformationFailed);
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
    BOOL success = [valueTransformer transformValue:[NSDecimalNumber decimalNumberWithString:@"123456.7890"] toValue:&value error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSNumber class]);
    expect(value).to.equal([NSDecimalNumber decimalNumberWithString:@"123456.7890"]);
}

- (void)testDecimalNumberToNumberTransformerTransformationSuccessFromNumberToDecimalNumber
{
    RKValueTransformer *valueTransformer = [RKValueTransformer decimalNumberToNumberValueTransformer];
    NSNumber *value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@123456.7890 toValue:&value error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beKindOf([NSDecimalNumber class]);
    expect(value).to.equal([NSDecimalNumber decimalNumberWithString:@"123456.7890"]);
}

- (void)testDecimalNumberToNumberTransformerFailureWithUntransformableInputValue
{
    RKValueTransformer *valueTransformer = [RKValueTransformer decimalNumberToNumberValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@[] toValue:&value error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorUntransformableInputValue);
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
    BOOL success = [valueTransformer transformValue:[NSNull null] toValue:&value error:&error];
    expect(success).to.beTruthy();
    expect(value).to.beNil();
}

- (void)testNullTransformerFailureWithUntransformableInputValue
{
    RKValueTransformer *valueTransformer = [RKValueTransformer nullValueTransformer];
    id value = nil;
    NSError *error = nil;
    BOOL success = [valueTransformer transformValue:@12345 toValue:&value error:&error];
    expect(success).to.beFalsy();
    expect(value).to.beNil();
    expect(error).notTo.beNil();
    expect(error.domain).to.equal(RKErrorDomain);
    expect(error.code).to.equal(RKValueTransformationErrorUntransformableInputValue);
}

#pragma mark Keyed Archiving

//#pragma mark -
//#pragma mark Default Transformers
//- (void)testDefaultObjectToDataTransformer
//{
//    RKValueTransformer *transformer = [RKValueTransformer defaultObjectToDataTransformer];
//    expect(transformer).toNot.beNil();
//    
//    NSObject<NSCoding> *input = @[@"One", @"Two", @"Three"];
//    NSData *output;
//    NSError *error;
//    
//    BOOL success = [transformer transformValue:input toValue:&output error:&error];
//    expect(success).to.beTruthy();
//    
//    expect(output).to.beKindOf([NSData class]);
//    expect(output).to.equal([NSKeyedArchiver archivedDataWithRootObject:input]);
//    expect(error).to.beNil();
//    
//    expect([NSKeyedUnarchiver unarchiveObjectWithData:output]).to.equal(input);
//}

@end

@interface RKCompoundValueTransformerTest : SenTestCase
@end

@implementation RKCompoundValueTransformerTest

#pragma mark NSCopying

#pragma mark RKValueTransforming

#pragma <#arguments#>
@end
