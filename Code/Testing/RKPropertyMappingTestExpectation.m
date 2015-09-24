//
//  RKMappingTestExpectation.m
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

#import <RestKit/ObjectMapping/RKPropertyMapping.h>
#import <RestKit/Testing/RKPropertyMappingTestExpectation.h>

@interface RKPropertyMappingTestExpectation ()
@property (nonatomic, copy, readwrite) NSString *sourceKeyPath;
@property (nonatomic, copy, readwrite) NSString *destinationKeyPath;
@property (nonatomic, strong, readwrite) id value;
@property (nonatomic, copy, readwrite) RKMappingTestExpectationEvaluationBlock evaluationBlock;
@property (nonatomic, strong, readwrite) RKMapping *mapping;
@end

@implementation RKPropertyMappingTestExpectation

+ (instancetype)expectationWithSourceKeyPath:(NSString *)sourceKeyPath destinationKeyPath:(NSString *)destinationKeyPath
{
    RKPropertyMappingTestExpectation *expectation = [self new];
    expectation.sourceKeyPath = sourceKeyPath;
    expectation.destinationKeyPath = destinationKeyPath;

    return expectation;
}

+ (instancetype)expectationWithSourceKeyPath:(NSString *)sourceKeyPath destinationKeyPath:(NSString *)destinationKeyPath value:(id)value
{
    RKPropertyMappingTestExpectation *expectation = [self new];
    expectation.sourceKeyPath = sourceKeyPath;
    expectation.destinationKeyPath = destinationKeyPath;
    expectation.value = value;

    return expectation;
}

+ (instancetype)expectationWithSourceKeyPath:(NSString *)sourceKeyPath destinationKeyPath:(NSString *)destinationKeyPath evaluationBlock:(RKMappingTestExpectationEvaluationBlock)evaluationBlock
{
    RKPropertyMappingTestExpectation *expectation = [self new];
    expectation.sourceKeyPath = sourceKeyPath;
    expectation.destinationKeyPath = destinationKeyPath;
    expectation.evaluationBlock = evaluationBlock;

    return expectation;
}

+ (instancetype)expectationWithSourceKeyPath:(NSString *)sourceKeyPath destinationKeyPath:(NSString *)destinationKeyPath mapping:(RKMapping *)mapping
{
    RKPropertyMappingTestExpectation *expectation = [self new];
    expectation.sourceKeyPath = sourceKeyPath;
    expectation.destinationKeyPath = destinationKeyPath;
    expectation.mapping = mapping;

    return expectation;
}

- (NSString *)summary
{
    return [NSString stringWithFormat:@"map '%@' to '%@'", self.sourceKeyPath, self.destinationKeyPath];
}

- (NSString *)description
{
    if (self.value) {
        return [NSString stringWithFormat:@"map '%@' to '%@' with %@ value '%@'",
                self.sourceKeyPath, self.destinationKeyPath, [self.value class], self.value];
    } else if (self.evaluationBlock) {
        return [NSString stringWithFormat:@"map '%@' to '%@' satisfying evaluation block",
                self.sourceKeyPath, self.destinationKeyPath];
    } else if (self.mapping) {
        return [NSString stringWithFormat:@"map '%@' to '%@' using mapping: %@",
                self.sourceKeyPath, self.destinationKeyPath, self.mapping];
    }

    return [self summary];
}

@end
