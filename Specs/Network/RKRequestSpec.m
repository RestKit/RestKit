//
//  RKRequestSpec.m
//  RestKit
//
//  Created by Blake Watters on 1/15/10.
//  Copyright 2010 Two Toasters
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
#import "RKRequest.h"
#import "RKParams.h"
#import "RKResponse.h"
#import "RKURL.h"
#import "RKDirectory.h"

@interface RKRequest (Private)
- (void)fireAsynchronousRequest;
- (void)shouldDispatchRequest;
@end

@interface RKRequestSpec : RKSpec {
}

@end

@implementation RKRequestSpec

- (void)setUp {
    // Clear the cache directory
    RKSpecClearCacheDirectory();
}

/**
 * This spec requires the test Sinatra server to be running
 * `ruby Specs/server.rb`
 */
- (void)testShouldSendMultiPartRequests {
	NSString* URLString = [NSString stringWithFormat:@"http://127.0.0.1:4567/photo"];
	NSURL* URL = [NSURL URLWithString:URLString];
    RKSpecStubNetworkAvailability(YES);
	RKRequest* request = [[RKRequest alloc] initWithURL:URL];
	RKParams* params = [[RKParams params] retain];
    NSBundle *testBundle = [NSBundle bundleWithIdentifier:@"org.restkit.unit-tests"];
	NSString* filePath = [testBundle pathForResource:@"blake" ofType:@"png"];
	[params setFile:filePath forParam:@"file"];
	[params setValue:@"this is the value" forParam:@"test"];
	request.method = RKRequestMethodPOST;
	request.params = params;
	RKResponse* response = [request sendSynchronously];
	assertThatInteger(response.statusCode, is(equalToInt(200)));
}

#pragma mark - Basics

- (void)testShouldSetURLRequestHTTPBody {
    NSURL* URL = [NSURL URLWithString:RKSpecGetBaseURL()];
    RKRequest* request = [[RKRequest alloc] initWithURL:URL];
    NSString* JSON = @"whatever";
    NSData* data = [JSON dataUsingEncoding:NSASCIIStringEncoding];
    request.HTTPBody = data;
    assertThat(request.URLRequest.HTTPBody, equalTo(data));
    assertThat(request.HTTPBody, equalTo(data));
    assertThat(request.HTTPBodyString, equalTo(JSON));
}

- (void)testShouldSetURLRequestHTTPBodyByString {
    NSURL* URL = [NSURL URLWithString:RKSpecGetBaseURL()];
    RKRequest* request = [[RKRequest alloc] initWithURL:URL];
    NSString* JSON = @"whatever";
    NSData* data = [JSON dataUsingEncoding:NSASCIIStringEncoding];
    request.HTTPBodyString = JSON;
    assertThat(request.URLRequest.HTTPBody, equalTo(data));
    assertThat(request.HTTPBody, equalTo(data));
    assertThat(request.HTTPBodyString, equalTo(JSON));
}

#pragma mark - Background Policies

#if TARGET_OS_IPHONE

- (void)testShouldSendTheRequestWhenBackgroundPolicyIsRKRequestBackgroundPolicyNone {
    RKSpecStubNetworkAvailability(YES);
	NSURL* URL = [NSURL URLWithString:RKSpecGetBaseURL()];
	RKRequest* request = [[RKRequest alloc] initWithURL:URL];
    request.backgroundPolicy = RKRequestBackgroundPolicyNone;
    id requestMock = [OCMockObject partialMockForObject:request];
    [[requestMock expect] fireAsynchronousRequest]; // Not sure what else to test on this case
    [request sendAsynchronously];
    [requestMock verify];
}

- (UIApplication *)sharedApplicationMock {
    id mockApplication = [OCMockObject mockForClass:[UIApplication class]];
    return mockApplication;
}

- (void)stubSharedApplicationWhileExecutingBlock:(void (^)(void))block {
    [self swizzleMethod:@selector(sharedApplication) 
                inClass:[UIApplication class] 
             withMethod:@selector(sharedApplicationMock) 
              fromClass:[self class] 
           executeBlock:block];
}

