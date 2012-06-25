//
//  RKRequestTest.m
//  RestKit
//
//  Created by Blake Watters on 1/15/10.
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
#import "RKRequest.h"
#import "RKParams.h"
#import "RKResponse.h"
#import "RKURL.h"
#import "RKDirectory.h"

@interface RKRequest (Private)
- (void)fireAsynchronousRequest;
- (void)shouldDispatchRequest;
@end

@interface RKRequestTest : RKTestCase {
    int _methodInvocationCounter;
}

@end

@implementation RKRequestTest

- (void)setUp
{
    [RKTestFactory setUp];

    // Clear the cache directory
    [RKTestFactory clearCacheDirectory];
    _methodInvocationCounter = 0;
}

- (void)tearDown
{
    [RKTestFactory tearDown];
}

- (int)incrementMethodInvocationCounter
{
    return _methodInvocationCounter++;
}

/**
 * This spec requires the test Sinatra server to be running
 * `ruby Tests/server.rb`
 */
- (void)testShouldSendMultiPartRequests
{
    NSString *URLString = [NSString stringWithFormat:@"http://127.0.0.1:4567/photo"];
    NSURL *URL = [NSURL URLWithString:URLString];
    RKRequest *request = [[RKRequest alloc] initWithURL:URL];
    RKParams *params = [[RKParams params] retain];
    NSString *filePath = [RKTestFixture pathForFixture:@"blake.png"];
    [params setFile:filePath forParam:@"file"];
    [params setValue:@"this is the value" forParam:@"test"];
    request.method = RKRequestMethodPOST;
    request.params = params;
    RKResponse *response = [request sendSynchronously];
    assertThatInteger(response.statusCode, is(equalToInt(200)));
}

#pragma mark - Basics

- (void)testShouldSetURLRequestHTTPBody
{
    NSURL *URL = [NSURL URLWithString:[RKTestFactory baseURLString]];
    RKRequest *request = [[RKRequest alloc] initWithURL:URL];
    NSString *JSON = @"whatever";
    NSData *data = [JSON dataUsingEncoding:NSASCIIStringEncoding];
    request.HTTPBody = data;
    assertThat(request.URLRequest.HTTPBody, equalTo(data));
    assertThat(request.HTTPBody, equalTo(data));
    assertThat(request.HTTPBodyString, equalTo(JSON));
}

- (void)testShouldSetURLRequestHTTPBodyByString
{
    NSURL *URL = [NSURL URLWithString:[RKTestFactory baseURLString]];
    RKRequest *request = [[RKRequest alloc] initWithURL:URL];
    NSString *JSON = @"whatever";
    NSData *data = [JSON dataUsingEncoding:NSASCIIStringEncoding];
    request.HTTPBodyString = JSON;
    assertThat(request.URLRequest.HTTPBody, equalTo(data));
    assertThat(request.HTTPBody, equalTo(data));
    assertThat(request.HTTPBodyString, equalTo(JSON));
}

- (void)testShouldTimeoutAtIntervalWhenSentAsynchronously
{
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    id loaderMock = [OCMockObject partialMockForObject:loader];
    NSURL *URL = [[RKTestFactory baseURL] URLByAppendingResourcePath:@"/timeout"];
    RKRequest *request = [[RKRequest alloc] initWithURL:URL];
    request.delegate = loaderMock;
    request.timeoutInterval = 3.0;
    [[[loaderMock expect] andForwardToRealObject] request:request didFailLoadWithError:OCMOCK_ANY];
    [request sendAsynchronously];
    [loaderMock waitForResponse];
    assertThatInt((int)loader.error.code, equalToInt(RKRequestConnectionTimeoutError));
    [request release];
}

- (void)testShouldTimeoutAtIntervalWhenSentSynchronously
{
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    id loaderMock = [OCMockObject partialMockForObject:loader];
    NSURL *URL = [[RKTestFactory baseURL] URLByAppendingResourcePath:@"/timeout"];
    RKRequest *request = [[RKRequest alloc] initWithURL:URL];
    request.delegate = loaderMock;
    request.timeoutInterval = 3.0;
    [[[loaderMock expect] andForwardToRealObject] request:request didFailLoadWithError:OCMOCK_ANY];
    [request sendSynchronously];
    assertThatInt((int)loader.error.code, equalToInt(RKRequestConnectionTimeoutError));
    [request release];
}

- (void)testShouldCreateOneTimeoutTimerWhenSentAsynchronously
{
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    RKRequest *request = [[RKRequest alloc] initWithURL:[RKTestFactory baseURL]];
    request.delegate = loader;
    id requestMock = [OCMockObject partialMockForObject:request];
    [[[requestMock expect] andCall:@selector(incrementMethodInvocationCounter) onObject:self] createTimeoutTimer];
    [requestMock sendAsynchronously];
    [loader waitForResponse];
    assertThatInt(_methodInvocationCounter, equalToInt(1));
    [request release];
}

- (void)testThatSendingDataInvalidatesTimeoutTimer
{
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    loader.timeout = 3.0;
    NSURL *URL = [[RKTestFactory baseURL] URLByAppendingResourcePath:@"/timeout"];
    RKRequest *request = [[RKRequest alloc] initWithURL:URL];
    request.method = RKRequestMethodPOST;
    request.delegate = loader;
    request.params = [NSDictionary dictionaryWithObject:@"test" forKey:@"test"];
request.timeoutInterval = 1.0;
    [request sendAsynchronously];
    [loader waitForResponse];
    assertThatBool([loader wasSuccessful], is(equalToBool(YES)));
    [request release];
}

