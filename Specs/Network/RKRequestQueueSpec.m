//
//  RKRequestQueueSpec.m
//  RestKit
//
//  Created by Blake Watters on 3/28/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"

@interface RKRequestQueueSpec : RKSpec {
    
}

@end


@implementation RKRequestQueueSpec

- (void)itShouldBeSuspendedWhenInitialized {
    RKRequestQueue* queue = [RKRequestQueue new];
    [expectThat(queue.suspended) should:be(YES)];
    [queue release];
}

- (void)itShouldSuspendTheQueueOnTransitionToTheBackground {
    RKRequestQueue* queue = [RKRequestQueue new];
    [expectThat(queue.suspended) should:be(YES)];
    queue.suspended = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
    [expectThat(queue.suspended) should:be(YES)];
    [queue release];
}

- (void)itShouldUnsuspendTheQueueOnTransitionToTheForeground {
    RKRequestQueue* queue = [RKRequestQueue new];
    [expectThat(queue.suspended) should:be(YES)];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification object:nil];
    [expectThat(queue.suspended) should:be(NO)];
    [queue release];
}

- (void)itShouldInformTheDelegateWhenSuspended {
    RKRequestQueue* queue = [RKRequestQueue new];
    [expectThat(queue.suspended) should:be(YES)];
    queue.suspended = NO;
    OCMockObject* delegateMock = [OCMockObject niceMockForProtocol:@protocol(RKRequestQueueDelegate)];
    [[delegateMock expect] requestQueueWasSuspended:queue];
    queue.delegate = (NSObject<RKRequestQueueDelegate>*) delegateMock;
    queue.suspended = YES;
    [delegateMock verify];
    [queue release];
}

- (void)itShouldInformTheDelegateWhenUnsuspended {
    RKRequestQueue* queue = [RKRequestQueue new];
    [expectThat(queue.suspended) should:be(YES)];
    OCMockObject* delegateMock = [OCMockObject niceMockForProtocol:@protocol(RKRequestQueueDelegate)];
    [[delegateMock expect] requestQueueWasUnsuspended:queue];
    queue.delegate = (NSObject<RKRequestQueueDelegate>*) delegateMock;
    queue.suspended = NO;
    [delegateMock verify];
    [queue release];
}

- (void)itShouldInformTheDelegateOnTransitionFromEmptyToProcessing {
    RKRequestQueue* queue = [RKRequestQueue new];
    OCMockObject* delegateMock = [OCMockObject niceMockForProtocol:@protocol(RKRequestQueueDelegate)];
    [[delegateMock expect] requestQueueDidBeginLoading:queue];
    queue.delegate = (NSObject<RKRequestQueueDelegate>*) delegateMock;
    [queue setValue:[NSNumber numberWithInt:1] forKey:@"loadingCount"];
    [delegateMock verify];
    [queue release];
}

- (void)itShouldInformTheDelegateOnTransitionFromProcessingToEmpty {
    RKRequestQueue* queue = [RKRequestQueue new];
    OCMockObject* delegateMock = [OCMockObject niceMockForProtocol:@protocol(RKRequestQueueDelegate)];
    [[delegateMock expect] requestQueueDidFinishLoading:queue];
    queue.delegate = (NSObject<RKRequestQueueDelegate>*) delegateMock;
    [queue setValue:[NSNumber numberWithInt:1] forKey:@"loadingCount"];
    [queue setValue:[NSNumber numberWithInt:0] forKey:@"loadingCount"];
    [delegateMock verify];
    [queue release];
}

