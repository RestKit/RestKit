//
//  RKMappingTestTest.m
//  RestKit
//
//  Created by Blake Watters on 1/3/13.
//  Copyright (c) 2013 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKMappingTest.h"
#import "RKTestUser.h"
#import "RKHuman.h"
#import "RKCat.h"

@interface RKMappingTestTest : XCTestCase
@property (nonatomic, strong) id objectRepresentation;
@property (nonatomic, strong) RKMappingTest *mappingTest;
@end

@implementation RKMappingTestTest

- (void)setUp
{
    self.objectRepresentation = [RKTestFixture parsedObjectWithContentsOfFixture:@"user.json"];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping addAttributeMappingsFromDictionary:@{
     @"id":         @"userID",
     @"name":       @"name",
     @"birthdate":  @"birthDate",
     @"created_at": @"createdAt"
     }];
    RKObjectMapping *addressMapping = [RKObjectMapping mappingForClass:[RKTestAddress class]];
    [addressMapping addAttributeMappingsFromDictionary:@{ @"id": @"addressID"}];
    [addressMapping addAttributeMappingsFromArray:@[ @"city", @"state", @"country" ]];
    [mapping addRelationshipMappingWithSourceKeyPath:@"address" mapping:addressMapping];
    RKObjectMapping *coordinateMapping = [RKObjectMapping mappingForClass:[RKTestCoordinate class]];
    [coordinateMapping addAttributeMappingsFromArray:@[ @"latitude", @"longitude" ]];
    [mapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:nil toKeyPath:@"coordinate" withMapping:coordinateMapping]];
    
    self.mappingTest = [[RKMappingTest alloc] initWithMapping:mapping sourceObject:self.objectRepresentation destinationObject:nil];
}

- (void)testMappingTestForAttribute
{
    [self.mappingTest addExpectation:[RKPropertyMappingTestExpectation expectationWithSourceKeyPath:@"name"
                                                                                 destinationKeyPath:@"name"
                                                                                              value:@"Blake Watters"]];
    expect([self.mappingTest evaluate]).to.equal(YES);
}

- (void)testMappingTestFailureForAttribute
{
    [self.mappingTest addExpectation:[RKPropertyMappingTestExpectation expectationWithSourceKeyPath:@"name"
                                                                                 destinationKeyPath:@"name"
                                                                                              value:@"Invalid"]];
    expect([self.mappingTest evaluate]).to.equal(NO);
}

- (void)testMappingTestForAttributeWithBlock
{
    [self.mappingTest addExpectation:[RKPropertyMappingTestExpectation expectationWithSourceKeyPath:@"name" destinationKeyPath:@"name" evaluationBlock:^BOOL(RKPropertyMappingTestExpectation *expectation, RKPropertyMapping *mapping, id mappedValue, NSError *__autoreleasing *error) {
        return [mappedValue isEqualToString:@"Blake Watters"];
    }]];
    expect([self.mappingTest evaluate]).to.equal(YES);
}

- (void)testMappingTestForRelationship
{
    RKTestCoordinate *coordinate = [RKTestCoordinate new];
    coordinate.latitude = 12345;
    coordinate.longitude = 56789;
    [self.mappingTest addExpectation:[RKPropertyMappingTestExpectation expectationWithSourceKeyPath:nil
                                                                                 destinationKeyPath:@"coordinate"
                                                                                              value:coordinate]];
    expect([self.mappingTest evaluate]).to.equal(YES);
}

- (void)testMappingTestForRelationshipWithBlock
{
    [self.mappingTest addExpectation:[RKPropertyMappingTestExpectation expectationWithSourceKeyPath:@"address" destinationKeyPath:@"address" evaluationBlock:^BOOL(RKPropertyMappingTestExpectation *expectation, RKPropertyMapping *mapping, id mappedValue, NSError *__autoreleasing *error) {
        RKTestAddress *address = (RKTestAddress *)mappedValue;
        return [address.addressID isEqualToNumber:@(1234)] && [address.city isEqualToString:@"Carrboro"] && [address.state isEqualToString:@"North Carolina"] && [address.country isEqualToString:@"USA"];
        return YES;
    }]];
    expect([self.mappingTest evaluate]).to.equal(YES);
}

