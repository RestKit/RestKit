//
//  RKMappingTestExpectation.m
//  RestKit
//
//  Created by Blake Watters on 2/17/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKMappingTestExpectation.h"
#import "RKAttributeMapping.h"

@interface RKMappingTestExpectation ()
@property (nonatomic, copy, readwrite) NSString *sourceKeyPath;
@property (nonatomic, copy, readwrite) NSString *destinationKeyPath;
@property (nonatomic, strong, readwrite) id value;
@property (nonatomic, copy, readwrite) BOOL (^evaluationBlock)(RKAttributeMapping *mapping, id value);
@property (nonatomic, strong, readwrite) RKMapping *mapping;
@end


@implementation RKMappingTestExpectation

@synthesize sourceKeyPath = _sourceKeyPath;
@synthesize destinationKeyPath = _destinationKeyPath;
@synthesize value = _value;
@synthesize evaluationBlock = _evaluationBlock;
@synthesize mapping = _mapping;

+ (RKMappingTestExpectation *)expectationWithSourceKeyPath:(NSString *)sourceKeyPath destinationKeyPath:(NSString *)destinationKeyPath
{
    RKMappingTestExpectation *expectation = [self new];
    expectation.sourceKeyPath = sourceKeyPath;
    expectation.destinationKeyPath = destinationKeyPath;

    return expectation;
}

+ (RKMappingTestExpectation *)expectationWithSourceKeyPath:(NSString *)sourceKeyPath destinationKeyPath:(NSString *)destinationKeyPath value:(id)value
{
    RKMappingTestExpectation *expectation = [self new];
    expectation.sourceKeyPath = sourceKeyPath;
    expectation.destinationKeyPath = destinationKeyPath;
    expectation.value = value;

    return expectation;
}

+ (RKMappingTestExpectation *)expectationWithSourceKeyPath:(NSString *)sourceKeyPath destinationKeyPath:(NSString *)destinationKeyPath evaluationBlock:(BOOL (^)(RKAttributeMapping *mapping, id value))testBlock
{
    RKMappingTestExpectation *expectation = [self new];
    expectation.sourceKeyPath = sourceKeyPath;
    expectation.destinationKeyPath = destinationKeyPath;
    expectation.evaluationBlock = testBlock;

    return expectation;
}

+ (RKMappingTestExpectation *)expectationWithSourceKeyPath:(NSString *)sourceKeyPath destinationKeyPath:(NSString *)destinationKeyPath mapping:(RKMapping *)mapping
{
    RKMappingTestExpectation *expectation = [self new];
    expectation.sourceKeyPath = sourceKeyPath;
    expectation.destinationKeyPath = destinationKeyPath;
    expectation.mapping = mapping;

    return expectation;
}

- (NSString *)mappingDescription
{
    return [NSString stringWithFormat:@"expected sourceKeyPath '%@' to map to destinationKeyPath '%@'",
            self.sourceKeyPath, self.destinationKeyPath];
}

- (NSString *)description
{
    if (self.value) {
        return [NSString stringWithFormat:@"expected sourceKeyPath '%@' to map to destinationKeyPath '%@' with %@ value '%@'",
                self.sourceKeyPath, self.destinationKeyPath, [self.value class], self.value];
    } else if (self.evaluationBlock) {
        return [NSString stringWithFormat:@"expected sourceKeyPath '%@' to map to destinationKeyPath '%@' satisfying evaluation block",
                self.sourceKeyPath, self.destinationKeyPath];
    } else if (self.mapping) {
        return [NSString stringWithFormat:@"expected sourceKeyPath '%@' to map to destinationKeyPath '%@' using mapping: %@",
                self.sourceKeyPath, self.destinationKeyPath, self.mapping];
    }

    return [self mappingDescription];
}

@end