- (void)testShouldObserveForAppBackgroundTransitionsAndCancelTheRequestWhenBackgroundPolicyIsRKRequestBackgroundPolicyCancel {
    [self stubSharedApplicationWhileExecutingBlock:^{
        NSURL* URL = [NSURL URLWithString:RKSpecGetBaseURL()];
        RKRequest* request = [[RKRequest alloc] initWithURL:URL];
        request.backgroundPolicy = RKRequestBackgroundPolicyCancel;
        id requestMock = [OCMockObject partialMockForObject:request];
        [[requestMock expect] cancel];
        [requestMock sendAsynchronously];
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
        [requestMock verify];
        [request release];
    }];
}

- (void)testShouldInformTheDelegateOfCancelWhenTheRequestWhenBackgroundPolicyIsRKRequestBackgroundPolicyCancel {
    [self stubSharedApplicationWhileExecutingBlock:^{
        RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
        NSURL* URL = [NSURL URLWithString:RKSpecGetBaseURL()];
        RKRequest* request = [[RKRequest alloc] initWithURL:URL];
        request.backgroundPolicy = RKRequestBackgroundPolicyCancel;
        request.delegate = loader;
        [request sendAsynchronously];
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
        assertThatBool(loader.wasCancelled, is(equalToBool(YES)));
        [request release];
    }];    
}

- (void)testShouldPutTheRequestBackOntoTheQueueWhenBackgroundPolicyIsRKRequestBackgroundPolicyRequeue {
    [self stubSharedApplicationWhileExecutingBlock:^{
        RKRequestQueue* queue = [RKRequestQueue new];
        queue.suspended = YES;
        RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
        NSURL* URL = [NSURL URLWithString:RKSpecGetBaseURL()];
        RKRequest* request = [[RKRequest alloc] initWithURL:URL];
        request.backgroundPolicy = RKRequestBackgroundPolicyRequeue;
        request.delegate = loader;
        request.queue = queue;
        [request sendAsynchronously];
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
        assertThatBool([request isLoading], is(equalToBool(NO)));
        assertThatBool([queue containsRequest:request], is(equalToBool(YES)));
        [queue release];
    }];
}

- (void)testShouldCreateABackgroundTaskWhenBackgroundPolicyIsRKRequestBackgroundPolicyContinue {
    NSURL* URL = [NSURL URLWithString:RKSpecGetBaseURL()];
    RKRequest* request = [[RKRequest alloc] initWithURL:URL];
    request.backgroundPolicy = RKRequestBackgroundPolicyContinue;
    [request sendAsynchronously];
    assertThatInt(request.backgroundTaskIdentifier, equalToInt(UIBackgroundTaskInvalid));
}

- (void)testShouldSendTheRequestWhenBackgroundPolicyIsNone {
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    NSURL* URL = [NSURL URLWithString:RKSpecGetBaseURL()];
    RKRequest* request = [[RKRequest alloc] initWithURL:URL];
    request.backgroundPolicy = RKRequestBackgroundPolicyNone;
    request.delegate = loader;
    [request sendAsynchronously];
    [loader waitForResponse];
    assertThatBool([loader success], is(equalToBool(YES)));
}

- (void)testShouldSendTheRequestWhenBackgroundPolicyIsContinue {
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    NSURL* URL = [NSURL URLWithString:RKSpecGetBaseURL()];
    RKRequest* request = [[RKRequest alloc] initWithURL:URL];
    request.backgroundPolicy = RKRequestBackgroundPolicyContinue;
    request.delegate = loader;
    [request sendAsynchronously];
    [loader waitForResponse];
    assertThatBool([loader success], is(equalToBool(YES)));
}

- (void)testShouldSendTheRequestWhenBackgroundPolicyIsCancel {
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    NSURL* URL = [NSURL URLWithString:RKSpecGetBaseURL()];
    RKRequest* request = [[RKRequest alloc] initWithURL:URL];
    request.backgroundPolicy = RKRequestBackgroundPolicyCancel;
    request.delegate = loader;
    [request sendAsynchronously];
    [loader waitForResponse];
    assertThatBool([loader success], is(equalToBool(YES)));
}

- (void)testShouldSendTheRequestWhenBackgroundPolicyIsRequeue {
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    NSURL* URL = [NSURL URLWithString:RKSpecGetBaseURL()];
    RKRequest* request = [[RKRequest alloc] initWithURL:URL];
    request.backgroundPolicy = RKRequestBackgroundPolicyRequeue;
    request.delegate = loader;
    [request sendAsynchronously];
    [loader waitForResponse];
    assertThatBool([loader success], is(equalToBool(YES)));
}

#endif

