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

@interface RKRequest (Private)
- (void)fireAsynchronousRequest;
- (void)shouldDispatchRequest;
@end

@interface RKRequestSpec : RKSpec {
}

@end

@implementation RKRequestSpec

- (void)beforeAll {
    // Clear the cache directory
    RKSpecClearCacheDirectory();
}

/**
 * This spec requires the test Sinatra server to be running
 * `ruby Specs/server.rb`
 */
- (void)itShouldSendMultiPartRequests {
	NSString* URLString = [NSString stringWithFormat:@"http://127.0.0.1:4567/photo"];
	NSURL* URL = [NSURL URLWithString:URLString];
    RKSpecStubNetworkAvailability(YES);
	RKRequest* request = [[RKRequest alloc] initWithURL:URL];
	RKParams* params = [[RKParams params] retain];
	NSString* filePath = [[NSBundle mainBundle] pathForResource:@"blake" ofType:@"png"];
	[params setFile:filePath forParam:@"file"];
	[params setValue:@"this is the value" forParam:@"test"];
	request.method = RKRequestMethodPOST;
	request.params = params;
	RKResponse* response = [request sendSynchronously];
	[expectThat(response.statusCode) should:be(200)];
}

#pragma mark - Basics

- (void)itShouldSetURLRequestHTTPBody {
    NSURL* URL = [NSURL URLWithString:RKSpecGetBaseURL()];
    RKRequest* request = [[RKRequest alloc] initWithURL:URL];
    NSString* JSON = @"whatever";
    NSData* data = [JSON dataUsingEncoding:NSASCIIStringEncoding];
    request.HTTPBody = data;
    [expectThat(request.URLRequest.HTTPBody) should:be(data)];
    [expectThat(request.HTTPBody) should:be(data)];
    [expectThat(request.HTTPBodyString) should:be(JSON)];
}

- (void)itShouldSetURLRequestHTTPBodyByString {
    NSURL* URL = [NSURL URLWithString:RKSpecGetBaseURL()];
    RKRequest* request = [[RKRequest alloc] initWithURL:URL];
    NSString* JSON = @"whatever";
    NSData* data = [JSON dataUsingEncoding:NSASCIIStringEncoding];
    request.HTTPBodyString = JSON;
    [expectThat(request.URLRequest.HTTPBody) should:be(data)];
    [expectThat(request.HTTPBody) should:be(data)];
    [expectThat(request.HTTPBodyString) should:be(JSON)];
}

#pragma mark - Background Policies

- (void)itShouldSendTheRequestWhenBackgroundPolicyIsRKRequestBackgroundPolicyNone {
    RKSpecStubNetworkAvailability(YES);
	NSURL* URL = [NSURL URLWithString:RKSpecGetBaseURL()];
	RKRequest* request = [[RKRequest alloc] initWithURL:URL];
    request.backgroundPolicy = RKRequestBackgroundPolicyNone;
    id requestMock = [OCMockObject partialMockForObject:request];
    [[requestMock expect] fireAsynchronousRequest]; // Not sure what else to test on this case
    [request sendAsynchronously];
    [requestMock verify];
}

- (void)itShouldObserveForAppBackgroundTransitionsAndCancelTheRequestWhenBackgroundPolicyIsRKRequestBackgroundPolicyCancel {
    NSURL* URL = [NSURL URLWithString:RKSpecGetBaseURL()];
	RKRequest* request = [[RKRequest alloc] initWithURL:URL];
    request.backgroundPolicy = RKRequestBackgroundPolicyCancel;
    id requestMock = [OCMockObject partialMockForObject:request];
    [[requestMock expect] cancel];
    [requestMock sendAsynchronously];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
    [requestMock verify];
}

- (void)itShouldInformTheDelegateOfCancelWhenTheRequestWhenBackgroundPolicyIsRKRequestBackgroundPolicyCancel {
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    NSURL* URL = [NSURL URLWithString:RKSpecGetBaseURL()];
    RKRequest* request = [[RKRequest alloc] initWithURL:URL];
    request.backgroundPolicy = RKRequestBackgroundPolicyCancel;
    request.delegate = loader;
    [request sendAsynchronously];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
    [expectThat(loader.wasCancelled) should:be(YES)];
}

