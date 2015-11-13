//
//  RKManagedObjectRequestOperationTest.m
//  RestKit
//
//  Created by Blake Watters on 10/17/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKManagedObjectRequestOperation.h"
#import "RKEntityMapping.h"
#import "RKHuman.h"
#import "RKTestUser.h"
#import "RKTestAddress.h"
#import "RKMappingErrors.h"
#import "RKMappableObject.h"
#import "RKPost.h"

@interface RKManagedObjectRequestOperation ()
@property (nonatomic, readonly, copy) NSArray *fetchRequestsMatchingResponseURL;
@end
NSSet *RKSetByRemovingSubkeypathsFromSet(NSSet *setOfKeyPaths);


@interface RKTestDelegateManagedObjectRequestOperation : RKManagedObjectRequestOperation
@end

@implementation RKTestDelegateManagedObjectRequestOperation

- (void)mapperWillStartMapping:(RKMapperOperation *)mapper
{
    // For stubbing
}

@end

@interface RKTestListOfLists : NSObject
@property (nonatomic, strong) NSArray *listOfLists;
@end
@implementation RKTestListOfLists
@end

///////////////////////////////////////////////////////////////////////////////////////////////

@interface RKManagedObjectRequestOperationTest : RKTestCase

@end

@implementation RKManagedObjectRequestOperationTest

- (void)setUp
{
    [RKTestFactory setUp];
}

- (void)tearDown
{
    [RKTestFactory tearDown];
}

- (void)testThatInitializationWithRequestDefaultsToSavingToPersistentStore
{
    RKObjectManager *manager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:@"http://restkit.org"]];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/whatever" relativeToURL:manager.baseURL]];
    RKManagedObjectRequestOperation *operation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[]];
    expect(operation.savesToPersistentStore).to.equal(YES);
}

- (void)testThatInitializationWithRequestOperationDefaultsToSavingToPersistentStore
{
    RKObjectManager *manager = [RKObjectManager managerWithBaseURL:[NSURL URLWithString:@"http://restkit.org"]];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/whatever" relativeToURL:manager.baseURL]];
    RKHTTPRequestOperation *requestOperation = [[RKHTTPRequestOperation alloc] initWithRequest:request];
    RKManagedObjectRequestOperation *operation = [[RKManagedObjectRequestOperation alloc] initWithHTTPRequestOperation:requestOperation responseDescriptors:@[]];
    expect(operation.savesToPersistentStore).to.equal(YES);
}

- (void)testFetchRequestBlocksAreInvokedWithARelativeURL
{
    NSURL *baseURL = [NSURL URLWithString:@"http://restkit.org/api/v1/"];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"categories/1234" relativeToURL:baseURL]];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:request.URL statusCode:200 HTTPVersion:@"1.1" headerFields:@{}];
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:@"categories/:categoryID" keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    responseDescriptor.baseURL = baseURL;
    id mockRequestOperation = [OCMockObject niceMockForClass:[RKHTTPRequestOperation class]];
    [[[mockRequestOperation stub] andReturn:request] request];
    [[[mockRequestOperation stub] andReturn:response] response];
    RKManagedObjectRequestOperation *operation = [[RKManagedObjectRequestOperation alloc] initWithHTTPRequestOperation:mockRequestOperation responseDescriptors:@[ responseDescriptor ]];
    
    __block NSURL *blockURL = nil;
    RKFetchRequestBlock fetchRequesBlock = ^NSFetchRequest *(NSURL *URL) {
        blockURL = URL;
        return nil;
    };
    
    operation.fetchRequestBlocks = @[fetchRequesBlock];
    [operation fetchRequestsMatchingResponseURL];
    expect(blockURL).notTo.beNil();
    expect([blockURL.baseURL absoluteString]).to.equal(@"http://restkit.org/api/v1/");
    expect(blockURL.relativePath).to.equal(@"categories/1234");
}

- (void)testFetchRequestBlocksDoNotCrash
{
    NSURL *baseURL = [NSURL URLWithString:@"http://restkit.org/api/v1/"];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"categories/1234" relativeToURL:baseURL]];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:request.URL statusCode:200 HTTPVersion:@"1.1" headerFields:@{}];
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:@"categories/:categoryID" keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    responseDescriptor.baseURL = baseURL;
    id mockRequestOperation = [OCMockObject niceMockForClass:[RKHTTPRequestOperation class]];
    [[[mockRequestOperation stub] andReturn:request] request];
    [[[mockRequestOperation stub] andReturn:response] response];
    RKManagedObjectRequestOperation *operation = [[RKManagedObjectRequestOperation alloc] initWithHTTPRequestOperation:mockRequestOperation responseDescriptors:@[ responseDescriptor ]];
    RKFetchRequestBlock fetchRequesBlock = ^NSFetchRequest *(NSURL *URL) {
        return [NSFetchRequest fetchRequestWithEntityName:@"RKHuman"];
    };
    
    operation.fetchRequestBlocks = @[fetchRequesBlock];
    [operation fetchRequestsMatchingResponseURL];
}

- (void)testThatFetchRequestBlocksInvokedWithRelativeURLAreInAgreementWithPathPattern
{
    NSURL *baseURL = [NSURL URLWithString:@"http://restkit.org/api/v1/"];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"library/" relativeToURL:baseURL]];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:request.URL statusCode:200 HTTPVersion:@"1.1" headerFields:@{}];
    expect([request.URL absoluteString]).to.equal(@"http://restkit.org/api/v1/library/");
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:@"library/" keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    responseDescriptor.baseURL = baseURL;
    id mockRequestOperation = [OCMockObject niceMockForClass:[RKHTTPRequestOperation class]];
    [[[mockRequestOperation stub] andReturn:request] request];
    [[[mockRequestOperation stub] andReturn:response] response];
    RKManagedObjectRequestOperation *operation = [[RKManagedObjectRequestOperation alloc] initWithHTTPRequestOperation:mockRequestOperation responseDescriptors:@[ responseDescriptor ]];
    __block NSURL *blockURL = nil;
    RKFetchRequestBlock fetchRequesBlock = ^NSFetchRequest *(NSURL *URL) {
        blockURL = URL;
        return nil;
    };
    
    operation.fetchRequestBlocks = @[fetchRequesBlock];
    [operation fetchRequestsMatchingResponseURL];
    expect(blockURL).notTo.beNil();
    expect([blockURL absoluteString]).to.equal(@"http://restkit.org/api/v1/library/");
    expect([blockURL.baseURL absoluteString]).to.equal(@"http://restkit.org/api/v1/");
    expect(blockURL.relativePath).to.equal(@"library");
    expect(blockURL.relativeString).to.equal(@"library/");
}

- (void)testThatMappingResultContainsObjectsFetchedFromManagedObjectContextTheOperationWasInitializedWith
{
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/humans/all.json" relativeToURL:[RKTestFactory baseURL]]];
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [humanMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"]];
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:humanMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"human" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.mainQueueManagedObjectContext;
    
    [managedObjectRequestOperation start];
    expect([managedObjectRequestOperation isFinished]).will.beTruthy();
    expect(managedObjectRequestOperation.mappingResult).notTo.beNil();
    NSArray *managedObjectContexts = [[managedObjectRequestOperation.mappingResult array] valueForKeyPath:@"@distinctUnionOfObjects.managedObjectContext"];
    expect([managedObjectContexts count]).to.equal(1);
    expect(managedObjectContexts).to.equal(@[managedObjectStore.mainQueueManagedObjectContext]);
}

// 304 'Not Modified'
- (void)testThatManagedObjectsAreFetchedWhenHandlingAResponseThatCanSkipMapping
{
    RKFetchRequestBlock fetchRequestBlock = ^(NSURL *URL){
        return [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    };
    
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/humans/1" relativeToURL:[RKTestFactory baseURL]]];
    
    // Store a cache entry indicating that the response has been previously mapped
    NSData *responseData = [@"{}" dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *headers = @{ @"ETag": @"\"2cdd0a2b329541d81e82ab20aff6281b\"", @"Content-Type": @"application/json" };
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[request URL] statusCode:200 HTTPVersion:@"1.1" headerFields:headers];
    NSAssert(response, @"Failed to build cached response");
    NSCachedURLResponse *cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:response data:responseData userInfo:@{RKResponseHasBeenMappedCacheUserInfoKey: @YES} storagePolicy:NSURLCacheStorageAllowed];
    [[NSURLCache sharedURLCache] storeCachedResponse:cachedResponse forRequest:request];
    
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [humanMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"]];
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:humanMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"human" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
    managedObjectRequestOperation.fetchRequestBlocks = @[fetchRequestBlock];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.mainQueueManagedObjectContext;
    RKFetchRequestManagedObjectCache *cache = [RKFetchRequestManagedObjectCache new];
    managedObjectRequestOperation.managedObjectCache = cache;
    
    [managedObjectRequestOperation start];
    expect([managedObjectRequestOperation isFinished]).will.beTruthy();
    expect(managedObjectRequestOperation.mappingResult).notTo.beNil();
    NSArray *mappedObjects = [managedObjectRequestOperation.mappingResult array];
    expect(mappedObjects).to.haveCountOf(1);
    expect([mappedObjects[0] objectID]).to.equal([human objectID]);
}

// 304 'Not Modified'
- (void)testThatManagedObjectsAreMappedWhenHandlingAResponseThatCanSkipMappingButThereIsNoFetchRequestBlockRegistered
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/humans/1" relativeToURL:[RKTestFactory baseURL]]];
    
    // Store a cache entry indicating that the response has been previously mapped
    NSData *responseData = [@"{ \"name\": \"Blake\"}" dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *headers = @{ @"ETag": @"\"2cdd0a2b329541d81e82ab20aff6281b\"", @"Content-Type": @"application/json" };
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[request URL] statusCode:200 HTTPVersion:@"1.1" headerFields:headers];
    NSAssert(response, @"Failed to build cached response");
    NSCachedURLResponse *cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:response data:responseData userInfo:@{RKResponseHasBeenMappedCacheUserInfoKey: @YES} storagePolicy:NSURLCacheStorageAllowed];
    [[NSURLCache sharedURLCache] storeCachedResponse:cachedResponse forRequest:request];
    
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [humanMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"]];
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:humanMapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.mainQueueManagedObjectContext;
    
    [managedObjectRequestOperation start];
    expect([managedObjectRequestOperation isFinished]).will.beTruthy();
    expect(managedObjectRequestOperation.mappingResult).notTo.beNil();
    NSArray *mappedObjects = [managedObjectRequestOperation.mappingResult array];
    expect(mappedObjects).to.haveCountOf(1);
}

- (void)testThatThe304CanSkipMappingOptimizationIsNotAppliedIfThereIsAMixtureOfEntityAndObjectMappingsMatchingTheResponse
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/humans/1" relativeToURL:[RKTestFactory baseURL]]];

    // Store a cache entry indicating that the response has been previously mapped
    NSData *responseData = [@"{\"human\": { \"name\": \"Blake\"}, \"user\": { \"name\": \"Blake\" }}" dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *headers = @{ @"ETag": @"\"2cdd0a2b329541d81e82ab20aff6281b\"", @"Content-Type": @"application/json" };
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[request URL] statusCode:200 HTTPVersion:@"1.1" headerFields:headers];
    NSAssert(response, @"Failed to build cached response");
    NSCachedURLResponse *cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:response data:responseData userInfo:@{RKResponseHasBeenMappedCacheUserInfoKey: @YES} storagePolicy:NSURLCacheStorageAllowed];
    [[NSURLCache sharedURLCache] storeCachedResponse:cachedResponse forRequest:request];

    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [humanMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:humanMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"human" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];

    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [userMapping addAttributeMappingsFromDictionary:@{ @"name": @"name" }];
    RKResponseDescriptor *userResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"user" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];

    RKFetchRequestBlock fetchRequestBlock = ^(NSURL *URL){
        return [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    };

    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor, userResponseDescriptor ]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.mainQueueManagedObjectContext;
    managedObjectRequestOperation.fetchRequestBlocks = @[ fetchRequestBlock ];

    [managedObjectRequestOperation start];
    expect([managedObjectRequestOperation isFinished]).will.beTruthy();
    expect(managedObjectRequestOperation.mappingResult).notTo.beNil();
    NSArray *mappedObjects = [managedObjectRequestOperation.mappingResult array];
    expect(mappedObjects).notTo.beNil();
    expect(mappedObjects).to.haveCountOf(2);
}

