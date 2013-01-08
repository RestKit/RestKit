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
#import "RKTestUser.h"
#import "RKObjectMapperTestModel.h"
#import "RKDynamicMapping.h"
#import "RKTestAddress.h"

@interface RKSubclassedTestModel : RKObjectMapperTestModel
@end

@implementation RKSubclassedTestModel
@end

@interface RKTestAFHTTPClient : AFHTTPClient
@end

@implementation RKTestAFHTTPClient

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters
{
    NSMutableURLRequest *request = [super requestWithMethod:method path:path parameters:parameters];
    [request setAllHTTPHeaderFields:@{@"test": @"value", @"Accept": @"text/html"}];
    return request;
}

@end

@interface RKTestHTTPRequestOperation : RKHTTPRequestOperation
@end
@implementation RKTestHTTPRequestOperation : RKHTTPRequestOperation
@end

@interface RKObjectManagerTest : RKTestCase

@property (nonatomic, strong) RKObjectManager *objectManager;
@property (nonatomic, strong) RKRoute *humanGETRoute;
@property (nonatomic, strong) RKRoute *humanPOSTRoute;
@property (nonatomic, strong) RKRoute *humanDELETERoute;
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
    
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:_objectManager.managedObjectStore];
    [humanMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"]];
    [humanMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"nick-name" toKeyPath:@"nickName"]];
    [humanMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"birthday" toKeyPath:@"birthday"]];
    [humanMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"sex" toKeyPath:@"sex"]];
    [humanMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"age" toKeyPath:@"age"]];
    [humanMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"created-at" toKeyPath:@"createdAt"]];
    [humanMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"updated-at" toKeyPath:@"updatedAt"]];
    [humanMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"railsID"]];
    
    RKEntityMapping *catMapping = [RKEntityMapping mappingForEntityForName:@"Cat" inManagedObjectStore:_objectManager.managedObjectStore];
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
    
    RKObjectMapping *humanSerialization = [RKObjectMapping requestMapping];
    [humanSerialization addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"]];
    [self.objectManager addRequestDescriptor:[RKRequestDescriptor requestDescriptorWithMapping:humanSerialization objectClass:[RKHuman class] rootKeyPath:@"human"]];

    self.humanPOSTRoute = [RKRoute routeWithClass:[RKHuman class] pathPattern:@"/humans" method:RKRequestMethodPOST];
    self.humanGETRoute = [RKRoute routeWithClass:[RKHuman class] pathPattern:@"/humans/:railsID" method:RKRequestMethodGET];
    self.humanDELETERoute = [RKRoute routeWithClass:[RKHuman class] pathPattern:@"/humans/:railsID" method:RKRequestMethodDELETE];
    self.humanCatsRoute = [RKRoute routeWithRelationshipName:@"cats" objectClass:[RKHuman class] pathPattern:@"/humans/:railsID/cats" method:RKRequestMethodGET];
    self.humansCollectionRoute = [RKRoute routeWithName:@"humans" pathPattern:@"/humans" method:RKRequestMethodGET];

    [self.objectManager.router.routeSet addRoute:self.humanPOSTRoute];
    [self.objectManager.router.routeSet addRoute:self.humanGETRoute];
    [self.objectManager.router.routeSet addRoute:self.humanDELETERoute];
    [self.objectManager.router.routeSet addRoute:self.humanCatsRoute];
    [self.objectManager.router.routeSet addRoute:self.humansCollectionRoute];
}

- (void)tearDown
{
    [RKTestFactory tearDown];
}

- (void)testInitializationWithBaseURLSetsDefaultAcceptHeaderValueToJSON
{
    RKObjectManager *manager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:@"http://restkit.org"]];
    expect([manager defaultHeaders][@"Accept"]).to.equal(RKMIMETypeJSON);
}

- (void)testInitializationWithBaseURLSetsRequestSerializationMIMETypeToFormURLEncoded
{
    RKObjectManager *manager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:@"http://restkit.org"]];
    expect(manager.requestSerializationMIMEType).to.equal(RKMIMETypeFormURLEncoded);
}

- (void)testInitializationWithAFHTTPClientSetsNilAcceptHeaderValue
{
    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:@"http://restkit.org"]];
    [client setDefaultHeader:@"Accept" value:@"this/that"];
    RKObjectManager *manager = [[RKObjectManager alloc] initWithHTTPClient:client];
    expect([manager defaultHeaders][@"Accept"]).to.equal(@"this/that");
}

- (void)testDefersToAFHTTPClientParameterEncodingWhenInitializedWithAFHTTPClient
{
    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:@"http://restkit.org"]];
    client.parameterEncoding = AFJSONParameterEncoding;
    RKObjectManager *manager = [[RKObjectManager alloc] initWithHTTPClient:client];
    expect([manager requestSerializationMIMEType]).to.equal(RKMIMETypeJSON);
}

- (void)testDefaultsToFormURLEncodingForUnsupportedParameterEncodings
{
    AFHTTPClient *client = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:@"http://restkit.org"]];
    client.parameterEncoding = AFPropertyListParameterEncoding;
    RKObjectManager *manager = [[RKObjectManager alloc] initWithHTTPClient:client];
    expect([manager requestSerializationMIMEType]).to.equal(RKMIMETypeFormURLEncoded);
}

