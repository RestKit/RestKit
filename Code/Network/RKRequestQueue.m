//
//  RKRequestQueue.m
//  RestKit
//
//  Created by Blake Watters on 12/1/10.
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

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#import "RKClient.h"
#import "RKRequestQueue.h"
#import "RKResponse.h"
#import "RKNotifications.h"
#import "RKLog.h"
#import "RKFixCategoryBug.h"

RK_FIX_CATEGORY_BUG(UIApplication_RKNetworkActivity)

// Constants
static NSMutableArray *RKRequestQueueInstances = nil;

static const NSTimeInterval kFlushDelay = 0.3;

// Set Logging Component
#undef RKLogComponent
#define RKLogComponent lcl_cRestKitNetworkQueue

@interface RKRequestQueue ()
@property (nonatomic, retain, readwrite) NSString *name;
@end

@implementation RKRequestQueue

@synthesize name = _name;
@synthesize delegate = _delegate;
@synthesize concurrentRequestsLimit = _concurrentRequestsLimit;
@synthesize requestTimeout = _requestTimeout;
@synthesize suspended = _suspended;

#if TARGET_OS_IPHONE
@synthesize showsNetworkActivityIndicatorWhenBusy = _showsNetworkActivityIndicatorWhenBusy;
#endif

+ (RKRequestQueue *)sharedQueue
{
    RKLogWarning(@"Deprecated invocation of [RKRequestQueue sharedQueue]. Returning [RKClient sharedClient].requestQueue. Update your code to reference the queue you want explicitly.");
    return [RKClient sharedClient].requestQueue;
}

+ (void)setSharedQueue:(RKRequestQueue *)requestQueue
{
    RKLogWarning(@"Deprecated access to [RKRequestQueue setSharedQueue:]. Invoking [[RKClient sharedClient] setRequestQueue:]. Update your code to reference the specific queue instance you want.");
    [RKClient sharedClient].requestQueue = requestQueue;
}

+ (id)requestQueue
{
    return [[self new] autorelease];
}

+ (id)newRequestQueueWithName:(NSString *)name
{
    if (RKRequestQueueInstances == nil) {
        RKRequestQueueInstances = [NSMutableArray new];
    }

    if ([self requestQueueExistsWithName:name]) {
        return nil;
    }

    RKRequestQueue *queue = [self new];
    queue.name = name;
    [RKRequestQueueInstances addObject:[NSValue valueWithNonretainedObject:queue]];

    return queue;
}

+ (id)requestQueueWithName:(NSString *)name
{
    if (RKRequestQueueInstances == nil) {
        RKRequestQueueInstances = [NSMutableArray new];
    }

    // Find existing reference
    NSArray *requestQueueInstances = [RKRequestQueueInstances copy];
    RKRequestQueue *namedQueue = nil;
    for (NSValue *value in requestQueueInstances) {
        RKRequestQueue *queue = (RKRequestQueue *)[value nonretainedObjectValue];
        if ([queue.name isEqualToString:name]) {
            namedQueue = queue;
            break;
        }
    }
    [requestQueueInstances release];

    if (namedQueue == nil) {
        namedQueue = [self requestQueue];
        namedQueue.name = name;
        [RKRequestQueueInstances addObject:[NSValue valueWithNonretainedObject:namedQueue]];
    }

    return namedQueue;
}

+ (BOOL)requestQueueExistsWithName:(NSString *)name
{
    BOOL queueExists = NO;
    if (RKRequestQueueInstances) {
        NSArray *requestQueueInstances = [RKRequestQueueInstances copy];
        for (NSValue *value in requestQueueInstances) {
            RKRequestQueue *queue = (RKRequestQueue *)[value nonretainedObjectValue];
            if ([queue.name isEqualToString:name]) {
                queueExists = YES;
                break;
            }
        }
        [requestQueueInstances release];
    }

    return queueExists;
}

- (id)init
{
    if ((self = [super init])) {
        _requests = [[NSMutableArray alloc] init];
        _loadingRequests = [[NSMutableSet alloc] init];
        _suspended = YES;
        _concurrentRequestsLimit = 5;
        _requestTimeout = 300;
        _showsNetworkActivityIndicatorWhenBusy = NO;

#if TARGET_OS_IPHONE
        BOOL backgroundOK = &UIApplicationDidEnterBackgroundNotification != NULL;
        if (backgroundOK) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(willTransitionToBackground)
                                                         name:UIApplicationDidEnterBackgroundNotification
                                                       object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(willTransitionToForeground)
                                                         name:UIApplicationWillEnterForegroundNotification
                                                       object:nil];
        }
#endif
    }
    return self;
}