- (void)testThatCachedNotModifiedResponseIsNotUsedWhenMappingFailedToComplete
{
    [[NSURLCache sharedURLCache] removeAllCachedResponses];

    RKFetchRequestBlock fetchRequestBlock = ^(NSURL *URL){
        return [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    };

    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/coredata/etag" relativeToURL:[RKTestFactory baseURL]]];
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [humanMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"]];

    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:humanMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"human" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    RKManagedObjectRequestOperation *initialManagedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
    initialManagedObjectRequestOperation.fetchRequestBlocks = @[fetchRequestBlock];
    initialManagedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    initialManagedObjectRequestOperation.managedObjectCache = managedObjectStore.managedObjectCache;

    // Send our first request in order to generate a cache entry, ensuring mapping is suspended and thus no objects are created in the store
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    [[RKObjectRequestOperation responseMappingQueue] setSuspended:YES];
    [operationQueue addOperation:initialManagedObjectRequestOperation];

    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    [initialManagedObjectRequestOperation cancel];

    expect(initialManagedObjectRequestOperation.isCancelled).to.beTruthy();
    expect([[NSURLCache sharedURLCache] cachedResponseForRequest:request]).toNot.beNil();
    expect(initialManagedObjectRequestOperation.mappingResult).to.beNil();

    // Now setup and send our second request
    [[RKObjectRequestOperation responseMappingQueue] setSuspended:NO];
    RKManagedObjectRequestOperation *secondManagedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
    secondManagedObjectRequestOperation.fetchRequestBlocks = @[fetchRequestBlock];
    secondManagedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    secondManagedObjectRequestOperation.managedObjectCache = managedObjectStore.managedObjectCache;

    [operationQueue addOperation:secondManagedObjectRequestOperation];
    expect([secondManagedObjectRequestOperation isFinished]).will.beTruthy();
    expect(secondManagedObjectRequestOperation.mappingResult).notTo.beNil();
    NSArray *mappedObjects = [secondManagedObjectRequestOperation.mappingResult array];
    expect(mappedObjects).to.haveCountOf(2);
}

- (void)testThatInvalidObjectFailingManagedObjectContextSaveFailsOperation
{
    // NOTE: The model defines a maximum length of 15 for the 'name' attribute
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKHuman *human = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:nil withProperties:nil];
    human.name = @"This Is An Invalid Name Because It Exceeds Fifteen Characters";
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/humans/all.json" relativeToURL:[RKTestFactory baseURL]]];
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [humanMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"]];
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:humanMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"human" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.mainQueueManagedObjectContext;
    
    [managedObjectRequestOperation start];
    expect([managedObjectRequestOperation isFinished]).will.beTruthy();
    expect(managedObjectRequestOperation.error).notTo.beNil();
    expect(managedObjectRequestOperation.mappingResult).to.beNil();
    #if __IPHONE_OS_VERSION_MIN_REQUIRED
    expect([managedObjectRequestOperation.error localizedDescription]).to.equal(@"The operation couldn’t be completed. (Cocoa error 1660.)");
    #else
    expect([managedObjectRequestOperation.error localizedDescription]).to.equal(@"name is too long.");
    #endif
}

#pragma mark - Deletion Response Tests

// 204 application/json
- (void)testDeletionOfObjectWith204ResponseTriggersObjectDeletion
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKHuman *human = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext withProperties:nil];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/humans/204" relativeToURL:[RKTestFactory baseURL]]];
    request.HTTPMethod = @"DELETE";
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    managedObjectRequestOperation.targetObject = human;
    [managedObjectRequestOperation start];
    [managedObjectRequestOperation waitUntilFinished];
    expect(managedObjectRequestOperation.error).to.beNil();
    expect([human hasBeenDeleted]).to.equal(YES);
}

// 200 application/json ""
- (void)testDeletionOfObjectWithZeroLengthResponseTriggersObjectDeletion
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKHuman *human = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext withProperties:nil];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/humans/empty" relativeToURL:[RKTestFactory baseURL]]];
    request.HTTPMethod = @"DELETE";
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    managedObjectRequestOperation.targetObject = human;
    [managedObjectRequestOperation start];
    [managedObjectRequestOperation waitUntilFinished];
    expect(managedObjectRequestOperation.error).to.beNil();
    expect([human hasBeenDeleted]).to.equal(YES);
}

// 200 application/json "{}"
- (void)testDeletionOfObjectWithEmptyDictionaryResponseTriggersObjectDeletion
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKHuman *human = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext withProperties:nil];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/humans/1" relativeToURL:[RKTestFactory baseURL]]];
    request.HTTPMethod = @"DELETE";
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    managedObjectRequestOperation.targetObject = human;
    [managedObjectRequestOperation start];
    [managedObjectRequestOperation waitUntilFinished];
    expect(managedObjectRequestOperation.error).to.beNil();
    expect([human hasBeenDeleted]).to.equal(YES);
}

// 200 application/json { "human": { "status": "OK" } }
- (void)testDeletionOfObjectWithUnmappedResponseBody
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [humanMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:humanMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"human" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];

    RKHuman *human = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext withProperties:nil];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/humans/success" relativeToURL:[RKTestFactory baseURL]]];
    request.HTTPMethod = @"DELETE";
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    managedObjectRequestOperation.targetObject = human;
    [managedObjectRequestOperation start];
    [managedObjectRequestOperation waitUntilFinished];
    expect(managedObjectRequestOperation.error).to.beNil();
    expect([human hasBeenDeleted]).to.equal(YES);
}

// 200 application/json { "human": { "status": "OK" } }
- (void)testDeletionOfObjectWithResponseDescriptorMappingResponseByURL
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [entityMapping addAttributeMappingsFromDictionary:@{ @"human.status" : @"name" }];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:entityMapping method:RKRequestMethodAny pathPattern:@"/humans/success" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    RKHuman *human = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext withProperties:nil];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/humans/success" relativeToURL:[RKTestFactory baseURL]]];
    request.HTTPMethod = @"DELETE";
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    managedObjectRequestOperation.targetObject = human;
    [managedObjectRequestOperation start];
    [managedObjectRequestOperation waitUntilFinished];
    expect(managedObjectRequestOperation.error).to.beNil();
    expect([human hasBeenDeleted]).to.equal(YES);
}

// 200 application/json { "human": { "status": "OK" } }
- (void)testDeletionOfObjectWithResponseDescriptorMappingResponseByKeyPath
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [entityMapping addAttributeMappingsFromDictionary:@{ @"status" : @"name" }];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:entityMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"human" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    RKHuman *human = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext withProperties:nil];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/humans/success" relativeToURL:[RKTestFactory baseURL]]];
    request.HTTPMethod = @"DELETE";
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    managedObjectRequestOperation.targetObject = human;
    [managedObjectRequestOperation start];
    [managedObjectRequestOperation waitUntilFinished];
    expect(managedObjectRequestOperation.error).to.beNil();
    expect([human hasBeenDeleted]).to.equal(YES);
}

- (void)testThatDeletionOfObjectThatHasAlreadyBeenDeletedFromCoreDataDoesNotRaiseException
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [humanMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:humanMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"human" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];

    RKHuman *human = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext withProperties:nil];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/humans/success" relativeToURL:[RKTestFactory baseURL]]];
    request.HTTPMethod = @"DELETE";
    [managedObjectStore.persistentStoreManagedObjectContext saveToPersistentStore:nil];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    managedObjectRequestOperation.targetObject = human;
    [managedObjectRequestOperation start];
    [managedObjectRequestOperation waitUntilFinished];
    expect(managedObjectRequestOperation.error).to.beNil();
    expect([human hasBeenDeleted]).to.equal(YES);
}

// 404 application/json
- (void)testDeletionOfObjectWith404ResponseTriggersObjectDeletion
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKHuman *human = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext withProperties:nil];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/humans/404" relativeToURL:[RKTestFactory baseURL]]];
    request.HTTPMethod = @"DELETE";
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    managedObjectRequestOperation.targetObject = human;
    [managedObjectRequestOperation start];
    [managedObjectRequestOperation waitUntilFinished];
    expect(managedObjectRequestOperation.error).to.beNil();
    expect([human hasBeenDeleted]).to.equal(YES);
}

// 410 application/json
- (void)testDeletionOfObjectWith410ResponseTriggersObjectDeletion
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKHuman *human = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext withProperties:nil];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/humans/410" relativeToURL:[RKTestFactory baseURL]]];
    request.HTTPMethod = @"DELETE";
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    managedObjectRequestOperation.targetObject = human;
    [managedObjectRequestOperation start];
    [managedObjectRequestOperation waitUntilFinished];
    expect(managedObjectRequestOperation.error).to.beNil();
    expect([human hasBeenDeleted]).to.equal(YES);
}

