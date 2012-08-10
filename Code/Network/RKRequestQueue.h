//
//  RKRequestQueue.h
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

#import <Foundation/Foundation.h>
#import "RKRequest.h"

@protocol RKRequestQueueDelegate;

/**
 A lightweight queue implementation responsible for dispatching and managing
 RKRequest objects.
 */
@interface RKRequestQueue : NSObject {
    NSMutableArray *_requests;
    NSMutableSet *_loadingRequests;
    NSTimer *_queueTimer;
    BOOL _showsNetworkActivityIndicatorWhenBusy;
}


///-----------------------------------------------------------------------------
/// @name Creating a Request Queue
///-----------------------------------------------------------------------------

/**
 Creates and returns a new request queue.

 @return An autoreleased RKRequestQueue object.
 */
+ (id)requestQueue;

/**
 Returns a new retained request queue with the given name. If there is already
 an existing queue with the given name, nil will be returned.

 @param name A symbolic name for the queue.
 @return A new retained RKRequestQueue with the given name or nil if one already
 exists with the given name.
 */
+ (id)newRequestQueueWithName:(NSString *)name;


///-----------------------------------------------------------------------------
/// @name Retrieving an Existing Queue
///-----------------------------------------------------------------------------

/**
 Returns queue with the specified name. If no queue is found with the name
 provided, a new queue will be initialized and returned.

 @param name A symbolic name for the queue.
 @return An existing RKRequestQueue with the given name or a new queue if none
 currently exist.
 */
+ (id)requestQueueWithName:(NSString *)name;

///-----------------------------------------------------------------------------
/// @name Naming Queues
///-----------------------------------------------------------------------------

/**
 A symbolic name for the queue.

 Used to return existing queue references via
 [RKRequestQueue requestQueueWithName:]
 */
@property (nonatomic, retain, readonly) NSString *name;

/**
 Determine if a queue exists with a given name.

 @param name The queue name to search against.
 @return YES when there is a queue with the given name.
 */
+ (BOOL)requestQueueExistsWithName:(NSString *)name;


///-----------------------------------------------------------------------------
/// @name Monitoring State Changes
///-----------------------------------------------------------------------------

/**
 The delegate to inform when the request queue state machine changes.

 If the object implements the RKRequestQueueDelegate protocol, it will receive
 request lifecycle event messages.
 */
@property (nonatomic, assign) id<RKRequestQueueDelegate> delegate;


///-----------------------------------------------------------------------------
/// @name Managing the Queue
///-----------------------------------------------------------------------------

/**
 The number of concurrent requests supported by this queue.

 **Default**: 5 concurrent requests
 */
@property (nonatomic) NSUInteger concurrentRequestsLimit;

/**
 Request timeout value used by the queue.

 **Default**: 5 minutes (300 seconds)
 */
@property (nonatomic, assign) NSUInteger requestTimeout;

/**
 Returns the total number of requests in the queue.
 */
@property (nonatomic, readonly) NSUInteger count;

/**
 Add an asynchronous request to the queue and send it as as soon as possible.

 @param request The request to be added to the queue.
 */
- (void)addRequest:(RKRequest *)request;

/**
 Cancel a request that is in progress.

 @param request The request to be cancelled.
 */
- (void)cancelRequest:(RKRequest *)request;

/**
 Cancel all requests with a given delegate.

 @param delegate The delegate assigned to the requests to be cancelled.
 */
- (void)cancelRequestsWithDelegate:(id<RKRequestDelegate>)delegate;

/**
 Aborts all requests with a given delegate by nullifying the delegate
 reference and canceling the request.

 Useful when an object that acts as the delegate for one or more requests
 is being deallocated and all outstanding requests should be cancelled
 without generating any further delegate callbacks.

 @param delegate The object acting as the delegate for all enqueued requests that are to be aborted.
 */
- (void)abortRequestsWithDelegate:(id<RKRequestDelegate>)delegate;

/**
 Cancel all active or pending requests.
 */
- (void)cancelAllRequests;

/**
 Determine if a given request is currently in this queue.

 @param request The request to check the queue for.
 @return YES if the specified request is in this queue.
 */
- (BOOL)containsRequest:(RKRequest *)request;


///-----------------------------------------------------------------------------
/// @name Processing Queued Requests
///-----------------------------------------------------------------------------

/**
 Start checking for and processing requests.
 */
- (void)start;

