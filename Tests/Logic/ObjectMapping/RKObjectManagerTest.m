//
//  RKObjectManagerTest.m
//  RestKit
//
//  Created by Blake Watters on 1/14/10.
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
#import "RKObjectManager.h"
#import "RKManagedObjectStore.h"
#import "RKTestResponseLoader.h"
#import "RKEntityMapping.h"
#import "RKObjectMappingProvider.h"
#import "RKHuman.h"
#import "RKCat.h"
#import "RKObjectMapperTestModel.h"

@interface RKObjectManagerTest : RKTestCase {
    RKObjectManager *_objectManager;
}

@end

@implementation RKObjectManagerTest

- (void)setUp
{
    [RKTestFactory setUp];

    _objectManager = [RKTestFactory objectManager];
    _objectManager.managedObjectStore = [RKTestFactory managedObjectStore];
    [RKObjectManager setSharedManager:_objectManager];
    NSError *error;
    [_objectManager.managedObjectStore resetPersistentStores:&error];

    RKObjectMappingProvider *provider = [[RKObjectMappingProvider new] autorelease];

    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:_objectManager.managedObjectStore];
    humanMapping.rootKeyPath = @"human";
    [humanMapping addAttributeMapping:[RKAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"]];
    [humanMapping addAttributeMapping:[RKAttributeMapping mappingFromKeyPath:@"nick-name" toKeyPath:@"nickName"]];
    [humanMapping addAttributeMapping:[RKAttributeMapping mappingFromKeyPath:@"birthday" toKeyPath:@"birthday"]];
    [humanMapping addAttributeMapping:[RKAttributeMapping mappingFromKeyPath:@"sex" toKeyPath:@"sex"]];
    [humanMapping addAttributeMapping:[RKAttributeMapping mappingFromKeyPath:@"age" toKeyPath:@"age"]];
    [humanMapping addAttributeMapping:[RKAttributeMapping mappingFromKeyPath:@"created-at" toKeyPath:@"createdAt"]];
    [humanMapping addAttributeMapping:[RKAttributeMapping mappingFromKeyPath:@"updated-at" toKeyPath:@"updatedAt"]];
    [humanMapping addAttributeMapping:[RKAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"railsID"]];

    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"RKCat" inManagedObjectStore:_objectManager.managedObjectStore];
    [catMapping addAttributeMapping:[RKAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"]];
    [catMapping addAttributeMapping:[RKAttributeMapping mappingFromKeyPath:@"nick-name" toKeyPath:@"nickName"]];
    [catMapping addAttributeMapping:[RKAttributeMapping mappingFromKeyPath:@"birthday" toKeyPath:@"birthday"]];
    [catMapping addAttributeMapping:[RKAttributeMapping mappingFromKeyPath:@"sex" toKeyPath:@"sex"]];
    [catMapping addAttributeMapping:[RKAttributeMapping mappingFromKeyPath:@"age" toKeyPath:@"age"]];
    [catMapping addAttributeMapping:[RKAttributeMapping mappingFromKeyPath:@"created-at" toKeyPath:@"createdAt"]];
    [catMapping addAttributeMapping:[RKAttributeMapping mappingFromKeyPath:@"updated-at" toKeyPath:@"updatedAt"]];
    [catMapping addAttributeMapping:[RKAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"railsID"]];

    [catMapping addRelationshipMapping:[RKRelationshipMapping mappingFromKeyPath:@"cats" toKeyPath:@"cats" withMapping:catMapping]];

    [provider setMapping:humanMapping forKeyPath:@"human"];
    [provider setMapping:humanMapping forKeyPath:@"humans"];

    RKObjectMapping *humanSerialization = [RKObjectMapping mappingForClass:[NSDictionary class]];
    [humanSerialization addAttributeMapping:[RKAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"]];
    [provider setSerializationMapping:humanSerialization forClass:[RKHuman class]];
    _objectManager.mappingProvider = provider;
    [_objectManager.router.routeSet addRoute:[RKRoute routeWithClass:[RKHuman class] resourcePathPattern:@"/humans" method:RKRequestMethodPOST]];
}

- (void)tearDown
{
    [RKTestFactory tearDown];
}

- (void)testShouldSetTheAcceptHeaderAppropriatelyForTheFormat
{
    assertThat([_objectManager.client.HTTPHeaders valueForKey:@"Accept"], is(equalTo(@"application/json")));
}

// TODO: Move to Core Data specific spec file...
- (void)testShouldUpdateACoreDataBackedTargetObject
{
    RKHuman *temporaryHuman = [[RKHuman alloc] initWithEntity:[NSEntityDescription entityForName:@"RKHuman" inManagedObjectContext:_objectManager.managedObjectStore.primaryManagedObjectContext] insertIntoManagedObjectContext:_objectManager.managedObjectStore.primaryManagedObjectContext];
    temporaryHuman.name = @"My Name";
    
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    [_objectManager postObject:temporaryHuman delegate:loader];
    [loader waitForResponse];

    assertThat(loader.objects, isNot(empty()));
    RKHuman *human = (RKHuman *)[loader.objects objectAtIndex:0];
    assertThat(human.objectID, is(equalTo(temporaryHuman.objectID)));
    assertThat(human.railsID, is(equalToInt(1)));
}

- (void)testShouldNotPersistTemporaryEntityToPersistentStoreOnError
{
    RKHuman *temporaryHuman = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:_objectManager.managedObjectStore.primaryManagedObjectContext];
    temporaryHuman.name = @"My Name";
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [mapping mapAttributes:@"name", nil];

    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    NSString *resourcePath = @"/humans/fail";
    RKObjectLoader *objectLoader = [_objectManager loaderWithResourcePath:resourcePath];
    objectLoader.delegate = loader;
    objectLoader.method = RKRequestMethodPOST;
    objectLoader.targetObject = temporaryHuman;
    objectLoader.serializationMapping = mapping;
    [objectLoader send];
    [loader waitForResponse];

    assertThatBool([temporaryHuman isNew], is(equalToBool(YES)));
}

- (void)testShouldNotDeleteACoreDataBackedTargetObjectOnErrorIfItWasAlreadySaved
{
    RKHuman *temporaryHuman = [[RKHuman alloc] initWithEntity:[NSEntityDescription entityForName:@"RKHuman" inManagedObjectContext:_objectManager.managedObjectStore.primaryManagedObjectContext] insertIntoManagedObjectContext:_objectManager.managedObjectStore.primaryManagedObjectContext];
    temporaryHuman.name = @"My Name";
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [mapping mapAttributes:@"name", nil];

    // Save it to suppress deletion
    [_objectManager.managedObjectStore.primaryManagedObjectContext save:nil];

    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    NSString *resourcePath = @"/humans/fail";
    RKObjectLoader *objectLoader = [_objectManager loaderWithResourcePath:resourcePath];
    objectLoader.delegate = loader;
    objectLoader.method = RKRequestMethodPOST;
    objectLoader.targetObject = temporaryHuman;
    objectLoader.serializationMapping = mapping;
    [objectLoader send];
    [loader waitForResponse];

    assertThat(temporaryHuman.managedObjectContext, is(equalTo(_objectManager.managedObjectStore.primaryManagedObjectContext)));
}

// TODO: Move to Core Data specific spec file...
- (void)testShouldLoadAHuman
{
    assertThatBool([RKClient sharedClient].isNetworkReachable, is(equalToBool(YES)));
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    [_objectManager loadObjectsAtResourcePath:@"/JSON/humans/1.json" delegate:loader];
    [loader waitForResponse];
    assertThat(loader.error, is(nilValue()));
    assertThat(loader.objects, isNot(empty()));
    RKHuman *blake = (RKHuman *)[loader.objects objectAtIndex:0];
    assertThat(blake.name, is(equalTo(@"Blake Watters")));
}

- (void)testShouldLoadAllHumans
{
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    [_objectManager loadObjectsAtResourcePath:@"/JSON/humans/all.json" delegate:loader];
    [loader waitForResponse];
    NSArray *humans = (NSArray *)loader.objects;
    assertThatUnsignedInteger([humans count], is(equalToInt(2)));
    assertThat([humans objectAtIndex:0], is(instanceOf([RKHuman class])));
}

- (void)testShouldHandleConnectionFailures
{
    NSString *localBaseURL = [NSString stringWithFormat:@"http://127.0.0.1:3001"];
    RKObjectManager *modelManager = [RKObjectManager managerWithBaseURLString:localBaseURL];
    modelManager.client.requestQueue.suspended = NO;
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    [modelManager loadObjectsAtResourcePath:@"/JSON/humans/1" delegate:loader];
    [loader waitForResponse];
    assertThatBool(loader.wasSuccessful, is(equalToBool(NO)));
}

- (void)testShouldPOSTAnObject
{
    RKObjectManager *manager = [RKTestFactory objectManager];
    [manager.router.routeSet addRoute:[RKRoute routeWithClass:[RKObjectMapperTestModel class] resourcePathPattern:@"/humans" method:RKRequestMethodPOST]];

    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKObjectMapperTestModel class]];
    mapping.rootKeyPath = @"human";
    [mapping mapAttributes:@"name", @"age", nil];
    [manager.mappingProvider setMapping:mapping forKeyPath:@"human"];
    [manager.mappingProvider setSerializationMapping:mapping forClass:[RKObjectMapperTestModel class]];

    RKObjectMapperTestModel *human = [[RKObjectMapperTestModel new] autorelease];
    human.name = @"Blake Watters";
    human.age = [NSNumber numberWithInt:28];

    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    [manager postObject:human delegate:loader];
    [loader waitForResponse];

    // NOTE: The /humans endpoint returns a canned response, we are testing the plumbing
    // of the object manager here.
    assertThat(human.name, is(equalTo(@"My Name")));
}

- (void)testShouldNotSetAContentBodyOnAGET
{
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    [objectManager.router.routeSet addRoute:[RKRoute routeWithClass:[RKObjectMapperTestModel class] resourcePathPattern:@"/humans/1" method:RKRequestMethodAny]];

    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKObjectMapperTestModel class]];
    [mapping mapAttributes:@"name", @"age", nil];
    [objectManager.mappingProvider registerMapping:mapping withRootKeyPath:@"human"];

    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    RKObjectMapperTestModel *human = [[RKObjectMapperTestModel new] autorelease];
    human.name = @"Blake Watters";
    human.age = [NSNumber numberWithInt:28];
    __block RKObjectLoader *objectLoader = nil;
    [objectManager getObject:human usingBlock:^(RKObjectLoader *loader) {
        loader.delegate = responseLoader;
        objectLoader = loader;
    }];
    [responseLoader waitForResponse];
    RKLogCritical(@"%@", [objectLoader.URLRequest allHTTPHeaderFields]);
    assertThat([objectLoader.URLRequest valueForHTTPHeaderField:@"Content-Length"], is(equalTo(@"0")));
}

