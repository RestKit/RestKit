//
//  RKConnectionDescriptionTest.m
//  RestKit
//
//  Created by Blake Watters on 11/25/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKConnectionDescription.h"

@interface RKConnectionDescriptionTest : RKTestCase
@property (nonatomic, strong) NSRelationshipDescription *relationship;
@end

@implementation RKConnectionDescriptionTest

- (void)expectBlock:(void (^)(void))block toRaise:(NSString *)exceptionName reason:(NSString *)reason
{
    NSException *caughtException = nil;
    @try {
        block();
    }
    @catch (NSException *exception) {
        caughtException = exception;
    }
    @finally {
        expect(caughtException).notTo.beNil();
        if (caughtException) {
            if (exceptionName) expect([caughtException name]).to.equal(exceptionName);
            if (reason) expect([caughtException reason]).to.equal(reason);
        }
    }
}

- (void)setUp
{
    [RKTestFactory setUp];
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    self.relationship = [entity relationshipsByName][@"cats"];
}

- (void)tearDown
{
    [RKTestFactory tearDown];
}

- (void)testInitWithNilRelationshipRaisesError
{
    expect(^{ RKConnectionDescription __unused *connection = [[RKConnectionDescription alloc] initWithRelationship:nil attributes:@{ @"catID": @"catID" }]; }).to.raiseWithReason(NSInternalInconsistencyException, @"Invalid parameter not satisfying: relationship");
}

- (void)testInitWithNilAttributesRaisesError
{
//    expect(^{ RKConnectionDescription __unused *connection = [[RKConnectionDescription alloc] initWithRelationship:self.relationship attributes:@"Invalid parameter not satisfying: attributes"]; }).to.raise(NSInternalInconsistencyException);
    [self expectBlock:^{
        RKConnectionDescription __unused *connection = [[RKConnectionDescription alloc] initWithRelationship:self.relationship attributes:nil];
    } toRaise:NSInternalInconsistencyException reason:@"Invalid parameter not satisfying: attributes"];
}

- (void)testInitWithEmptyAttributesDictionaryRaisesError
{
//    expect(^{ RKConnectionDescription __unused *connection = [[RKConnectionDescription alloc] initWithRelationship:self.relationship attributes:@{}]; }).to.raiseWithReason(NSInternalInconsistencyException, @"Cannot connect a relationship without at least one pair of attributes describing the connection");
    [self expectBlock:^{
        RKConnectionDescription __unused *connection = [[RKConnectionDescription alloc] initWithRelationship:self.relationship attributes:@{}];
    } toRaise:NSInternalInconsistencyException reason:@"Cannot connect a relationship without at least one pair of attributes describing the connection"];
}

- (void)testInitWithAttributeThatDoesNotExistInEntityRaisesError
{
//    expect(^{ RKConnectionDescription __unused *connection = [[RKConnectionDescription alloc] initWithRelationship:self.relationship attributes:@{ @"invalidID": @"catID" }]; }).to.raiseWithReason(NSInternalInconsistencyException, @"Invalid parameter not satisfying: relationship");    
    [self expectBlock:^{
        RKConnectionDescription __unused *connection = [[RKConnectionDescription alloc] initWithRelationship:self.relationship attributes:@{ @"invalidID": @"catID" }];
    } toRaise:NSInternalInconsistencyException reason:@"Cannot connect relationship: invalid attributes given for source entity 'Human': invalidID"];
}

- (void)testInitWithAttributeThatDoesNotExistInDestinationEntityRaisesError
{
//    expect(^{ RKConnectionDescription __unused *connection = [[RKConnectionDescription alloc] initWithRelationship:self.relationship attributes:@{ @"favoriteCatID": @"invalid" }]; }).to.raiseWithReason(NSInternalInconsistencyException, @"Invalid parameter not satisfying: relationship");
    [self expectBlock:^{
        RKConnectionDescription __unused *connection = [[RKConnectionDescription alloc] initWithRelationship:self.relationship attributes:@{ @"favoriteCatID": @"invalid" }];
    } toRaise:NSInternalInconsistencyException reason:@"Cannot connect relationship: invalid attributes given for destination entity 'Cat': invalid"];
}

@end
