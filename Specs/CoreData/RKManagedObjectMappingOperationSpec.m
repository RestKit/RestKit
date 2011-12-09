//
//  RKManagedObjectMappingOperationSpec.m
//  RestKit
//
//  Created by Blake Watters on 5/31/11.
//  Copyright 2011 Two Toasters
//  
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//  http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
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

- (void)testShouldOverloadInitializationOfRKObjectMappingOperationToReturnInstancesOfRKManagedObjectMappingOperationWhenAppropriate {
    RKSpecNewManagedObjectStore();    
    RKManagedObjectMapping* managedMapping = [RKManagedObjectMapping mappingForClass:[RKHuman class]];
    NSDictionary* sourceObject = [NSDictionary dictionary];
    RKHuman* human = [RKHuman createEntity];
    RKObjectMappingOperation* operation = [RKObjectMappingOperation mappingOperationFromObject:sourceObject toObject:human withMapping:managedMapping];
    assertThat(operation, is(instanceOf([RKManagedObjectMappingOperation class])));
}

- (void)testShouldOverloadInitializationOfRKObjectMappingOperationButReturnUnmanagedMappingOperationWhenAppropriate {
    RKObjectMapping* vanillaMapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    NSDictionary* sourceObject = [NSDictionary dictionary];
    NSMutableDictionary* destinationObject = [NSMutableDictionary dictionary];
    RKObjectMappingOperation* operation = [RKObjectMappingOperation mappingOperationFromObject:sourceObject toObject:destinationObject withMapping:vanillaMapping];
    assertThat(operation, is(instanceOf([RKObjectMappingOperation class])));
}

- (void)testShouldConnectRelationshipsByPrimaryKey {
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

- (void)testShouldConnectRelationshipsByPrimaryKeyWithDifferentSourceAndDestinationKeyPaths {
    RKManagedObjectStore* objectStore = RKSpecNewManagedObjectStore();
    
    RKManagedObjectMapping* catMapping = [RKManagedObjectMapping mappingForClass:[RKCat class]];
    catMapping.primaryKeyAttribute = @"railsID";
    [catMapping mapAttributes:@"name", nil];
    
    RKManagedObjectMapping* humanMapping = [RKManagedObjectMapping mappingForClass:[RKHuman class]];
    humanMapping.primaryKeyAttribute = @"railsID";
    [humanMapping mapAttributes:@"name", @"favoriteCatID", nil];
    [humanMapping mapKeyPath:@"favorite_cat" toRelationship:@"favoriteCat" withMapping:catMapping];
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

- (void)testShouldLoadNestedHasManyRelationship {  
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

- (void)testShouldMapNullToAHasManyRelationship {
    RKLogConfigureByName("RestKit/ObjectMapping", RKLogLevelTrace);
    RKSpecNewManagedObjectStore();
    RKManagedObjectMapping* catMapping = [RKManagedObjectMapping mappingForClass:[RKCat class]];
    [catMapping mapAttributes:@"name", nil];
    
    RKManagedObjectMapping* humanMapping = [RKManagedObjectMapping mappingForClass:[RKHuman class]];
    [humanMapping mapAttributes:@"name", @"favoriteCatID", nil];
    [humanMapping hasMany:@"cats" withMapping:catMapping];
    
    NSDictionary* mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Blake", @"cats", [NSNull null], nil];
    RKHuman* human = [RKHuman object];
    RKManagedObjectMappingOperation* operation = [[RKManagedObjectMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human mapping:humanMapping];
    NSError* error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(human.cats, is(empty()));
}

- (void)testShouldLoadNestedHasManyRelationshipWithoutABackingClass {
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

- (void)testShouldConnectManyToManyRelationships {
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
    assertThatUnsignedInteger([parent.children count], is(equalToInt(2)));
    assertThat([[parent.children anyObject] parents], isNot(nilValue()));
    assertThatBool([[[parent.children anyObject] parents] containsObject:parent], is(equalToBool(YES)));
    assertThatUnsignedInteger([[[parent.children anyObject] parents] count], is(equalToInt(1)));
}

- (void)testShouldConnectRelationshipsByPrimaryKeyRegardlessOfOrder {
    RKSpecNewManagedObjectStore();
    RKManagedObjectMapping* parentMapping = [RKManagedObjectMapping mappingForClass:[RKParent class]];
    [parentMapping mapAttributes:@"parentID", nil];
    parentMapping.primaryKeyAttribute = @"parentID";
    
    RKManagedObjectMapping* childMapping = [RKManagedObjectMapping mappingForClass:[RKChild class]];
    [childMapping mapAttributes:@"fatherID", nil];
    [childMapping mapRelationship:@"father" withMapping:parentMapping];
    [childMapping connectRelationship:@"father" withObjectForPrimaryKeyAttribute:@"fatherID"];    
        
    RKObjectMappingProvider *mappingProvider = [RKObjectMappingProvider new];
    // NOTE: This may be fragile. Reverse order seems to trigger them to be mapped parent first. NSDictionary
    // keys are not guaranteed to return in any particular order
    [mappingProvider setMapping:parentMapping forKeyPath:@"parents"];
    [mappingProvider setMapping:childMapping forKeyPath:@"children"];    
    
    NSDictionary *JSON = RKSpecParseFixture(@"ConnectingParents.json");
    RKLogConfigureByName("RestKit/ObjectMapping", RKLogLevelTrace);
    RKLogConfigureByName("RestKit/CoreData", RKLogLevelTrace);
    RKObjectMapper *mapper = [RKObjectMapper mapperWithObject:JSON mappingProvider:mappingProvider];
    RKObjectMappingResult *result = [mapper performMapping];
    NSArray *children = [[result asDictionary] valueForKey:@"children"];
    assertThat(children, hasCountOf(1));
    RKChild *child = [children lastObject];
    assertThat(child.father, is(notNilValue()));
}

@end