- (void)itShouldPutTheRequestBackOntoTheQueueWhenBackgroundPolicyIsRKRequestBackgroundPolicyRequeue {
    RKRequestQueue* queue = [[RKRequestQueue new] autorelease];
    queue.suspended = YES;
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    NSURL* URL = [NSURL URLWithString:RKSpecGetBaseURL()];
    RKRequest* request = [[RKRequest alloc] initWithURL:URL];
    request.backgroundPolicy = RKRequestBackgroundPolicyRequeue;
    request.delegate = loader;
    request.queue = queue;
    [request sendAsynchronously];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
    [expectThat([request isLoading]) should:be(NO)];
    [expectThat([queue containsRequest:request]) should:be(YES)];
}

- (void)itShouldCreateABackgroundTaskWhenBackgroundPolicyIsRKRequestBackgroundPolicyContinue {
    NSURL* URL = [NSURL URLWithString:RKSpecGetBaseURL()];
    RKRequest* request = [[RKRequest alloc] initWithURL:URL];
    request.backgroundPolicy = RKRequestBackgroundPolicyContinue;
    [request sendAsynchronously];
    [expectThat(request.backgroundTaskIdentifier) shouldNot:be(UIBackgroundTaskInvalid)];
}

- (void)itShouldSendTheRequestWhenBackgroundPolicyIsNone {
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    NSURL* URL = [NSURL URLWithString:RKSpecGetBaseURL()];
    RKRequest* request = [[RKRequest alloc] initWithURL:URL];
    request.backgroundPolicy = RKRequestBackgroundPolicyNone;
    request.delegate = loader;
    [request sendAsynchronously];
    [loader waitForResponse];
    [expectThat([loader success]) should:be(YES)];
}

- (void)itShouldSendTheRequestWhenBackgroundPolicyIsContinue {
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    NSURL* URL = [NSURL URLWithString:RKSpecGetBaseURL()];
    RKRequest* request = [[RKRequest alloc] initWithURL:URL];
    request.backgroundPolicy = RKRequestBackgroundPolicyContinue;
    request.delegate = loader;
    [request sendAsynchronously];
    [loader waitForResponse];
    [expectThat([loader success]) should:be(YES)];
}

- (void)itShouldSendTheRequestWhenBackgroundPolicyIsCancel {
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    NSURL* URL = [NSURL URLWithString:RKSpecGetBaseURL()];
    RKRequest* request = [[RKRequest alloc] initWithURL:URL];
    request.backgroundPolicy = RKRequestBackgroundPolicyCancel;
    request.delegate = loader;
    [request sendAsynchronously];
    [loader waitForResponse];
    [expectThat([loader success]) should:be(YES)];
}

- (void)itShouldSendTheRequestWhenBackgroundPolicyIsRequeue {
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    NSURL* URL = [NSURL URLWithString:RKSpecGetBaseURL()];
    RKRequest* request = [[RKRequest alloc] initWithURL:URL];
    request.backgroundPolicy = RKRequestBackgroundPolicyRequeue;
    request.delegate = loader;
    [request sendAsynchronously];
    [loader waitForResponse];
    [expectThat([loader success]) should:be(YES)];
}

#pragma mark RKRequestCachePolicy Specs

- (void)itShouldSendTheRequestWhenTheCachePolicyIsNone {
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    NSString* url = [NSString stringWithFormat:@"%@/etags", RKSpecGetBaseURL()];
    NSURL* URL = [NSURL URLWithString:url];
    RKRequest* request = [[RKRequest alloc] initWithURL:URL];
    request.cachePolicy = RKRequestCachePolicyNone;
    request.delegate = loader;
    [request sendAsynchronously];
    [loader waitForResponse];
    [expectThat([loader success]) should:be(YES)];
}

- (void)itShouldCacheTheRequestHeadersAndBodyIncludingOurOwnCustomTimestampHeader {
    NSString* baseURL = RKSpecGetBaseURL();
    NSString* cacheDirForClient = [NSString stringWithFormat:@"RKClientRequestCache-%@",
								   [[NSURL URLWithString:baseURL] host]];
	NSString* cachePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0]
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
    [expectThat([loader success]) should:be(YES)];
    NSDictionary* headers = [cache headersForRequest:request];
    [expectThat([headers valueForKey:@"X-RESTKIT-CACHEDATE"]) shouldNot:be(nil)];
    [expectThat([headers valueForKey:@"Etag"]) should:be(@"686897696a7c876b7e")];
    [expectThat([[cache responseForRequest:request] bodyAsString]) should:be(@"This Should Get Cached")];
}