// TODO: Move to Core Data specific spec file...
- (void)testShouldUpdateACoreDataBackedTargetObject
{
    NSManagedObjectContext *managedObjectContext = [[RKTestFactory managedObjectStore] persistentStoreManagedObjectContext];
    RKHuman *temporaryHuman = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectContext withProperties:nil];
    temporaryHuman.name = @"My Name";
    
    RKManagedObjectRequestOperation *operation = [_objectManager appropriateObjectRequestOperationWithObject:temporaryHuman method:RKRequestMethodPOST path:nil parameters:nil];
    [operation start];
    [operation waitUntilFinished];
    
    expect(operation.mappingResult).notTo.beNil();
    expect([operation.mappingResult array]).notTo.beEmpty();
    RKHuman *human = (RKHuman *)[[operation.mappingResult array] objectAtIndex:0];
    expect(human.objectID).to.equal(temporaryHuman.objectID);
    expect(human.railsID).to.equal(1);
}

- (void)testShouldNotPersistTemporaryEntityToPersistentStoreOnError
{
    NSManagedObjectContext *managedObjectContext = [[RKTestFactory managedObjectStore] persistentStoreManagedObjectContext];
    RKHuman *temporaryHuman = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectContext withProperties:nil];
    temporaryHuman.name = @"My Name";
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [mapping addAttributeMappingsFromArray:@[@"name"]];
    
    RKManagedObjectRequestOperation *operation = [_objectManager appropriateObjectRequestOperationWithObject:temporaryHuman method:RKRequestMethodPOST path:@"/humans/fail" parameters:nil];
    [operation start];
    [operation waitUntilFinished];
    
    expect([temporaryHuman isNew]).to.equal(YES);
}

- (void)testThatFailedObjectRequestOperationDoesNotSaveObjectToPersistentStore
{
    NSManagedObjectContext *managedObjectContext = [[RKTestFactory managedObjectStore] persistentStoreManagedObjectContext];
    RKHuman *temporaryHuman = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectContext withProperties:nil];    
    temporaryHuman.name = @"My Name";
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [mapping addAttributeMappingsFromArray:@[@"name"]];
    
    expect([temporaryHuman isNew]).to.equal(YES);
    
    RKManagedObjectRequestOperation *operation = [self.objectManager appropriateObjectRequestOperationWithObject:temporaryHuman method:RKRequestMethodPOST path:@"/humans/fail" parameters:nil];
    [operation start];
    [operation waitUntilFinished];
    
    expect([temporaryHuman isNew]).to.equal(YES);
}

- (void)testShouldDeleteACoreDataBackedTargetObjectOnSuccessfulDeleteReturning200
{
    NSManagedObjectContext *managedObjectContext = [[RKTestFactory managedObjectStore] persistentStoreManagedObjectContext];
    RKHuman *temporaryHuman = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectContext withProperties:nil];
    temporaryHuman.name = @"My Name";
    temporaryHuman.railsID = @1;
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [mapping addAttributeMappingsFromArray:@[@"name"]];

    // Save it to ensure the object is persisted before we delete it
    [self.objectManager.managedObjectStore.persistentStoreManagedObjectContext save:nil];

    RKManagedObjectRequestOperation *operation = [self.objectManager appropriateObjectRequestOperationWithObject:temporaryHuman method:RKRequestMethodDELETE path:nil parameters:nil];
    [operation start];
    [operation waitUntilFinished];

    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    NSArray *humans = [_objectManager.managedObjectStore.persistentStoreManagedObjectContext executeFetchRequest:fetchRequest error:&error];
    expect(error).to.beNil();
    expect(humans).to.haveCountOf(0);
}

- (void)testShouldDeleteACoreDataBackedTargetObjectOnSuccessfulDeleteReturning204
{
    NSManagedObjectContext *managedObjectContext = [[RKTestFactory managedObjectStore] persistentStoreManagedObjectContext];
    RKHuman *temporaryHuman = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectContext withProperties:nil];
    temporaryHuman.name = @"My Name";
    temporaryHuman.railsID = @204;
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [mapping addAttributeMappingsFromArray:@[@"name"]];

    // Save it to ensure the object is persisted before we delete it
    [self.objectManager.managedObjectStore.persistentStoreManagedObjectContext save:nil];

    RKManagedObjectRequestOperation *operation = [self.objectManager appropriateObjectRequestOperationWithObject:temporaryHuman method:RKRequestMethodDELETE path:nil parameters:nil];
    [operation start];
    [operation waitUntilFinished];

    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    NSArray *humans = [_objectManager.managedObjectStore.persistentStoreManagedObjectContext executeFetchRequest:fetchRequest error:&error];
    expect(error).to.beNil();
    expect(humans).to.haveCountOf(0);
}

- (void)testCancellationByExactMethodAndPath
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/object_manager/cancel" relativeToURL:self.objectManager.HTTPClient.baseURL]];
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:self.objectManager.responseDescriptors];
    [_objectManager enqueueObjectRequestOperation:operation];
    [_objectManager cancelAllObjectRequestOperationsWithMethod:RKRequestMethodGET matchingPathPattern:@"/object_manager/cancel"];
    expect([operation isCancelled]).to.equal(YES);
}

- (void)testCancellationByPathMatch
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/object_manager/1234/cancel" relativeToURL:self.objectManager.HTTPClient.baseURL]];
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:self.objectManager.responseDescriptors];
    [_objectManager enqueueObjectRequestOperation:operation];
    [_objectManager cancelAllObjectRequestOperationsWithMethod:RKRequestMethodGET matchingPathPattern:@"/object_manager/:objectID/cancel"];
    expect([operation isCancelled]).to.equal(YES);
}

