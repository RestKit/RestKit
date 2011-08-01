//
//  RKManagedObjectMappingOperationSpec.m
//  RestKit
//
//  Created by Blake Watters on 5/31/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKManagedObjectMapping.h"
#import "RKManagedObjectMappingOperation.h"
#import "RKCat.h"
#import "RKHuman.h"

@interface RKManagedObjectMappingOperationSpec : RKSpec {
    
}

@end

@implementation RKManagedObjectMappingOperationSpec

- (void)itShouldOverloadInitializationOfRKObjectMappingOperationToReturnInstancesOfRKManagedObjectMappingOperationWhenAppropriate {
    RKSpecNewManagedObjectStore();    
    RKManagedObjectMapping* managedMapping = [RKManagedObjectMapping mappingForClass:[RKHuman class]];
    NSDictionary* sourceObject = [NSDictionary dictionary];
    RKHuman* human = [RKHuman createEntity];
    RKObjectMappingOperation* operation = [RKObjectMappingOperation mappingOperationFromObject:sourceObject toObject:human withMapping:managedMapping];
    assertThat(operation, is(instanceOf([RKManagedObjectMappingOperation class])));
}

- (void)itShouldOverloadInitializationOfRKObjectMappingOperationButReturnUnmanagedMappingOperationWhenAppropriate {
    RKObjectMapping* vanillaMapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    NSDictionary* sourceObject = [NSDictionary dictionary];
    NSMutableDictionary* destinationObject = [NSMutableDictionary dictionary];
    RKObjectMappingOperation* operation = [RKObjectMappingOperation mappingOperationFromObject:sourceObject toObject:destinationObject withMapping:vanillaMapping];
    assertThat(operation, is(instanceOf([RKObjectMappingOperation class])));
}

- (void)itShouldConnectRelationshipsByPrimaryKey {
    RKManagedObjectStore* objectStore = RKSpecNewManagedObjectStore();
    
    RKManagedObjectMapping* catMapping = [RKManagedObjectMapping mappingForClass:[RKCat class]];
    catMapping.primaryKeyAttribute = @"railsID";
    [catMapping mapAttributes:@"name", nil];
    
    RKManagedObjectMapping* humanMapping = [RKManagedObjectMapping mappingForClass:[RKHuman class]];
    humanMapping.primaryKeyAttribute = @"railsID";
    [humanMapping mapAttributes:@"name", @"favoriteCatID", nil];
    [humanMapping hasOne:@"favoriteCat" withMapping:catMapping];
    [humanMapping connectRelationship:@"favoriteCat" withObjectForPrimaryKeyAttribute:@"favoriteCatID"];
    
    // Create a cat to connect
    RKCat* cat = [RKCat object];
    cat.name = @"Asia";
    cat.railsID = [NSNumber numberWithInt:31337];
    [objectStore save];
    
    NSDictionary* mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Blake", @"favoriteCatID", [NSNumber numberWithInt:31337], nil];
    RKHuman* human = [RKHuman object];
    RKManagedObjectMappingOperation* operation = [[RKManagedObjectMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    NSError* error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(human.favoriteCat, isNot(nilValue()));
    assertThat(human.favoriteCat.name, is(equalTo(@"Asia")));
}

@end