- (void)testThatRunLoopModePropertyRespected
{
    NSString * const dummyRunLoopMode = @"dummyRunLoopMode";
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    RKRequest *request = [[RKRequest alloc] initWithURL:[RKTestFactory baseURL]];
    request.delegate = loader;
    request.runLoopMode = dummyRunLoopMode;
    [request sendAsynchronously];
    while ([[NSRunLoop currentRunLoop] runMode:dummyRunLoopMode beforeDate:[[NSRunLoop currentRunLoop] limitDateForMode:dummyRunLoopMode]])
        ;
    assertThatBool([loader wasSuccessful], is(equalToBool(YES)));
    [request release];
}

#pragma mark - Background Policies

#if TARGET_OS_IPHONE

- (void)testShouldSendTheRequestWhenBackgroundPolicyIsRKRequestBackgroundPolicyNone
{
    NSURL *URL = [RKTestFactory baseURL];
    RKRequest *request = [[RKRequest alloc] initWithURL:URL];
    request.backgroundPolicy = RKRequestBackgroundPolicyNone;
    id requestMock = [OCMockObject partialMockForObject:request];
    [[requestMock expect] fireAsynchronousRequest]; // Not sure what else to test on this case
    [request sendAsynchronously];
    [requestMock verify];
}

- (UIApplication *)sharedApplicationMock
{
    id mockApplication = [OCMockObject mockForClass:[UIApplication class]];
    return mockApplication;
}

- (void)stubSharedApplicationWhileExecutingBlock:(void (^)(void))block
{
    [self swizzleMethod:@selector(sharedApplication)
                inClass:[UIApplication class]
             withMethod:@selector(sharedApplicationMock)
              fromClass:[self class]
           executeBlock:block];
}

- (void)testShouldObserveForAppBackgroundTransitionsAndCancelTheRequestWhenBackgroundPolicyIsRKRequestBackgroundPolicyCancel
{
    [self stubSharedApplicationWhileExecutingBlock:^{
        NSURL *URL = [RKTestFactory baseURL];
        RKRequest *request = [[RKRequest alloc] initWithURL:URL];
        request.backgroundPolicy = RKRequestBackgroundPolicyCancel;
        id requestMock = [OCMockObject partialMockForObject:request];
        [[requestMock expect] cancel];
        [requestMock sendAsynchronously];
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
        [requestMock verify];
    }];
}

- (void)testShouldInformTheDelegateOfCancelWhenTheRequestWhenBackgroundPolicyIsRKRequestBackgroundPolicyCancel
{
    [RKTestFactory client];
    [self stubSharedApplicationWhileExecutingBlock:^{
        RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
        NSURL *URL = [RKTestFactory baseURL];
        RKRequest *request = [[RKRequest alloc] initWithURL:URL];
        request.backgroundPolicy = RKRequestBackgroundPolicyCancel;
        request.delegate = loader;
        [request sendAsynchronously];
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
        assertThatBool(loader.wasCancelled, is(equalToBool(YES)));
        [request release];
    }];
}

- (void)testShouldDeallocTheRequestWhenBackgroundPolicyIsRKRequestBackgroundPolicyCancel
{
    [RKTestFactory client];
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    NSURL *URL = [RKTestFactory baseURL];
    RKRequest *request = [[RKRequest alloc] initWithURL:URL];
    request.backgroundPolicy = RKRequestBackgroundPolicyCancel;
    request.delegate = loader;
    [request sendAsynchronously];
    [loader waitForResponse];
    assertThatInteger([request retainCount], is(equalToInteger(1)));
    [request release];
}

