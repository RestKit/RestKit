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
    RKHuman *human = [RKTestFactory insertManagedObjectForEntityForName:@"RKHuman" inManagedObjectContext:nil withProperties:nil];
    human.favoriteCatID = @250;
    RKCat *asia = [RKTestFactory insertManagedObjectForEntityForName:@"RKCat" inManagedObjectContext:nil withProperties:nil];
    asia.railsID = @250;
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:[RKTestFactory managedObjectStore]];
    RKConnectionMapping *connectionMapping = [mapping addConnectionMappingForRelationshipForName:@"favoriteCat" fromSourceKeyPath:@"favoriteCatID" toKeyPath:@"railsID" matcher:nil];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKRelationshipConnectionOperation *operation = [[RKRelationshipConnectionOperation alloc] initWithManagedObject:human connectionMapping:connectionMapping managedObjectCache:managedObjectCache];
    [operation start];
    assertThat(human.favoriteCat, is(equalTo(asia)));
}

- (void)testSuccessfulConnectionOfToManyRelationship
{
    RKHuman *human = [RKTestFactory insertManagedObjectForEntityForName:@"RKHuman" inManagedObjectContext:nil withProperties:nil];
    human.sex = @"female";
    RKCat *asia = [RKTestFactory insertManagedObjectForEntityForName:@"RKCat" inManagedObjectContext:nil withProperties:nil];
    asia.sex = @"female";
    RKCat *lola = [RKTestFactory insertManagedObjectForEntityForName:@"RKCat" inManagedObjectContext:nil withProperties:nil];
    lola.sex = @"female";
    RKCat *roy = [RKTestFactory insertManagedObjectForEntityForName:@"RKCat" inManagedObjectContext:nil withProperties:nil];
    roy.sex = @"male";

    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:[RKTestFactory managedObjectStore]];
    RKConnectionMapping *connectionMapping = [mapping addConnectionMappingForRelationshipForName:@"cats" fromSourceKeyPath:@"sex" toKeyPath:@"sex" matcher:nil];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKRelationshipConnectionOperation *operation = [[RKRelationshipConnectionOperation alloc] initWithManagedObject:human connectionMapping:connectionMapping managedObjectCache:managedObjectCache];
    [operation start];
    assertThat(human.cats, hasCountOf(2));
    assertThat(human.cats, hasItems(asia, lola, nil));
}

- (void)testConnectionWithoutResultsNullifiesExistingRelationship
{
    RKHuman *human = [RKTestFactory insertManagedObjectForEntityForName:@"RKHuman" inManagedObjectContext:nil withProperties:nil];
    human.sex = @"invalid";
    RKCat *asia = [RKTestFactory insertManagedObjectForEntityForName:@"RKCat" inManagedObjectContext:nil withProperties:nil];
    asia.sex = @"female";
    RKCat *lola = [RKTestFactory insertManagedObjectForEntityForName:@"RKCat" inManagedObjectContext:nil withProperties:nil];
    lola.sex = @"female";
    RKCat *roy = [RKTestFactory insertManagedObjectForEntityForName:@"RKCat" inManagedObjectContext:nil withProperties:nil];
    roy.sex = @"male";

    human.cats = [NSSet setWithObjects:asia, lola, roy, nil];
    assertThat(human.cats, isNot(empty()));

    // No cats with a sex of 'invalid'
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:[RKTestFactory managedObjectStore]];
    RKConnectionMapping *connectionMapping = [mapping addConnectionMappingForRelationshipForName:@"cats" fromSourceKeyPath:@"sex" toKeyPath:@"sex" matcher:nil];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    RKRelationshipConnectionOperation *operation = [[RKRelationshipConnectionOperation alloc] initWithManagedObject:human connectionMapping:connectionMapping managedObjectCache:managedObjectCache];
    [operation start];
    assertThat(human.cats, is(empty()));
}

@end
