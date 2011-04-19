//
//  RKRequestQueueSpec.m
//  RestKit
//
//  Created by Blake Watters on 3/28/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKSpecEnvironment.h"

@interface RKRequestQueueSpec : NSObject <UISpec> {
    
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
    RKRequestQueue* queue = [RKRequestQueue new];
    queue.showsNetworkActivityIndicatorWhenBusy = YES;
    [expectThat([UIApplication sharedApplication].networkActivityIndicatorVisible) should:be(NO)];
    [queue setValue:[NSNumber numberWithInt:1] forKey:@"loadingCount"];
    [expectThat([UIApplication sharedApplication].networkActivityIndicatorVisible) should:be(YES)];
    [queue release];
}

- (void)itShouldStopSpinningTheNetworkActivityIfAsked {
    RKRequestQueue* queue = [RKRequestQueue new];
    queue.showsNetworkActivityIndicatorWhenBusy = YES;
    [queue setValue:[NSNumber numberWithInt:1] forKey:@"loadingCount"];
    [expectThat([UIApplication sharedApplication].networkActivityIndicatorVisible) should:be(YES)];
    [queue setValue:[NSNumber numberWithInt:0] forKey:@"loadingCount"];
    [expectThat([UIApplication sharedApplication].networkActivityIndicatorVisible) should:be(NO)];
    [queue release];
}

@end