- (void)testCancellationFailsForMismatchedMethod
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/object_manager/cancel" relativeToURL:self.objectManager.HTTPClient.baseURL]];
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:self.objectManager.responseDescriptors];
    [_objectManager enqueueObjectRequestOperation:operation];
    [_objectManager cancelAllObjectRequestOperationsWithMethod:RKRequestMethodPOST matchingPathPattern:@"/object_manager/cancel"];
    expect([operation isCancelled]).to.equal(NO);
}

- (void)testCancellationFailsForMismatchedPath
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/object_manager/cancel" relativeToURL:self.objectManager.HTTPClient.baseURL]];
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:self.objectManager.responseDescriptors];
    [_objectManager enqueueObjectRequestOperation:operation];
    [_objectManager cancelAllObjectRequestOperationsWithMethod:RKRequestMethodGET matchingPathPattern:@"/wrong"];
    expect([operation isCancelled]).to.equal(NO);
}

- (void)testCancellationByPathMatchForBaseURLWithPath
{
    self.objectManager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:@"http://localhost:4567/object_manager/"]];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://localhost:4567/object_manager/1234/cancel"]];
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:self.objectManager.responseDescriptors];
    [_objectManager enqueueObjectRequestOperation:operation];
    [_objectManager cancelAllObjectRequestOperationsWithMethod:RKRequestMethodGET matchingPathPattern:@":objectID/cancel"];
    expect([operation isCancelled]).to.equal(YES);
}

- (void)testShouldProperlyFireABatchOfOperations
{
    NSManagedObjectContext *managedObjectContext = [[RKTestFactory managedObjectStore] persistentStoreManagedObjectContext];
    RKHuman *temporaryHuman = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectContext withProperties:nil];
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
    expect(_objectManager.operationQueue).notTo.beNil();
    [_objectManager.operationQueue waitUntilAllOperationsAreFinished];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        expect(progressCallbackCount).to.equal(3);
        expect(completionBlockOperationCount).to.equal(3);
    });
}

- (void)testShouldProperlyFireABatchOfOperationsFromRoute
{
    NSManagedObjectContext *managedObjectContext = [[RKTestFactory managedObjectStore] persistentStoreManagedObjectContext];
    RKHuman *dan = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectContext withProperties:nil];
    dan.name = @"Dan";

    RKHuman *blake = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectContext withProperties:nil];
    blake.name = @"Blake";

    RKHuman *jeff = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectContext withProperties:nil];
    jeff.name = @"Jeff";

    __block NSUInteger progressCallbackCount = 0;
    __block NSUInteger completionBlockOperationCount = 0;
    [_objectManager enqueueBatchOfObjectRequestOperationsWithRoute:self.humanPOSTRoute objects:@[dan, blake, jeff] progress:^(NSUInteger numberOfFinishedOperations, NSUInteger totalNumberOfOperations) {
        progressCallbackCount++;
    } completion:^(NSArray *operations) {
        completionBlockOperationCount = operations.count;
    }];
    expect(_objectManager.operationQueue).notTo.beNil();
    [_objectManager.operationQueue waitUntilAllOperationsAreFinished];

    dispatch_async(dispatch_get_main_queue(), ^{
        expect(progressCallbackCount).to.equal(3);
        expect(completionBlockOperationCount).to.equal(3);
    });
}

- (void)testThatObjectParametersAreNotSentDuringGetObject
{
    RKHuman *temporaryHuman = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:nil withProperties:nil];
    temporaryHuman.name = @"My Name";
    temporaryHuman.railsID = @204;
    RKManagedObjectRequestOperation *operation = [_objectManager appropriateObjectRequestOperationWithObject:temporaryHuman method:RKRequestMethodGET path:nil parameters:@{@"this": @"that"}];
    expect([operation.HTTPRequestOperation.request.URL absoluteString]).to.equal(@"http://127.0.0.1:4567/humans/204?this=that");
}

- (void)testThatObjectParametersAreNotSentDuringDeleteObject
{
    RKHuman *temporaryHuman = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:nil withProperties:nil];
    temporaryHuman.name = @"My Name";
    temporaryHuman.railsID = @204;
    RKManagedObjectRequestOperation *operation = [_objectManager appropriateObjectRequestOperationWithObject:temporaryHuman method:RKRequestMethodDELETE path:nil parameters:@{@"this": @"that"}];
    expect([operation.HTTPRequestOperation.request.URL absoluteString]).to.equal(@"http://127.0.0.1:4567/humans/204?this=that");
}

- (void)testInitializationOfObjectRequestOperationProducesCorrectURLRequest
{
    RKHuman *temporaryHuman = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:nil withProperties:nil];
    NSURLRequest *request = [_objectManager requestWithObject:temporaryHuman method:RKRequestMethodPATCH path:@"/the/path" parameters:@{@"key": @"value"}];
    expect([request.URL absoluteString]).to.equal(@"http://127.0.0.1:4567/the/path");
    expect(request.HTTPMethod).to.equal(@"PATCH");
    expect(request.HTTPBody).notTo.beNil();
    NSString *string = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
    expect(string).to.equal(@"key=value");
}

