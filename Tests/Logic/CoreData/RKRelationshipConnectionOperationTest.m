//
//  RKRelationshipConnectionOperationTest.m
//  RestKit
//
//  Created by Blake Watters on 9/29/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKHuman.h"
#import "RKCat.h"
#import "RKHouse.h"
#import "RKResident.h"
#import "RKChild.h"
#import "RKRelationshipConnectionOperation.h"
#import "RKFetchRequestManagedObjectCache.h"

@interface RKRelationshipConnectionOperationTest : SenTestCase

@end

@implementation RKRelationshipConnectionOperationTest

- (void)setUp
{
    [RKTestFactory setUp];
}

- (void)tearDown
{
    [RKTestFactory tearDown];
}

- (void)testSuccessfulConnectionOfToOneRelationship
{
    RKHuman *human = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:nil withProperties:nil];
    human.favoriteCatID = @250;
    RKCat *asia = [RKTestFactory insertManagedObjectForEntityForName:@"Cat" inManagedObjectContext:nil withProperties:nil];
    asia.railsID = @250;
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:[RKTestFactory managedObjectStore]];
    [mapping addConnectionForRelationship:@"favoriteCat" connectedBy:@{ @"favoriteCatID": @"railsID" } ];
    RKConnectionDescription *connection = [mapping connectionForRelationship:@"favoriteCat"];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKRelationshipConnectionOperation *operation = [[RKRelationshipConnectionOperation alloc] initWithManagedObject:human connections:@[ connection ] managedObjectCache:managedObjectCache];
    [operation start];
    assertThat(human.favoriteCat, is(equalTo(asia)));
}

- (void)testSuccessfulConnectionOfToManyRelationship
{
    RKHuman *human = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:nil withProperties:nil];
    human.sex = @"female";
    RKCat *asia = [RKTestFactory insertManagedObjectForEntityForName:@"Cat" inManagedObjectContext:nil withProperties:nil];
    asia.sex = @"female";
    RKCat *lola = [RKTestFactory insertManagedObjectForEntityForName:@"Cat" inManagedObjectContext:nil withProperties:nil];
    lola.sex = @"female";
    RKCat *roy = [RKTestFactory insertManagedObjectForEntityForName:@"Cat" inManagedObjectContext:nil withProperties:nil];
    roy.sex = @"male";

    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:[RKTestFactory managedObjectStore]];
    [mapping addConnectionForRelationship:@"cats" connectedBy:@"sex"];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKConnectionDescription *connection = [mapping connectionForRelationship:@"cats"];
    RKRelationshipConnectionOperation *operation = [[RKRelationshipConnectionOperation alloc] initWithManagedObject:human connections:@[ connection ] managedObjectCache:managedObjectCache];
    [operation start];
    assertThat(human.cats, hasCountOf(2));
    assertThat(human.cats, hasItems(asia, lola, nil));
}

- (void)testConnectionWithoutResultsNullifiesExistingRelationship
{
    RKHuman *human = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:nil withProperties:nil];
    human.sex = @"invalid";
    RKCat *asia = [RKTestFactory insertManagedObjectForEntityForName:@"Cat" inManagedObjectContext:nil withProperties:nil];
    asia.sex = @"female";
    RKCat *lola = [RKTestFactory insertManagedObjectForEntityForName:@"Cat" inManagedObjectContext:nil withProperties:nil];
    lola.sex = @"female";
    RKCat *roy = [RKTestFactory insertManagedObjectForEntityForName:@"Cat" inManagedObjectContext:nil withProperties:nil];
    roy.sex = @"male";

    human.cats = [NSSet setWithObjects:asia, lola, roy, nil];
    assertThat(human.cats, isNot(isEmpty()));

    // No cats with a sex of 'invalid'
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:[RKTestFactory managedObjectStore]];
    [mapping addConnectionForRelationship:@"cats" connectedBy:@{ @"sex": @"sex" }];
    RKConnectionDescription *connection = [mapping connectionForRelationship:@"cats"];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKRelationshipConnectionOperation *operation = [[RKRelationshipConnectionOperation alloc] initWithManagedObject:human connections:@[ connection ] managedObjectCache:managedObjectCache];
    [operation start];
    assertThat(human.cats, isEmpty());
}