- (void)removeFromNamedQueues
{
    if (self.name) {
        for (NSValue *value in RKRequestQueueInstances) {
            RKRequestQueue *queue = (RKRequestQueue *)[value nonretainedObjectValue];
            if ([queue.name isEqualToString:self.name]) {
                [RKRequestQueueInstances removeObject:value];
                return;
            }
        }
    }
}

- (void)dealloc
{
    RKLogDebug(@"Queue instance is being deallocated: %@", self);
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [self removeFromNamedQueues];

    [_queueTimer invalidate];
    [_loadingRequests release];
    _loadingRequests = nil;
    [_requests release];
    _requests = nil;

    [super dealloc];
}

- (NSUInteger)count
{
    return [_requests count];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p name=%@ suspended=%@ requestCount=%d loadingCount=%d/%d>",
            NSStringFromClass([self class]), self, self.name, self.suspended ? @"YES" : @"NO",
            self.count, self.loadingCount, self.concurrentRequestsLimit];
}

- (NSUInteger)loadingCount
{
    return [_loadingRequests count];
}

- (void)addLoadingRequest:(RKRequest *)request
{
    if (self.loadingCount == 0) {
        RKLogTrace(@"Loading count increasing from 0 to 1. Firing requestQueueDidBeginLoading");

        // Transitioning from empty to processing
        if ([_delegate respondsToSelector:@selector(requestQueueDidBeginLoading:)]) {
            [_delegate requestQueueDidBeginLoading:self];
        }

#if TARGET_OS_IPHONE
        if (self.showsNetworkActivityIndicatorWhenBusy) {
            [[UIApplication sharedApplication] pushNetworkActivity];
        }
#endif
    }
    @synchronized(self) {
        [_loadingRequests addObject:request];
    }
    RKLogTrace(@"Loading count now %ld for queue %@", (long)self.loadingCount, self);
}

- (void)removeLoadingRequest:(RKRequest *)request
{
    if (self.loadingCount == 1 && [_loadingRequests containsObject:request]) {
        RKLogTrace(@"Loading count decreasing from 1 to 0. Firing requestQueueDidFinishLoading");

        // Transition from processing to empty
        if ([_delegate respondsToSelector:@selector(requestQueueDidFinishLoading:)]) {
            [_delegate requestQueueDidFinishLoading:self];
        }

#if TARGET_OS_IPHONE
        if (self.showsNetworkActivityIndicatorWhenBusy) {
            [[UIApplication sharedApplication] popNetworkActivity];
        }
#endif
    }
    @synchronized(self) {
        [_loadingRequests removeObject:request];
    }
    RKLogTrace(@"Loading count now %ld for queue %@", (long)self.loadingCount, self);
}

- (void)loadNextInQueueDelayed
{
    if (!_queueTimer) {
        _queueTimer = [NSTimer scheduledTimerWithTimeInterval:kFlushDelay
                                                       target:self
                                                     selector:@selector(loadNextInQueue)
                                                     userInfo:nil
                                                      repeats:NO];
        RKLogTrace(@"Timer initialized with delay %f for queue %@", kFlushDelay, self);
    }
}

- (RKRequest *)nextRequest
{
    for (NSUInteger i = 0; i < [_requests count]; i++) {
        RKRequest *request = [_requests objectAtIndex:i];
        if ([request isUnsent]) {
            return request;
        }
    }

    return nil;
}

- (void)loadNextInQueue
{
    // We always want to dispatch requests from the main thread so the current thread does not terminate
    // and cause us to lose the delegate callbacks
    if (! [NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(loadNextInQueue) withObject:nil waitUntilDone:NO];
        return;
    }

    // Make sure that the Request Queue does not fire off any requests until the Reachability state has been determined.
    if (self.suspended) {
        _queueTimer = nil;
        [self loadNextInQueueDelayed];

        RKLogTrace(@"Deferring request loading for queue %@ due to suspension", self);
        return;
    }

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    _queueTimer = nil;

    @synchronized(self) {
        RKRequest *request = [self nextRequest];
        while (request && self.loadingCount < _concurrentRequestsLimit) {
            RKLogTrace(@"Processing request %@ in queue %@", request, self);
            if ([_delegate respondsToSelector:@selector(requestQueue:willSendRequest:)]) {
                [_delegate requestQueue:self willSendRequest:request];
            }

            [self addLoadingRequest:request];
            RKLogDebug(@"Sent request %@ from queue %@. Loading count = %ld of %ld", request, self, (long)self.loadingCount, (long)_concurrentRequestsLimit);
            [request sendAsynchronously];

            if ([_delegate respondsToSelector:@selector(requestQueue:didSendRequest:)]) {
                [_delegate requestQueue:self didSendRequest:request];
            }

            request = [self nextRequest];
        }
    }

    if (_requests.count && !_suspended) {
        [self loadNextInQueueDelayed];
    }

    [pool drain];
}

