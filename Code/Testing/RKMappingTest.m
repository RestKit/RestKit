//
//  RKMappingTest.m
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

#import "RKMappingTest.h"
#import "RKEntityMapping.h"
#import "RKObjectMappingOperationDataSource.h"
#import "RKRelationshipMapping.h"
#import "RKErrors.h"
#import "RKObjectUtilities.h"

// Error Constants
NSString * const RKMappingTestErrorDomain = @"org.restkit.RKMappingTest.ErrorDomain";
NSString * const RKMappingTestEventErrorKey = @"RKMappingTestEventErrorKey";
NSString * const RKMappingTestExpectationErrorKey = @"RKMappingTestExpectationErrorKey";
NSString * const RKMappingTestValueErrorKey = @"RKMappingTestValueErrorKey";
NSString * const RKMappingTestVerificationFailureException = @"RKMappingTestVerificationFailureException";

///-----------------------------------------------------------------------------
///-----------------------------------------------------------------------------

@interface RKMappingTestEvent : NSObject

@property (nonatomic, strong, readonly) RKPropertyMapping *propertyMapping;
@property (nonatomic, strong, readonly) id value;

@property (weak, nonatomic, readonly) NSString *sourceKeyPath;
@property (weak, nonatomic, readonly) NSString *destinationKeyPath;

+ (RKMappingTestEvent *)eventWithMapping:(RKPropertyMapping *)propertyMapping value:(id)value;

@end

@interface RKMappingTestEvent ()
@property (nonatomic, strong, readwrite) id value;
@property (nonatomic, strong, readwrite) RKPropertyMapping *propertyMapping;
@end

@implementation RKMappingTestEvent

+ (RKMappingTestEvent *)eventWithMapping:(RKPropertyMapping *)propertyMapping value:(id)value
{
    RKMappingTestEvent *event = [RKMappingTestEvent new];
    event.value = value;
    event.propertyMapping = propertyMapping;

    return event;
}

- (NSString *)sourceKeyPath
{
    return [self.propertyMapping sourceKeyPath];
}

- (NSString *)destinationKeyPath
{
    return [self.propertyMapping destinationKeyPath];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ mapped sourceKeyPath '%@' => destinationKeyPath '%@' with value: %@>", [self class],
            self.sourceKeyPath, self.destinationKeyPath, self.value];
}

@end

///-----------------------------------------------------------------------------
///-----------------------------------------------------------------------------

@interface RKMappingTest () <RKMappingOperationDelegate>
@property (nonatomic, strong, readwrite) RKObjectMapping *mapping;
@property (nonatomic, strong, readwrite) id sourceObject;
@property (nonatomic, strong, readwrite) id destinationObject;
@property (nonatomic, strong) NSMutableArray *expectations;
@property (nonatomic, strong) NSMutableArray *events;
@property (nonatomic, assign, getter = hasPerformedMapping) BOOL performedMapping;

// Method Definitions for old compilers
- (void)performMapping;
- (void)verifyExpectation:(RKMappingTestExpectation *)expectation;

@end

@implementation RKMappingTest

+ (RKMappingTest *)testForMapping:(RKObjectMapping *)mapping sourceObject:(id)sourceObject destinationObject:(id)destinationObject
{
    return [[self alloc] initWithMapping:mapping sourceObject:sourceObject destinationObject:destinationObject];
}

- (id)initWithMapping:(RKObjectMapping *)mapping sourceObject:(id)sourceObject destinationObject:(id)destinationObject
{
    NSAssert(sourceObject != nil, @"Cannot perform a mapping operation without a sourceObject object");
    NSAssert(mapping != nil, @"Cannot perform a mapping operation without a mapping");

    self = [super init];
    if (self) {
        self.sourceObject = sourceObject;
        self.destinationObject = destinationObject;
        self.mapping = mapping;
        self.expectations = [NSMutableArray new];
        self.events = [NSMutableArray new];
        self.verifiesOnExpect = NO;
        self.performedMapping = NO;
        self.mappingOperationDataSource = [RKObjectMappingOperationDataSource new];
    }

    return self;
}

- (void)addExpectation:(RKMappingTestExpectation *)expectation
{
    [self.expectations addObject:expectation];

    if (self.verifiesOnExpect) {
        [self performMapping];
        [self verifyExpectation:expectation];
    }
}

- (void)expectMappingFromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath
{
    [self addExpectation:[RKMappingTestExpectation expectationWithSourceKeyPath:sourceKeyPath destinationKeyPath:destinationKeyPath]];
}

- (void)expectMappingFromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath withValue:(id)value
{
    [self addExpectation:[RKMappingTestExpectation expectationWithSourceKeyPath:sourceKeyPath destinationKeyPath:destinationKeyPath value:value]];
}

- (void)expectMappingFromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath passingTest:(RKMappingTestExpectationEvaluationBlock)evaluationBlock
{
    [self addExpectation:[RKMappingTestExpectation expectationWithSourceKeyPath:sourceKeyPath destinationKeyPath:destinationKeyPath evaluationBlock:evaluationBlock]];
}

