//
//  RKPaginatorTest.m
//  RestKit
//
//  Created by Blake Watters on 12/29/11.
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
#import "RKPaginator.h"
#import "RKObjectMapperTestModel.h"
#import "RKURLEncodedSerialization.h"

@interface RKPaginator (Testability)
- (void)waitUntilFinished;
@end

@interface RKPaginatorTest : RKTestCase
@property (nonatomic, readonly) NSURL *paginationURL;
@property (nonatomic, readonly) RKObjectMapping *paginationMapping;
@property (nonatomic, readonly) RKResponseDescriptor *responseDescriptor;
@end

@implementation RKPaginatorTest

static NSString * const RKPaginatorTestResourcePathPattern = @"/paginate?per_page=:perPage&page=:currentPage";
static NSString * const RKPaginatorTestResourcePathPatternWithOffset = @"/paginate?limit=:perPage&offset=:offset";

- (void)setUp
{
    [RKTestFactory setUp];
}

- (void)tearDown
{
    [RKTestFactory tearDown];
}

- (RKResponseDescriptor *)responseDescriptor
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKObjectMapperTestModel class]];
    [mapping addAttributeMappingsFromArray:@[@"name", @"age"]];
    
    return [RKResponseDescriptor responseDescriptorWithMapping:mapping pathPattern:nil keyPath:@"entries" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
}

- (RKObjectMapping *)paginationMapping
{
    RKObjectMapping *paginationMapping = [RKObjectMapping mappingForClass:[RKPaginator class]];
    [paginationMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"current_page" toKeyPath:@"currentPage"]];
    [paginationMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"per_page" toKeyPath:@"perPage"]];
    [paginationMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"total_entries" toKeyPath:@"objectCount"]];
    [paginationMapping addPropertyMapping:[RKAttributeMapping attributeMappingFromKeyPath:@"offset" toKeyPath:@"offset"]];

    return paginationMapping;
}

- (NSURL *)paginationURL
{
    return [NSURL URLWithString:RKPaginatorTestResourcePathPattern relativeToURL:[RKTestFactory baseURL]];
}

- (NSURL *)paginationOffsetURL
{
    return [NSURL URLWithString:RKPaginatorTestResourcePathPatternWithOffset relativeToURL:[RKTestFactory baseURL]];
}

#pragma mark - Test Cases

- (void)testInitCopiesPatternURL
{
    NSURL *patternURL = [NSURL URLWithString:@"http://restkit.org"];
    NSURLRequest *request = [NSURLRequest requestWithURL:patternURL];
    RKPaginator *paginator = [[RKPaginator alloc] initWithRequest:request paginationMapping:self.paginationMapping responseDescriptors:@[ self.responseDescriptor ]];
    expect([paginator.patternURL absoluteString]).to.equal(@"http://restkit.org");
}

- (void)testInitDoesNotHavePageCount
{
    NSURLRequest *request = [NSURLRequest requestWithURL:self.paginationURL];
    RKPaginator *paginator = [[RKPaginator alloc] initWithRequest:request paginationMapping:self.paginationMapping responseDescriptors:@[ self.responseDescriptor ]];
    expect([paginator hasPageCount]).to.equal(NO);
}

- (void)testInitDoesNotHaveObjectCount
{
    NSURLRequest *request = [NSURLRequest requestWithURL:self.paginationURL];
    RKPaginator *paginator = [[RKPaginator alloc] initWithRequest:request paginationMapping:self.paginationMapping responseDescriptors:@[ self.responseDescriptor ]];
    expect([paginator hasObjectCount]).to.equal(NO);
}

- (void)testThatInitWithInvalidPaginationMappingRaisesError
{
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[NSMutableDictionary class]];
    NSURLRequest *request = [NSURLRequest requestWithURL:self.paginationURL];
    NSException *exception = nil;
    @try {
        RKPaginator *paginator = [[RKPaginator alloc] initWithRequest:request paginationMapping:mapping responseDescriptors:@[ self.responseDescriptor ]];
        [paginator loadPage:1];
    }
    @catch (NSException *e) {
        exception = e;
    }
    expect(exception).notTo.beNil();
    expect([exception reason]).to.equal(@"The paginationMapping must have a target object class of `RKPaginator`");
}

