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
#import "RKPost.h"
#import "RKObjectRequestOperation.h"
#import "RKManagedObjectRequestOperation.h"

@interface RKSubclassedTestModel : RKObjectMapperTestModel
@end

@implementation RKSubclassedTestModel
@end

@interface RKTestAFHTTPClient : AFRKHTTPClient
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

@interface RKTestObjectRequestOperation : RKObjectRequestOperation
@end

@implementation RKTestObjectRequestOperation

+ (BOOL)canProcessRequest:(NSURLRequest *)request
{
    return [[request.URL relativePath] isEqualToString:@"/match"];
}

@end

@interface RKTestManagedObjectRequestOperation : RKManagedObjectRequestOperation
@end

@implementation RKTestManagedObjectRequestOperation

+ (BOOL)canProcessRequest:(NSURLRequest *)request
{
    return [[request.URL relativePath] isEqualToString:@"/match"];
}

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
     [RKResponseDescriptor responseDescriptorWithMapping:humanMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"human" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)],
     [RKResponseDescriptor responseDescriptorWithMapping:humanMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"humans" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)]
     ]];
    
    RKObjectMapping *humanSerialization = [RKObjectMapping requestMapping];
    [humanSerialization addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"]];
    [self.objectManager addRequestDescriptor:[RKRequestDescriptor requestDescriptorWithMapping:humanSerialization objectClass:[RKHuman class] rootKeyPath:@"human" method:RKRequestMethodAny]];

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
    AFRKHTTPClient *client = [AFRKHTTPClient clientWithBaseURL:[NSURL URLWithString:@"http://restkit.org"]];
    [client setDefaultHeader:@"Accept" value:@"this/that"];
    RKObjectManager *manager = [[RKObjectManager alloc] initWithHTTPClient:client];
    expect([manager defaultHeaders][@"Accept"]).to.equal(@"this/that");
}

- (void)testDefersToAFHTTPClientParameterEncodingWhenInitializedWithAFHTTPClient
{
    AFRKHTTPClient *client = [AFRKHTTPClient clientWithBaseURL:[NSURL URLWithString:@"http://restkit.org"]];
    client.parameterEncoding = AFRKJSONParameterEncoding;
    RKObjectManager *manager = [[RKObjectManager alloc] initWithHTTPClient:client];
    expect([manager requestSerializationMIMEType]).to.equal(RKMIMETypeJSON);
}

- (void)testDefaultsToFormURLEncodingForUnsupportedParameterEncodings
{
    AFRKHTTPClient *client = [AFRKHTTPClient clientWithBaseURL:[NSURL URLWithString:@"http://restkit.org"]];
    client.parameterEncoding = AFRKPropertyListParameterEncoding;
    RKObjectManager *manager = [[RKObjectManager alloc] initWithHTTPClient:client];
    expect([manager requestSerializationMIMEType]).to.equal(RKMIMETypeFormURLEncoded);
}

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
    RKHuman *human = (RKHuman *)[operation.mappingResult array][0];
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

- (void)testCancellationOfMultipartRequestByPath
{
    self.objectManager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:@"http://localhost:4567/object_manager/"]];
    RKTestUser *testUser = [RKTestUser new];
    NSMutableURLRequest *request = [self.objectManager multipartFormRequestWithObject:testUser method:RKRequestMethodPOST path:@"path" parameters:nil constructingBodyWithBlock:^(id<AFRKMultipartFormData> formData) {
        [formData appendPartWithFormData:[@"testing" dataUsingEncoding:NSUTF8StringEncoding] name:@"part"];
    }];
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:self.objectManager.responseDescriptors];
    [_objectManager enqueueObjectRequestOperation:operation];
    [_objectManager cancelAllObjectRequestOperationsWithMethod:RKRequestMethodPOST matchingPathPattern:@"path"];
    expect([operation isCancelled]).to.equal(YES);
}

- (void)testEnqueuedObjectRequestOperationByExactMethodAndPath
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/object_manager/cancel" relativeToURL:self.objectManager.HTTPClient.baseURL]];
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:self.objectManager.responseDescriptors];
    [_objectManager enqueueObjectRequestOperation:operation];
    expect([[_objectManager enqueuedObjectRequestOperationsWithMethod:RKRequestMethodGET matchingPathPattern:@"/object_manager/cancel"] count]).to.equal(1);
}

- (void)testEnqueuedObjectRequestOperationByMultipleExactMethodAndPath
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/object_manager/cancel" relativeToURL:self.objectManager.HTTPClient.baseURL]];
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:self.objectManager.responseDescriptors];
    RKObjectRequestOperation *secondOperation = [operation copy];
    RKObjectRequestOperation *thirdOperation = [operation copy];
    [_objectManager enqueueObjectRequestOperation:operation];
    [_objectManager enqueueObjectRequestOperation:secondOperation];
    [_objectManager enqueueObjectRequestOperation:thirdOperation];
    expect([[_objectManager enqueuedObjectRequestOperationsWithMethod:RKRequestMethodGET matchingPathPattern:@"/object_manager/cancel"] count]).to.equal(3);
}

- (void)testEnqueuedObjectRequestOperationByPathMatch
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/object_manager/1234/cancel" relativeToURL:self.objectManager.HTTPClient.baseURL]];
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:self.objectManager.responseDescriptors];
    [_objectManager enqueueObjectRequestOperation:operation];
    expect([[_objectManager enqueuedObjectRequestOperationsWithMethod:RKRequestMethodGET matchingPathPattern:@"/object_manager/:objectID/cancel"] count]).to.equal(1);
}

- (void)testEnqueuedObjectRequestOperationFailsForMismatchedMethod
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/object_manager/cancel" relativeToURL:self.objectManager.HTTPClient.baseURL]];
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:self.objectManager.responseDescriptors];
    [_objectManager enqueueObjectRequestOperation:operation];
    expect([[_objectManager enqueuedObjectRequestOperationsWithMethod:RKRequestMethodGET matchingPathPattern:@"/wrong"] count]).to.equal(0);
}

- (void)testEnqueuedObjectRequestOperationFailsForMismatchedPath
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/object_manager/cancel" relativeToURL:self.objectManager.HTTPClient.baseURL]];
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:self.objectManager.responseDescriptors];
    [_objectManager enqueueObjectRequestOperation:operation];
    expect([[_objectManager enqueuedObjectRequestOperationsWithMethod:RKRequestMethodGET matchingPathPattern:@"/wrong"] count]).to.equal(0);
}

- (void)testEnqueuedObjectRequestOperationByPathMatchForBaseURLWithPath
{
    self.objectManager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:@"http://localhost:4567/object_manager/"]];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://localhost:4567/object_manager/1234/cancel"]];
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:self.objectManager.responseDescriptors];
    [_objectManager enqueueObjectRequestOperation:operation];
    expect([[_objectManager enqueuedObjectRequestOperationsWithMethod:RKRequestMethodGET matchingPathPattern:@":objectID/cancel"] count]).to.equal(1);
}

- (void)testEnqueuedObjectRequestOperationByMultipleBitmaskMethodAndPath
{
    NSURLRequest *request1 = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/object_manager/cancel" relativeToURL:self.objectManager.HTTPClient.baseURL]];
    NSMutableURLRequest *request2 = [request1 mutableCopy];
    request2.HTTPMethod = @"POST";
    NSMutableURLRequest *request3 = [request1 mutableCopy];
    request3.HTTPMethod = @"DELETE";
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request1 responseDescriptors:self.objectManager.responseDescriptors];
    
    RKObjectRequestOperation *secondOperation = [[RKObjectRequestOperation alloc] initWithRequest:request2 responseDescriptors:self.objectManager.responseDescriptors];
    RKObjectRequestOperation *thirdOperation = [[RKObjectRequestOperation alloc] initWithRequest:request3 responseDescriptors:self.objectManager.responseDescriptors];
    [_objectManager enqueueObjectRequestOperation:operation];
    [_objectManager enqueueObjectRequestOperation:secondOperation];
    [_objectManager enqueueObjectRequestOperation:thirdOperation];
    NSArray *operations = [_objectManager enqueuedObjectRequestOperationsWithMethod:RKRequestMethodGET | RKRequestMethodPOST matchingPathPattern:@"/object_manager/cancel"];
    expect(operations).to.haveCountOf(2);
    expect(operations).to.contain(operation);
    expect(operations).to.contain(secondOperation);
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
    expect([operation.HTTPRequestOperation.request.URL absoluteString]).to.equal(@"http://localhost:4567/humans/204?this=that");
}

