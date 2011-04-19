//
//  RKRequestQueue.m
//  RestKit
//
//  Created by Blake Watters on 12/1/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#import "RKRequestQueue.h"
#import "RKResponse.h"
#import "RKNotifications.h"
#import "RKClient.h"

static RKRequestQueue* gSharedQueue = nil;

static const NSTimeInterval kFlushDelay = 0.3;

@interface RKRequestQueue (Private)

// Declare the loading count read-write
@property (nonatomic, readwrite) NSUInteger loadingCount;
@end

@implementation RKRequestQueue

@synthesize delegate = _delegate;
@synthesize concurrentRequestsLimit = _concurrentRequestsLimit;
@synthesize requestTimeout = _requestTimeout;
@synthesize suspended = _suspended;
@synthesize loadingCount = _loadingCount;

#if TARGET_OS_IPHONE
@synthesize showsNetworkActivityIndicatorWhenBusy = _showsNetworkActivityIndicatorWhenBusy;
#endif

+ (RKRequestQueue*)sharedQueue {
	if (!gSharedQueue) {
		gSharedQueue = [[RKRequestQueue alloc] init];
		gSharedQueue.suspended = NO;
	}
	return gSharedQueue;
}

+ (void)setSharedQueue:(RKRequestQueue*)requestQueue {
	if (gSharedQueue != requestQueue) {
		[gSharedQueue release];
		gSharedQueue = [requestQueue retain];
	}
}

- (id)init {
	if ((self = [super init])) {
		_requests = [[NSMutableArray alloc] init];
		_suspended = YES;
		_loadingCount = 0;
		_concurrentRequestsLimit = 5;
		_requestTimeout = 300;
        _showsNetworkActivityIndicatorWhenBusy = NO;

		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(responseDidLoad:)
													 name:RKResponseReceivedNotification
												   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(responseDidLoad:)
													 name:RKRequestFailedWithErrorNotification
												   object:nil];
#if TARGET_OS_IPHONE
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(willTransitionToBackground) 
                                                     name:UIApplicationDidEnterBackgroundNotification 
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(willTransitionToForeground)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
#endif
	}
	return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];

	[_queueTimer invalidate];
	[_requests release];
	_requests = nil;

	[super dealloc];
}

- (NSUInteger)count {
    return [_requests count];
}

- (void)setLoadingCount:(NSUInteger)count {
    if (_loadingCount == 0 && count > 0) {
        // Transitioning from empty to processing
        if ([_delegate respondsToSelector:@selector(requestQueueDidBeginLoading:)]) {
            [_delegate requestQueueDidBeginLoading:self];
        }

#if TARGET_OS_IPHONE        
        if (self.showsNetworkActivityIndicatorWhenBusy) {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        }
#endif
    } else if (_loadingCount > 0 && count == 0) {
        // Transition from processing to empty
        if ([_delegate respondsToSelector:@selector(requestQueueDidFinishLoading:)]) {
            [_delegate requestQueueDidFinishLoading:self];
        }
        
#if TARGET_OS_IPHONE
        if (self.showsNetworkActivityIndicatorWhenBusy) {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        }
#endif
    }
    
    _loadingCount = count;
}

- (void)loadNextInQueueDelayed {
	if (!_queueTimer) {
		_queueTimer = [NSTimer scheduledTimerWithTimeInterval:kFlushDelay
													   target:self
													 selector:@selector(loadNextInQueue)
													 userInfo:nil
													  repeats:NO];
	}
}

- (void)loadNextInQueue {
	// This makes sure that the Request Queue does not fire off any requests until the Reachability state has been determined.
	if ([[[RKClient sharedClient] baseURLReachabilityObserver] networkStatus] == RKReachabilityIndeterminate ||
        self.suspended) {
		_queueTimer = nil;
		[self loadNextInQueueDelayed];
		return;
	}

	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	_queueTimer = nil;
	
	NSArray* requestsCopy = [NSArray arrayWithArray:_requests];
	for (RKRequest* request in requestsCopy) {
		if (![request isLoading] && ![request isLoaded] && self.loadingCount < _concurrentRequestsLimit) {            
            if ([_delegate respondsToSelector:@selector(requestQueue:willSendRequest:)]) {
                [_delegate requestQueue:self willSendRequest:request];
            }
            
            self.loadingCount = self.loadingCount + 1;
            [request sendAsynchronously];

            if ([_delegate respondsToSelector:@selector(requestQueue:didSendRequest:)]) {
                [_delegate requestQueue:self didSendRequest:request];
            }
		}
	}
	
	if (_requests.count && !_suspended) {
		[self loadNextInQueueDelayed];
	}

	[pool drain];
}