#pragma mark -

- (void)testThatManagedObjectMappedAsTheRelationshipOfNonManagedObjectsAreRefetchedFromTheParentContext
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [entityMapping addAttributeMappingsFromArray:@[ @"name" ]];
    [userMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"favorite_cat" toKeyPath:@"friends" withMapping:entityMapping]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"human" statusCodes:[NSIndexSet indexSetWithIndex:200]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/humans/with_to_one_relationship.json" relativeToURL:[RKTestFactory baseURL]]];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.mainQueueManagedObjectContext;
    [managedObjectRequestOperation start];
    expect([managedObjectRequestOperation isFinished]).will.beTruthy();
    expect(managedObjectRequestOperation.error).to.beNil();
    expect([managedObjectRequestOperation.mappingResult array]).to.haveCountOf(1);
    RKTestUser *testUser = [managedObjectRequestOperation.mappingResult firstObject];
    expect([[testUser.friends lastObject] managedObjectContext]).to.equal(managedObjectStore.mainQueueManagedObjectContext);
}

- (void)testThatManagedObjectMappedAsTheRelationshipOfNonManagedObjectsWithADynamicMappingAreRefetchedFromTheParentContext
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [entityMapping addAttributeMappingsFromArray:@[ @"name" ]];
    [userMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"favorite_cat" toKeyPath:@"friends" withMapping:entityMapping]];
    
    RKObjectMapping *addressMapping = [RKObjectMapping mappingForClass:[RKTestAddress class]];
    [addressMapping addAttributeMappingsFromDictionary:@{ @"name": @"city" }];    
    
    RKDynamicMapping *dynamicMapping = [RKDynamicMapping new];
    [dynamicMapping addMatcher:[RKObjectMappingMatcher matcherWithKeyPath:@"name" expectedValue:@"Blake Watters" objectMapping:userMapping]];
    [dynamicMapping addMatcher:[RKObjectMappingMatcher matcherWithKeyPath:@"name" expectedValue:@"Other" objectMapping:addressMapping]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:dynamicMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"human" statusCodes:[NSIndexSet indexSetWithIndex:200]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/humans/all.json" relativeToURL:[RKTestFactory baseURL]]];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    [managedObjectRequestOperation start];
    [managedObjectRequestOperation waitUntilFinished];
    expect(managedObjectRequestOperation.error).to.beNil();
    expect([managedObjectRequestOperation.mappingResult array]).to.haveCountOf(2);
    RKTestUser *testUser = [managedObjectRequestOperation.mappingResult firstObject];
    expect([[testUser.friends lastObject] managedObjectContext]).to.equal(managedObjectStore.persistentStoreManagedObjectContext);
}

- (void)testThatManagedObjectMappedFromRootKeyPathAreRefetchedFromTheParentContext
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [entityMapping addAttributeMappingsFromDictionary:@{ @"human.name": @"name" }];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:entityMapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/humans/with_to_one_relationship.json" relativeToURL:[RKTestFactory baseURL]]];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    [managedObjectRequestOperation start];
    [managedObjectRequestOperation waitUntilFinished];
    expect(managedObjectRequestOperation.error).to.beNil();
    expect([managedObjectRequestOperation.mappingResult array]).to.haveCountOf(1);
    NSManagedObject *managedObject = [managedObjectRequestOperation.mappingResult firstObject];
    expect([managedObject managedObjectContext]).to.equal(managedObjectStore.persistentStoreManagedObjectContext);
}

- (void)testThatManagedObjectMappedToNSSetRelationshipOfNonManagedObjectsAreRefetchedFromTheParentContext
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [entityMapping addAttributeMappingsFromArray:@[ @"name" ]];
    [userMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"favorite_cat" toKeyPath:@"friendsSet" withMapping:entityMapping]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"human" statusCodes:[NSIndexSet indexSetWithIndex:200]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/humans/with_to_one_relationship.json" relativeToURL:[RKTestFactory baseURL]]];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    [managedObjectRequestOperation start];
    [managedObjectRequestOperation waitUntilFinished];
    expect(managedObjectRequestOperation.error).to.beNil();
    expect([managedObjectRequestOperation.mappingResult array]).to.haveCountOf(1);
    RKTestUser *testUser = [managedObjectRequestOperation.mappingResult firstObject];
    expect([[testUser.friendsSet anyObject] managedObjectContext]).to.equal(managedObjectStore.persistentStoreManagedObjectContext);
}

- (void)testThatManagedObjectMappedToNSOrderedSetRelationshipOfNonManagedObjectsAreRefetchedFromTheParentContext
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [entityMapping addAttributeMappingsFromArray:@[ @"name" ]];
    [userMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"favorite_cat" toKeyPath:@"friendsOrderedSet" withMapping:entityMapping]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"human" statusCodes:[NSIndexSet indexSetWithIndex:200]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/humans/with_to_one_relationship.json" relativeToURL:[RKTestFactory baseURL]]];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    [managedObjectRequestOperation start];
    [managedObjectRequestOperation waitUntilFinished];
    expect(managedObjectRequestOperation.error).to.beNil();
    expect([managedObjectRequestOperation.mappingResult array]).to.haveCountOf(1);
    RKTestUser *testUser = [managedObjectRequestOperation.mappingResult firstObject];
    expect([[testUser.friendsOrderedSet firstObject] managedObjectContext]).to.equal(managedObjectStore.persistentStoreManagedObjectContext);
}

- (void)testMappingRespectsTargetObjectWhenMappingNonManagedThatIncludesChildManagedObject
{
    RKTestUser *testUser = [RKTestUser new];
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [entityMapping addAttributeMappingsFromArray:@[ @"name" ]];
    [userMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"favorite_cat" toKeyPath:@"friendsOrderedSet" withMapping:entityMapping]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"human" statusCodes:[NSIndexSet indexSetWithIndex:200]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/humans/with_to_one_relationship.json" relativeToURL:[RKTestFactory baseURL]]];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    managedObjectRequestOperation.targetObject = testUser;
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    [managedObjectRequestOperation start];
    [managedObjectRequestOperation waitUntilFinished];
    expect(managedObjectRequestOperation.error).to.beNil();
    expect([managedObjectRequestOperation.mappingResult array]).to.haveCountOf(1);
    RKTestUser *mappedTestUser = [managedObjectRequestOperation.mappingResult firstObject];
    expect(mappedTestUser).to.equal(testUser);
}

- (void)testDeletionOfOrphanedManagedObjects
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKHuman *orphanedHuman = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [entityMapping addAttributeMappingsFromArray:@[ @"name" ]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:entityMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"human" statusCodes:[NSIndexSet indexSetWithIndex:200]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/humans/with_to_one_relationship.json" relativeToURL:[RKTestFactory baseURL]]];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    RKFetchRequestBlock fetchRequestBlock = ^NSFetchRequest * (NSURL *URL) {
        return [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    };
    managedObjectRequestOperation.fetchRequestBlocks = @[ fetchRequestBlock ];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    [managedObjectRequestOperation start];
    [managedObjectRequestOperation waitUntilFinished];
    expect(managedObjectRequestOperation.error).to.beNil();
    expect([managedObjectRequestOperation.mappingResult array]).to.haveCountOf(1);
    expect(orphanedHuman.managedObjectContext).to.beNil();
}

- (void)testDeletionOfOrphanedObjectsMappedOnRelationships
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKHuman *orphanedHuman = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [entityMapping addAttributeMappingsFromArray:@[ @"name" ]];
    [userMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"favorite_cat" toKeyPath:@"friends" withMapping:entityMapping]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"human" statusCodes:[NSIndexSet indexSetWithIndex:200]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/humans/with_to_one_relationship.json" relativeToURL:[RKTestFactory baseURL]]];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    RKFetchRequestBlock fetchRequestBlock = ^NSFetchRequest * (NSURL *URL) {
        return [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    };
    managedObjectRequestOperation.fetchRequestBlocks = @[ fetchRequestBlock ];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    [managedObjectRequestOperation start];
    [managedObjectRequestOperation waitUntilFinished];
    expect(managedObjectRequestOperation.error).to.beNil();
    expect([managedObjectRequestOperation.mappingResult array]).to.haveCountOf(1);
    expect(orphanedHuman.managedObjectContext).to.beNil();
}

- (void)testDeletionOfOrphanedTagsOfPosts
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSManagedObject *orphanedTag = [NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    [orphanedTag setValue:@"orphaned" forKey:@"name"];
    RKEntityMapping *postMapping = [RKEntityMapping mappingForEntityForName:@"Post" inManagedObjectStore:managedObjectStore];
    [postMapping addAttributeMappingsFromArray:@[ @"title", @"body" ]];
    RKEntityMapping *tagMapping = [RKEntityMapping mappingForEntityForName:@"Tag" inManagedObjectStore:managedObjectStore];
    [tagMapping addAttributeMappingsFromArray:@[ @"name" ]];
    [postMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"tags" toKeyPath:@"tags" withMapping:tagMapping]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:postMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"posts" statusCodes:[NSIndexSet indexSetWithIndex:200]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/posts.json" relativeToURL:[RKTestFactory baseURL]]];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    RKFetchRequestBlock fetchRequestBlock = ^NSFetchRequest * (NSURL *URL) {
        return [NSFetchRequest fetchRequestWithEntityName:@"Tag"];
    };
    managedObjectRequestOperation.fetchRequestBlocks = @[ fetchRequestBlock ];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    [managedObjectRequestOperation start];
    [managedObjectRequestOperation waitUntilFinished];
    expect(managedObjectRequestOperation.error).to.beNil();
    expect([managedObjectRequestOperation.mappingResult array]).to.haveCountOf(1);
    expect(orphanedTag.managedObjectContext).to.beNil();
    
    // Create 3 tags. Update the post entity so it only points to 2 tags. Tag should be deleted.
    // Create 3 tags. Create another post pointing to one of the tags. Update the post entity so it only points to 2 tags. Tag should be deleted.
}

