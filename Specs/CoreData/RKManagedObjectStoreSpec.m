//
//  RKManagedObjectStoreSpec.m
//  RestKit
//
//  Created by Blake Watters on 7/2/11.
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
#import "RKHuman.h"

@interface RKManagedObjectStoreSpec : RKSpec

@end

@implementation RKManagedObjectStoreSpec

- (void)testShouldCoercePrimaryKeysToStringsForLookup {
    RKManagedObjectStore* objectStore = RKSpecNewManagedObjectStore();
    RKHuman* human = [RKHuman createEntity];
    human.railsID = [NSNumber numberWithInt:1234];
    [objectStore save];
    NSManagedObject* newReference = [objectStore findOrCreateInstanceOfEntity:[RKHuman entity] withPrimaryKeyAttribute:@"railsID" andValue:@"1234"];
    assertThat(newReference, is(equalTo(human)));
}

- (void)testShouldStoreNewInstancesOfCreatedObjectsByStringKey {
    RKManagedObjectStore* objectStore = RKSpecNewManagedObjectStore();
    NSManagedObject* firstInstance = [objectStore findOrCreateInstanceOfEntity:[RKHuman entity] withPrimaryKeyAttribute:@"railsID" andValue:[NSNumber numberWithInt:1234]];
    NSManagedObject* secondInstance = [objectStore findOrCreateInstanceOfEntity:[RKHuman entity] withPrimaryKeyAttribute:@"railsID" andValue:[NSNumber numberWithInt:1234]];
    assertThat(secondInstance, is(equalTo(firstInstance)));
}

@end