- (void)testAFHTTPClientCanModifyRequestsBuiltByObjectManager
{
    RKTestAFHTTPClient *testClient = [[RKTestAFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:@"http://test.com"]];
    RKObjectManager *manager = [[RKObjectManager alloc] initWithHTTPClient:testClient];
    RKHuman *temporaryHuman = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:nil withProperties:nil];
    NSURLRequest *request = [manager requestWithObject:temporaryHuman method:RKRequestMethodPATCH path:@"/the/path" parameters:@{@"key": @"value"}];
    
    expect([request.URL absoluteString]).to.equal(@"http://test.com/the/path");
    expect(request.HTTPMethod).to.equal(@"PATCH");
    expect([request allHTTPHeaderFields][@"test"]).to.equal(@"value");
    expect([request allHTTPHeaderFields][@"Accept"]).to.equal(@"text/html");
}

- (void)testRegistrationOfHTTPRequestOperationClass
{
    RKObjectManager *manager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:@"http://restkit.org"]];
    [manager setHTTPOperationClass:[RKTestHTTPRequestOperation class]];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/test" relativeToURL:manager.baseURL]];
    RKObjectRequestOperation *operation = [manager objectRequestOperationWithRequest:request success:nil failure:nil];
    expect(operation.HTTPRequestOperation).to.beKindOf([RKTestHTTPRequestOperation class]);
}

- (void)testSettingNilHTTPRequestOperationClassRestoresDefaultHTTPOperationClass
{
    RKObjectManager *manager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:@"http://restkit.org"]];
    [manager setHTTPOperationClass:[RKTestHTTPRequestOperation class]];
    [manager setHTTPOperationClass:nil];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/test" relativeToURL:manager.baseURL]];
    RKObjectRequestOperation *operation = [manager objectRequestOperationWithRequest:request success:nil failure:nil];
    expect(operation.HTTPRequestOperation).to.beKindOf([RKHTTPRequestOperation class]);
}

- (void)testThatManagedObjectRequestOperationsDefaultToSavingToPersistentStore
{
    RKObjectManager *manager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:@"http://restkit.org"]];
    NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/whatever" relativeToURL:manager.baseURL]];
    RKManagedObjectRequestOperation *operation = [manager managedObjectRequestOperationWithRequest:request managedObjectContext:managedObjectContext success:nil failure:nil];
    expect(operation.savesToPersistentStore).to.equal(YES);
}

- (void)testShouldLoadAHuman
{
    __block RKObjectRequestOperation *requestOperation = nil;
    [self.objectManager getObjectsAtPath:@"/JSON/humans/1.json" parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        requestOperation = operation;
    } failure:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        expect(requestOperation.error).to.beNil();
        expect([requestOperation.mappingResult array]).notTo.beEmpty();
        RKHuman *blake = (RKHuman *)[requestOperation.mappingResult array][0];
        expect(blake.name).to.equal(@"Blake Watters");
    });
}

- (void)testShouldLoadAllHumans
{
    __block RKObjectRequestOperation *requestOperation = nil;
    [_objectManager getObjectsAtPath:@"/JSON/humans/all.json" parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        requestOperation = operation;
    } failure:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray *humans = [requestOperation.mappingResult array];
        expect(humans).to.haveCountOf(2);
        expect(humans[0]).to.beInstanceOf([RKHuman class]);
    });
}

- (void)testThatAttemptingToAddARequestDescriptorThatOverlapsAnExistingEntryGeneratesAnError
{
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    RKRequestDescriptor *requestDesriptor1 = [RKRequestDescriptor requestDescriptorWithMapping:mapping objectClass:[RKCat class] rootKeyPath:nil];
    RKRequestDescriptor *requestDesriptor2 = [RKRequestDescriptor requestDescriptorWithMapping:mapping objectClass:[RKCat class] rootKeyPath:@"cat"];
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    [objectManager addRequestDescriptor:requestDesriptor1];
    
    NSException *caughtException = nil;
    @try {
        [objectManager addRequestDescriptor:requestDesriptor2];
    }
    @catch (NSException *exception) {
        caughtException = exception;
    }
    @finally {
        expect(caughtException).notTo.beNil();
    }
}

- (void)testThatRegisteringARequestDescriptorForASubclassSecondWillMatchAppropriately
{
    RKObjectMapping *mapping1 = [RKObjectMapping requestMapping];
    [mapping1 addAttributeMappingsFromArray:@[ @"name" ]];
    RKObjectMapping *mapping2 = [RKObjectMapping requestMapping];
    [mapping2 addAttributeMappingsFromArray:@[ @"age" ]];
    
    RKRequestDescriptor *requestDesriptor1 = [RKRequestDescriptor requestDescriptorWithMapping:mapping1 objectClass:[RKObjectMapperTestModel class] rootKeyPath:nil];
    RKRequestDescriptor *requestDesriptor2 = [RKRequestDescriptor requestDescriptorWithMapping:mapping2 objectClass:[RKSubclassedTestModel class] rootKeyPath:@"subclassed"];
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    objectManager.requestSerializationMIMEType = RKMIMETypeJSON;
    [objectManager addRequestDescriptor:requestDesriptor1];
    [objectManager addRequestDescriptor:requestDesriptor2];
    
    RKSubclassedTestModel *model = [RKSubclassedTestModel new];
    model.name = @"Blake";
    model.age = @30;
    NSURLRequest *request = [objectManager requestWithObject:model method:RKRequestMethodPOST path:@"/path" parameters:nil];
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:request.HTTPBody options:0 error:nil];
    expect(dictionary).to.equal(@{ @"subclassed": @{ @"age": @(30) } });
}

