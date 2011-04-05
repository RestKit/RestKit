//
//  RKRequestQueue.m
//  RestKit
//
//  Created by Blake Watters on 12/1/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKRequestQueue.h"
#import "RKResponse.h"
#import "RKNotifications.h"
#import "RKClient.h"

static RKRequestQueue* gSharedQueue = nil;

static const NSTimeInterval kFlushDelay = 0.3;

@implementation RKRequestQueue

@synthesize suspended = _suspended;
@synthesize concurrentRequestsLimit = _concurrentRequestsLimit;
@synthesize requestTimeout = _requestTimeout;
@synthesize delegate = _delegate;

+ (RKRequestQueue*)sharedQueue {
	if (!gSharedQueue) {
		gSharedQueue = [[RKRequestQueue alloc] init];
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
	if (self = [super init]) {
		_requests = [[NSMutableArray alloc] init];
		_suspended = NO;
		_totalLoading = 0;
		_concurrentRequestsLimit = 5;
		_requestTimeout = 300;
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(responseDidLoad:)
													 name:RKResponseReceivedNotification
												   object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(responseDidLoad:)
													 name:RKRequestFailedWithErrorNotification
												   object:nil];
	}
	return self;
}

- (id)initWithDelegate:(NSObject<RKRequestQueueDelegate>*)delegate {
	if (self = [self init]) {
		_delegate = delegate;
	}
	return self;
}

- (void)dealloc {
	[_queueTimer invalidate];
	[_requests release];
	_requests = nil;
	[super dealloc];
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

- (void)dispatchRequest:(RKRequest*)request {
	if ([_delegate respondsToSelector:@selector(requestQueue:willSendRequest:)]) {
		[_delegate requestQueue:self willSendRequest:request];
	}

	[request performSelector:@selector(fireAsynchronousRequest)];

	if ([_delegate respondsToSelector:@selector(requestQueue:didSendRequest:)]) {
		[_delegate requestQueue:self didSendRequest:request];
	}
}

- (void)loadNextInQueue {
	// This makes sure that the Request Queue does not fire off any requests
	// until the Reachability state has been determined.
	// This prevents the request queue from
	if ([[[RKClient sharedClient] baseURLReachabilityObserver] networkStatus] == RKReachabilityIndeterminate) {
		[self loadNextInQueueDelayed];
		return;
	}

	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

	_queueTimer = nil;

	NSArray* requestsCopy = [NSArray arrayWithArray:_requests];
	for (RKRequest* request in requestsCopy) {
		if (![request isLoading] && ![request isLoaded] && _totalLoading < _concurrentRequestsLimit) {
			++_totalLoading;
			[self dispatchRequest:request];
		}
	}

	if ([_requests count] && !_suspended) {
		[self loadNextInQueueDelayed];

	} else if ([_requests count] == 0 &&
			   [_delegate respondsToSelector:@selector(requestQueueDidFinish:)]) {

		[_delegate requestQueueDidFinish:self];
	}

	[pool drain];
}

- (void)setSuspended:(BOOL)isSuspended {
	_suspended = isSuspended;

	if (!_suspended) {
		[self loadNextInQueue];
	} else if (_queueTimer) {
		[_queueTimer invalidate];
		_queueTimer = nil;
	}
}

- (void)addRequest:(RKRequest*)request {
	if ([_requests count] == 0 &&
		[_delegate respondsToSelector:@selector(requestQueueDidStart:)]) {

		[_delegate requestQueueDidStart:self];
	}
	[_requests addObject:request];
	[self loadNextInQueue];
}

- (void)cancelRequest:(RKRequest*)request loadNext:(BOOL)loadNext {
	if ([_requests containsObject:request] && ![request isLoaded]) {
		[request cancel];
		request.delegate = nil;

		[_requests removeObject:request];
		_totalLoading--;

		if ([_delegate respondsToSelector:@selector(requestQueue:didCancelRequest:)]) {
			[_delegate requestQueue:self didCancelRequest:request];
		}

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

/**
 * Invoked via observation when a request has loaded a response. Remove
 * the completed request from the queue and continue processing
 */
- (void)responseDidLoad:(NSNotification*)notification {
	if ([notification object]) {
		// Our RKRequest completed and we're notified with an RKResponse object
		if ([[notification object] isKindOfClass:[RKResponse class]]) {
			RKResponse* response = (RKResponse*)[notification object];
			RKRequest* request = [response request];
			[_requests removeObject:request];
			_totalLoading--;

			if ([_delegate respondsToSelector:@selector(requestQueue:didLoadResponse:)]) {
				[_delegate requestQueue:self didLoadResponse:response];
			}

		// Our RKRequest failed and we're notified with the original RKRequest object
		} else if ([[notification object] isKindOfClass:[RKRequest class]]) {
			RKRequest* request = (RKRequest*)[notification object];
			[_requests removeObject:request];
			_totalLoading--;

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

@end