- (void)expectMappingFromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath usingMapping:(RKMapping *)mapping
{
    [self addExpectation:[RKMappingTestExpectation expectationWithSourceKeyPath:sourceKeyPath destinationKeyPath:destinationKeyPath mapping:mapping]];
}

- (RKMappingTestEvent *)eventMatchingKeyPathsForExpectation:(RKMappingTestExpectation *)expectation
{
    for (RKMappingTestEvent *event in self.events) {
        if ([event.sourceKeyPath isEqualToString:expectation.sourceKeyPath] && [event.destinationKeyPath isEqualToString:expectation.destinationKeyPath]) {
            return event;
        }
    }

    return nil;
}

- (NSError *)errorForExpectation:(RKMappingTestExpectation *)expectation
                        withCode:(NSInteger)errorCode
                        userInfo:(NSDictionary *)userInfo
                     description:(NSString *)description
                          reason:(NSString *)reason
{
    NSMutableDictionary *fullUserInfo = [userInfo mutableCopy];
    fullUserInfo[NSLocalizedDescriptionKey] = description;
    fullUserInfo[NSLocalizedFailureReasonErrorKey] = reason;
    return [NSError errorWithDomain:RKMappingTestErrorDomain code:errorCode userInfo:fullUserInfo];
}

- (BOOL)event:(RKMappingTestEvent *)event satisfiesExpectation:(RKMappingTestExpectation *)expectation error:(NSError **)error
{
    BOOL success;

    NSDictionary *userInfo = @{ RKMappingTestEventErrorKey : event,
                                RKMappingTestExpectationErrorKey : expectation };
    if (expectation.evaluationBlock) {
        // Let the expectation block evaluate the match
        NSError *blockError = nil;
        success = expectation.evaluationBlock(expectation, event.propertyMapping, event.value, &blockError);

        if (! success) {
            if (blockError) {
                // If the block has given us an error, use the reason
                NSMutableDictionary *mutableUserInfo = [userInfo mutableCopy];
                [mutableUserInfo setValue:blockError forKey:NSUnderlyingErrorKey];
                NSString *reason = [NSString stringWithFormat:@"expected to %@ with value %@ '%@', but it did not",
                                         expectation, [event.value class], event.value];
                *error = [self errorForExpectation:expectation
                                          withCode:RKMappingTestEvaluationBlockError
                                          userInfo:mutableUserInfo
                                       description:[blockError localizedDescription]
                                            reason:reason];

                *error = blockError;
            } else {
                NSString *description = [NSString stringWithFormat:@"evaluation block returned `NO` for %@ value '%@'", [event.value class], event.value];
                NSString *reason = [NSString stringWithFormat:@"expected to %@ with value %@ '%@', but it did not",
                                         expectation, [event.value class], event.value];
                *error = [self errorForExpectation:expectation
                                          withCode:RKMappingTestEvaluationBlockError
                                          userInfo:userInfo
                                       description:description
                                            reason:reason];
            }
        }
    } else if (expectation.value) {
        // Use RestKit comparison magic to match values
        success = RKObjectIsEqualToObject(event.value, expectation.value);

        if (! success) {
            NSString *description = [NSString stringWithFormat:@"mapped to unexpected %@ value '%@'", [event.value class], event.value];
            NSString *reason = [NSString stringWithFormat:@"expected to %@, but instead got %@ '%@'",
                                     expectation, [event.value class], event.value];
            if (error) *error = [self errorForExpectation:expectation
                                                 withCode:RKMappingTestEvaluationBlockError
                                                 userInfo:userInfo
                                              description:description
                                                   reason:reason];
        }
    } else if (expectation.mapping) {
        if ([event.propertyMapping isKindOfClass:[RKRelationshipMapping class]]) {
            // Check the mapping that was used to map the relationship
            RKMapping *relationshipMapping = [(RKRelationshipMapping *)event.propertyMapping mapping];
            success = [relationshipMapping isEqualToMapping:expectation.mapping];

            if (! success) {
                NSString *description = [NSString stringWithFormat:@"mapped using unexpected mapping: %@", relationshipMapping];
                NSString *reason = [NSString stringWithFormat:@"expected to %@, but was instead mapped using: %@",
                                         expectation, relationshipMapping];
                if (error) *error = [self errorForExpectation:expectation
                                                     withCode:RKMappingTestEvaluationBlockError
                                                     userInfo:userInfo
                                                  description:description
                                                       reason:reason];
            }
        } else {
            NSString *description = [NSString stringWithFormat:@"expected a property mapping of type `RKRelationshipMapping` but instead got a `%@`", [expectation.mapping class]];
            NSString *reason = [NSString stringWithFormat:@"expected to %@, but instead of a `RKRelationshipMapping` got a `%@`",
                                     expectation, [expectation.mapping class]];
            if (error) *error = [self errorForExpectation:expectation
                                                 withCode:RKMappingTestEvaluationBlockError
                                                 userInfo:userInfo
                                              description:description
                                                   reason:reason];

            // Error message here that a relationship was not mapped!!!
            return NO;
        }
    } else {
        // We only wanted to know that a mapping occured between the keyPaths
        success = YES;
    }

    return success;
}

