//
//  RKManagedObjectFactorySpec.m
//  RestKit
//
//  Created by Blake Watters on 5/11/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKManagedObjectStore.h"
#import "RKManagedObjectFactory.h"
#import "RKObjectMapping.h"
#import "RKMappableObject.h"
#import "NSManagedObject+ActiveRecord.h"
#import "RKHuman.h"
#import "RKManagedObjectMapping.h"
    
@interface RKManagedObjectFactorySpec : RKSpec {
}

@end

@implementation RKManagedObjectFactorySpec

- (void)itShouldCreateNewInstancesOfUnmanagedObjects {
    RKManagedObjectStore* store = RKSpecNewManagedObjectStore();
    RKManagedObjectFactory* factory = [RKManagedObjectFactory objectFactoryWithObjectStore:store];
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKMappableObject class]];
    id object = [factory objectWithMapping:mapping andData:[NSDictionary dictionary]];
    assertThat(object, isNot(nilValue()));
    assertThat([object class], is(equalTo([RKMappableObject class])));
}

- (void)itShouldCreateNewInstancesOfManagedObjectsWhenTheMappingIsAnRKObjectMapping {
    RKManagedObjectStore* store = RKSpecNewManagedObjectStore();
    RKManagedObjectFactory* factory = [RKManagedObjectFactory objectFactoryWithObjectStore:store];
    RKObjectMapping* mapping = [RKObjectMapping mappingForClass:[RKMappableObject class]];
    id object = [factory objectWithMapping:mapping andData:[NSDictionary dictionary]];
    assertThat(object, isNot(nilValue()));
    assertThat([object class], is(equalTo([RKMappableObject class])));
}

- (void)itShouldFindExistingManagedObjectsByPrimaryKey {
    RKManagedObjectStore* store = RKSpecNewManagedObjectStore();
    RKManagedObjectFactory* factory = [RKManagedObjectFactory objectFactoryWithObjectStore:store];
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[RKHuman class]];
    mapping.primaryKeyAttribute = @"railsID";
    [mapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"railsID"]];
    
    RKHuman* human = [RKHuman object];
    human.railsID = [NSNumber numberWithInt:123];
    [store save];
    assertThatBool([RKHuman hasAtLeastOneEntity], is(equalToBool(YES)));
    
    NSDictionary* data = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:123] forKey:@"id"];
    id object = [factory objectWithMapping:mapping andData:data];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(equalTo(human)));
}

- (void)itShouldFindExistingManagedObjectsByPrimaryKeyPath {
    RKManagedObjectStore* store = RKSpecNewManagedObjectStore();
    [RKHuman truncateAll];
    RKManagedObjectFactory* factory = [RKManagedObjectFactory objectFactoryWithObjectStore:store];
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
    id object = [factory objectWithMapping:mapping andData:nestedDictionary];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(equalTo(human)));
}

- (void)itShouldCreateNewManagedObjectInstancesWhenThereIsNoPrimaryKeyInTheData {
    RKManagedObjectStore* store = RKSpecNewManagedObjectStore();
    RKManagedObjectFactory* factory = [RKManagedObjectFactory objectFactoryWithObjectStore:store];
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[RKHuman class]];
    mapping.primaryKeyAttribute = @"railsID";
    
    NSDictionary* data = [NSDictionary dictionary];
    id object = [factory objectWithMapping:mapping andData:data];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(instanceOf([RKHuman class])));
}

- (void)itShouldCreateNewManagedObjectInstancesWhenThereIsNoPrimaryKeyAttribute {
    RKManagedObjectStore* store = RKSpecNewManagedObjectStore();
    RKManagedObjectFactory* factory = [RKManagedObjectFactory objectFactoryWithObjectStore:store];
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[RKHuman class]];
    
    NSDictionary* data = [NSDictionary dictionary];
    id object = [factory objectWithMapping:mapping andData:data];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(instanceOf([RKHuman class])));
}

- (void)itShouldCreateANewManagedObjectWhenThePrimaryKeyValueIsNSNull {
    RKManagedObjectStore* store = RKSpecNewManagedObjectStore();
    RKManagedObjectFactory* factory = [RKManagedObjectFactory objectFactoryWithObjectStore:store];
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[RKHuman class]];
    mapping.primaryKeyAttribute = @"railsID";
    [mapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"railsID"]];
    
    NSDictionary* data = [NSDictionary dictionaryWithObject:[NSNull null] forKey:@"id"];
    id object = [factory objectWithMapping:mapping andData:data];
    assertThat(object, isNot(nilValue()));
    assertThat(object, is(instanceOf([RKHuman class])));
}

@end
