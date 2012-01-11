//
//  RKObjectPaginatorSpec.m
//  RestKit
//
//  Created by Blake Watters on 12/29/11.
//  Copyright (c) 2011 RestKit. All rights reserved.
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

#import "RKSpecEnvironment.h"
#import "RKObjectPaginator.h"
#import "RKObjectMapperSpecModel.h"

NSString * const RKSpecPaginatorDelegateTimeoutException = @"RKSpecPaginatorDelegateTimeoutException";

@interface RKSpecPaginatorDelegate : NSObject <RKObjectPaginatorDelegate>

@property (nonatomic, readonly, retain) NSArray *paginatedObjects;
@property (nonatomic, readonly, retain) NSError *paginationError;
@property (nonatomic, readonly) NSUInteger currentPage;
@property (nonatomic, readonly, getter = isLoading) BOOL loading;
@property (nonatomic, assign) NSTimeInterval timeout;

+ (RKSpecPaginatorDelegate *)paginatorDelegate;

- (BOOL)isLoaded;
- (BOOL)isError;
- (void)waitForLoad;

@end

@interface RKSpecPaginatorDelegate ()
@property (nonatomic, readwrite, retain) NSArray *paginatedObjects;
@property (nonatomic, readwrite, retain) NSError *paginationError;
@end

@implementation RKSpecPaginatorDelegate

@synthesize paginatedObjects;
@synthesize currentPage;
@synthesize paginationError;
@synthesize loading;
@synthesize timeout;

+ (RKSpecPaginatorDelegate *)paginatorDelegate {
    return [[self new] autorelease];
}

- (id)init {
    self = [super init];
    if (self) {
        currentPage = NSIntegerMax;
        timeout = 5;
    }
    
    return self;
}

- (void)dealloc {
    [paginatedObjects release];
    [paginationError release];    
    
    [super dealloc];
}

- (BOOL)isLoaded {
    return currentPage != NSIntegerMax;
}

- (BOOL)isError {
    return paginationError == nil;
}

- (void)waitForLoad {
    loading = YES;
    self.paginatedObjects = nil;
    self.paginationError = nil;
    
	NSDate* startDate = [NSDate date];
	
	while (loading) {		
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
		if ([[NSDate date] timeIntervalSinceDate:startDate] > self.timeout) {
			[NSException raise:@"RKSpecPaginatorDelegateTimeoutException" format:@"*** Operation timed out after %f seconds...", self.timeout];
			loading = NO;
		}
	}
}

#pragma mark - RKObjectPaginatorDelegate

- (void)paginator:(RKObjectPaginator *)paginator didLoadObjects:(NSArray *)objects forPage:(NSUInteger)page {
    loading = NO;
    self.paginatedObjects = objects;
    currentPage = page;
}

- (void)paginator:(RKObjectPaginator *)paginator didFailWithError:(NSError *)error objectLoader:(RKObjectLoader *)loader {
    loading = NO;
    self.paginationError = error;
}

@end

@interface RKObjectPaginatorSpec : RKSpec {
}

@end

@implementation RKObjectPaginatorSpec

static NSString * const RKObjectPaginatorSpecResourcePathPattern = @"/paginate?per_page=:perPage&page=:currentPage";

- (RKObjectMappingProvider *)paginationMappingProvider {
    RKObjectMapping *paginationMapping = [RKObjectMapping mappingForClass:[RKObjectPaginator class]];
    [paginationMapping mapKeyPath:@"current_page" toAttribute:@"currentPage"];
    [paginationMapping mapKeyPath:@"per_page" toAttribute:@"perPage"];
    [paginationMapping mapKeyPath:@"total_entries" toAttribute:@"objectCount"];
    
    RKObjectMapping *mapping = [RKObjectMapping mappingForClass:[RKObjectMapperSpecModel class]];
    [mapping mapAttributes:@"name", @"age", nil];
    RKObjectMappingProvider *mappingProvider = [RKObjectMappingProvider mappingProvider];
    mappingProvider.paginationMapping = paginationMapping;
    [mappingProvider setObjectMapping:mapping forKeyPath:@"entries"];
    
    return mappingProvider;
}