- (void)performMapping
{
    NSAssert(self.mapping.objectClass, @"Cannot test a mapping that does not have a destination objectClass");

    // Ensure repeated invocations of verify only result in a single mapping operation
    if (! self.hasPerformedMapping) {
        id sourceObject = self.rootKeyPath ? [self.sourceObject valueForKeyPath:self.rootKeyPath] : self.sourceObject;
        if (nil == self.destinationObject) {
            self.destinationObject = [self.mappingOperationDataSource mappingOperation:nil targetObjectForRepresentation:self.sourceObject withMapping:self.mapping];
        }
        RKMappingOperation *mappingOperation = [[RKMappingOperation alloc] initWithSourceObject:sourceObject destinationObject:self.destinationObject mapping:self.mapping];
        mappingOperation.dataSource = self.mappingOperationDataSource;
        NSError *error = nil;
        mappingOperation.delegate = self;
        [mappingOperation start];
        if (mappingOperation.error) {
            [NSException raise:NSInternalInconsistencyException format:@"%p: failed with error: %@\n%@ during mapping from %@ to %@ with mapping %@",
             self, error, [self description], self.sourceObject, self.destinationObject, self.mapping];
        }

        self.performedMapping = YES;
    }
}

- (void)verifyExpectation:(RKMappingTestExpectation *)expectation
{
    RKMappingTestEvent *event = [self eventMatchingKeyPathsForExpectation:expectation];
    if (event) {
        // Found a matching event, check if it satisfies the expectation
        NSError *error = nil;
        if (! [self event:event satisfiesExpectation:expectation error:&error]) {
            NSDictionary *userInfo = @{ NSUnderlyingErrorKey: error,
                                        RKMappingTestEventErrorKey: event,
                                        RKMappingTestExpectationErrorKey: expectation };
            [[NSException exceptionWithName:RKMappingTestVerificationFailureException
                                     reason:[error localizedDescription]
                                   userInfo:userInfo] raise];
        }
    } else {
        // No match
        [NSException raise:NSInternalInconsistencyException format:@"%@: expectation not satisfied: %@, but did not.",
         [self description], [expectation mappingDescription]];
    }
}

- (void)verify
{
    [self performMapping];

    for (RKMappingTestExpectation *expectation in self.expectations) {
        [self verifyExpectation:expectation];
    }
}

#pragma mark - Evaluating Expectations

- (BOOL)evaluate
{
    [self performMapping];

    for (RKMappingTestExpectation *expectation in self.expectations) {
        if (! [self evaluateExpectation:expectation error:nil]) return NO;
    }

    return YES;
}

- (BOOL)evaluateExpectation:(RKMappingTestExpectation *)expectation error:(NSError **)error
{
    [self performMapping];

    RKMappingTestEvent *event = [self eventMatchingKeyPathsForExpectation:expectation];
    if (event) {
        if (! [self event:event satisfiesExpectation:expectation error:error]) {
            return NO;
        }
    } else {
        if (error) {
            NSDictionary *userInfo = @{
            RKMappingTestExpectationErrorKey : expectation,
            NSLocalizedDescriptionKey        : [NSString stringWithFormat:@"expected to %@, but did not.", [expectation mappingDescription]],
            NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:@"%@: %@, but did not.", [self description], [expectation mappingDescription]]
            };
            *error = [NSError errorWithDomain:RKMappingTestErrorDomain code:RKMappingTestUnsatisfiedExpectationError userInfo:userInfo];
        };
        return NO;
    }

    return YES;
}

- (NSString *)expectationsDescription
{
    return [self.expectations valueForKey:@"description"];
}

- (NSString *)eventsDescription
{
    return [self.events valueForKey:@"description"];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ Expectations: %@\nEvents: %@",
            [self class], [self expectationsDescription], [self eventsDescription]];
}

#pragma mark - RKMappingOperationDelegate

- (void)addEvent:(RKMappingTestEvent *)event
{
    @synchronized(self.events) { [self.events addObject:event]; };
}

- (void)mappingOperation:(RKMappingOperation *)operation didSetValue:(id)value forKeyPath:(NSString *)keyPath usingMapping:(RKAttributeMapping *)mapping
{
    [self addEvent:[RKMappingTestEvent eventWithMapping:mapping value:value]];
}

- (void)mappingOperation:(RKMappingOperation *)operation didNotSetUnchangedValue:(id)value forKeyPath:(NSString *)keyPath usingMapping:(RKAttributeMapping *)mapping
{
    [self addEvent:[RKMappingTestEvent eventWithMapping:mapping value:value]];
}

- (void)mappingOperation:(RKMappingOperation *)operation didConnectRelationship:(NSRelationshipDescription *)relationship usingMapping:(RKConnectionMapping *)connectionMapping
{
    id connectedObjects = [operation.destinationObject valueForKey:relationship.name];
    [self addEvent:[RKMappingTestEvent eventWithMapping:connectionMapping value:connectedObjects]];
}

@end