- (void)testShouldPutTheRequestBackOntoTheQueueWhenBackgroundPolicyIsRKRequestBackgroundPolicyRequeue
{
    [self stubSharedApplicationWhileExecutingBlock:^{
        RKRequestQueue *queue = [RKRequestQueue new];
        queue.suspended = YES;
        RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
        NSURL *URL = [RKTestFactory baseURL];
        RKRequest *request = [[RKRequest alloc] initWithURL:URL];
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

- (void)testShouldCreateABackgroundTaskWhenBackgroundPolicyIsRKRequestBackgroundPolicyContinue
{
    NSURL *URL = [RKTestFactory baseURL];
    RKRequest *request = [[RKRequest alloc] initWithURL:URL];
    request.backgroundPolicy = RKRequestBackgroundPolicyContinue;
    [request sendAsynchronously];
    assertThatInt(request.backgroundTaskIdentifier, equalToInt(UIBackgroundTaskInvalid));
}

- (void)testShouldSendTheRequestWhenBackgroundPolicyIsNone
{
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    NSURL *URL = [RKTestFactory baseURL];
    RKRequest *request = [[RKRequest alloc] initWithURL:URL];
    request.backgroundPolicy = RKRequestBackgroundPolicyNone;
    request.delegate = loader;
    [request sendAsynchronously];
    [loader waitForResponse];
    assertThatBool([loader wasSuccessful], is(equalToBool(YES)));
}

- (void)testShouldSendTheRequestWhenBackgroundPolicyIsContinue
{
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    NSURL *URL = [RKTestFactory baseURL];
    RKRequest *request = [[RKRequest alloc] initWithURL:URL];
    request.backgroundPolicy = RKRequestBackgroundPolicyContinue;
    request.delegate = loader;
    [request sendAsynchronously];
    [loader waitForResponse];
    assertThatBool([loader wasSuccessful], is(equalToBool(YES)));
}

- (void)testShouldSendTheRequestWhenBackgroundPolicyIsCancel
{
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    NSURL *URL = [RKTestFactory baseURL];
    RKRequest *request = [[RKRequest alloc] initWithURL:URL];
    request.backgroundPolicy = RKRequestBackgroundPolicyCancel;
    request.delegate = loader;
    [request sendAsynchronously];
    [loader waitForResponse];
    assertThatBool([loader wasSuccessful], is(equalToBool(YES)));
}

- (void)testShouldSendTheRequestWhenBackgroundPolicyIsRequeue
{
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    NSURL *URL = [RKTestFactory baseURL];
    RKRequest *request = [[RKRequest alloc] initWithURL:URL];
    request.backgroundPolicy = RKRequestBackgroundPolicyRequeue;
    request.delegate = loader;
    [request sendAsynchronously];
    [loader waitForResponse];
    assertThatBool([loader wasSuccessful], is(equalToBool(YES)));
}

#endif

#pragma mark RKRequestCachePolicy Tests

- (void)testShouldSendTheRequestWhenTheCachePolicyIsNone
{
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    NSString *url = [NSString stringWithFormat:@"%@/etags", [RKTestFactory baseURLString]];
    NSURL *URL = [NSURL URLWithString:url];
    RKRequest *request = [[RKRequest alloc] initWithURL:URL];
    request.cachePolicy = RKRequestCachePolicyNone;
    request.delegate = loader;
    [request sendAsynchronously];
    [loader waitForResponse];
    assertThatBool([loader wasSuccessful], is(equalToBool(YES)));
}

- (void)testShouldCacheTheRequestHeadersAndBodyIncludingOurOwnCustomTimestampHeader
{
    NSString *baseURL = [RKTestFactory baseURLString];
    NSString *cacheDirForClient = [NSString stringWithFormat:@"RKClientRequestCache-%@",
                                   [[NSURL URLWithString:baseURL] host]];
    NSString *cachePath = [[RKDirectory cachesDirectory]
                           stringByAppendingPathComponent:cacheDirForClient];
    RKRequestCache *cache = [[RKRequestCache alloc] initWithPath:cachePath
                                                        storagePolicy:RKRequestCacheStoragePolicyPermanently];
    [cache invalidateWithStoragePolicy:RKRequestCacheStoragePolicyPermanently];

    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    NSString *url = [NSString stringWithFormat:@"%@/etags/cached", [RKTestFactory baseURLString]];
    NSURL *URL = [NSURL URLWithString:url];
    RKRequest *request = [[RKRequest alloc] initWithURL:URL];
    request.cachePolicy = RKRequestCachePolicyEtag;
    request.cache = cache;
    request.delegate = loader;
    [request sendAsynchronously];
    [loader waitForResponse];
    assertThatBool([loader wasSuccessful], is(equalToBool(YES)));
    NSDictionary *headers = [cache headersForRequest:request];
    assertThat([headers valueForKey:@"X-RESTKIT-CACHEDATE"], isNot(nilValue()));
    assertThat([headers valueForKey:@"Etag"], is(equalTo(@"686897696a7c876b7e")));
    assertThat([[cache responseForRequest:request] bodyAsString], is(equalTo(@"This Should Get Cached")));
}

- (void)testShouldGenerateAUniqueCacheKeyBasedOnTheUrlTheMethodAndTheHTTPBody
{
    NSString *baseURL = [RKTestFactory baseURLString];
    NSString *cacheDirForClient = [NSString stringWithFormat:@"RKClientRequestCache-%@",
                                   [[NSURL URLWithString:baseURL] host]];
    NSString *cachePath = [[RKDirectory cachesDirectory]
                           stringByAppendingPathComponent:cacheDirForClient];
    RKRequestCache *cache = [[RKRequestCache alloc] initWithPath:cachePath
                                                        storagePolicy:RKRequestCacheStoragePolicyPermanently];
    [cache invalidateWithStoragePolicy:RKRequestCacheStoragePolicyPermanently];

    NSString *url = [NSString stringWithFormat:@"%@/etags/cached", [RKTestFactory baseURLString]];
    NSURL *URL = [NSURL URLWithString:url];
    RKRequest *request = [[RKRequest alloc] initWithURL:URL];
    request.cachePolicy = RKRequestCachePolicyEtag;
    request.method = RKRequestMethodDELETE;
    // Don't cache delete. cache key should be nil.
    assertThat([request cacheKey], is(nilValue()));

    request.method = RKRequestMethodPOST;
    assertThat([request cacheKey], is(nilValue()));

    request.method = RKRequestMethodPUT;
    assertThat([request cacheKey], is(nilValue()));
}

- (void)testShouldLoadFromCacheWhenWeRecieveA304
{
    NSString *baseURL = [RKTestFactory baseURLString];
    NSString *cacheDirForClient = [NSString stringWithFormat:@"RKClientRequestCache-%@",
                                   [[NSURL URLWithString:baseURL] host]];
    NSString *cachePath = [[RKDirectory cachesDirectory]
                           stringByAppendingPathComponent:cacheDirForClient];
    RKRequestCache *cache = [[RKRequestCache alloc] initWithPath:cachePath
                                storagePolicy:RKRequestCacheStoragePolicyPermanently];
    [cache invalidateWithStoragePolicy:RKRequestCacheStoragePolicyPermanently];
    {
        RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
        NSString *url = [NSString stringWithFormat:@"%@/etags/cached", [RKTestFactory baseURLString]];
        NSURL *URL = [NSURL URLWithString:url];
        RKRequest *request = [[RKRequest alloc] initWithURL:URL];
        request.cachePolicy = RKRequestCachePolicyEtag;
        request.cache = cache;
        request.delegate = loader;
        [request sendAsynchronously];
        [loader waitForResponse];
        assertThatBool([loader wasSuccessful], is(equalToBool(YES)));
        assertThat([loader.response bodyAsString], is(equalTo(@"This Should Get Cached")));
        assertThat([cache etagForRequest:request], is(equalTo(@"686897696a7c876b7e")));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(NO)));
    }
    {
        RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
        NSString *url = [NSString stringWithFormat:@"%@/etags/cached", [RKTestFactory baseURLString]];
        NSURL *URL = [NSURL URLWithString:url];
        RKRequest *request = [[RKRequest alloc] initWithURL:URL];
        request.cachePolicy = RKRequestCachePolicyEtag;
        request.cache = cache;
        request.delegate = loader;
        [request sendAsynchronously];
        [loader waitForResponse];
        assertThatBool([loader wasSuccessful], is(equalToBool(YES)));
        assertThat([loader.response bodyAsString], is(equalTo(@"This Should Get Cached")));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(YES)));
    }
}

