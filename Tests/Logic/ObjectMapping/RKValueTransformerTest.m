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
    [RKValueTransformer class];
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



@end
