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
#import "RKEntityMapping.h"
#import "RKHuman.h"
#import "RKCat.h"
#import "NSManagedObject+RKAdditions.h"
#import "RKObjectMappingProvider+CoreData.h"

@interface RKManagedObjectLoaderTest : RKTestCase
@end

@implementation RKManagedObjectLoaderTest

- (void)testShouldDeleteObjectFromLocalStoreOnDELETE
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    objectManager.managedObjectStore = managedObjectStore;
    
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    human.name = @"Blake Watters";
    human.railsID = [NSNumber numberWithInt:1];
    [objectManager.managedObjectStore.primaryManagedObjectContext save:nil];

    assertThat(objectManager.managedObjectStore.primaryManagedObjectContext, is(equalTo(managedObjectStore.primaryManagedObjectContext)));

    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:managedObjectStore];
    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    RKURL *URL = [objectManager.baseURL URLByAppendingResourcePath:@"/humans/1"];
    RKManagedObjectLoader *objectLoader = [[RKManagedObjectLoader alloc] initWithURL:URL mappingProvider:objectManager.mappingProvider];
    objectLoader.managedObjectContext = managedObjectStore.primaryManagedObjectContext;
    objectLoader.mainQueueManagedObjectContext = managedObjectStore.mainQueueManagedObjectContext;
    objectLoader.delegate = responseLoader;
    objectLoader.method = RKRequestMethodDELETE;
    objectLoader.objectMapping = mapping;
    objectLoader.targetObject = human;
    [objectLoader send];
    responseLoader.timeout = 60;
    [responseLoader waitForResponse];
    
    assertThatBool([human hasBeenDeleted], equalToBool(YES));
}

- (void)testShouldLoadAnObjectWithAToOneRelationship
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    objectManager.managedObjectStore = managedObjectStore;

    RKObjectMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:managedObjectStore];
    [humanMapping mapAttributes:@"name", nil];
    RKObjectMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"RKCat" inManagedObjectStore:managedObjectStore];
    [catMapping mapAttributes:@"name", nil];
    [humanMapping mapKeyPath:@"favorite_cat" toRelationship:@"favoriteCat" withMapping:catMapping];
    [objectManager.mappingProvider setMapping:humanMapping forKeyPath:@"human"];
    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    RKURL *URL = [objectManager.baseURL URLByAppendingResourcePath:@"/JSON/humans/with_to_one_relationship.json"];
    RKManagedObjectLoader *objectLoader = [[[RKManagedObjectLoader alloc] initWithURL:URL mappingProvider:objectManager.mappingProvider] autorelease];
    objectLoader.managedObjectContext = managedObjectStore.primaryManagedObjectContext;
    objectLoader.mainQueueManagedObjectContext = managedObjectStore.mainQueueManagedObjectContext;
    objectLoader.delegate = responseLoader;
    [objectLoader send];
    responseLoader.timeout = 50;
    [responseLoader waitForResponse];
    RKHuman *human = [responseLoader.objects lastObject];
    assertThat(human, isNot(nilValue()));
    assertThat(human.name, is(equalTo(@"Blake Watters")));
    assertThat(human.favoriteCat, isNot(nilValue()));
    assertThat(human.favoriteCat.name, is(equalTo(@"Asia")));
}

