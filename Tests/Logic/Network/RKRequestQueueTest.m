//
//  RKRequestQueueTest.m
//  RestKit
//
//  Created by Blake Watters on 3/28/11.
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

// Expose the request queue's [add|remove]LoadingRequest methods testing purposes...
@interface RKRequestQueue ()
- (void)addLoadingRequest:(RKRequest *)request;
- (void)removeLoadingRequest:(RKRequest *)request;
@end

@interface RKRequestQueueTest : RKTestCase {
    NSAutoreleasePool *_autoreleasePool;
}

@end


@implementation RKRequestQueueTest

- (void)setUp
{
    _autoreleasePool = [NSAutoreleasePool new];
}

- (void)tearDown
{
    [_autoreleasePool drain];
}

- (void)testShouldBeSuspendedWhenInitialized
{
    RKRequestQueue *queue = [RKRequestQueue new];
    assertThatBool(queue.suspended, is(equalToBool(YES)));
    [queue release];
}

#if TARGET_OS_IPHONE

// TODO: Crashing...
- (void)testShouldSuspendTheQueueOnTransitionToTheBackground
{
    return;
    RKRequestQueue *queue = [RKRequestQueue new];
    assertThatBool(queue.suspended, is(equalToBool(YES)));
    queue.suspended = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
    assertThatBool(queue.suspended, is(equalToBool(YES)));
    [queue release];
}

- (void)testShouldUnsuspendTheQueueOnTransitionToTheForeground
{
    // TODO: Crashing...
    return;
    RKRequestQueue *queue = [RKRequestQueue new];
    assertThatBool(queue.suspended, is(equalToBool(YES)));
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification object:nil];
    assertThatBool(queue.suspended, is(equalToBool(NO)));
    [queue release];
}

#endif

- (void)testShouldInformTheDelegateWhenSuspended
{
    RKRequestQueue *queue = [RKRequestQueue new];
    assertThatBool(queue.suspended, is(equalToBool(YES)));
    queue.suspended = NO;
    OCMockObject *delegateMock = [OCMockObject niceMockForProtocol:@protocol(RKRequestQueueDelegate)];
    [[delegateMock expect] requestQueueWasSuspended:queue];
    queue.delegate = (NSObject<RKRequestQueueDelegate> *)delegateMock;
    queue.suspended = YES;
    [delegateMock verify];
    [queue release];
}

- (void)testShouldInformTheDelegateWhenUnsuspended
{
    RKRequestQueue *queue = [RKRequestQueue new];
    assertThatBool(queue.suspended, is(equalToBool(YES)));
    OCMockObject *delegateMock = [OCMockObject niceMockForProtocol:@protocol(RKRequestQueueDelegate)];
    [[delegateMock expect] requestQueueWasUnsuspended:queue];
    queue.delegate = (NSObject<RKRequestQueueDelegate> *)delegateMock;
    queue.suspended = NO;
    [delegateMock verify];
    [queue release];
}

- (void)testShouldInformTheDelegateOnTransitionFromEmptyToProcessing
{
    RKRequestQueue *queue = [RKRequestQueue new];
    OCMockObject *delegateMock = [OCMockObject niceMockForProtocol:@protocol(RKRequestQueueDelegate)];
    [[delegateMock expect] requestQueueDidBeginLoading:queue];
    queue.delegate = (NSObject<RKRequestQueueDelegate> *)delegateMock;
    NSURL *URL = [RKTestFactory baseURL];
    RKRequest *request = [[RKRequest alloc] initWithURL:URL];
    [queue addLoadingRequest:request];
    [delegateMock verify];
    [queue release];
}

- (void)testShouldInformTheDelegateOnTransitionFromProcessingToEmpty
{
    RKRequestQueue *queue = [RKRequestQueue new];
    OCMockObject *delegateMock = [OCMockObject niceMockForProtocol:@protocol(RKRequestQueueDelegate)];
    [[delegateMock expect] requestQueueDidFinishLoading:queue];
    queue.delegate = (NSObject<RKRequestQueueDelegate> *)delegateMock;
    NSURL *URL = [RKTestFactory baseURL];
    RKRequest *request = [[RKRequest alloc] initWithURL:URL];
    [queue addLoadingRequest:request];
    [queue removeLoadingRequest:request];
    [delegateMock verify];
    [queue release];
}