#pragma mark - Key Path Connections

- (void)testConnectingToOneRelationshipViaKeyPath
{
    NSEntityDescription *entity = [[[RKTestFactory managedObjectStore] managedObjectModel] entitiesByName][@"Human"];
    NSRelationshipDescription *relationship = [entity relationshipsByName][@"landlord"];
    RKConnectionDescription *connection = [[RKConnectionDescription alloc] initWithRelationship:relationship keyPath:@"residence.owner"];

    RKHuman *tenant = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:nil withProperties:nil];
    RKHuman *homeowner = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:nil withProperties:nil];
    RKHouse *house = [RKTestFactory insertManagedObjectForEntityForName:@"House" inManagedObjectContext:nil withProperties:nil];
    house.owner = homeowner;
    tenant.residence = house;

    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKRelationshipConnectionOperation *operation = [[RKRelationshipConnectionOperation alloc] initWithManagedObject:tenant connections:@[ connection ] managedObjectCache:managedObjectCache];
    [operation start];

    expect(tenant.landlord).to.equal(homeowner);
}

- (void)testConnectingToManyRelationshipViaKeyPath
{
    NSEntityDescription *entity = [[[RKTestFactory managedObjectStore] managedObjectModel] entitiesByName][@"Human"];
    NSRelationshipDescription *relationship = [entity relationshipsByName][@"roommates"];
    RKConnectionDescription *connection = [[RKConnectionDescription alloc] initWithRelationship:relationship keyPath:@"house.residents"];

    RKHuman *human = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:nil withProperties:nil];
    RKHouse *house = [RKTestFactory insertManagedObjectForEntityForName:@"House" inManagedObjectContext:nil withProperties:nil];
    RKResident *resident1 = [RKTestFactory insertManagedObjectForEntityForName:@"Resident" inManagedObjectContext:nil withProperties:nil];
    RKResident *resident2 = [RKTestFactory insertManagedObjectForEntityForName:@"Resident" inManagedObjectContext:nil withProperties:nil];

    human.house = house;
    house.residents = [NSSet setWithObjects:resident1, resident2, nil];

    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKRelationshipConnectionOperation *operation = [[RKRelationshipConnectionOperation alloc] initWithManagedObject:human connections:@[ connection ] managedObjectCache:managedObjectCache];
    [operation start];

    NSSet *expectedRoommates = [NSSet setWithObjects:resident1, resident2, nil];
    expect(human.roommates).to.equal(expectedRoommates);
}

- (void)testConnectingAcrossToManyRelationshipsViaKeyPath
{
    NSEntityDescription *entity = [[[RKTestFactory managedObjectStore] managedObjectModel] entitiesByName][@"Human"];
    NSRelationshipDescription *relationship = [entity relationshipsByName][@"friends"];
    RKConnectionDescription *connection = [[RKConnectionDescription alloc] initWithRelationship:relationship keyPath:@"housesResidedAt.ownersInChronologicalOrder"];

    RKHuman *human = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:nil withProperties:nil];

    // Create 2 houses with 2 previous owners
    RKHouse *house1 = [RKTestFactory insertManagedObjectForEntityForName:@"House" inManagedObjectContext:nil withProperties:nil];
    RKHuman *homeowner1 = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:nil withProperties:nil];
    RKHuman *homeowner2 = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:nil withProperties:nil];
    house1.ownersInChronologicalOrder = [NSOrderedSet orderedSetWithObjects:homeowner1, homeowner2, nil];

    RKHouse *house2 = [RKTestFactory insertManagedObjectForEntityForName:@"House" inManagedObjectContext:nil withProperties:nil];
    RKHuman *homeowner3 = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:nil withProperties:nil];
    RKHuman *homeowner4 = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:nil withProperties:nil];
    house2.ownersInChronologicalOrder = [NSOrderedSet orderedSetWithObjects:homeowner3, homeowner4, nil];

    human.housesResidedAt = [NSOrderedSet orderedSetWithObjects:house1, house2, nil];

    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKRelationshipConnectionOperation *operation = [[RKRelationshipConnectionOperation alloc] initWithManagedObject:human connections:@[ connection ] managedObjectCache:managedObjectCache];
    [operation start];

    NSSet *expectedFriends = [NSSet setWithObjects:homeowner1, homeowner2, homeowner3, homeowner4, nil];
    expect(human.friends).to.haveCountOf(4);
    expect(human.friends).to.equal(expectedFriends);
}