- (void)itShouldGenerateAUniqueCacheKeyBasedOnTheUrlTheMethodAndTheHTTPBody {
    NSString* baseURL = RKSpecGetBaseURL();
    NSString* cacheDirForClient = [NSString stringWithFormat:@"RKClientRequestCache-%@",
								   [[NSURL URLWithString:baseURL] host]];
	NSString* cachePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0]
						   stringByAppendingPathComponent:cacheDirForClient];
    RKRequestCache* cache = [[RKRequestCache alloc] initWithCachePath:cachePath
                                                        storagePolicy:RKRequestCacheStoragePolicyPermanently];
    [cache invalidateWithStoragePolicy:RKRequestCacheStoragePolicyPermanently];
    
    NSString* url = [NSString stringWithFormat:@"%@/etags/cached", RKSpecGetBaseURL()];
    NSURL* URL = [NSURL URLWithString:url];
    RKRequest* request = [[RKRequest alloc] initWithURL:URL];
    request.cachePolicy = RKRequestCachePolicyEtag;
    
    NSString* cacheKeyGET = [request cacheKey];
    request.method = RKRequestMethodDELETE;
    // Don't cache delete. cache key should be nil.
    [expectThat([request cacheKey]) should:be(nil)];
    
    request.method = RKRequestMethodPOST;
    [expectThat([request cacheKey]) shouldNot:be(nil)];
    [expectThat(cacheKeyGET) shouldNot:be([request cacheKey])];
    request.params = [NSDictionary dictionaryWithObject:@"val" forKey:@"key"];
    NSString* cacheKeyPOST = [request cacheKey];
    [expectThat(cacheKeyPOST) shouldNot:be(nil)];
    request.method = RKRequestMethodPUT;
    [expectThat(cacheKeyPOST) shouldNot:be([request cacheKey])];
    [expectThat([request cacheKey]) shouldNot:be(nil)];
}

- (void)itShouldLoadFromCacheWhenWeRecieveA304 {
    NSString* baseURL = RKSpecGetBaseURL();
    NSString* cacheDirForClient = [NSString stringWithFormat:@"RKClientRequestCache-%@",
								   [[NSURL URLWithString:baseURL] host]];
	NSString* cachePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0]
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
        [expectThat([loader success]) should:be(YES)];
        [expectThat([loader.response bodyAsString]) should:be(@"This Should Get Cached")];
        [expectThat([cache etagForRequest:request]) should:be(@"686897696a7c876b7e")];
        [expectThat([loader.response wasLoadedFromCache]) should:be(NO)];
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
        [expectThat([loader success]) should:be(YES)];
        [expectThat([loader.response bodyAsString]) should:be(@"This Should Get Cached")];
        [expectThat([loader.response wasLoadedFromCache]) should:be(YES)];
    }
}

- (void)itShouldUpdateTheInternalCacheDateWhenWeRecieveA304 {
    NSString* baseURL = RKSpecGetBaseURL();
    NSString* cacheDirForClient = [NSString stringWithFormat:@"RKClientRequestCache-%@",
								   [[NSURL URLWithString:baseURL] host]];
	NSString* cachePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0]
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
        [expectThat([loader success]) should:be(YES)];
        [expectThat([loader.response bodyAsString]) should:be(@"This Should Get Cached")];
        [expectThat([cache etagForRequest:request]) should:be(@"686897696a7c876b7e")];
        [expectThat([loader.response wasLoadedFromCache]) should:be(NO)];
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
        [expectThat([loader success]) should:be(YES)];
        [expectThat([loader.response bodyAsString]) should:be(@"This Should Get Cached")];
        [expectThat([loader.response wasLoadedFromCache]) should:be(YES)];
        internalCacheDate2 = [cache cacheDateForRequest:request];
    }
    [expectThat(internalCacheDate1) shouldNot:be(internalCacheDate2)];
}

- (void)itShouldLoadFromTheCacheIfThereIsAnError {
    NSString* baseURL = RKSpecGetBaseURL();
    NSString* cacheDirForClient = [NSString stringWithFormat:@"RKClientRequestCache-%@",
								   [[NSURL URLWithString:baseURL] host]];
	NSString* cachePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0]
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
        [expectThat([loader success]) should:be(YES)];
        [expectThat([loader.response bodyAsString]) should:be(@"This Should Get Cached")];
        [expectThat([loader.response wasLoadedFromCache]) should:be(NO)];
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
        [expectThat([loader.response bodyAsString]) should:be(@"This Should Get Cached")];
        [expectThat([loader.response wasLoadedFromCache]) should:be(YES)];
    }
}

