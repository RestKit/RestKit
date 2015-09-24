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

#import <RestKit/ObjectMapping/RKObjectMappingOperationDataSource.h>
#import <RestKit/ObjectMapping/RKObjectUtilities.h>
#import <RestKit/ObjectMapping/RKRelationshipMapping.h>
#import <RestKit/Support/RKErrors.h>
#import <RestKit/Support/RKLog.h>
#import <RestKit/Testing/RKMappingTest.h>

// Core Data
#ifdef _COREDATADEFINES_H
#if __has_include("RKCoreData.h")
#define RKCoreDataIncluded
#import <RestKit/CoreData/RKConnectionDescription.h>
#import <RestKit/CoreData/RKEntityMapping.h>
#import <RestKit/CoreData/RKFetchRequestManagedObjectCache.h>
#import <RestKit/CoreData/RKManagedObjectMappingOperationDataSource.h>
#import <RestKit/Testing/RKConnectionTestExpectation.h>
#endif
#endif

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
#ifdef RKCoreDataIncluded
@property (nonatomic, strong, readonly) RKConnectionDescription *connection;
#endif
@property (nonatomic, strong, readonly) id value;

@property (weak, nonatomic, readonly) NSString *sourceKeyPath;
@property (weak, nonatomic, readonly) NSString *destinationKeyPath;

+ (RKMappingTestEvent *)eventWithMapping:(RKPropertyMapping *)propertyMapping value:(id)value;

#ifdef RKCoreDataIncluded
+ (RKMappingTestEvent *)eventWithConnection:(RKConnectionDescription *)connection value:(id)value;
#endif

@end

@interface RKMappingTestEvent ()
@property (nonatomic, strong, readwrite) id value;
@property (nonatomic, strong, readwrite) RKPropertyMapping *propertyMapping;
#ifdef RKCoreDataIncluded
@property (nonatomic, strong, readwrite) RKConnectionDescription *connection;
#endif
@end

@implementation RKMappingTestEvent

+ (RKMappingTestEvent *)eventWithMapping:(RKPropertyMapping *)propertyMapping value:(id)value
{
    RKMappingTestEvent *event = [RKMappingTestEvent new];
    event.value = value;
    event.propertyMapping = propertyMapping;

    return event;
}

#ifdef RKCoreDataIncluded
+ (RKMappingTestEvent *)eventWithConnection:(RKConnectionDescription *)connection value:(id)value
{
    RKMappingTestEvent *event = [RKMappingTestEvent new];
    event.connection = connection;
    event.value = value;
    return event;
}
#endif

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
    if (self.propertyMapping) {
        return [NSString stringWithFormat:@"%@ mapped sourceKeyPath '%@' => destinationKeyPath '%@' with value: %@>", [self class],
                self.sourceKeyPath, self.destinationKeyPath, self.value];
    }
#ifdef RKCoreDataIncluded
    else if (self.connection) {
        if ([self.connection isForeignKeyConnection]) {
            return [NSString stringWithFormat:@"%@ connected Relationship '%@' using attributes '%@' to value: %@>", [self class],
                    [self.connection.relationship name], [self.connection.attributes valueForKey:@"name"], self.value];
        } else if ([self.connection isKeyPathConnection]) {
            return [NSString stringWithFormat:@"%@ connected Relationship '%@' using keyPath '%@' to value: %@>", [self class],
                    [self.connection.relationship name], self.connection.keyPath, self.value];
        }
    }
#endif
    
    return [super description];
}

@end

///-----------------------------------------------------------------------------
///-----------------------------------------------------------------------------

@interface RKMappingTest () <RKMappingOperationDelegate>
@property (nonatomic, strong, readwrite) RKMapping *mapping;
@property (nonatomic, strong, readwrite) id sourceObject;
@property (nonatomic, strong, readwrite) id destinationObject;
@property (nonatomic, strong) NSMutableArray *expectations;
@property (nonatomic, strong) NSMutableArray *events;
@property (nonatomic, assign, getter = hasPerformedMapping) BOOL performedMapping;

// Method Definitions for old compilers
- (void)performMapping;
- (void)verifyExpectation:(RKPropertyMappingTestExpectation *)expectation;

@end

@implementation RKMappingTest

+ (instancetype)testForMapping:(RKMapping *)mapping sourceObject:(id)sourceObject destinationObject:(id)destinationObject
{
    return [[self alloc] initWithMapping:mapping sourceObject:sourceObject destinationObject:destinationObject];
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"-init is not a valid initializer for the class %@, use designated initilizer -initWithMapping", NSStringFromClass([self class])]
                                 userInfo:nil];
    return [self init];
}

