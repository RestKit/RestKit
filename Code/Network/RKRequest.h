//
//  RKRequest.h
//  RestKit
//
//  Created by Jeremy Ellison on 7/27/09.
//  Copyright 2009 Two Toasters
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

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "RKRequestSerializable.h"

@class RKRequestCache;

/**
 * HTTP methods for requests
 */
typedef enum RKRequestMethod {
    RKRequestMethodGET = 0,
    RKRequestMethodPOST,
    RKRequestMethodPUT,
    RKRequestMethodDELETE,
    RKRequestMethodHEAD
} RKRequestMethod;

/**
 * Cache policy for determining how to use RKCache
 */
typedef enum {
	// Never use the cache
    RKRequestCachePolicyNone = 0,

	// Load from the cache when we are offline
    RKRequestCachePolicyLoadIfOffline = 1 << 0,

	// Load from the cache if we encounter an error
    RKRequestCachePolicyLoadOnError = 1 << 1,

	// Load from the cache if we have data stored and the server returns a 304 (not modified) response
    RKRequestCachePolicyEtag = 1 << 2,
    
    // Load from the cache if we have data stored
    RKRequestCachePolicyEnabled = 1 << 3,
    
    // Load from the cache if we are within the timeout window
    RKRequestCachePolicyTimeout = 1 << 4,

    RKRequestCachePolicyDefault = RKRequestCachePolicyEtag | RKRequestCachePolicyTimeout
} RKRequestCachePolicy;

/**
 * Background Request Policy
 *
 * On iOS 4.x and higher, UIKit provides
 * support for continueing activities for a limited amount
 * of time in the background. RestKit provides simple
 * support for continuing a request when in the background.
 */
#if TARGET_OS_IPHONE
typedef enum RKRequestBackgroundPolicy {
    RKRequestBackgroundPolicyNone = 0,      // Take no action with regards to backgrounding
    RKRequestBackgroundPolicyCancel,        // Cancel the request on transition to the background
    RKRequestBackgroundPolicyContinue,      // Continue the request in the background until time expires
    RKRequestBackgroundPolicyRequeue        // Stop the request and place it back on the queue. It will fire when the app reopens
} RKRequestBackgroundPolicy;
#endif

typedef enum {
    RKRequestAuthenticationTypeNone = 0,     // Disable the use of authentication
    RKRequestAuthenticationTypeHTTP,         // Use NSURLConnection's HTTP AUTH auto-negotiation
    RKRequestAuthenticationTypeHTTPBasic,    // Force the use of HTTP Basic authentication. This will supress AUTH challenges
    RKRequestAuthenticationTypeOAuth1,       // Enable the use of OAuth 1.0 authentication
    RKRequestAuthenticationTypeOAuth2        // Enable the use of OAuth 2.0 authentication
} RKRequestAuthenticationType;

@class RKResponse, RKRequestQueue, RKReachabilityObserver;
@protocol RKRequestDelegate;

/**
 Models the request portion of an HTTP request/response cycle.
 */
@interface RKRequest : NSObject {
	NSURL *_URL;
	NSMutableURLRequest *_URLRequest;
	NSURLConnection *_connection;
	NSDictionary *_additionalHTTPHeaders;
	NSObject<RKRequestSerializable> *_params;
	NSObject<RKRequestDelegate> *_delegate;
	id _userData;
    RKRequestAuthenticationType _authenticationType;
	NSString *_username;
	NSString *_password;
    NSString *_OAuth1ConsumerKey;
    NSString *_OAuth1ConsumerSecret;
    NSString *_OAuth1AccessToken;
    NSString *_OAuth1AccessTokenSecret;
    NSString *_OAuth2AccessToken;
    NSString *_OAuth2RefreshToken;
	RKRequestMethod _method;
	BOOL _isLoading;
	BOOL _isLoaded;
	RKRequestCachePolicy _cachePolicy;
    BOOL _sentSynchronously;
    RKRequestCache *_cache;
    NSTimeInterval _cacheTimeoutInterval;
    RKRequestQueue *_queue;
    RKReachabilityObserver *_reachabilityObserver;
    
    #if TARGET_OS_IPHONE
    RKRequestBackgroundPolicy _backgroundPolicy;
    UIBackgroundTaskIdentifier _backgroundTaskIdentifier;
    #endif
}

/**
 * The URL this request is loading
 */
@property(nonatomic, retain) NSURL *URL;

