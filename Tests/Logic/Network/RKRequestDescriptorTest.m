//
//  RKRequestDescriptorTest.m
//  RestKit
//
//  Created by Blake Watters on 10/14/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKDynamicMapping.h"

@interface RKRequestDescriptorTest : RKTestCase

@end

@implementation RKRequestDescriptorTest

- (void)testValidArgumentsInitializeWithoutRaisingException
{
    RKObjectMapping *invalidMapping = [RKObjectMapping requestMapping];
    NSException *exception = nil;
    @try {
        [RKRequestDescriptor requestDescriptorWithObjectClass:[RKRequestDescriptorTest class] methods:RKHTTPMethodAny rootKeyPath:nil mapping:invalidMapping];
    }
    @catch (NSException *caughtExpection) {
        exception = caughtExpection;
    }
    @finally {
        expect(exception).to.beNil();
    }
}

- (void)testInvalidArgumentExceptionIsRaisedIfInitializedWithNonRequestMapping
{
    RKObjectMapping *invalidMapping = [RKObjectMapping mappingForClass:[RKRequestDescriptorTest class]];
    NSException *exception = nil;
    @try {
        [RKRequestDescriptor requestDescriptorWithObjectClass:[RKRequestDescriptorTest class] methods:RKHTTPMethodAny rootKeyPath:nil mapping:invalidMapping];
    }
    @catch (NSException *caughtExpection) {
        exception = caughtExpection;
    }
    @finally {
        expect(exception).notTo.beNil();
        expect(exception.name).to.equal(NSInvalidArgumentException);
        expect(exception.reason).to.equal(@"`RKRequestDescriptor` objects must be initialized with a mapping whose target class is `NSMutableDictionary`, got 'RKRequestDescriptorTest' (see `[RKObjectMapping requestMapping]`)");
    }
}

- (void)testInvalidArgumentExceptionIsRaisedInInitializedWithDynamicMappingContainingNonRequestMappings
{
    RKObjectMapping *invalidMapping = [RKObjectMapping mappingForClass:[RKRequestDescriptorTest class]];
    RKDynamicMapping *dynamicMapping = [RKDynamicMapping new];
    [dynamicMapping addMatcher:[RKObjectMappingMatcher matcherWithKeyPath:@"whatever" expectedValue:@"whatever" objectMapping:invalidMapping]];
    
    NSException *exception = nil;
    @try {
        [RKRequestDescriptor requestDescriptorWithObjectClass:[RKRequestDescriptorTest class] methods:RKHTTPMethodAny rootKeyPath:nil mapping:dynamicMapping];
    }
    @catch (NSException *caughtExpection) {
        exception = caughtExpection;
    }
    @finally {
        expect(exception).notTo.beNil();
        expect(exception.name).to.equal(NSInvalidArgumentException);
        expect(exception.reason).to.equal(@"`RKRequestDescriptor` objects may only be initialized with `RKDynamicMapping` objects containing `RKObjectMapping` objects whose target class is `NSMutableDictionary`, got 'RKRequestDescriptorTest' (see `[RKObjectMapping requestMapping]`)");
    }
}

- (void)testThatDescriptorsWithTheSameAttributesAreConsideredEqual
{
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    RKRequestDescriptor *firstDescriptor = [RKRequestDescriptor requestDescriptorWithObjectClass:[RKRequestDescriptorTest class]
                                                                                         methods:RKHTTPMethodAny
                                                                                     rootKeyPath:@"/issues"
                                                                                         mapping:mapping];
    RKRequestDescriptor *secondDescriptor = [RKRequestDescriptor requestDescriptorWithObjectClass:[RKRequestDescriptorTest class]
                                                                                          methods:RKHTTPMethodAny
                                                                                      rootKeyPath:@"/issues"
                                                                                          mapping:mapping];
    expect(firstDescriptor).to.equal(secondDescriptor);
}

- (void)testThatDescriptorsWithDifferentMappingsAreNotConsideredEqual
{
    RKRequestDescriptor *firstDescriptor = [RKRequestDescriptor requestDescriptorWithObjectClass:[RKRequestDescriptorTest class]
                                                                                         methods:RKHTTPMethodAny
                                                                                     rootKeyPath:@"/issues"
                                                                                         mapping:[RKObjectMapping requestMapping]];
    RKRequestDescriptor *secondDescriptor = [RKRequestDescriptor requestDescriptorWithObjectClass:[RKRequestDescriptorTest class]
                                                                                          methods:RKHTTPMethodAny
                                                                                      rootKeyPath:@"/issues"
                                                                                          mapping:[RKDynamicMapping new]];
    expect(firstDescriptor).toNot.equal(secondDescriptor);
}

- (void)testThatDescriptorsWithDifferentObjectClassesAreNotConsideredEqual
{
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    RKRequestDescriptor *firstDescriptor = [RKRequestDescriptor requestDescriptorWithObjectClass:[RKRequestDescriptorTest class]
                                                                                         methods:RKHTTPMethodAny
                                                                                     rootKeyPath:@"/issues"
                                                                                         mapping:mapping];
    RKRequestDescriptor *secondDescriptor = [RKRequestDescriptor requestDescriptorWithObjectClass:[NSObject class]
                                                                                          methods:RKHTTPMethodAny
                                                                                      rootKeyPath:@"/issues"
                                                                                          mapping:mapping];
    expect(firstDescriptor).toNot.equal(secondDescriptor);
}

- (void)testThatDescriptorsWithDifferentRootKeyPathsAreNotConsideredEqual
{
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    RKRequestDescriptor *firstDescriptor = [RKRequestDescriptor requestDescriptorWithObjectClass:[RKRequestDescriptorTest class]
                                                                                         methods:RKHTTPMethodAny
                                                                                     rootKeyPath:@"/issues"
                                                                                         mapping:mapping];
    RKRequestDescriptor *secondDescriptor = [RKRequestDescriptor requestDescriptorWithObjectClass:[RKRequestDescriptorTest class]
                                                                                          methods:RKHTTPMethodAny
                                                                                      rootKeyPath:@"/"
                                                                                          mapping:mapping];
    expect(firstDescriptor).toNot.equal(secondDescriptor);
}

@end