- (void)itShouldLoadFromTheCacheIfWeAreWithinTheTimeout {
    NSString* baseURL = RKSpecGetBaseURL();
    NSString* cacheDirForClient = [NSString stringWithFormat:@"RKClientRequestCache-%@",
								   [[NSURL URLWithString:baseURL] host]];
	NSString* cachePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0]
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
        [expectThat([loader success]) should:be(YES)];
        [expectThat([loader.response bodyAsString]) should:be(@"This Should Get Cached For 5 Seconds")];
        [expectThat([loader.response wasLoadedFromCache]) should:be(NO)];
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
        [expectThat([loader.response bodyAsString]) should:be(@"This Should Get Cached For 5 Seconds")];
        [expectThat([loader.response wasLoadedFromCache]) should:be(YES)];
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
        [expectThat([loader.response bodyAsString]) should:be(@"This Should Get Cached For 5 Seconds")];
        [expectThat([loader.response wasLoadedFromCache]) should:be(YES)];
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
        [expectThat([loader success]) should:be(YES)];
        [expectThat([loader.response bodyAsString]) should:be(@"This Should Get Cached For 5 Seconds")];
        [expectThat([loader.response wasLoadedFromCache]) should:be(NO)];
    }
}

- (void)itShouldLoadFromTheCacheIfWeAreOffline {
    NSString* baseURL = RKSpecGetBaseURL();
    NSString* cacheDirForClient = [NSString stringWithFormat:@"RKClientRequestCache-%@",
								   [[NSURL URLWithString:baseURL] host]];
	NSString* cachePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0]
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
        [expectThat([loader success]) should:be(YES)];
        [expectThat([loader.response bodyAsString]) should:be(@"This Should Get Cached")];
        [expectThat([loader.response wasLoadedFromCache]) should:be(NO)];
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
        [expectThat([loader.response bodyAsString]) should:be(@"This Should Get Cached")];
        [expectThat([loader.response wasLoadedFromCache]) should:be(YES)];
    }
}

- (void)itShouldCacheTheStatusCodeMIMETypeAndURL {
    NSString* baseURL = RKSpecGetBaseURL();
    NSString* cacheDirForClient = [NSString stringWithFormat:@"RKClientRequestCache-%@",
								   [[NSURL URLWithString:baseURL] host]];
	NSString* cachePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0]
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
        [expectThat([loader success]) should:be(YES)];
        [expectThat([loader.response bodyAsString]) should:be(@"This Should Get Cached")];
        NSLog(@"Headers: %@", [cache headersForRequest:request]);
        [expectThat([cache etagForRequest:request]) should:be(@"686897696a7c876b7e")];
        [expectThat([loader.response wasLoadedFromCache]) should:be(NO)];
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
        [expectThat([loader success]) should:be(YES)];
        [expectThat([loader.response wasLoadedFromCache]) should:be(YES)];
        [expectThat(loader.response.statusCode) should:be(200)];
        [expectThat(loader.response.MIMEType) should:be(@"text/html")];
        [expectThat([loader.response.URL absoluteString]) should:be(@"http://127.0.0.1:4567/etags/cached")];
    }
}