- (void)testThatDeletionOfOrphanedObjectsCanBeSuppressedByPredicate
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSManagedObject *tagOnDiferentObject = [NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    [tagOnDiferentObject setValue:@"orphaned" forKey:@"name"];
    
    NSManagedObject *otherPost = [NSEntityDescription insertNewObjectForEntityForName:@"Post" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    [otherPost setValue:@"Title" forKey:@"title"];
    [otherPost setValue:[NSSet setWithObject:tagOnDiferentObject]  forKey:@"tags"];
    
    RKEntityMapping *postMapping = [RKEntityMapping mappingForEntityForName:@"Post" inManagedObjectStore:managedObjectStore];
    [postMapping addAttributeMappingsFromArray:@[ @"title", @"body" ]];
    RKEntityMapping *tagMapping = [RKEntityMapping mappingForEntityForName:@"Tag" inManagedObjectStore:managedObjectStore];
    [tagMapping addAttributeMappingsFromArray:@[ @"name" ]];
    [postMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"tags" toKeyPath:@"tags" withMapping:tagMapping]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:postMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"posts" statusCodes:[NSIndexSet indexSetWithIndex:200]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/posts.json" relativeToURL:[RKTestFactory baseURL]]];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    RKFetchRequestBlock fetchRequestBlock = ^NSFetchRequest * (NSURL *URL) {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Tag"];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"posts.@count == 0"];
        return fetchRequest;
    };
    managedObjectRequestOperation.fetchRequestBlocks = @[ fetchRequestBlock ];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    [managedObjectRequestOperation start];
    [managedObjectRequestOperation waitUntilFinished];
    expect(managedObjectRequestOperation.error).to.beNil();
    expect([managedObjectRequestOperation.mappingResult array]).to.haveCountOf(1);
    expect(tagOnDiferentObject.managedObjectContext).notTo.beNil();
}

- (void)testThatObjectsOrphanedByRequestOperationAreDeletedAppropriately
{
    // create tags: development, restkit, orphaned
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    __block NSManagedObject *post = nil;
    __block NSManagedObject *orphanedTag;
    __block NSManagedObject *anotherTag;
    [managedObjectStore.persistentStoreManagedObjectContext performBlockAndWait:^{
        NSManagedObject *developmentTag = [NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
        [developmentTag setValue:@"development" forKey:@"name"];
        NSManagedObject *restkitTag = [NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
        [restkitTag setValue:@"restkit" forKey:@"name"];
        orphanedTag = [NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
        [orphanedTag setValue:@"orphaned" forKey:@"name"];
        
        post = [NSEntityDescription insertNewObjectForEntityForName:@"Post" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
        [post setValue:@"Post Title" forKey:@"title"];
        [post setValue:[NSSet setWithObjects:developmentTag, restkitTag, orphanedTag, nil]  forKey:@"tags"];
        
        anotherTag = [NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
        [anotherTag setValue:@"another" forKey:@"name"];
        NSManagedObject *anotherPost = [NSEntityDescription insertNewObjectForEntityForName:@"Post" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
        [anotherPost setValue:@"Another Post" forKey:@"title"];
        [anotherPost setValue:[NSSet setWithObject:anotherTag] forKey:@"tags"];
        
        [managedObjectStore.persistentStoreManagedObjectContext save:nil];
    }];
    
    RKEntityMapping *postMapping = [RKEntityMapping mappingForEntityForName:@"Post" inManagedObjectStore:managedObjectStore];
    postMapping.identificationAttributes = @[ @"title" ];
    [postMapping addAttributeMappingsFromArray:@[ @"title", @"body" ]];
    RKEntityMapping *tagMapping = [RKEntityMapping mappingForEntityForName:@"Tag" inManagedObjectStore:managedObjectStore];
    tagMapping.identificationAttributes = @[ @"name" ];
    [tagMapping addAttributeMappingsFromArray:@[ @"name" ]];
    [postMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"tags" toKeyPath:@"tags" withMapping:tagMapping]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:postMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"posts" statusCodes:[NSIndexSet indexSetWithIndex:200]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/posts.json" relativeToURL:[RKTestFactory baseURL]]];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    managedObjectRequestOperation.managedObjectCache = managedObjectCache;
    RKFetchRequestBlock fetchRequestBlock = ^NSFetchRequest * (NSURL *URL) {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Tag"];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"posts.@count == 0"];
        return fetchRequest;
    };
    managedObjectRequestOperation.fetchRequestBlocks = @[ fetchRequestBlock ];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    [managedObjectRequestOperation start];
    [managedObjectRequestOperation waitUntilFinished];
    expect(managedObjectRequestOperation.error).to.beNil();
    expect([managedObjectRequestOperation.mappingResult array]).to.haveCountOf(1);
    
    NSSet *tagNames = [post valueForKeyPath:@"tags.name"];
    NSSet *expectedTagNames = [NSSet setWithObjects:@"development", @"restkit", nil ];
    expect(tagNames).to.equal(expectedTagNames);
    
    expect([orphanedTag hasBeenDeleted]).to.equal(YES);
    expect([anotherTag hasBeenDeleted]).to.equal(NO);
}

- (void)testPruningOfSubkeypathsFromSet
{
    NSSet *keyPaths = [NSSet setWithObjects:@"posts", @"posts.tags", @"another", @"something.else.entirely", @"another.this.that", @"somewhere.out.there", @"some.posts", nil];
    NSSet *prunedSet = RKSetByRemovingSubkeypathsFromSet(keyPaths);
    NSSet *expectedSet = [NSSet setWithObjects:@"posts", @"another", @"something.else.entirely", @"somewhere.out.there", @"some.posts", nil];
    expect(prunedSet).to.equal(expectedSet);
}

- (void)testPathVisitationDoesNotRecurseInfinitelyForSelfReferentialMappings
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKHuman *orphanedHuman = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [entityMapping addAttributeMappingsFromArray:@[ @"name" ]];
    [entityMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"friends" toKeyPath:@"friends" withMapping:entityMapping]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:entityMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"human" statusCodes:[NSIndexSet indexSetWithIndex:200]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/humans/with_to_one_relationship.json" relativeToURL:[RKTestFactory baseURL]]];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    RKFetchRequestBlock fetchRequestBlock = ^NSFetchRequest * (NSURL *URL) {
        return [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    };
    managedObjectRequestOperation.fetchRequestBlocks = @[ fetchRequestBlock ];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    managedObjectRequestOperation.managedObjectCache = managedObjectCache;
    [managedObjectRequestOperation start];
    [managedObjectRequestOperation waitUntilFinished];
    expect(managedObjectRequestOperation.error).to.beNil();
    expect([managedObjectRequestOperation.mappingResult array]).to.haveCountOf(1);
    expect(orphanedHuman.managedObjectContext).to.beNil();
}

- (void)testDeletionOfObjectsMappedFindsObjectsMappedBySelfReferentialMappings
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];    
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    entityMapping.identificationAttributes = @[ @"railsID" ];
    [entityMapping addAttributeMappingsFromDictionary:@{ @"name": @"name", @"id": @"railsID" }];
    [entityMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"friends" toKeyPath:@"friends" withMapping:entityMapping]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:entityMapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    
    // Create Blake, Sarah, Colin, Monkey & Orphan
    NSManagedObjectContext *context = managedObjectStore.persistentStoreManagedObjectContext;
    NSUInteger count = [context countForEntityForName:@"Human" predicate:nil error:nil];
    expect(count).to.equal(0);
    RKHuman *blake = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:context withProperties:@{ @"railsID": @(1), @"name": @"Blake" }];
    RKHuman *sarah = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:context withProperties:@{ @"railsID": @(2), @"name": @"Sarah" }];
    RKHuman *monkey = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:context withProperties:@{ @"railsID": @(3), @"name": @"Monkey" }];
    RKHuman *colin = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:context withProperties:@{ @"railsID": @(4), @"name": @"Colin" }];
    RKHuman *orphan = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:context withProperties:@{ @"railsID": @(5), @"name": @"Orphan" }];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/humans/self_referential.json" relativeToURL:[RKTestFactory baseURL]]];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    RKFetchRequestBlock fetchRequestBlock = ^NSFetchRequest * (NSURL *URL) {
        return [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    };
    managedObjectRequestOperation.fetchRequestBlocks = @[ fetchRequestBlock ];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    managedObjectRequestOperation.managedObjectCache = managedObjectCache;
    [managedObjectRequestOperation start];
    [managedObjectRequestOperation waitUntilFinished];
    expect(managedObjectRequestOperation.error).to.beNil();
    expect([managedObjectRequestOperation.mappingResult array]).to.haveCountOf(1);
    
    // Verify that orphan was deleted
    count = [context countForEntityForName:@"Human" predicate:nil error:nil];
    expect(count).to.equal(4);
    
    expect(blake.managedObjectContext).notTo.beNil();
    expect(sarah.managedObjectContext).notTo.beNil();
    expect(monkey.managedObjectContext).notTo.beNil();
    expect(colin.managedObjectContext).notTo.beNil();
    expect(orphan.managedObjectContext).to.beNil();
}

- (void)testDeletionOfObjectsMappedFindsObjectsMappedByNestedSelfReferentialMappings
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *houseMapping = [RKEntityMapping mappingForEntityForName:@"House" inManagedObjectStore:managedObjectStore];
    [houseMapping addAttributeMappingsFromDictionary:@{ @"houseID": @"railsID" }];
    [houseMapping addAttributeMappingsFromArray:@[ @"city", @"state" ]];
    houseMapping.identificationAttributes = @[ @"railsID" ];    
    
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    humanMapping.identificationAttributes = @[ @"railsID" ];
    [humanMapping addAttributeMappingsFromDictionary:@{ @"name": @"name", @"humanID": @"railsID" }];
    [humanMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"roommates" toKeyPath:@"friends" withMapping:humanMapping]];
    [humanMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"landlord" toKeyPath:@"landlord" withMapping:humanMapping]];
    
    [houseMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"owner" toKeyPath:@"owner" withMapping:humanMapping]];
    [houseMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"occupants" toKeyPath:@"occupants" withMapping:humanMapping]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:houseMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"houses" statusCodes:[NSIndexSet indexSetWithIndex:200]];
    
    // Create Blake, Sarah, Colin, Monkey & Orphan
    NSManagedObjectContext *context = managedObjectStore.persistentStoreManagedObjectContext;
    RKHuman *orphan = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:context withProperties:@{ @"railsID": @(5), @"name": @"Orphan" }];
    RKHuman *edward = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:context withProperties:@{ @"railsID": @(4), @"name": @"Edward" }];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/humans/nested_self_referential.json" relativeToURL:[RKTestFactory baseURL]]];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    RKFetchRequestBlock humanFetchRequestBlock = ^NSFetchRequest * (NSURL *URL) {
        return [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    };
    RKFetchRequestBlock houseFetchRequestBlock = ^NSFetchRequest * (NSURL *URL) {
        return [NSFetchRequest fetchRequestWithEntityName:@"House"];
    };
    managedObjectRequestOperation.fetchRequestBlocks = @[ humanFetchRequestBlock, houseFetchRequestBlock ];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    managedObjectRequestOperation.deletesOrphanedObjects = YES;
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    managedObjectRequestOperation.managedObjectCache = managedObjectCache;
    [managedObjectRequestOperation start];
    [managedObjectRequestOperation waitUntilFinished];
    expect(managedObjectRequestOperation.error).to.beNil();
    expect([managedObjectRequestOperation.mappingResult array]).to.haveCountOf(1);
    
    NSUInteger count = [context countForEntityForName:@"Human" predicate:nil error:nil];
    expect(count).to.equal(4);
    
    count = [context countForEntityForName:@"House" predicate:nil error:nil];
    expect(count).to.equal(1);
    
    expect(edward.managedObjectContext).notTo.beNil();
    expect(orphan.managedObjectContext).to.beNil();
}