#pragma mark RKRequestCachePolicy Specs

- (void)testShouldSendTheRequestWhenTheCachePolicyIsNone {
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    NSString* url = [NSString stringWithFormat:@"%@/etags", RKSpecGetBaseURL()];
    NSURL* URL = [NSURL URLWithString:url];
    RKRequest* request = [[RKRequest alloc] initWithURL:URL];
    request.cachePolicy = RKRequestCachePolicyNone;
    request.delegate = loader;
    [request sendAsynchronously];
    [loader waitForResponse];
    assertThatBool([loader success], is(equalToBool(YES)));
}

- (void)testShouldCacheTheRequestHeadersAndBodyIncludingOurOwnCustomTimestampHeader {
    NSString* baseURL = RKSpecGetBaseURL();
    NSString* cacheDirForClient = [NSString stringWithFormat:@"RKClientRequestCache-%@",
								   [[NSURL URLWithString:baseURL] host]];
	NSString* cachePath = [[RKDirectory cachesDirectory]
						   stringByAppendingPathComponent:cacheDirForClient];
    RKRequestCache* cache = [[RKRequestCache alloc] initWithCachePath:cachePath
                                                        storagePolicy:RKRequestCacheStoragePolicyPermanently];
    [cache invalidateWithStoragePolicy:RKRequestCacheStoragePolicyPermanently];

    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    NSString* url = [NSString stringWithFormat:@"%@/etags/cached", RKSpecGetBaseURL()];
    NSURL* URL = [NSURL URLWithString:url];
    RKRequest* request = [[RKRequest alloc] initWithURL:URL];
    request.cachePolicy = RKRequestCachePolicyEtag;
    request.cache = cache;
    request.delegate = loader;
    [request sendAsynchronously];
    [loader waitForResponse];
    assertThatBool([loader success], is(equalToBool(YES)));
    NSDictionary* headers = [cache headersForRequest:request];
    assertThat([headers valueForKey:@"X-RESTKIT-CACHEDATE"], isNot(nilValue()));
    assertThat([headers valueForKey:@"Etag"], is(equalTo(@"686897696a7c876b7e")));
    assertThat([[cache responseForRequest:request] bodyAsString], is(equalTo(@"This Should Get Cached")));
}

- (void)testShouldGenerateAUniqueCacheKeyBasedOnTheUrlTheMethodAndTheHTTPBody {
    NSString* baseURL = RKSpecGetBaseURL();
    NSString* cacheDirForClient = [NSString stringWithFormat:@"RKClientRequestCache-%@",
								   [[NSURL URLWithString:baseURL] host]];
	NSString* cachePath = [[RKDirectory cachesDirectory]
						   stringByAppendingPathComponent:cacheDirForClient];
    RKRequestCache* cache = [[RKRequestCache alloc] initWithCachePath:cachePath
                                                        storagePolicy:RKRequestCacheStoragePolicyPermanently];
    [cache invalidateWithStoragePolicy:RKRequestCacheStoragePolicyPermanently];
    
    NSString* url = [NSString stringWithFormat:@"%@/etags/cached", RKSpecGetBaseURL()];
    NSURL* URL = [NSURL URLWithString:url];
    RKRequest* request = [[RKRequest alloc] initWithURL:URL];
    request.cachePolicy = RKRequestCachePolicyEtag;
    request.method = RKRequestMethodDELETE;
    // Don't cache delete. cache key should be nil.
    assertThat([request cacheKey], is(nilValue()));
    
    request.method = RKRequestMethodPOST;
    assertThat([request cacheKey], isNot(nilValue()));
    assertThat([request cacheKey], is(equalTo(@"bb373e6316a78f3f0322aa1e5f5818e2")));
    
    request.method = RKRequestMethodPUT;
    assertThat([request cacheKey], isNot(nilValue()));
    assertThat([request cacheKey], is(equalTo(@"aba9267af702ee12cd49b5a2615df182")));    
}