/**
 * The resourcePath portion of this loader's URL
 */
@property (nonatomic, retain) NSString *resourcePath;

/**
 * The HTTP verb the request is sent via
 *
 * @default RKRequestMethodGET
 */
@property(nonatomic, assign) RKRequestMethod method;

/**
 * A serializable collection of parameters sent as the HTTP Body of the request
 */
@property(nonatomic, retain) NSObject<RKRequestSerializable> *params;

/**
 * The delegate to inform when the request is completed
 *
 * If the object implements the RKRequestDelegate protocol,
 * it will receive request lifecycle event messages.
 */
@property(nonatomic, assign) NSObject<RKRequestDelegate> *delegate;

/**
 * A Dictionary of additional HTTP Headers to send with the request
 */
@property(nonatomic, retain) NSDictionary *additionalHTTPHeaders;

/**
 * An opaque pointer to associate user defined data with the request.
 */
@property(nonatomic, retain) id userData;

/**
 * The underlying NSMutableURLRequest sent for this request
 */
@property(nonatomic, readonly) NSMutableURLRequest *URLRequest;

/**
 * The HTTP method as a string used for this request
 */
@property(nonatomic, readonly) NSString *HTTPMethod;

/**
 The request queue that this request belongs to
 */
@property (nonatomic, assign) RKRequestQueue *queue;

/**
 * The policy to take on transition to the background (iOS 4.x and higher only)
 *
 * Default: RKRequestBackgroundPolicyCancel
 */
#if TARGET_OS_IPHONE
@property(nonatomic, assign) RKRequestBackgroundPolicy backgroundPolicy;
@property(nonatomic, readonly) UIBackgroundTaskIdentifier backgroundTaskIdentifier;
#endif

/**
 The reachability observer to consult for network status. Used for performing
 offline cache loads.
 
 Generally configured by the RKClient instance that minted this request
 */
@property (nonatomic, assign) RKReachabilityObserver *reachabilityObserver;

/////////////////////////////////////////////////////////////////////////
/// @name Authentication
/////////////////////////////////////////////////////////////////////////

/**
 The type of authentication to use for this request.
 
 When configured to RKRequestAuthenticationTypeHTTPBasic, RestKit will add
 an Authorization header establishing login via HTTP Basic. This is an optimization
 that skips the challenge portion of the request.
 
 **Default**: RKRequestAuthenticationTypeNone
 
 @see RKRequestAuthenticationType
 */
@property (nonatomic, assign) RKRequestAuthenticationType authenticationType;

/**
 The username to use for an HTTP Authentication
 */
@property(nonatomic, retain) NSString *username;

/**
 The password to use for an HTTP Authentication
 */
@property(nonatomic, retain) NSString *password;

/*** @name OAuth Secrets */

/**
 The OAuth 1.0 consumer key
 */
@property(nonatomic,retain) NSString *OAuth1ConsumerKey;

/**
 The OAuth 1.0 consumer secret
 */
@property(nonatomic,retain) NSString *OAuth1ConsumerSecret;

/**
 The OAuth 1.0 access token
 */
@property(nonatomic,retain) NSString *OAuth1AccessToken;

/**
 The OAuth 1.0 access token secret
 */
@property(nonatomic,retain) NSString *OAuth1AccessTokenSecret;

/*** @name OAuth2 Secrets */

/**
 The OAuth 2.0 access token
 */
@property(nonatomic,retain) NSString *OAuth2AccessToken;

/**
 The OAuth 2.0 refresh token. Used to retrieve a new access token before expiration
 */
@property(nonatomic,retain) NSString *OAuth2RefreshToken;

/////////////////////////////////////////////////////////////////////////
/// @name Cacheing
/////////////////////////////////////////////////////////////////////////

/**
 Returns the cache key for getting/setting the cache entry for this request
 in the cache.
 
 The cacheKey is an MD5 value computed by hashing a combination of the destination
 URL, the HTTP verb, and the request body (if possible)
 */
@property (nonatomic, readonly) NSString *cacheKey;

/**
 The cache policy used when storing this request into the request cache
 */
@property (nonatomic, assign) RKRequestCachePolicy cachePolicy;

/**
 The request cache to store and load responses for this request
 
 Generally configured by the RKClient instance that minted this request
 */
@property (nonatomic, retain) RKRequestCache *cache;