- (void)testThatObjectParametersAreNotSentDuringDeleteObject
{
    RKHuman *temporaryHuman = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:nil withProperties:nil];
    temporaryHuman.name = @"My Name";
    temporaryHuman.railsID = @204;
    RKManagedObjectRequestOperation *operation = [_objectManager appropriateObjectRequestOperationWithObject:temporaryHuman method:RKRequestMethodDELETE path:nil parameters:@{@"this": @"that"}];
    expect([operation.HTTPRequestOperation.request.URL absoluteString]).to.equal(@"http://localhost:4567/humans/204?this=that");
}

- (void)testInitializationOfObjectRequestOperationProducesCorrectURLRequest
{
    RKHuman *temporaryHuman = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:nil withProperties:nil];
    NSURLRequest *request = [_objectManager requestWithObject:temporaryHuman method:RKRequestMethodPATCH path:@"/the/path" parameters:@{@"key": @"value"}];
    expect([request.URL absoluteString]).to.equal(@"http://localhost:4567/the/path");
    expect(request.HTTPMethod).to.equal(@"PATCH");
    expect(request.HTTPBody).notTo.beNil();
    NSString *string = [[NSString alloc] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding];
    expect(string).to.equal(@"human[name]&key=value");
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
    [manager registerRequestOperationClass:[RKTestHTTPRequestOperation class]];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/test" relativeToURL:manager.baseURL]];
    RKObjectRequestOperation *operation = [manager objectRequestOperationWithRequest:request success:nil failure:nil];
    expect(operation.HTTPRequestOperation).to.beKindOf([RKTestHTTPRequestOperation class]);
}

- (void)testSettingNilHTTPRequestOperationClassRestoresDefaultHTTPOperationClass
{
    RKObjectManager *manager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:@"http://restkit.org"]];
    [manager registerRequestOperationClass:[RKTestHTTPRequestOperation class]];
    [manager unregisterRequestOperationClass:[RKTestHTTPRequestOperation class]];
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
    RKRequestDescriptor *requestDesriptor1 = [RKRequestDescriptor requestDescriptorWithMapping:mapping objectClass:[RKCat class] rootKeyPath:nil method:RKRequestMethodAny];
    RKRequestDescriptor *requestDesriptor2 = [RKRequestDescriptor requestDescriptorWithMapping:mapping objectClass:[RKCat class] rootKeyPath:@"cat" method:RKRequestMethodAny];
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
    
    RKRequestDescriptor *requestDesriptor1 = [RKRequestDescriptor requestDescriptorWithMapping:mapping1 objectClass:[RKObjectMapperTestModel class] rootKeyPath:nil method:RKRequestMethodAny];
    RKRequestDescriptor *requestDesriptor2 = [RKRequestDescriptor requestDescriptorWithMapping:mapping2 objectClass:[RKSubclassedTestModel class] rootKeyPath:@"subclassed" method:RKRequestMethodAny];
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
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:vanillaMapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:nil];
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
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:dynamicMapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:nil];
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
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:dynamicMapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:nil];
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
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:objectMapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:nil];
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
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:objectMapping2 method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:nil];
    RKObjectManager *manager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:@"http://restkit.org"]];
    manager.managedObjectStore = [RKTestFactory managedObjectStore];
    [manager addResponseDescriptor:responseDescriptor];
    RKObjectRequestOperation *objectRequestOperation = [manager appropriateObjectRequestOperationWithObject:nil method:RKRequestMethodGET path:@"/something" parameters:nil];
    expect(objectRequestOperation).to.beInstanceOf([RKManagedObjectRequestOperation class]);
}

- (void)testChangingHTTPClient
{
    RKObjectManager *manager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:@"http://restkit.org"]];
    manager.HTTPClient = [AFRKHTTPClient clientWithBaseURL:[NSURL URLWithString:@"http://google.com/"]];
    expect([manager.baseURL absoluteString]).to.equal(@"http://google.com/");
}

- (void)testPostingOneObjectAndGettingResponseMatchingAnotherClass
{
    RKObjectManager *manager = [RKObjectManager managerWithBaseURL:[RKTestFactory baseURL]];
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [userMapping addAttributeMappingsFromDictionary:@{ @"fullname": @"name" }];
    RKObjectMapping *metaMapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [metaMapping addAttributeMappingsFromArray:@[ @"status", @"version" ]];
    RKResponseDescriptor *metaResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:metaMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"meta" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
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
    RKResponseDescriptor *userResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"data.STUser" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    RKObjectMapping *metaMapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [metaMapping addAttributeMappingsFromArray:@[ @"status", @"version" ]];    
    RKResponseDescriptor *metaResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:metaMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"meta" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
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

    RKRequestDescriptor *firstRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:firstRequestMapping objectClass:[RKTestUser class] rootKeyPath:nil method:RKRequestMethodAny];
    RKRequestDescriptor *secondRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:secondRequestMapping objectClass:[RKTestAddress class] rootKeyPath:nil method:RKRequestMethodAny];

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

    RKRequestDescriptor *firstRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:firstRequestMapping objectClass:[RKTestUser class] rootKeyPath:@"whatever" method:RKRequestMethodAny];
    RKRequestDescriptor *secondRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:secondRequestMapping objectClass:[RKTestAddress class] rootKeyPath:@"whatever" method:RKRequestMethodAny];

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

    RKRequestDescriptor *firstRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:firstRequestMapping objectClass:[RKTestUser class] rootKeyPath:@"this" method:RKRequestMethodAny];
    RKRequestDescriptor *secondRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:secondRequestMapping objectClass:[RKTestAddress class] rootKeyPath:@"that" method:RKRequestMethodAny];

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

    RKRequestDescriptor *firstRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:firstRequestMapping objectClass:[RKTestUser class] rootKeyPath:@"this" method:RKRequestMethodAny];
    RKRequestDescriptor *secondRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:secondRequestMapping objectClass:[RKTestAddress class] rootKeyPath:@"that" method:RKRequestMethodAny];

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

- (void)testPostingAnArrayWithSingleObjectGeneratesAnArray
{
    RKObjectMapping *firstRequestMapping = [RKObjectMapping requestMapping];
    [firstRequestMapping addAttributeMappingsFromArray:@[ @"name", @"emailAddress" ]];
    
    RKRequestDescriptor *firstRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:firstRequestMapping objectClass:[RKTestUser class] rootKeyPath:@"whatever" method:RKRequestMethodAny];
    
    RKTestUser *user = [RKTestUser new];
    user.name = @"Blake";
    user.emailAddress = @"blake@restkit.org";
    
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    objectManager.requestSerializationMIMEType = RKMIMETypeJSON;
    [objectManager addRequestDescriptor:firstRequestDescriptor];
    
    NSArray *arrayOfObjects = @[ user ];
    NSURLRequest *request = [objectManager requestWithObject:arrayOfObjects method:RKRequestMethodPOST path:@"/path" parameters:nil];
    NSArray *array = [NSJSONSerialization JSONObjectWithData:request.HTTPBody options:0 error:nil];
    NSDictionary *expected = @{ @"whatever": @[ @{ @"name": @"Blake", @"emailAddress": @"blake@restkit.org" } ] };
    expect(array).to.equal(expected);
}

