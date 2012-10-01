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
#import "RKEntityMapping.h"
#import "RKHuman.h"
#import "RKCat.h"
#import "RKObjectMapperTestModel.h"

void RKAssociateBaseURLWithURL(NSURL *baseURL, NSURL *URL);
NSURL *RKBaseURLAssociatedWithURL(NSURL *URL);

@interface RKObjectManagerTest : RKTestCase

@property (nonatomic, strong) RKObjectManager *objectManager;
@property (nonatomic, strong) RKRoute *humanGETRoute;
@property (nonatomic, strong) RKRoute *humanPOSTRoute;
@property (nonatomic, strong) RKRoute *humanCatsRoute;
@property (nonatomic, strong) RKRoute *humansCollectionRoute;

@end

@implementation RKObjectManagerTest

- (void)setUp
{
    [RKTestFactory setUp];
    
    self.objectManager = [RKTestFactory objectManager];
    self.objectManager.managedObjectStore = [RKTestFactory managedObjectStore];
    [RKObjectManager setSharedManager:self.objectManager];
    NSError *error;
    [self.objectManager.managedObjectStore resetPersistentStores:&error];
    
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"RKHuman" inManagedObjectStore:_objectManager.managedObjectStore];
    [humanMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"]];
    [humanMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"nick-name" toKeyPath:@"nickName"]];
    [humanMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"birthday" toKeyPath:@"birthday"]];
    [humanMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"sex" toKeyPath:@"sex"]];
    [humanMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"age" toKeyPath:@"age"]];
    [humanMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"created-at" toKeyPath:@"createdAt"]];
    [humanMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"updated-at" toKeyPath:@"updatedAt"]];
    [humanMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"railsID"]];
    
    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"RKCat" inManagedObjectStore:_objectManager.managedObjectStore];
    [catMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"]];
    [catMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"nick-name" toKeyPath:@"nickName"]];
    [catMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"birthday" toKeyPath:@"birthday"]];
    [catMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"sex" toKeyPath:@"sex"]];
    [catMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"age" toKeyPath:@"age"]];
    [catMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"created-at" toKeyPath:@"createdAt"]];
    [catMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"updated-at" toKeyPath:@"updatedAt"]];
    [catMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"railsID"]];
    
    [catMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"cats" toKeyPath:@"cats" withMapping:catMapping]];
    
    [self.objectManager addResponseDescriptorsFromArray:@[
     [RKResponseDescriptor responseDescriptorWithMapping:humanMapping pathPattern:nil keyPath:@"human" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)],
     [RKResponseDescriptor responseDescriptorWithMapping:humanMapping pathPattern:nil keyPath:@"humans" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)]
     ]];
    
    RKObjectMapping *humanSerialization = [RKObjectMapping mappingForClass:[NSDictionary class]];
    [humanSerialization addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"]];
    [self.objectManager addRequestDescriptor:[RKRequestDescriptor requestDescriptorWithMapping:humanSerialization objectClass:[RKHuman class] rootKeyPath:@"human"]];

    self.humanPOSTRoute = [RKRoute routeWithClass:[RKHuman class] pathPattern:@"/humans" method:RKRequestMethodPOST];
    self.humanGETRoute = [RKRoute routeWithClass:[RKHuman class] pathPattern:@"/humans/:railsID" method:RKRequestMethodGET];
    self.humanCatsRoute = [RKRoute routeWithRelationshipName:@"cats" objectClass:[RKHuman class] pathPattern:@"/humans/:railsID/cats" method:RKRequestMethodGET];
    self.humansCollectionRoute = [RKRoute routeWithName:@"humans" pathPattern:@"/humans" method:RKRequestMethodGET];

    [self.objectManager.router.routeSet addRoute:self.humanPOSTRoute];
    [self.objectManager.router.routeSet addRoute:self.humanGETRoute];
    [self.objectManager.router.routeSet addRoute:self.humanCatsRoute];
    [self.objectManager.router.routeSet addRoute:self.humansCollectionRoute];
}

- (void)tearDown
{
    [RKTestFactory tearDown];
}

