//
//  RKRequestQueueSpec.m
//  RestKit
//
//  Created by Blake Watters on 3/28/11.
//  Copyright 2011 Two Toasters
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

@interface RKRequestQueueSpec : RKSpec {
    
}

@end


@implementation RKRequestQueueSpec

- (void)testShouldBeSuspendedWhenInitialized {
    RKRequestQueue* queue = [RKRequestQueue new];
    assertThatBool(queue.suspended, is(equalToBool(YES)));
    [queue release];
}

#if TARGET_OS_IPHONE

// TODO: Crashing...
- (void)testShouldSuspendTheQueueOnTransitionToTheBackground {
    return;
    RKRequestQueue* queue = [RKRequestQueue new];
    assertThatBool(queue.suspended, is(equalToBool(YES)));
    queue.suspended = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
    assertThatBool(queue.suspended, is(equalToBool(YES)));
    [queue release];
}

- (void)testShouldUnsuspendTheQueueOnTransitionToTheForeground {
    // TODO: Crashing...
    return;
    RKRequestQueue* queue = [RKRequestQueue new];
    assertThatBool(queue.suspended, is(equalToBool(YES)));
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification object:nil];
    assertThatBool(queue.suspended, is(equalToBool(NO)));
    [queue release];
}

#endif

- (void)testShouldInformTheDelegateWhenSuspended {
    RKRequestQueue* queue = [RKRequestQueue new];
    assertThatBool(queue.suspended, is(equalToBool(YES)));
    queue.suspended = NO;
    OCMockObject* delegateMock = [OCMockObject niceMockForProtocol:@protocol(RKRequestQueueDelegate)];
    [[delegateMock expect] requestQueueWasSuspended:queue];
    queue.delegate = (NSObject<RKRequestQueueDelegate>*) delegateMock;
    queue.suspended = YES;
    [delegateMock verify];
    [queue release];
}

- (void)testShouldInformTheDelegateWhenUnsuspended {
    RKRequestQueue* queue = [RKRequestQueue new];
    assertThatBool(queue.suspended, is(equalToBool(YES)));
    OCMockObject* delegateMock = [OCMockObject niceMockForProtocol:@protocol(RKRequestQueueDelegate)];
    [[delegateMock expect] requestQueueWasUnsuspended:queue];
    queue.delegate = (NSObject<RKRequestQueueDelegate>*) delegateMock;
    queue.suspended = NO;
    [delegateMock verify];
    [queue release];
}

- (void)testShouldInformTheDelegateOnTransitionFromEmptyToProcessing {
    RKRequestQueue* queue = [RKRequestQueue new];
    OCMockObject* delegateMock = [OCMockObject niceMockForProtocol:@protocol(RKRequestQueueDelegate)];
    [[delegateMock expect] requestQueueDidBeginLoading:queue];
    queue.delegate = (NSObject<RKRequestQueueDelegate>*) delegateMock;
    [queue setValue:[NSNumber numberWithInt:1] forKey:@"loadingCount"];
    [delegateMock verify];
    [queue release];
}

- (void)testShouldInformTheDelegateOnTransitionFromProcessingToEmpty {
    RKRequestQueue* queue = [RKRequestQueue new];
    OCMockObject* delegateMock = [OCMockObject niceMockForProtocol:@protocol(RKRequestQueueDelegate)];
    [[delegateMock expect] requestQueueDidFinishLoading:queue];
    queue.delegate = (NSObject<RKRequestQueueDelegate>*) delegateMock;
    [queue setValue:[NSNumber numberWithInt:1] forKey:@"loadingCount"];
    [queue setValue:[NSNumber numberWithInt:0] forKey:@"loadingCount"];
    [delegateMock verify];
    [queue release];
}

- (void)testShouldInformTheDelegateOnTransitionFromProcessingToEmptyForQueuesWithASingleRequest {
    OCMockObject* delegateMock = [OCMockObject niceMockForProtocol:@protocol(RKRequestQueueDelegate)];
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];

    NSString* url = [NSString stringWithFormat:@"%@/ok-with-delay/0.3", RKSpecGetBaseURL()];
    NSURL* URL = [NSURL URLWithString:url];
    RKRequest * request = [[RKRequest alloc] initWithURL:URL];
    request.delegate = loader;

    RKRequestQueue* queue = [RKRequestQueue new];
    queue.delegate = (NSObject<RKRequestQueueDelegate>*) delegateMock;
    [[delegateMock expect] requestQueueDidFinishLoading:queue];
    [queue addRequest:request];
    [queue start];
    [loader waitForResponse];
    [delegateMock verify];
}