- (void)testEvaluateExpectationReturnsUnsatisfiedExpectationErrorForUnmappedKeyPath
{
    NSError *error = nil;
    BOOL success = [self.mappingTest evaluateExpectation:[RKPropertyMappingTestExpectation expectationWithSourceKeyPath:@"nonexistant"
                                                                                          destinationKeyPath:@"name"
                                                                                                       value:@"Invalid"] error:&error];
    expect(success).to.equal(NO);
    expect(error).notTo.beNil();
    expect(error.code).to.equal(RKMappingTestUnsatisfiedExpectationError);
    expect([error localizedDescription]).to.equal(@"expected to map 'nonexistant' to 'name', but did not.");
}

- (void)testEvaluateExpectationReturnsValueInequalityErrorErrorForValueMismatch
{
    NSError *error = nil;
    BOOL success = [self.mappingTest evaluateExpectation:[RKPropertyMappingTestExpectation expectationWithSourceKeyPath:@"name"
                                                                                                     destinationKeyPath:@"name"
                                                                                                                  value:@"Incorrect"] error:&error];
    expect(success).to.equal(NO);
    expect(error).notTo.beNil();
    expect(error.code).to.equal(RKMappingTestValueInequalityError);
    expect([error localizedDescription]).to.equal(@"mapped to unexpected __NSCFString value 'Blake Watters'");
}

- (void)testEvaluateExpectationReturnsEvaluationBlockErrorForBlockFailure
{
    NSError *error = nil;
    BOOL success = [self.mappingTest evaluateExpectation:[RKPropertyMappingTestExpectation expectationWithSourceKeyPath:@"address" destinationKeyPath:@"address" evaluationBlock:^BOOL(RKPropertyMappingTestExpectation *expectation, RKPropertyMapping *mapping, id mappedValue, NSError *__autoreleasing *error) {
        return NO;
    }] error:&error];
    expect(success).to.equal(NO);
    expect(error).notTo.beNil();
    expect(error.code).to.equal(RKMappingTestEvaluationBlockError);
    assertThat([error localizedDescription], startsWith(@"evaluation block returned `NO` for RKTestAddress value '<RKTestAddress:"));
}

- (void)testEvaluateExpectationReturnsMappingMismatchErrorForMismatchedMapping
{
    NSError *error = nil;
    RKDynamicMapping *dynamicMapping = [RKDynamicMapping new];
    BOOL success = [self.mappingTest evaluateExpectation:[RKPropertyMappingTestExpectation expectationWithSourceKeyPath:@"address" destinationKeyPath:@"address" mapping:dynamicMapping] error:&error];
    expect(success).to.equal(NO);
    expect(error).notTo.beNil();
    expect(error.code).to.equal(RKMappingTestMappingMismatchError);
    assertThat([error localizedDescription], startsWith(@"mapped using unexpected mapping: <RKObjectMapping"));
}

- (void)testVerifyWithFailureRaisesException
{
    NSException *caughtException = nil;
    @try {
        [self.mappingTest addExpectation:[RKPropertyMappingTestExpectation expectationWithSourceKeyPath:@"name"
                                                                                     destinationKeyPath:@"name"
                                                                                                  value:@"Invalid"]];
        [self.mappingTest verify];
    }
    @catch (NSException *exception) {
        caughtException = exception;
    }
    expect(caughtException).notTo.beNil();
    expect([caughtException name]).to.equal(RKMappingTestVerificationFailureException);
    expect([caughtException reason]).to.equal(@"mapped to unexpected __NSCFString value 'Blake Watters'");
}

@end

@interface RKMappingTestCoreDataIntegrationTest : RKTestCase
@property (nonatomic, strong) id objectRepresentation;
@property (nonatomic, strong) RKManagedObjectStore *managedObjectStore;
@property (nonatomic, strong) RKMappingTest *mappingTest;
@property (nonatomic, strong) RKEntityMapping *entityMapping;
@property (nonatomic, strong) RKCat *asia;
@end