- (void)testPostingNilObjectWithExtraParameters
{
    RKObjectMapping *firstRequestMapping = [RKObjectMapping requestMapping];
    [firstRequestMapping addAttributeMappingsFromArray:@[ @"name", @"emailAddress" ]];
    RKObjectMapping *secondRequestMapping = [RKObjectMapping requestMapping];
    [secondRequestMapping addAttributeMappingsFromArray:@[ @"city", @"state" ]];

    RKRequestDescriptor *firstRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:firstRequestMapping objectClass:[RKTestUser class] rootKeyPath:@"this" method:RKRequestMethodAny];
    RKRequestDescriptor *secondRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:secondRequestMapping objectClass:[RKTestAddress class] rootKeyPath:@"that" method:RKRequestMethodAny];

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

    RKRequestDescriptor *firstRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:firstRequestMapping objectClass:[RKTestUser class] rootKeyPath:nil method:RKRequestMethodAny];
    RKRequestDescriptor *secondRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:secondRequestMapping objectClass:[RKTestAddress class] rootKeyPath:nil method:RKRequestMethodAny];

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

    RKRequestDescriptor *firstRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:firstRequestMapping objectClass:[RKTestUser class] rootKeyPath:@"bang" method:RKRequestMethodAny];
    RKRequestDescriptor *secondRequestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:secondRequestMapping objectClass:[RKTestAddress class] rootKeyPath:nil method:RKRequestMethodAny];

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

#pragma mark - Object Request Operation Registration

- (void)testRegistrationOfObjectRequestOperationClass
{
    RKObjectManager *manager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:@"http://restkit.org"]];
    [manager registerRequestOperationClass:[RKTestObjectRequestOperation class]];
    NSURL *URL = [NSURL URLWithString:@"/match" relativeToURL:manager.baseURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    RKObjectRequestOperation *operation = [manager objectRequestOperationWithRequest:request success:nil failure:nil];
    expect(operation).to.beInstanceOf([RKTestObjectRequestOperation class]);
}

- (void)testRegistrationOfObjectRequestOperationClassRespectsSubclassDecisionToProcessRequest
{
    RKObjectManager *manager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:@"http://restkit.org"]];
    [manager registerRequestOperationClass:[RKTestObjectRequestOperation class]];
    NSURL *URL = [NSURL URLWithString:@"/mismatch" relativeToURL:manager.baseURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    RKObjectRequestOperation *operation = [manager objectRequestOperationWithRequest:request success:nil failure:nil];
    expect(operation).notTo.beInstanceOf([RKTestObjectRequestOperation class]);
    expect(operation).to.beInstanceOf([RKObjectRequestOperation class]);
}

- (void)testRegistrationOfManagedObjectRequestOperationClass
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKObjectManager *manager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:@"http://restkit.org"]];
    [manager registerRequestOperationClass:[RKTestManagedObjectRequestOperation class]];
    NSURL *URL = [NSURL URLWithString:@"/match" relativeToURL:manager.baseURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    RKObjectRequestOperation *operation = [manager managedObjectRequestOperationWithRequest:request managedObjectContext:managedObjectStore.mainQueueManagedObjectContext success:nil failure:nil];
    expect(operation).to.beInstanceOf([RKTestManagedObjectRequestOperation class]);
}

- (void)testRegistrationOfManagedObjectRequestOperationClassRespectsSubclassDecisionToProcessRequest
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKObjectManager *manager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:@"http://restkit.org"]];
    [manager registerRequestOperationClass:[RKTestManagedObjectRequestOperation class]];
    NSURL *URL = [NSURL URLWithString:@"/mismatch" relativeToURL:manager.baseURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    RKObjectRequestOperation *operation = [manager managedObjectRequestOperationWithRequest:request managedObjectContext:managedObjectStore.mainQueueManagedObjectContext success:nil failure:nil];
    expect(operation).notTo.beInstanceOf([RKTestManagedObjectRequestOperation class]);
    expect(operation).to.beInstanceOf([RKManagedObjectRequestOperation class]);
}

- (void)testThatPostingUnsavedObjectWithUnsavedChildrenDoesNotCrash
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSManagedObject *developmentTag = [NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    [developmentTag setValue:@"development" forKey:@"name"];
    NSManagedObject *restkitTag = [NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    [restkitTag setValue:@"restkit" forKey:@"name"];

    NSManagedObject *post = [NSEntityDescription insertNewObjectForEntityForName:@"Post" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    [post setValue:@"Post Title" forKey:@"title"];
    [post setValue:[NSSet setWithObjects:developmentTag, restkitTag, nil]  forKey:@"tags"];

    RKEntityMapping *postMapping = [RKEntityMapping mappingForEntityForName:@"Post" inManagedObjectStore:managedObjectStore];
    postMapping.identificationAttributes = @[ @"title" ];
    [postMapping addAttributeMappingsFromArray:@[ @"title", @"body" ]];
    RKEntityMapping *tagMapping = [RKEntityMapping mappingForEntityForName:@"Tag" inManagedObjectStore:managedObjectStore];
    tagMapping.identificationAttributes = @[ @"name" ];
    [tagMapping addAttributeMappingsFromArray:@[ @"name" ]];
    [postMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"tags" toKeyPath:@"tags" withMapping:tagMapping]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:postMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"post" statusCodes:[NSIndexSet indexSetWithIndex:200]];

    RKObjectMapping *tagRequestMapping = [RKObjectMapping requestMapping];
    [tagRequestMapping addAttributeMappingsFromArray:@[ @"name" ]];
    RKObjectMapping *postRequestMapping = [RKObjectMapping requestMapping];
    [postRequestMapping addAttributeMappingsFromArray:@[ @"title", @"body" ]];
    [postRequestMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"tags" toKeyPath:@"tags" withMapping:tagRequestMapping]];
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:postRequestMapping objectClass:[NSManagedObject class] rootKeyPath:nil method:RKRequestMethodAny];

    RKObjectManager *objectManager = [RKTestFactory objectManager];
    objectManager.managedObjectStore = managedObjectStore;
    [objectManager addResponseDescriptor:responseDescriptor];
    [objectManager addRequestDescriptor:requestDescriptor];

    expect([post isNew]).to.equal(YES);
    expect([post.objectID isTemporaryID]).to.equal(YES);
    expect([developmentTag isNew]).to.equal(YES);
    expect([developmentTag.objectID isTemporaryID]).to.equal(YES);
    expect([restkitTag isNew]).to.equal(YES);
    expect([restkitTag.objectID isTemporaryID]).to.equal(YES);

    __block RKMappingResult *postMappingResult = nil;
    RKManagedObjectRequestOperation *operation = [objectManager appropriateObjectRequestOperationWithObject:post method:RKRequestMethodPOST path:@"/posts.json" parameters:nil];
    operation.savesToPersistentStore = NO;
    [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        postMappingResult = mappingResult;
    } failure:nil];
    [objectManager enqueueObjectRequestOperation:operation];

    expect(postMappingResult).willNot.beNil();
    expect([post.objectID isTemporaryID]).will.equal(NO);
    expect([developmentTag.objectID isTemporaryID]).will.equal(NO);
    expect([restkitTag.objectID isTemporaryID]).will.equal(NO);
}