- (void)testShouldNotSetAContentBodyOnADELETE
{
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    [objectManager.router.routeSet addRoute:[RKRoute routeWithClass:[RKObjectMapperTestModel class] resourcePathPattern:@"/humans/1" method:RKRequestMethodAny]];

    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKObjectMapperTestModel class]];
    [mapping mapAttributes:@"name", @"age", nil];
    [objectManager.mappingProvider registerMapping:mapping withRootKeyPath:@"human"];

    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    RKObjectMapperTestModel *human = [[RKObjectMapperTestModel new] autorelease];
    human.name = @"Blake Watters";
    human.age = [NSNumber numberWithInt:28];
    __block RKObjectLoader *objectLoader = nil;
    [objectManager deleteObject:human usingBlock:^(RKObjectLoader *loader) {
        loader.delegate = responseLoader;
        objectLoader = loader;
    }];
    [responseLoader waitForResponse];
    RKLogCritical(@"%@", [objectLoader.URLRequest allHTTPHeaderFields]);
    assertThat([objectLoader.URLRequest valueForHTTPHeaderField:@"Content-Length"], is(equalTo(@"0")));
}

#pragma mark - Block Helpers

- (void)testShouldLetYouLoadObjectsWithABlock
{
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKObjectMapperTestModel class]];
    [mapping mapAttributes:@"name", @"age", nil];
    [objectManager.mappingProvider registerMapping:mapping withRootKeyPath:@"human"];

    RKTestResponseLoader *responseLoader = [[RKTestResponseLoader responseLoader] retain];
    [objectManager loadObjectsAtResourcePath:@"/JSON/humans/1.json" usingBlock:^(RKObjectLoader *loader) {
        loader.delegate = responseLoader;
        loader.objectMapping = mapping;
    }];
    [responseLoader waitForResponse];
    assertThatBool(responseLoader.wasSuccessful, is(equalToBool(YES)));
    assertThat(responseLoader.objects, hasCountOf(1));
}