- (void)testShouldUpdateTheInternalCacheDateWhenWeRecieveA304
{
    NSString *baseURL = [RKTestFactory baseURLString];
    NSString *cacheDirForClient = [NSString stringWithFormat:@"RKClientRequestCache-%@",
                                   [[NSURL URLWithString:baseURL] host]];
    NSString *cachePath = [[RKDirectory cachesDirectory]
                           stringByAppendingPathComponent:cacheDirForClient];
    RKRequestCache *cache = [[RKRequestCache alloc] initWithPath:cachePath
                                                        storagePolicy:RKRequestCacheStoragePolicyPermanently];
    [cache invalidateWithStoragePolicy:RKRequestCacheStoragePolicyPermanently];

    NSDate *internalCacheDate1;
    NSDate *internalCacheDate2;
    {
        RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
        NSString *url = [NSString stringWithFormat:@"%@/etags/cached", [RKTestFactory baseURLString]];
        NSURL *URL = [NSURL URLWithString:url];
        RKRequest *request = [[RKRequest alloc] initWithURL:URL];
        request.cachePolicy = RKRequestCachePolicyEtag;
        request.cache = cache;
        request.delegate = loader;
        [request sendAsynchronously];
        [loader waitForResponse];
        assertThatBool([loader wasSuccessful], is(equalToBool(YES)));
        assertThat([loader.response bodyAsString], is(equalTo(@"This Should Get Cached")));
        assertThat([cache etagForRequest:request], is(equalTo(@"686897696a7c876b7e")));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(NO)));
        internalCacheDate1 = [cache cacheDateForRequest:request];
    }
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.5]];
    {
        RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
        NSString *url = [NSString stringWithFormat:@"%@/etags/cached", [RKTestFactory baseURLString]];
        NSURL *URL = [NSURL URLWithString:url];
        RKRequest *request = [[RKRequest alloc] initWithURL:URL];
        request.cachePolicy = RKRequestCachePolicyEtag;
        request.cache = cache;
        request.delegate = loader;
        [request sendAsynchronously];
        [loader waitForResponse];
        assertThatBool([loader wasSuccessful], is(equalToBool(YES)));
        assertThat([loader.response bodyAsString], is(equalTo(@"This Should Get Cached")));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(YES)));
        internalCacheDate2 = [cache cacheDateForRequest:request];
    }
    assertThat(internalCacheDate1, isNot(internalCacheDate2));
}

- (void)testShouldLoadFromTheCacheIfThereIsAnError
{
    NSString *baseURL = [RKTestFactory baseURLString];
    NSString *cacheDirForClient = [NSString stringWithFormat:@"RKClientRequestCache-%@",
                                   [[NSURL URLWithString:baseURL] host]];
    NSString *cachePath = [[RKDirectory cachesDirectory]
                           stringByAppendingPathComponent:cacheDirForClient];
    RKRequestCache *cache = [[RKRequestCache alloc] initWithPath:cachePath
                                                        storagePolicy:RKRequestCacheStoragePolicyPermanently];
    [cache invalidateWithStoragePolicy:RKRequestCacheStoragePolicyPermanently];

    {
        RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
        NSString *url = [NSString stringWithFormat:@"%@/etags/cached", [RKTestFactory baseURLString]];
        NSURL *URL = [NSURL URLWithString:url];
        RKRequest *request = [[RKRequest alloc] initWithURL:URL];
        request.cachePolicy = RKRequestCachePolicyEtag;
        request.cache = cache;
        request.delegate = loader;
        [request sendAsynchronously];
        [loader waitForResponse];
        assertThatBool([loader wasSuccessful], is(equalToBool(YES)));
        assertThat([loader.response bodyAsString], is(equalTo(@"This Should Get Cached")));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(NO)));
    }
    {
        RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
        NSString *url = [NSString stringWithFormat:@"%@/etags/cached", [RKTestFactory baseURLString]];
        NSURL *URL = [NSURL URLWithString:url];
        RKRequest *request = [[RKRequest alloc] initWithURL:URL];
        request.cachePolicy = RKRequestCachePolicyLoadOnError;
        request.cache = cache;
        request.delegate = loader;
        [request didFailLoadWithError:[NSError errorWithDomain:@"Fake" code:0 userInfo:nil]];
        assertThat([loader.response bodyAsString], is(equalTo(@"This Should Get Cached")));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(YES)));
    }
}

