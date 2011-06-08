//
//  RKRequestSpec.m
//  RestKit
//
//  Created by Blake Watters on 1/15/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"
#import "RKRequest.h"
#import "RKParams.h"
#import "RKResponse.h"

@interface RKRequest (Private)
- (void)fireAsynchronousRequest;
- (void)shouldDispatchRequest;
@end

@interface RKRequestSpec : NSObject <UISpec> {
}

@end

@implementation RKRequestSpec

/**
 * This spec requires the test Sinatra server to be running
 * `ruby Specs/server.rb`
 */
- (void)itShouldSendMultiPartRequests {
	NSString* URLString = [NSString stringWithFormat:@"http://127.0.0.1:4567/photo"];
	NSURL* URL = [NSURL URLWithString:URLString];
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
    RKRequestQueue* queue = [[RKRequestQueue new] autorelease];
    [RKRequestQueue setSharedQueue:queue];
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
    [RKRequestQueue setSharedQueue:queue];
    [RKRequestQueue sharedQueue].suspended = YES;
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    NSURL* URL = [NSURL URLWithString:RKSpecGetBaseURL()];
    RKRequest* request = [[RKRequest alloc] initWithURL:URL];
    request.backgroundPolicy = RKRequestBackgroundPolicyRequeue;
    request.delegate = loader;
    [request sendAsynchronously];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
    [expectThat([request isLoading]) should:be(NO)];
    [expectThat([[RKRequestQueue sharedQueue] containsRequest:request]) should:be(YES)];
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
        [expectThat([loader.response.URL absoluteString]) should:be(@"http://localhost:4567/etags/cached")];
    }
}

@end