@implementation RKMappingTestCoreDataIntegrationTest

- (void)setUp
{
    [RKTestFactory setUp];
    
    self.objectRepresentation = [RKTestFixture parsedObjectWithContentsOfFixture:@"with_to_one_relationship.json"];
    self.managedObjectStore = [RKTestFactory managedObjectStore];
    self.entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:self.managedObjectStore];
    [self.entityMapping addAttributeMappingsFromDictionary:@{
     @"name":               @"name",
     @"age":                @"age",
     @"favorite_cat_id":    @"favoriteCatID"
     }];   
    self.mappingTest = [[RKMappingTest alloc] initWithMapping:self.entityMapping sourceObject:self.objectRepresentation destinationObject:nil];
    self.mappingTest.rootKeyPath = @"human";
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:self.managedObjectStore.persistentStoreManagedObjectContext cache:managedObjectCache];
    dataSource.operationQueue = [NSOperationQueue new];
    self.mappingTest.mappingOperationDataSource = dataSource;
    self.mappingTest.managedObjectContext = self.managedObjectStore.persistentStoreManagedObjectContext;
    self.mappingTest.managedObjectCache = managedObjectCache;
    
    self.asia = [NSEntityDescription insertNewObjectForEntityForName:@"Cat" inManagedObjectContext:self.mappingTest.managedObjectContext];
    self.asia.name = @"Asia";
    self.asia.railsID = @(1234);
}

- (void)tearDown
{
    [RKTestFactory tearDown];
}

- (void)testMappingTestForCoreDataAttribute
{
    [self.mappingTest addExpectation:[RKPropertyMappingTestExpectation expectationWithSourceKeyPath:@"name"
                                                                                 destinationKeyPath:@"name"
                                                                                              value:@"Blake Watters"]];
    expect([self.mappingTest evaluate]).to.equal(YES);
}

- (void)testMappingTestForCoreDataRelationship
{
    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"Cat" inManagedObjectStore:self.managedObjectStore];
    catMapping.identificationAttributes = @[ @"name" ];
    [catMapping addAttributeMappingsFromDictionary:@{ @"id": @"railsID" }];
    [catMapping addAttributeMappingsFromArray:@[ @"name" ]];
    [self.entityMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"favorite_cat" toKeyPath:@"favoriteCat" withMapping:catMapping]];
    [self.mappingTest addExpectation:[RKPropertyMappingTestExpectation expectationWithSourceKeyPath:@"favorite_cat"
                                                                                 destinationKeyPath:@"favoriteCat"
                                                                                              value:self.asia]];
    expect([self.mappingTest evaluate]).to.equal(YES);
}

- (void)testMappingTestForCoreDataRelationshipFromNilSourceKeyPath
{
    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"Cat" inManagedObjectStore:self.managedObjectStore];
    catMapping.identificationAttributes = @[ @"name" ];
    [catMapping addAttributeMappingsFromDictionary:@{ @"id": @"railsID" }];
    [catMapping addAttributeMappingsFromArray:@[ @"name" ]];
    [self.entityMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:nil toKeyPath:@"favoriteCat" withMapping:catMapping]];
    [self.mappingTest addExpectation:[RKPropertyMappingTestExpectation expectationWithSourceKeyPath:nil
                                                                                 destinationKeyPath:@"favoriteCat"]];
    expect([self.mappingTest evaluate]).to.equal(YES);
}

- (void)testMappingTestForCoreDataRelationshipConnection
{
    [self.entityMapping addConnectionForRelationship:@"favoriteCat" connectedBy:@{ @"favoriteCatID": @"railsID" }];
    [self.mappingTest addExpectation:[RKConnectionTestExpectation expectationWithRelationshipName:@"favoriteCat" attributes:@{ @"favoriteCatID": @"railsID" } value:self.asia]];
    expect([self.mappingTest evaluate]).to.equal(YES);
}

@end