- (void)testShouldLoadFromCacheWhenWeRecieveA304 {
    NSString* baseURL = RKSpecGetBaseURL();
    NSString* cacheDirForClient = [NSString stringWithFormat:@"RKClientRequestCache-%@",
								   [[NSURL URLWithString:baseURL] host]];
	NSString* cachePath = [[RKDirectory cachesDirectory]
						   stringByAppendingPathComponent:cacheDirForClient];
    RKRequestCache* cache = [[RKRequestCache alloc] initWithCachePath:cachePath
                                storagePolicy:RKRequestCacheStoragePolicyPermanently];
    [cache invalidateWithStoragePolicy:RKRequestCacheStoragePolicyPermanently];
    {
        RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
        NSString* url = [NSString stringWithFormat:@"%@/etags/cached", RKSpecGetBaseURL()];
        NSURL* URL = [NSURL URLWithString:url];
        RKRequest* request = [[RKRequest alloc] initWithURL:URL];
        request.cachePolicy = RKRequestCachePolicyEtag;
        request.cache = cache;
        request.delegate = loader;
        [request sendAsynchronously];
        [loader waitForResponse];
        assertThatBool([loader success], is(equalToBool(YES)));
        assertThat([loader.response bodyAsString], is(equalTo(@"This Should Get Cached")));
        assertThat([cache etagForRequest:request], is(equalTo(@"686897696a7c876b7e")));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(NO)));
    }
    {
        RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
        NSString* url = [NSString stringWithFormat:@"%@/etags/cached", RKSpecGetBaseURL()];
        NSURL* URL = [NSURL URLWithString:url];
        RKRequest* request = [[RKRequest alloc] initWithURL:URL];
        request.cachePolicy = RKRequestCachePolicyEtag;
        request.cache = cache;
        request.delegate = loader;
        [request sendAsynchronously];
        [loader waitForResponse];
        assertThatBool([loader success], is(equalToBool(YES)));
        assertThat([loader.response bodyAsString], is(equalTo(@"This Should Get Cached")));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(YES)));
    }
}

- (void)testShouldUpdateTheInternalCacheDateWhenWeRecieveA304 {
    NSString* baseURL = RKSpecGetBaseURL();
    NSString* cacheDirForClient = [NSString stringWithFormat:@"RKClientRequestCache-%@",
								   [[NSURL URLWithString:baseURL] host]];
	NSString* cachePath = [[RKDirectory cachesDirectory]
						   stringByAppendingPathComponent:cacheDirForClient];
    RKRequestCache* cache = [[RKRequestCache alloc] initWithCachePath:cachePath
                                                        storagePolicy:RKRequestCacheStoragePolicyPermanently];
    [cache invalidateWithStoragePolicy:RKRequestCacheStoragePolicyPermanently];
    
    NSDate* internalCacheDate1;
    NSDate* internalCacheDate2;
    {
        RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
        NSString* url = [NSString stringWithFormat:@"%@/etags/cached", RKSpecGetBaseURL()];
        NSURL* URL = [NSURL URLWithString:url];
        RKRequest* request = [[RKRequest alloc] initWithURL:URL];
        request.cachePolicy = RKRequestCachePolicyEtag;
        request.cache = cache;
        request.delegate = loader;
        [request sendAsynchronously];
        [loader waitForResponse];
        assertThatBool([loader success], is(equalToBool(YES)));
        assertThat([loader.response bodyAsString], is(equalTo(@"This Should Get Cached")));
        assertThat([cache etagForRequest:request], is(equalTo(@"686897696a7c876b7e")));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(NO)));
        internalCacheDate1 = [cache cacheDateForRequest:request];
    }
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.5]];
    {
        RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
        NSString* url = [NSString stringWithFormat:@"%@/etags/cached", RKSpecGetBaseURL()];
        NSURL* URL = [NSURL URLWithString:url];
        RKRequest* request = [[RKRequest alloc] initWithURL:URL];
        request.cachePolicy = RKRequestCachePolicyEtag;
        request.cache = cache;
        request.delegate = loader;
        [request sendAsynchronously];
        [loader waitForResponse];
        assertThatBool([loader success], is(equalToBool(YES)));
        assertThat([loader.response bodyAsString], is(equalTo(@"This Should Get Cached")));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(YES)));
        internalCacheDate2 = [cache cacheDateForRequest:request];
    }
    assertThat(internalCacheDate1, isNot(internalCacheDate2));
}