- (void)testShouldLoadFromTheCacheIfWeAreWithinTheTimeout
{
    NSString *baseURL = [RKTestFactory baseURLString];
    NSString *cacheDirForClient = [NSString stringWithFormat:@"RKClientRequestCache-%@",
                                   [[NSURL URLWithString:baseURL] host]];
    NSString *cachePath = [[RKDirectory cachesDirectory]
                           stringByAppendingPathComponent:cacheDirForClient];
    RKRequestCache *cache = [[RKRequestCache alloc] initWithPath:cachePath
                                                        storagePolicy:RKRequestCacheStoragePolicyPermanently];
    [cache invalidateWithStoragePolicy:RKRequestCacheStoragePolicyPermanently];

    NSString *url = [NSString stringWithFormat:@"%@/disk/cached", [RKTestFactory baseURLString]];
    NSURL *URL = [NSURL URLWithString:url];
    {
        RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
        RKRequest *request = [[RKRequest alloc] initWithURL:URL];
        request.cachePolicy = RKRequestCachePolicyTimeout;
        request.cacheTimeoutInterval = 5;
        request.cache = cache;
        request.delegate = loader;
        [request sendAsynchronously];
        [loader waitForResponse];
        assertThatBool([loader wasSuccessful], is(equalToBool(YES)));
        assertThat([loader.response bodyAsString], is(equalTo(@"This Should Get Cached For 5 Seconds")));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(NO)));
    }
    {
        RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
        RKRequest *request = [[RKRequest alloc] initWithURL:URL];
        request.cachePolicy = RKRequestCachePolicyTimeout;
        request.cacheTimeoutInterval = 5;
        request.cache = cache;
        request.delegate = loader;
        [request sendAsynchronously];
        [loader waitForResponse];
        assertThat([loader.response bodyAsString], is(equalTo(@"This Should Get Cached For 5 Seconds")));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(YES)));
    }
    {
        RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
        RKRequest *request = [[RKRequest alloc] initWithURL:URL];
        request.cachePolicy = RKRequestCachePolicyTimeout;
        request.cacheTimeoutInterval = 5;
        request.cache = cache;
        request.delegate = loader;
        [request sendAsynchronously];
        [loader waitForResponse];
        assertThat([loader.response bodyAsString], is(equalTo(@"This Should Get Cached For 5 Seconds")));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(YES)));
    }
    {
        RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
        RKRequest *request = [[RKRequest alloc] initWithURL:URL];
        request.cachePolicy = RKRequestCachePolicyTimeout;
        request.cacheTimeoutInterval = 0;
        request.cache = cache;
        request.delegate = loader;
        [request sendAsynchronously];
        [loader waitForResponse];
        assertThatBool([loader wasSuccessful], is(equalToBool(YES)));
        assertThat([loader.response bodyAsString], is(equalTo(@"This Should Get Cached For 5 Seconds")));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(NO)));
    }
}

- (void)testShouldLoadFromTheCacheIfWeAreOffline
{
    NSString *baseURL = [RKTestFactory baseURLString];
    NSString *cacheDirForClient = [NSString stringWithFormat:@"RKClientRequestCache-%@",
                                   [[NSURL URLWithString:baseURL] host]];
    NSString *cachePath = [[RKDirectory cachesDirectory]
                           stringByAppendingPathComponent:cacheDirForClient];
    RKRequestCache *cache = [[RKRequestCache alloc] initWithPath:cachePath
                                                        storagePolicy:RKRequestCacheStoragePolicyPermanently];
    [cache invalidateWithStoragePolicy:RKRequestCacheStoragePolicyPermanently];

    {
        RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
        loader.timeout = 60;
        NSString *url = [NSString stringWithFormat:@"%@/etags/cached", [RKTestFactory baseURLString]];
        NSURL *URL = [NSURL URLWithString:url];
        RKRequest *request = [[RKRequest alloc] initWithURL:URL];
        request.cachePolicy = RKRequestCachePolicyEtag;
        request.cache = cache;
        request.delegate = loader;
        [request sendAsynchronously];
        [loader waitForResponse];
        assertThatBool([loader wasSuccessful], is(equalToBool(YES)));
        assertThat([loader.response bodyAsString], is(equalTo(@"This Should Get Cached")));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(NO)));
    }
    {
        RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
        loader.timeout = 60;
        NSString *url = [NSString stringWithFormat:@"%@/etags/cached", [RKTestFactory baseURLString]];
        NSURL *URL = [NSURL URLWithString:url];
        RKRequest *request = [[RKRequest alloc] initWithURL:URL];
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

- (void)testShouldCacheTheStatusCodeMIMETypeAndURL
{
    NSString *baseURL = [RKTestFactory baseURLString];
    NSString *cacheDirForClient = [NSString stringWithFormat:@"RKClientRequestCache-%@",
                                   [[NSURL URLWithString:baseURL] host]];
    NSString *cachePath = [[RKDirectory cachesDirectory]
                           stringByAppendingPathComponent:cacheDirForClient];

    RKRequestCache *cache = [[RKRequestCache alloc] initWithPath:cachePath
                                                        storagePolicy:RKRequestCacheStoragePolicyPermanently];
    [cache invalidateWithStoragePolicy:RKRequestCacheStoragePolicyPermanently];
    {
        RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
        NSString *url = [NSString stringWithFormat:@"%@/etags/cached", [RKTestFactory baseURLString]];
        NSURL *URL = [NSURL URLWithString:url];
        RKRequest *request = [[RKRequest alloc] initWithURL:URL];
        request.cachePolicy = RKRequestCachePolicyEtag;
        request.cache = cache;
        request.delegate = loader;
        [request sendAsynchronously];
        [loader waitForResponse];
        assertThatBool([loader wasSuccessful], is(equalToBool(YES)));
        assertThat([loader.response bodyAsString], is(equalTo(@"This Should Get Cached")));
        NSLog(@"Headers: %@", [cache headersForRequest:request]);
        assertThat([cache etagForRequest:request], is(equalTo(@"686897696a7c876b7e")));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(NO)));
    }
    {
        RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
        NSString *url = [NSString stringWithFormat:@"%@/etags/cached", [RKTestFactory baseURLString]];
        NSURL *URL = [NSURL URLWithString:url];
        RKRequest *request = [[RKRequest alloc] initWithURL:URL];
        request.cachePolicy = RKRequestCachePolicyEtag;
        request.cache = cache;
        request.delegate = loader;
        [request sendAsynchronously];
        [loader waitForResponse];
        assertThatBool([loader wasSuccessful], is(equalToBool(YES)));
        assertThatBool([loader.response wasLoadedFromCache], is(equalToBool(YES)));
        assertThatInteger(loader.response.statusCode, is(equalToInt(200)));
        assertThat(loader.response.MIMEType, is(equalTo(@"text/html")));
        assertThat([loader.response.URL absoluteString], is(equalTo(@"http://127.0.0.1:4567/etags/cached")));
    }
}