- (void)testPathMatchingForMultipartRequest
{
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    NSString *path = @"/api/upload/";
    
    NSData *blakePng = [RKTestFixture dataWithContentsOfFixture:@"blake.png"];
    NSMutableURLRequest *request = [objectManager multipartFormRequestWithObject:nil method:RKRequestMethodPOST path:path parameters:nil constructingBodyWithBlock:^(id<AFRKMultipartFormData> formData) {
        [formData appendPartWithFileData:blakePng
                                    name:@"file"
                                fileName:@"blake.png"
                                mimeType:@"image/png"];
    }];
    
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping addAttributeMappingsFromArray:@[ @"name" ]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:path keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    [objectManager addResponseDescriptor:responseDescriptor];
    
    RKObjectRequestOperation * operation = [[RKObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    [[RKObjectManager sharedManager] enqueueObjectRequestOperation:operation];
    
    expect([operation isFinished]).will.equal(YES);
    expect(operation.error).to.beNil();
    RKTestUser *user = [operation.mappingResult firstObject];
    expect(user.name).to.equal(@"Blake");
}

- (void)testPostingTemporaryObjectThatDoesNotExistInCacheDoesNotCreateDuplicatesWithFetchRequestCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    managedObjectStore.managedObjectCache = managedObjectCache;
    
    NSEntityDescription *entity = [managedObjectStore.managedObjectModel entitiesByName][@"Human"];
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    entityMapping.identificationAttributes = @[ @"railsID" ];
    [entityMapping addAttributeMappingsFromDictionary:@{ @"id": @"railsID", @"name": @"name" }];
    
    NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [childContext setParentContext:managedObjectStore.mainQueueManagedObjectContext];
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:childContext];
    
    RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:[RKTestFactory baseURL]];
    objectManager.managedObjectStore = managedObjectStore;
    [objectManager addResponseDescriptor:[RKResponseDescriptor responseDescriptorWithMapping:entityMapping method:RKRequestMethodAny pathPattern:@"/humans" keyPath:@"human" statusCodes:[NSIndexSet indexSetWithIndex:201]]];
    __block RKMappingResult *mappingResult = nil;
    [objectManager postObject:human path:@"/humans" parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *blockMappingResult) {
        mappingResult = blockMappingResult;
    } failure:nil];
    
    expect(mappingResult).willNot.beNil();
    
    expect([[human objectID] isTemporaryID]).to.beFalsy();
    
    NSSet *managedObjects = [managedObjectCache managedObjectsWithEntity:entity attributeValues:@{ @"railsID": @(1) } inManagedObjectContext:childContext];
    expect(managedObjects).to.haveCountOf(1);
    
    [objectManager postObject:human path:@"/humans" parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *blockMappingResult) {
        mappingResult = blockMappingResult;
    } failure:nil];
    
    expect(mappingResult).willNot.beNil();
    managedObjects = [managedObjectCache managedObjectsWithEntity:entity attributeValues:@{ @"railsID": @(1) } inManagedObjectContext:childContext];
    expect(managedObjects).to.haveCountOf(1);
}

- (void)testPostingTemporaryObjectWithChildObjectsThatDoesNotExistInCacheDoesNotCreateDuplicatesWithFetchRequestCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    managedObjectStore.managedObjectCache = managedObjectCache;
    
    NSManagedObject *developmentTag = [NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    [developmentTag setValue:@"development" forKey:@"name"];
    NSManagedObject *restkitTag = [NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    [restkitTag setValue:@"restkit" forKey:@"name"];
    
    NSManagedObject *post = [NSEntityDescription insertNewObjectForEntityForName:@"Post" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    [post setValue:@"Post Title" forKey:@"title"];
    [post setValue:[NSSet setWithObjects:developmentTag, restkitTag, nil]  forKey:@"tags"];
    
    RKEntityMapping *postMapping = [RKEntityMapping mappingForEntityForName:@"Post" inManagedObjectStore:managedObjectStore];
    postMapping.identificationAttributes = @[ @"title" ];
    [postMapping addAttributeMappingsFromArray:@[ @"title", @"body" ]];
    RKEntityMapping *tagMapping = [RKEntityMapping mappingForEntityForName:@"Tag" inManagedObjectStore:managedObjectStore];
    [tagMapping addAttributeMappingsFromArray:@[ @"name" ]];
    RKRelationshipMapping *relationshipMapping = [RKRelationshipMapping relationshipMappingFromKeyPath:@"tags" toKeyPath:@"tags" withMapping:tagMapping];
    [postMapping addPropertyMapping:relationshipMapping];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:postMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"post" statusCodes:[NSIndexSet indexSetWithIndex:200]];
    
    RKObjectMapping *tagRequestMapping = [RKObjectMapping requestMapping];
    [tagRequestMapping addAttributeMappingsFromArray:@[ @"name" ]];
    RKObjectMapping *postRequestMapping = [RKObjectMapping requestMapping];
    [postRequestMapping addAttributeMappingsFromArray:@[ @"title", @"body" ]];
    [postRequestMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"tags" toKeyPath:@"tags" withMapping:tagRequestMapping]];
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:postRequestMapping objectClass:[NSManagedObject class] rootKeyPath:nil method:RKRequestMethodAny];
    
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    objectManager.managedObjectStore = managedObjectStore;
    [objectManager addResponseDescriptor:responseDescriptor];
    [objectManager addRequestDescriptor:requestDescriptor];
    
    expect([post isNew]).to.equal(YES);
    expect([post.objectID isTemporaryID]).to.equal(YES);
    expect([developmentTag isNew]).to.equal(YES);
    expect([developmentTag.objectID isTemporaryID]).to.equal(YES);
    expect([restkitTag isNew]).to.equal(YES);
    expect([restkitTag.objectID isTemporaryID]).to.equal(YES);
    
    __block RKMappingResult *postMappingResult = nil;
    RKManagedObjectRequestOperation *operation = [objectManager appropriateObjectRequestOperationWithObject:post method:RKRequestMethodPOST path:@"/posts.json" parameters:nil];
    operation.savesToPersistentStore = NO;
    [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        postMappingResult = mappingResult;
    } failure:nil];
    [objectManager enqueueObjectRequestOperation:operation];
    
    expect(postMappingResult).willNot.beNil();
    expect([post.objectID isTemporaryID]).will.equal(NO);
    expect([developmentTag.objectID isTemporaryID]).will.equal(NO);
    expect([restkitTag.objectID isTemporaryID]).will.equal(NO);
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Tag"];
    NSUInteger tagsCount = [objectManager.managedObjectStore.mainQueueManagedObjectContext countForFetchRequest:fetchRequest error:nil];
    expect(tagsCount).to.equal(2);
}

- (void)testThatMappingAToManyRelationshipOnAnExistingSetOfObjectsDoesNotReuseTheFirstObjectInTheCollection
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *postMapping = [RKEntityMapping mappingForEntityForName:@"Post" inManagedObjectStore:managedObjectStore];
    [postMapping addAttributeMappingsFromDictionary:@{ @"title": @"title" }];
    RKEntityMapping *tagMapping = [RKEntityMapping mappingForEntityForName:@"Tag" inManagedObjectStore:managedObjectStore];
    [tagMapping addAttributeMappingsFromDictionary:@{ @"name": @"name" }];
    [postMapping addRelationshipMappingWithSourceKeyPath:@"tags" mapping:tagMapping];
    NSDictionary *representation = @{ @"title": @"The Post", @"tags": @[ @{ @"name": @"first" }, @{ @"name": @"second" } ] };
    RKFetchRequestManagedObjectCache *fetchRequestCache = [RKFetchRequestManagedObjectCache new];
    RKManagedObjectMappingOperationDataSource *dataSource = [[RKManagedObjectMappingOperationDataSource alloc] initWithManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext cache:fetchRequestCache];
    RKMapperOperation *mapperOperation = [[RKMapperOperation alloc] initWithRepresentation:representation mappingsDictionary:@{ [NSNull null]: postMapping }];
    mapperOperation.mappingOperationDataSource = dataSource;
    NSError *error = nil;
    BOOL success = [mapperOperation execute:&error];
    expect(success).to.beTruthy();
    RKPost *post = [mapperOperation.mappingResult firstObject];
    expect(post.tags).to.haveCountOf(2);
    
    mapperOperation = [[RKMapperOperation alloc] initWithRepresentation:representation mappingsDictionary:@{ [NSNull null]: postMapping }];
    mapperOperation.mappingOperationDataSource = dataSource;
    success = [mapperOperation execute:&error];
    expect(success).to.beTruthy();
    post = [mapperOperation.mappingResult firstObject];
    expect(post.tags).to.haveCountOf(2);
}

- (void)testMappingErrorsFromFiveHundredStatusCodeRange
{
    RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:[RKTestFactory baseURL]];    
    NSIndexSet *statusCodes = RKStatusCodeIndexSetForClass(RKStatusCodeClassServerError);
    RKObjectMapping *errorResponseMapping = [RKObjectMapping mappingForClass:[RKErrorMessage class]];
    [errorResponseMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:nil toKeyPath:@"errorMessage"]];
    [objectManager addResponseDescriptor:[RKResponseDescriptor responseDescriptorWithMapping:errorResponseMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"errors" statusCodes:statusCodes]];
    
    __block NSError *error = nil;
    [objectManager getObjectsAtPath:@"/fail" parameters:nil success:nil failure:^(RKObjectRequestOperation *operation, NSError *blockError) {
        error = blockError;
    }];
    
    expect(error).willNot.beNil();
    expect([error localizedDescription]).to.equal(@"error1, error2");
}