- (void)testShouldLoadFromTheCacheIfThereIsAnError {
    NSString* baseURL = RKSpecGetBaseURL();
    NSString* cacheDirForClient = [NSString stringWithFormat:@"RKClientRequestCache-%@",
								   [[NSURL URLWithString:baseURL] host]];
	NSString* cachePath = [[RKDirectory cachesDirectory]
						   stringByAppendingPathComponent:cacheDirForClient];
    RKRequestCache* cache = [[RKRequestCache alloc] initWithCachePath:cachePath
                                                        storagePolicy:RKRequestCacheStoragePolicyPermanently];
    [cache invalidateWithStoragePolicy:RKRequestCacheStoragePolicyPermanently];
    
    {
        RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
        NSString* url = [NSString stringWithFormat:@"%@/etags/cached", RKSpecGetBaseURL()];
        NSURL* URL = [NSURL URLWithString:url];
        RKRequest* request = [[RKRequest alloc] initWithURL:URL];
        request.cachePolicy = RKRequestCachePolicyEtag;
        request.cache = cache;
        request.delegate = loader;
        [request sendAsynchronously];
        [loader waitForResponse];
        assertThatBool([loader success], is(equalToBool(YES)));
        assertThat([loader.response bodyAsString], is(equalTo(@"This Should Get Cached")));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(NO)));
    }
    {
        RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
        NSString* url = [NSString stringWithFormat:@"%@/etags/cached", RKSpecGetBaseURL()];
        NSURL* URL = [NSURL URLWithString:url];
        RKRequest* request = [[RKRequest alloc] initWithURL:URL];
        request.cachePolicy = RKRequestCachePolicyLoadOnError;
        request.cache = cache;
        request.delegate = loader;
        [request didFailLoadWithError:[NSError errorWithDomain:@"Fake" code:0 userInfo:nil]];
        assertThat([loader.response bodyAsString], is(equalTo(@"This Should Get Cached")));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(YES)));
    }
}

- (void)testShouldLoadFromTheCacheIfWeAreWithinTheTimeout {
    NSString* baseURL = RKSpecGetBaseURL();
    NSString* cacheDirForClient = [NSString stringWithFormat:@"RKClientRequestCache-%@",
								   [[NSURL URLWithString:baseURL] host]];
	NSString* cachePath = [[RKDirectory cachesDirectory]
						   stringByAppendingPathComponent:cacheDirForClient];
    RKRequestCache* cache = [[RKRequestCache alloc] initWithCachePath:cachePath
                                                        storagePolicy:RKRequestCacheStoragePolicyPermanently];
    [cache invalidateWithStoragePolicy:RKRequestCacheStoragePolicyPermanently];
    
    NSString* url = [NSString stringWithFormat:@"%@/disk/cached", RKSpecGetBaseURL()];
    NSURL* URL = [NSURL URLWithString:url];
    {
        RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
        RKRequest* request = [[RKRequest alloc] initWithURL:URL];
        request.cachePolicy = RKRequestCachePolicyTimeout;
        request.cacheTimeoutInterval = 5;
        request.cache = cache;
        request.delegate = loader;
        [request sendAsynchronously];
        [loader waitForResponse];
        assertThatBool([loader success], is(equalToBool(YES)));
        assertThat([loader.response bodyAsString], is(equalTo(@"This Should Get Cached For 5 Seconds")));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(NO)));
    }
    {
        RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
        RKRequest* request = [[RKRequest alloc] initWithURL:URL];
        request.cachePolicy = RKRequestCachePolicyTimeout;
        request.cacheTimeoutInterval = 5;
        request.cache = cache;
        request.delegate = loader;
        [request sendAsynchronously];
        // Don't wait for a response as this actually returns synchronously.
        assertThat([loader.response bodyAsString], is(equalTo(@"This Should Get Cached For 5 Seconds")));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(YES)));
    }
    {
        RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
        RKRequest* request = [[RKRequest alloc] initWithURL:URL];
        request.cachePolicy = RKRequestCachePolicyTimeout;
        request.cacheTimeoutInterval = 5;
        request.cache = cache;
        request.delegate = loader;
        [request sendSynchronously];
        // Don't wait for a response as this actually returns synchronously.
        assertThat([loader.response bodyAsString], is(equalTo(@"This Should Get Cached For 5 Seconds")));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(YES)));
    }
    {
        RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
        RKRequest* request = [[RKRequest alloc] initWithURL:URL];
        request.cachePolicy = RKRequestCachePolicyTimeout;
        request.cacheTimeoutInterval = 0;
        request.cache = cache;
        request.delegate = loader;
        [request sendAsynchronously];
        [loader waitForResponse];
        assertThatBool([loader success], is(equalToBool(YES)));
        assertThat([loader.response bodyAsString], is(equalTo(@"This Should Get Cached For 5 Seconds")));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(NO)));
    }
}

