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
    expect(^{ RKConnectionDescription __unused *connection = [[RKConnectionDescription alloc] initWithRelationship:self.relationship attributes:nil]; }).to.raiseWithReason(NSInternalInconsistencyException, @"Invalid parameter not satisfying: attributes");
}

- (void)testInitWithEmptyAttributesDictionaryRaisesError
{
    expect(^{ RKConnectionDescription __unused *connection = [[RKConnectionDescription alloc] initWithRelationship:self.relationship attributes:@{}]; }).to.raiseWithReason(NSInternalInconsistencyException, @"Cannot connect a relationship without at least one pair of attributes describing the connection");
}

- (void)testInitWithAttributeThatDoesNotExistInEntityRaisesError
{
    expect(^{ RKConnectionDescription __unused *connection = [[RKConnectionDescription alloc] initWithRelationship:self.relationship attributes:@{ @"invalidID": @"catID" }]; }).to.raiseWithReason(NSInternalInconsistencyException, @"Cannot connect relationship: invalid attributes given for source entity 'Human': invalidID");
}

- (void)testInitWithAttributeThatDoesNotExistInDestinationEntityRaisesError
{
    expect(^{ RKConnectionDescription __unused *connection = [[RKConnectionDescription alloc] initWithRelationship:self.relationship attributes:@{ @"favoriteCatID": @"invalid" }]; }).to.raiseWithReason(NSInternalInconsistencyException, @"Cannot connect relationship: invalid attributes given for destination entity 'Cat': invalid");
}

@end
