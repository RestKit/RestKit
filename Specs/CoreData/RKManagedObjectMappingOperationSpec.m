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

- (void)itShouldConnectRelationshipsByPrimaryKey {
    RKManagedObjectStore* objectStore = RKSpecNewManagedObjectStore();
    
    RKManagedObjectMapping* catMapping = [RKManagedObjectMapping mappingForClass:[RKCat class]];
    catMapping.primaryKeyAttribute = @"railsID";
    [catMapping mapAttributes:@"name", nil];
    
    RKManagedObjectMapping* humanMapping = [RKManagedObjectMapping mappingForClass:[RKHuman class]];
    humanMapping.primaryKeyAttribute = @"railsID";
    [humanMapping mapAttributes:@"name", @"favoriteCatID", nil];
    [humanMapping hasOne:@"favoriteCat" withObjectMapping:catMapping];
    [humanMapping connectRelationship:@"favoriteCat" withObjectForPrimaryKeyAttribute:@"favoriteCatID"];
    
    // Create a cat to connect
    RKCat* cat = [RKCat object];
    cat.name = @"Asia";
    cat.railsID = [NSNumber numberWithInt:31337];
    [objectStore save];
    
    NSDictionary* mappableData = [NSDictionary dictionaryWithKeysAndObjects:@"name", @"Blake", @"favoriteCatID", [NSNumber numberWithInt:31337], nil];
    RKHuman* human = [RKHuman object];
    RKManagedObjectMappingOperation* operation = [[RKManagedObjectMappingOperation alloc] initWithSourceObject:mappableData destinationObject:human objectMapping:humanMapping];
    NSError* error = nil;
    BOOL success = [operation performMapping:&error];
    assertThatBool(success, is(equalToBool(YES)));
    assertThat(human.favoriteCat, isNot(nilValue()));
    assertThat(human.favoriteCat.name, is(equalTo(@"Asia")));
}

@end