- (void)setSuspended:(BOOL)isSuspended
{
    if (_suspended != isSuspended) {
        if (isSuspended) {
            RKLogDebug(@"Queue %@ has been suspended", self);

            // Becoming suspended
            if ([_delegate respondsToSelector:@selector(requestQueueWasSuspended:)]) {
                [_delegate requestQueueWasSuspended:self];
            }
        } else {
            RKLogDebug(@"Queue %@ has been unsuspended", self);

            // Becoming unsupended
            if ([_delegate respondsToSelector:@selector(requestQueueWasUnsuspended:)]) {
                [_delegate requestQueueWasUnsuspended:self];
            }
        }
    }

    _suspended = isSuspended;

    if (!_suspended) {
        [self loadNextInQueue];
    } else if (_queueTimer) {
        [_queueTimer invalidate];
        _queueTimer = nil;
    }
}

- (void)addRequest:(RKRequest *)request
{
    RKLogTrace(@"Request %@ added to queue %@", request, self);
    NSAssert(![self containsRequest:request], @"Attempting to add the same request multiple times");

    @synchronized(self) {
        [_requests addObject:request];
        request.queue = self;
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(processRequestDidFinishLoadingNotification:)
                                                 name:RKRequestDidFinishLoadingNotification
                                               object:request];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(processRequestDidLoadResponseNotification:)
                                                 name:RKRequestDidLoadResponseNotification
                                               object:request];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(processRequestDidFailWithErrorNotification:)
                                                 name:RKRequestDidFailWithErrorNotification
                                               object:request];

    [self loadNextInQueue];
}

- (BOOL)removeRequest:(RKRequest *)request
{
    if ([self containsRequest:request]) {
        RKLogTrace(@"Removing request %@ from queue %@", request, self);
        @synchronized(self) {
            [self removeLoadingRequest:request];
            [_requests removeObject:request];
            request.queue = nil;
        }

        [[NSNotificationCenter defaultCenter] removeObserver:self name:RKRequestDidLoadResponseNotification object:request];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:RKRequestDidFailWithErrorNotification object:request];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:RKRequestDidFinishLoadingNotification object:request];

        return YES;
    }

    RKLogWarning(@"Failed to remove request %@ from queue %@: it is not in the queue.", request, self);
    return NO;
}

- (BOOL)containsRequest:(RKRequest *)request
{
    @synchronized(self) {
        return [_requests containsObject:request];
    }
}

- (void)cancelRequest:(RKRequest *)request loadNext:(BOOL)loadNext
{
    if ([request isUnsent]) {
        RKLogDebug(@"Cancelled undispatched request %@ and removed from queue %@", request, self);

        [self removeRequest:request];
        request.delegate = nil;

        if ([_delegate respondsToSelector:@selector(requestQueue:didCancelRequest:)]) {
            [_delegate requestQueue:self didCancelRequest:request];
        }
    } else if ([self containsRequest:request] && [request isLoading]) {
        RKLogDebug(@"Cancelled loading request %@ and removed from queue %@", request, self);

        [request cancel];
        request.delegate = nil;

        if ([_delegate respondsToSelector:@selector(requestQueue:didCancelRequest:)]) {
            [_delegate requestQueue:self didCancelRequest:request];
        }

        [self removeRequest:request];

        if (loadNext) {
            [self loadNextInQueue];
        }
    }
}

- (void)cancelRequest:(RKRequest *)request
{
    [self cancelRequest:request loadNext:YES];
}

- (void)cancelRequestsWithDelegate:(NSObject<RKRequestDelegate> *)delegate
{
    RKLogDebug(@"Cancelling all request in queue %@ with delegate %p", self, delegate);

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSArray *requestsCopy = [NSArray arrayWithArray:_requests];
    for (RKRequest *request in requestsCopy) {
        if (request.delegate && request.delegate == delegate) {
            [self cancelRequest:request];
        }
    }
    [pool drain];
}

- (void)abortRequestsWithDelegate:(NSObject<RKRequestDelegate> *)delegate
{
    RKLogDebug(@"Aborting all request in queue %@ with delegate %p", self, delegate);

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSArray *requestsCopy = [NSArray arrayWithArray:_requests];
    for (RKRequest *request in requestsCopy) {
        if (request.delegate && request.delegate == delegate) {
            request.delegate = nil;
            [self cancelRequest:request];
        }
    }
    [pool drain];
}

- (void)cancelAllRequests
{
    RKLogDebug(@"Cancelling all request in queue %@", self);

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSArray *requestsCopy = [NSArray arrayWithArray:_requests];
    for (RKRequest *request in requestsCopy) {
        [self cancelRequest:request loadNext:NO];
    }
    [pool drain];
}