- (void)testPostingATemporaryObjectThatHasJustBeenSaved
{
    NSManagedObjectContext *managedObjectContext = [[RKTestFactory managedObjectStore] mainQueueManagedObjectContext];
    RKHuman *temporaryHuman = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectContext];
    temporaryHuman.name = @"My Name";
    expect([temporaryHuman.objectID isTemporaryID]).to.equal(YES);
    NSError *error = nil;
    BOOL success = [temporaryHuman.managedObjectContext saveToPersistentStore:&error];
    expect(success).to.equal(YES);
    
    RKManagedObjectRequestOperation *operation = [_objectManager appropriateObjectRequestOperationWithObject:temporaryHuman method:RKRequestMethodPOST path:nil parameters:nil];
    [_objectManager enqueueObjectRequestOperation:operation];
    expect([operation isFinished]).will.equal(YES);
    
    expect(operation.mappingResult).notTo.beNil();
    expect([operation.mappingResult array]).notTo.beEmpty();
    RKHuman *human = (RKHuman *)[operation.mappingResult array][0];
    expect(human.objectID).to.equal(temporaryHuman.objectID);
    expect(human.railsID).to.equal(1);
}

- (void)testConnectingARelationshipToAnObjectUsingRoutingMetadata
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    managedObjectStore.managedObjectCache = managedObjectCache;
    
    NSManagedObject *post = [NSEntityDescription insertNewObjectForEntityForName:@"Post" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    [post setValue:@"The Post" forKey:@"title"];
    [post setValue:@(1234) forKey:@"postID"];
    
    RKEntityMapping *tagMapping = [RKEntityMapping mappingForEntityForName:@"Tag" inManagedObjectStore:managedObjectStore];
    [tagMapping addAttributeMappingsFromDictionary:@{ @"@metadata.routing.parameters.postID": @"postID", @"name": @"name" }];
    [tagMapping addConnectionForRelationship:@"posts" connectedBy:@{ @"postID": @"postID" }];
    
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:tagMapping method:RKRequestMethodAny pathPattern:@"/posts/:postID/tags" keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    [objectManager addResponseDescriptor:responseDescriptor];
    [objectManager.router.routeSet addRoute:[RKRoute routeWithRelationshipName:@"tags" objectClass:[RKPost class] pathPattern:@"/posts/:postID/tags" method:RKRequestMethodGET]];
    __block RKMappingResult *mappingResult = nil;
    [objectManager getObjectsAtPathForRelationship:@"tags" ofObject:post parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *blockMappingResult) {
        mappingResult = blockMappingResult;
    } failure:nil];
    expect(mappingResult).willNot.beNil();
    NSArray *tags = [mappingResult array];
    expect(tags).notTo.beNil();
    NSArray *tagNames = @[@"development", @"restkit"];
    expect([tags valueForKey:@"name"]).to.equal(tagNames);
    NSSet *connectedTags = [post valueForKey:@"tags"];
    expect(connectedTags).notTo.beEmpty();
}

- (void)testMappingMetadataParameterForNamedRoute
{
    RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:[RKTestFactory baseURL]];
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [userMapping addAttributeMappingsFromDictionary:@{ @"name": @"name", @"@metadata.routing.parameters.userID": @"position" }];    
    [objectManager.router.routeSet addRoute:[RKRoute routeWithName:@"load_human" pathPattern:@"/JSON/humans/:userID\\.json" method:RKRequestMethodGET]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:@"/JSON/humans/:userID\\.json" keyPath:@"human" statusCodes:[NSIndexSet indexSetWithIndex:200]];
    [objectManager addResponseDescriptor:responseDescriptor];
    
    RKTestUser *user = [RKTestUser new];
    user.userID = @1;
    __block RKMappingResult *mappingResult = nil;
    [objectManager getObjectsAtPathForRouteNamed:@"load_human" object:user parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *blockMappingResult) {
        mappingResult = blockMappingResult;
    } failure:nil];
    
    expect(mappingResult).willNot.beNil();
    RKTestUser *anotherUser = [mappingResult firstObject];
    expect(anotherUser).notTo.equal(user);
    expect(anotherUser.name).to.equal(@"Blake Watters");
    expect(anotherUser.position).to.equal(@1);
}

- (void)testMappingMetadataQueryParametersByPath
{
    RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:[RKTestFactory baseURL]];
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [userMapping addAttributeMappingsFromDictionary:@{ @"name": @"name", @"@metadata.query.parameters.userID": @"position" }];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:@"/JSON/humans/:userID\\.json" keyPath:@"human" statusCodes:[NSIndexSet indexSetWithIndex:200]];
    [objectManager addResponseDescriptor:responseDescriptor];
    
    __block RKMappingResult *mappingResult = nil;
    [objectManager getObjectsAtPath:@"/JSON/humans/1.json" parameters:@{ @"userID" : @"12" } success:^(RKObjectRequestOperation *operation, RKMappingResult *blockMappingResult) {
        mappingResult = blockMappingResult;
    } failure:nil];
    
    expect(mappingResult).willNot.beNil();
    RKTestUser *user = [mappingResult firstObject];
    expect(user.name).to.equal(@"Blake Watters");
    expect(user.position).to.equal(@12);
}

- (void)testMappingMetadataByPathNoneSupplied
{
    RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:[RKTestFactory baseURL]];
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [userMapping addAttributeMappingsFromDictionary:@{ @"name": @"name", @"@metadata.query.parameters.userID": @"position" }];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:@"/JSON/humans/:userID\\.json" keyPath:@"human" statusCodes:[NSIndexSet indexSetWithIndex:200]];
    [objectManager addResponseDescriptor:responseDescriptor];
    
    __block RKMappingResult *mappingResult = nil;
    [objectManager getObjectsAtPath:@"/JSON/humans/1.json" parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *blockMappingResult) {
        mappingResult = blockMappingResult;
    } failure:nil];
    
    expect(mappingResult).willNot.beNil();
    RKTestUser *user = [mappingResult firstObject];
    expect(user.name).to.equal(@"Blake Watters");
    expect(user.position).to.beNil;
}

- (void)testMappingMetadataQueryParametersByRoute
{
    RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:[RKTestFactory baseURL]];
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [userMapping addAttributeMappingsFromDictionary:@{ @"name": @"name", @"@metadata.query.parameters.userID": @"position" }];
    [objectManager.router.routeSet addRoute:[RKRoute routeWithName:@"load_human" pathPattern:@"/JSON/humans/:userID\\.json" method:RKRequestMethodGET]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:@"/JSON/humans/:userID\\.json" keyPath:@"human" statusCodes:[NSIndexSet indexSetWithIndex:200]];
    [objectManager addResponseDescriptor:responseDescriptor];
    
    RKTestUser *user = [RKTestUser new];
    user.userID = @1;
    __block RKMappingResult *mappingResult = nil;
    [objectManager getObjectsAtPathForRouteNamed:@"load_human" object:user parameters:@{ @"userID" : @"12" } success:^(RKObjectRequestOperation *operation, RKMappingResult *blockMappingResult) {
        mappingResult = blockMappingResult;
    } failure:nil];
    
    expect(mappingResult).willNot.beNil();
    RKTestUser *anotherUser = [mappingResult firstObject];
    expect(anotherUser).notTo.equal(user);
    expect(anotherUser.name).to.equal(@"Blake Watters");
    expect(anotherUser.position).to.equal(@12);
}

- (void)testMappingMetadataQueryParametersByRouteNoneSupplied
{
    RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:[RKTestFactory baseURL]];
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [userMapping addAttributeMappingsFromDictionary:@{ @"name": @"name", @"@metadata.query.parameters.userID": @"position" }];
    [objectManager.router.routeSet addRoute:[RKRoute routeWithName:@"load_human" pathPattern:@"/JSON/humans/:userID\\.json" method:RKRequestMethodGET]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:@"/JSON/humans/:userID\\.json" keyPath:@"human" statusCodes:[NSIndexSet indexSetWithIndex:200]];
    [objectManager addResponseDescriptor:responseDescriptor];
    
    RKTestUser *user = [RKTestUser new];
    user.userID = @1;
    __block RKMappingResult *mappingResult = nil;
    [objectManager getObjectsAtPathForRouteNamed:@"load_human" object:user parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *blockMappingResult) {
        mappingResult = blockMappingResult;
    } failure:nil];
    
    expect(mappingResult).willNot.beNil();
    RKTestUser *anotherUser = [mappingResult firstObject];
    expect(anotherUser).notTo.equal(user);
    expect(anotherUser.name).to.equal(@"Blake Watters");
    expect(anotherUser.position).to.beNil;
}

