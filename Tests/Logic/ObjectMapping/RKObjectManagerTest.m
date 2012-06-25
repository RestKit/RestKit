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
#import "RKManagedObjectMapping.h"
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
    _objectManager.objectStore = [RKManagedObjectStore objectStoreWithStoreFilename:@"RKTests.sqlite"];
    [RKObjectManager setSharedManager:_objectManager];
    [_objectManager.objectStore deletePersistentStore];

    RKObjectMappingProvider *provider = [[RKObjectMappingProvider new] autorelease];

    RKManagedObjectMapping *humanMapping = [RKManagedObjectMapping mappingForClass:[RKHuman class] inManagedObjectStore:_objectManager.objectStore];
    humanMapping.rootKeyPath = @"human";
    [humanMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"]];
    [humanMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"nick-name" toKeyPath:@"nickName"]];
    [humanMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"birthday" toKeyPath:@"birthday"]];
    [humanMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"sex" toKeyPath:@"sex"]];
    [humanMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"age" toKeyPath:@"age"]];
    [humanMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"created-at" toKeyPath:@"createdAt"]];
    [humanMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"updated-at" toKeyPath:@"updatedAt"]];
    [humanMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"railsID"]];

    RKManagedObjectMapping *catObjectMapping = [RKManagedObjectMapping mappingForClass:[RKCat class] inManagedObjectStore:_objectManager.objectStore];
    [catObjectMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"]];
    [catObjectMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"nick-name" toKeyPath:@"nickName"]];
    [catObjectMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"birthday" toKeyPath:@"birthday"]];
    [catObjectMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"sex" toKeyPath:@"sex"]];
    [catObjectMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"age" toKeyPath:@"age"]];
    [catObjectMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"created-at" toKeyPath:@"createdAt"]];
    [catObjectMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"updated-at" toKeyPath:@"updatedAt"]];
    [catObjectMapping addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"id" toKeyPath:@"railsID"]];

    [catObjectMapping addRelationshipMapping:[RKObjectRelationshipMapping mappingFromKeyPath:@"cats" toKeyPath:@"cats" withMapping:catObjectMapping]];

    [provider setMapping:humanMapping forKeyPath:@"human"];
    [provider setMapping:humanMapping forKeyPath:@"humans"];

    RKObjectMapping *humanSerialization = [RKObjectMapping mappingForClass:[NSDictionary class]];
    [humanSerialization addAttributeMapping:[RKObjectAttributeMapping mappingFromKeyPath:@"name" toKeyPath:@"name"]];
    [provider setSerializationMapping:humanSerialization forClass:[RKHuman class]];
    _objectManager.mappingProvider = provider;

    RKObjectRouter *router = [[[RKObjectRouter alloc] init] autorelease];
    [router routeClass:[RKHuman class] toResourcePath:@"/humans" forMethod:RKRequestMethodPOST];
    _objectManager.router = router;
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
    RKHuman *temporaryHuman = [[RKHuman alloc] initWithEntity:[NSEntityDescription entityForName:@"RKHuman" inManagedObjectContext:_objectManager.objectStore.primaryManagedObjectContext] insertIntoManagedObjectContext:_objectManager.objectStore.primaryManagedObjectContext];
    temporaryHuman.name = @"My Name";

    // TODO: We should NOT have to save the object store here to make this
    // spec pass. Without it we are crashing inside the mapper internals. Believe
    // that we just need a way to save the context before we begin mapping or something
    // on success. Always saving means that we can abandon objects on failure...
    [_objectManager.objectStore save:nil];
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    [_objectManager postObject:temporaryHuman delegate:loader];
    [loader waitForResponse];

    assertThat(loader.objects, isNot(empty()));
    RKHuman *human = (RKHuman *)[loader.objects objectAtIndex:0];
    assertThat(human, is(equalTo(temporaryHuman)));
    assertThat(human.railsID, is(equalToInt(1)));
}

- (void)testShouldDeleteACoreDataBackedTargetObjectOnError
{
    RKHuman *temporaryHuman = [[RKHuman alloc] initWithEntity:[NSEntityDescription entityForName:@"RKHuman" inManagedObjectContext:_objectManager.objectStore.primaryManagedObjectContext] insertIntoManagedObjectContext:_objectManager.objectStore.primaryManagedObjectContext];
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

    assertThat(temporaryHuman.managedObjectContext, is(equalTo(nil)));
}

- (void)testShouldNotDeleteACoreDataBackedTargetObjectOnErrorIfItWasAlreadySaved
{
    RKHuman *temporaryHuman = [[RKHuman alloc] initWithEntity:[NSEntityDescription entityForName:@"RKHuman" inManagedObjectContext:_objectManager.objectStore.primaryManagedObjectContext] insertIntoManagedObjectContext:_objectManager.objectStore.primaryManagedObjectContext];
    temporaryHuman.name = @"My Name";
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [mapping mapAttributes:@"name", nil];

    // Save it to suppress deletion
    [_objectManager.objectStore save:nil];

    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    NSString *resourcePath = @"/humans/fail";
    RKObjectLoader *objectLoader = [_objectManager loaderWithResourcePath:resourcePath];
    objectLoader.delegate = loader;
    objectLoader.method = RKRequestMethodPOST;
    objectLoader.targetObject = temporaryHuman;
    objectLoader.serializationMapping = mapping;
    [objectLoader send];
    [loader waitForResponse];

    assertThat(temporaryHuman.managedObjectContext, is(equalTo(_objectManager.objectStore.primaryManagedObjectContext)));
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

    RKObjectRouter *router = [[RKObjectRouter new] autorelease];
    [router routeClass:[RKObjectMapperTestModel class] toResourcePath:@"/humans" forMethod:RKRequestMethodPOST];
    manager.router = router;

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
    [objectManager.router routeClass:[RKObjectMapperTestModel class] toResourcePath:@"/humans/1"];

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
    [objectManager.router routeClass:[RKObjectMapperTestModel class] toResourcePath:@"/humans/1"];

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

    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
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
    [objectManager.router routeClass:[RKObjectMapperTestModel class] toResourcePath:@"/humans/2"];
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
    [objectManager.router routeClass:[RKObjectMapperTestModel class] toResourcePath:@"/human/1"];
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