- (void)testShouldPostSimpleKeyValuesViaRKParams
{
    RKParams *params = [RKParams params];

    [params setValue:@"hello" forParam:@"username"];
    [params setValue:@"password" forParam:@"password"];

    RKClient *client = [RKTestFactory client];
    client.cachePolicy = RKRequestCachePolicyNone;
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    loader.timeout = 20;
    [client post:@"/echo_params" params:params delegate:loader];
    [loader waitForResponse];
    assertThat([loader.response bodyAsString], is(equalTo(@"{\"username\":\"hello\",\"password\":\"password\"}")));
}

- (void)testShouldSetAnEmptyContentBodyWhenParamsIsNil
{
    RKClient *client = [RKTestFactory client];
    client.cachePolicy = RKRequestCachePolicyNone;
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    loader.timeout = 20;
    RKRequest *request = [client get:@"/echo_params" delegate:loader];
    [loader waitForResponse];
    assertThat([request.URLRequest valueForHTTPHeaderField:@"Content-Length"], is(equalTo(@"0")));
}

- (void)testShouldSetAnEmptyContentBodyWhenQueryParamsIsAnEmptyDictionary
{
    RKClient *client = [RKTestFactory client];
    client.cachePolicy = RKRequestCachePolicyNone;
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    loader.timeout = 20;
    RKRequest *request = [client get:@"/echo_params" queryParameters:[NSDictionary dictionary] delegate:loader];
    [loader waitForResponse];
    assertThat([request.URLRequest valueForHTTPHeaderField:@"Content-Length"], is(equalTo(@"0")));
}

- (void)testShouldPUTWithParams
{
    RKClient *client = [RKTestFactory client];
    RKParams *params = [RKParams params];
    [params setValue:@"ddss" forParam:@"username"];
    [params setValue:@"aaaa@aa.com" forParam:@"email"];
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    [client put:@"/ping" params:params delegate:loader];
    [loader waitForResponse];
    assertThat([loader.response bodyAsString], is(equalTo(@"{\"username\":\"ddss\",\"email\":\"aaaa@aa.com\"}")));
}

- (void)testShouldAllowYouToChangeTheURL
{
    NSURL *URL = [NSURL URLWithString:@"http://restkit.org/monkey"];
    RKRequest *request = [RKRequest requestWithURL:URL];
    request.URL = [NSURL URLWithString:@"http://restkit.org/gorilla"];
    assertThat([request.URL absoluteString], is(equalTo(@"http://restkit.org/gorilla")));
}

- (void)testShouldAllowYouToChangeTheResourcePath
{
    RKURL *URL = [[RKURL URLWithString:@"http://restkit.org"] URLByAppendingResourcePath:@"/monkey"];
    RKRequest *request = [RKRequest requestWithURL:URL];
    request.resourcePath = @"/gorilla";
    assertThat(request.resourcePath, is(equalTo(@"/gorilla")));
}

- (void)testShouldNotRaiseAnExceptionWhenAttemptingToMutateResourcePathOnAnNSURL
{
    NSURL *URL = [NSURL URLWithString:@"http://restkit.org/monkey"];
    RKRequest *request = [RKRequest requestWithURL:URL];
    NSException *exception = nil;
    @try {
        request.resourcePath = @"/gorilla";
    }
    @catch (NSException *e) {
        exception = e;
    }
    @finally {
        assertThat(exception, is(nilValue()));
    }
}

- (void)testShouldOptionallySkipSSLValidation
{
    NSURL *URL = [NSURL URLWithString:@"https://blakewatters.com/"];
    RKRequest *request = [RKRequest requestWithURL:URL];
    request.disableCertificateValidation = YES;
    RKResponse *response = [request sendSynchronously];
    assertThatBool([response isOK], is(equalToBool(YES)));
}

- (void)testShouldNotAddANonZeroContentLengthHeaderIfParamsIsSetAndThisIsAGETRequest
{
    RKClient *client = [RKTestFactory client];
    client.disableCertificateValidation = YES;
    NSURL *URL = [NSURL URLWithString:@"https://blakewatters.com/"];
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    RKRequest *request = [RKRequest requestWithURL:URL];
    request.delegate = loader;
    request.params = [NSDictionary dictionaryWithObject:@"foo" forKey:@"bar"];
    [request send];
    [loader waitForResponse];
    assertThat([request.URLRequest valueForHTTPHeaderField:@"Content-Length"], is(equalTo(@"0")));
}

- (void)testShouldNotAddANonZeroContentLengthHeaderIfParamsIsSetAndThisIsAHEADRequest
{
    RKClient *client = [RKTestFactory client];
    client.disableCertificateValidation = YES;
    NSURL *URL = [NSURL URLWithString:@"https://blakewatters.com/"];
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    RKRequest *request = [RKRequest requestWithURL:URL];
    request.delegate = loader;
    request.method = RKRequestMethodHEAD;
    request.params = [NSDictionary dictionaryWithObject:@"foo" forKey:@"bar"];
    [request send];
    [loader waitForResponse];
    assertThat([request.URLRequest valueForHTTPHeaderField:@"Content-Length"], is(equalTo(@"0")));
}

