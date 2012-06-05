//
//  RKManagedObjectLoaderTest.m
//  RestKit
//
//  Created by Blake Watters on 4/28/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
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

#import "RKTestEnvironment.h"
#import "RKManagedObjectLoader.h"
#import "RKManagedObjectMapping.h"
#import "RKHuman.h"
#import "RKCat.h"
#import "NSManagedObject+ActiveRecord.h"
#import "RKObjectMappingProvider+CoreData.h"

@interface RKManagedObjectLoaderTest : RKTestCase {

}

@end

@implementation RKManagedObjectLoaderTest

- (void)testShouldDeleteObjectFromLocalStoreOnDELETE
{
    RKManagedObjectStore *store = [RKTestFactory managedObjectStore];
    [store save:nil];
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    objectManager.objectStore = store;
    RKHuman *human = [RKHuman object];
    human.name = @"Blake Watters";
    human.railsID = [NSNumber numberWithInt:1];
    [objectManager.objectStore save:nil];

    assertThat(objectManager.objectStore.primaryManagedObjectContext, is(equalTo(store.primaryManagedObjectContext)));

    RKManagedObjectMapping *mapping = [RKManagedObjectMapping mappingForClass:[RKHuman class] inManagedObjectStore:store];
    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    RKURL *URL = [objectManager.baseURL URLByAppendingResourcePath:@"/humans/1"];
    RKManagedObjectLoader *objectLoader = [RKManagedObjectLoader loaderWithURL:URL mappingProvider:objectManager.mappingProvider objectStore:store];
    objectLoader.delegate = responseLoader;
    objectLoader.method = RKRequestMethodDELETE;
    objectLoader.objectMapping = mapping;
    objectLoader.targetObject = human;
    [objectLoader send];
    [responseLoader waitForResponse];
    assertThatBool([human isDeleted], equalToBool(YES));
}

- (void)testShouldLoadAnObjectWithAToOneRelationship
{
    RKManagedObjectStore *store = [RKTestFactory managedObjectStore];
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    objectManager.objectStore = store;

    RKObjectMapping *humanMapping = [RKManagedObjectMapping mappingForClass:[RKHuman class] inManagedObjectStore:store];
    [humanMapping mapAttributes:@"name", nil];
    RKObjectMapping *catMapping = [RKManagedObjectMapping mappingForClass:[RKCat class] inManagedObjectStore:store];
    [catMapping mapAttributes:@"name", nil];
    [humanMapping mapKeyPath:@"favorite_cat" toRelationship:@"favoriteCat" withMapping:catMapping];
    [objectManager.mappingProvider setMapping:humanMapping forKeyPath:@"human"];
    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    RKURL *URL = [objectManager.baseURL URLByAppendingResourcePath:@"/JSON/humans/with_to_one_relationship.json"];
    RKManagedObjectLoader *objectLoader = [RKManagedObjectLoader loaderWithURL:URL mappingProvider:objectManager.mappingProvider objectStore:store];
    objectLoader.delegate = responseLoader;
    [objectLoader send];
    [responseLoader waitForResponse];
    RKHuman *human = [responseLoader.objects lastObject];
    assertThat(human, isNot(nilValue()));
    assertThat(human.favoriteCat, isNot(nilValue()));
    assertThat(human.favoriteCat.name, is(equalTo(@"Asia")));
}

- (void)testShouldDeleteObjectsMissingFromPayloadReturnedByObjectCache
{
    RKManagedObjectStore *store = [RKTestFactory managedObjectStore];
    RKManagedObjectMapping *humanMapping = [RKManagedObjectMapping mappingForEntityWithName:@"RKHuman"
                                                                       inManagedObjectStore:store];
    [humanMapping mapKeyPath:@"id" toAttribute:@"railsID"];
    [humanMapping mapAttributes:@"name", nil];
    humanMapping.primaryKeyAttribute = @"railsID";
    humanMapping.rootKeyPath = @"human";

    // Create 3 objects, we will expect 2 after the load
    [RKHuman truncateAll];
    assertThatUnsignedInteger([RKHuman count:nil], is(equalToInt(0)));
    RKHuman *blake = [RKHuman createEntity];
    blake.railsID = [NSNumber numberWithInt:123];
    RKHuman *other = [RKHuman createEntity];
    other.railsID = [NSNumber numberWithInt:456];
    RKHuman *deleteMe = [RKHuman createEntity];
    deleteMe.railsID = [NSNumber numberWithInt:9999];
    [store save:nil];
    assertThatUnsignedInteger([RKHuman count:nil], is(equalToInt(3)));

    RKObjectManager *objectManager = [RKTestFactory objectManager];
    [objectManager.mappingProvider setObjectMapping:humanMapping
                             forResourcePathPattern:@"/JSON/humans/all.json"
                              withFetchRequestBlock:^ (NSString *resourcePath) {
                                  return [RKHuman fetchRequest];
                              }];
    objectManager.objectStore = store;

    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    responseLoader.timeout = 25;
    RKURL *URL = [objectManager.baseURL URLByAppendingResourcePath:@"/JSON/humans/all.json"];
    RKManagedObjectLoader *objectLoader = [RKManagedObjectLoader loaderWithURL:URL mappingProvider:objectManager.mappingProvider objectStore:store];
    objectLoader.delegate = responseLoader;
    [objectLoader send];
    [responseLoader waitForResponse];

    assertThatUnsignedInteger([RKHuman count:nil], is(equalToInt(2)));
    assertThatBool([blake isDeleted], is(equalToBool(NO)));
    assertThatBool([other isDeleted], is(equalToBool(NO)));
    assertThatBool([deleteMe isDeleted], is(equalToBool(YES)));
}