- (void)testInitCopiesPatternURL {
    RKURL *patternURL = [RKURL URLWithBaseURLString:@"http://restkit.org"];
    RKObjectPaginator *paginator = [RKObjectPaginator paginatorWithPatternURL:patternURL mappingProvider:nil];
    assertThat([paginator.patternURL absoluteString], is(equalTo(@"http://restkit.org")));
}

- (void)testInitRetainsMappingProvider {
    RKURL *patternURL = [RKURL URLWithBaseURLString:@"http://restkit.org" resourcePath:RKObjectPaginatorSpecResourcePathPattern];
    RKObjectMappingProvider *mappingProvider = [self paginationMappingProvider];
    RKObjectPaginator *paginator = [RKObjectPaginator paginatorWithPatternURL:patternURL mappingProvider:mappingProvider];
    assertThat(paginator.mappingProvider, is(equalTo(mappingProvider)));
}

- (void)testThatLoadWithNilMappingProviderRaisesException {
    RKURL *patternURL = [RKURL URLWithBaseURLString:@"http://restkit.org" resourcePath:RKObjectPaginatorSpecResourcePathPattern];
    RKObjectPaginator *paginator = [RKObjectPaginator paginatorWithPatternURL:patternURL mappingProvider:nil];
    NSException *exception = nil;
    @try {
        [paginator loadPage:1];
    }
    @catch (NSException *e) {
        exception = e;
    }
    @finally {
        assertThat(exception, is(notNilValue()));
    }
}

- (void)testThatResourcePathPatternEvaluatesAgainstPaginator {
    RKURL *patternURL = [RKURL URLWithBaseURLString:@"http://restkit.org" resourcePath:RKObjectPaginatorSpecResourcePathPattern];
    RKObjectPaginator *paginator = [RKObjectPaginator paginatorWithPatternURL:patternURL mappingProvider:nil];
    assertThat([[paginator URL] resourcePath], is(equalTo(@"/paginate?per_page=25&page=0")));
}

- (void)testThatURLReturnsReflectsStateOfPaginator {
    RKURL *patternURL = [RKURL URLWithBaseURLString:@"http://restkit.org" resourcePath:RKObjectPaginatorSpecResourcePathPattern];
    RKObjectPaginator *paginator = [RKObjectPaginator paginatorWithPatternURL:patternURL mappingProvider:nil];
    assertThat([[paginator URL] absoluteString], is(equalTo(@"http://restkit.org/paginate?page=0&per_page=25")));
}

- (void)testLoadingAPageOfObjects {
    RKURL *patternURL = [RKSpecGetBaseURL() URLByAppendingResourcePath:RKObjectPaginatorSpecResourcePathPattern];
    RKObjectMappingProvider *mappingProvider = [self paginationMappingProvider];
    RKSpecPaginatorDelegate *testDelegate = [RKSpecPaginatorDelegate paginatorDelegate];
    RKObjectPaginator *paginator = [RKObjectPaginator paginatorWithPatternURL:patternURL mappingProvider:mappingProvider];
    paginator.delegate = testDelegate;
    [paginator loadPage:1];
    [testDelegate waitForLoad];
    assertThatBool([testDelegate isLoaded], is(equalToBool(YES)));
}

- (void)testLoadingPageOfObjectMapsPerPage {
    RKURL *patternURL = [RKSpecGetBaseURL() URLByAppendingResourcePath:RKObjectPaginatorSpecResourcePathPattern];
    RKObjectMappingProvider *mappingProvider = [self paginationMappingProvider];
    RKObjectPaginator *paginator = [RKObjectPaginator paginatorWithPatternURL:patternURL mappingProvider:mappingProvider];
    RKSpecPaginatorDelegate *testDelegate = [RKSpecPaginatorDelegate paginatorDelegate];
    paginator.delegate = testDelegate;
    [paginator loadPage:1];
    [testDelegate waitForLoad];
    assertThatInteger(paginator.perPage, is(equalToInteger(2)));
}