- (void)testDeletionOfOrphanedObjectsMappedWithCyclicRelationshipThatIsNotSelfReferential
{
    NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel new];
    NSEntityDescription *listEntity = [NSEntityDescription new];
    [listEntity setName:@"List"];
    NSAttributeDescription *listNameAttribute = [NSAttributeDescription new];
    [listNameAttribute setName:@"name"];
    [listNameAttribute setAttributeType:NSStringAttributeType];
    
    NSEntityDescription *authorEntity = [NSEntityDescription new];
    [authorEntity setName:@"Author"];
    NSAttributeDescription *authorNameAttribute = [NSAttributeDescription new];
    [authorNameAttribute setName:@"name"];
    [authorNameAttribute setAttributeType:NSStringAttributeType];
    [authorEntity setProperties:@[ authorNameAttribute ]];
    
    NSEntityDescription *entryEntity = [NSEntityDescription new];
    [entryEntity setName:@"Entry"];    
    NSAttributeDescription *entryNameAttribute = [NSAttributeDescription new];
    [entryNameAttribute setName:@"name"];
    [entryNameAttribute setAttributeType:NSStringAttributeType];
    NSAttributeDescription *entryValueAttribute = [NSAttributeDescription new];
    [entryValueAttribute setName:@"value"];
    [entryValueAttribute setAttributeType:NSStringAttributeType];
    
    // Create relationships
    NSRelationshipDescription *listHasOneAuthorRelationship = [NSRelationshipDescription new];
    [listHasOneAuthorRelationship setName:@"author"];
    [listHasOneAuthorRelationship setDestinationEntity:authorEntity];
    [listHasOneAuthorRelationship setMaxCount:1]; // To One
    
    NSRelationshipDescription *authorHasManyListsRelationship = [NSRelationshipDescription new];
    [authorHasManyListsRelationship setName:@"lists"];
    [authorHasManyListsRelationship setDestinationEntity:listEntity];
    [authorHasManyListsRelationship setMaxCount:0]; // To Many

    [authorHasManyListsRelationship setInverseRelationship:listHasOneAuthorRelationship];
    [listHasOneAuthorRelationship setInverseRelationship:authorHasManyListsRelationship];
    
    NSRelationshipDescription *listHasManyValuesRelationship = [NSRelationshipDescription new];
    [listHasManyValuesRelationship setName:@"entries"];
    [listHasManyValuesRelationship setDestinationEntity:entryEntity];
    [listHasManyValuesRelationship setMaxCount:0]; // To Many
    
    NSRelationshipDescription *entryBelongsToListRelationship = [NSRelationshipDescription new];
    [entryBelongsToListRelationship setName:@"list"];
    [entryBelongsToListRelationship setDestinationEntity:listEntity];
    [entryBelongsToListRelationship setMaxCount:1]; // To One
    [entryBelongsToListRelationship setInverseRelationship:listHasManyValuesRelationship];
    
    [listHasManyValuesRelationship setInverseRelationship:entryBelongsToListRelationship];
    
    NSRelationshipDescription *entryRelatesToOtherListRelationship = [NSRelationshipDescription new];
    [entryRelatesToOtherListRelationship setName:@"relatedList"];
    [entryRelatesToOtherListRelationship setDestinationEntity:listEntity];
    [entryRelatesToOtherListRelationship setMaxCount:1]; // To One
    [entryRelatesToOtherListRelationship setInverseRelationship:listHasManyValuesRelationship];
    
    // Set the properties
    [authorEntity setProperties:@[ authorNameAttribute, authorHasManyListsRelationship ]];
    [listEntity setProperties:@[ listNameAttribute, listHasOneAuthorRelationship, listHasManyValuesRelationship ]];
    [entryEntity setProperties:@[ entryNameAttribute, entryValueAttribute, entryBelongsToListRelationship, entryRelatesToOtherListRelationship ]];
    
    [managedObjectModel setEntities:@[ listEntity, authorEntity, entryEntity ]];
    
    // Configure a Core Data stack for this model
    NSError *error = nil;
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:managedObjectModel];
    [managedObjectStore createPersistentStoreCoordinator];
    [managedObjectStore addInMemoryPersistentStore:&error];
    [managedObjectStore createManagedObjectContexts];
    
    // Create mappings
    RKEntityMapping *listMapping = [[RKEntityMapping alloc] initWithEntity:listEntity];
    listMapping.identificationAttributes = @[ @"name" ];
    [listMapping addAttributeMappingsFromArray:@[ @"name" ]];
    RKEntityMapping *authorMapping = [[RKEntityMapping alloc] initWithEntity:authorEntity];
    authorMapping.identificationAttributes = @[ @"name" ];
    [authorMapping addAttributeMappingsFromArray:@[ @"name" ]];
    RKEntityMapping *entryMapping = [[RKEntityMapping alloc] initWithEntity:entryEntity];
    entryMapping.identificationAttributes = @[ @"name" ];
    [entryMapping addAttributeMappingsFromArray:@[ @"name" ]];
    
    // NOTE: This cyclic mapping should trigger an explosion...
    [entryMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"list"
                                                                                 toKeyPath:@"list"
                                                                               withMapping:listMapping]];
    [entryMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"relatedList"
                                                                                 toKeyPath:@"relatedList"
                                                                               withMapping:listMapping]];
    
    [listMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"author"
                                                                                toKeyPath:@"author"
                                                                              withMapping:authorMapping]];
    
    RKRelationshipMapping *entriesRelationship = [RKRelationshipMapping relationshipMappingFromKeyPath:@"entries"
                                                                                             toKeyPath:@"entries"
                                                                                           withMapping:entryMapping];
    entriesRelationship.assignmentPolicy = RKUnionAssignmentPolicy;
    [listMapping addPropertyMapping:entriesRelationship];
    
    
    RKObjectMapping *listsOfListsMapping = [RKObjectMapping mappingForClass:[RKTestListOfLists class]];
    [listsOfListsMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"lists" toKeyPath:@"listOfLists" withMapping:listMapping]];
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:listsOfListsMapping
                                                                                            method:RKRequestMethodAny
                                                                                       pathPattern:nil
                                                                                           keyPath:nil
                                                                                       statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    // Create an orphaned Author and List
    NSManagedObject *orphanedAuthor = [[NSManagedObject alloc] initWithEntity:authorEntity insertIntoManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    [orphanedAuthor setValue:@"Orphaned Author" forKey:@"name"];
    
    NSManagedObject *orphanedList = [[NSManagedObject alloc] initWithEntity:listEntity insertIntoManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    [orphanedList setValue:@"Orphaned List" forKey:@"name"];
    
    // Create an existing List and Entry to be Unioned onto the result set
    NSManagedObject *existingList = [[NSManagedObject alloc] initWithEntity:listEntity insertIntoManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    [existingList setValue:@"Second List" forKey:@"name"];
    
    NSManagedObject *existingEntry = [[NSManagedObject alloc] initWithEntity:entryEntity insertIntoManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    [existingEntry setValue:@"Existing Entry" forKey:@"name"];
    [existingList setValue:[NSSet setWithObject:existingEntry] forKey:@"entries"];
    
    BOOL success = [managedObjectStore.persistentStoreManagedObjectContext saveToPersistentStore:&error];
    expect(success).to.equal(YES);
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/lists.json" relativeToURL:[RKTestFactory baseURL]]];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    RKFetchRequestBlock listFetchRequestBlock = ^NSFetchRequest * (NSURL *URL) {
        return [NSFetchRequest fetchRequestWithEntityName:@"List"];
    };
    RKFetchRequestBlock authorFetchRequestBlock = ^NSFetchRequest * (NSURL *URL) {
        return [NSFetchRequest fetchRequestWithEntityName:@"Author"];
    };
    RKFetchRequestBlock entryFetchRequestBlock = ^NSFetchRequest * (NSURL *URL) {
        return [NSFetchRequest fetchRequestWithEntityName:@"Entry"];
    };
    managedObjectRequestOperation.fetchRequestBlocks = @[ listFetchRequestBlock, authorFetchRequestBlock, entryFetchRequestBlock ];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    managedObjectRequestOperation.deletesOrphanedObjects = YES;
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    managedObjectRequestOperation.managedObjectCache = managedObjectCache;
    [managedObjectRequestOperation start];
    [managedObjectRequestOperation waitUntilFinished];
    expect(managedObjectRequestOperation.error).to.beNil();
    expect([managedObjectRequestOperation.mappingResult array]).to.haveCountOf(1);
    
    NSManagedObjectContext *managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    NSUInteger count = [managedObjectContext countForEntityForName:@"List" predicate:nil error:nil];
    expect(count).to.equal(3);
    
    count = [managedObjectContext countForEntityForName:@"Entry" predicate:nil error:nil];
    expect(count).to.equal(4);
    
    count = [managedObjectContext countForEntityForName:@"Author" predicate:nil error:nil];
    expect(count).to.equal(2);
    
    // Orphans get deleted
    expect(orphanedAuthor.managedObjectContext).to.beNil();
    expect(orphanedList.managedObjectContext).to.beNil();
    
    // Objects in the results do not
    expect(existingList.managedObjectContext).notTo.beNil();
    expect(existingEntry.managedObjectContext).notTo.beNil();
}

- (void)testMappingWithDynamicMappingContainingIncompatibleEntityMappingsAtSameKeyPath
{
    RKDynamicMapping *dynamicMapping = [RKDynamicMapping new];
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    humanMapping.identificationAttributes = @[ @"railsID" ];
    [humanMapping addAttributeMappingsFromDictionary:@{ @"name": @"name", @"humanID": @"railsID" }];
    [humanMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"roommates" toKeyPath:@"friends" withMapping:humanMapping]];
    
    RKEntityMapping *childMapping = [RKEntityMapping mappingForEntityForName:@"Child" inManagedObjectStore:managedObjectStore];
    RKEntityMapping *parentMapping = [RKEntityMapping mappingForEntityForName:@"Parent" inManagedObjectStore:managedObjectStore];
    parentMapping.identificationAttributes = @[ @"railsID" ];
    [parentMapping addAttributeMappingsFromDictionary:@{ @"name": @"name", @"humanID": @"railsID" }];
    [parentMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"children" toKeyPath:@"children" withMapping:childMapping]];
    
    [dynamicMapping addMatcher:[RKObjectMappingMatcher matcherWithKeyPath:@"invalid" expectedValue:@"whatever" objectMapping:parentMapping]];
    [dynamicMapping addMatcher:[RKObjectMappingMatcher matcherWithKeyPath:@"name" expectedValue:@"Blake" objectMapping:humanMapping]];
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:dynamicMapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/humans/self_referential.json" relativeToURL:[RKTestFactory baseURL]]];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    RKFetchRequestBlock humanFetchRequestBlock = ^NSFetchRequest * (NSURL *URL) {
        return [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    };
    RKFetchRequestBlock parentFetchRequestBlock = ^NSFetchRequest * (NSURL *URL) {
        return [NSFetchRequest fetchRequestWithEntityName:@"Parent"];
    };
    RKFetchRequestBlock childFetchRequestBlock = ^NSFetchRequest * (NSURL *URL) {
        return [NSFetchRequest fetchRequestWithEntityName:@"Child"];
    };
    managedObjectRequestOperation.fetchRequestBlocks = @[ humanFetchRequestBlock, parentFetchRequestBlock, childFetchRequestBlock ];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    managedObjectRequestOperation.deletesOrphanedObjects = YES;
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    managedObjectRequestOperation.managedObjectCache = managedObjectCache;
    [managedObjectRequestOperation start];
    [managedObjectRequestOperation waitUntilFinished];
    expect(managedObjectRequestOperation.error).to.beNil();
    expect([managedObjectRequestOperation.mappingResult array]).to.haveCountOf(1);
}