- (void)start
{
    RKLogDebug(@"Started queue %@", self);
    [self setSuspended:NO];
}

- (void)processRequestDidLoadResponseNotification:(NSNotification *)notification
{
    NSAssert([notification.object isKindOfClass:[RKRequest class]], @"Notification expected to contain an RKRequest, got a %@", NSStringFromClass([notification.object class]));
    RKLogTrace(@"Received notification: %@", notification);

    RKRequest *request = (RKRequest *)notification.object;
    NSDictionary *userInfo = [notification userInfo];

    // We successfully loaded a response
    RKLogDebug(@"Received response for request %@, removing from queue. (Now loading %ld of %ld)", request, (long)self.loadingCount, (long)_concurrentRequestsLimit);

    RKResponse *response = [userInfo objectForKey:RKRequestDidLoadResponseNotificationUserInfoResponseKey];
    if ([_delegate respondsToSelector:@selector(requestQueue:didLoadResponse:)]) {
        [_delegate requestQueue:self didLoadResponse:response];
    }

    [self removeLoadingRequest:request];
    [self loadNextInQueue];
}

- (void)processRequestDidFailWithErrorNotification:(NSNotification *)notification
{
    NSAssert([notification.object isKindOfClass:[RKRequest class]], @"Notification expected to contain an RKRequest, got a %@", NSStringFromClass([notification.object class]));
    RKLogTrace(@"Received notification: %@", notification);

    RKRequest *request = (RKRequest *)notification.object;
    NSDictionary *userInfo = [notification userInfo];

    // We failed with an error
    NSError *error = nil;
    if (userInfo) {
        error = [userInfo objectForKey:RKRequestDidFailWithErrorNotificationUserInfoErrorKey];
        RKLogDebug(@"Request %@ failed loading in queue %@ with error: %@.(Now loading %ld of %ld)", request, self,
                   [error localizedDescription], (long)self.loadingCount, (long)_concurrentRequestsLimit);
    } else {
        RKLogWarning(@"Received RKRequestDidFailWithErrorNotification without a userInfo, something is amiss...");
    }

    if ([_delegate respondsToSelector:@selector(requestQueue:didFailRequest:withError:)]) {
        [_delegate requestQueue:self didFailRequest:request withError:error];
    }

    [self removeLoadingRequest:request];
    [self loadNextInQueue];
}

/*
 Invoked via observation when a request has loaded a response or failed with an
 error. Remove the completed request from the queue and continue processing
 */
- (void)processRequestDidFinishLoadingNotification:(NSNotification *)notification
{
    NSAssert([notification.object isKindOfClass:[RKRequest class]], @"Notification expected to contain an RKRequest, got a %@", NSStringFromClass([notification.object class]));
    RKLogTrace(@"Received notification: %@", notification);

    RKRequest *request = (RKRequest *)notification.object;
    if ([self containsRequest:request]) {
        [self removeRequest:request];

        // Load the next request
        [self loadNextInQueue];
    } else {
        RKLogWarning(@"Request queue %@ received unexpected lifecycle notification %@ for request %@: Request not found in queue.", [notification name], self, request);
    }
}

#pragma mark - Background Request Support

- (void)willTransitionToBackground
{
    RKLogDebug(@"App is transitioning into background, suspending queue");

    // Suspend the queue so background requests do not trigger additional requests on state changes
    self.suspended = YES;
}

- (void)willTransitionToForeground
{
    RKLogDebug(@"App returned from background, unsuspending queue");

    self.suspended = NO;
}

@end

#if TARGET_OS_IPHONE

@implementation UIApplication (RKNetworkActivity)

static NSInteger networkActivityCount;

- (NSInteger)networkActivityCount
{
    @synchronized(self) {
        return networkActivityCount;
    }
}

- (void)refreshActivityIndicator
{
    if (![NSThread isMainThread]) {
        SEL sel_refresh = @selector(refreshActivityIndicator);
        [self performSelectorOnMainThread:sel_refresh withObject:nil waitUntilDone:NO];
        return;
    }
    BOOL active = (self.networkActivityCount > 0);
    self.networkActivityIndicatorVisible = active;
}

- (void)pushNetworkActivity
{
    @synchronized(self) {
        networkActivityCount++;
    }
    [self refreshActivityIndicator];
}

- (void)popNetworkActivity
{
    @synchronized(self) {
        if (networkActivityCount > 0) {
            networkActivityCount--;
        } else {
            networkActivityCount = 0;
            RKLogError(@"Unbalanced network activity: count already 0.");
        }
    }
    [self refreshActivityIndicator];
}

- (void)resetNetworkActivity
{
    @synchronized(self) {
        networkActivityCount = 0;
    }
    [self refreshActivityIndicator];
}

@end

#endif