- (void)testShouldAllowYouToOverrideTheRoutedResourcePath
{
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    [objectManager.router.routeSet addRoute:[RKRoute routeWithClass:[RKObjectMapperTestModel class] resourcePathPattern:@"/humans/2" method:RKRequestMethodAny]];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKObjectMapperTestModel class]];
    [mapping mapAttributes:@"name", @"age", nil];
    [objectManager.mappingProvider registerMapping:mapping withRootKeyPath:@"human"];

    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    RKObjectMapperTestModel *human = [[RKObjectMapperTestModel new] autorelease];
    human.name = @"Blake Watters";
    human.age = [NSNumber numberWithInt:28];
    [objectManager deleteObject:human usingBlock:^(RKObjectLoader *loader) {
        loader.delegate = responseLoader;
        loader.resourcePath = @"/humans/1";
    }];
    responseLoader.timeout = 50;
    [responseLoader waitForResponse];
    assertThat(responseLoader.response.request.resourcePath, is(equalTo(@"/humans/1")));
}

- (void)testShouldAllowYouToUseObjectHelpersWithoutRouting
{
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKObjectMapperTestModel class]];
    [mapping mapAttributes:@"name", @"age", nil];
    [objectManager.mappingProvider registerMapping:mapping withRootKeyPath:@"human"];

    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    RKObjectMapperTestModel *human = [[RKObjectMapperTestModel new] autorelease];
    human.name = @"Blake Watters";
    human.age = [NSNumber numberWithInt:28];
    [objectManager sendObject:human toResourcePath:@"/humans/1" usingBlock:^(RKObjectLoader *loader) {
        loader.method = RKRequestMethodDELETE;
        loader.delegate = responseLoader;
        loader.resourcePath = @"/humans/1";
    }];
    [responseLoader waitForResponse];
    assertThat(responseLoader.response.request.resourcePath, is(equalTo(@"/humans/1")));
}

