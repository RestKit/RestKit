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
#import "RKChild.h"
#import "RKParent.h"

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

- (void)itShouldLoadNestedHasManyRelationship {  
    RKManagedObjectMapping* catMapping = [RKManagedObjectMapping mappingForClass:[RKCat class]];
    catMapping.primaryKeyAttribute = @"railsID";
    [catMapping mapAttributes:@"name", nil];
    
    RKManagedObjectMapping* humanMapping = [RKManagedObjectMapping mappingForClass:[RKHuman class]];
    humanMapping.primaryKeyAttribute = @"railsID";
    [humanMapping mapAttributes:@"name", @"favoriteCatID", nil];
    [humanMapping hasMany:@"cats" withMapping:catMapping];
    
    NSArray* catsData = [NSArray arrayWithObject:[NSDictionary dictionaryWithObject:@"Asia" forKey:@"name"]];
    NSDictionary* mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Blake", @"favoriteCatID", [NSNumber numberWithInt:31337], @"cats", catsData, nil];
    RKHuman* human = [RKHuman object];
    RKManagedObjectMappingOperation* operation = [[RKManagedObjectMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    NSError* error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
}

- (void)itShouldLoadNestedHasManyRelationshipWithoutABackingClass {
    RKManagedObjectStore* objectStore = RKSpecNewManagedObjectStore();
    RKManagedObjectMapping* cloudMapping = [RKManagedObjectMapping mappingForEntityWithName:@"RKCloud"];
    [cloudMapping mapAttributes:@"name", nil];
    
    RKManagedObjectMapping* stormMapping = [RKManagedObjectMapping mappingForEntityWithName:@"RKStorm"];
    [stormMapping mapAttributes:@"name", @"favoriteCatID", nil];
    [stormMapping hasMany:@"clouds" withMapping:cloudMapping];
    
    NSArray* cloudsData = [NSArray arrayWithObject:[NSDictionary dictionaryWithObject:@"Nimbus" forKey:@"name"]];
    NSDictionary* mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Hurricane", @"clouds", cloudsData, nil];
    NSEntityDescription* entity = [NSEntityDescription entityForName:@"RKStorm" inManagedObjectContext:objectStore.managedObjectContext];
    NSManagedObject* storm = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:objectStore.managedObjectContext];
    RKManagedObjectMappingOperation* operation = [[RKManagedObjectMappingOperation alloc] initWithSourceObject:mappableData destinationObject:storm mapping:stormMapping];
    NSError* error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
}

- (void)itShouldConnectManyToManyRelationships {
    RKSpecNewManagedObjectStore();
    RKManagedObjectMapping* childMapping = [RKManagedObjectMapping mappingForClass:[RKChild class]];
    childMapping.primaryKeyAttribute = @"railsID";
    [childMapping mapAttributes:@"name", nil];

    RKManagedObjectMapping* parentMapping = [RKManagedObjectMapping mappingForClass:[RKParent class]];
    parentMapping.primaryKeyAttribute = @"railsID";
    [parentMapping mapAttributes:@"name", @"age", nil];
    [parentMapping hasMany:@"children" withMapping:childMapping];

    NSArray* childMappableData = [NSArray arrayWithObjects:[NSDictionary dictionaryWithKeysAndObjects:@"name", @"Maya", nil],
                                  [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Brady", nil], nil];
    NSDictionary* parentMappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Win",
                                        @"age", [NSNumber numberWithInt:34],
                                        @"children", childMappableData, nil];
    RKParent* parent = [RKParent object];
    RKManagedObjectMappingOperation* operation = [[RKManagedObjectMappingOperation alloc] initWithSourceObject:parentMappableData destinationObject:parent mapping:parentMapping];
    NSError* error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(parent.children, isNot(nilValue()));
    assertThatInt([parent.children count], is(equalToInt(2)));
    assertThat([[parent.children anyObject] parents], isNot(nilValue()));
    assertThatBool([[[parent.children anyObject] parents] containsObject:parent], is(equalToBool(YES)));
    assertThatInt([[[parent.children anyObject] parents] count], is(equalToInt(1)));
}

@end