- (void)testThatInitWithNilResponseDescriptorsRaisesError
{
    NSURLRequest *request = [NSURLRequest requestWithURL:self.paginationURL];
    NSException *exception = nil;
    @try {
        RKPaginator *paginator = [[RKPaginator alloc] initWithRequest:request paginationMapping:self.paginationMapping responseDescriptors:nil];
        [paginator loadPage:1];
    }
    @catch (NSException *e) {
        exception = e;
    }
    expect(exception).notTo.beNil();
    expect([exception reason]).to.equal(@"Invalid parameter not satisfying: responseDescriptors");
}

- (void)testThatResourcePathPatternEvaluatesAgainstPaginator
{
    NSURLRequest *request = [NSURLRequest requestWithURL:self.paginationURL];
    RKPaginator *paginator = [[RKPaginator alloc] initWithRequest:request paginationMapping:self.paginationMapping responseDescriptors:@[ self.responseDescriptor ]];
    id mockPaginator = [OCMockObject partialMockForObject:paginator];
    NSUInteger currentPage = 1;
    [[[mockPaginator stub] andReturnValue:OCMOCK_VALUE(currentPage)] currentPage];
    expect([paginator.URL relativeString]).to.equal(@"/paginate?per_page=25&page=1");
}

- (void)testThatURLReturnedReflectsStateOfPaginator
{
    NSURLRequest *request = [NSURLRequest requestWithURL:self.paginationURL];
    RKPaginator *paginator = [[RKPaginator alloc] initWithRequest:request paginationMapping:self.paginationMapping responseDescriptors:@[ self.responseDescriptor ]];
    id mockPaginator = [OCMockObject partialMockForObject:paginator];
    NSUInteger currentPage = 1;
    [[[mockPaginator stub] andReturnValue:OCMOCK_VALUE(currentPage)] currentPage];
    expect([[mockPaginator URL] query]).to.equal(@"per_page=25&page=1");
}

- (void)testThatURLReturnedReflectsStateOfPaginatorWithOffset
{
    NSURLRequest *request = [NSURLRequest requestWithURL:self.paginationOffsetURL];
    RKPaginator *paginator = [[RKPaginator alloc] initWithRequest:request paginationMapping:self.paginationMapping responseDescriptors:@[ self.responseDescriptor ]];
    id mockPaginator = [OCMockObject partialMockForObject:paginator];
    NSUInteger currentPage = 1;
    [[[mockPaginator stub] andReturnValue:OCMOCK_VALUE(currentPage)] currentPage];
    expect([[mockPaginator URL] query]).to.equal(@"limit=25&offset=0");
}


- (void)testLoadingAPageOfObjects
{
    NSURLRequest *request = [NSURLRequest requestWithURL:self.paginationURL];
    RKPaginator *paginator = [[RKPaginator alloc] initWithRequest:request paginationMapping:self.paginationMapping responseDescriptors:@[ self.responseDescriptor ]];
    [paginator loadPage:1];
    [paginator waitUntilFinished];
    expect(paginator.isLoaded).will.equal(YES);
}

- (void)testLoadingAPageOfObjectsWithDocumentedPaginationMapping
{
    RKObjectMapping *paginationMapping = [RKObjectMapping mappingForClass:[RKPaginator class]];
    [paginationMapping addAttributeMappingsFromDictionary:@{
     @"per_page":        @"perPage",
     @"total_pages":     @"pageCount",
     @"total_objects":   @"objectCount",
     }];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:self.paginationURL];
    RKPaginator *paginator = [[RKPaginator alloc] initWithRequest:request paginationMapping:paginationMapping responseDescriptors:@[ self.responseDescriptor ]];
    [paginator loadPage:1];
    [paginator waitUntilFinished];
    expect(paginator.isLoaded).will.equal(YES);
}

- (void)testLoadingPageOfObjectMapsPerPage
{
    NSURLRequest *request = [NSURLRequest requestWithURL:self.paginationURL];
    RKPaginator *paginator = [[RKPaginator alloc] initWithRequest:request paginationMapping:self.paginationMapping responseDescriptors:@[ self.responseDescriptor ]];
    [paginator loadPage:1];
    [paginator waitUntilFinished];
    expect(paginator.perPage).to.equal(3);
}