- (void)testShouldInformTheDelegateOnTransitionFromProcessingToEmptyForQueuesWithASingleRequest
{
    OCMockObject *delegateMock = [OCMockObject niceMockForProtocol:@protocol(RKRequestQueueDelegate)];
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];

    NSString *url = [NSString stringWithFormat:@"%@/ok-with-delay/0.3", [RKTestFactory baseURLString]];
    NSURL *URL = [NSURL URLWithString:url];
    RKRequest *request = [[RKRequest alloc] initWithURL:URL];
    request.delegate = loader;

    RKRequestQueue *queue = [RKRequestQueue new];
    queue.delegate = (NSObject<RKRequestQueueDelegate> *)delegateMock;
    [[delegateMock expect] requestQueueDidFinishLoading:queue];
    [queue addRequest:request];
    [queue start];
    [loader waitForResponse];
    [delegateMock verify];
    [queue release];
}

// TODO: These tests cannot pass in the unit testing environment... Need to migrate to an integration
// testing area
//- (void)testShouldBeginSpinningTheNetworkActivityIfAsked {
//    [[UIApplication sharedApplication] rk_resetNetworkActivity];
//    RKRequestQueue *queue = [RKRequestQueue new];
//    queue.showsNetworkActivityIndicatorWhenBusy = YES;
//    assertThatBool([UIApplication sharedApplication].networkActivityIndicatorVisible, is(equalToBool(NO)));
//    [queue setValue:[NSNumber numberWithInt:1] forKey:@"loadingCount"];
//    assertThatBool([UIApplication sharedApplication].networkActivityIndicatorVisible, is(equalToBool(YES)));
//    [queue release];
//}
//
//- (void)testShouldStopSpinningTheNetworkActivityIfAsked {
//    [[UIApplication sharedApplication] rk_resetNetworkActivity];
//    RKRequestQueue *queue = [RKRequestQueue new];
//    queue.showsNetworkActivityIndicatorWhenBusy = YES;
//    [queue setValue:[NSNumber numberWithInt:1] forKey:@"loadingCount"];
//    assertThatBool([UIApplication sharedApplication].networkActivityIndicatorVisible, is(equalToBool(YES)));
//    [queue setValue:[NSNumber numberWithInt:0] forKey:@"loadingCount"];
//    assertThatBool([UIApplication sharedApplication].networkActivityIndicatorVisible, is(equalToBool(NO)));
//    [queue release];
//}
//
//- (void)testShouldJointlyManageTheNetworkActivityIndicator {
//    [[UIApplication sharedApplication] rk_resetNetworkActivity];
//    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
//    loader.timeout = 10;
//
//    RKRequestQueue *queue1 = [RKRequestQueue new];
//    queue1.showsNetworkActivityIndicatorWhenBusy = YES;
//    NSString *url1 = [NSString stringWithFormat:@"%@/ok-with-delay/2.0", [RKTestFactory baseURL]];
//    NSURL *URL1 = [NSURL URLWithString:url1];
//    RKRequest *request1 = [[RKRequest alloc] initWithURL:URL1];
//    request1.delegate = loader;
//
//    RKRequestQueue *queue2 = [RKRequestQueue new];
//    queue2.showsNetworkActivityIndicatorWhenBusy = YES;
//    NSString *url2 = [NSString stringWithFormat:@"%@/ok-with-delay/2.0", [RKTestFactory baseURL]];
//    NSURL *URL2 = [NSURL URLWithString:url2];
//    RKRequest *request2 = [[RKRequest alloc] initWithURL:URL2];
//    request2.delegate = loader;
//
//    assertThatBool([UIApplication sharedApplication].networkActivityIndicatorVisible, is(equalToBool(NO)));
//    [queue1 addRequest:request1];
//    [queue1 start];
//    assertThatBool([UIApplication sharedApplication].networkActivityIndicatorVisible, is(equalToBool(YES)));
//    [queue2 addRequest:request2];
//    [queue2 start];
//    assertThatBool([UIApplication sharedApplication].networkActivityIndicatorVisible, is(equalToBool(YES)));
//    [loader waitForResponse];
//    assertThatBool([UIApplication sharedApplication].networkActivityIndicatorVisible, is(equalToBool(YES)));
//    [loader waitForResponse];
//    assertThatBool([UIApplication sharedApplication].networkActivityIndicatorVisible, is(equalToBool(NO)));
//}

- (void)testShouldLetYouReturnAQueueByName
{
    RKRequestQueue *queue = [RKRequestQueue requestQueueWithName:@"Images"];
    assertThat(queue, isNot(nilValue()));
    assertThat(queue.name, is(equalTo(@"Images")));
}

