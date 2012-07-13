//
//  RKManagedObjectMappingOperationDataSourceTest.m
//  RestKit
//
//  Created by Blake Watters on 7/12/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "NSEntityDescription+RKAdditions.h"
#import "RKEntityCache.h"
#import "RKEntityByAttributeCache.h"
#import "RKHuman.h"
#import "RKManagedObjectMappingOperationDataSource.h"
#import "RKMappableObject.h"

@interface RKManagedObjectMappingOperationDataSourceTest : RKTestCase

@end

@implementation RKManagedObjectMappingOperationDataSourceTest

- (void)testShouldCreateNewInstancesOfUnmanagedObjects
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                      cache:managedObjectStore.cacheStrategy];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKMappableObject class]];
    id object = [dataSource objectForMappableContent:[NSDictionary dictionary] mapping:mapping];
    assertThat(object, isNot(nilValue()));
    assertThat([object class], is(equalTo([RKMappableObject class])));
}

- (void)testShouldCreateNewManagedObjectInstancesWhenThereIsNoPrimaryKeyInTheData
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                      cache:managedObjectStore.cacheStrategy];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityWithName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    mapping.primaryKeyAttribute = @"railsID";
    
    NSDictionary *data = [NSDictionary dictionary];
    id object = [dataSource objectForMappableContent:data mapping:mapping];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(instanceOf([RKHuman class])));
}

- (void)testShouldCreateNewManagedObjectInstancesWhenThereIsNoPrimaryKeyAttribute
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                      cache:managedObjectStore.cacheStrategy];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityWithName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    
    NSDictionary *data = [NSDictionary dictionary];
    id object = [dataSource objectForMappableContent:data mapping:mapping];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(instanceOf([RKHuman class])));
}

- (void)testShouldCreateANewManagedObjectWhenThePrimaryKeyValueIsNSNull
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.primaryManagedObjectContext
                                                                                                                                      cache:managedObjectStore.cacheStrategy];
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityWithName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    mapping.primaryKeyAttribute = @"railsID";
    [mapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"railsID"]];
    
    NSDictionary *data = [NSDictionary dictionaryWithObject:[NSNull null] forKey:@"id"];
    id object = [dataSource objectForMappableContent:data mapping:mapping];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(instanceOf([RKHuman class])));
}

@end