- (void)testThatResponseDescriptorWithUnmanagedMappingTriggersCreationOfObjectRequestOperation
{
    RKObjectMapping *vanillaMapping = [RKObjectMapping requestMapping];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:vanillaMapping pathPattern:nil keyPath:nil statusCodes:nil];
    RKObjectManager *manager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:@"http://restkit.org"]];
    manager.managedObjectStore = [RKTestFactory managedObjectStore];
    [manager addResponseDescriptor:responseDescriptor];
    RKObjectRequestOperation *objectRequestOperation = [manager appropriateObjectRequestOperationWithObject:nil method:RKRequestMethodGET path:@"/something" parameters:nil];
    expect(objectRequestOperation).to.beInstanceOf([RKObjectRequestOperation class]);
}

- (void)testThatResponseDescriptorWithDynamicMappingContainingEntityMappingsTriggersCreationOfManagedObjectRequestOperation
{
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:_objectManager.managedObjectStore];
    RKDynamicMapping *dynamicMapping = [RKDynamicMapping new];
    [dynamicMapping addMatcher:[RKObjectMappingMatcher matcherWithKeyPath:@"whatever" expectedValue:@"whatever" objectMapping:humanMapping]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:dynamicMapping pathPattern:nil keyPath:nil statusCodes:nil];
    RKObjectManager *manager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:@"http://restkit.org"]];
    manager.managedObjectStore = [RKTestFactory managedObjectStore];
    [manager addResponseDescriptor:responseDescriptor];
    RKObjectRequestOperation *objectRequestOperation = [manager appropriateObjectRequestOperationWithObject:nil method:RKRequestMethodGET path:@"/something" parameters:nil];
    expect(objectRequestOperation).to.beInstanceOf([RKManagedObjectRequestOperation class]);
}

- (void)testThatResponseDescriptorWithDynamicMappingUsingABlockTriggersCreationOfManagedObjectRequestOperation
{
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:_objectManager.managedObjectStore];
    RKDynamicMapping *dynamicMapping = [RKDynamicMapping new];
    [dynamicMapping setObjectMappingForRepresentationBlock:^RKObjectMapping *(id representation) {
        return humanMapping;
    }];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:dynamicMapping pathPattern:nil keyPath:nil statusCodes:nil];
    RKObjectManager *manager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:@"http://restkit.org"]];
    manager.managedObjectStore = [RKTestFactory managedObjectStore];
    [manager addResponseDescriptor:responseDescriptor];
    RKObjectRequestOperation *objectRequestOperation = [manager appropriateObjectRequestOperationWithObject:nil method:RKRequestMethodGET path:@"/something" parameters:nil];
    expect(objectRequestOperation).to.beInstanceOf([RKManagedObjectRequestOperation class]);
}

- (void)testThatResponseDescriptorWithUnmanagedMappingContainingRelationshipMappingWithEntityMappingsTriggersCreationOfManagedObjectRequestOperation
{
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:_objectManager.managedObjectStore];
    RKObjectMapping *objectMapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [objectMapping addRelationshipMappingWithSourceKeyPath:@"relationship" mapping:humanMapping];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:objectMapping pathPattern:nil keyPath:nil statusCodes:nil];
    RKObjectManager *manager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:@"http://restkit.org"]];
    manager.managedObjectStore = [RKTestFactory managedObjectStore];
    [manager addResponseDescriptor:responseDescriptor];
    RKObjectRequestOperation *objectRequestOperation = [manager appropriateObjectRequestOperationWithObject:nil method:RKRequestMethodGET path:@"/something" parameters:nil];
    expect(objectRequestOperation).to.beInstanceOf([RKManagedObjectRequestOperation class]);
}

- (void)testThatResponseDescriptorWithUnmanagedMappingContainingRelationshipMappingWithEntityMappingsDeepWithinObjectGraphTriggersCreationOfManagedObjectRequestOperation
{
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:_objectManager.managedObjectStore];
    RKObjectMapping *objectMapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [objectMapping addRelationshipMappingWithSourceKeyPath:@"relationship" mapping:humanMapping];
    RKObjectMapping *objectMapping2 = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [objectMapping2 addRelationshipMappingWithSourceKeyPath:@"relationship" mapping:objectMapping];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:objectMapping2 pathPattern:nil keyPath:nil statusCodes:nil];
    RKObjectManager *manager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:@"http://restkit.org"]];
    manager.managedObjectStore = [RKTestFactory managedObjectStore];
    [manager addResponseDescriptor:responseDescriptor];
    RKObjectRequestOperation *objectRequestOperation = [manager appropriateObjectRequestOperationWithObject:nil method:RKRequestMethodGET path:@"/something" parameters:nil];
    expect(objectRequestOperation).to.beInstanceOf([RKManagedObjectRequestOperation class]);
}

- (void)testChangingHTTPClient
{
    RKObjectManager *manager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:@"http://restkit.org"]];
    manager.HTTPClient = [AFHTTPClient clientWithBaseURL:[NSURL URLWithString:@"http://google.com/"]];
    expect([manager.baseURL absoluteString]).to.equal(@"http://google.com/");
}