- (void)testConnectingToManyOrderedSetRelationshipViaKeyPath
{
    NSEntityDescription *entity = [[[RKTestFactory managedObjectStore] managedObjectModel] entitiesByName][@"Human"];
    NSRelationshipDescription *relationship = [entity relationshipsByName][@"friendsInTheOrderWeMet"];
    RKConnectionDescription *connection = [[RKConnectionDescription alloc] initWithRelationship:relationship keyPath:@"housesResidedAt.ownersInChronologicalOrder"];

    RKHuman *human = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:nil withProperties:nil];

    // Create 2 houses with 2 previous owners
    RKHouse *house1 = [RKTestFactory insertManagedObjectForEntityForName:@"House" inManagedObjectContext:nil withProperties:nil];
    RKHuman *homeowner1 = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:nil withProperties:nil];
    RKHuman *homeowner2 = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:nil withProperties:nil];
    house1.ownersInChronologicalOrder = [NSOrderedSet orderedSetWithObjects:homeowner1, homeowner2, nil];

    RKHouse *house2 = [RKTestFactory insertManagedObjectForEntityForName:@"House" inManagedObjectContext:nil withProperties:nil];
    RKHuman *homeowner3 = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:nil withProperties:nil];
    RKHuman *homeowner4 = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:nil withProperties:nil];
    house2.ownersInChronologicalOrder = [NSOrderedSet orderedSetWithObjects:homeowner3, homeowner4, nil];

    human.housesResidedAt = [NSOrderedSet orderedSetWithObjects:house1, house2, nil];

    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKRelationshipConnectionOperation *operation = [[RKRelationshipConnectionOperation alloc] initWithManagedObject:human connections:@[ connection ] managedObjectCache:managedObjectCache];
    [operation start];

    NSOrderedSet *expectedFriends = [NSOrderedSet orderedSetWithObjects:homeowner1, homeowner2, homeowner3, homeowner4, nil];
    expect(human.friendsInTheOrderWeMet).to.equal(expectedFriends);
}

- (void)testConnectingToManyOrderedSetRelationshipWithEmptyTargetViaKeyPath
{
    NSEntityDescription *entity = [[[RKTestFactory managedObjectStore] managedObjectModel] entitiesByName][@"Human"];
    NSRelationshipDescription *relationship = [entity relationshipsByName][@"friendsInTheOrderWeMet"];
    RKConnectionDescription *connection = [[RKConnectionDescription alloc] initWithRelationship:relationship keyPath:@"housesResidedAt.ownersInChronologicalOrder"];

    RKHuman *human = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:nil withProperties:nil];

    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKRelationshipConnectionOperation *operation = [[RKRelationshipConnectionOperation alloc] initWithManagedObject:human connections:@[ connection ] managedObjectCache:managedObjectCache];
    [operation start];

    expect([human.friendsInTheOrderWeMet set]).to.beEmpty();
}

