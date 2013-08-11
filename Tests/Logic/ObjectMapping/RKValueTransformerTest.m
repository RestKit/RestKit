//
//  RKValueTransformerTest.m
//  RestKit
//
//  Created by Samuel E. Giddins on 6/13/13.
//  Copyright (c) 2013 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKValueTransformers.h"

@interface RKValueTransformerTest : SenTestCase

@end

@implementation RKValueTransformerTest

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

- (void)testValueTransformerRequiresAllParametersExceptReverse
{
    Class source = nil, destination = nil;
    RKValueTransformationBlock forward = nil, reverse = nil;
    source = [NSString class];
    destination = [NSURL class];
    forward = ^BOOL(id inputValue, id *outputValue, NSError **error) {
        *outputValue = [NSURL URLWithString:inputValue];
        return YES;
    };
    reverse = ^BOOL(id inputValue, id *outputValue, NSError **error) {
        *outputValue = [inputValue absoluteString];
        return YES;
    };
    
    // All params OK
    expect(^{[RKValueTransformer valueTransformerWithSourceClass:source destinationClass:destination transformationBlock:forward reverseTransformationBlock:reverse];}).toNot.raiseAny();
    
    // nil reverse passes
    expect(^{[RKValueTransformer valueTransformerWithSourceClass:source destinationClass:destination transformationBlock:forward reverseTransformationBlock:nil];}).toNot.raiseAny();
    
    // nil transformationBlock fails
    expect(^{[RKValueTransformer valueTransformerWithSourceClass:source destinationClass:destination transformationBlock:nil reverseTransformationBlock:reverse];}).to.raise(NSInvalidArgumentException);
    
    // nil source fails
    expect(^{[RKValueTransformer valueTransformerWithSourceClass:nil destinationClass:destination transformationBlock:forward reverseTransformationBlock:reverse];}).to.raise(NSInvalidArgumentException);
    
    // nil destination fails
    expect(^{[RKValueTransformer valueTransformerWithSourceClass:source destinationClass:nil transformationBlock:forward reverseTransformationBlock:reverse];}).to.raise(NSInvalidArgumentException);
}

- (void)testValueTransformerPropertiesYieldAssignedValues
{
    Class source = nil, destination = nil;
    RKValueTransformationBlock forward = nil, reverse = nil;
    source = [NSString class];
    destination = [NSURL class];
    forward = ^BOOL(id inputValue, id *outputValue, NSError **error) {
        *outputValue = [NSURL URLWithString:inputValue];
        return YES;
    };
    reverse = ^BOOL(id inputValue, id *outputValue, NSError **error) {
        *outputValue = [inputValue absoluteString];
        return YES;
    };
    
    RKValueTransformer *transformer = [RKValueTransformer valueTransformerWithSourceClass:source destinationClass:destination transformationBlock:forward reverseTransformationBlock:reverse];
    
    expect(transformer.sourceClass).to.equal(source);
    expect(transformer.destinationClass).to.equal(destination);
}

- (void)testTransformationSetsOutputValue
{
    Class source = nil, destination = nil;
    RKValueTransformationBlock forward = nil, reverse = nil;
    source = [NSString class];
    destination = [NSURL class];
    forward = ^BOOL(id inputValue, id *outputValue, NSError **error) {
        *outputValue = [NSURL URLWithString:inputValue];
        return YES;
    };
    reverse = ^BOOL(id inputValue, id *outputValue, NSError **error) {
        *outputValue = [inputValue absoluteString];
        return YES;
    };
    
    RKValueTransformer *transformer = [RKValueTransformer valueTransformerWithSourceClass:source destinationClass:destination transformationBlock:forward reverseTransformationBlock:reverse];
    
    NSString *input = @"http://restkit.org/";
    NSURL *output;
    NSError *error;
    
    BOOL success = [transformer transformValue:input toValue:&output error:&error];
    expect(success).to.beTruthy();
    
    expect(output).to.beInstanceOf([NSURL class]);
    expect(output).to.equal([NSURL URLWithString:input]);
    expect(error).to.beNil();
}

#pragma mark -
#pragma mark Default Transformers

- (void)testDefaultStringToURLTransformer
{
    RKValueTransformer *transformer = [RKValueTransformer defaultStringToURLTransformer];
    expect(transformer).toNot.beNil();
    
    NSString *input = @"http://restkit.org/";
    NSURL *output;
    NSError *error;
    
    BOOL success = [transformer transformValue:input toValue:&output error:&error];
    expect(success).to.beTruthy();
    
    expect(output).to.beKindOf([NSURL class]);
    expect(output).to.equal([NSURL URLWithString:input]);
    expect(error).to.beNil();
}

- (void)testDefaultStringToURLTransformerReverse
{
    RKValueTransformer *transformer = [RKValueTransformer defaultStringToURLTransformer];
    expect(transformer).toNot.beNil();
    
    NSURL *input = [NSURL URLWithString:@"http://restkit.org/"];
    NSString *output;
    NSError *error;
    
    BOOL success = [transformer transformValue:input toValue:&output error:&error];
    expect(success).to.beTruthy();
    
    expect(output).to.beKindOf([NSString class]);
    expect(output).to.equal(@"http://restkit.org/");
    expect(error).to.beNil();
}

