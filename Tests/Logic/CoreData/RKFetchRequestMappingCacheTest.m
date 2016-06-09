//
//  RKFetchRequestMappingTest.m
//  RestKit
//
//  Created by Blake Watters on 3/20/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKCat.h"
#import "RKEvent.h"
#import "RKHouse.h"
#import "RKHuman.h"

@interface RKFetchRequestMappingCacheTest : RKTestCase

@end

@implementation RKFetchRequestMappingCacheTest

- (void)setUp
{
    [RKTestFactory setUp];
}

- (void)tearDown
{
    [RKTestFactory tearDown];
}

- (void)testFetchRequestMappingCacheReturnsObjectsWithNumericPrimaryKey
{
    // RKCat entity. Integer prinmary key.
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKFetchRequestManagedObjectCache *cache = [RKFetchRequestManagedObjectCache new];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Cat" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Cat" inManagedObjectStore:managedObjectStore];
    mapping.identificationAttributes = @[ @"railsID" ];

    RKCat *reginald = [NSEntityDescription insertNewObjectForEntityForName:@"Cat" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    reginald.name = @"Reginald";
    reginald.railsID = @123456;
    [managedObjectStore.persistentStoreManagedObjectContext save:nil];
    
    NSSet *managedObjects = [cache managedObjectsWithEntity:entity
                                              attributeValues:@{ @"railsID": @123456 }
                                       inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    NSSet *cats = [NSSet setWithObject:reginald];
    expect(managedObjects).to.equal(cats);
}

- (void)testFetchRequestMappingCacheReturnsObjectsWithStringPrimaryKey
{
    // RKEvent entity. String primary key
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKFetchRequestManagedObjectCache *cache = [RKFetchRequestManagedObjectCache new];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Event" inManagedObjectStore:managedObjectStore];
    mapping.identificationAttributes = @[ @"eventID" ];

    RKEvent *birthday = [NSEntityDescription insertNewObjectForEntityForName:@"Event" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    birthday.eventID = @"e-1234-a8-b12";
    [managedObjectStore.persistentStoreManagedObjectContext save:nil];
    
    NSSet *managedObjects = [cache managedObjectsWithEntity:entity
                                              attributeValues:@{ @"eventID": @"e-1234-a8-b12" }
                                       inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    NSSet *birthdays = [NSSet setWithObject:birthday];
    expect(managedObjects).to.equal(birthdays);
}

- (void)testFetchRequestMappingCacheReturnsObjectsWithStringUsingDotNotation
{
    // RKEvent entity. String primary key
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKFetchRequestManagedObjectCache *cache = [RKFetchRequestManagedObjectCache new];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKHouse *house = [NSEntityDescription insertNewObjectForEntityForName:@"House" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    house.city = @"myCity";
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    human.house = house;
    house.owner = human;
    
    [managedObjectStore.persistentStoreManagedObjectContext save:nil];
    
    NSSet *managedObjects = [cache managedObjectsWithEntity:entity
                                            attributeValues:@{ @"house.city": @"myCity" }
                                     inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    NSSet *humans = [NSSet setWithObject:human];
    expect(managedObjects).to.equal(humans);
}

- (void)testThatCacheCanHandleSwitchingBetweenSingularAndPluralAttributeValues
{
    // RKEvent entity. String primary key
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKFetchRequestManagedObjectCache *cache = [RKFetchRequestManagedObjectCache new];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Event" inManagedObjectStore:managedObjectStore];
    mapping.identificationAttributes = @[ @"eventID" ];
    
    RKEvent *event1 = [NSEntityDescription insertNewObjectForEntityForName:@"Event" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    event1.eventID = @"e-1234-a8-b12";
    
    RKEvent *event2 = [NSEntityDescription insertNewObjectForEntityForName:@"Event" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    event2.eventID = @"ff-1234-a8-b12";
    
    [managedObjectStore.persistentStoreManagedObjectContext save:nil];
    
    NSSet *managedObjects = [cache managedObjectsWithEntity:entity
                                            attributeValues:@{ @"eventID": @[ event1.eventID, event2.eventID ] }
                                     inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    NSSet *events = [NSSet setWithObjects:event1, event2, nil];
    expect(managedObjects).to.haveCountOf(2);
    expect(managedObjects).to.equal(events);
    
    managedObjects = [cache managedObjectsWithEntity:entity
                                     attributeValues:@{ @"eventID": event1.eventID }
                              inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    events = [NSSet setWithObject:event1];
    expect(managedObjects).to.haveCountOf(1);
    expect(managedObjects).to.equal(events);
    
    managedObjects = [cache managedObjectsWithEntity:entity
                                     attributeValues:@{ @"eventID": @[ event1.eventID ] }
                              inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    events = [NSSet setWithObject:event1];
    expect(managedObjects).to.haveCountOf(1);
    expect(managedObjects).to.equal(events);
}

@end