- (void)setSuspended:(BOOL)isSuspended {    
    if (_suspended != isSuspended) {
        if (isSuspended) {
            // Becoming suspended
            if ([_delegate respondsToSelector:@selector(requestQueueWasSuspended:)]) {
                [_delegate requestQueueWasSuspended:self];
            }
        } else {
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

- (void)addRequest:(RKRequest*)request {
	[_requests addObject:request];
	[self loadNextInQueue];
}

- (BOOL)containsRequest:(RKRequest*)request {
    return [_requests containsObject:request];
}

- (void)cancelRequest:(RKRequest*)request loadNext:(BOOL)loadNext {
	if ([_requests containsObject:request] && ![request isLoaded]) {
		[request cancel];
		request.delegate = nil;
        
    if ([_delegate respondsToSelector:@selector(requestQueue:didCancelRequest:)]) {
        [_delegate requestQueue:self didCancelRequest:request];
    }

		[_requests removeObject:request];
		self.loadingCount = self.loadingCount - 1;
		
		if (loadNext) {
			[self loadNextInQueue];
		}
	}
}

- (void)cancelRequest:(RKRequest*)request {
	[self cancelRequest:request loadNext:YES];
}

- (void)cancelRequestsWithDelegate:(NSObject<RKRequestDelegate>*)delegate {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSArray* requestsCopy = [NSArray arrayWithArray:_requests];
	for (RKRequest* request in requestsCopy) {
		if (request.delegate && request.delegate == delegate) {
			[self cancelRequest:request];
		}
	}
	[pool drain];
}

- (void)cancelAllRequests {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSArray* requestsCopy = [NSArray arrayWithArray:_requests];
	for (RKRequest* request in requestsCopy) {
		[self cancelRequest:request loadNext:NO];
	}
	[pool drain];
}

- (void)start {
    [self setSuspended:NO];
}

/**
 * Invoked via observation when a request has loaded a response. Remove
 * the completed request from the queue and continue processing
 */
- (void)responseDidLoad:(NSNotification*)notification {
	  if (notification.object) {
        
        // Get the RKRequest, so we can check if it is from this RKRequestQueue
        RKRequest *request = nil;
        if ([notification.object isKindOfClass:[RKResponse class]]) {
			      request = [(RKResponse*)notification.object request];
        } else if ([notification.object isKindOfClass:[RKRequest class]]) {
            request = (RKRequest*)notification.object;
        }
        
		// Our RKRequest completed and we're notified with an RKResponse object
        if (request != nil && [self containsRequest:request]) { 
            if ([notification.object isKindOfClass:[RKResponse class]]) {
                [_requests removeObject:request];
                self.loadingCount = self.loadingCount - 1;
                
                if ([_delegate respondsToSelector:@selector(requestQueue:didLoadResponse:)]) {
                    [_delegate requestQueue:self didLoadResponse:(RKResponse*)notification.object];
                }
				
				// Our RKRequest failed and we're notified with the original RKRequest object
            } else if ([notification.object isKindOfClass:[RKRequest class]]) {
                [_requests removeObject:request];
                self.loadingCount = self.loadingCount - 1;
                
                NSDictionary* userInfo = [notification userInfo];
                NSError* error = nil;
                if (userInfo) {
                    error = [userInfo objectForKey:@"error"];
                }
                
                if ([_delegate respondsToSelector:@selector(requestQueue:didFailRequest:withError:)]) {
                    [_delegate requestQueue:self didFailRequest:request withError:error];
                }
            }
			
            [self loadNextInQueue];
        }
	}
}

#pragma mark - Background Request Support

- (void)willTransitionToBackground {
    // Suspend the queue so background requests do not trigger additional requests on state changes
    self.suspended = YES;
}

- (void)willTransitionToForeground {
    self.suspended = NO;
}

@end
