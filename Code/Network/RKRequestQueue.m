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
static const NSTimeInterval kTimeout = 300.0;
static const NSInteger kMaxConcurrentLoads = 5;

@implementation RKRequestQueue

@synthesize suspended = _suspended;

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
	if ((self = [super init])) {
		_requests = [[NSMutableArray alloc] init];
		_suspended = NO;
		_totalLoading = 0;
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
	[request performSelector:@selector(fireAsynchronousRequest)];
}

- (void)loadNextInQueue {
	// This makes sure that the Request Queue does not fire off any requests until the Reachability state has been determined.
	// This prevents the request queue from
	if ([[[RKClient sharedClient] baseURLReachabilityObserver] networkStatus] == RKReachabilityIndeterminate) {
		[self loadNextInQueueDelayed];
		return;
	}
	
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

	_queueTimer = nil;

	NSArray* requestsCopy = [NSArray arrayWithArray:_requests];
	for (RKRequest* request in requestsCopy) {
		if (![request isLoading] && ![request isLoaded] && _totalLoading < kMaxConcurrentLoads) {
			++_totalLoading;
			[self dispatchRequest:request];
		}
	}

	if (_requests.count && !_suspended) {
		[self loadNextInQueueDelayed];
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

- (void)sendRequest:(RKRequest*)request {
	[_requests addObject:request];
	[self loadNextInQueue];
}

- (void)cancelRequest:(RKRequest*)request loadNext:(BOOL)loadNext {
	if ([_requests containsObject:request] && ![request isLoaded]) {
		[request cancel];
		request.delegate = nil;

		[_requests removeObject:request];
		_totalLoading--;

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
	if (notification.object) {
		// Our RKRequest completed and we're notified with an RKResponse object
		if ([notification.object isKindOfClass:[RKResponse class]]) {
			RKRequest* request = [(RKResponse*)notification.object request];
			[_requests removeObject:request];
			_totalLoading--;

		// Our RKRequest failed and we're notified with the original RKRequest object
		} else if ([notification.object isKindOfClass:[RKRequest class]]) {
			RKRequest* request = (RKRequest*)notification.object;
			[_requests removeObject:request];
			_totalLoading--;
		}

		[self loadNextInQueue];
	}
}

@end
