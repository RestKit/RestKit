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
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RKCat" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"RKCat" inManagedObjectStore:managedObjectStore];
    mapping.primaryKeyAttribute = @"railsID";

    RKCat *reginald = [NSEntityDescription insertNewObjectForEntityForName:@"RKCat" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    reginald.name = @"Reginald";
    reginald.railsID = [NSNumber numberWithInt:123456];
    [managedObjectStore.persistentStoreManagedObjectContext save:nil];

    NSManagedObject *cachedObject = [cache findInstanceOfEntity:entity
                                        withPrimaryKeyAttribute:mapping.primaryKeyAttribute
                                                          value:[NSNumber numberWithInt:123456]
                                         inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    expect(cachedObject).to.equal(reginald);
}

- (void)testFetchRequestMappingCacheReturnsObjectsWithStringPrimaryKey
{
    // RKEvent entity. String primary key
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKFetchRequestManagedObjectCache *cache = [RKFetchRequestManagedObjectCache new];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RKEvent" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"RKEvent" inManagedObjectStore:managedObjectStore];
    mapping.primaryKeyAttribute = @"eventID";

    RKEvent *birthday = [NSEntityDescription insertNewObjectForEntityForName:@"RKEvent" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    birthday.eventID = @"e-1234-a8-b12";
    [managedObjectStore.persistentStoreManagedObjectContext save:nil];

    NSManagedObject *cachedObject = [cache findInstanceOfEntity:entity
                                        withPrimaryKeyAttribute:mapping.primaryKeyAttribute
                                                          value:@"e-1234-a8-b12"
                                         inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    expect(cachedObject).to.equal(birthday);
}

@end