- (void)testShouldLoadFromTheCacheIfWeAreOffline {
    NSString* baseURL = RKSpecGetBaseURL();
    NSString* cacheDirForClient = [NSString stringWithFormat:@"RKClientRequestCache-%@",
								   [[NSURL URLWithString:baseURL] host]];
	NSString* cachePath = [[RKDirectory cachesDirectory]
						   stringByAppendingPathComponent:cacheDirForClient];
    RKRequestCache* cache = [[RKRequestCache alloc] initWithCachePath:cachePath
                                                        storagePolicy:RKRequestCacheStoragePolicyPermanently];
    [cache invalidateWithStoragePolicy:RKRequestCacheStoragePolicyPermanently];
    
    {
        RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
        NSString* url = [NSString stringWithFormat:@"%@/etags/cached", RKSpecGetBaseURL()];
        NSURL* URL = [NSURL URLWithString:url];
        RKRequest* request = [[RKRequest alloc] initWithURL:URL];
        request.cachePolicy = RKRequestCachePolicyEtag;
        request.cache = cache;
        request.delegate = loader;
        [request sendAsynchronously];
        [loader waitForResponse];
        assertThatBool([loader success], is(equalToBool(YES)));
        assertThat([loader.response bodyAsString], is(equalTo(@"This Should Get Cached")));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(NO)));
    }
    {
        RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
        NSString* url = [NSString stringWithFormat:@"%@/etags/cached", RKSpecGetBaseURL()];
        NSURL* URL = [NSURL URLWithString:url];
        RKRequest* request = [[RKRequest alloc] initWithURL:URL];
        request.cachePolicy = RKRequestCachePolicyLoadIfOffline;
        request.cache = cache;
        request.delegate = loader;
        id mock = [OCMockObject partialMockForObject:request];
        BOOL returnValue = NO;
        [[[mock expect] andReturnValue:OCMOCK_VALUE(returnValue)] shouldDispatchRequest];
        [mock sendAsynchronously];
        assertThat([loader.response bodyAsString], is(equalTo(@"This Should Get Cached")));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(YES)));
    }
}

- (void)testShouldCacheTheStatusCodeMIMETypeAndURL {
    NSString* baseURL = RKSpecGetBaseURL();
    NSString* cacheDirForClient = [NSString stringWithFormat:@"RKClientRequestCache-%@",
								   [[NSURL URLWithString:baseURL] host]];
	NSString* cachePath = [[RKDirectory cachesDirectory]
						   stringByAppendingPathComponent:cacheDirForClient];
    
    RKRequestCache* cache = [[RKRequestCache alloc] initWithCachePath:cachePath
                                                        storagePolicy:RKRequestCacheStoragePolicyPermanently];
    [cache invalidateWithStoragePolicy:RKRequestCacheStoragePolicyPermanently];
    {
        RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
        NSString* url = [NSString stringWithFormat:@"%@/etags/cached", RKSpecGetBaseURL()];
        NSURL* URL = [NSURL URLWithString:url];
        RKRequest* request = [[RKRequest alloc] initWithURL:URL];
        request.cachePolicy = RKRequestCachePolicyEtag;
        request.cache = cache;
        request.delegate = loader;
        [request sendAsynchronously];
        [loader waitForResponse];
        assertThatBool([loader success], is(equalToBool(YES)));
        assertThat([loader.response bodyAsString], is(equalTo(@"This Should Get Cached")));
        NSLog(@"Headers: %@", [cache headersForRequest:request]);
        assertThat([cache etagForRequest:request], is(equalTo(@"686897696a7c876b7e")));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(NO)));
    }
    {
        RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
        NSString* url = [NSString stringWithFormat:@"%@/etags/cached", RKSpecGetBaseURL()];
        NSURL* URL = [NSURL URLWithString:url];
        RKRequest* request = [[RKRequest alloc] initWithURL:URL];
        request.cachePolicy = RKRequestCachePolicyEtag;
        request.cache = cache;
        request.delegate = loader;
        [request sendAsynchronously];
        [loader waitForResponse];
        assertThatBool([loader success], is(equalToBool(YES)));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(YES)));
        assertThatInteger(loader.response.statusCode, is(equalToInt(200)));
        assertThat(loader.response.MIMEType, is(equalTo(@"text/html")));
        assertThat([loader.response.URL absoluteString], is(equalTo(@"http://127.0.0.1:4567/etags/cached")));
    }
}