// TODO: Move to Core Data specific spec file...
- (void)testShouldUpdateACoreDataBackedTargetObject
{
    RKHuman *temporaryHuman = [[RKHuman alloc] initWithEntity:[NSEntityDescription entityForName:@"RKHuman" inManagedObjectContext:_objectManager.managedObjectStore.persistentStoreManagedObjectContext] insertIntoManagedObjectContext:_objectManager.managedObjectStore.persistentStoreManagedObjectContext];
    temporaryHuman.name = @"My Name";
    
    RKManagedObjectRequestOperation *operation = [_objectManager appropriateObjectRequestOperationWithObject:temporaryHuman method:RKRequestMethodPOST path:nil parameters:nil];
    [operation start];
    [operation waitUntilFinished];
    
    assertThat([operation.mappingResult array], isNot(empty()));
    RKHuman *human = (RKHuman *)[[operation.mappingResult array] objectAtIndex:0];
    assertThat(human.objectID, is(equalTo(temporaryHuman.objectID)));
    assertThat(human.railsID, is(equalToInt(1)));
}

- (void)testShouldNotPersistTemporaryEntityToPersistentStoreOnError
{
    RKHuman *temporaryHuman = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:_objectManager.managedObjectStore.persistentStoreManagedObjectContext];
    temporaryHuman.name = @"My Name";
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [mapping addAttributeMappingsFromArray:@[@"name"]];
    
    RKManagedObjectRequestOperation *operation = [_objectManager appropriateObjectRequestOperationWithObject:temporaryHuman method:RKRequestMethodPOST path:@"/humans/fail" parameters:nil];
    [operation start];
    [operation waitUntilFinished];
    
    assertThatBool([temporaryHuman isNew], is(equalToBool(YES)));
}

- (void)testShouldNotDeleteACoreDataBackedTargetObjectOnErrorIfItWasAlreadySaved
{
    RKHuman *temporaryHuman = [[RKHuman alloc] initWithEntity:[NSEntityDescription entityForName:@"RKHuman" inManagedObjectContext:_objectManager.managedObjectStore.persistentStoreManagedObjectContext] insertIntoManagedObjectContext:_objectManager.managedObjectStore.persistentStoreManagedObjectContext];
    temporaryHuman.name = @"My Name";
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [mapping addAttributeMappingsFromArray:@[@"name"]];
    
    // Save it to suppress deletion
    [self.objectManager.managedObjectStore.persistentStoreManagedObjectContext save:nil];
    
    RKManagedObjectRequestOperation *operation = [self.objectManager appropriateObjectRequestOperationWithObject:temporaryHuman method:RKRequestMethodPOST path:@"/humans/fail" parameters:nil];
    [operation start];
    [operation waitUntilFinished];
    
    assertThat(temporaryHuman.managedObjectContext, is(equalTo(_objectManager.managedObjectStore.persistentStoreManagedObjectContext)));
}

- (void)testCancellationByExactMethodAndPath
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/object_manager/cancel" relativeToURL:self.objectManager.HTTPClient.baseURL]];
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:self.objectManager.responseDescriptors];
    [_objectManager enqueueObjectRequestOperation:operation];
    [_objectManager cancelAllObjectRequestOperationsWithMethod:RKRequestMethodGET matchingPathPattern:@"/object_manager/cancel"];
    assertThatBool([operation isCancelled], is(equalToBool(YES)));
}

- (void)testCancellationByPathMatch
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/object_manager/1234/cancel" relativeToURL:self.objectManager.HTTPClient.baseURL]];
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:self.objectManager.responseDescriptors];
    [_objectManager enqueueObjectRequestOperation:operation];
    [_objectManager cancelAllObjectRequestOperationsWithMethod:RKRequestMethodGET matchingPathPattern:@"/object_manager/:objectID/cancel"];
    assertThatBool([operation isCancelled], is(equalToBool(YES)));
}

- (void)testCancellationFailsForMismatchedMethod
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/object_manager/cancel" relativeToURL:self.objectManager.HTTPClient.baseURL]];
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:self.objectManager.responseDescriptors];
    [_objectManager enqueueObjectRequestOperation:operation];
    [_objectManager cancelAllObjectRequestOperationsWithMethod:RKRequestMethodPOST matchingPathPattern:@"/object_manager/cancel"];
    assertThatBool([operation isCancelled], is(equalToBool(NO)));
}