- (instancetype)initWithMapping:(RKMapping *)mapping sourceObject:(id)sourceObject destinationObject:(id)destinationObject
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
        self.performedMapping = NO;
    }

    return self;
}

- (void)addExpectation:(id)expectation
{
    NSParameterAssert(expectation);
    Class connectionTestExpectation = NSClassFromString(@"RKConnectionTestExpectation");
    if (![expectation isKindOfClass:[RKPropertyMappingTestExpectation class]] && ![expectation isKindOfClass:connectionTestExpectation]) {
        [NSException raise:NSInvalidArgumentException
                    format:@"Invalid expectation: expected an object of type `%@` or `%@`, but instead got a `%@`",
                           [RKPropertyMappingTestExpectation class], @"RKConnectionTestExpectation", expectation];
    }
    [self.expectations addObject:expectation];
}

- (RKMappingTestEvent *)eventMatchingExpectation:(id)expectation
{
#ifdef RKCoreDataIncluded
    Class connectionTestExpectation = NSClassFromString(@"RKConnectionTestExpectation");
#endif
    for (RKMappingTestEvent *event in [self.events copy]) {
        if ([expectation isKindOfClass:[RKPropertyMappingTestExpectation class]]) {
            RKPropertyMappingTestExpectation *propertyExpectation = (RKPropertyMappingTestExpectation *) expectation;
            if ([event.sourceKeyPath isEqualToString:propertyExpectation.sourceKeyPath] && [event.destinationKeyPath isEqualToString:propertyExpectation.destinationKeyPath]) {
                return event;
            } else if ((event.sourceKeyPath == nil && propertyExpectation.sourceKeyPath == nil) && ([event.destinationKeyPath isEqualToString:propertyExpectation.destinationKeyPath])) {
                return event;
            }
        }
#ifdef RKCoreDataIncluded
        else if ([expectation isKindOfClass:connectionTestExpectation]) {
            RKConnectionTestExpectation *connectionExpectation = (RKConnectionTestExpectation *) expectation;
            if ([[event.connection.relationship name] isEqualToString:connectionExpectation.relationshipName]) {
                return event;
            }
        }
#endif
    }

    return nil;
}

- (NSError *)errorForExpectation:(RKPropertyMappingTestExpectation *)expectation
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