- (void)testShouldPostSimpleKeyValuesViaRKParams {
    RKParams* params = [RKParams params];
    
    [params setValue: @"hello" forParam:@"username"];
    [params setValue: @"password" forParam:@"password"];
    
    RKClient* client = RKSpecNewClient();
    client.cachePolicy = RKRequestCachePolicyNone;
    RKSpecStubNetworkAvailability(YES);
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    loader.timeout = 20;
    [client post:@"/echo_params" params:params delegate:loader];
    [loader waitForResponse];
    assertThat([loader.response bodyAsString], is(equalTo(@"{\"username\":\"hello\",\"password\":\"password\"}")));
}

- (void)testShouldSetAnEmptyContentBodyWhenParamsIsNil {
    RKClient* client = RKSpecNewClient();
    client.cachePolicy = RKRequestCachePolicyNone;
    RKSpecStubNetworkAvailability(YES);
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    loader.timeout = 20;
    RKRequest* request = [client get:@"/echo_params" delegate:loader];
    [loader waitForResponse];
    assertThat([request.URLRequest valueForHTTPHeaderField:@"Content-Length"], is(equalTo(@"0")));
}

- (void)testShouldSetAnEmptyContentBodyWhenQueryParamsIsAnEmptyDictionary {
    RKClient* client = RKSpecNewClient();
    client.cachePolicy = RKRequestCachePolicyNone;
    RKSpecStubNetworkAvailability(YES);
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    loader.timeout = 20;
    RKRequest* request = [client get:@"/echo_params" queryParams:[NSDictionary dictionary] delegate:loader];
    [loader waitForResponse];
    assertThat([request.URLRequest valueForHTTPHeaderField:@"Content-Length"], is(equalTo(@"0")));
}

- (void)testShouldPUTWithParams {
    RKClient* client = RKSpecNewClient();
    RKParams *params = [RKParams params];    
    [params setValue:@"ddss" forParam:@"username"];    
    [params setValue:@"aaaa@aa.com" forParam:@"email"];
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    [client put:@"/ping" params:params delegate:loader];
    [loader waitForResponse];
    assertThat([loader.response bodyAsString], is(equalTo(@"{\"username\":\"ddss\",\"email\":\"aaaa@aa.com\"}")));
}

- (void)testShouldAllowYouToChangeTheURL {
    NSURL* URL = [NSURL URLWithString:@"http://restkit.org/monkey"];
    RKRequest* request = [RKRequest requestWithURL:URL delegate:self];
    request.URL = [NSURL URLWithString:@"http://restkit.org/gorilla"];
    assertThat([request.URL absoluteString], is(equalTo(@"http://restkit.org/gorilla")));
}

- (void)testShouldAllowYouToChangeTheResourcePath {
    RKURL* URL = [RKURL URLWithBaseURLString:@"http://restkit.org" resourcePath:@"/monkey"];
    RKRequest* request = [RKRequest requestWithURL:URL delegate:self];
    request.resourcePath = @"/gorilla";
    assertThat(request.resourcePath, is(equalTo(@"/gorilla")));
}

- (void)testShouldRaiseAnExceptionWhenAttemptingToMutateResourcePathOnAnNSURL {
    NSURL* URL = [NSURL URLWithString:@"http://restkit.org/monkey"];
    RKRequest* request = [RKRequest requestWithURL:URL delegate:self];
    NSException* exception = nil;
    @try {
        request.resourcePath = @"/gorilla";
    }
    @catch (NSException* e) {
        exception = e;
    }
    @finally {
        assertThat(exception, is(notNilValue()));
    }
}

- (void)testShouldOptionallySkipSSLValidation {
    RKClient* client = RKSpecNewClient();
    client.disableCertificateValidation = YES;
    NSURL* URL = [NSURL URLWithString:@"https://blakewatters.com/"];
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    RKRequest* request = [RKRequest requestWithURL:URL delegate:loader];
    [request send];
    [loader waitForResponse];
    assertThatBool([loader.response isOK], is(equalToBool(YES)));
}