- (void)testCancellationFailsForMismatchedPath
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/object_manager/cancel" relativeToURL:self.objectManager.HTTPClient.baseURL]];
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:self.objectManager.responseDescriptors];
    [_objectManager enqueueObjectRequestOperation:operation];
    [_objectManager cancelAllObjectRequestOperationsWithMethod:RKRequestMethodGET matchingPathPattern:@"/wrong"];
    assertThatBool([operation isCancelled], is(equalToBool(NO)));
}

- (void)testShouldProperlyFireABatchOfOperations
{
    RKHuman *temporaryHuman = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:_objectManager.managedObjectStore.persistentStoreManagedObjectContext];
    temporaryHuman.name = @"My Name";

    RKManagedObjectRequestOperation *successfulGETOperation = [_objectManager appropriateObjectRequestOperationWithObject:temporaryHuman method:RKRequestMethodGET path:nil parameters:nil];
    RKManagedObjectRequestOperation *successfulPOSTOperation = [_objectManager appropriateObjectRequestOperationWithObject:temporaryHuman method:RKRequestMethodPOST path:nil parameters:nil];
    RKManagedObjectRequestOperation *failedPOSTOperation = [_objectManager appropriateObjectRequestOperationWithObject:temporaryHuman method:RKRequestMethodPOST path:@"/humans/fail" parameters:nil];

    __block NSUInteger progressCallbackCount = 0;
    __block NSUInteger completionBlockOperationCount = 0;
    [_objectManager enqueueBatchOfObjectRequestOperations:@[successfulGETOperation, successfulPOSTOperation, failedPOSTOperation] progress:^(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations) {
        progressCallbackCount++;
    } completion:^(NSArray *operations) {
        completionBlockOperationCount = operations.count;
    }];
    assertThat(_objectManager.operationQueue, is(notNilValue()));
    [_objectManager.operationQueue waitUntilAllOperationsAreFinished];

    // Spin the run loop to allow completion blocks to fire after operations have completed
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];

    assertThatInteger(progressCallbackCount, is(equalToInteger(3)));
    assertThatInteger(completionBlockOperationCount, is(equalToInteger(3)));
}

- (void)testShouldProperlyFireABatchOfOperationsFromRoute
{
    RKHuman *dan = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:_objectManager.managedObjectStore.persistentStoreManagedObjectContext];
    dan.name = @"Dan";

    RKHuman *blake = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:_objectManager.managedObjectStore.persistentStoreManagedObjectContext];
    blake.name = @"Blake";

    RKHuman *jeff = [NSEntityDescription insertNewObjectForEntityForName:@"RKHuman" inManagedObjectContext:_objectManager.managedObjectStore.persistentStoreManagedObjectContext];
    jeff.name = @"Jeff";

    __block NSUInteger progressCallbackCount = 0;
    __block NSUInteger completionBlockOperationCount = 0;
    [_objectManager enqueueBatchOfObjectRequestOperationsWithRoute:self.humanPOSTRoute objects:@[dan, blake, jeff] progress:^(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations) {
        progressCallbackCount++;
    } completion:^(NSArray *operations) {
        completionBlockOperationCount = operations.count;
    }];
    assertThat(_objectManager.operationQueue, is(notNilValue()));
    [_objectManager.operationQueue waitUntilAllOperationsAreFinished];

    // Spin the run loop to allow completion blocks to fire after operations have completed
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];

    assertThatInteger(progressCallbackCount, is(equalToInteger(3)));
    assertThatInteger(completionBlockOperationCount, is(equalToInteger(3)));
}