- (void)testShouldDeleteObjectsMissingFromPayloadReturnedByObjectCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"RKHuman"
                                                                       inManagedObjectStore:managedObjectStore];
    [humanMapping mapKeyPath:@"id" toAttribute:@"railsID"];
    [humanMapping mapAttributes:@"name", nil];
    humanMapping.primaryKeyAttribute = @"railsID";
    humanMapping.rootKeyPath = @"human";

    // Create 3 objects, we will expect 2 after the load
    NSError *error;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"RKHuman"];
    NSUInteger count = [managedObjectStore.primaryManagedObjectContext countForFetchRequest:fetchRequest error:&error];

    assertThatUnsignedInteger(count, is(equalToInt(0)));
    RKHuman *blake = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    blake.railsID = [NSNumber numberWithInt:123];
    RKHuman *other = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    other.railsID = [NSNumber numberWithInt:456];
    RKHuman *deleteMe = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    deleteMe.railsID = [NSNumber numberWithInt:9999];
    [managedObjectStore.primaryManagedObjectContext save:nil];

    count = [managedObjectStore.primaryManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    assertThatUnsignedInteger(count, is(equalToInt(3)));

    RKObjectManager *objectManager = [RKTestFactory objectManager];
    [objectManager.mappingProvider setObjectMapping:humanMapping
                             forResourcePathPattern:@"/JSON/humans/all.json"
                              withFetchRequestBlock:^ (NSString *resourcePath) {
                                  return fetchRequest;
                              }];
    objectManager.managedObjectStore = managedObjectStore;

    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    responseLoader.timeout = 25;
    RKURL *URL = [objectManager.baseURL URLByAppendingResourcePath:@"/JSON/humans/all.json"];
    RKManagedObjectLoader *objectLoader = [[[RKManagedObjectLoader alloc] initWithURL:URL mappingProvider:objectManager.mappingProvider] autorelease];
    objectLoader.managedObjectContext = managedObjectStore.primaryManagedObjectContext;
    objectLoader.mainQueueManagedObjectContext = managedObjectStore.mainQueueManagedObjectContext;
    objectLoader.delegate = responseLoader;
    [objectLoader send];
    [responseLoader waitForResponse];

    count = [managedObjectStore.primaryManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    assertThatUnsignedInteger(count, is(equalToInt(2)));
    assertThatBool([blake isDeleted], is(equalToBool(NO)));
    assertThatBool([other isDeleted], is(equalToBool(NO)));
    assertThatBool([deleteMe hasBeenDeleted], is(equalToBool(YES)));
}

- (void)testShouldNotAssertDuringObjectMappingOnSynchronousRequest
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    objectManager.managedObjectStore = managedObjectStore;

    RKObjectMapping *mapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:managedObjectStore];
    RKManagedObjectLoader *objectLoader = [objectManager loaderWithResourcePath:@"/humans/1"];
    objectLoader.objectMapping = mapping;
    RKResponse *response = [objectLoader sendSynchronously];

    NSUInteger humanCount = [managedObjectStore.primaryManagedObjectContext countForEntityForName:@"RKHuman" predicate:nil error:nil];
    assertThatUnsignedInteger(humanCount, is(equalToInt(1)));
    assertThatInteger(response.statusCode, is(equalToInt(200)));
}

- (void)testShouldSkipObjectMappingOnRequestCacheHitWhenObjectCachePresent
{
    [RKTestFactory clearCacheDirectory];

    RKObjectManager *objectManager = [RKTestFactory objectManager];
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    objectManager.managedObjectStore = managedObjectStore;
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:managedObjectStore];
    [humanMapping mapKeyPath:@"id" toAttribute:@"railsID"];
    [humanMapping mapAttributes:@"name", nil];
    humanMapping.primaryKeyAttribute = @"railsID";
    humanMapping.rootKeyPath = @"human";

    NSError *error;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"RKHuman"];
    NSUInteger count = [managedObjectStore.primaryManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    assertThatInteger(count, is(equalToInteger(0)));
    RKHuman *blake = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    blake.railsID = [NSNumber numberWithInt:123];
    RKHuman *other = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    other.railsID = [NSNumber numberWithInt:456];
    [managedObjectStore.primaryManagedObjectContext save:nil];
    count = [managedObjectStore.primaryManagedObjectContext countForFetchRequest:fetchRequest error:&error];
    assertThatInteger(count, is(equalToInteger(2)));

    [objectManager.mappingProvider setMapping:humanMapping forKeyPath:@"human"];
    [objectManager.mappingProvider setObjectMapping:humanMapping forResourcePathPattern:@"/coredata/etag" withFetchRequestBlock:^NSFetchRequest *(NSString *resourcePath) {
        return fetchRequest;
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
        count = [managedObjectStore.primaryManagedObjectContext countForFetchRequest:fetchRequest error:&error];
        assertThatInteger(count, is(equalToInteger(2)));
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
        count = [managedObjectStore.primaryManagedObjectContext countForFetchRequest:fetchRequest error:&error];
        assertThatInteger(count, is(equalToInteger(2)));
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
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    objectManager.managedObjectStore = managedObjectStore;
    id mockStore = [OCMockObject partialMockForObject:managedObjectStore];
    BOOL success = NO;
    [[[mockStore stub] andReturnValue:OCMOCK_VALUE(success)] save:[OCMArg anyPointer]];

    RKObjectMapping *mapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:managedObjectStore];
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

- (void)testObtainingPermanentObjectIDForSourceObjectOnSuccess
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    objectManager.managedObjectStore = managedObjectStore;
    RKObjectMapping *mapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:managedObjectStore];
    RKManagedObjectLoader *objectLoader = [objectManager loaderWithResourcePath:@"/humans/1"];
    objectLoader.objectMapping = mapping;
    objectLoader.serializationMapping = [RKObjectMapping serializationMapping];
    [objectLoader.serializationMapping mapAttributes:@"name", nil];
    
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:managedObjectStore.primaryManagedObjectContext];
    assertThatBool([human.objectID isTemporaryID], is(equalToBool(YES)));
    objectLoader.sourceObject = human;
    objectLoader.method = RKRequestMethodGET;
    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    objectLoader.delegate = responseLoader;
    [objectLoader send];
    [responseLoader waitForResponse];
    assertThatBool([human.objectID isTemporaryID], is(equalToBool(NO)));
}

@end
