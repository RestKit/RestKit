//
//  RKManagedObjectStoreSpec.m
//  RestKit
//
//  Created by Blake Watters on 7/2/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKHuman.h"

@interface RKManagedObjectStoreSpec : RKSpec

@end

@implementation RKManagedObjectStoreSpec

- (void)itShouldCoercePrimaryKeysToStringsForLookup {
    RKManagedObjectStore* objectStore = RKSpecNewManagedObjectStore();
    RKHuman* human = [RKHuman createEntity];
    human.railsID = [NSNumber numberWithInt:1234];
    [objectStore save];
    NSManagedObject* newReference = [objectStore findOrCreateInstanceOfEntity:[RKHuman entity] withPrimaryKeyAttribute:@"railsID" andValue:@"1234"];
    assertThat(newReference, is(equalTo(human)));
}

- (void)itShouldStoreNewInstancesOfCreatedObjectsByStringKey {
    RKManagedObjectStore* objectStore = RKSpecNewManagedObjectStore();
    NSManagedObject* firstInstance = [objectStore findOrCreateInstanceOfEntity:[RKHuman entity] withPrimaryKeyAttribute:@"railsID" andValue:[NSNumber numberWithInt:1234]];
    NSManagedObject* secondInstance = [objectStore findOrCreateInstanceOfEntity:[RKHuman entity] withPrimaryKeyAttribute:@"railsID" andValue:[NSNumber numberWithInt:1234]];
    assertThat(secondInstance, is(equalTo(firstInstance)));
}

@end