// TODO: Move to Core Data specific spec file...
//- (void)testShouldLoadAHuman
//{
//
//    __block RKObjectRequestOperation *requestOperation = nil;
//    [self.objectManager getObjectsAtPath:@"/JSON/humans/1.json" parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
//        requestOperation = operation;
//    } failure:nil];
//    [self.objectManager.operationQueue waitUntilAllOperationsAreFinished];
//
//    assertThat(loader.error, is(nilValue()));
//    assertThat(loader.objects, isNot(empty()));
//    RKHuman *blake = (RKHuman *)[loader.objects objectAtIndex:0];
//    assertThat(blake.name, is(equalTo(@"Blake Watters")));
//}
//
//- (void)testShouldLoadAllHumans
//{
//    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
//    [_objectManager loadObjectsAtResourcePath:@"/JSON/humans/all.json" delegate:loader];
//    [loader waitForResponse];
//    NSArray *humans = (NSArray *)loader.objects;
//    assertThatUnsignedInteger([humans count], is(equalToInt(2)));
//    assertThat([humans objectAtIndex:0], is(instanceOf([RKHuman class])));
//}
//
//- (void)testShouldHandleConnectionFailures
//{
//    NSString *localBaseURL = [NSString stringWithFormat:@"http://127.0.0.1:3001"];
//    RKObjectManager *modelManager = [RKObjectManager managerWithBaseURLString:localBaseURL];
//    modelManager.client.requestQueue.suspended = NO;
//    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
//    [modelManager loadObjectsAtResourcePath:@"/JSON/humans/1" delegate:loader];
//    [loader waitForResponse];
//    assertThatBool(loader.wasSuccessful, is(equalToBool(NO)));
//}
//
//- (void)testShouldPOSTAnObject
//{
//    RKObjectManager *manager = [RKTestFactory objectManager];
//    [manager.router.routeSet addRoute:[RKRoute routeWithClass:[RKObjectMapperTestModel class] pathPattern:@"/humans" method:RKRequestMethodPOST]];
//
//    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKObjectMapperTestModel class]];
//    mapping.rootKeyPath = @"human";
//    [mapping addAttributeMappingsFromArray:@[@"name", @"age"]];
//    [manager.mappingProvider setMapping:mapping forKeyPath:@"human"];
//    [manager.mappingProvider setSerializationMapping:mapping forClass:[RKObjectMapperTestModel class]];
//
//    RKObjectMapperTestModel *human = [[RKObjectMapperTestModel new] autorelease];
//    human.name = @"Blake Watters";
//    human.age = [NSNumber numberWithInt:28];
//
//    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
//    [manager postObject:human delegate:loader];
//    [loader waitForResponse];
//
//    // NOTE: The /humans endpoint returns a canned response, we are testing the plumbing
//    // of the object manager here.
//    assertThat(human.name, is(equalTo(@"My Name")));
//}
//
//- (void)testShouldNotSetAContentBodyOnAGET
//{
//    RKObjectManager *objectManager = [RKTestFactory objectManager];
//    [objectManager.router.routeSet addRoute:[RKRoute routeWithClass:[RKObjectMapperTestModel class] pathPattern:@"/humans/1" method:RKRequestMethodAny]];
//
//    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKObjectMapperTestModel class]];
//    [mapping addAttributeMappingsFromArray:@[@"name", @"age"]];
//    [objectManager.mappingProvider registerMapping:mapping withRootKeyPath:@"human"];
//
//    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
//    RKObjectMapperTestModel *human = [[RKObjectMapperTestModel new] autorelease];
//    human.name = @"Blake Watters";
//    human.age = [NSNumber numberWithInt:28];
//    __block RKObjectLoader *objectLoader = nil;
//    [objectManager getObject:human usingBlock:^(RKObjectLoader *loader) {
//        loader.delegate = responseLoader;
//        objectLoader = loader;
//    }];
//    [responseLoader waitForResponse];
//    RKLogCritical(@"%@", [objectLoader.URLRequest allHTTPHeaderFields]);
//    assertThat([objectLoader.URLRequest valueForHTTPHeaderField:@"Content-Length"], is(equalTo(@"0")));
//}
//
//- (void)testShouldNotSetAContentBodyOnADELETE
//{
//    RKObjectManager *objectManager = [RKTestFactory objectManager];
//    [objectManager.router.routeSet addRoute:[RKRoute routeWithClass:[RKObjectMapperTestModel class] pathPattern:@"/humans/1" method:RKRequestMethodAny]];
//
//    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKObjectMapperTestModel class]];
//    [mapping addAttributeMappingsFromArray:@[@"name", @"age"]];
//    [objectManager.mappingProvider registerMapping:mapping withRootKeyPath:@"human"];
//
//    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
//    RKObjectMapperTestModel *human = [[RKObjectMapperTestModel new] autorelease];
//    human.name = @"Blake Watters";
//    human.age = [NSNumber numberWithInt:28];
//    __block RKObjectLoader *objectLoader = nil;
//    [objectManager deleteObject:human usingBlock:^(RKObjectLoader *loader) {
//        loader.delegate = responseLoader;
//        objectLoader = loader;
//    }];
//    [responseLoader waitForResponse];
//    RKLogCritical(@"%@", [objectLoader.URLRequest allHTTPHeaderFields]);
//    assertThat([objectLoader.URLRequest valueForHTTPHeaderField:@"Content-Length"], is(equalTo(@"0")));
//}
//
//#pragma mark - Block Helpers
//
//- (void)testShouldLetYouLoadObjectsWithABlock
//{
//    RKObjectManager *objectManager = [RKTestFactory objectManager];
//    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKObjectMapperTestModel class]];
//    [mapping addAttributeMappingsFromArray:@[@"name", @"age"]];
//    [objectManager.mappingProvider registerMapping:mapping withRootKeyPath:@"human"];
//
//    RKTestResponseLoader *responseLoader = [[RKTestResponseLoader responseLoader] retain];
//    [objectManager loadObjectsAtResourcePath:@"/JSON/humans/1.json" usingBlock:^(RKObjectLoader *loader) {
//        loader.delegate = responseLoader;
//        loader.objectMapping = mapping;
//    }];
//    [responseLoader waitForResponse];
//    assertThatBool(responseLoader.wasSuccessful, is(equalToBool(YES)));
//    assertThat(responseLoader.objects, hasCountOf(1));
//}
//
//- (void)testShouldAllowYouToOverrideTheRoutedResourcePath
//{
//    RKObjectManager *objectManager = [RKTestFactory objectManager];
//    [objectManager.router.routeSet addRoute:[RKRoute routeWithClass:[RKObjectMapperTestModel class] pathPattern:@"/humans/2" method:RKRequestMethodAny]];
//    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKObjectMapperTestModel class]];
//    [mapping addAttributeMappingsFromArray:@[@"name", @"age"]];
//    [objectManager.mappingProvider registerMapping:mapping withRootKeyPath:@"human"];
//
//    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
//    RKObjectMapperTestModel *human = [[RKObjectMapperTestModel new] autorelease];
//    human.name = @"Blake Watters";
//    human.age = [NSNumber numberWithInt:28];
//    [objectManager deleteObject:human usingBlock:^(RKObjectLoader *loader) {
//        loader.delegate = responseLoader;
//        loader.resourcePath = @"/humans/1";
//    }];
//    responseLoader.timeout = 50;
//    [responseLoader waitForResponse];
//    assertThat(responseLoader.response.request.resourcePath, is(equalTo(@"/humans/1")));
//}
//
//- (void)testShouldAllowYouToUseObjectHelpersWithoutRouting
//{
//    RKObjectManager *objectManager = [RKTestFactory objectManager];
//    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKObjectMapperTestModel class]];
//    [mapping addAttributeMappingsFromArray:@[@"name", @"age"]];
//    [objectManager.mappingProvider registerMapping:mapping withRootKeyPath:@"human"];
//
//    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
//    RKObjectMapperTestModel *human = [[RKObjectMapperTestModel new] autorelease];
//    human.name = @"Blake Watters";
//    human.age = [NSNumber numberWithInt:28];
//    [objectManager sendObject:human toResourcePath:@"/humans/1" usingBlock:^(RKObjectLoader *loader) {
//        loader.method = RKRequestMethodDELETE;
//        loader.delegate = responseLoader;
//        loader.resourcePath = @"/humans/1";
//    }];
//    [responseLoader waitForResponse];
//    assertThat(responseLoader.response.request.resourcePath, is(equalTo(@"/humans/1")));
//}
//
//- (void)testShouldAllowYouToSkipTheMappingProvider
//{
//    RKObjectManager *objectManager = [RKTestFactory objectManager];
//    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKObjectMapperTestModel class]];
//    mapping.rootKeyPath = @"human";
//    [mapping addAttributeMappingsFromArray:@[@"name", @"age"]];
//
//    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
//    RKObjectMapperTestModel *human = [[RKObjectMapperTestModel new] autorelease];
//    human.name = @"Blake Watters";
//    human.age = [NSNumber numberWithInt:28];
//    [objectManager sendObject:human toResourcePath:@"/humans/1" usingBlock:^(RKObjectLoader *loader) {
//        loader.method = RKRequestMethodDELETE;
//        loader.delegate = responseLoader;
//        loader.objectMapping = mapping;
//    }];
//    [responseLoader waitForResponse];
//    assertThatBool(responseLoader.wasSuccessful, is(equalToBool(YES)));
//    assertThat(responseLoader.response.request.resourcePath, is(equalTo(@"/humans/1")));
//}
//
//- (void)testShouldLetYouOverloadTheParamsOnAnObjectLoaderRequest
//{
//    RKObjectManager *objectManager = [RKTestFactory objectManager];
//    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKObjectMapperTestModel class]];
//    mapping.rootKeyPath = @"human";
//    [mapping addAttributeMappingsFromArray:@[@"name", @"age"]];
//
//    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
//    RKObjectMapperTestModel *human = [[RKObjectMapperTestModel new] autorelease];
//    human.name = @"Blake Watters";
//    human.age = [NSNumber numberWithInt:28];
//    NSDictionary *myParams = [NSDictionary dictionaryWithObject:@"bar" forKey:@"foo"];
//    __block RKObjectLoader *objectLoader = nil;
//    [objectManager sendObject:human toResourcePath:@"/humans/1" usingBlock:^(RKObjectLoader *loader) {
//        loader.delegate = responseLoader;
//        loader.method = RKRequestMethodPOST;
//        loader.objectMapping = mapping;
//        loader.params = myParams;
//        objectLoader = loader;
//    }];
//    [responseLoader waitForResponse];
//    assertThat(objectLoader.params, is(equalTo(myParams)));
//}
//
//- (void)testInitializationOfObjectLoaderViaManagerConfiguresSerializationMIMEType
//{
//    RKObjectManager *objectManager = [RKTestFactory objectManager];
//    objectManager.serializationMIMEType = RKMIMETypeJSON;
//    RKObjectLoader *loader = [objectManager loaderWithResourcePath:@"/test"];
//    assertThat(loader.serializationMIMEType, isNot(nilValue()));
//    assertThat(loader.serializationMIMEType, is(equalTo(RKMIMETypeJSON)));
//}
//
//- (void)testInitializationOfRoutedPathViaSendObjectMethodUsingBlock
//{
//    RKObjectManager *objectManager = [RKTestFactory objectManager];
//    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKObjectMapperTestModel class]];
//    mapping.rootKeyPath = @"human";
//    [objectManager.mappingProvider registerObjectMapping:mapping withRootKeyPath:@"human"];
//    [objectManager.router.routeSet addRoute:[RKRoute routeWithClass:[RKObjectMapperTestModel class] pathPattern:@"/human/1" method:RKRequestMethodAny]];
//    objectManager.serializationMIMEType = RKMIMETypeJSON;
//    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
//
//    RKObjectMapperTestModel *object = [RKObjectMapperTestModel new];
//    [objectManager putObject:object usingBlock:^(RKObjectLoader *loader) {
//        loader.delegate = responseLoader;sss
//    }];
//    [responseLoader waitForResponse];
//}
//
//- (void)testThatInitializationOfObjectManagerInitializesNetworkStatusFromClient
//{
//    RKReachabilityObserver *observer = [[RKReachabilityObserver alloc] initWithHost:@"google.com"];
//    id mockObserver = [OCMockObject partialMockForObject:observer];
//    BOOL yes = YES;
//    [[[mockObserver stub] andReturnValue:OCMOCK_VALUE(yes)] isReachabilityDetermined];
//    [[[mockObserver stub] andReturnValue:OCMOCK_VALUE(yes)] isNetworkReachable];
//    RKClient *client = [RKTestFactory client];
//    client.reachabilityObserver = mockObserver;
//    RKObjectManager *manager = [[RKObjectManager alloc] init];
//    manager.client = client;
//    assertThatInteger(manager.networkStatus, is(equalToInteger(RKObjectManagerNetworkStatusOnline)));
//}
//
//- (void)testThatMutationOfUnderlyingClientReachabilityObserverUpdatesManager
//{
//    RKObjectManager *manager = [RKTestFactory objectManager];
//    RKReachabilityObserver *observer = [[RKReachabilityObserver alloc] initWithHost:@"google.com"];
//    assertThatInteger(manager.networkStatus, is(equalToInteger(RKObjectManagerNetworkStatusOnline)));
//    manager.client.reachabilityObserver = observer;
//    assertThatInteger(manager.networkStatus, is(equalToInteger(RKObjectManagerNetworkStatusUnknown)));
//
//
//- (void)testThatReplacementOfUnderlyingClientUpdatesManagerReachabilityObserver
//{
//    RKObjectManager *manager = [RKTestFactory objectManager];
//    RKReachabilityObserver *observer = [[RKReachabilityObserver alloc] initWithHost:@"google.com"];
//    RKClient *client = [RKTestFactory client];
//    client.reachabilityObserver = observer;
//    assertThatInteger(manager.networkStatus, is(equalToInteger(RKObjectManagerNetworkStatusOnline)));
//    manager.client = client;
//    assertThatInteger(manager.networkStatus, is(equalToInteger(RKObjectManagerNetworkStatusUnknown)));
//}