- (void)testShouldAllowYouToSkipTheMappingProvider
{
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKObjectMapperTestModel class]];
    mapping.rootKeyPath = @"human";
    [mapping mapAttributes:@"name", @"age", nil];

    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    RKObjectMapperTestModel *human = [[RKObjectMapperTestModel new] autorelease];
    human.name = @"Blake Watters";
    human.age = [NSNumber numberWithInt:28];
    [objectManager sendObject:human toResourcePath:@"/humans/1" usingBlock:^(RKObjectLoader *loader) {
        loader.method = RKRequestMethodDELETE;
        loader.delegate = responseLoader;
        loader.objectMapping = mapping;
    }];
    [responseLoader waitForResponse];
    assertThatBool(responseLoader.wasSuccessful, is(equalToBool(YES)));
    assertThat(responseLoader.response.request.resourcePath, is(equalTo(@"/humans/1")));
}

- (void)testShouldLetYouOverloadTheParamsOnAnObjectLoaderRequest
{
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKObjectMapperTestModel class]];
    mapping.rootKeyPath = @"human";
    [mapping mapAttributes:@"name", @"age", nil];

    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    RKObjectMapperTestModel *human = [[RKObjectMapperTestModel new] autorelease];
    human.name = @"Blake Watters";
    human.age = [NSNumber numberWithInt:28];
    NSDictionary *myParams = [NSDictionary dictionaryWithObject:@"bar" forKey:@"foo"];
    __block RKObjectLoader *objectLoader = nil;
    [objectManager sendObject:human toResourcePath:@"/humans/1" usingBlock:^(RKObjectLoader *loader) {
        loader.delegate = responseLoader;
        loader.method = RKRequestMethodPOST;
        loader.objectMapping = mapping;
        loader.params = myParams;
        objectLoader = loader;
    }];
    [responseLoader waitForResponse];
    assertThat(objectLoader.params, is(equalTo(myParams)));
}

