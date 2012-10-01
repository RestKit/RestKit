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
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RKCat" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"RKCat" inManagedObjectStore:managedObjectStore];
    mapping.primaryKeyAttribute = @"railsID";

    RKCat *reginald = [NSEntityDescription insertNewObjectForEntityForName:@"RKCat" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    reginald.name = @"Reginald";
    reginald.railsID = [NSNumber numberWithInt:123456];
    [managedObjectStore.primaryManagedObjectContext save:nil];

    NSManagedObject *cachedObject = [cache findInstanceOfEntity:entity
                                        withPrimaryKeyAttribute:mapping.primaryKeyAttribute
                                                          value:[NSNumber numberWithInt:123456]
                                         inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    assertThat(cachedObject, is(equalTo(reginald)));
}

- (void)testFetchRequestMappingCacheReturnsObjectsWithStringPrimaryKey
{
    // RKEvent entity. String primary key
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKFetchRequestManagedObjectCache *cache = [RKFetchRequestManagedObjectCache new];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"RKEvent" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"RKEvent" inManagedObjectStore:managedObjectStore];
    mapping.primaryKeyAttribute = @"eventID";

    RKEvent *birthday = [NSEntityDescription insertNewObjectForEntityForName:@"RKEvent" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    birthday.eventID = @"e-1234-a8-b12";
    [managedObjectStore.primaryManagedObjectContext save:nil];

    NSManagedObject *cachedObject = [cache findInstanceOfEntity:entity
                                        withPrimaryKeyAttribute:mapping.primaryKeyAttribute
                                                          value:@"e-1234-a8-b12"
                                         inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    assertThat(cachedObject, is(equalTo(birthday)));
}

@end