- (void)testPostingOneObjectAndGettingResponseMatchingAnotherClass
{
    RKObjectManager *manager = [RKObjectManager managerWithBaseURL:[RKTestFactory baseURL]];
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [userMapping addAttributeMappingsFromDictionary:@{ @"fullname": @"name" }];
    RKObjectMapping *metaMapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [metaMapping addAttributeMappingsFromArray:@[ @"status", @"version" ]];
    RKResponseDescriptor *metaResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:metaMapping pathPattern:nil keyPath:@"meta" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    [manager addResponseDescriptorsFromArray:@[ metaResponseDescriptor ]];
    RKTestUser *user = [RKTestUser new];
    RKObjectRequestOperation *requestOperation = [manager appropriateObjectRequestOperationWithObject:user method:RKRequestMethodPOST path:@"/ComplexUser" parameters:nil];
    [requestOperation start];
    [requestOperation waitUntilFinished];
    
    expect(requestOperation.error).to.beNil();
    expect(requestOperation.mappingResult).notTo.beNil();
    expect([requestOperation.mappingResult array]).to.haveCountOf(1);
    NSDictionary *expectedObject = @{ @"status": @"ok", @"version": @"0.3" };
    expect([requestOperation.mappingResult firstObject]).to.equal(expectedObject);
}

- (void)testPostingOneObjectAndGettingResponseMatchingMultipleDescriptors
{
    RKObjectManager *manager = [RKObjectManager managerWithBaseURL:[RKTestFactory baseURL]];
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [userMapping addAttributeMappingsFromDictionary:@{ @"fullname": @"name" }];
    RKResponseDescriptor *userResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping pathPattern:nil keyPath:@"data.STUser" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    RKObjectMapping *metaMapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [metaMapping addAttributeMappingsFromArray:@[ @"status", @"version" ]];    
    RKResponseDescriptor *metaResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:metaMapping pathPattern:nil keyPath:@"meta" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    [manager addResponseDescriptorsFromArray:@[ userResponseDescriptor, metaResponseDescriptor ]];
    RKTestUser *user = [RKTestUser new];
    RKObjectRequestOperation *requestOperation = [manager appropriateObjectRequestOperationWithObject:user method:RKRequestMethodPOST path:@"/ComplexUser" parameters:nil];
    [requestOperation start];
    [requestOperation waitUntilFinished];
    
    expect(requestOperation.mappingResult).notTo.beNil();
    expect([requestOperation.mappingResult array]).to.haveCountOf(2);
}

- (void)testThatAppropriateObjectRequestOperationReturnsManagedObjectRequestOperationForManagedObjectWithNoResponseDescriptors
{
    RKObjectManager *manager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:@"http://restkit.org"]];
    manager.managedObjectStore = [RKTestFactory managedObjectStore];
    NSManagedObject *managedObject = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:manager.managedObjectStore.mainQueueManagedObjectContext];
    RKObjectRequestOperation *objectRequestOperation = [manager appropriateObjectRequestOperationWithObject:managedObject method:RKRequestMethodPOST path:@"/something" parameters:nil];
    expect(objectRequestOperation).to.beInstanceOf([RKManagedObjectRequestOperation class]);
}

- (void)testCreatingAnObjectRequestWithoutARequestDescriptorButWithParametersSetsTheRequestBody
{
    RKTestUser *user = [RKTestUser new];
    user.name = @"Blake";
    user.emailAddress = @"blake@restkit.org";
    
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    objectManager.requestSerializationMIMEType = RKMIMETypeJSON;
    
    NSURLRequest *request = [objectManager requestWithObject:user method:RKRequestMethodPOST path:@"/path" parameters:@{ @"this": @"that" }];
    id body = [NSJSONSerialization JSONObjectWithData:request.HTTPBody options:0 error:nil];
    NSDictionary *expected = @{ @"this": @"that" };
    expect(body).to.equal(expected);
}

- (void)testPostingAnArrayOfObjectsWhereNoneHaveARootKeyPath
{
    RKObjectMapping *firstRequestMapping = [RKObjectMapping requestMapping];
    [firstRequestMapping addAttributeMappingsFromArray:@[ @"name", @"emailAddress" ]];
    RKObjectMapping *secondRequestMapping = [RKObjectMapping requestMapping];
    [secondRequestMapping addAttributeMappingsFromArray:@[ @"city", @"state" ]];

    RKRequestDescriptor *firstRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:firstRequestMapping objectClass:[RKTestUser class] rootKeyPath:nil];
    RKRequestDescriptor *secondRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:secondRequestMapping objectClass:[RKTestAddress class] rootKeyPath:nil];

    RKTestUser *user = [RKTestUser new];
    user.name = @"Blake";
    user.emailAddress = @"blake@restkit.org";

    RKTestAddress *address = [RKTestAddress new];
    address.city = @"New York City";
    address.state = @"New York";

    RKObjectManager *objectManager = [RKTestFactory objectManager];
    objectManager.requestSerializationMIMEType = RKMIMETypeJSON;
    [objectManager addRequestDescriptor:firstRequestDescriptor];
    [objectManager addRequestDescriptor:secondRequestDescriptor];

    NSArray *arrayOfObjects = @[ user, address ];
    NSURLRequest *request = [objectManager requestWithObject:arrayOfObjects method:RKRequestMethodPOST path:@"/path" parameters:nil];
    NSArray *array = [NSJSONSerialization JSONObjectWithData:request.HTTPBody options:0 error:nil];
    NSArray *expected = @[ @{ @"name": @"Blake", @"emailAddress": @"blake@restkit.org" }, @{ @"city": @"New York City", @"state": @"New York" } ];
    expect(array).to.equal(expected);
}