- (void)testLoadingPageOfObjectMapsTotalEntries
{
    NSURLRequest *request = [NSURLRequest requestWithURL:self.paginationURL];
    RKPaginator *paginator = [[RKPaginator alloc] initWithRequest:request paginationMapping:self.paginationMapping responseDescriptors:@[ self.responseDescriptor ]];
    [paginator loadPage:1];
    [paginator waitUntilFinished];
    expect(paginator.objectCount).to.equal(6);
}

- (void)testLoadingPageOfObjectMapsCurrentPage
{
    NSURLRequest *request = [NSURLRequest requestWithURL:self.paginationURL];
    RKPaginator *paginator = [[RKPaginator alloc] initWithRequest:request paginationMapping:self.paginationMapping responseDescriptors:@[ self.responseDescriptor ]];
    [paginator loadPage:1];
    [paginator waitUntilFinished];
    expect(paginator.currentPage).to.equal(1);
}

- (void)testLoadingPageOfObjectMapsEntriesToObjects
{
    NSURLRequest *request = [NSURLRequest requestWithURL:self.paginationURL];
    RKPaginator *paginator = [[RKPaginator alloc] initWithRequest:request paginationMapping:self.paginationMapping responseDescriptors:@[ self.responseDescriptor ]];
    [paginator loadPage:1];
    [paginator waitUntilFinished];
    expect([paginator.mappingResult array]).will.haveCountOf(3);
    NSArray *expectedNames = @[ @"Blake", @"Sarah", @"Colin" ];
    expect([[paginator.mappingResult array] valueForKey:@"name"]).to.equal(expectedNames);
}

- (void)testLoadingPageOfObjectHasPageCount
{
    NSURLRequest *request = [NSURLRequest requestWithURL:self.paginationURL];
    RKPaginator *paginator = [[RKPaginator alloc] initWithRequest:request paginationMapping:self.paginationMapping responseDescriptors:@[ self.responseDescriptor ]];
    [paginator loadPage:1];
    [paginator waitUntilFinished];
    expect([paginator hasPageCount]).to.beTruthy();
}

- (void)testLoadingPageOfObjectHasObjectCount
{
    NSURLRequest *request = [NSURLRequest requestWithURL:self.paginationURL];
    RKPaginator *paginator = [[RKPaginator alloc] initWithRequest:request paginationMapping:self.paginationMapping responseDescriptors:@[ self.responseDescriptor ]];
    [paginator loadPage:1];
    [paginator waitUntilFinished];
    expect([paginator hasObjectCount]).to.beTruthy();
}

- (void)testInvocationOfCompletionBlockWithSuccess
{
    NSURLRequest *request = [NSURLRequest requestWithURL:self.paginationURL];
    RKPaginator *paginator = [[RKPaginator alloc] initWithRequest:request paginationMapping:self.paginationMapping responseDescriptors:@[ self.responseDescriptor ]];
    __block NSArray *blockObjects = nil;
    [paginator setCompletionBlockWithSuccess:^(RKPaginator *paginator, NSArray *objects, NSUInteger page) {
        blockObjects = objects;
    } failure:nil];
    [paginator loadPage:1];
    [paginator waitUntilFinished];
    expect(blockObjects).willNot.beNil();
}

- (void)testOnDidFailWithErrorBlockIsInvokedOnError
{
    NSURLRequest *request = [NSURLRequest requestWithURL:self.paginationURL];
    RKPaginator *paginator = [[RKPaginator alloc] initWithRequest:request paginationMapping:self.paginationMapping responseDescriptors:@[ self.responseDescriptor ]];
    __block NSError *expectedError = nil;
    [paginator setCompletionBlockWithSuccess:nil failure:^(RKPaginator *paginator, NSError *error) {
        expectedError = error;
    }];
    [paginator loadPage:999];
    [paginator waitUntilFinished];
    expect(expectedError).willNot.beNil();
}

- (void)testInvocationOfCompletionBlockWithoutWaiting
{
    NSURLRequest *request = [NSURLRequest requestWithURL:self.paginationURL];
    RKPaginator *paginator = [[RKPaginator alloc] initWithRequest:request paginationMapping:self.paginationMapping responseDescriptors:@[ self.responseDescriptor ]];
    __block NSArray *blockObjects = nil;
    [paginator setCompletionBlockWithSuccess:^(RKPaginator *paginator, NSArray *objects, NSUInteger page) {
        blockObjects = objects;
    } failure:nil];
    [paginator loadPage:1];
    expect(blockObjects).willNot.beNil();
}