- (void)testShouldReturnAnExistingQueueByName
{
    RKRequestQueue *queue = [RKRequestQueue requestQueueWithName:@"Images2"];
    assertThat(queue, isNot(nilValue()));
    RKRequestQueue *secondQueue = [RKRequestQueue requestQueueWithName:@"Images2"];
    assertThat(queue, is(equalTo(secondQueue)));
}

- (void)testShouldReturnTheQueueWithoutAModifiedRetainCount
{
    RKRequestQueue *queue = [RKRequestQueue requestQueueWithName:@"Images3"];
    assertThat(queue, isNot(nilValue()));
    assertThatUnsignedInteger([queue retainCount], is(equalToInt(1)));
}

- (void)testShouldReturnYESWhenAQueueExistsWithAGivenName
{
    assertThatBool([RKRequestQueue requestQueueExistsWithName:@"Images4"], is(equalToBool(NO)));
    [RKRequestQueue requestQueueWithName:@"Images4"];
    assertThatBool([RKRequestQueue requestQueueExistsWithName:@"Images4"], is(equalToBool(YES)));
}

- (void)testShouldRemoveTheQueueFromTheNamedInstancesOnDealloc
{
    // TODO: Crashing...
    return;
    RKRequestQueue *queue = [RKRequestQueue requestQueueWithName:@"Images5"];
    assertThat(queue, isNot(nilValue()));
    assertThatBool([RKRequestQueue requestQueueExistsWithName:@"Images5"], is(equalToBool(YES)));
    [queue release];
    assertThatBool([RKRequestQueue requestQueueExistsWithName:@"Images5"], is(equalToBool(NO)));
}

- (void)testShouldReturnANewOwningReferenceViaNewRequestWithName
{
    RKRequestQueue *requestQueue = [RKRequestQueue newRequestQueueWithName:@"Images6"];
    assertThat(requestQueue, isNot(nilValue()));
    assertThatUnsignedInteger([requestQueue retainCount], is(equalToInt(1)));
}

- (void)testShouldReturnNilIfNewRequestQueueWithNameIsCalledForAnExistingName
{
    RKRequestQueue *queue = [RKRequestQueue newRequestQueueWithName:@"Images7"];
    assertThat(queue, isNot(nilValue()));
    RKRequestQueue *queue2 = [RKRequestQueue newRequestQueueWithName:@"Images7"];
    assertThat(queue2, is(nilValue()));
}

- (void)testShouldRemoveItemsFromTheQueueWithAnUnmappableResponse
{
    RKRequestQueue *queue = [RKRequestQueue requestQueue];
    RKObjectManager *objectManager = [RKTestFactory objectManager];
    RKTestResponseLoader *loader = [RKTestResponseLoader responseLoader];
    RKObjectLoader *objectLoader = [objectManager loaderWithResourcePath:@"/403"];
    objectLoader.delegate = loader;
    [queue addRequest:(RKRequest *)objectLoader];
    [queue start];
    [loader waitForResponse];
    assertThatUnsignedInteger(queue.loadingCount, is(equalToInt(0)));
}

- (void)testThatSendingRequestToInvalidURLDoesNotGetSentTwice
{
    RKRequestQueue *queue = [RKRequestQueue requestQueue];
    NSURL *URL = [NSURL URLWithString:@"http://localhost:7662/RKRequestQueueExample"];
    RKRequest *request = [RKRequest requestWithURL:URL];
    RKTestResponseLoader *responseLoader = [RKTestResponseLoader responseLoader];
    id mockResponseLoader = [OCMockObject partialMockForObject:responseLoader];
    [[[mockResponseLoader expect] andForwardToRealObject] request:request didFailLoadWithError:OCMOCK_ANY];
    request.delegate = responseLoader;
    id mockQueueDelegate = [OCMockObject niceMockForProtocol:@protocol(RKRequestQueueDelegate)];
    __block NSUInteger invocationCount = 0;
    [[mockQueueDelegate stub] requestQueue:queue willSendRequest:[OCMArg checkWithBlock:^BOOL(id request) {
        invocationCount++;
        return YES;
    }]];
    [queue addRequest:request];
    queue.delegate = mockQueueDelegate;
    [queue start];
    [mockResponseLoader waitForResponse];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    [mockResponseLoader verify];
    assertThatInteger(invocationCount, is(equalToInteger(1)));
}

@end