- (void)testDefaultStringToNumberTransformerWithInteger
{
    RKValueTransformer *transformer = [RKValueTransformer defaultStringToNumberTransformer];
    expect(transformer).toNot.beNil();
    
    NSString *input = @"100";
    NSNumber *output;
    NSError *error;
    
    BOOL success = [transformer transformValue:input toValue:&output error:&error];
    expect(success).to.beTruthy();
    
    expect(output).to.beKindOf([NSNumber class]);
    expect(output).to.equal(@100);
    expect(error).to.beNil();
}

- (void)testDefaultNumberToDateTransformer
{
    RKValueTransformer *transformer = [RKValueTransformer defaultNumberToDateTransformer];
    expect(transformer).toNot.beNil();
    
    NSNumber *input = @100;
    NSDate *output;
    NSError *error;
    
    BOOL success = [transformer transformValue:input toValue:&output error:&error];
    expect(success).to.beTruthy();
    
    expect(output).to.beKindOf([NSDate class]);
    expect(output).to.equal([NSDate dateWithTimeIntervalSince1970:100]);
    expect(error).to.beNil();
}

- (void)testDefaultOrderedSetToArrayTransformer
{
    RKValueTransformer *transformer = [RKValueTransformer defaultOrderedSetToArrayTransformer];
    expect(transformer).toNot.beNil();
    
    NSOrderedSet *input = [NSOrderedSet orderedSetWithObjects:@"One", @"Two", @"Three", nil];
    NSArray *output;
    NSError *error;
    
    BOOL success = [transformer transformValue:input toValue:&output error:&error];
    expect(success).to.beTruthy();
    
    expect(output).to.beKindOf([NSArray class]);
    expect(output).to.equal((@[@"One", @"Two", @"Three"]));
    expect(error).to.beNil();
}

- (void)testDefaultSetToArrayTransformer
{
    RKValueTransformer *transformer = [RKValueTransformer defaultSetToArrayTransformer];
    expect(transformer).toNot.beNil();
    
    NSSet *input = [NSSet setWithObjects:@"One", @"Two", @"Three", nil];
    NSArray *output;
    NSError *error;
    
    BOOL success = [transformer transformValue:input toValue:&output error:&error];
    expect(success).to.beTruthy();
    
    expect(output).to.beKindOf([NSArray class]);
    expect(output).to.equal((@[@"One", @"Two", @"Three"]));
    expect(error).to.beNil();
}

- (void)testDefaultStringToDecimalNumberTransformer
{
    RKValueTransformer *transformer = [RKValueTransformer defaultStringToDecimalNumberTransformer];
    expect(transformer).toNot.beNil();
    
    NSString *input = @"1234765";
    NSDecimalNumber *output;
    NSError *error;
    
    BOOL success = [transformer transformValue:input toValue:&output error:&error];
    expect(success).to.beTruthy();
    
    expect(output).to.beKindOf([NSDecimalNumber class]);
    expect(output).to.equal([NSDecimalNumber decimalNumberWithDecimal:[@1234765 decimalValue]]);
    expect(error).to.beNil();
}

- (void)testDefaultNumberToDecimalNumberTransformer
{
    RKValueTransformer *transformer = [RKValueTransformer defaultNumberToDecimalNumberTransformer];
    expect(transformer).toNot.beNil();
    
    NSNumber *input = @1234765;
    NSDecimalNumber *output;
    NSError *error;
    
    BOOL success = [transformer transformValue:input toValue:&output error:&error];
    expect(success).to.beTruthy();
    
    expect(output).to.beKindOf([NSDecimalNumber class]);
    expect(output).to.equal([NSDecimalNumber decimalNumberWithDecimal:[@1234765 decimalValue]]);
    expect(error).to.beNil();
}

- (void)testDefaultObjectToDataTransformer
{
    RKValueTransformer *transformer = [RKValueTransformer defaultObjectToDataTransformer];
    expect(transformer).toNot.beNil();
    
    NSObject<NSCoding> *input = @[@"One", @"Two", @"Three"];
    NSData *output;
    NSError *error;
    
    BOOL success = [transformer transformValue:input toValue:&output error:&error];
    expect(success).to.beTruthy();
    
    expect(output).to.beKindOf([NSData class]);
    expect(output).to.equal([NSKeyedArchiver archivedDataWithRootObject:input]);
    expect(error).to.beNil();
    
    expect([NSKeyedUnarchiver unarchiveObjectWithData:output]).to.equal(input);
}

- (void)testDefaultNullTransformer
{
    RKValueTransformer *transformer = [RKValueTransformer defaultNullTransformer];
    expect(transformer).toNot.beNil();
    
    NSNull *input = [NSNull null];
    NSData *output;
    NSError *error;
    
    BOOL success = [transformer transformValue:input toValue:&output error:&error];
    expect(success).to.beTruthy();
    
    expect(output).to.beNil();
    expect(error).to.beNil();
}

@end
