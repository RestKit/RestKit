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

- (void)itShouldNotBeSuspendedWhenInitialized {
    RKRequestQueue* queue = [[RKRequestQueue alloc] init];
    [expectThat(queue.suspended) should:be(NO)];
    [queue release];
}

- (void)itShouldSuspendTheQueueOnTransitionToTheBackground {
    RKRequestQueue* queue = [[RKRequestQueue alloc] init];
    [expectThat(queue.suspended) should:be(NO)];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:nil];
    [expectThat(queue.suspended) should:be(YES)];
    [queue release];
}

- (void)itShouldUnsuspendTheQueueOnTransitionToTheForeground {
    RKRequestQueue* queue = [[RKRequestQueue alloc] init];
    [expectThat(queue.suspended) should:be(NO)];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification object:nil];
    [expectThat(queue.suspended) should:be(NO)];
    [queue release];
}

@end
