//
//  RKManagedObjectMappingSpec.m
//  RestKit
//
//  Created by Blake Watters on 5/31/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKManagedObjectMapping.h"
#import "RKHuman.h"
#import "RKMappableObject.h"

@interface RKManagedObjectMappingSpec : RKSpec {
    
}

@end


@implementation RKManagedObjectMappingSpec

- (void)itShouldReturnTheDefaultValueForACoreDataAttribute {
    // Load Core Data
    RKSpecNewManagedObjectStore();
    
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForEntityWithName:@"RKCat"];
    id value = [mapping defaultValueForMissingAttribute:@"name"];
    assertThat(value, is(equalTo(@"Kitty Cat!")));
}

- (void)itShouldCreateNewInstancesOfUnmanagedObjects {
    RKSpecNewManagedObjectStore();
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKMappableObject class]];
    id object = [mapping mappableObjectForData:[NSDictionary dictionary]];
    assertThat(object, isNot(nilValue()));
    assertThat([object class], is(equalTo([RKMappableObject class])));
}

- (void)itShouldCreateNewInstancesOfManagedObjectsWhenTheMappingIsAnRKObjectMapping {
    RKSpecNewManagedObjectStore();
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKMappableObject class]];
    id object = [mapping mappableObjectForData:[NSDictionary dictionary]];
    assertThat(object, isNot(nilValue()));
    assertThat([object class], is(equalTo([RKMappableObject class])));
}

- (void)itShouldFindExistingManagedObjectsByPrimaryKey {
    RKManagedObjectStore* store = RKSpecNewManagedObjectStore();
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[RKHuman class]];
    mapping.primaryKeyAttribute = @"railsID";
    [mapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"railsID"]];
    
    RKHuman* human = [RKHuman object];
    human.railsID = [NSNumber numberWithInt:123];
    [store save];
    assertThatBool([RKHuman hasAtLeastOneEntity], is(equalToBool(YES)));
    
    NSDictionary* data = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:123] forKey:@"id"];
    id object = [mapping mappableObjectForData:data];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(equalTo(human)));
}

- (void)itShouldFindExistingManagedObjectsByPrimaryKeyPath {
    RKManagedObjectStore* store = RKSpecNewManagedObjectStore();
    [RKHuman truncateAll];
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[RKHuman class]];
    mapping.primaryKeyAttribute = @"railsID";
    [mapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"monkey.id" toKeyPath:@"railsID"]];
    
    [RKHuman truncateAll];
    RKHuman* human = [RKHuman object];
    human.railsID = [NSNumber numberWithInt:123];
    [store save];
    assertThatBool([RKHuman hasAtLeastOneEntity], is(equalToBool(YES)));
    
    NSDictionary* data = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:123] forKey:@"id"];
    NSDictionary* nestedDictionary = [NSDictionary dictionaryWithObject:data forKey:@"monkey"];
    id object = [mapping mappableObjectForData:nestedDictionary];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(equalTo(human)));
}

- (void)itShouldCreateNewManagedObjectInstancesWhenThereIsNoPrimaryKeyInTheData {
    RKSpecNewManagedObjectStore();
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[RKHuman class]];
    mapping.primaryKeyAttribute = @"railsID";
    
    NSDictionary* data = [NSDictionary dictionary];
    id object = [mapping mappableObjectForData:data];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(instanceOf([RKHuman class])));
}

- (void)itShouldCreateNewManagedObjectInstancesWhenThereIsNoPrimaryKeyAttribute {
    RKSpecNewManagedObjectStore();
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[RKHuman class]];
    
    NSDictionary* data = [NSDictionary dictionary];
    id object = [mapping mappableObjectForData:data];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(instanceOf([RKHuman class])));
}

- (void)itShouldCreateANewManagedObjectWhenThePrimaryKeyValueIsNSNull {
    RKSpecNewManagedObjectStore();
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[RKHuman class]];
    mapping.primaryKeyAttribute = @"railsID";
    [mapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"railsID"]];
    
    NSDictionary* data = [NSDictionary dictionaryWithObject:[NSNull null] forKey:@"id"];
    id object = [mapping mappableObjectForData:data];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(instanceOf([RKHuman class])));
}

@end