- (void)itShouldPostSimpleKeyValuesViaRKParams {
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

- (void)itShouldSetAnEmptyContentBodyWhenParamsIsNil {
    RKClient* client = RKSpecNewClient();
    client.cachePolicy = RKRequestCachePolicyNone;
    RKSpecStubNetworkAvailability(YES);
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    loader.timeout = 20;
    RKRequest* request = [client get:@"/echo_params" delegate:loader];
    [loader waitForResponse];
    assertThat([request.URLRequest valueForHTTPHeaderField:@"Content-Length"], is(equalTo(@"0")));
}

- (void)itShouldSetAnEmptyContentBodyWhenQueryParamsIsAnEmptyDictionary {
    RKClient* client = RKSpecNewClient();
    client.cachePolicy = RKRequestCachePolicyNone;
    RKSpecStubNetworkAvailability(YES);
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    loader.timeout = 20;
    RKRequest* request = [client get:@"/echo_params" queryParams:[NSDictionary dictionary] delegate:loader];
    [loader waitForResponse];
    assertThat([request.URLRequest valueForHTTPHeaderField:@"Content-Length"], is(equalTo(@"0")));
}

- (void)itShouldPUTWithParams {
    RKClient* client = RKSpecNewClient();
    RKParams *params = [RKParams params];    
    [params setValue:@"ddss" forParam:@"username"];    
    [params setValue:@"aaaa@aa.com" forParam:@"email"];
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    [client put:@"/ping" params:params delegate:loader];
    [loader waitForResponse];
    assertThat([loader.response bodyAsString], is(equalTo(@"{\"username\":\"ddss\",\"email\":\"aaaa@aa.com\"}")));
}

- (void)itShouldAllowYouToChangeTheURL {
    NSURL* URL = [NSURL URLWithString:@"http://restkit.org/monkey"];
    RKRequest* request = [RKRequest requestWithURL:URL delegate:self];
    request.URL = [NSURL URLWithString:@"http://restkit.org/gorilla"];
    assertThat([request.URL absoluteString], is(equalTo(@"http://restkit.org/gorilla")));
}

- (void)itShouldAllowYouToChangeTheResourcePath {
    RKURL* URL = [RKURL URLWithBaseURLString:@"http://restkit.org" resourcePath:@"/monkey"];
    RKRequest* request = [RKRequest requestWithURL:URL delegate:self];
    request.resourcePath = @"/gorilla";
    assertThat(request.resourcePath, is(equalTo(@"/gorilla")));
}

- (void)itShouldRaiseAnExceptionWhenAttemptingToMutateResourcePathOnAnNSURL {
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

- (void)itShouldOptionallySkipSSLValidation {
    RKClient* client = RKSpecNewClient();
    client.disableCertificateValidation = YES;
    NSURL* URL = [NSURL URLWithString:@"https://blakewatters.com/"];
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    RKRequest* request = [RKRequest requestWithURL:URL delegate:loader];
    [request send];
    [loader waitForResponse];
    assertThatBool([loader.response isOK], is(equalToBool(YES)));
}

- (void)itShouldNotAddANonZeroContentLengthHeaderIfParamsIsSetAndThisIsAGETRequest {
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

- (void)itShouldNotAddANonZeroContentLengthHeaderIfParamsIsSetAndThisIsAHEADRequest {
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
- (void)itShouldReturnACachePathWhenTheRequestIsUsingRKParams {
    RKParams *params = [RKParams params];
    [params setValue:@"foo" forParam:@"bar"];
    NSURL *URL = [NSURL URLWithString:@"http://restkit.org/"];
    RKRequest *request = [RKRequest requestWithURL:URL delegate:nil];
    request.params = params;
    NSString* baseURL = RKSpecGetBaseURL();
    NSString* cacheDirForClient = [NSString stringWithFormat:@"RKClientRequestCache-%@",
								   [[NSURL URLWithString:baseURL] host]];
    NSString* cachePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0]
						   stringByAppendingPathComponent:cacheDirForClient];
    RKRequestCache *requestCache = [[RKRequestCache alloc] initWithCachePath:cachePath storagePolicy:RKRequestCacheStoragePolicyForDurationOfSession];
    NSString *requestCachePath = [requestCache pathForRequest:request];
    NSArray *pathComponents = [requestCachePath pathComponents];
    NSString *cacheFile = [NSString pathWithComponents:[pathComponents subarrayWithRange:NSMakeRange([pathComponents count] - 2, 2)]];
    assertThat(cacheFile, is(equalTo(@"SessionStore/4ba47367884760141da2e38fda525a1f")));
}

- (void)itShouldReturnNilForCachePathWhenTheRequestIsADELETE {
    RKParams *params = [RKParams params];
    [params setValue:@"foo" forParam:@"bar"];
    NSURL *URL = [NSURL URLWithString:@"http://restkit.org/"];
    RKRequest *request = [RKRequest requestWithURL:URL delegate:nil];
    request.method = RKRequestMethodDELETE;
    NSString* baseURL = RKSpecGetBaseURL();
    NSString* cacheDirForClient = [NSString stringWithFormat:@"RKClientRequestCache-%@",
								   [[NSURL URLWithString:baseURL] host]];
    NSString* cachePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0]
						   stringByAppendingPathComponent:cacheDirForClient];
    RKRequestCache *requestCache = [[RKRequestCache alloc] initWithCachePath:cachePath storagePolicy:RKRequestCacheStoragePolicyForDurationOfSession];
    NSString *requestCachePath = [requestCache pathForRequest:request];
    assertThat(requestCachePath, is(nilValue()));
}

- (void)itShouldBuildAProperAuthorizationHeaderForOAuth1 {
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
