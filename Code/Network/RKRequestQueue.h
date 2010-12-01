//
//  RKRequestQueue.h
//  RestKit
//
//  Created by Blake Watters on 12/1/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RKRequest.h"

/**
 * A lightweight queue implementation responsible
 * for dispatching and managing RKRequest objects
 */
@interface RKRequestQueue : NSObject {
	NSMutableArray* _requests;
	NSInteger		_totalLoading;
	NSTimer*        _queueTimer;
	BOOL			_suspended;
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
- (void)sendRequest:(RKRequest*)request;

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