- (void)testMappingWithDynamicMappingContainingMixedNestedKeyPaths
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    NSManagedObject *orphanedParty = [NSEntityDescription insertNewObjectForEntityForName:@"Party" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];

    RKDynamicMapping *dynamicMapping = [RKDynamicMapping new];
    [dynamicMapping setForceCollectionMapping:YES];

    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    humanMapping.identificationAttributes = @[ @"railsID" ];
    [humanMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"id" toKeyPath:@"railsID"]];

    RKEntityMapping *meetingMapping = [RKEntityMapping mappingForEntityForName:@"Meeting" inManagedObjectStore:managedObjectStore];
    [meetingMapping addAttributeMappingsFromDictionary:@{ @"location": @"location" }];
    [dynamicMapping addMatcher:[RKObjectMappingMatcher matcherWithPredicate:[NSPredicate predicateWithFormat:@"type == 'Meeting'"] objectMapping:meetingMapping]];

    RKEntityMapping *partyMapping = [RKEntityMapping mappingForEntityForName:@"Party" inManagedObjectStore:managedObjectStore];
    [partyMapping addAttributeMappingsFromDictionary:@{ @"summary": @"summary" }];
    [partyMapping addRelationshipMappingWithSourceKeyPath:@"vips" mapping:humanMapping];

    [dynamicMapping addMatcher:[RKObjectMappingMatcher matcherWithPredicate:[NSPredicate predicateWithFormat:@"type == 'Party'"] objectMapping:partyMapping]];

    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:dynamicMapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/NakedEvents.json" relativeToURL:[RKTestFactory baseURL]]];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    RKFetchRequestBlock meetingFetchRequestBlock = ^NSFetchRequest * (NSURL *URL) {
        return [NSFetchRequest fetchRequestWithEntityName:@"Meeting"];
    };
    RKFetchRequestBlock eventFetchRequestBlock = ^NSFetchRequest * (NSURL *URL) {
        return [NSFetchRequest fetchRequestWithEntityName:@"Party"];
    };
    managedObjectRequestOperation.fetchRequestBlocks = @[ meetingFetchRequestBlock, eventFetchRequestBlock ];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    managedObjectRequestOperation.deletesOrphanedObjects = YES; // Test deleting orphaned objects with dynamic mapping.
    RKFetchRequestManagedObjectCache *managedObjectCache = [RKFetchRequestManagedObjectCache new];
    managedObjectRequestOperation.managedObjectCache = managedObjectCache;
    [managedObjectRequestOperation start];
    expect([managedObjectRequestOperation isFinished]).will.beTruthy();
    expect(managedObjectRequestOperation.error).to.beNil();
    expect([managedObjectRequestOperation.mappingResult array]).to.haveCountOf(2);
    expect(orphanedParty.managedObjectContext).to.beNil();
}

- (void)testThatMappingObjectsWithTheSameIdentificationAttributesAcrossTwoObjectRequestOperationConcurrentlyDoesNotCreateDuplicateObjects
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKInMemoryManagedObjectCache *inMemoryCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    managedObjectStore.managedObjectCache = inMemoryCache;
    RKEntityMapping *mapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    mapping.identificationAttributes = @[ @"railsID" ];
    [mapping addAttributeMappingsFromArray:@[ @"name" ]];
    [mapping addAttributeMappingsFromDictionary:@{ @"id": @"railsID" }];
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping method:RKRequestMethodAny pathPattern:nil keyPath:@"human" statusCodes:nil];
    
    NSURL *URL = [NSURL URLWithString:@"humans/1" relativeToURL:[RKTestFactory baseURL]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    
    RKManagedObjectRequestOperation *firstOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    firstOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    firstOperation.managedObjectCache = inMemoryCache;
    RKManagedObjectRequestOperation *secondOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    secondOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    secondOperation.managedObjectCache = inMemoryCache;
    
    NSOperationQueue *operationQueue = [NSOperationQueue new];
    [operationQueue setMaxConcurrentOperationCount:2];
    [operationQueue setSuspended:YES];
    [operationQueue addOperation:firstOperation];
    [operationQueue addOperation:secondOperation];
    
    // Start both operations
    [operationQueue setSuspended:NO];
    [operationQueue waitUntilAllOperationsAreFinished];
    
    // Now pull the count back from the parent context
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"railsID == 1"];
    NSArray *fetchedObjects = [managedObjectStore.persistentStoreManagedObjectContext executeFetchRequest:fetchRequest error:nil];
    expect(fetchedObjects).to.haveCountOf(1);
}

- (void)testManagedObjectRequestOperationCompletesAndIgnoresInvalidObjectsWhenDiscardsInvalidObjectsOnInsertIsYES
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *postMapping = [RKEntityMapping mappingForEntityForName:@"Post" inManagedObjectStore:managedObjectStore];
    postMapping.discardsInvalidObjectsOnInsert = YES;
    [postMapping addAttributeMappingsFromArray:@[ @"title", @"body" ]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:postMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"posts" statusCodes:[NSIndexSet indexSetWithIndex:200]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/posts_with_invalid.json" relativeToURL:[RKTestFactory baseURL]]];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    [managedObjectRequestOperation start];
    [managedObjectRequestOperation waitUntilFinished];
    expect(managedObjectRequestOperation.error).to.beNil();
    NSArray *array = [managedObjectRequestOperation.mappingResult array];
    if ([array count] == 2) {
        // Object shows up in results, but MOC is nil -- indicating it has been deleted.
        expect([array[1] managedObjectContext]).to.beNil();
    } else {
        // iOS 6
        expect(array).to.haveCountOf(1);
    }
}

- (void)testManagedObjectRequestOperationFailsWithValidationErrorWhenDiscardsInvalidObjectsOnInsertIsNO
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *postMapping = [RKEntityMapping mappingForEntityForName:@"Post" inManagedObjectStore:managedObjectStore];
    postMapping.discardsInvalidObjectsOnInsert = NO;
    [postMapping addAttributeMappingsFromArray:@[ @"title", @"body" ]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:postMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"posts" statusCodes:[NSIndexSet indexSetWithIndex:200]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/posts_with_invalid.json" relativeToURL:[RKTestFactory baseURL]]];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    [managedObjectRequestOperation start];
    [managedObjectRequestOperation waitUntilFinished];
    expect(managedObjectRequestOperation.error).notTo.beNil();
    expect([managedObjectRequestOperation.error code]).to.equal(NSValidationMissingMandatoryPropertyError);
#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED
    expect([managedObjectRequestOperation.error localizedDescription]).to.equal(@"title is a required value.");
#else
    expect([managedObjectRequestOperation.error localizedDescription]).to.equal(@"The operation couldn’t be completed. (Cocoa error 1570.)");
#endif
}

- (void)testThatSuccessfulCompletionSavesManagedObjectIfTargetObjectIsUnsavedEvenIfNoMappingWasPerformed
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKHuman *human = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext withProperties:nil];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/204" relativeToURL:[RKTestFactory baseURL]]];
    request.HTTPMethod = @"POST";
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    managedObjectRequestOperation.targetObject = human;
    [managedObjectRequestOperation start];
    [managedObjectRequestOperation waitUntilFinished];
    expect(managedObjectRequestOperation.error).to.beNil();
    [managedObjectStore.persistentStoreManagedObjectContext performBlockAndWait:^{
        expect([human isNew]).to.equal(NO);
    }];
}

- (void)testThatManagedObjectContextIsNotSavedWhenOperationErrorIsMapped
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [entityMapping addAttributeMappingsFromDictionary:@{ @"name": @"name" }];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:entityMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"human" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    RKObjectMapping *errorMapping = [RKObjectMapping mappingForClass:[RKErrorMessage class]];
    [errorMapping addAttributeMappingsFromDictionary:@{ @"self": @"errorMessage" }];
    NSMutableIndexSet *errorCodes = [[NSMutableIndexSet alloc] init];
    [errorCodes addIndexes:RKStatusCodeIndexSetForClass(RKStatusCodeClassClientError)];
    [errorCodes addIndexes:RKStatusCodeIndexSetForClass(RKStatusCodeClassServerError)];
    RKResponseDescriptor *errorDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:errorMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"error" statusCodes:errorCodes];
    
    NSManagedObjectContext *scratchContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    id mockContext = [OCMockObject partialMockForObject:scratchContext];
    [(NSManagedObjectContext *)[mockContext reject] save:((NSError __autoreleasing **)[OCMArg anyPointer])];
    scratchContext.parentContext = [managedObjectStore mainQueueManagedObjectContext];
    
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:mockContext];
    human.name = @"Blake";
    
    NSMutableURLRequest *request = [NSMutableURLRequest  requestWithURL:[NSURL URLWithString:@"/422" relativeToURL:[RKTestFactory baseURL]]];
    request.HTTPMethod = @"POST";
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor, errorDescriptor ]];
    managedObjectRequestOperation.managedObjectContext = mockContext;
    managedObjectRequestOperation.targetObject = human;
    [managedObjectRequestOperation start];
    [managedObjectRequestOperation waitUntilFinished];
    
    expect(scratchContext.hasChanges).to.beTruthy();
    expect([managedObjectStore.mainQueueManagedObjectContext existingObjectWithID:human.objectID error:nil]).to.beNil();
    expect(managedObjectRequestOperation.error).toNot.beNil();
    expect(managedObjectRequestOperation.mappingResult.dictionary[@"human"]).to.beNil();
    expect(scratchContext.insertedObjects).to.haveCountOf(1);
    [mockContext verify];
}