/**
 Sets the flag that determines if new load requests are allowed to reach the
 network.

 Because network requests tend to slow down performance, this property can be
 used to temporarily delay them.  All requests made while suspended are queued,
 and when suspended becomes false again they are executed.
 */
@property (nonatomic) BOOL suspended;

/**
 Returns the total number of requests that are currently loading.
 */
@property (nonatomic, readonly) NSUInteger loadingCount;

#if TARGET_OS_IPHONE
/**
 Sets the flag for showing the network activity indicatory.

 When YES, this queue will spin the network activity in the menu bar when it is
 processing requests.

 **Default**: NO
 */
@property (nonatomic) BOOL showsNetworkActivityIndicatorWhenBusy;
#endif


///-----------------------------------------------------------------------------
/// @name Global Queues (Deprecated)
///-----------------------------------------------------------------------------

/**
 Returns the global queue

 @bug **DEPRECATED** in v0.10.0: All RKClient instances now own their own
 individual request queues.

 @see [RKClient requestQueue]
 @return Global request queue.
 */
+ (RKRequestQueue *)sharedQueue DEPRECATED_ATTRIBUTE;

/**
 Sets the global queue

 @bug **DEPRECATED** in v0.10.0: All RKClient instances now own their own
 individual request queues.

 @see [RKClient requestQueue]
 @param requestQueue The request queue to assign as the global queue.
 */
+ (void)setSharedQueue:(RKRequestQueue *)requestQueue DEPRECATED_ATTRIBUTE;

@end


/**
 Lifecycle events for an RKRequestQueue
 */
@protocol RKRequestQueueDelegate <NSObject>
@optional

///-----------------------------------------------------------------------------
/// @name Starting and Stopping the Queue
///-----------------------------------------------------------------------------

/**
 Sent when the queue transitions from an empty state to processing requests.

 @param queue The queue that began processing requests.
 */
- (void)requestQueueDidBeginLoading:(RKRequestQueue *)queue;

/**
 Sent when queue transitions from a processing state to an empty start.

 @param queue The queue that finished processing requests.
 */
- (void)requestQueueDidFinishLoading:(RKRequestQueue *)queue;

/**
 Sent when the queue has been suspended and request processing has been halted.

 @param queue The request queue that has been suspended.
 */
- (void)requestQueueWasSuspended:(RKRequestQueue *)queue;

/**
 Sent when the queue has been unsuspended and request processing has resumed.

 @param queue The request queue that has resumed processing.
 */
- (void)requestQueueWasUnsuspended:(RKRequestQueue *)queue;


///-----------------------------------------------------------------------------
/// @name Processing Requests
///-----------------------------------------------------------------------------

/**
 Sent before queue sends a request.

 @param queue The queue that will process the request.
 @param request The request to be processed.
 */
- (void)requestQueue:(RKRequestQueue *)queue willSendRequest:(RKRequest *)request;

/**
 Sent after queue has sent a request.

 @param queue The queue that processed the request.
 @param request The processed request.
 */
- (void)requestQueue:(RKRequestQueue *)queue didSendRequest:(RKRequest *)request;

/**
 Sent when queue received a response for a request.

 @param queue The queue that received the response.
 @param response The response that was received.
 */
- (void)requestQueue:(RKRequestQueue *)queue didLoadResponse:(RKResponse *)response;

/**
 Sent when queue has cancelled a request.

 @param queue The queue that cancelled the request.
 @param request The cancelled request.
 */
- (void)requestQueue:(RKRequestQueue *)queue didCancelRequest:(RKRequest *)request;

/**
 Sent when an attempted request fails.

 @param queue The queue in which the request failed from.
 @param request The failed request.
 @param error An NSError object containing the RKRestKitError that caused the
 request to fail.
 */
- (void)requestQueue:(RKRequestQueue *)queue didFailRequest:(RKRequest *)request withError:(NSError *)error;

@end

#if TARGET_OS_IPHONE
/**
 A category on UIApplication to allow for jointly managing the network activity
 indicator.

 Adopted from 'iOS Recipes' book: http://pragprog.com/book/cdirec/ios-recipes
 */
@interface UIApplication (RKNetworkActivity)

/**
 Returns the number of network activity requests.
 */
@property (nonatomic, assign, readonly) NSInteger networkActivityCount;

/**
 Push a network activity request onto the stack.
 */
- (void)pushNetworkActivity;

/**
 Pop a network activity request off the stack.
 */
- (void)popNetworkActivity;

/**
 Reset the network activity stack.
 */
- (void)resetNetworkActivity;

@end
#endif
