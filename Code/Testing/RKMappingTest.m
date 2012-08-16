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

BOOL RKObjectIsValueEqualToValue(id sourceValue, id destinationValue);

///-----------------------------------------------------------------------------
///-----------------------------------------------------------------------------

@interface RKMappingTestEvent : NSObject

@property (nonatomic, strong, readonly) RKAttributeMapping *mapping;
@property (nonatomic, strong, readonly) id value;

@property (nonatomic, readonly) NSString *sourceKeyPath;
@property (nonatomic, readonly) NSString *destinationKeyPath;

+ (RKMappingTestEvent *)eventWithMapping:(RKAttributeMapping *)mapping value:(id)value;

@end

@interface RKMappingTestEvent ()
@property (nonatomic, strong, readwrite) id value;
@property (nonatomic, strong, readwrite) RKAttributeMapping *mapping;
@end

@implementation RKMappingTestEvent

@synthesize value = _value;
@synthesize mapping = _mapping;

+ (RKMappingTestEvent *)eventWithMapping:(RKAttributeMapping *)mapping value:(id)value
{
    RKMappingTestEvent *event = [RKMappingTestEvent new];
    event.value = value;
    event.mapping = mapping;

    return event;
}

- (NSString *)sourceKeyPath
{
    return self.mapping.sourceKeyPath;
}

- (NSString *)destinationKeyPath
{
    return self.mapping.destinationKeyPath;
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

@synthesize sourceObject = _sourceObject;
@synthesize destinationObject = _destinationObject;
@synthesize mapping = _mapping;
@synthesize rootKeyPath = _rootKeyPath;
@synthesize expectations = _expectations;
@synthesize events = _events;
@synthesize verifiesOnExpect = _verifiesOnExpect;
@synthesize performedMapping = _performedMapping;
@synthesize mappingOperationDataSource = _mappingOperationDataSource;

+ (RKMappingTest *)testForMapping:(RKObjectMapping *)mapping object:(id)sourceObject
{
    return [[self alloc] initWithMapping:mapping sourceObject:sourceObject destinationObject:nil];
}

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

- (void)expectMappingFromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath passingTest:(BOOL (^)(RKAttributeMapping *mapping, id value))evaluationBlock
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

- (BOOL)event:(RKMappingTestEvent *)event satisfiesExpectation:(RKMappingTestExpectation *)expectation errorMessage:(NSString **)errorMessage
{
    BOOL success;
    if (expectation.evaluationBlock) {
        // Let the expectation block evaluate the match
        success = expectation.evaluationBlock(event.mapping, event.value);

        if (! success) {
            *errorMessage = [NSString stringWithFormat:@"%@: expectation not satisfied: %@, but instead got %@ '%@'",
                             [self description], expectation, [event.value class], event.value];
        }
    } else if (expectation.value) {
        // Use RestKit comparison magic to match values
        success = RKObjectIsValueEqualToValue(event.value, expectation.value);

        if (! success) {
            *errorMessage = [NSString stringWithFormat:@"%@: expectation not satisfied: %@, but instead got %@ '%@'",
                             [self description], expectation, [event.value class], event.value];
        }
    } else if (expectation.mapping) {
        if ([event.mapping isKindOfClass:[RKRelationshipMapping class]]) {
            // Check the mapping that was used to map the relationship
            RKMapping *relationshipMapping = [(RKRelationshipMapping *)event.mapping mapping];
            success = [relationshipMapping isEqualToMapping:expectation.mapping];

            if (! success) {
                *errorMessage = [NSString stringWithFormat:@"%@: expectation not satisfied: %@ but was instead mapped using: %@",
                                 [self description], expectation, relationshipMapping];
            }
        } else {
            *errorMessage = [NSString stringWithFormat:@"%@: expectation not satisfied: %@, expected an RKObjectRelationshipMapping but instead got a %@",
                                 [self description], expectation, [expectation.mapping class]];

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
            self.destinationObject = [self.mappingOperationDataSource objectForMappableContent:self.sourceObject mapping:self.mapping];
        }
        RKMappingOperation *mappingOperation = [RKMappingOperation mappingOperationFromObject:sourceObject toObject:self.destinationObject withMapping:self.mapping];
        mappingOperation.dataSource = self.mappingOperationDataSource;
        NSError *error = nil;
        mappingOperation.delegate = self;
        BOOL success = [mappingOperation performMapping:&error];
        if (! success) {
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
        NSString *errorMessage = nil;
        if (! [self event:event satisfiesExpectation:expectation errorMessage:&errorMessage]) {
            #pragma GCC diagnostic ignored "-Wformat-security"
            [NSException raise:NSInternalInconsistencyException format:errorMessage];
            #pragma GCC diagnostic pop
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

#pragma mark - RKObjecMappingOperationDelegate

- (void)addEvent:(RKMappingTestEvent *)event
{
    [self.events addObject:event];
}

- (void)mappingOperation:(RKMappingOperation *)operation didSetValue:(id)value forKeyPath:(NSString *)keyPath usingMapping:(RKAttributeMapping *)mapping
{
    [self addEvent:[RKMappingTestEvent eventWithMapping:mapping value:value]];
}

- (void)mappingOperation:(RKMappingOperation *)operation didNotSetUnchangedValue:(id)value forKeyPath:(NSString *)keyPath usingMapping:(RKAttributeMapping *)mapping
{
    [self addEvent:[RKMappingTestEvent eventWithMapping:mapping value:value]];
}

@end