- (void)testPostingAnArrayOfObjectsWhereAllObjectsHaveAnOverlappingRootKeyPath
{
    RKObjectMapping *firstRequestMapping = [RKObjectMapping requestMapping];
    [firstRequestMapping addAttributeMappingsFromArray:@[ @"name", @"emailAddress" ]];
    RKObjectMapping *secondRequestMapping = [RKObjectMapping requestMapping];
    [secondRequestMapping addAttributeMappingsFromArray:@[ @"city", @"state" ]];

    RKRequestDescriptor *firstRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:firstRequestMapping objectClass:[RKTestUser class] rootKeyPath:@"whatever"];
    RKRequestDescriptor *secondRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:secondRequestMapping objectClass:[RKTestAddress class] rootKeyPath:@"whatever"];

    RKTestUser *user = [RKTestUser new];
    user.name = @"Blake";
    user.emailAddress = @"blake@restkit.org";

    RKTestAddress *address = [RKTestAddress new];
    address.city = @"New York City";
    address.state = @"New York";

    RKObjectManager *objectManager = [RKTestFactory objectManager];
    objectManager.requestSerializationMIMEType = RKMIMETypeJSON;
    [objectManager addRequestDescriptor:firstRequestDescriptor];
    [objectManager addRequestDescriptor:secondRequestDescriptor];

    NSArray *arrayOfObjects = @[ user, address ];
    NSURLRequest *request = [objectManager requestWithObject:arrayOfObjects method:RKRequestMethodPOST path:@"/path" parameters:nil];
    NSArray *array = [NSJSONSerialization JSONObjectWithData:request.HTTPBody options:0 error:nil];
    NSDictionary *expected = @{ @"whatever": @[ @{ @"name": @"Blake", @"emailAddress": @"blake@restkit.org" }, @{ @"city": @"New York City", @"state": @"New York" } ] };
    expect(array).to.equal(expected);
}

- (void)testPostingAnArrayOfObjectsWithMixedRootKeyPath
{
    RKObjectMapping *firstRequestMapping = [RKObjectMapping requestMapping];
    [firstRequestMapping addAttributeMappingsFromArray:@[ @"name", @"emailAddress" ]];
    RKObjectMapping *secondRequestMapping = [RKObjectMapping requestMapping];
    [secondRequestMapping addAttributeMappingsFromArray:@[ @"city", @"state" ]];

    RKRequestDescriptor *firstRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:firstRequestMapping objectClass:[RKTestUser class] rootKeyPath:@"this"];
    RKRequestDescriptor *secondRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:secondRequestMapping objectClass:[RKTestAddress class] rootKeyPath:@"that"];

    RKTestUser *user = [RKTestUser new];
    user.name = @"Blake";
    user.emailAddress = @"blake@restkit.org";

    RKTestAddress *address = [RKTestAddress new];
    address.city = @"New York City";
    address.state = @"New York";

    RKObjectManager *objectManager = [RKTestFactory objectManager];
    objectManager.requestSerializationMIMEType = RKMIMETypeJSON;
    [objectManager addRequestDescriptor:firstRequestDescriptor];
    [objectManager addRequestDescriptor:secondRequestDescriptor];

    NSArray *arrayOfObjects = @[ user, address ];
    NSURLRequest *request = [objectManager requestWithObject:arrayOfObjects method:RKRequestMethodPOST path:@"/path" parameters:nil];
    NSArray *array = [NSJSONSerialization JSONObjectWithData:request.HTTPBody options:0 error:nil];
    NSDictionary *expected = @{ @"this": @{ @"name": @"Blake", @"emailAddress": @"blake@restkit.org" }, @"that": @{ @"city": @"New York City", @"state": @"New York" } };
    expect(array).to.equal(expected);
}

- (void)testPostingAnArrayOfObjectsWithNonNilRootKeyPathAndExtraParameters
{
    RKObjectMapping *firstRequestMapping = [RKObjectMapping requestMapping];
    [firstRequestMapping addAttributeMappingsFromArray:@[ @"name", @"emailAddress" ]];
    RKObjectMapping *secondRequestMapping = [RKObjectMapping requestMapping];
    [secondRequestMapping addAttributeMappingsFromArray:@[ @"city", @"state" ]];

    RKRequestDescriptor *firstRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:firstRequestMapping objectClass:[RKTestUser class] rootKeyPath:@"this"];
    RKRequestDescriptor *secondRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:secondRequestMapping objectClass:[RKTestAddress class] rootKeyPath:@"that"];

    RKTestUser *user = [RKTestUser new];
    user.name = @"Blake";
    user.emailAddress = @"blake@restkit.org";

    RKTestAddress *address = [RKTestAddress new];
    address.city = @"New York City";
    address.state = @"New York";

    RKObjectManager *objectManager = [RKTestFactory objectManager];
    objectManager.requestSerializationMIMEType = RKMIMETypeJSON;
    [objectManager addRequestDescriptor:firstRequestDescriptor];
    [objectManager addRequestDescriptor:secondRequestDescriptor];

    NSArray *arrayOfObjects = @[ user, address ];
    NSURLRequest *request = [objectManager requestWithObject:arrayOfObjects method:RKRequestMethodPOST path:@"/path" parameters:@{ @"extra": @"info" }];
    NSArray *array = [NSJSONSerialization JSONObjectWithData:request.HTTPBody options:0 error:nil];
    NSDictionary *expected = @{ @"this": @{ @"name": @"Blake", @"emailAddress": @"blake@restkit.org" }, @"that": @{ @"city": @"New York City", @"state": @"New York" }, @"extra": @"info" };
    expect(array).to.equal(expected);
}

