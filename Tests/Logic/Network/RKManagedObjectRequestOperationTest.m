//
//  RKManagedObjectRequestOperationTest.m
//  RestKit
//
//  Created by Blake Watters on 10/17/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKTestEnvironment.h"
#import "RKManagedObjectRequestOperation.h"

@interface RKManagedObjectRequestOperation ()
- (NSSet *)localObjectsFromFetchRequestsMatchingRequestURL:(NSError **)error;
@end


@interface RKManagedObjectRequestOperationTest : RKTestCase

@end

@implementation RKManagedObjectRequestOperationTest

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
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping pathPattern:@"categories/:categoryID" keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    responseDescriptor.baseURL = baseURL;
    RKManagedObjectRequestOperation *operation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
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
    expect([request.URL absoluteString]).to.equal(@"http://restkit.org/api/v1/library/");
    RKObjectMapping *mapping = [RKObjectMapping requestMapping];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping pathPattern:@"library/" keyPath:nil statusCodes:[NSIndexSet indexSetWithIndex:200]];
    responseDescriptor.baseURL = baseURL;
    RKManagedObjectRequestOperation *operation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[responseDescriptor]];
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

@end
