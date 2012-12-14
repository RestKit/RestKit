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
#import "RKMappingErrors.h"

@interface RKManagedObjectRequestOperation ()
- (NSSet *)localObjectsFromFetchRequestsMatchingRequestURL:(NSError **)error;
@end

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
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping pathPattern:@"categories/:categoryID" keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
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
    NSError *error;
    [operation localObjectsFromFetchRequestsMatchingRequestURL:&error];
    expect(blockURL).notTo.beNil();
    expect([blockURL.baseURL absoluteString]).to.equal(@"http://restkit.org/api/v1/");
    expect(blockURL.relativePath).to.equal(@"categories/1234");
}

- (void)testThatFetchRequestBlocksInvokedWithRelativeURLAreInAgreementWithPathPattern
{
    NSURL *baseURL = [NSURL URLWithString:@"http://restkit.org/api/v1/"];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"library/" relativeToURL:baseURL]];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:request.URL statusCode:200 HTTPVersion:@"1.1" headerFields:@{}];
    expect([request.URL absoluteString]).to.equal(@"http://restkit.org/api/v1/library/");
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping pathPattern:@"library/" keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
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
    NSError *error;
    [operation localObjectsFromFetchRequestsMatchingRequestURL:&error];
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
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:humanMapping pathPattern:nil keyPath:@"human" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.mainQueueManagedObjectContext;
    
    [managedObjectRequestOperation start];
    [managedObjectRequestOperation waitUntilFinished];
    expect(managedObjectRequestOperation.mappingResult).notTo.beNil();
    NSArray *managedObjectContexts = [[managedObjectRequestOperation.mappingResult array] valueForKeyPath:@"@distinctUnionOfObjects.managedObjectContext"];
    expect([managedObjectContexts count]).to.equal(1);
    expect(managedObjectContexts[0]).to.equal(managedObjectStore.mainQueueManagedObjectContext);
}

// 304 'Not Modified'
- (void)testThatManagedObjectsAreFetchedWhenHandlingANotModifiedResponse
{
    RKFetchRequestBlock fetchRequestBlock = ^(NSURL *URL){
        return [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    };
    
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKHuman *human = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.mainQueueManagedObjectContext];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/204_with_not_modified_status" relativeToURL:[RKTestFactory baseURL]]];
    RKEntityMapping *humanMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [humanMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"name" toKeyPath:@"name"]];
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:humanMapping pathPattern:nil keyPath:@"human" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
    managedObjectRequestOperation.fetchRequestBlocks = @[fetchRequestBlock];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.mainQueueManagedObjectContext;
    
    [managedObjectRequestOperation start];
    [managedObjectRequestOperation waitUntilFinished];
    expect(managedObjectRequestOperation.mappingResult).notTo.beNil();
    NSArray *mappedObjects = [managedObjectRequestOperation.mappingResult array];
    expect(mappedObjects).to.haveCountOf(1);
    expect([mappedObjects[0] objectID]).to.equal([human objectID]);
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
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:humanMapping pathPattern:nil keyPath:@"human" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.mainQueueManagedObjectContext;
    
    [managedObjectRequestOperation start];
    [managedObjectRequestOperation waitUntilFinished];
    expect(managedObjectRequestOperation.error).notTo.beNil();
    expect(managedObjectRequestOperation.mappingResult).to.beNil();
    expect([managedObjectRequestOperation.error localizedDescription]).to.equal(@"The operation couldn’t be completed. (Cocoa error 1660.)");
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
    expect(managedObjectRequestOperation.error).to.beNil();
    expect([human hasBeenDeleted]).to.equal(YES);
}

// 200 application/json { "human": { "status": "OK" } }
- (void)testDeletionOfObjectWithUnmappedResponseBody
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKHuman *human = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext withProperties:nil];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/humans/success" relativeToURL:[RKTestFactory baseURL]]];
    request.HTTPMethod = @"DELETE";
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    managedObjectRequestOperation.targetObject = human;
    [managedObjectRequestOperation start];
    expect(managedObjectRequestOperation.error).to.beNil();
    expect([human hasBeenDeleted]).to.equal(YES);
}

// 200 application/json { "human": { "status": "OK" } }
- (void)testDeletionOfObjectWithResponseDescriptorMappingResponseByURL
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [entityMapping addAttributeMappingsFromDictionary:@{ @"human.status" : @"name" }];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:entityMapping pathPattern:@"/humans/success" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    RKHuman *human = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext withProperties:nil];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/humans/success" relativeToURL:[RKTestFactory baseURL]]];
    request.HTTPMethod = @"DELETE";
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    managedObjectRequestOperation.targetObject = human;
    [managedObjectRequestOperation start];
    expect(managedObjectRequestOperation.error).to.beNil();
    expect([human hasBeenDeleted]).to.equal(YES);
}

// 200 application/json { "human": { "status": "OK" } }
- (void)testDeletionOfObjectWithResponseDescriptorMappingResponseByKeyPath
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [entityMapping addAttributeMappingsFromDictionary:@{ @"status" : @"name" }];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:entityMapping pathPattern:nil keyPath:@"human" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    RKHuman *human = [RKTestFactory insertManagedObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext withProperties:nil];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"/humans/success" relativeToURL:[RKTestFactory baseURL]]];
    request.HTTPMethod = @"DELETE";
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    managedObjectRequestOperation.targetObject = human;
    [managedObjectRequestOperation start];
    expect(managedObjectRequestOperation.error).to.beNil();
    expect([human hasBeenDeleted]).to.equal(YES);
}