- (void)testPostingNilObjectWithExtraParameters
{
    RKObjectMapping *firstRequestMapping = [RKObjectMapping requestMapping];
    [firstRequestMapping addAttributeMappingsFromArray:@[ @"name", @"emailAddress" ]];
    RKObjectMapping *secondRequestMapping = [RKObjectMapping requestMapping];
    [secondRequestMapping addAttributeMappingsFromArray:@[ @"city", @"state" ]];

    RKRequestDescriptor *firstRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:firstRequestMapping objectClass:[RKTestUser class] rootKeyPath:@"this"];
    RKRequestDescriptor *secondRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:secondRequestMapping objectClass:[RKTestAddress class] rootKeyPath:@"that"];

    RKObjectManager *objectManager = [RKTestFactory objectManager];
    objectManager.requestSerializationMIMEType = RKMIMETypeJSON;
    [objectManager addRequestDescriptor:firstRequestDescriptor];
    [objectManager addRequestDescriptor:secondRequestDescriptor];

    NSDictionary *parameters = @{ @"this": @"that" };
    NSURLRequest *request = [objectManager requestWithObject:nil method:RKRequestMethodPOST path:@"/path" parameters:parameters];
    NSArray *array = [NSJSONSerialization JSONObjectWithData:request.HTTPBody options:0 error:nil];
    expect(array).to.equal(parameters);
}

- (void)testAttemptingToPostAnArrayOfObjectsWithMixtureOfNilAndNonNilRootKeyPathsRaisesError
{
    RKObjectMapping *firstRequestMapping = [RKObjectMapping requestMapping];
    [firstRequestMapping addAttributeMappingsFromArray:@[ @"name", @"emailAddress" ]];
    RKObjectMapping *secondRequestMapping = [RKObjectMapping requestMapping];
    [secondRequestMapping addAttributeMappingsFromArray:@[ @"city", @"state" ]];

    RKRequestDescriptor *firstRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:firstRequestMapping objectClass:[RKTestUser class] rootKeyPath:nil];
    RKRequestDescriptor *secondRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:secondRequestMapping objectClass:[RKTestAddress class] rootKeyPath:nil];

    RKTestUser *user = [RKTestUser new];
    user.name = @"Blake";
    user.emailAddress = @"blake@restkit.org";

    RKTestAddress *address = [RKTestAddress new];
    address.city = @"New York City";
    address.state = @"New York";

    RKObjectManager *objectManager = [RKTestFactory objectManager];
    objectManager.requestSerializationMIMEType = RKMIMETypeJSON;
    [objectManager addRequestDescriptor:firstRequestDescriptor];
    [objectManager addRequestDescriptor:secondRequestDescriptor];

    NSArray *arrayOfObjects = @[ user, address ];
    NSException *caughtException = nil;
    @try {
        NSURLRequest __unused *request = [objectManager requestWithObject:arrayOfObjects method:RKRequestMethodPOST path:@"/path" parameters:@{ @"name": @"Foo" }];
    }
    @catch (NSException *exception) {
        caughtException = exception;
        expect([exception name]).to.equal(NSInvalidArgumentException);
        expect([exception reason]).to.equal(@"Cannot merge parameters with array of object representations serialized with a nil root key path.");
    }
    expect(caughtException).notTo.beNil();
}

- (void)testThatAttemptingToPostObjectsWithAMixtureOfNilAndNonNilRootKeyPathsRaisesError
{
    RKObjectMapping *firstRequestMapping = [RKObjectMapping requestMapping];
    [firstRequestMapping addAttributeMappingsFromArray:@[ @"name", @"emailAddress" ]];
    RKObjectMapping *secondRequestMapping = [RKObjectMapping requestMapping];
    [secondRequestMapping addAttributeMappingsFromArray:@[ @"city", @"state" ]];

    RKRequestDescriptor *firstRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:firstRequestMapping objectClass:[RKTestUser class] rootKeyPath:@"bang"];
    RKRequestDescriptor *secondRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:secondRequestMapping objectClass:[RKTestAddress class] rootKeyPath:nil];

    RKTestUser *user = [RKTestUser new];
    user.name = @"Blake";
    user.emailAddress = @"blake@restkit.org";

    RKTestAddress *address = [RKTestAddress new];
    address.city = @"New York City";
    address.state = @"New York";

    RKObjectManager *objectManager = [RKTestFactory objectManager];
    objectManager.requestSerializationMIMEType = RKMIMETypeJSON;
    [objectManager addRequestDescriptor:firstRequestDescriptor];
    [objectManager addRequestDescriptor:secondRequestDescriptor];

    NSArray *arrayOfObjects = @[ user, address ];
    NSException *caughtException = nil;
    @try {
        NSURLRequest __unused *request = [objectManager requestWithObject:arrayOfObjects method:RKRequestMethodPOST path:@"/path" parameters:nil];
    }
    @catch (NSException *exception) {
        caughtException = exception;
        expect([exception name]).to.equal(NSInvalidArgumentException);
        expect([exception reason]).to.equal(@"Invalid request descriptor configuration: The request descriptors specify that multiple objects be serialized at incompatible key paths. Cannot serialize objects at the `nil` root key path in the same request as objects with a non-nil root key path. Please check your request descriptors and try again.");
    }
    expect(caughtException).notTo.beNil();
}

@end
