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
    NSObject<RKRequestQueueDelegate>* _delegate;
	NSInteger _totalLoading;
    NSInteger _concurrentRequestsLimit;
	NSTimer*  _queueTimer;
	BOOL _suspended;
}

/**
 * The delegate to inform when the request queue state machine changes
 *
 * If the object implements the RKRequestQueueDelegate protocol,
 * it will receive request lifecycle event messages.
 */
@property(nonatomic, assign) NSObject<RKRequestQueueDelegate>* delegate;

/**
 * The number of current requests supported by this queue
 */
@property (nonatomic) NSInteger concurrentRequestsLimit;

/**
 * Gets the flag that determines if new load requests are allowed to reach the network.
 *
 * Because network requests tend to slow down performance, this property can be used to
 * temporarily delay them.  All requests made while suspended are queued, and when
 * suspended becomes false again they are executed.
 */
@property (nonatomic) BOOL suspended;

/**
 * Return the global queue
 */
+ (RKRequestQueue*)sharedQueue;

/**
 * Set the global queue
 */
+ (void)setSharedQueue:(RKRequestQueue*)requestQueue;

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

/**
 * Start checking for and processing requests
 */
- (void)start;

@end

/**
 * Lifecycle events for RKRequestQueue
 *
 */
@protocol RKRequestQueueDelegate
@optional

/**
 * Sent when queue starts running
 */
- (void)requestQueueDidStart:(RKRequestQueue*)queue;

/**
 * Sent when queue is emptied
 */
- (void)requestQueueDidFinish:(RKRequestQueue*)queue;

/**
 * Sent before queue sends a request
 */
- (void)requestQueue:(RKRequestQueue*)queue willSendRequest:(RKRequest*)request;

/**
 * Sent after queue has sent a request
 */
- (void)requestQueue:(RKRequestQueue*)queue didSendRequest:(RKRequest*)request;

/**
 * Sent when queue received a response for a request
 */
- (void)requestQueue:(RKRequestQueue*)queue didLoadResponse:(RKResponse*)response;

/**
 * Sent when queue has canceled a request
 */
- (void)requestQueue:(RKRequestQueue*)queue didCancelRequest:(RKRequest*)request;

/**
 * Sent when an attempted request fails
 */
- (void)requestQueue:(RKRequestQueue*)queue didFailRequest:(RKRequest*)request withError:(NSError*)error;

@end
