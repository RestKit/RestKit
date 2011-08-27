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
	NSUInteger _loadingCount;
    NSUInteger _concurrentRequestsLimit;
	NSUInteger _requestTimeout;
	NSTimer*  _queueTimer;
	BOOL _suspended;
    BOOL _showsNetworkActivityIndicatorWhenBusy;
}

/**
 A symbolic name for the queue. Used to return existing queue references
 via [RKRequestQueue queueWithName:]
 */
@property (nonatomic, retain, readonly) NSString* name;

/**
 * The delegate to inform when the request queue state machine changes
 *
 * If the object implements the RKRequestQueueDelegate protocol,
 * it will receive request lifecycle event messages.
 */
@property(nonatomic, assign) NSObject<RKRequestQueueDelegate>* delegate;

/**
 * The number of current requests supported by this queue
 * Defaults to 5
 */
@property (nonatomic) NSUInteger concurrentRequestsLimit;

/**
 * Request timeout value used by the queue
 * Defaults to 5 minutes (300 seconds)
 */
@property (nonatomic, assign) NSUInteger requestTimeout;

/**
 * Gets the flag that determines if new load requests are allowed to reach the network.
 *
 * Because network requests tend to slow down performance, this property can be used to
 * temporarily delay them.  All requests made while suspended are queued, and when
 * suspended becomes false again they are executed.
 */
@property (nonatomic) BOOL suspended;

/**
 * Returns the total number of requests that are currently loading
 */
@property (nonatomic, readonly) NSUInteger loadingCount;

/**
 * Returns the number of requests in the queue
 */
@property (nonatomic, readonly) NSUInteger count;

#if TARGET_OS_IPHONE
/**
 * When YES, this queue will spin the network activity in the menu bar when it is processing
 * requests
 *
 * *Default*: NO
 */
@property (nonatomic) BOOL showsNetworkActivityIndicatorWhenBusy;
#endif

/**
 * Return the global queue
 */
+ (RKRequestQueue*)sharedQueue;

/**
 * Set the global queue
 */
+ (void)setSharedQueue:(RKRequestQueue*)requestQueue;

/**
 Returns a new auto-released request queue
 */
+ (id)requestQueue;

/**
 Returns a new retained request queue with the given name. If there is already
 an existing queue with the given name, nil will be returned.
 */
+ (id)newRequestQueueWithName:(NSString*)name;

/**
 Returns queue with the specified name. If no queue is found with
 the name provided, a new queue will be initialized and returned.
 */
+ (id)requestQueueWithName:(NSString*)name;

/**
 Returns YES when there is a queue with the given name
 */
+ (BOOL)requestQueueExistsWithName:(NSString*)name;

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

/**
 * Returns YES if the specified request is in this queue
 */
- (BOOL)containsRequest:(RKRequest*)request;

@end

/**
 * Lifecycle events for RKRequestQueue
 *
 */
@protocol RKRequestQueueDelegate
@optional

/**
 * Sent when the queue has been suspended and request processing has been halted
 */
- (void)requestQueueWasSuspended:(RKRequestQueue*)queue;

/**
 * Sent when the queue has been unsuspended and request processing has resumed
 */
- (void)requestQueueWasUnsuspended:(RKRequestQueue*)queue;

/**
 * Sent when the queue transitions from an empty state to processing requests
 */
- (void)requestQueueDidBeginLoading:(RKRequestQueue*)queue;

/**
 * Sent when queue transitions from a processing state to an empty start
 */
- (void)requestQueueDidFinishLoading:(RKRequestQueue*)queue;

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

/**
 *  A category on UIApplication to allow for jointly managing of network activity indicator.
 *  Adopted from 'iOS Recipes' book: http://pragprog.com/book/cdirec/ios-recipes
 */

#if TARGET_OS_IPHONE

@interface UIApplication (RKNetworkActivity)

@property (nonatomic, assign, readonly) NSInteger rk_networkActivityCount;

- (void)rk_pushNetworkActivity;
- (void)rk_popNetworkActivity;
- (void)rk_resetNetworkActivity;

@end

#endif