- (void)testThatMapperOperationDelegateIsPassedThroughToUnderlyingMapperOperation
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [entityMapping addAttributeMappingsFromArray:@[ @"name" ]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:entityMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"human" statusCodes:[NSIndexSet indexSetWithIndex:200]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/humans/with_to_one_relationship.json" relativeToURL:[RKTestFactory baseURL]]];
    RKTestDelegateManagedObjectRequestOperation *managedObjectRequestOperation = [[RKTestDelegateManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    id mockOperation = [OCMockObject partialMockForObject:managedObjectRequestOperation];
    [[mockOperation expect] mapperWillStartMapping:OCMOCK_ANY];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    [managedObjectRequestOperation start];
    [managedObjectRequestOperation waitUntilFinished];
    expect([managedObjectRequestOperation isFinished]).will.beTruthy();
    [mockOperation verify];
}

- (void)testThatRefetchingOfNestedNonManagedAndManagedObjectsWorksWithHasOneRelations
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKObjectMapping *itemMapping = [RKObjectMapping mappingForClass:[RKMappableObject class]];
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [entityMapping addAttributeMappingsFromArray:@[ @"name" ]];
    [userMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"favorite_cat" toKeyPath:@"bestFriend" withMapping:entityMapping]];
    [itemMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"items.human" toKeyPath:@"hasMany" withMapping:userMapping]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:itemMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"result" statusCodes:[NSIndexSet indexSetWithIndex:200]];

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/humans/has_many_with_to_one_relationship.json" relativeToURL:[RKTestFactory baseURL]]];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    [managedObjectRequestOperation start];
    [managedObjectRequestOperation waitUntilFinished];
    expect(managedObjectRequestOperation.error).to.beNil();
    RKMappableObject *result = [managedObjectRequestOperation.mappingResult.array lastObject];
    RKTestUser *user = (RKTestUser *)result.hasMany.anyObject;
    expect(user.bestFriend).to.beInstanceOf([RKHuman class]);
    expect([user.bestFriend managedObjectContext]).to.equal(managedObjectStore.persistentStoreManagedObjectContext);
}

- (void)testThatEntityMappingUsingNilKeyPathInsideNestedMappingDoesRefetchManagedObjects
{
    RKLogConfigureByName("RestKit/ObjectMapping", RKLogLevelTrace);
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [entityMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:nil toKeyPath:@"favoriteCatID"]];
    entityMapping.identificationAttributes = @[@"favoriteCatID"];
    [userMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"favorite_cat_id" toKeyPath:@"bestFriend" withMapping:entityMapping]];
    [userMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"children" toKeyPath:@"friends" withMapping:userMapping]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/humans/with_to_one_relationship_inside_collection.json" relativeToURL:[RKTestFactory baseURL]]];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    [managedObjectRequestOperation start];
    [managedObjectRequestOperation waitUntilFinished];
    expect(managedObjectRequestOperation.error).to.beNil();
    RKMappableObject *result = managedObjectRequestOperation.mappingResult.firstObject;
    RKTestUser *user = (RKTestUser *)result;
    expect(user.bestFriend).to.beInstanceOf([RKHuman class]);
    expect(user.friends.count).to.equal(1);
    RKTestUser *child = (RKTestUser *)user.friends.firstObject;
    expect([user.bestFriend managedObjectContext]).to.equal(managedObjectStore.persistentStoreManagedObjectContext);
    expect([child.bestFriend managedObjectContext]).to.equal(managedObjectStore.persistentStoreManagedObjectContext);
}

- (void)testThatAnEmptyResultHasTheProperManagedObjectContext
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [entityMapping addAttributeMappingsFromArray:@[ @"name" ]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:entityMapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/humans/empty_human.json" relativeToURL:[RKTestFactory baseURL]]];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    [managedObjectRequestOperation start];
    [managedObjectRequestOperation waitUntilFinished];
    expect(managedObjectRequestOperation.error).to.beNil();
    RKHuman *result = [managedObjectRequestOperation.mappingResult.array lastObject];
    expect(managedObjectRequestOperation.managedObjectContext).to.equal(result.managedObjectContext);
}

- (void)testMappingMetadataConfiguredOnTheOperation
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [entityMapping addAttributeMappingsFromDictionary:@{ @"@metadata.nickName": @"nickName" }];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:entityMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"human" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];

    NSMutableURLRequest *request = [NSMutableURLRequest  requestWithURL:[NSURL URLWithString:@"/humans/1" relativeToURL:[RKTestFactory baseURL]]];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    managedObjectRequestOperation.mappingMetadata = @{ @"nickName": @"Big Sleezy" };
    [managedObjectRequestOperation start];
    [managedObjectRequestOperation waitUntilFinished];
    expect(managedObjectRequestOperation.error).to.beNil();
    expect(managedObjectRequestOperation.mappingResult).notTo.beNil();
    RKHuman *human = [managedObjectRequestOperation.mappingResult firstObject];
    expect(human.nickName).to.equal(@"Big Sleezy");
}

- (void)testCopyingOperation
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [entityMapping addAttributeMappingsFromDictionary:@{ @"@metadata.nickName": @"nickName" }];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:entityMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"human" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    NSMutableURLRequest *request = [NSMutableURLRequest  requestWithURL:[NSURL URLWithString:@"/humans/1" relativeToURL:[RKTestFactory baseURL]]];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    RKManagedObjectRequestOperation *copiedOperation = [managedObjectRequestOperation copy];
    copiedOperation.mappingMetadata = @{ @"nickName": @"Big Sleezy" };
    [copiedOperation start];
    [copiedOperation waitUntilFinished];
    expect(copiedOperation.error).to.beNil();
    expect(copiedOperation.mappingResult).notTo.beNil();
    RKHuman *human = [copiedOperation.mappingResult firstObject];
    expect(human.nickName).to.equal(@"Big Sleezy");
}

- (void)testThatManuallyCreatedObjectsAreNotDuplicatedWhenMappedWithInMemoryManagedObjectCache
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [entityMapping addAttributeMappingsFromDictionary:@{ @"id": @"railsID", @"name": @"name" }];
    entityMapping.identificationAttributes = @[ @"railsID" ];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:entityMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"human" statusCodes:nil];
    RKInMemoryManagedObjectCache *managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    human.railsID = @1;
    [managedObjectStore.mainQueueManagedObjectContext saveToPersistentStore:nil];
    NSMutableURLRequest *request = [NSMutableURLRequest  requestWithURL:[NSURL URLWithString:@"/humans" relativeToURL:[RKTestFactory baseURL]]];
    [request setHTTPMethod:@"POST"];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.mainQueueManagedObjectContext;
    managedObjectRequestOperation.managedObjectCache = managedObjectCache;
    NSOperationQueue *operationQueue = [NSOperationQueue new];
    [operationQueue addOperation:managedObjectRequestOperation];
    expect(managedObjectRequestOperation.isFinished).will.equal(YES);
    RKHuman *mappedHuman = [managedObjectRequestOperation.mappingResult firstObject];
    expect(mappedHuman).to.equal(human);
}

- (void)testThatManuallyCreatedObjectsThatAreNotSavedBeforePostingAreNotDuplicatedWhenMappedWithInMemoryManagedObjectCache
{
    [Expecta setAsynchronousTestTimeout:15];
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [entityMapping addAttributeMappingsFromDictionary:@{ @"id": @"railsID", @"name": @"name" }];
    entityMapping.identificationAttributes = @[ @"railsID" ];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:entityMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"human" statusCodes:nil];
    RKInMemoryManagedObjectCache *managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    human.railsID = @1;
    NSMutableURLRequest *request = [NSMutableURLRequest  requestWithURL:[NSURL URLWithString:@"/humans" relativeToURL:[RKTestFactory baseURL]]];
    [request setHTTPMethod:@"POST"];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.mainQueueManagedObjectContext;
    managedObjectRequestOperation.managedObjectCache = managedObjectCache;
    NSOperationQueue *operationQueue = [NSOperationQueue new];
    [operationQueue addOperation:managedObjectRequestOperation];
    expect(managedObjectRequestOperation.isFinished).will.equal(YES);
    RKHuman *mappedHuman = [managedObjectRequestOperation.mappingResult firstObject];
    expect(mappedHuman).to.equal(human);
    NSUInteger count = [managedObjectStore.mainQueueManagedObjectContext countForEntityForName:@"Human" predicate:[NSPredicate predicateWithFormat:@"railsID = 1"] error:nil];
    expect(count).to.equal(1);
}

- (void)testThatModificationKeyAttributeDoesNotInapproproiatelyTriggerManagedObjectDeletion
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [entityMapping addAttributeMappingsFromDictionary:@{ @"id": @"railsID", @"name": @"name" }];
    entityMapping.identificationAttributes = @[ @"railsID" ];
    [entityMapping setModificationAttributeForName:@"railsID"];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:entityMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"human" statusCodes:nil];
    RKInMemoryManagedObjectCache *managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    human.railsID = @1;
    [managedObjectStore.mainQueueManagedObjectContext saveToPersistentStore:nil];
    NSURLRequest *request = [NSURLRequest  requestWithURL:[NSURL URLWithString:@"/humans/1" relativeToURL:[RKTestFactory baseURL]]];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.mainQueueManagedObjectContext;
    managedObjectRequestOperation.managedObjectCache = managedObjectCache;
    RKFetchRequestBlock fetchRequestBlock = ^(NSURL *URL){
        return [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    };
    managedObjectRequestOperation.deletesOrphanedObjects = YES;
    managedObjectRequestOperation.fetchRequestBlocks = @[ fetchRequestBlock ];
    [managedObjectRequestOperation start];
    expect([managedObjectRequestOperation isFinished]).will.equal(YES);
    expect([human isDeleted]).to.equal(NO);
}

