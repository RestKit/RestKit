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
    NSString* url2 = [NSString stringWithFormat:@"%@/ok-with-delay/5.0", RKSpecGetBaseURL()];
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

@end