- (void)testShouldNotAssertDuringObjectMappingOnSynchronousRequest
{
    RKManagedObjectStore *store = [RKTestFactory managedObjectStore];
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    objectManager.objectStore = store;

    RKObjectMapping *mapping = [RKManagedObjectMapping mappingForClass:[RKHuman class] inManagedObjectStore:store];
    RKManagedObjectLoader *objectLoader = [objectManager loaderWithResourcePath:@"/humans/1"];
    objectLoader.objectMapping = mapping;
    RKResponse *response = [objectLoader sendSynchronously];

    NSArray *humans = [RKHuman findAll];
    assertThatUnsignedInteger([humans count], is(equalToInt(1)));
    assertThatInteger(response.statusCode, is(equalToInt(200)));
}

- (void)testShouldSkipObjectMappingOnRequestCacheHitWhenObjectCachePresent
{
    [RKTestFactory clearCacheDirectory];

    RKObjectManager *objectManager = [RKTestFactory objectManager];
    RKManagedObjectStore *objectStore = [RKTestFactory managedObjectStore];
    objectManager.objectStore = objectStore;
    RKManagedObjectMapping *humanMapping = [RKManagedObjectMapping mappingForEntityWithName:@"RKHuman" inManagedObjectStore:objectStore];
    [humanMapping mapKeyPath:@"id" toAttribute:@"railsID"];
    [humanMapping mapAttributes:@"name", nil];
    humanMapping.primaryKeyAttribute = @"railsID";
    humanMapping.rootKeyPath = @"human";

    [RKHuman truncateAll];
    assertThatInteger([RKHuman count:nil], is(equalToInteger(0)));
    RKHuman *blake = [RKHuman createEntity];
    blake.railsID = [NSNumber numberWithInt:123];
    RKHuman *other = [RKHuman createEntity];
    other.railsID = [NSNumber numberWithInt:456];
    [objectStore save:nil];
    assertThatInteger([RKHuman count:nil], is(equalToInteger(2)));

    [objectManager.mappingProvider setMapping:humanMapping forKeyPath:@"human"];
    [objectManager.mappingProvider setObjectMapping:humanMapping forResourcePathPattern:@"/coredata/etag" withFetchRequestBlock:^NSFetchRequest *(NSString *resourcePath) {
        return [RKHuman fetchRequest];
    }];

    {
        RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
        RKManagedObjectLoader *objectLoader = [objectManager loaderWithResourcePath:@"/coredata/etag"];
        objectLoader.delegate = responseLoader;
        id mockLoader = [OCMockObject partialMockForObject:objectLoader];
        [[[mockLoader expect] andForwardToRealObject] performMapping:[OCMArg setTo:OCMOCK_ANY]];

        [mockLoader send];
        [responseLoader waitForResponse];

        STAssertNoThrow([mockLoader verify], nil);
        assertThatInteger([RKHuman count:nil], is(equalToInteger(2)));
        assertThatBool([responseLoader wasSuccessful], is(equalToBool(YES)));
        assertThatBool([responseLoader.response wasLoadedFromCache], is(equalToBool(NO)));
        assertThatInteger([responseLoader.objects count], is(equalToInteger(2)));
    }
    {
        RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
        RKManagedObjectLoader *objectLoader = [objectManager loaderWithResourcePath:@"/coredata/etag"];
        objectLoader.delegate = responseLoader;
        id mockLoader = [OCMockObject partialMockForObject:objectLoader];
        [[mockLoader reject] performMapping:[OCMArg setTo:OCMOCK_ANY]];

        [mockLoader send];
        [responseLoader waitForResponse];

        STAssertNoThrow([mockLoader verify], nil);
        assertThatInteger([RKHuman count:nil], is(equalToInteger(2)));
        assertThatBool([responseLoader wasSuccessful], is(equalToBool(YES)));
        assertThatBool([responseLoader.response wasLoadedFromCache], is(equalToBool(YES)));
        assertThatInteger([responseLoader.objects count], is(equalToInteger(2)));
    }
}

- (void)testTheOnDidFailBlockIsInvokedOnFailure
{
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    RKManagedObjectLoader *loader = [objectManager loaderWithResourcePath:@"/fail"];
    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    __block BOOL invoked = NO;
    loader.onDidFailWithError = ^ (NSError *error) {
        invoked = YES;
    };
    loader.delegate = responseLoader;
    [loader sendAsynchronously];
    [responseLoader waitForResponse];
    assertThatBool(invoked, is(equalToBool(YES)));
}

- (void)testThatObjectLoadedDidFinishLoadingIsCalledOnStoreSaveFailure
{
    RKManagedObjectStore *store = [RKTestFactory managedObjectStore];
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    objectManager.objectStore = store;
    id mockStore = [OCMockObject partialMockForObject:store];
    BOOL success = NO;
    [[[mockStore stub] andReturnValue:OCMOCK_VALUE(success)] save:[OCMArg anyPointer]];

    RKObjectMapping *mapping = [RKManagedObjectMapping mappingForClass:[RKHuman class] inManagedObjectStore:store];
    RKManagedObjectLoader *objectLoader = [objectManager loaderWithResourcePath:@"/humans/1"];
    objectLoader.objectMapping = mapping;

    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    id mockResponseLoader = [OCMockObject partialMockForObject:responseLoader];
    [[mockResponseLoader expect] objectLoaderDidFinishLoading:objectLoader];
    objectLoader.delegate = responseLoader;
    [objectLoader sendAsynchronously];
    [responseLoader waitForResponse];
    [mockResponseLoader verify];
}

@end