- (void)testThatNestedObjectsThatAreNotMappedDueToTheModificationKeyAreNotInappropriatelyDeletedAsOrphans
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *postMapping = [RKEntityMapping mappingForEntityForName:@"Post" inManagedObjectStore:managedObjectStore];
    [postMapping addAttributeMappingsFromDictionary:@{ @"title": @"title", @"body": @"body" }];
    postMapping.identificationAttributes = @[ @"title" ];
    [postMapping setModificationAttributeForName:@"title"];
    RKEntityMapping *tagMapping = [RKEntityMapping mappingForEntityForName:@"Tag" inManagedObjectStore:managedObjectStore];
    [tagMapping addAttributeMappingsFromArray:@[ @"name" ]];
    [postMapping addRelationshipMappingWithSourceKeyPath:@"tags" mapping:tagMapping];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:postMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"posts" statusCodes:nil];
    RKInMemoryManagedObjectCache *managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKPost *post = [NSEntityDescription insertNewObjectForEntityForName:@"Post" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    [post setValue:@"Post Title" forKey:@"title"];
    NSManagedObject *developmentTag = [NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    [developmentTag setValue:@"development" forKey:@"name"];
    NSManagedObject *restKitTag = [NSEntityDescription insertNewObjectForEntityForName:@"Tag" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    [restKitTag setValue:@"restkit" forKey:@"name"];
    [post setValue:[NSSet setWithObjects:developmentTag, restKitTag, nil] forKey:@"tags"];
    [managedObjectStore.mainQueueManagedObjectContext saveToPersistentStore:nil];
    NSURLRequest *request = [NSURLRequest  requestWithURL:[NSURL URLWithString:@"/posts.json" relativeToURL:[RKTestFactory baseURL]]];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.mainQueueManagedObjectContext;
    managedObjectRequestOperation.managedObjectCache = managedObjectCache;
    RKFetchRequestBlock postFetchRequestBlock = ^(NSURL *URL){
        return [NSFetchRequest fetchRequestWithEntityName:@"Post"];
    };
    RKFetchRequestBlock tagFetchRequestBlock = ^(NSURL *URL){
        return [NSFetchRequest fetchRequestWithEntityName:@"Tag"];
    };
    managedObjectRequestOperation.deletesOrphanedObjects = YES;
    managedObjectRequestOperation.fetchRequestBlocks = @[ postFetchRequestBlock, tagFetchRequestBlock ];
    [managedObjectRequestOperation start];
    expect([managedObjectRequestOperation isFinished]).will.equal(YES);
    expect([post isDeleted]).to.equal(NO);
    expect([restKitTag hasBeenDeleted]).to.equal(NO);
    expect([developmentTag hasBeenDeleted]).to.equal(NO);
}

- (void)testThanAnEmptyResponseTriggersDeletionOfOrphanedObjects
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [entityMapping addAttributeMappingsFromDictionary:@{ @"id": @"railsID", @"name": @"name" }];
    entityMapping.identificationAttributes = @[ @"railsID" ];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:entityMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"human" statusCodes:nil];
    RKInMemoryManagedObjectCache *managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    human.railsID = @1;
    [managedObjectStore.mainQueueManagedObjectContext saveToPersistentStore:nil];
    NSURLRequest *request = [NSURLRequest  requestWithURL:[NSURL URLWithString:@"/empty/array" relativeToURL:[RKTestFactory baseURL]]];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.mainQueueManagedObjectContext;
    managedObjectRequestOperation.managedObjectCache = managedObjectCache;
    RKFetchRequestBlock fetchRequestBlock = ^(NSURL *URL){
        return [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    };
    managedObjectRequestOperation.deletesOrphanedObjects = YES;
    managedObjectRequestOperation.fetchRequestBlocks = @[ fetchRequestBlock ];
    [managedObjectRequestOperation start];
    expect([managedObjectRequestOperation isFinished]).will.equal(YES);
    expect([human hasBeenDeleted]).to.equal(YES);
}

- (void)testThatErrorStatusCodeDoesNotTriggerDeletionOfOrphanedObjects
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [entityMapping addAttributeMappingsFromDictionary:@{ @"id": @"railsID", @"name": @"name" }];
    entityMapping.identificationAttributes = @[ @"railsID" ];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:entityMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"human" statusCodes:nil];
    RKInMemoryManagedObjectCache *managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    human.railsID = @1;
    [managedObjectStore.mainQueueManagedObjectContext saveToPersistentStore:nil];
    NSMutableURLRequest *request = [NSMutableURLRequest  requestWithURL:[NSURL URLWithString:@"/500" relativeToURL:[RKTestFactory baseURL]]];
    request.HTTPMethod = @"GET";
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.mainQueueManagedObjectContext;
    managedObjectRequestOperation.managedObjectCache = managedObjectCache;
    RKFetchRequestBlock fetchRequestBlock = ^(NSURL *URL){
        return [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    };
    managedObjectRequestOperation.deletesOrphanedObjects = YES;
    managedObjectRequestOperation.fetchRequestBlocks = @[ fetchRequestBlock ];
    [managedObjectRequestOperation start];
    expect([managedObjectRequestOperation isFinished]).will.equal(YES);
    expect([human hasBeenDeleted]).to.equal(NO);
}

- (void)testThatCorruptedBodyDoesNotTriggerDeletionOfOrphanedObjects
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [entityMapping addAttributeMappingsFromDictionary:@{ @"id": @"railsID", @"name": @"name" }];
    entityMapping.identificationAttributes = @[ @"railsID" ];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:entityMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"human" statusCodes:nil];
    RKInMemoryManagedObjectCache *managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    human.railsID = @1;
    [managedObjectStore.mainQueueManagedObjectContext saveToPersistentStore:nil];
    NSMutableURLRequest *request = [NSMutableURLRequest  requestWithURL:[NSURL URLWithString:@"/corrupted/json" relativeToURL:[RKTestFactory baseURL]]];
    request.HTTPMethod = @"GET";
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.mainQueueManagedObjectContext;
    managedObjectRequestOperation.managedObjectCache = managedObjectCache;
    RKFetchRequestBlock fetchRequestBlock = ^(NSURL *URL){
        return [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    };
    managedObjectRequestOperation.deletesOrphanedObjects = YES;
    managedObjectRequestOperation.fetchRequestBlocks = @[ fetchRequestBlock ];
    [managedObjectRequestOperation start];
    expect([managedObjectRequestOperation isFinished]).will.equal(YES);
    expect([human hasBeenDeleted]).to.equal(NO);
}


- (void)testThatAResponseContainingOnlyNonManagedObjectsTriggersDeletionOfOrphanedObjects
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [entityMapping addAttributeMappingsFromDictionary:@{ @"id": @"railsID", @"name": @"name" }];
    entityMapping.identificationAttributes = @[ @"railsID" ];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:entityMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"human" statusCodes:nil];
    
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    [userMapping addAttributeMappingsFromArray:@[ @"name" ]];
    RKResponseDescriptor *userResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping method:RKRequestMethodAny pathPattern:nil keyPath:nil statusCodes:nil];
    
    RKInMemoryManagedObjectCache *managedObjectCache = [[RKInMemoryManagedObjectCache alloc] initWithManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    human.railsID = @1;
    [managedObjectStore.mainQueueManagedObjectContext saveToPersistentStore:nil];
    NSURLRequest *request = [NSURLRequest  requestWithURL:[NSURL URLWithString:@"/JSON/user.json" relativeToURL:[RKTestFactory baseURL]]];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor, userResponseDescriptor ]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.mainQueueManagedObjectContext;
    managedObjectRequestOperation.managedObjectCache = managedObjectCache;
    RKFetchRequestBlock fetchRequestBlock = ^(NSURL *URL){
        return [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    };
    managedObjectRequestOperation.deletesOrphanedObjects = YES;
    managedObjectRequestOperation.fetchRequestBlocks = @[ fetchRequestBlock ];
    [managedObjectRequestOperation start];
    expect([managedObjectRequestOperation isFinished]).will.equal(YES);
    expect([human hasBeenDeleted]).to.equal(YES);
}

- (void)testThatWillSaveMappingContextBlockIsInvoked
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [entityMapping addAttributeMappingsFromDictionary:@{ @"name": @"name" }];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:entityMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"human" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    NSMutableURLRequest *request = [NSMutableURLRequest  requestWithURL:[NSURL URLWithString:@"/humans/1" relativeToURL:[RKTestFactory baseURL]]];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    __block NSManagedObjectContext *blockMappingContext = nil;
    [managedObjectRequestOperation setWillSaveMappingContextBlock:^(NSManagedObjectContext *mappingContext) {
        blockMappingContext = mappingContext;
    }];
    [managedObjectRequestOperation start];
    [managedObjectRequestOperation waitUntilFinished];
    expect(blockMappingContext).notTo.beNil();
}

- (void)testThatWillSaveMappingContextMappingResultIsAvailable {
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [entityMapping addAttributeMappingsFromDictionary:@{ @"name": @"name" }];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:entityMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"human" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    
    NSMutableURLRequest *request = [NSMutableURLRequest  requestWithURL:[NSURL URLWithString:@"/humans/1" relativeToURL:[RKTestFactory baseURL]]];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    
    __block RKMappingResult *mappingResult = nil;
    __weak RKManagedObjectRequestOperation *operationWeak = managedObjectRequestOperation;
    [managedObjectRequestOperation setWillSaveMappingContextBlock:^(NSManagedObjectContext *mappingContext) {
        RKManagedObjectRequestOperation *operationStrong = operationWeak;
        mappingResult = operationStrong.mappingResult;
    }];
    
    [managedObjectRequestOperation start];
    [managedObjectRequestOperation waitUntilFinished];
    expect(mappingResult).notTo.beNil();
}

- (void)testLoadingManagedObjectsWithAttributeKeyPath
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    entityMapping.identificationAttributes = @[ @"railsID" ];
    [entityMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:nil toKeyPath:@"railsID"]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:entityMapping method:RKRequestMethodAny pathPattern:nil keyPath:@"user_ids" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];

    NSMutableURLRequest *request = [NSMutableURLRequest  requestWithURL:[NSURL URLWithString:@"/user_ids" relativeToURL:[RKTestFactory baseURL]]];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    managedObjectRequestOperation.managedObjectCache = [RKFetchRequestManagedObjectCache new];
    [managedObjectRequestOperation start];
    [managedObjectRequestOperation waitUntilFinished];
    expect([managedObjectRequestOperation.mappingResult array]).will.haveCountOf(3);
}

@end