- (void)testShouldNotAddANonZeroContentLengthHeaderIfParamsIsSetAndThisIsAGETRequest {
    RKClient* client = RKSpecNewClient();
    client.disableCertificateValidation = YES;
    NSURL* URL = [NSURL URLWithString:@"https://blakewatters.com/"];
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    RKRequest* request = [RKRequest requestWithURL:URL delegate:loader];
    request.params = [NSDictionary dictionaryWithObject:@"foo" forKey:@"bar"];
    [request send];
    [loader waitForResponse];
    assertThat([request.URLRequest valueForHTTPHeaderField:@"Content-Length"], is(equalTo(@"0")));
}

- (void)testShouldNotAddANonZeroContentLengthHeaderIfParamsIsSetAndThisIsAHEADRequest {
    RKClient* client = RKSpecNewClient();
    client.disableCertificateValidation = YES;
    NSURL* URL = [NSURL URLWithString:@"https://blakewatters.com/"];
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    RKRequest* request = [RKRequest requestWithURL:URL delegate:loader];
    request.method = RKRequestMethodHEAD;
    request.params = [NSDictionary dictionaryWithObject:@"foo" forKey:@"bar"];
    [request send];
    [loader waitForResponse];
    assertThat([request.URLRequest valueForHTTPHeaderField:@"Content-Length"], is(equalTo(@"0")));
}

// TODO: Move to RKRequestCacheSpec
- (void)testShouldReturnACachePathWhenTheRequestIsUsingRKParams {
    RKParams *params = [RKParams params];
    [params setValue:@"foo" forParam:@"bar"];
    NSURL *URL = [NSURL URLWithString:@"http://restkit.org/"];
    RKRequest *request = [RKRequest requestWithURL:URL delegate:nil];
    request.params = params;
    NSString* baseURL = RKSpecGetBaseURL();
    NSString* cacheDirForClient = [NSString stringWithFormat:@"RKClientRequestCache-%@",
								   [[NSURL URLWithString:baseURL] host]];
    NSString* cachePath = [[RKDirectory cachesDirectory]
						   stringByAppendingPathComponent:cacheDirForClient];
    RKRequestCache *requestCache = [[RKRequestCache alloc] initWithCachePath:cachePath storagePolicy:RKRequestCacheStoragePolicyForDurationOfSession];
    NSString *requestCachePath = [requestCache pathForRequest:request];
    NSArray *pathComponents = [requestCachePath pathComponents];
    NSString *cacheFile = [NSString pathWithComponents:[pathComponents subarrayWithRange:NSMakeRange([pathComponents count] - 2, 2)]];
    assertThat(cacheFile, is(equalTo(@"SessionStore/4ba47367884760141da2e38fda525a1f")));
}

- (void)testShouldReturnNilForCachePathWhenTheRequestIsADELETE {
    RKParams *params = [RKParams params];
    [params setValue:@"foo" forParam:@"bar"];
    NSURL *URL = [NSURL URLWithString:@"http://restkit.org/"];
    RKRequest *request = [RKRequest requestWithURL:URL delegate:nil];
    request.method = RKRequestMethodDELETE;
    NSString* baseURL = RKSpecGetBaseURL();
    NSString* cacheDirForClient = [NSString stringWithFormat:@"RKClientRequestCache-%@",
								   [[NSURL URLWithString:baseURL] host]];
    NSString* cachePath = [[RKDirectory cachesDirectory]
						   stringByAppendingPathComponent:cacheDirForClient];
    RKRequestCache *requestCache = [[RKRequestCache alloc] initWithCachePath:cachePath storagePolicy:RKRequestCacheStoragePolicyForDurationOfSession];
    NSString *requestCachePath = [requestCache pathForRequest:request];
    assertThat(requestCachePath, is(nilValue()));
}

- (void)testShouldBuildAProperAuthorizationHeaderForOAuth1 {
    RKRequest *request = [RKRequest requestWithURL:[RKURL URLWithString:@"http://restkit.org/this?that=foo&bar=word"] delegate:nil];
    request.authenticationType = RKRequestAuthenticationTypeOAuth1;
    request.OAuth1AccessToken = @"12345";
    request.OAuth1AccessTokenSecret = @"monkey";
    request.OAuth1ConsumerKey = @"another key";
    request.OAuth1ConsumerSecret = @"more data";
    [request prepareURLRequest];
    NSString *authorization = [request.URLRequest valueForHTTPHeaderField:@"Authorization"];
    assertThat(authorization, isNot(nilValue()));
}
@end