- (void)testLoadingNextPageOfObjects
{
    NSURLRequest *request = [NSURLRequest requestWithURL:self.paginationURL];
    RKPaginator *paginator = [[RKPaginator alloc] initWithRequest:request paginationMapping:self.paginationMapping responseDescriptors:@[ self.responseDescriptor ]];
    [paginator loadPage:1];
    [paginator waitUntilFinished];
    expect(paginator.currentPage).to.equal(1);
    [paginator loadNextPage];
    [paginator waitUntilFinished];
    expect(paginator.currentPage).to.equal(2);
    NSArray *names = @[ @"Asia", @"Roy", @"Lola" ];
    expect([[paginator.mappingResult array] valueForKey:@"name"]).to.equal(names);
}

- (void)testLoadingPreviousPageOfObjects
{
    NSURLRequest *request = [NSURLRequest requestWithURL:self.paginationURL];
    RKPaginator *paginator = [[RKPaginator alloc] initWithRequest:request paginationMapping:self.paginationMapping responseDescriptors:@[ self.responseDescriptor ]];
    [paginator loadPage:2];
    [paginator waitUntilFinished];
    expect(paginator.currentPage).to.equal(2);
    [paginator loadPreviousPage];
    [paginator waitUntilFinished];
    expect(paginator.currentPage).to.equal(1);
    NSArray *names = @[ @"Blake", @"Sarah", @"Colin" ];
    expect([[paginator.mappingResult array] valueForKey:@"name"]).to.equal(names);
}

- (void)testFailureWhenLoadingAPageOfObjects
{
    NSURLRequest *request = [NSURLRequest requestWithURL:self.paginationURL];
    RKPaginator *paginator = [[RKPaginator alloc] initWithRequest:request paginationMapping:self.paginationMapping responseDescriptors:@[ self.responseDescriptor ]];
    [paginator loadPage:3];
    [paginator waitUntilFinished];
    expect(paginator.error).willNot.beNil();
}

- (void)testKnowledgeOfHasANextPage
{
    RKPaginator *paginator = [RKPaginator new];
    id mockPaginator = [OCMockObject partialMockForObject:paginator];
    BOOL isLoaded = YES;
    NSUInteger perPage = 5;
    NSUInteger pageCount = 3;
    [[[mockPaginator stub] andReturnValue:OCMOCK_VALUE(isLoaded)] isLoaded];
    [[[mockPaginator stub] andReturnValue:OCMOCK_VALUE(perPage)] perPage];
    [[[mockPaginator stub] andReturnValue:OCMOCK_VALUE(pageCount)] pageCount];

    NSUInteger currentPage = 1;
    [[[mockPaginator expect] andReturnValue:OCMOCK_VALUE(currentPage)] currentPage];
    assertThatBool([mockPaginator hasNextPage], is(equalToBool(YES)));
    currentPage = 2;
    [[[mockPaginator expect] andReturnValue:OCMOCK_VALUE(currentPage)] currentPage];
    assertThatBool([mockPaginator hasNextPage], is(equalToBool(YES)));
    currentPage = 3;
    [[[mockPaginator expect] andReturnValue:OCMOCK_VALUE(currentPage)] currentPage];
    assertThatBool([mockPaginator hasNextPage], is(equalToBool(NO)));
}

- (void)testHasNextPageRaisesExpectionWhenNotLoaded
{
    RKPaginator *paginator = [RKPaginator new];
    id mockPaginator = [OCMockObject partialMockForObject:paginator];
    BOOL loaded = NO;
    [[[mockPaginator stub] andReturnValue:OCMOCK_VALUE(loaded)] isLoaded];
    STAssertThrows([mockPaginator hasNextPage], @"Expected exception due to isLoaded == NO");
}

- (void)testHasNextPageRaisesExpectionWhenPageCountIsUnknown
{
    RKPaginator *paginator = [RKPaginator new];
    id mockPaginator = [OCMockObject partialMockForObject:paginator];
    BOOL loaded = YES;
    [[[mockPaginator stub] andReturnValue:OCMOCK_VALUE(loaded)] isLoaded];
    BOOL hasPageCount = NO;
    [[[mockPaginator stub] andReturnValue:OCMOCK_VALUE(hasPageCount)] hasPageCount];
    STAssertThrows([mockPaginator hasNextPage], @"Expected exception due to pageCount == NSUIntegerMax");
}