- (void)testLoadingPageOfObjectMapsTotalEntries {
    RKURL *patternURL = [RKSpecGetBaseURL() URLByAppendingResourcePath:RKObjectPaginatorSpecResourcePathPattern];
    RKObjectMappingProvider *mappingProvider = [self paginationMappingProvider];
    RKObjectPaginator *paginator = [RKObjectPaginator paginatorWithPatternURL:patternURL mappingProvider:mappingProvider];
    RKSpecPaginatorDelegate *testDelegate = [RKSpecPaginatorDelegate paginatorDelegate];
    paginator.delegate = testDelegate;
    [paginator loadPage:1];
    [testDelegate waitForLoad];
    assertThatInteger(paginator.objectCount, is(equalToInteger(6)));
}

- (void)testLoadingPageOfObjectMapsCurrentPage {
    RKURL *patternURL = [RKSpecGetBaseURL() URLByAppendingResourcePath:RKObjectPaginatorSpecResourcePathPattern];
    RKObjectMappingProvider *mappingProvider = [self paginationMappingProvider];
    RKObjectPaginator *paginator = [RKObjectPaginator paginatorWithPatternURL:patternURL mappingProvider:mappingProvider];
    RKSpecPaginatorDelegate *testDelegate = [RKSpecPaginatorDelegate paginatorDelegate];
    paginator.delegate = testDelegate;
    [paginator loadPage:1];
    [testDelegate waitForLoad];
    assertThatInteger(paginator.currentPage, is(equalToInteger(1)));
}

- (void)testLoadingPageOfObjectMapsEntriesToObjects {
    RKURL *patternURL = [RKSpecGetBaseURL() URLByAppendingResourcePath:RKObjectPaginatorSpecResourcePathPattern];
    RKObjectMappingProvider *mappingProvider = [self paginationMappingProvider];
    RKObjectPaginator *paginator = [RKObjectPaginator paginatorWithPatternURL:patternURL mappingProvider:mappingProvider];
    RKSpecPaginatorDelegate *testDelegate = [RKSpecPaginatorDelegate paginatorDelegate];
    paginator.delegate = testDelegate;
    [paginator loadPage:1];
    [testDelegate waitForLoad];
    assertThatInteger([[testDelegate paginatedObjects] count], is(equalToInteger(3)));
    assertThat([[testDelegate paginatedObjects] valueForKey:@"name"], is(equalTo([NSArray arrayWithObjects:@"Blake", @"Sarah", @"Colin", nil])));
}

- (void)testDelegateIsInformedOnError {
    RKURL *patternURL = [RKSpecGetBaseURL() URLByAppendingResourcePath:RKObjectPaginatorSpecResourcePathPattern];
    RKObjectMappingProvider *mappingProvider = [self paginationMappingProvider];
    RKObjectPaginator *paginator = [RKObjectPaginator paginatorWithPatternURL:patternURL mappingProvider:mappingProvider];
    RKSpecPaginatorDelegate *testDelegate = [RKSpecPaginatorDelegate paginatorDelegate];
    id mockDelegate = [OCMockObject partialMockForObject:testDelegate];
    [[[mockDelegate expect] andForwardToRealObject] paginator:paginator didFailWithError:OCMOCK_ANY objectLoader:OCMOCK_ANY];
    paginator.delegate = mockDelegate;
    [paginator loadPage:999];
    [mockDelegate waitForLoad];
    [mockDelegate verify];
}

- (void)testLoadingNextPageOfObjects {
    RKURL *patternURL = [RKSpecGetBaseURL() URLByAppendingResourcePath:RKObjectPaginatorSpecResourcePathPattern];
    RKObjectMappingProvider *mappingProvider = [self paginationMappingProvider];
    RKObjectPaginator *paginator = [RKObjectPaginator paginatorWithPatternURL:patternURL mappingProvider:mappingProvider];
    RKSpecPaginatorDelegate *testDelegate = [RKSpecPaginatorDelegate paginatorDelegate];
    paginator.delegate = testDelegate;
    [paginator loadPage:1];
    [testDelegate waitForLoad];
    assertThatInteger(paginator.currentPage, is(equalToInteger(1)));
    [paginator loadNextPage];
    [testDelegate waitForLoad];
    assertThatInteger(paginator.currentPage, is(equalToInteger(2)));
    assertThat([[testDelegate paginatedObjects] valueForKey:@"name"], is(equalTo([NSArray arrayWithObjects:@"Asia", @"Roy", @"Lola", nil])));
}