- (void)testConnectingToSubentities
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *childEntity = [NSEntityDescription entityForName:@"Child" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    NSRelationshipDescription *relationship = [childEntity relationshipsByName][@"friends"];
    RKConnectionDescription *connection = [[RKConnectionDescription alloc] initWithRelationship:relationship attributes:@{ @"friendIDs": @"railsID" }];
    connection.includesSubentities = YES;

    RKHuman *human = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:nil withProperties:nil];
    human.railsID = @(12345);
    RKChild *child = [RKTestFactory insertManagedObjectForEntityForName:@"Child" inManagedObjectContext:nil withProperties:nil];
    child.railsID = @(12345);

    RKChild *secondChild = [RKTestFactory insertManagedObjectForEntityForName:@"Child" inManagedObjectContext:nil withProperties:nil];
    secondChild.friendIDs = @[ @(12345) ];

    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKRelationshipConnectionOperation *operation = [[RKRelationshipConnectionOperation alloc] initWithManagedObject:secondChild connections:@[ connection ] managedObjectCache:managedObjectCache];
    [operation start];

    NSSet *expectedFriends = [NSSet setWithObjects:human, child, nil];
    expect(secondChild.friends).to.equal(expectedFriends);
}

- (void)testNotConnectingToSubentities
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSEntityDescription *childEntity = [NSEntityDescription entityForName:@"Child" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    NSRelationshipDescription *relationship = [childEntity relationshipsByName][@"friends"];
    RKConnectionDescription *connection = [[RKConnectionDescription alloc] initWithRelationship:relationship attributes:@{ @"friendIDs": @"railsID" }];
    connection.includesSubentities = NO;

    RKHuman *human = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:nil withProperties:nil];
    human.railsID = @(12345);
    RKChild *child = [RKTestFactory insertManagedObjectForEntityForName:@"Child" inManagedObjectContext:nil withProperties:nil];
    child.railsID = @(12345);

    RKChild *secondChild = [RKTestFactory insertManagedObjectForEntityForName:@"Child" inManagedObjectContext:nil withProperties:nil];
    secondChild.friendIDs = @[ @(12345) ];

    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKRelationshipConnectionOperation *operation = [[RKRelationshipConnectionOperation alloc] initWithManagedObject:secondChild connections:@[ connection ] managedObjectCache:managedObjectCache];
    [operation start];

    NSSet *expectedFriends = [NSSet setWithObjects:human, nil];
    expect(secondChild.friends).to.equal(expectedFriends);
}

- (void)testConnectionWithSourcePredicate
{
    RKHuman *human = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:nil withProperties:nil];
    human.sex = @"female";
    RKCat *asia = [RKTestFactory insertManagedObjectForEntityForName:@"Cat" inManagedObjectContext:nil withProperties:nil];
    asia.sex = @"female";
    RKCat *lola = [RKTestFactory insertManagedObjectForEntityForName:@"Cat" inManagedObjectContext:nil withProperties:nil];
    lola.sex = @"female";
    RKCat *roy = [RKTestFactory insertManagedObjectForEntityForName:@"Cat" inManagedObjectContext:nil withProperties:nil];
    roy.sex = @"male";
    
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:[RKTestFactory managedObjectStore]];
    [mapping addConnectionForRelationship:@"cats" connectedBy:@"sex"];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKConnectionDescription *connection = [mapping connectionForRelationship:@"cats"];
    connection.sourcePredicate = [NSPredicate predicateWithFormat:@"sex == %@", @"male"];
    
    RKRelationshipConnectionOperation *operation = [[RKRelationshipConnectionOperation alloc] initWithManagedObject:human connections:@[ connection ] managedObjectCache:managedObjectCache];
    [operation start];
    assertThat(human.cats, hasCountOf(0));
}

- (void)testConnectionWithDestinationPredicate
{
    RKHuman *human = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:nil withProperties:nil];
    human.sex = @"female";
    
    RKCat *asia = [RKTestFactory insertManagedObjectForEntityForName:@"Cat" inManagedObjectContext:nil withProperties:@{@"birthYear": @2011}];
    asia.sex = @"female";
    RKCat *lola = [RKTestFactory insertManagedObjectForEntityForName:@"Cat" inManagedObjectContext:nil withProperties:@{@"birthYear": @2012}];
    lola.sex = @"female";
    
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:[RKTestFactory managedObjectStore]];
    [mapping addConnectionForRelationship:@"cats" connectedBy:@"sex"];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKConnectionDescription *connection = [mapping connectionForRelationship:@"cats"];
    connection.destinationPredicate = [NSPredicate predicateWithFormat:@"birthYear = 2011"];
       
    RKRelationshipConnectionOperation *operation = [[RKRelationshipConnectionOperation alloc] initWithManagedObject:human connections:@[ connection ] managedObjectCache:managedObjectCache];
    [operation start];
    assertThat(human.cats, hasCountOf(1));
    assertThat(human.cats, hasItems(asia, nil));
}

