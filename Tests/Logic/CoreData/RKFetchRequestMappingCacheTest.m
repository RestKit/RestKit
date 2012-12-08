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

@interface RKFetchRequestMappingCacheTest : RKTestCase

@end

@implementation RKFetchRequestMappingCacheTest

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
    reginald.railsID = [NSNumber numberWithInt:123456];
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

@end
