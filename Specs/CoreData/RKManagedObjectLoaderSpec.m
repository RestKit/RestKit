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

- (void)itShouldLoadAnObjectWithAToOneRelationship {
    RKManagedObjectStore* store = RKSpecNewManagedObjectStore();
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    objectManager.objectStore = store;
    
    RKObjectMapping* humanMapping = [RKManagedObjectMapping mappingForClass:[RKHuman class] inManagedObjectStore:store];
    [humanMapping mapAttributes:@"name", nil];
    RKObjectMapping* catMapping = [RKManagedObjectMapping mappingForClass:[RKCat class] inManagedObjectStore:store];
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

- (void)itShouldDeleteObjectFromLocalStoreOnDELETE {    
    RKManagedObjectStore* store = RKSpecNewManagedObjectStore();
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    objectManager.objectStore = store;
    RKHuman* human = [RKHuman object];
    human.name = @"Blake Watters";
    human.railsID = [NSNumber numberWithInt:1];
    [objectManager.objectStore save];
    
    assertThat(objectManager.objectStore.managedObjectContext, is(equalTo(store.managedObjectContext)));
    
    RKManagedObjectMapping* mapping = [RKManagedObjectMapping mappingForClass:[RKHuman class] inManagedObjectStore:store];
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
    RKManagedObjectLoader* objectLoader = [RKManagedObjectLoader loaderWithResourcePath:@"/humans/1" objectManager:objectManager delegate:responseLoader];
    objectLoader.method = RKRequestMethodDELETE;
    objectLoader.objectMapping = mapping;
    objectLoader.targetObject = human;
    [objectLoader send];
    [responseLoader waitForResponse];
    assertThatBool([human isDeleted], equalToBool(YES));
}

- (void)itShouldDeleteObjectsMissingFromPayloadReturnedByObjectCache {
    RKManagedObjectStore* store = RKSpecNewManagedObjectStore();
    RKManagedObjectMapping* humanMapping = [RKManagedObjectMapping mappingForEntityWithName:@"RKHuman"  
                                                                       inManagedObjectStore:store];
    [humanMapping mapKeyPath:@"id" toAttribute:@"railsID"];
    [humanMapping mapAttributes:@"name", nil];
    humanMapping.primaryKeyAttribute = @"railsID";
    
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
    objectManager.objectStore = store;
    
    id mockObjectCache = [OCMockObject mockForProtocol:@protocol(RKManagedObjectCache)];
    [[[mockObjectCache expect] andReturn:[RKHuman fetchRequest]] fetchRequestForResourcePath:OCMOCK_ANY];
    objectManager.objectStore.managedObjectCache = mockObjectCache;
    
    RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
    responseLoader.timeout = 25;
    RKManagedObjectLoader* objectLoader = [RKManagedObjectLoader loaderWithResourcePath:@"/JSON/humans/all.json" objectManager:objectManager delegate:responseLoader]; 
    [objectLoader send];
    [responseLoader waitForResponse];
    
    assertThatInt([RKHuman count:nil], is(equalToInt(2)));
    assertThatBool([deleteMe isDeleted], is(equalToBool(YES)));
}

- (void)itShouldSkipObjectMappingOnRequestCacheHitWhenObjectCachePresent {
    RKLogConfigureByName("RestKit/Network", RKLogLevelTrace);
    RKLogConfigureByName("RestKit/Network/Cache", RKLogLevelTrace);
    RKSpecClearCacheDirectory();
    
    RKObjectManager* objectManager = RKSpecNewObjectManager();
    RKManagedObjectStore* objectStore = RKSpecNewManagedObjectStore();
    objectManager.objectStore = objectStore;
    RKManagedObjectMapping* humanMapping = [RKManagedObjectMapping mappingForEntityWithName:@"RKHuman" inManagedObjectStore:objectStore];
    [humanMapping mapKeyPath:@"id" toAttribute:@"railsID"];
    [humanMapping mapAttributes:@"name", nil];
    humanMapping.primaryKeyAttribute = @"railsID";

    [RKHuman truncateAll];
    assertThatInt([RKHuman count:nil], is(equalToInt(0)));
    RKHuman* blake = [RKHuman createEntity];
    blake.railsID = [NSNumber numberWithInt:123];
    RKHuman* other = [RKHuman createEntity];
    other.railsID = [NSNumber numberWithInt:456];
    [objectStore save];
    assertThatInt([RKHuman count:nil], is(equalToInt(2)));
    
    [objectManager.mappingProvider setMapping:humanMapping forKeyPath:@"human"];

    id mockObjectCache = [OCMockObject mockForProtocol:@protocol(RKManagedObjectCache)];
    [[[mockObjectCache stub] andReturn:[RKHuman fetchRequest]] fetchRequestForResourcePath:@"/coredata/etag"];
    objectManager.objectStore.managedObjectCache = mockObjectCache;

    {
        RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
        RKManagedObjectLoader* objectLoader = [RKManagedObjectLoader loaderWithResourcePath:@"/coredata/etag"
                                                                              objectManager:objectManager
                                                                                   delegate:responseLoader];
        id mockLoader = [OCMockObject partialMockForObject:objectLoader];
        [[[mockLoader expect] andForwardToRealObject] performMapping:[OCMArg setTo:OCMOCK_ANY]];

        [mockLoader send];
        [responseLoader waitForResponse];

        [mockLoader verify];
        assertThatInt([RKHuman count:nil], is(equalToInt(2)));
        [expectThat([responseLoader success]) should:be(YES)];
        [expectThat([responseLoader.response wasLoadedFromCache]) should:be(NO)];
        assertThatInt([responseLoader.objects count], is(equalToInt(2)));
    }
    {
        RKSpecResponseLoader* responseLoader = [RKSpecResponseLoader responseLoader];
        RKManagedObjectLoader* objectLoader = [RKManagedObjectLoader loaderWithResourcePath:@"/coredata/etag"
                                                                              objectManager:objectManager
                                                                                   delegate:responseLoader];
        id mockLoader = [OCMockObject partialMockForObject:objectLoader];
        [[mockLoader reject] performMapping:[OCMArg setTo:OCMOCK_ANY]];

        [mockLoader send];
        [responseLoader waitForResponse];

        [mockLoader verify];
        assertThatInt([RKHuman count:nil], is(equalToInt(2)));
        [expectThat([responseLoader success]) should:be(YES)];
        [expectThat([responseLoader.response wasLoadedFromCache]) should:be(YES)];
        assertThatInt([responseLoader.objects count], is(equalToInt(2)));
    }
}

@end