// TODO: These tests cannot pass in the unit testing environment... Need to migrate to an integration
// testing area
//- (void)testShouldBeginSpinningTheNetworkActivityIfAsked {
//    [[UIApplication sharedApplication] rk_resetNetworkActivity];
//    RKRequestQueue* queue = [RKRequestQueue new];
//    queue.showsNetworkActivityIndicatorWhenBusy = YES;
//    assertThatBool([UIApplication sharedApplication].networkActivityIndicatorVisible, is(equalToBool(NO)));
//    [queue setValue:[NSNumber numberWithInt:1] forKey:@"loadingCount"];
//    assertThatBool([UIApplication sharedApplication].networkActivityIndicatorVisible, is(equalToBool(YES)));
//    [queue release];
//}
//
//- (void)testShouldStopSpinningTheNetworkActivityIfAsked {
//    [[UIApplication sharedApplication] rk_resetNetworkActivity];
//    RKRequestQueue* queue = [RKRequestQueue new];
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
//    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
//    loader.timeout = 10;
//
//    RKRequestQueue *queue1 = [RKRequestQueue new];
//    queue1.showsNetworkActivityIndicatorWhenBusy = YES;
//    NSString* url1 = [NSString stringWithFormat:@"%@/ok-with-delay/2.0", RKSpecGetBaseURL()];
//    NSURL* URL1 = [NSURL URLWithString:url1];
//    RKRequest * request1 = [[RKRequest alloc] initWithURL:URL1];
//    request1.delegate = loader;
//
//    RKRequestQueue *queue2 = [RKRequestQueue new];
//    queue2.showsNetworkActivityIndicatorWhenBusy = YES;
//    NSString* url2 = [NSString stringWithFormat:@"%@/ok-with-delay/2.0", RKSpecGetBaseURL()];
//    NSURL* URL2 = [NSURL URLWithString:url2];
//    RKRequest * request2 = [[RKRequest alloc] initWithURL:URL2];
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

- (void)testShouldLetYouReturnAQueueByName {
    RKRequestQueue* queue = [RKRequestQueue requestQueueWithName:@"Images"];
    assertThat(queue, isNot(nilValue()));
    assertThat(queue.name, is(equalTo(@"Images")));
}

- (void)testShouldReturnAnExistingQueueByName {
    RKRequestQueue* queue = [RKRequestQueue requestQueueWithName:@"Images2"];
    assertThat(queue, isNot(nilValue()));
    RKRequestQueue* secondQueue = [RKRequestQueue requestQueueWithName:@"Images2"];
    assertThat(queue, is(equalTo(secondQueue)));
}

- (void)testShouldReturnTheQueueWithoutAModifiedRetainCount {
    RKRequestQueue* queue = [RKRequestQueue requestQueueWithName:@"Images3"];
    assertThat(queue, isNot(nilValue()));
    assertThatUnsignedInteger([queue retainCount], is(equalToInt(1)));
}

- (void)testShouldReturnYESWhenAQueueExistsWithAGivenName {
    assertThatBool([RKRequestQueue requestQueueExistsWithName:@"Images4"], is(equalToBool(NO)));
    [RKRequestQueue requestQueueWithName:@"Images4"];
    assertThatBool([RKRequestQueue requestQueueExistsWithName:@"Images4"], is(equalToBool(YES)));
}

- (void)testShouldRemoveTheQueueFromTheNamedInstancesOnDealloc {
    // TODO: Crashing...
    return;
    RKRequestQueue* queue = [RKRequestQueue requestQueueWithName:@"Images5"];
    assertThat(queue, isNot(nilValue()));
    assertThatBool([RKRequestQueue requestQueueExistsWithName:@"Images5"], is(equalToBool(YES)));
    [queue release];
    assertThatBool([RKRequestQueue requestQueueExistsWithName:@"Images5"], is(equalToBool(NO)));
}

- (void)testShouldReturnANewOwningReferenceViaNewRequestWithName {
    RKRequestQueue* requestQueue = [RKRequestQueue newRequestQueueWithName:@"Images6"];
    assertThat(requestQueue, isNot(nilValue()));
    assertThatUnsignedInteger([requestQueue retainCount], is(equalToInt(1)));
}

- (void)testShouldReturnNilIfNewRequestQueueWithNameIsCalledForAnExistingName {
    RKRequestQueue* queue = [RKRequestQueue newRequestQueueWithName:@"Images7"];
    assertThat(queue, isNot(nilValue()));
    RKRequestQueue* queue2 = [RKRequestQueue newRequestQueueWithName:@"Images7"];
    assertThat(queue2, is(nilValue()));
}

- (void)testShouldRemoveItemsFromTheQueueWithAnUnmappableResponse {
    RKRequestQueue *queue = [RKRequestQueue requestQueue];
    RKObjectManager *objectManager = RKSpecNewObjectManager();
    RKSpecResponseLoader *loader = [RKSpecResponseLoader responseLoader];
    RKObjectLoader *objectLoader = [RKObjectLoader loaderWithResourcePath:@"/403" objectManager:objectManager delegate:loader];
    [queue addRequest:(RKRequest *)objectLoader];
    [queue start];
    [loader waitForResponse];
    assertThatUnsignedInteger(queue.loadingCount, is(equalToInt(0)));
}

@end