- (void)testMappingMetadataQueryParametersByRelationship
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    managedObjectStore.managedObjectCache = managedObjectCache;
    
    NSManagedObject *post = [NSEntityDescription insertNewObjectForEntityForName:@"Post" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    [post setValue:@"The Post" forKey:@"title"];
    [post setValue:@(1234) forKey:@"postID"];
    
    RKEntityMapping *tagMapping = [RKEntityMapping mappingForEntityForName:@"Tag" inManagedObjectStore:managedObjectStore];
    [tagMapping addAttributeMappingsFromDictionary:@{ @"@metadata.routing.parameters.postID": @"postID", @"@metadata.query.parameters.name": @"name" }];
    [tagMapping addConnectionForRelationship:@"posts" connectedBy:@{ @"postID": @"postID" }];
    
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:tagMapping method:RKRequestMethodAny pathPattern:@"/posts/:postID/tags" keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    [objectManager addResponseDescriptor:responseDescriptor];
    [objectManager.router.routeSet addRoute:[RKRoute routeWithRelationshipName:@"tags" objectClass:[RKPost class] pathPattern:@"/posts/:postID/tags" method:RKRequestMethodGET]];
    __block RKMappingResult *mappingResult = nil;
    [objectManager getObjectsAtPathForRelationship:@"tags" ofObject:post parameters:@{ @"name" : @"injectName" } success:^(RKObjectRequestOperation *operation, RKMappingResult *blockMappingResult) {
        mappingResult = blockMappingResult;
    } failure:nil];
    expect(mappingResult).willNot.beNil();
    NSArray *tags = [mappingResult array];
    expect(tags).notTo.beNil();
    NSArray *tagNames = @[@"injectName", @"injectName"];
    expect([tags valueForKey:@"name"]).to.equal(tagNames);
    NSSet *connectedTags = [post valueForKey:@"tags"];
    expect(connectedTags).notTo.beEmpty();
}

- (void)testMappingMetadataQueryParametersByRelationshipNoneSupplied
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    managedObjectStore.managedObjectCache = managedObjectCache;
    
    NSManagedObject *post = [NSEntityDescription insertNewObjectForEntityForName:@"Post" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    [post setValue:@"The Post" forKey:@"title"];
    [post setValue:@(1234) forKey:@"postID"];
    
    RKEntityMapping *tagMapping = [RKEntityMapping mappingForEntityForName:@"Tag" inManagedObjectStore:managedObjectStore];
    [tagMapping addAttributeMappingsFromDictionary:@{ @"@metadata.routing.parameters.postID": @"postID", @"@metadata.query.parameters.name": @"name" }];
    [tagMapping addConnectionForRelationship:@"posts" connectedBy:@{ @"postID": @"postID" }];
    
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:tagMapping method:RKRequestMethodAny pathPattern:@"/posts/:postID/tags" keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    [objectManager addResponseDescriptor:responseDescriptor];
    [objectManager.router.routeSet addRoute:[RKRoute routeWithRelationshipName:@"tags" objectClass:[RKPost class] pathPattern:@"/posts/:postID/tags" method:RKRequestMethodGET]];
    __block RKMappingResult *mappingResult = nil;
    [objectManager getObjectsAtPathForRelationship:@"tags" ofObject:post parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *blockMappingResult) {
        mappingResult = blockMappingResult;
    } failure:nil];
    expect(mappingResult).willNot.beNil();
    NSArray *tags = [mappingResult array];
    expect(tags).notTo.beNil();
    expect([tags valueForKey:@"name"]).to.beNil;
    NSSet *connectedTags = [post valueForKey:@"tags"];
    expect(connectedTags).notTo.beEmpty();
}

- (void)testRoutingMetadataWithAppropriateObjectRequestOperation
{
    NSManagedObjectContext *managedObjectContext = [[RKTestFactory managedObjectStore] persistentStoreManagedObjectContext];
    RKHuman *temporaryHuman = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectContext withProperties:nil];
    temporaryHuman.name = @"My Name";
    temporaryHuman.railsID = @(12345);
    RKManagedObjectRequestOperation *operation = [_objectManager appropriateObjectRequestOperationWithObject:temporaryHuman method:RKRequestMethodDELETE path:nil parameters:nil];
    expect([operation.mappingMetadata valueForKeyPath:@"routing.parameters.railsID"]).to.equal(@"12345");
}

- (void)testThatNoCrashOccursWhenLoadingNamedRouteWithNilObject
{
    RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:[RKTestFactory baseURL]];
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [objectManager.router.routeSet addRoute:[RKRoute routeWithName:@"named_route" pathPattern:@"/JSON/humans/1.json" method:RKRequestMethodGET]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"human" statusCodes:[NSIndexSet indexSetWithIndex:200]];
    [objectManager addResponseDescriptor:responseDescriptor];
    
    __block RKMappingResult *mappingResult = nil;
    [objectManager getObjectsAtPathForRouteNamed:@"named_route" object:nil parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *blockMappingResult) {
        mappingResult = blockMappingResult;
    } failure:nil];
    
    expect(mappingResult).willNot.beNil();
}

- (void)testUseOfMetadataMappingAsIdentificationAttribute
{
    RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:[RKTestFactory baseURL]];
    objectManager.managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:objectManager.managedObjectStore];
    [humanMapping addAttributeMappingsFromDictionary:@{ @"name": @"name", @"@metadata.routing.parameters.railsID": @"favoriteCatID" }];
    [humanMapping setIdentificationAttributes:@[ @"favoriteCatID" ]];
    [objectManager.router.routeSet addRoute:[RKRoute routeWithName:@"load_human" pathPattern:@"/JSON/humans/:railsID\\.json" method:RKRequestMethodGET]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:humanMapping method:RKRequestMethodAny pathPattern:@"/JSON/humans/:railsID\\.json" keyPath:@"human" statusCodes:[NSIndexSet indexSetWithIndex:200]];
    [objectManager addResponseDescriptor:responseDescriptor];
    
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:objectManager.managedObjectStore.mainQueueManagedObjectContext];
    human.railsID = @1;
    __block RKMappingResult *mappingResult = nil;
    [objectManager getObjectsAtPathForRouteNamed:@"load_human" object:human parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *blockMappingResult) {
        mappingResult = blockMappingResult;
    } failure:nil];
    
    expect(mappingResult).willNot.beNil();
    RKHuman *anotherHuman = [mappingResult firstObject];
    expect(anotherHuman.name).to.equal(@"Blake Watters");
    expect(anotherHuman.favoriteCatID).to.equal(@1);
    expect([anotherHuman isEqual:human]).to.beFalsy();
}