- (void)itShouldInformTheDelegateOnTransitionFromProcessingToEmptyForQueuesWithASingleRequest {
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

- (void)itShouldBeginSpinningTheNetworkActivityIfAsked {
    [[UIApplication sharedApplication] rk_resetNetworkActivity];
    RKRequestQueue* queue = [RKRequestQueue new];
    queue.showsNetworkActivityIndicatorWhenBusy = YES;
    [expectThat([UIApplication sharedApplication].networkActivityIndicatorVisible) should:be(NO)];
    [queue setValue:[NSNumber numberWithInt:1] forKey:@"loadingCount"];
    [expectThat([UIApplication sharedApplication].networkActivityIndicatorVisible) should:be(YES)];
    [queue release];
}

- (void)itShouldStopSpinningTheNetworkActivityIfAsked {
    [[UIApplication sharedApplication] rk_resetNetworkActivity];
    RKRequestQueue* queue = [RKRequestQueue new];
    queue.showsNetworkActivityIndicatorWhenBusy = YES;
    [queue setValue:[NSNumber numberWithInt:1] forKey:@"loadingCount"];
    [expectThat([UIApplication sharedApplication].networkActivityIndicatorVisible) should:be(YES)];
    [queue setValue:[NSNumber numberWithInt:0] forKey:@"loadingCount"];
    [expectThat([UIApplication sharedApplication].networkActivityIndicatorVisible) should:be(NO)];
    [queue release];
}

- (void)itShouldJointlyManageTheNetworkActivityIndicator {
    [[UIApplication sharedApplication] rk_resetNetworkActivity];
    RKSpecResponseLoader* loader = [RKSpecResponseLoader responseLoader];
    loader.timeout = 10;

    RKRequestQueue *queue1 = [RKRequestQueue new];
    queue1.showsNetworkActivityIndicatorWhenBusy = YES;
    NSString* url1 = [NSString stringWithFormat:@"%@/ok-with-delay/2.0", RKSpecGetBaseURL()];
    NSURL* URL1 = [NSURL URLWithString:url1];
    RKRequest * request1 = [[RKRequest alloc] initWithURL:URL1];
    request1.delegate = loader;

    RKRequestQueue *queue2 = [RKRequestQueue new];
    queue2.showsNetworkActivityIndicatorWhenBusy = YES;
    NSString* url2 = [NSString stringWithFormat:@"%@/ok-with-delay/2.0", RKSpecGetBaseURL()];
    NSURL* URL2 = [NSURL URLWithString:url2];
    RKRequest * request2 = [[RKRequest alloc] initWithURL:URL2];
    request2.delegate = loader;

    [expectThat([UIApplication sharedApplication].networkActivityIndicatorVisible) should:be(NO)];
    [queue1 addRequest:request1];
    [queue1 start];
    [expectThat([UIApplication sharedApplication].networkActivityIndicatorVisible) should:be(YES)];
    [queue2 addRequest:request2];
    [queue2 start];
    [expectThat([UIApplication sharedApplication].networkActivityIndicatorVisible) should:be(YES)];
    [loader waitForResponse];
    [expectThat([UIApplication sharedApplication].networkActivityIndicatorVisible) should:be(YES)];
    [loader waitForResponse];
    [expectThat([UIApplication sharedApplication].networkActivityIndicatorVisible) should:be(NO)];
}

- (void)itShouldLetYouReturnAQueueByName {
    RKRequestQueue* queue = [RKRequestQueue requestQueueWithName:@"Images"];
    assertThat(queue, isNot(nilValue()));
    assertThat(queue.name, is(equalTo(@"Images")));
}

- (void)itShouldReturnAnExistingQueueByName {
    RKRequestQueue* queue = [RKRequestQueue requestQueueWithName:@"Images2"];
    assertThat(queue, isNot(nilValue()));
    RKRequestQueue* secondQueue = [RKRequestQueue requestQueueWithName:@"Images2"];
    assertThat(queue, is(equalTo(secondQueue)));
}

- (void)itShouldReturnTheQueueWithoutAModifiedRetainCount {
    RKRequestQueue* queue = [RKRequestQueue requestQueueWithName:@"Images3"];
    assertThat(queue, isNot(nilValue()));
    assertThatInt([queue retainCount], is(equalToInt(1)));
}

- (void)itShouldReturnYESWhenAQueueExistsWithAGivenName {
    assertThatBool([RKRequestQueue requestQueueExistsWithName:@"Images4"], is(equalToBool(NO)));
    [RKRequestQueue requestQueueWithName:@"Images4"];
    assertThatBool([RKRequestQueue requestQueueExistsWithName:@"Images4"], is(equalToBool(YES)));
}

- (void)itShouldRemoveTheQueueFromTheNamedInstancesOnDealloc {
    RKRequestQueue* queue = [RKRequestQueue requestQueueWithName:@"Images5"];
    assertThat(queue, isNot(nilValue()));
    assertThatBool([RKRequestQueue requestQueueExistsWithName:@"Images5"], is(equalToBool(YES)));
    [queue release];
    assertThatBool([RKRequestQueue requestQueueExistsWithName:@"Images5"], is(equalToBool(NO)));
}

- (void)itShouldReturnANewOwningReferenceViaNewRequestWithName {
    RKRequestQueue* requestQueue = [RKRequestQueue newRequestQueueWithName:@"Images6"];
    assertThat(requestQueue, isNot(nilValue()));
    assertThatInt([requestQueue retainCount], is(equalToInt(1)));
}

- (void)itShouldReturnNilIfNewRequestQueueWithNameIsCalledForAnExistingName {
    RKRequestQueue* queue = [RKRequestQueue newRequestQueueWithName:@"Images7"];
    assertThat(queue, isNot(nilValue()));
    RKRequestQueue* queue2 = [RKRequestQueue newRequestQueueWithName:@"Images7"];
    assertThat(queue2, is(nilValue()));
}

@end