- (BOOL)event:(RKMappingTestEvent *)event satisfiesExpectation:(id)expectation error:(NSError **)error
{
    BOOL success = NO;

    NSDictionary *userInfo = @{ RKMappingTestEventErrorKey : event,
                                RKMappingTestExpectationErrorKey : expectation };
    if ([expectation isKindOfClass:[RKPropertyMappingTestExpectation class]]) {
        RKPropertyMappingTestExpectation *propertyExpectation = (RKPropertyMappingTestExpectation *)expectation;
        if (propertyExpectation.evaluationBlock) {
            // Let the expectation block evaluate the match
            NSError *blockError = nil;
            success = propertyExpectation.evaluationBlock(expectation, event.propertyMapping, event.value, &blockError);
            
            if (! success) {
                if (blockError) {
                    // If the block has given us an error, use the reason
                    NSMutableDictionary *mutableUserInfo = [userInfo mutableCopy];
                    [mutableUserInfo setValue:blockError forKey:NSUnderlyingErrorKey];
                    NSString *reason = [NSString stringWithFormat:@"expected to %@ with value %@ '%@', but it did not",
                                        expectation, [event.value class], event.value];
                    
                    if (error) {
                        *error = [self errorForExpectation:expectation
                                                  withCode:RKMappingTestEvaluationBlockError
                                                  userInfo:mutableUserInfo
                                               description:[blockError localizedDescription]
                                                    reason:reason];
                        
                        *error = blockError;
                    }
                } else {
                    NSString *description = [NSString stringWithFormat:@"evaluation block returned `NO` for %@ value '%@'", [event.value class], event.value];
                    NSString *reason = [NSString stringWithFormat:@"expected to %@ with value %@ '%@', but it did not",
                                        expectation, [event.value class], event.value];
                    if (error) {
                        *error = [self errorForExpectation:expectation
                                                  withCode:RKMappingTestEvaluationBlockError
                                                  userInfo:userInfo
                                               description:description
                                                    reason:reason];
                    }
                }
            }
        } else if (propertyExpectation.value) {
            // Use RestKit comparison magic to match values
            success = RKObjectIsEqualToObject(event.value, propertyExpectation.value);
            
            if (! success) {
                NSString *description = [NSString stringWithFormat:@"mapped to unexpected %@ value '%@'", [event.value class], event.value];
                NSString *reason = [NSString stringWithFormat:@"expected to %@, but instead got %@ '%@'",
                                    expectation, [event.value class], event.value];
                if (error) {
                    *error = [self errorForExpectation:expectation
                                              withCode:RKMappingTestValueInequalityError
                                              userInfo:userInfo
                                           description:description
                                                reason:reason];
                }
            }
        } else if (propertyExpectation.mapping) {
            if ([event.propertyMapping isKindOfClass:[RKRelationshipMapping class]]) {
                // Check the mapping that was used to map the relationship
                RKMapping *relationshipMapping = [(RKRelationshipMapping *)event.propertyMapping mapping];
                success = [relationshipMapping isEqualToMapping:propertyExpectation.mapping];
                
                if (! success) {
                    NSString *description = [NSString stringWithFormat:@"mapped using unexpected mapping: %@", relationshipMapping];
                    NSString *reason = [NSString stringWithFormat:@"expected to %@, but was instead mapped using: %@",
                                        expectation, relationshipMapping];
                    if (error) {
                        *error = [self errorForExpectation:expectation
                                                  withCode:RKMappingTestMappingMismatchError
                                                  userInfo:userInfo
                                               description:description
                                                    reason:reason];
                    }
                }
            } else {
                NSString *description = [NSString stringWithFormat:@"expected a property mapping of type `RKRelationshipMapping` but instead got a `%@`", [propertyExpectation.mapping class]];
                NSString *reason = [NSString stringWithFormat:@"expected to %@, but instead of a `RKRelationshipMapping` got a `%@`",
                                    expectation, [propertyExpectation.mapping class]];
                if (error) {
                    *error = [self errorForExpectation:expectation
                                              withCode:RKMappingTestMappingMismatchError
                                              userInfo:userInfo
                                           description:description
                                                reason:reason];
                }
                
                // Error message here that a relationship was not mapped!!!
                return NO;
            }
        } else {
            // We only wanted to know that a mapping occured between the keyPaths
            success = YES;
        }
    }
#ifdef RKCoreDataIncluded
    else if ([expectation isKindOfClass:[RKConnectionTestExpectation class]]) {
        RKConnectionTestExpectation *connectionExpectation = (RKConnectionTestExpectation *)expectation;
        id expectedValue = connectionExpectation.value;
        id connectedValue = event.value;
        
        // Check that the connection attributes match
        if (connectionExpectation.attributes) {
            RKMappingTestCondition([connectionExpectation.attributes isEqualToDictionary:event.connection.attributes], RKMappingTestValueInequalityError, error, @"established connection using unexpected attributes: %@", event.connection.attributes);
        }
    
        // Wrong objects
        if (expectedValue) {
            RKMappingTestCondition(connectedValue, RKMappingTestValueInequalityError, error, @"unexpectedly connected to nil object set (%@)", connectedValue);
            
            if ([connectedValue isKindOfClass:[NSManagedObject class]] && [connectionExpectation.value isKindOfClass:[NSManagedObject class]]) {
                // Do a managed object ID comparison
                RKMappingTestCondition([[connectedValue objectID] isEqual:[expectedValue objectID]], RKMappingTestValueInequalityError, error, @"connected to unexpected managed object: %@", connectedValue);
            } else {
                // If we are connecting to a collection of managed objects, do a comparison of object IDs
                if (RKObjectIsCollectionContainingOnlyManagedObjects(connectedValue) && RKObjectIsCollectionContainingOnlyManagedObjects(expectedValue)) {
                    RKMappingTestCondition(RKObjectIsEqualToObject([connectedValue valueForKeyPath:@"objectID"], [expectedValue valueForKeyPath:@"objectID"]), RKMappingTestValueInequalityError, error, @"connected to unexpected %@ value '%@'", [connectedValue class], connectedValue);
                } else {
                    RKMappingTestCondition(RKObjectIsEqualToObject(connectedValue, expectedValue), RKMappingTestValueInequalityError, error, @"connected to unexpected %@ value '%@'", [connectedValue class], connectedValue);
                }
            }
        } else {
            RKMappingTestCondition(connectedValue == nil, RKMappingTestValueInequalityError, error, @"unexpectedly connected to non-nil object set (%@)", connectedValue);
        }
        
        return YES;
    }
#endif
    return success;
}