- (void)testHasPreviousPageRaisesExpectionWhenNotLoaded
{
    RKPaginator *paginator = [RKPaginator new];
    id mockPaginator = [OCMockObject partialMockForObject:paginator];
    BOOL loaded = NO;
    [[[mockPaginator stub] andReturnValue:OCMOCK_VALUE(loaded)] isLoaded];
    STAssertThrows([mockPaginator hasPreviousPage], @"Expected exception due to isLoaded == NO");
}

- (void)testKnowledgeOfPreviousPage
{
    RKPaginator *paginator = [RKPaginator new];
    id mockPaginator = [OCMockObject partialMockForObject:paginator];
    BOOL isLoaded = YES;
    NSUInteger perPage = 5;
    NSUInteger pageCount = 3;
    [[[mockPaginator stub] andReturnValue:OCMOCK_VALUE(isLoaded)] isLoaded];
    [[[mockPaginator stub] andReturnValue:OCMOCK_VALUE(perPage)] perPage];
    [[[mockPaginator stub] andReturnValue:OCMOCK_VALUE(pageCount)] pageCount];

    NSUInteger currentPage = 3;
    [[[mockPaginator expect] andReturnValue:OCMOCK_VALUE(currentPage)] currentPage];
    assertThatBool([mockPaginator hasPreviousPage], is(equalToBool(YES)));
    currentPage = 2;
    [[[mockPaginator expect] andReturnValue:OCMOCK_VALUE(currentPage)] currentPage];
    assertThatBool([mockPaginator hasPreviousPage], is(equalToBool(YES)));
    currentPage = 1;
    [[[mockPaginator expect] andReturnValue:OCMOCK_VALUE(currentPage)] currentPage];
    assertThatBool([mockPaginator hasPreviousPage], is(equalToBool(NO)));
}

- (void)testProxyAttributes
{
    RKPaginator *paginator = [RKPaginator new];
    [paginator setValue:@(12345) forKey:@"pageCountNumber"];
    expect(paginator.pageCount).to.equal(12345);
    expect([paginator valueForKey:@"pageCountNumber"]).to.equal(12345);
    
    [paginator setValue:@(1) forKey:@"currentPageNumber"];
    expect(paginator.currentPage).to.equal(1);
    expect([paginator valueForKey:@"currentPageNumber"]).to.equal(1);
    
    [paginator setValue:@(25) forKey:@"objectCountNumber"];
    expect(paginator.objectCount).to.equal(25);
    expect([paginator valueForKey:@"objectCountNumber"]).to.equal(25);
    
    [paginator setValue:@(10) forKey:@"perPageNumber"];
    expect(paginator.perPage).to.equal(10);
    expect([paginator valueForKey:@"perPageNumber"]).to.equal(10);
}

- (void)testPaginatorWithPaginationURLThatIncludesTrailingSlash
{
    NSURL *paginationURL = [NSURL URLWithString:@"/paginate/?per_page=:perPage&page=:currentPage" relativeToURL:[RKTestFactory baseURL]];
    NSURLRequest *request = [NSURLRequest requestWithURL:paginationURL];
    RKPaginator *paginator = [[RKPaginator alloc] initWithRequest:request paginationMapping:self.paginationMapping responseDescriptors:@[ self.responseDescriptor ]];
    __block NSArray *blockObjects = nil;
    [paginator setCompletionBlockWithSuccess:^(RKPaginator *paginator, NSArray *objects, NSUInteger page) {
        blockObjects = objects;
    } failure:nil];
    [paginator loadPage:1];
    [paginator waitUntilFinished];
    expect(blockObjects).willNot.beNil();
    expect(paginator.pageCount).to.equal(0);
    expect(paginator.objectCount).to.equal(0);
}

- (void)testOffsetNumberOfNextPage
{
    NSURLRequest *request = [NSURLRequest requestWithURL:self.paginationURL];
    RKPaginator *paginator = [[RKPaginator alloc] initWithRequest:request paginationMapping:self.paginationMapping responseDescriptors:@[ self.responseDescriptor ]];
    [paginator loadPage:1];
    [paginator waitUntilFinished];
    expect(paginator.offset).to.equal(0);
    [paginator loadNextPage];
    [paginator waitUntilFinished];
    expect(paginator.offset).to.equal(3);
}

@end
