//
//  RKRefetchingMappingResultTests.m
//  RestKit
//
//  Created by Peter Robinett on 8/27/15.
//  Copyright (c) 2015 RestKit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "RKTestEnvironment.h"
#import "RKHuman.h"

#import "RKMappingResult.h"

// Expose the private constructor
@interface RKMappingInfo ()

- (instancetype)initWithObjectMapping:(RKObjectMapping *)objectMapping dynamicMapping:(RKDynamicMapping *)dynamicMapping;
- (void)addPropertyMapping:(RKPropertyMapping *)propertyMapping;

@end

// Expose the private object declared in RKManagedObjectRequestOperation.m
@interface RKRefetchingMappingResult : NSProxy

- (instancetype)initWithMappingResult:(RKMappingResult *)mappingResult
       managedObjectContext:(NSManagedObjectContext *)managedObjectContext
                mappingInfo:(NSDictionary *)mappingInfo;
@end

@interface RKRefetchingMappingResultTests : XCTestCase

@property RKManagedObjectStore *managedObjectStore;
@property RKObjectManager *objectManager;
@property RKObjectMapping *mapping;
@property RKMappingInfo *mappingInfo;
@property NSManagedObjectContext *destinationContext;

@end

static NSString * const RKRefetchingMappingResultTestsKey = @"human";
static NSString * const RKRefetchingMappingResultTestsEntityName = @"Human";

@implementation RKRefetchingMappingResultTests

- (void)setUp
{
    self.managedObjectStore = [RKTestFactory managedObjectStore];

    self.objectManager = [RKTestFactory objectManager];
    self.objectManager.managedObjectStore = self.managedObjectStore;

    self.mapping = [RKEntityMapping mappingForEntityForName:RKRefetchingMappingResultTestsEntityName inManagedObjectStore:self.managedObjectStore];
    self.mappingInfo = [[RKMappingInfo alloc] initWithObjectMapping:self.mapping dynamicMapping:nil];

    self.destinationContext = [self.managedObjectStore newChildManagedObjectContextWithConcurrencyType:NSMainQueueConcurrencyType tracksChanges:NO];
}

- (void)tearDown
{
    self.destinationContext = nil;
    self.mappingInfo = nil;
    self.mapping = nil;
    self.objectManager = nil;
    self.managedObjectStore = nil;
}

- (void)testPermanentObjectID {
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:RKRefetchingMappingResultTestsEntityName inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human.name = @"Blake Watters";
    human.railsID = @1;
    [self.objectManager.managedObjectStore.persistentStoreManagedObjectContext save:nil];

    XCTAssertFalse([human.objectID isTemporaryID], @"The object should have a permanent objectID");

    RKMappingResult *result = [[RKMappingResult alloc] initWithDictionary:@{RKRefetchingMappingResultTestsKey: human}];

    RKRefetchingMappingResult *refetchingResult = [[RKRefetchingMappingResult alloc] initWithMappingResult:result managedObjectContext:self.destinationContext mappingInfo:@{RKRefetchingMappingResultTestsKey: @[self.mappingInfo]}];

    // treat the proxy as a normal mapping result
    RKMappingResult *proxiedResult = (RKMappingResult *)refetchingResult;
    // interact with the mapping result as normal
    RKHuman *refetchedHuman = proxiedResult.dictionary[RKRefetchingMappingResultTestsKey];

    XCTAssertNotNil(refetchedHuman, @"There should be a object");
    XCTAssertTrue([refetchedHuman isKindOfClass:[RKHuman class]], @"The object should be an RKHuman");
    XCTAssertNotEqualObjects(human, refetchedHuman, @"The objects should not match");
    XCTAssertEqualObjects(refetchedHuman.managedObjectContext, self.destinationContext, @"The object should be on the destination context");
    XCTAssertEqualObjects(human.objectID, refetchedHuman.objectID, @"The objectIDs should match");
}

- (void)testTemporaryObjectID {
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:RKRefetchingMappingResultTestsEntityName inManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext];
    human.name = @"Blake Watters";
    human.railsID = @1;

    XCTAssertTrue([human.objectID isTemporaryID], @"The object should have a temporary objectID");

    RKMappingResult *result = [[RKMappingResult alloc] initWithDictionary:@{RKRefetchingMappingResultTestsKey: human}];

    RKRefetchingMappingResult *refetchingResult = [[RKRefetchingMappingResult alloc] initWithMappingResult:result managedObjectContext:self.destinationContext mappingInfo:@{RKRefetchingMappingResultTestsKey: @[self.mappingInfo]}];

    // treat the proxy as a normal mapping result
    RKMappingResult *proxiedResult = (RKMappingResult *)refetchingResult;
    // interact with the mapping result as normal
    RKHuman *refetchedHuman = proxiedResult.dictionary[RKRefetchingMappingResultTestsKey];

    XCTAssertNil(refetchedHuman, @"There shouldn't be a object");
}

@end