- (id<RKMappingOperationDataSource>)dataSourceForMappingOperation:(RKMappingOperation *)mappingOperation
{
    // If we have been given an explicit data source, use it
    if (self.mappingOperationDataSource) return self.mappingOperationDataSource;
    
#ifdef RKCoreDataIncluded
    if ([self.mapping isKindOfClass:[RKEntityMapping class]]) {
        NSAssert(self.managedObjectContext, @"Cannot test an `RKEntityMapping` with a nil managed object context.");
        id<RKManagedObjectCaching> managedObjectCache = self.managedObjectCache ?: [RKFetchRequestManagedObjectCache new];
        RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:self.managedObjectContext cache:managedObjectCache];
        
        // Configure an operation queue to enable easy testing of connection operations
        NSOperationQueue *operationQueue = [NSOperationQueue new];
        dataSource.operationQueue = operationQueue;
        return dataSource;
    } else {
        return [RKObjectMappingOperationDataSource new];
    }
#else
    return [RKObjectMappingOperationDataSource new];
#endif
}

- (void)performMapping
{
    // Ensure repeated invocations of verify only result in a single mapping operation
    if (! self.hasPerformedMapping) {
        id sourceObject = self.rootKeyPath ? [self.sourceObject valueForKeyPath:self.rootKeyPath] : self.sourceObject;
        RKMappingOperation *mappingOperation = [[RKMappingOperation alloc] initWithSourceObject:sourceObject destinationObject:self.destinationObject mapping:self.mapping];
        id<RKMappingOperationDataSource> dataSource = [self dataSourceForMappingOperation:mappingOperation];
        mappingOperation.dataSource = dataSource;
        mappingOperation.delegate = self;
        [mappingOperation start];
        if (mappingOperation.error) {
            [NSException raise:NSInternalInconsistencyException format:@"%p: failed with error: %@\n%@ during mapping from %@ to %@ with mapping %@",
             self, mappingOperation.error, [self description], self.sourceObject, self.destinationObject, self.mapping];
        }
        
        // Let the connection operations execute to completion
#ifdef RKCoreDataIncluded
        Class managedObjectMappingOperationDataSourceClass = NSClassFromString(@"RKManagedObjectMappingOperationDataSource");
        if ([mappingOperation.dataSource isKindOfClass:managedObjectMappingOperationDataSourceClass]) {
            NSOperationQueue *operationQueue = [(RKManagedObjectMappingOperationDataSource *)mappingOperation.dataSource operationQueue];
            if (! [operationQueue isEqual:[NSOperationQueue mainQueue]]) {
                [operationQueue waitUntilAllOperationsAreFinished];
            }
        }
#endif

        self.performedMapping = YES;
        
        // Get the destination object from the mapping operation
        if (! self.destinationObject) self.destinationObject = mappingOperation.destinationObject;
    }
}

- (void)verifyExpectation:(RKPropertyMappingTestExpectation *)expectation
{
    RKMappingTestEvent *event = [self eventMatchingExpectation:expectation];
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
         [self description], [expectation summary]];
    }
}

- (void)verify
{
    [self performMapping];

    for (RKPropertyMappingTestExpectation *expectation in self.expectations) {
        [self verifyExpectation:expectation];
    }
}

#pragma mark - Evaluating Expectations

- (BOOL)evaluate
{
    [self performMapping];

    for (RKPropertyMappingTestExpectation *expectation in self.expectations) {
        if (! [self evaluateExpectation:expectation error:nil]) return NO;
    }

    return YES;
}

- (BOOL)evaluateExpectation:(id)expectation error:(NSError **)error
{
    NSParameterAssert(expectation);
    Class connectionTestExpectation = NSClassFromString(@"RKConnectionTestExpectation");
    if (! ([expectation isKindOfClass:[RKPropertyMappingTestExpectation class]] || (connectionTestExpectation && [expectation isKindOfClass:connectionTestExpectation]))) [NSException raise:NSInvalidArgumentException format:@"Must be an instance of `RKPropertyMappingTestExpectation` or `RKConnectionTestExpectation`"];
    [self performMapping];

    RKMappingTestEvent *event = [self eventMatchingExpectation:expectation];
    if (event) {
        if (! [self event:event satisfiesExpectation:expectation error:error]) {
            return NO;
        }
    } else {
        if (error) {
            NSDictionary *userInfo = @{
            RKMappingTestExpectationErrorKey : expectation,
            NSLocalizedDescriptionKey        : [NSString stringWithFormat:@"expected to %@, but did not.", [expectation summary]],
            NSLocalizedFailureReasonErrorKey : [NSString stringWithFormat:@"%@: %@, but did not.", [self description], [expectation summary]]
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

#ifdef RKCoreDataIncluded
- (void)mappingOperation:(RKMappingOperation *)operation didConnectRelationship:(NSRelationshipDescription *)relationship toValue:(id)value usingConnection:(RKConnectionDescription *)connection
{
    [self addEvent:[RKMappingTestEvent eventWithConnection:connection value:value]];
}
#endif

@end