- (void)testShouldLetYouHandleResponsesWithABlock
{
    RKURL *URL = [[RKTestFactory baseURL] URLByAppendingResourcePath:@"/ping"];
    RKRequest *request = [RKRequest requestWithURL:URL];
    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    request.delegate = responseLoader;
    __block BOOL blockInvoked = NO;
    request.onDidLoadResponse = ^ (RKResponse *response) {
        blockInvoked = YES;
    };
    [request sendAsynchronously];
    [responseLoader waitForResponse];
    assertThatBool(blockInvoked, is(equalToBool(YES)));
}

- (void)testShouldLetYouHandleErrorsWithABlock
{
    RKURL *URL = [[RKTestFactory baseURL] URLByAppendingResourcePath:@"/fail"];
    RKRequest *request = [RKRequest requestWithURL:URL];
    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    request.delegate = responseLoader;
    __block BOOL blockInvoked = NO;
    request.onDidLoadResponse = ^ (RKResponse *response) {
        blockInvoked = YES;
    };
    [request sendAsynchronously];
    [responseLoader waitForResponse];
    assertThatBool(blockInvoked, is(equalToBool(YES)));
}

// TODO: Move to RKRequestCacheTest
- (void)testShouldReturnACachePathWhenTheRequestIsUsingRKParams
{
    RKParams *params = [RKParams params];
    [params setValue:@"foo" forParam:@"bar"];
    NSURL *URL = [NSURL URLWithString:@"http://restkit.org/"];
    RKRequest *request = [RKRequest requestWithURL:URL];
    request.params = params;
    NSString *baseURL = [RKTestFactory baseURLString];
    NSString *cacheDirForClient = [NSString stringWithFormat:@"RKClientRequestCache-%@",
                                   [[NSURL URLWithString:baseURL] host]];
    NSString *cachePath = [[RKDirectory cachesDirectory]
                           stringByAppendingPathComponent:cacheDirForClient];
    RKRequestCache *requestCache = [[RKRequestCache alloc] initWithPath:cachePath storagePolicy:RKRequestCacheStoragePolicyForDurationOfSession];
    NSString *requestCachePath = [requestCache pathForRequest:request];
    NSArray *pathComponents = [requestCachePath pathComponents];
    NSString *cacheFile = [NSString pathWithComponents:[pathComponents subarrayWithRange:NSMakeRange([pathComponents count] - 2, 2)]];
    assertThat(cacheFile, is(equalTo(@"SessionStore/4ba47367884760141da2e38fda525a1f")));
}

- (void)testShouldReturnNilForCachePathWhenTheRequestIsADELETE
{
    RKParams *params = [RKParams params];
    [params setValue:@"foo" forParam:@"bar"];
    NSURL *URL = [NSURL URLWithString:@"http://restkit.org/"];
    RKRequest *request = [RKRequest requestWithURL:URL];
    request.method = RKRequestMethodDELETE;
    NSString *baseURL = [RKTestFactory baseURLString];
    NSString *cacheDirForClient = [NSString stringWithFormat:@"RKClientRequestCache-%@",
                                   [[NSURL URLWithString:baseURL] host]];
    NSString *cachePath = [[RKDirectory cachesDirectory]
                           stringByAppendingPathComponent:cacheDirForClient];
    RKRequestCache *requestCache = [[RKRequestCache alloc] initWithPath:cachePath storagePolicy:RKRequestCacheStoragePolicyForDurationOfSession];
    NSString *requestCachePath = [requestCache pathForRequest:request];
    assertThat(requestCachePath, is(nilValue()));
}

- (void)testShouldBuildAProperAuthorizationHeaderForOAuth1
{
    RKRequest *request = [RKRequest requestWithURL:[RKURL URLWithString:@"http://restkit.org/this?that=foo&bar=word"]];
    request.authenticationType = RKRequestAuthenticationTypeOAuth1;
    request.OAuth1AccessToken = @"12345";
    request.OAuth1AccessTokenSecret = @"monkey";
    request.OAuth1ConsumerKey = @"another key";
    request.OAuth1ConsumerSecret = @"more data";
    [request prepareURLRequest];
    NSString *authorization = [request.URLRequest valueForHTTPHeaderField:@"Authorization"];
    assertThat(authorization, isNot(nilValue()));
}

- (void)testShouldBuildAProperAuthorizationHeaderForOAuth1ThatIsAcceptedByServer
{
    RKRequest *request = [RKRequest requestWithURL:[RKURL URLWithString:[NSString stringWithFormat:@"%@/oauth1/me", [RKTestFactory baseURLString]]]];
    request.authenticationType = RKRequestAuthenticationTypeOAuth1;
    request.OAuth1AccessToken = @"12345";
    request.OAuth1AccessTokenSecret = @"monkey";
    request.OAuth1ConsumerKey = @"restkit_key";
    request.OAuth1ConsumerSecret = @"restkit_secret";
    [request prepareURLRequest];
    NSString *authorization = [request.URLRequest valueForHTTPHeaderField:@"Authorization"];
    assertThat(authorization, isNot(nilValue()));

    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    request.delegate = responseLoader;
    [request sendAsynchronously];
    [responseLoader waitForResponse];
    assertThatBool(responseLoader.successful, is(equalToBool(YES)));
}

- (void)testImproperOAuth1CredentialsShouldFall
{
    RKRequest *request = [RKRequest requestWithURL:[RKURL URLWithString:[NSString stringWithFormat:@"%@/oauth1/me", [RKTestFactory baseURLString]]]];
    request.authenticationType = RKRequestAuthenticationTypeOAuth1;
    request.OAuth1AccessToken = @"12345";
    request.OAuth1AccessTokenSecret = @"monkey";
    request.OAuth1ConsumerKey = @"restkit_key";
    request.OAuth1ConsumerSecret = @"restkit_incorrect_secret";
    [request prepareURLRequest];
    NSString *authorization = [request.URLRequest valueForHTTPHeaderField:@"Authorization"];
    assertThat(authorization, isNot(nilValue()));

    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    request.delegate = responseLoader;
    [request sendAsynchronously];
    [responseLoader waitForResponse];
    assertThatBool(responseLoader.successful, is(equalToBool(YES)));
}