- (void)testThatPostingAnArrayOfObjectsThatWereManuallyCreatedDoesNotResultInTheCreationOfDuplicatedObjects
{
    RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:[RKTestFactory baseURL]];
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKInMemoryManagedObjectCache *inMemoryCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    managedObjectStore.managedObjectCache = inMemoryCache;
    objectManager.managedObjectStore = managedObjectStore;
    
    NSManagedObject *developmentTag = [NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    [developmentTag setValue:@"development" forKey:@"name"];
    NSManagedObject *restKitTag = [NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    [restKitTag setValue:@"restkit" forKey:@"name"];
    [managedObjectStore.mainQueueManagedObjectContext saveToPersistentStore:nil];
    
    RKEntityMapping *tagMapping = [RKEntityMapping mappingForEntityForName:@"Tag" inManagedObjectStore:managedObjectStore];
    tagMapping.identificationAttributes = @[ @"name" ];
    [tagMapping addAttributeMappingsFromArray:@[ @"name" ]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:tagMapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:nil];
    [objectManager addResponseDescriptor:responseDescriptor];
    RKObjectMapping *requestMapping = [RKObjectMapping requestMapping];
    [requestMapping addAttributeMappingsFromArray:@[ @"name" ]];
    RKRequestDescriptor *requestDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:requestMapping objectClass:[NSManagedObject class] rootKeyPath:nil method:RKRequestMethodAny];
    [objectManager addRequestDescriptor:requestDescriptor];
    
    __block RKMappingResult *mappingResult = nil;
    NSArray *tags = @[ developmentTag, restKitTag ];
    [objectManager postObject:tags path:@"/tags" parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *blockMappingResult) {
        mappingResult = blockMappingResult;
    } failure:nil];
    expect(mappingResult).willNot.beNil();
    NSSet *tagObjectIDs = [NSSet setWithArray:[tags valueForKey:@"objectID"]];
    NSSet *mappedObjectIDs = [NSSet setWithArray:[mappingResult.array valueForKey:@"objectID"]];
    expect(mappedObjectIDs).to.equal(tagObjectIDs);
    NSUInteger tagsCount = [managedObjectStore.mainQueueManagedObjectContext countForEntityForName:@"Tag" predicate:nil error:nil];
    expect(tagsCount).to.equal(2);
}

- (void)testShouldPropagateDeletionsUpToPersistentStore
{
    RKHuman *temporaryHuman = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:[RKTestFactory managedObjectStore].persistentStoreManagedObjectContext withProperties:nil];
    temporaryHuman.name = @"My Name";
    temporaryHuman.railsID = @1;
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    [mapping addAttributeMappingsFromArray:@[@"name"]];
    
    // Save it to ensure the object is persisted before we delete it
    [[RKTestFactory managedObjectStore].persistentStoreManagedObjectContext save:nil];
    
    RKHuman *persistedHuman = (RKHuman *)[[RKTestFactory managedObjectStore].mainQueueManagedObjectContext objectWithID:temporaryHuman.objectID];
    expect(persistedHuman).toNot.beNil();
    
    RKManagedObjectRequestOperation *operation = [self.objectManager appropriateObjectRequestOperationWithObject:persistedHuman method:RKRequestMethodDELETE path:nil parameters:nil];
    operation.managedObjectContext = persistedHuman.managedObjectContext;
    RKFetchRequestManagedObjectCache *cache = [RKFetchRequestManagedObjectCache new];
    operation.managedObjectCache = cache;
    [operation start];
    expect([operation isFinished]).will.beTruthy();
    
    NSError *error = nil;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    NSArray *humans = [[RKTestFactory managedObjectStore].persistentStoreManagedObjectContext executeFetchRequest:fetchRequest error:&error];
    expect(error).to.beNil();
    expect(humans).to.haveCountOf(0);
}

- (void)testPostingAnObjectAndGettingBackOtherObjectsCanConnectRelationsById
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    managedObjectStore.managedObjectCache = managedObjectCache;

    RKEntityMapping *humanEntityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    humanEntityMapping.identificationAttributes = @[ @"railsID" ];
    [humanEntityMapping addAttributeMappingsFromDictionary:@{ @"id": @"railsID", @"catIDs": @"catIDs" }];
    [humanEntityMapping addConnectionForRelationship:@"cats" connectedBy:@{ @"catIDs" : @"railsID" }];

    RKEntityMapping *catEntityMapping = [RKEntityMapping mappingForEntityForName:@"Cat" inManagedObjectStore:managedObjectStore];
    catEntityMapping.identificationAttributes = @[ @"railsID" ];
    [catEntityMapping addAttributeMappingsFromDictionary:@{ @"id": @"railsID" }];

    NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [childContext setParentContext:managedObjectStore.mainQueueManagedObjectContext];
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:childContext];

    RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:[RKTestFactory baseURL]];
    objectManager.managedObjectStore = managedObjectStore;
    [objectManager addResponseDescriptor:[RKResponseDescriptor responseDescriptorWithMapping:humanEntityMapping method:RKRequestMethodAny pathPattern:@"/humans/and_cats" keyPath:@"human" statusCodes:[NSIndexSet indexSetWithIndex:201]]];
    [objectManager addResponseDescriptor:[RKResponseDescriptor responseDescriptorWithMapping:catEntityMapping method:RKRequestMethodAny pathPattern:@"/humans/and_cats" keyPath:@"cats" statusCodes:[NSIndexSet indexSetWithIndex:201]]];
    __block RKMappingResult *mappingResult = nil;

    [objectManager postObject:human path:@"/humans/and_cats" parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *blockMappingResult) {
        mappingResult = blockMappingResult;
    } failure:nil];

    expect(mappingResult).willNot.beNil();
    expect(human.cats).to.haveCountOf(2);
}

- (void)testManagerUsesResponseDescriptorForMethod
{
    RKObjectMapping *mapping1 = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping1 addAttributeMappingsFromArray:@[ @"name" ]];
    RKObjectMapping *mapping2 = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping2 addAttributeMappingsFromArray:@[ @"weight" ]];
    
    RKResponseDescriptor *responseDescriptor1 = [RKResponseDescriptor responseDescriptorWithMapping:mapping1 method:RKRequestMethodPOST pathPattern:@"/user" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    RKResponseDescriptor *responseDescriptor2 = [RKResponseDescriptor responseDescriptorWithMapping:mapping2 method:RKRequestMethodGET pathPattern:@"/user" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    objectManager.requestSerializationMIMEType = RKMIMETypeJSON;
    [objectManager addResponseDescriptorsFromArray:@[responseDescriptor1, responseDescriptor2]];
    
    __block RKTestUser *human;
    [[RKTestFactory objectManager] getObject:nil path:@"/user" parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        human = mappingResult.firstObject;
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        
    }];
    expect(human.name).will.beNil();
    expect(human.weight).will.equal(@131.3);
}

- (void)testThatRequestDescriptorExactMethodMatchFavoredOverRKRequestMethodAny
{
    RKObjectMapping *mapping1 = [RKObjectMapping requestMapping];
    [mapping1 addAttributeMappingsFromArray:@[ @"name" ]];
    RKObjectMapping *mapping2 = [RKObjectMapping requestMapping];
    [mapping2 addAttributeMappingsFromArray:@[ @"age" ]];
    
    RKRequestDescriptor *requestDesriptor1 = [RKRequestDescriptor requestDescriptorWithMapping:mapping1 objectClass:[RKObjectMapperTestModel class] rootKeyPath:nil method:RKRequestMethodAny];
    RKRequestDescriptor *requestDesriptor2 = [RKRequestDescriptor requestDescriptorWithMapping:mapping2 objectClass:[RKObjectMapperTestModel class] rootKeyPath:nil method:RKRequestMethodPOST];
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    objectManager.requestSerializationMIMEType = RKMIMETypeJSON;
    [objectManager addRequestDescriptor:requestDesriptor1];
    [objectManager addRequestDescriptor:requestDesriptor2];
    
    RKObjectMapperTestModel *model = [RKObjectMapperTestModel new];
    model.name = @"Blake";
    model.age = @30;
    NSURLRequest *request = [objectManager requestWithObject:model method:RKRequestMethodPOST path:@"/path" parameters:nil];
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:request.HTTPBody options:0 error:nil];
    expect(dictionary).to.equal(@{ @"age": @(30) });
}

- (void)testThatResponseDescriptorExactMethodMatchFavoredOverRKRequestMethodAny
{
    RKObjectMapping *mapping1 = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping1 addAttributeMappingsFromArray:@[ @"name" ]];
    RKObjectMapping *mapping2 = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [mapping2 addAttributeMappingsFromArray:@[ @"weight" ]];
    
    RKResponseDescriptor *responseDescriptor2 = [RKResponseDescriptor responseDescriptorWithMapping:mapping2 method:RKRequestMethodGET pathPattern:@"/user" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    RKResponseDescriptor *responseDescriptor1 = [RKResponseDescriptor responseDescriptorWithMapping:mapping1 method:RKRequestMethodAny pathPattern:@"/user" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    objectManager.requestSerializationMIMEType = RKMIMETypeJSON;
    [objectManager addResponseDescriptorsFromArray:@[responseDescriptor1, responseDescriptor2]];
    
    __block RKTestUser *human;
    [[RKTestFactory objectManager] getObject:nil path:@"/user" parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        human = mappingResult.firstObject;
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        
    }];
    expect(human.name).will.beNil();
    expect(human.weight).will.equal(@131.3);
}