/**
 Returns YES if the request is cacheable
 
 All requets are considered cacheable unless:
    1) The method is DELETE
    2) The request body is a stream (i.e. using RKParams)
 */
- (BOOL)isCacheable;

/**
 * The HTTP body as a NSData used for this request
 */ 
@property (nonatomic, retain) NSData *HTTPBody;

/**
 * The HTTP body as a string used for this request
 */
@property (nonatomic, retain) NSString *HTTPBodyString;

/**
 * The timeout interval within which the request should not be sent
 * and the cached response should be used. Used if the cache policy
 * includes RKRequestCachePolicyTimeout
 */
@property (nonatomic, assign) NSTimeInterval cacheTimeoutInterval;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

/**
 * Return a REST request that is ready for dispatching
 */
+ (RKRequest *)requestWithURL:(NSURL *)URL delegate:(id)delegate;

/**
 * Initialize a synchronous request
 */
- (id)initWithURL:(NSURL *)URL;

/**
 * Initialize a REST request and prepare it for dispatching
 */
- (id)initWithURL:(NSURL *)URL delegate:(id)delegate;

/**
 * Setup the NSURLRequest. The request must be prepared right before dispatching
 */
- (BOOL)prepareURLRequest;

/**
 * Resets the state of an RKRequest so that it can be re-sent.
 */
- (void)reset;

/**
 * Send the request asynchronously. It will be added to the queue and
 * dispatched as soon as possible.
 */
- (void)send;

/**
 * Immediately dispatch a request asynchronously, skipping the request queue
 */
- (void)sendAsynchronously;

/**
 * Send the request synchronously and return a hydrated response object
 */
- (RKResponse *)sendSynchronously;

/**
 * Callback performed to notify the request that the underlying NSURLConnection
 * has failed with an error.
 */
- (void)didFailLoadWithError:(NSError *)error;

/**
 * Callback performed to notify the request that the underlying NSURLConnection
 * has completed with a response.
 */
- (void)didFinishLoad:(RKResponse *)response;

/**
 * Cancels the underlying URL connection.
 * This will call the requestDidCancel: delegate method
 * if your delegate responds to it. This does not subsequently
 * set the the request's delegate to nil. However, it's good
 * practice to cancel the RKRequest and immediately set the
 * delegate property to nil within the delegate's dealloc method.
 * @see NSURLConnection:cancel
 */
- (void)cancel;

/**
 * Returns YES when this is a GET request
 */
- (BOOL)isGET;

/**
 * Returns YES when this is a POST request
 */
- (BOOL)isPOST;

/**
 * Returns YES when this is a PUT request
 */
- (BOOL)isPUT;

/**
 * Returns YES when this is a DELETE request
 */
- (BOOL)isDELETE;

/**
 * Returns YES when this is a HEAD request
 */
- (BOOL)isHEAD;

/**
 * Returns YES when this request is in-progress
 */
- (BOOL)isLoading;

/**
 * Returns YES when this request has been completed
 */
- (BOOL)isLoaded;

/**
 * Returnes YES when this request has not yet been sent
 */
- (BOOL)isUnsent;

/**
 * Returns YES when the request was sent to the specified resource path
 */
- (BOOL)wasSentToResourcePath:(NSString *)resourcePath;

@end

/**
 * Lifecycle events for RKRequests
 */
@protocol RKRequestDelegate <NSObject>
@optional

/**
 * Sent when a request has finished loading
 */
- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response;

/**
 * Sent when a request has failed due to an error
 */
- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error;

/**
 * Sent when a request has started loading
 */
- (void)requestDidStartLoad:(RKRequest *)request;

/**
 * Sent when a request has uploaded data to the remote site
 */
- (void)request:(RKRequest *)request didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite;

/**
 * Sent when request has received data from remote site
 */
- (void)request:(RKRequest*)request didReceivedData:(NSInteger)bytesReceived totalBytesReceived:(NSInteger)totalBytesReceived totalBytesExectedToReceive:(NSInteger)totalBytesExpectedToReceive;

/**
 * Sent to the delegate when a request was cancelled
 */
- (void)requestDidCancelLoad:(RKRequest *)request;

/**
 * Sent to the delegate when a request has timed out. This is sent when a
 * backgrounded request expired before completion.
 */
- (void)requestDidTimeout:(RKRequest *)request;

/**
 * Sent when a request fails authentication
 */
- (void)request:(RKRequest *)request didFailAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;

@end