- (void)testAssociationAndExtractionOfBaseURL
{
    NSURL *baseURL = [NSURL URLWithString:@"http://domain.com/api/v1/"];
    NSURL *relativeURL = [NSURL URLWithString:@"itemtype" relativeToURL:baseURL];
    assertThat([relativeURL relativePath], is(equalTo(@"itemtype")));
    NSURLRequest *request = [NSURLRequest requestWithURL:relativeURL];
    RKAssociateBaseURLWithURL(baseURL, request.URL);
    
    NSURL *associatedBaseURL = RKBaseURLAssociatedWithURL(request.URL);
    assertThat(associatedBaseURL, is(notNilValue()));
    NSString *relativePathFromAssociation = [[request.URL absoluteString] substringFromIndex:[[associatedBaseURL absoluteString] length]];
    assertThat(relativePathFromAssociation, is(equalTo(@"itemtype")));
}

- (void)testBaseURLandRelativePathRoundTripping
{
    NSURL *baseURL = [NSURL URLWithString:@"http://domain.com/api/v1/"];
    NSURL *relativeURL = [NSURL URLWithString:@"itemtype" relativeToURL:baseURL];
    assertThat([relativeURL baseURL], is(equalTo(baseURL)));
    assertThat([relativeURL relativePath], is(equalTo(@"itemtype")));
    assertThat([relativeURL relativeString], is(equalTo(@"itemtype")));
    
    // NSURLRequest clobbers the URL
    NSURLRequest *request = [NSURLRequest requestWithURL:relativeURL];
    assertThat([request.URL baseURL], isNot(equalTo(baseURL)));
    assertThat([request.URL relativePath], isNot(equalTo(@"itemtype")));
    assertThat([request.URL relativeString], isNot(equalTo(@"itemtype")));
    
    // Verify use of associated object support to workaround URL issues. We associate with the request URL after init, which is retained by the NSHTTPURLResponse
    RKAssociateBaseURLWithURL(baseURL, request.URL);
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:request.URL statusCode:200 HTTPVersion:@"HTTP/1.1" headerFields:nil];
    assertThat([response.URL baseURL], is(equalTo(nil)));
    NSURL *associatedBaseURL = RKBaseURLAssociatedWithURL(response.URL);
    assertThat(associatedBaseURL, is(equalTo(baseURL)));
    
    // These are wrong -- we want the relative 'itemtype' path
    assertThat([response.URL relativePath], is(equalTo(@"/api/v1/itemtype")));
    assertThat([response.URL relativeString], is(equalTo(@"http://domain.com/api/v1/itemtype")));
    
    // Build our own relative path and verify it works
    NSString *relativePathFromAssociation = [[request.URL absoluteString] substringFromIndex:[[associatedBaseURL absoluteString] length]];
    assertThat(relativePathFromAssociation, is(equalTo(@"itemtype")));
}

@end