- (void)testThatManagedObjectMappedAsTheRelationshipOfNonManagedObjectsAreRefetchedFromTheParentContext
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [entityMapping addAttributeMappingsFromArray:@[ @"name" ]];
    [userMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"favorite_cat" toKeyPath:@"friends" withMapping:entityMapping]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping pathPattern:nil keyPath:@"human" statusCodes:[NSIndexSet indexSetWithIndex:200]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/humans/with_to_one_relationship.json" relativeToURL:[RKTestFactory baseURL]]];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    [managedObjectRequestOperation start];
    expect(managedObjectRequestOperation.error).to.beNil();
    expect([managedObjectRequestOperation.mappingResult array]).to.haveCountOf(1);
    RKTestUser *testUser = [managedObjectRequestOperation.mappingResult firstObject];
    expect([[testUser.friends lastObject] managedObjectContext]).to.equal(managedObjectStore.persistentStoreManagedObjectContext);
}

- (void)testThatManagedObjectMappedAsTheRelationshipOfNonManagedObjectsWithADynamicMappingAreRefetchedFromTheParentContext
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [entityMapping addAttributeMappingsFromArray:@[ @"name" ]];
    [userMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"favorite_cat" toKeyPath:@"friends" withMapping:entityMapping]];
    RKDynamicMapping *dynamicMapping = [RKDynamicMapping new];
    [dynamicMapping setObjectMapping:userMapping whenValueOfKeyPath:@"name" isEqualTo:@"Blake Watters"];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:dynamicMapping pathPattern:nil keyPath:@"human" statusCodes:[NSIndexSet indexSetWithIndex:200]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/humans/with_to_one_relationship.json" relativeToURL:[RKTestFactory baseURL]]];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    [managedObjectRequestOperation start];
    expect(managedObjectRequestOperation.error).to.beNil();
    expect([managedObjectRequestOperation.mappingResult array]).to.haveCountOf(1);
    RKTestUser *testUser = [managedObjectRequestOperation.mappingResult firstObject];
    expect([[testUser.friends lastObject] managedObjectContext]).to.equal(managedObjectStore.persistentStoreManagedObjectContext);
}

- (void)testThatManagedObjectMappedFromRootKeyPathAreRefetchedFromTheParentContext
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [entityMapping addAttributeMappingsFromDictionary:@{ @"human.name": @"name" }];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:entityMapping pathPattern:nil keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/humans/with_to_one_relationship.json" relativeToURL:[RKTestFactory baseURL]]];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    [managedObjectRequestOperation start];
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
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping pathPattern:nil keyPath:@"human" statusCodes:[NSIndexSet indexSetWithIndex:200]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/humans/with_to_one_relationship.json" relativeToURL:[RKTestFactory baseURL]]];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    [managedObjectRequestOperation start];
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
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping pathPattern:nil keyPath:@"human" statusCodes:[NSIndexSet indexSetWithIndex:200]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/humans/with_to_one_relationship.json" relativeToURL:[RKTestFactory baseURL]]];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    [managedObjectRequestOperation start];
    expect(managedObjectRequestOperation.error).to.beNil();
    expect([managedObjectRequestOperation.mappingResult array]).to.haveCountOf(1);
    RKTestUser *testUser = [managedObjectRequestOperation.mappingResult firstObject];
    expect([[testUser.friendsOrderedSet firstObject] managedObjectContext]).to.equal(managedObjectStore.persistentStoreManagedObjectContext);
}

- (void)testDeletionOfOrphanedObjectsMappedOnRelationships
{
    RKManagedObjectStore *managedObjectStore = [RKTestFactory managedObjectStore];
    RKHuman *orphanedHuman = [NSEntityDescription insertNewObjectForEntityForName:@"Human" inManagedObjectContext:managedObjectStore.persistentStoreManagedObjectContext];
    RKObjectMapping *userMapping = [RKObjectMapping mappingForClass:[RKTestUser class]];
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"Human" inManagedObjectStore:managedObjectStore];
    [entityMapping addAttributeMappingsFromArray:@[ @"name" ]];
    [userMapping addPropertyMapping:[RKRelationshipMapping relationshipMappingFromKeyPath:@"favorite_cat" toKeyPath:@"friends" withMapping:entityMapping]];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:userMapping pathPattern:nil keyPath:@"human" statusCodes:[NSIndexSet indexSetWithIndex:200]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"/JSON/humans/with_to_one_relationship.json" relativeToURL:[RKTestFactory baseURL]]];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    RKFetchRequestBlock fetchRequestBlock = ^NSFetchRequest * (NSURL *URL) {
        return [NSFetchRequest fetchRequestWithEntityName:@"Human"];
    };
    managedObjectRequestOperation.fetchRequestBlocks = @[ fetchRequestBlock ];
    managedObjectRequestOperation.managedObjectContext = managedObjectStore.persistentStoreManagedObjectContext;
    [managedObjectRequestOperation start];
    expect(managedObjectRequestOperation.error).to.beNil();
    expect([managedObjectRequestOperation.mappingResult array]).to.haveCountOf(1);
    expect(orphanedHuman.managedObjectContext).to.beNil();
}

// TODO: test deletion of nested objects

@end
