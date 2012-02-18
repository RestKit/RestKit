//
//  RKMappingTest.m
//  RKGithub
//
//  Created by Blake Watters on 2/17/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKMappingTest.h"

BOOL RKObjectIsValueEqualToValue(id sourceValue, id destinationValue);

///-----------------------------------------------------------------------------
///-----------------------------------------------------------------------------

@interface RKMappingTestEvent : NSObject

@property (nonatomic, strong, readonly) RKObjectAttributeMapping *mapping;
@property (nonatomic, strong, readonly) id value;

@property (nonatomic, readonly) NSString *sourceKeyPath;
@property (nonatomic, readonly) NSString *destinationKeyPath;

+ (RKMappingTestEvent *)eventWithMapping:(RKObjectAttributeMapping *)mapping value:(id)value;

@end

@interface RKMappingTestEvent ()
@property (nonatomic, strong, readwrite) id value;
@property (nonatomic, strong, readwrite) RKObjectAttributeMapping *mapping;
@end

@implementation RKMappingTestEvent

@synthesize value;
@synthesize mapping;

+ (RKMappingTestEvent *)eventWithMapping:(RKObjectAttributeMapping *)mapping value:(id)value {
    RKMappingTestEvent *event = [RKMappingTestEvent new];
    event.value = value;
    event.mapping = mapping;
    
    return event;
}

- (NSString *)sourceKeyPath {
    return self.mapping.sourceKeyPath;
}

- (NSString *)destinationKeyPath {
    return self.mapping.destinationKeyPath;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@: mapped sourceKeyPath '%@' => destinationKeyPath '%@' with value: %@", [self class], self.sourceKeyPath, self.destinationKeyPath, self.value];
}

@end

///-----------------------------------------------------------------------------
///-----------------------------------------------------------------------------

@interface RKMappingTest ()
@property (nonatomic, strong, readwrite) RKObjectMapping *mapping;
@property (nonatomic, strong, readwrite) id sourceObject;
@property (nonatomic, strong, readwrite) id destinationObject;
@property (nonatomic, strong) NSMutableArray *expectations;
@property (nonatomic, strong) NSMutableArray *events;
@end

@implementation RKMappingTest

@synthesize sourceObject;
@synthesize destinationObject;
@synthesize mapping;
@synthesize expectations;
@synthesize events;

+ (RKMappingTest *)testForMapping:(RKObjectMapping *)mapping object:(id)sourceObject {
    return [[self alloc] initWithMapping:mapping sourceObject:sourceObject destinationObject:nil];
}

+ (RKMappingTest *)testForMapping:(RKObjectMapping *)mapping sourceObject:(id)sourceObject destinationObject:(id)destinationObject {
    return [[self alloc] initWithMapping:mapping sourceObject:sourceObject destinationObject:destinationObject];
}

- (id)initWithMapping:(RKObjectMapping *)_mapping sourceObject:(id)_sourceObject destinationObject:(id)_destinationObject {
    self = [super init];
    if (self) {        
        self.sourceObject = _sourceObject;
        self.destinationObject = _destinationObject;
        self.mapping = _mapping;
        self.expectations = [NSMutableArray new];
        self.events = [NSMutableArray new];
    }
    
    return self;
}

- (void)addExpectation:(RKMappingTestExpectation *)expectation {
    [self.expectations addObject:expectation];
}

- (void)expectMappingFromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath {
    [self addExpectation:[RKMappingTestExpectation expectationWithSourceKeyPath:sourceKeyPath destinationKeyPath:destinationKeyPath]];
}

- (void)expectMappingFromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath withValue:(id)value {
    [self addExpectation:[RKMappingTestExpectation expectationWithSourceKeyPath:sourceKeyPath destinationKeyPath:destinationKeyPath value:value]];
}

- (void)expectMappingFromKeyPath:(NSString *)sourceKeyPath toKeyPath:(NSString *)destinationKeyPath passingTest:(BOOL (^)(RKObjectAttributeMapping *mapping, id value))evaluationBlock {
    [self addExpectation:[RKMappingTestExpectation expectationWithSourceKeyPath:sourceKeyPath destinationKeyPath:destinationKeyPath evaluationBlock:evaluationBlock]];
}

- (RKMappingTestEvent *)eventSatisfyingExpectation:(RKMappingTestExpectation *)expectation {
    for (RKMappingTestEvent *event in self.events) {
        if ([event.sourceKeyPath isEqualToString:expectation.sourceKeyPath] && [event.destinationKeyPath isEqualToString:expectation.destinationKeyPath]) {
            if (expectation.evaluationBlock) {
                // Let the expectation block evaluate the match
                if (expectation.evaluationBlock(event.mapping, event.value)) {
                    return event;
                }
            } else if (expectation.value) {
                // Use RestKit comparison magic to match values
                if (RKObjectIsValueEqualToValue(event.value, expectation.value)) {
                    return event;
                }
            } else {
                // We only wanted to know that a mapping occured between the keyPaths
                return event;
            }
        }
    }
    
    return nil;
}

- (void)verify {
    id destination = self.destinationObject ? self.destinationObject : [self.mapping mappableObjectForData:self.sourceObject];
    RKObjectMappingOperation *mappingOperation = [RKObjectMappingOperation mappingOperationFromObject:self.sourceObject toObject:destination withMapping:self.mapping];
    NSError *error = nil;
    mappingOperation.delegate = self;
    BOOL success = [mappingOperation performMapping:&error];
    if (! success) {
        [NSException raise:NSInternalInconsistencyException format:@"%@: failure when mapping from %@ to %@ with mapping %@",
         [self description], self.sourceObject, self.destinationObject, self.mapping];
    }
    
    for (RKMappingTestExpectation *expectation in self.expectations) {
        RKMappingTestEvent *event = [self eventSatisfyingExpectation:expectation];
        if (! event) {
            [NSException raise:NSInternalInconsistencyException format:@"%@: expectation not satisfied: %@",
             [self description], expectation];
        }
    }
}

#pragma mark - RKObjecMappingOperationDelegate

- (void)addEvent:(RKMappingTestEvent *)event {
    [self.events addObject:event];
}

- (void)objectMappingOperation:(RKObjectMappingOperation *)operation didSetValue:(id)value forKeyPath:(NSString *)keyPath usingMapping:(RKObjectAttributeMapping*)_mapping {
    [self addEvent:[RKMappingTestEvent eventWithMapping:_mapping value:value]];
}

@end