@end

@interface RKObjectManagerNonCoreDataTest: RKTestCase
@property (nonatomic, strong) RKObjectManager *objectManager;

@property (nonatomic, strong) RKResponseDescriptor *addressResponseDescriptor;
@property (nonatomic, strong) RKResponseDescriptor *coordinateResponseDescriptor;

@end

@implementation RKObjectManagerNonCoreDataTest

-(void)setUp{
    [RKTestFactory setUp];
    self.objectManager = [RKTestFactory objectManager];
    [RKObjectManager setSharedManager:self.objectManager];
    
    RKObjectMapping *addressMapping = [RKObjectMapping mappingForClass:[RKTestAddress class]];
    [addressMapping addAttributeMappingsFromArray:@[@"addressID", @"city", @"state", @"country"]];
    
    RKObjectMapping *coordinateMapping = [RKObjectMapping mappingForClass:[RKTestCoordinate class]];
    [coordinateMapping addAttributeMappingsFromArray:@[@""]];
    
    self.addressResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:addressMapping method:RKRequestMethodGET pathPattern:@"address" keyPath:@"address" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    self.coordinateResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:coordinateMapping method:RKRequestMethodPOST pathPattern:@"coordinate" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
 
    [self.objectManager.router.routeSet addRoute:[RKRoute routeWithClass:[RKTestCoordinate class] pathPattern:@"coordinate" method:RKRequestMethodPOST]];
    [self.objectManager addResponseDescriptorsFromArray:@[self.addressResponseDescriptor, self.coordinateResponseDescriptor]];
}

-(void)tearDown{
    [RKTestFactory tearDown];
}

-(void)testThatAppropriateObjectRequestOperationOnlyContainsResponseDescriptorsThatMatchObjectAndMethod{
    RKTestCoordinate *coordinate = [RKTestCoordinate new];
    RKObjectRequestOperation *operation = [self.objectManager appropriateObjectRequestOperationWithObject:coordinate method:RKRequestMethodPOST path:@"coordinate" parameters:nil];
    expect(operation.responseDescriptors.count).to.equal(1);
    expect(operation.responseDescriptors[0]).to.equal(self.coordinateResponseDescriptor);
}

-(void)testThatAppropriateObjectRequestOperationOnlyContainsResponseDescriptorsThatMatchPahtAndMethod{
    RKObjectRequestOperation *operation = [self.objectManager appropriateObjectRequestOperationWithObject:nil method:RKRequestMethodGET path:@"address" parameters:nil];
    expect(operation.responseDescriptors.count).to.equal(1);
    expect(operation.responseDescriptors[0]).to.equal(self.addressResponseDescriptor);
}


@end

RKRequestDescriptor *RKRequestDescriptorFromArrayMatchingObjectAndRequestMethod(NSArray *requestDescriptors, id object, RKRequestMethod requestMethod);

@interface RKRequestDescriptorFromArrayMatchingObjectAndRequestMethodTest : RKTestCase

@property (nonatomic, strong) RKRequestDescriptor *exactClassAndExactMethodDescriptor;
@property (nonatomic, strong) RKRequestDescriptor *exactClassAndBitwiseMethodDescriptor;
@property (nonatomic, strong) RKRequestDescriptor *superclassAndExactMethodDescriptor;
@property (nonatomic, strong) RKRequestDescriptor *superclassAndBitwiseMethodDescriptor;
@property (nonatomic, strong) RKRequestDescriptor *nonMatchingClassAndExactMethodDescriptor;
@end

@implementation RKRequestDescriptorFromArrayMatchingObjectAndRequestMethodTest

- (void)setUp
{
    RKObjectMapping *requestMapping = [RKObjectMapping requestMapping];
    
    // Exact
    _exactClassAndExactMethodDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:requestMapping objectClass:[RKSubclassedTestModel class] rootKeyPath:nil method:RKRequestMethodPOST];
    _exactClassAndBitwiseMethodDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:requestMapping objectClass:[RKSubclassedTestModel class] rootKeyPath:nil method:RKRequestMethodPOST | RKRequestMethodPUT];
    
    // Superclass
    _superclassAndExactMethodDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:requestMapping objectClass:[RKObjectMapperTestModel class] rootKeyPath:@"superclass" method:RKRequestMethodPOST];
    _superclassAndBitwiseMethodDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:requestMapping objectClass:[RKObjectMapperTestModel class] rootKeyPath:@"superclass" method:RKRequestMethodPOST | RKRequestMethodPUT];
    
    // Non-matching
    _nonMatchingClassAndExactMethodDescriptor = [RKRequestDescriptor requestDescriptorWithMapping:requestMapping objectClass:[RKTestUser class] rootKeyPath:@"subclassed" method:RKRequestMethodPOST];
}

- (void)testExactClassAndExactMethodMatchHasHighestPrecedence
{    
    RKSubclassedTestModel *object = [RKSubclassedTestModel new];
    NSArray *descriptors = @[ _exactClassAndExactMethodDescriptor, _exactClassAndBitwiseMethodDescriptor, _superclassAndExactMethodDescriptor, _superclassAndBitwiseMethodDescriptor,  _nonMatchingClassAndExactMethodDescriptor ];
    RKRequestDescriptor *requestDescriptor = RKRequestDescriptorFromArrayMatchingObjectAndRequestMethod(descriptors, object, RKRequestMethodPOST);
    expect(requestDescriptor).to.equal(_exactClassAndExactMethodDescriptor);
}

- (void)testExactClassAndBitwiseMethodMatchHasSecondHighestPrecedence
{
    RKSubclassedTestModel *object = [RKSubclassedTestModel new];
    NSArray *descriptors = @[ _exactClassAndBitwiseMethodDescriptor, _superclassAndExactMethodDescriptor, _superclassAndBitwiseMethodDescriptor,  _nonMatchingClassAndExactMethodDescriptor ];
    RKRequestDescriptor *requestDescriptor = RKRequestDescriptorFromArrayMatchingObjectAndRequestMethod(descriptors, object, RKRequestMethodPOST);
    expect(requestDescriptor).to.equal(_exactClassAndBitwiseMethodDescriptor);
}

- (void)testSuperclassAndExactMethodMatchHasThirdHighestPrecedence
{
    RKSubclassedTestModel *object = [RKSubclassedTestModel new];
    NSArray *descriptors = @[ _superclassAndExactMethodDescriptor, _superclassAndBitwiseMethodDescriptor,  _nonMatchingClassAndExactMethodDescriptor ];
    RKRequestDescriptor *requestDescriptor = RKRequestDescriptorFromArrayMatchingObjectAndRequestMethod(descriptors, object, RKRequestMethodPOST);
    expect(requestDescriptor).to.equal(_superclassAndExactMethodDescriptor);
}

- (void)testSuperclassAndBitwiseMethodMatchHasThirdHighestPrecedence
{
    RKSubclassedTestModel *object = [RKSubclassedTestModel new];
    NSArray *descriptors = @[ _superclassAndBitwiseMethodDescriptor,  _nonMatchingClassAndExactMethodDescriptor ];
    RKRequestDescriptor *requestDescriptor = RKRequestDescriptorFromArrayMatchingObjectAndRequestMethod(descriptors, object, RKRequestMethodPOST);
    expect(requestDescriptor).to.equal(_superclassAndBitwiseMethodDescriptor);
}

- (void)testThatNonmatchingClassesReturnNil
{
    RKSubclassedTestModel *object = [RKSubclassedTestModel new];
    NSArray *descriptors = @[ _nonMatchingClassAndExactMethodDescriptor ];
    RKRequestDescriptor *requestDescriptor = RKRequestDescriptorFromArrayMatchingObjectAndRequestMethod(descriptors, object, RKRequestMethodPOST);
    expect(requestDescriptor).to.beNil();
}

@end
