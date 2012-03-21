//
//  RKFetchRequestMappingTest.m
//  RestKit
//
//  Created by Blake Watters on 3/20/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
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
    RKManagedObjectStore *objectStore = [RKTestFactory managedObjectStore];
    RKFetchRequestMappingCache *cache = [RKFetchRequestMappingCache new];
    NSEntityDescription *entity = [RKCat entityDescription];
    RKManagedObjectMapping *mapping = [RKManagedObjectMapping mappingForClass:[RKCat class] inManagedObjectStore:objectStore];
    mapping.primaryKeyAttribute = @"railsID";
    
    RKCat *reginald = [RKCat createInContext:objectStore.primaryManagedObjectContext];
    reginald.name = @"Reginald";
    reginald.railsID = [NSNumber numberWithInt:123456];
    [objectStore.primaryManagedObjectContext save:nil];
    
    NSManagedObject *cachedObject = [cache findInstanceOfEntity:entity 
                                                    withMapping:mapping 
                                             andPrimaryKeyValue:[NSNumber numberWithInt:123456]                                                                
                                         inManagedObjectContext:objectStore.primaryManagedObjectContext];
    assertThat(cachedObject, is(equalTo(reginald)));
}

- (void)testFetchRequestMappingCacheReturnsObjectsWithStringPrimaryKey
{
    // RKEvent entity. String primary key  
    RKManagedObjectStore *objectStore = [RKTestFactory managedObjectStore];
    RKFetchRequestMappingCache *cache = [RKFetchRequestMappingCache new];
    NSEntityDescription *entity = [RKEvent entityDescription];
    RKManagedObjectMapping *mapping = [RKManagedObjectMapping mappingForClass:[RKEvent class] inManagedObjectStore:objectStore];
    mapping.primaryKeyAttribute = @"eventID";
    
    RKEvent *birthday = [RKEvent createInContext:objectStore.primaryManagedObjectContext];
    birthday.eventID = @"e-1234-a8-b12";
    [objectStore.primaryManagedObjectContext save:nil];
    
    NSManagedObject *cachedObject = [cache findInstanceOfEntity:entity 
                                                    withMapping:mapping 
                                             andPrimaryKeyValue:@"e-1234-a8-b12"                                                                
                                         inManagedObjectContext:objectStore.primaryManagedObjectContext];
    assertThat(cachedObject, is(equalTo(birthday)));
}

@end
