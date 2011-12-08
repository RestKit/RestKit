//
//  RKManagedObjectLoaderSpec.m
//  RestKit
//
//  Created by Blake Watters on 4/28/11.
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
#import "RKManagedObjectLoader.h"
#import "RKManagedObjectMapping.h"
#import "RKHuman.h"
#import "RKCat.h"
#import "NSManagedObject+ActiveRecord.h"

@interface RKManagedObjectLoaderSpec : RKSpec {
    
}

@end

@implementation RKManagedObjectLoaderSpec

- (void)testShouldDeleteObjectFromLocalStoreOnDELETE {    
    RKManagedObjectStore* store = RKSpecNewManagedObjectStore();
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    RKSpecStubNetworkAvailability(YES);
    objectManager.objectStore = store;
    RKHuman* human = [RKHuman object];
    human.name = @"Blake Watters";
    human.railsID = [NSNumber numberWithInt:1];
    [objectManager.objectStore save];
    
    RKObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[RKHuman class]];
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
    RKManagedObjectLoader* objectLoader = [RKManagedObjectLoader loaderWithResourcePath:@"/humans/1" objectManager:objectManager delegate:responseLoader];
    objectLoader.method = RKRequestMethodDELETE;
    objectLoader.objectMapping = mapping;
    objectLoader.targetObject = human;
    [objectLoader send];
    [responseLoader waitForResponse];
    assertThatBool([human isDeleted], equalToBool(YES));
}

- (void)testShouldLoadAnObjectWithAToOneRelationship {
    RKManagedObjectStore* store = RKSpecNewManagedObjectStore();
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    RKSpecStubNetworkAvailability(YES);
    objectManager.objectStore = store;
    
    RKObjectMapping* humanMapping = [RKManagedObjectMapping mappingForClass:[RKHuman class]];
    [humanMapping mapAttributes:@"name", nil];
    RKObjectMapping* catMapping = [RKManagedObjectMapping mappingForClass:[RKCat class]];
    [catMapping mapAttributes:@"name", nil];
    [humanMapping mapKeyPath:@"favorite_cat" toRelationship:@"favoriteCat" withMapping:catMapping];
    [objectManager.mappingProvider setMapping:humanMapping forKeyPath:@"human"];
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
    RKManagedObjectLoader* objectLoader = [RKManagedObjectLoader loaderWithResourcePath:@"/JSON/humans/with_to_one_relationship.json" objectManager:objectManager delegate:responseLoader];
    [objectLoader send];
    [responseLoader waitForResponse];
    RKHuman* human = [responseLoader.objects lastObject];
    assertThat(human, isNot(nilValue()));
    assertThat(human.favoriteCat, isNot(nilValue()));
    assertThat(human.favoriteCat.name, is(equalTo(@"Asia")));
}

- (void)testShouldDeleteObjectsMissingFromPayloadReturnedByObjectCache {
    RKManagedObjectStore* store = RKSpecNewManagedObjectStore();
    RKManagedObjectMapping* humanMapping = [RKManagedObjectMapping mappingForEntityWithName:@"RKHuman"];
    [humanMapping mapKeyPath:@"id" toAttribute:@"railsID"];
    [humanMapping mapAttributes:@"name", nil];
    humanMapping.primaryKeyAttribute = @"id";
    
    // Create 3 objects, we will expect 2 after the load
    [RKHuman truncateAll];    
    assertThatInt([RKHuman count:nil], is(equalToInt(0)));
    RKHuman* blake = [RKHuman createEntity];
    blake.railsID = [NSNumber numberWithInt:123];
    RKHuman* other = [RKHuman createEntity];
    other.railsID = [NSNumber numberWithInt:456];
    RKHuman* deleteMe = [RKHuman createEntity];
    deleteMe.railsID = [NSNumber numberWithInt:9999];
    [store save];
    assertThatInt([RKHuman count:nil], is(equalToInt(3)));
        
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    [objectManager.mappingProvider setMapping:humanMapping forKeyPath:@"human"];
    RKSpecStubNetworkAvailability(YES);
    objectManager.objectStore = store;
    
    id mockObjectCache = [OCMockObject mockForProtocol:@protocol(RKManagedObjectCache)];
    NSArray* fetchRequests = [NSArray arrayWithObject:[RKHuman fetchRequest]];
    [[[mockObjectCache expect] andReturn:fetchRequests] fetchRequestsForResourcePath:OCMOCK_ANY];
    objectManager.objectStore.managedObjectCache = mockObjectCache;
    
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
    responseLoader.timeout = 25;
    RKManagedObjectLoader* objectLoader = [RKManagedObjectLoader loaderWithResourcePath:@"/JSON/humans/all.json" objectManager:objectManager delegate:responseLoader]; 
    [objectLoader send];
    [responseLoader waitForResponse];
    
    assertThatInt([RKHuman count:nil], is(equalToInt(2)));
    assertThatBool([deleteMe isDeleted], is(equalToBool(YES)));
}

@end