- (void)testConnectionOfOptionalRelationshipIsSkippedWhenAllConnectionAttributesEvaluateToNil
{
    RKHuman *human = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:nil withProperties:nil];
    RKCat __unused *asia = [RKTestFactory insertManagedObjectForEntityForName:@"Cat" inManagedObjectContext:nil withProperties:@{@"birthYear": @2011}];
    RKCat __unused *lola = [RKTestFactory insertManagedObjectForEntityForName:@"Cat" inManagedObjectContext:nil withProperties:@{@"birthYear": @2012}];
    
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:[RKTestFactory managedObjectStore]];
    [mapping addConnectionForRelationship:@"cats" connectedBy:@"sex"];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKConnectionDescription *connection = [mapping connectionForRelationship:@"cats"];
    
    RKRelationshipConnectionOperation *operation = [[RKRelationshipConnectionOperation alloc] initWithManagedObject:human connections:@[ connection ] managedObjectCache:managedObjectCache];
    [operation start];
    assertThat(human.cats, hasCountOf(0));
}

- (void)testConnectionOfOptionalRelationshipIsEvaluatedWhenAtLeastOneAttributeEvaluatesToNonNil
{
    RKHuman *human = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:nil withProperties:nil];
    human.sex = @"female";
    
    RKCat *asia = [RKTestFactory insertManagedObjectForEntityForName:@"Cat" inManagedObjectContext:nil withProperties:@{@"birthYear": @2011}];
    asia.sex = @"female";
    asia.name = @"Asia";
    RKCat *lola = [RKTestFactory insertManagedObjectForEntityForName:@"Cat" inManagedObjectContext:nil withProperties:@{@"birthYear": @2012}];
    lola.sex = @"female";
    lola.name = nil;
    
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:[RKTestFactory managedObjectStore]];
    [mapping addConnectionForRelationship:@"cats" connectedBy:@[ @"sex", @"name" ]];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKConnectionDescription *connection = [mapping connectionForRelationship:@"cats"];
    
    RKRelationshipConnectionOperation *operation = [[RKRelationshipConnectionOperation alloc] initWithManagedObject:human connections:@[ connection ] managedObjectCache:managedObjectCache];
    [operation start];
    assertThat(human.cats, hasCountOf(1));
    assertThat(human.cats, hasItems(lola, nil));
}

- (void)testConnectionOfOptionalRelationshipIsSkippedWhenAllAttributesEvaluateToNil
{
    RKHuman *human = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:nil withProperties:nil];
    
    RKCat *asia = [RKTestFactory insertManagedObjectForEntityForName:@"Cat" inManagedObjectContext:nil withProperties:@{@"birthYear": @2011}];
    asia.sex = @"female";
    asia.name = @"Asia";
    RKCat *lola = [RKTestFactory insertManagedObjectForEntityForName:@"Cat" inManagedObjectContext:nil withProperties:@{@"birthYear": @2012}];
    lola.sex = @"female";
    lola.name = nil;
    
    human.cats = [NSSet setWithObject:asia];
    
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:[RKTestFactory managedObjectStore]];
    [mapping addConnectionForRelationship:@"cats" connectedBy:@[ @"sex", @"name" ]];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKConnectionDescription *connection = [mapping connectionForRelationship:@"cats"];
    
    RKRelationshipConnectionOperation *operation = [[RKRelationshipConnectionOperation alloc] initWithManagedObject:human connections:@[ connection ] managedObjectCache:managedObjectCache];
    [operation start];
    
    // Operation should be skipped due to lack of connectable attributes
    assertThat(human.cats, hasCountOf(1));
    assertThat(human.cats, hasItems(asia, nil));
}

@end