- (void)testLoadingPreviousPageOfObjects {
    RKURL *patternURL = [RKSpecGetBaseURL() URLByAppendingResourcePath:RKObjectPaginatorSpecResourcePathPattern];
    RKObjectMappingProvider *mappingProvider = [self paginationMappingProvider];
    RKObjectPaginator *paginator = [RKObjectPaginator paginatorWithPatternURL:patternURL mappingProvider:mappingProvider];
    RKSpecPaginatorDelegate *testDelegate = [RKSpecPaginatorDelegate paginatorDelegate];
    paginator.delegate = testDelegate;
    [paginator loadPage:2];
    [testDelegate waitForLoad];
    assertThatInteger(paginator.currentPage, is(equalToInteger(2)));
    [paginator loadPreviousPage];
    [testDelegate waitForLoad];
    assertThatInteger(paginator.currentPage, is(equalToInteger(1)));
    assertThat([[testDelegate paginatedObjects] valueForKey:@"name"], is(equalTo([NSArray arrayWithObjects:@"Blake", @"Sarah", @"Colin", nil])));
}

- (void)testFailureWhenLoadingAPageOfObjects {
    RKURL *patternURL = [RKSpecGetBaseURL() URLByAppendingResourcePath:RKObjectPaginatorSpecResourcePathPattern];
    RKObjectMappingProvider *mappingProvider = [self paginationMappingProvider];
    RKObjectPaginator *paginator = [RKObjectPaginator paginatorWithPatternURL:patternURL mappingProvider:mappingProvider];
    RKSpecPaginatorDelegate *testDelegate = [RKSpecPaginatorDelegate paginatorDelegate];
    paginator.delegate = testDelegate;
    [paginator loadPage:3];
    [testDelegate waitForLoad];
    assertThat(testDelegate.paginationError, is(notNilValue()));
}

- (void)itShouldKnowIfItHasANextPage {
    RKObjectPaginator *paginator = [[RKObjectPaginator new] autorelease];
    id mockPaginator = [OCMockObject partialMockForObject:paginator];
    NSUInteger perPage = 5;
    NSUInteger currentPage = 1;
    NSUInteger objectCount = 10;
    [[[mockPaginator stub] andReturnValue:OCMOCK_VALUE(perPage)] perPage];
    [[[mockPaginator stub] andReturnValue:OCMOCK_VALUE(objectCount)] objectCount];    
    [[[mockPaginator stub] andReturnValue:OCMOCK_VALUE(currentPage)] currentPage];
    
    assertThatBool([mockPaginator hasNextPage], is(equalToBool(YES)));
    currentPage = 2;
    assertThatBool([mockPaginator hasNextPage], is(equalToBool(YES)));    
    currentPage = 3;
    assertThatBool([mockPaginator hasNextPage], is(equalToBool(NO)));
}

- (void)itShouldKnowIfItHasAPreviousPage {
    RKObjectPaginator *paginator = [[RKObjectPaginator new] autorelease];
    id mockPaginator = [OCMockObject partialMockForObject:paginator];
    NSUInteger perPage = 5;
    NSUInteger currentPage = 3;
    NSUInteger objectCount = 10;
    [[[mockPaginator stub] andReturnValue:OCMOCK_VALUE(perPage)] perPage];
    [[[mockPaginator stub] andReturnValue:OCMOCK_VALUE(objectCount)] objectCount];    
    [[[mockPaginator stub] andReturnValue:OCMOCK_VALUE(currentPage)] currentPage];
    
    assertThatBool([mockPaginator hasPreviousPage], is(equalToBool(YES)));
    currentPage = 2;
    assertThatBool([mockPaginator hasPreviousPage], is(equalToBool(YES)));    
    currentPage = 1;
    assertThatBool([mockPaginator hasPreviousPage], is(equalToBool(NO)));
}

@end