- (void)testOnDidLoadResponseBlockInvocation
{
    RKURL *URL = [[RKTestFactory baseURL] URLByAppendingResourcePath:@"/200"];
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    RKRequest *request = [RKRequest requestWithURL:URL];
    __block RKResponse *blockResponse = nil;
    request.onDidLoadResponse = ^ (RKResponse *response) {
        blockResponse = response;
    };
    request.delegate = loader;
    [request sendAsynchronously];
    [loader waitForResponse];
    assertThat(blockResponse, is(notNilValue()));
}

- (void)testOnDidFailLoadWithErrorBlockInvocation
{
    RKURL *URL = [[RKTestFactory baseURL] URLByAppendingResourcePath:@"/503"];
    RKRequest *request = [RKRequest requestWithURL:URL];
    __block NSError *blockError = nil;
    request.onDidFailLoadWithError = ^ (NSError *error) {
        blockError = error;
    };
    NSError *expectedError = [NSError errorWithDomain:@"Test" code:1234 userInfo:nil];
    [request didFailLoadWithError:expectedError];
    assertThat(blockError, is(notNilValue()));
}

- (void)testShouldBuildAProperRequestWhenSettingBodyByMIMEType
{
    RKClient *client = [RKTestFactory client];
    NSDictionary *bodyParams = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:10], @"number",
                                @"JSON String", @"string",
                                nil];
    RKRequest *request = [client requestWithResourcePath:@"/upload"];
    [request setMethod:RKRequestMethodPOST];
    [request setBody:bodyParams forMIMEType:RKMIMETypeJSON];
    [request prepareURLRequest];
    assertThat(request.HTTPBodyString, is(equalTo(@"{\"number\":10,\"string\":\"JSON String\"}")));
}

- (void)testThatGETRequestsAreConsideredCacheable
{
    RKRequest *request = [RKRequest new];
    request.method = RKRequestMethodGET;
    assertThatBool([request isCacheable], is(equalToBool(YES)));
}

- (void)testThatPOSTRequestsAreNotConsideredCacheable
{
    RKRequest *request = [RKRequest new];
    request.method = RKRequestMethodPOST;
    assertThatBool([request isCacheable], is(equalToBool(NO)));
}

- (void)testThatPUTRequestsAreNotConsideredCacheable
{
    RKRequest *request = [RKRequest new];
    request.method = RKRequestMethodPUT;
    assertThatBool([request isCacheable], is(equalToBool(NO)));
}

- (void)testThatDELETERequestsAreNotConsideredCacheable
{
    RKRequest *request = [RKRequest new];
    request.method = RKRequestMethodDELETE;
    assertThatBool([request isCacheable], is(equalToBool(NO)));
}

- (void)testInvocationOfDidReceiveResponse
{
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    id loaderMock = [OCMockObject partialMockForObject:loader];
    NSURL *URL = [[RKTestFactory baseURL] URLByAppendingResourcePath:@"/200"];
    RKRequest *request = [[RKRequest alloc] initWithURL:URL];
    request.delegate = loaderMock;
    [[loaderMock expect] request:request didReceiveResponse:OCMOCK_ANY];
    [request sendAsynchronously];
    [loaderMock waitForResponse];
    [request release];
    [loaderMock verify];
}

- (void)testThatIsLoadingIsNoDuringDidFailWithErrorCallback
{
    NSURL *URL = [[NSURL alloc] initWithString:@"http://localhost:8765"];
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];

    RKClient *client = [RKClient clientWithBaseURL:URL];
    RKRequest *request = [client requestWithResourcePath:@"/invalid"];
    request.method = RKRequestMethodGET;
    request.delegate = loader;
    request.onDidFailLoadWithError = ^(NSError *error) {
        assertThatBool([request isLoading], is(equalToBool(NO)));
    };
    [request sendAsynchronously];
    [loader waitForResponse];
}

- (void)testThatIsLoadedIsYesDuringDidFailWithErrorCallback
{
    NSURL *URL = [[NSURL alloc] initWithString:@"http://localhost:8765"];
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];

    RKClient *client = [RKClient clientWithBaseURL:URL];
    RKRequest *request = [client requestWithResourcePath:@"/invalid"];
    request.method = RKRequestMethodGET;
    request.delegate = loader;
    request.onDidFailLoadWithError = ^(NSError *error) {
        assertThatBool([request isLoaded], is(equalToBool(YES)));
    };
    [request sendAsynchronously];
    [loader waitForResponse];
}

- (void)testUnavailabilityOfResponseInDidFailWithErrorCallback
{
    NSURL *URL = [[NSURL alloc] initWithString:@"http://localhost:8765"];
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];

    RKClient *client = [RKClient clientWithBaseURL:URL];
    RKRequest *request = [client requestWithResourcePath:@"/invalid"];
    request.method = RKRequestMethodGET;
    request.delegate = loader;
    [request sendAsynchronously];
    [loader waitForResponse];
    assertThat(request.response, is(nilValue()));
}

- (void)testAvailabilityOfResponseWhenFailedDueTo500Response
{
    RKURL *URL = [[RKTestFactory baseURL] URLByAppendingResourcePath:@"/fail"];
    RKRequest *request = [RKRequest requestWithURL:URL];
    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    request.delegate = responseLoader;
    [request sendAsynchronously];
    [responseLoader waitForResponse];
    assertThat(request.response, is(notNilValue()));
    assertThatInteger(request.response.statusCode, is(equalToInteger(500)));
}

@end
