//
//  RKRequestQueue.h
//  RestKit
//
//  Created by Blake Watters on 12/1/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKRequest.h"


@protocol RKRequestQueueDelegate;

/**
 * A lightweight queue implementation responsible
 * for dispatching and managing RKRequest objects
 */
@interface RKRequestQueue : NSObject {
	NSMutableArray* _requests;
	NSUInteger		_totalLoading;
	NSTimer*		_queueTimer;
	BOOL			_suspended;
	NSUInteger		_concurrentRequestsLimit;
	NSUInteger		_requestTimeout;
	NSObject<RKRequestQueueDelegate>* _delegate;
}

/**
 * Gets the flag that determines if new load requests are allowed to reach the network.
 *
 * Because network requests tend to slow down performance, this property can be used to
 * temporarily delay them.  All requests made while suspended are queued, and when
 * suspended becomes false again they are executed.
 */
@property (nonatomic) BOOL suspended;

/**
 * Maximum concurrent loads allowed by the queue
 * Defaults to 5
 */
@property (nonatomic, assign) NSUInteger concurrentRequestsLimit;

/**
 * Request timeout value used by the queue
 * Defaults to 5 minutes (300 seconds)
 */
@property (nonatomic, assign) NSUInteger requestTimeout;

/**
 * The delegate to inform about various queue and request lifecycle
 * events
 *
 */
@property(nonatomic, assign) NSObject<RKRequestQueueDelegate>* delegate;

/**
 * Return the global queue
 */
+ (RKRequestQueue*)sharedQueue;

/**
 * Set the global queue
 */
+ (void)setSharedQueue:(RKRequestQueue*)requestQueue;

/**
 * Initialize an RKRequestQueue with the supplied delegate
 */
- (id)initWithDelegate:(NSObject<RKRequestQueueDelegate>*)delegate;

/**
 * Add an asynchronous request to the queue and send it as
 * as soon as possible
 */
- (void)addRequest:(RKRequest*)request;

/**
 * Cancel a request that is in progress
 */
- (void)cancelRequest:(RKRequest*)request;

/**
 * Cancel all requests with a given delegate
 */
- (void)cancelRequestsWithDelegate:(NSObject<RKRequestDelegate>*)delegate;

/**
 * Cancel all active or pending requests.
 */
- (void)cancelAllRequests;

@end

/**
 * Lifecycle events for RKRequestQueue implementations
 *
 */
@protocol RKRequestQueueDelegate
@optional

/**
 * Sent when the queue starts running
 */
- (void)requestQueueDidStart:(RKRequestQueue*)queue;

/**
 * Sent when the queue is emptied
 */
- (void)requestQueueDidFinish:(RKRequestQueue*)queue;

/**
 * Sent before the queue sends a request
 */
- (void)requestQueue:(RKRequestQueue*)queue willSendRequest:(RKRequest*)request;

/**
 * Sent after the queue sends a request
 */
- (void)requestQueue:(RKRequestQueue*)queue didSendRequest:(RKRequest*)request;

/**
 * Sent when the queue receives a response for a previously sent request
 */
- (void)requestQueue:(RKRequestQueue*)queue didLoadResponse:(RKResponse*)response;

/**
 * Sent when the queue cancels a request
 */
- (void)requestQueue:(RKRequestQueue*)queue didCancelRequest:(RKRequest*)request;

/**
 * Sent when the queue receives a failure for a previously sent request
 */
- (void)requestQueue:(RKRequestQueue*)queue didFailRequest:(RKRequest*)request withError:(NSError*)error;

@end