- (void)testInitializationOfObjectLoaderViaManagerConfiguresSerializationMIMEType
{
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    objectManager.serializationMIMEType = RKMIMETypeJSON;
    RKObjectLoader *loader = [objectManager loaderWithResourcePath:@"/test"];
    assertThat(loader.serializationMIMEType, isNot(nilValue()));
    assertThat(loader.serializationMIMEType, is(equalTo(RKMIMETypeJSON)));
}

- (void)testInitializationOfRoutedPathViaSendObjectMethodUsingBlock
{
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKObjectMapperTestModel class]];
    mapping.rootKeyPath = @"human";
    [objectManager.mappingProvider registerObjectMapping:mapping withRootKeyPath:@"human"];
    [objectManager.router.routeSet addRoute:[RKRoute routeWithClass:[RKObjectMapperTestModel class] resourcePathPattern:@"/human/1" method:RKRequestMethodAny]];
    objectManager.serializationMIMEType = RKMIMETypeJSON;
    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];

    RKObjectMapperTestModel *object = [RKObjectMapperTestModel new];
    [objectManager putObject:object usingBlock:^(RKObjectLoader *loader) {
        loader.delegate = responseLoader;
    }];
    [responseLoader waitForResponse];
}

- (void)testThatInitializationOfObjectManagerInitializesNetworkStatusFromClient
{
    RKReachabilityObserver *observer = [[RKReachabilityObserver alloc] initWithHost:@"google.com"];
    id mockObserver = [OCMockObject partialMockForObject:observer];
    BOOL yes = YES;
    [[[mockObserver stub] andReturnValue:OCMOCK_VALUE(yes)] isReachabilityDetermined];
    [[[mockObserver stub] andReturnValue:OCMOCK_VALUE(yes)] isNetworkReachable];
    RKClient *client = [RKTestFactory client];
    client.reachabilityObserver = mockObserver;
    RKObjectManager *manager = [[RKObjectManager alloc] init];
    manager.client = client;
    assertThatInteger(manager.networkStatus, is(equalToInteger(RKObjectManagerNetworkStatusOnline)));
}

- (void)testThatMutationOfUnderlyingClientReachabilityObserverUpdatesManager
{
    RKObjectManager *manager = [RKTestFactory objectManager];
    RKReachabilityObserver *observer = [[RKReachabilityObserver alloc] initWithHost:@"google.com"];
    assertThatInteger(manager.networkStatus, is(equalToInteger(RKObjectManagerNetworkStatusOnline)));
    manager.client.reachabilityObserver = observer;
    assertThatInteger(manager.networkStatus, is(equalToInteger(RKObjectManagerNetworkStatusUnknown)));
}

- (void)testThatReplacementOfUnderlyingClientUpdatesManagerReachabilityObserver
{
    RKObjectManager *manager = [RKTestFactory objectManager];
    RKReachabilityObserver *observer = [[RKReachabilityObserver alloc] initWithHost:@"google.com"];
    RKClient *client = [RKTestFactory client];
    client.reachabilityObserver = observer;
    assertThatInteger(manager.networkStatus, is(equalToInteger(RKObjectManagerNetworkStatusOnline)));
    manager.client = client;
    assertThatInteger(manager.networkStatus, is(equalToInteger(RKObjectManagerNetworkStatusUnknown)));
}

@end
