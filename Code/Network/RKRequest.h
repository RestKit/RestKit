//
//  RKRequest.h
//  RestKit
//
//  Created by Jeremy Ellison on 7/27/09.
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

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "RKRequestSerializable.h"

@class RKRequestCache;

/**
 HTTP methods for requests
 */
typedef enum RKRequestMethod {
    RKRequestMethodInvalid = -1,
    RKRequestMethodGET,
    RKRequestMethodPOST,
    RKRequestMethodPUT,
    RKRequestMethodDELETE,
    RKRequestMethodHEAD
} RKRequestMethod;

NSString *RKRequestMethodNameFromType(RKRequestMethod);
RKRequestMethod RKRequestMethodTypeFromName(NSString *);

/**
 Cache policy for determining how to use RKCache
 */
typedef enum {
    /**
     Never use the cache
     */
    RKRequestCachePolicyNone = 0,
    /**
     Load from the cache when we are offline
     */
    RKRequestCachePolicyLoadIfOffline = 1 << 0,
    /**
     Load from the cache if we encounter an error
     */
    RKRequestCachePolicyLoadOnError = 1 << 1,
    /**
     Load from the cache if we have data stored and the server returns a 304
     (not modified) response
     */
    RKRequestCachePolicyEtag = 1 << 2,
    /**
     Load from the cache if we have data stored
     */
    RKRequestCachePolicyEnabled = 1 << 3,
    /**
     Load from the cache if we are within the timeout window
     */
    RKRequestCachePolicyTimeout = 1 << 4,
    /**
     The default cache policy is etag and timeout support
     */
    RKRequestCachePolicyDefault = RKRequestCachePolicyEtag | RKRequestCachePolicyTimeout
} RKRequestCachePolicy;


#if TARGET_OS_IPHONE
/**
 Background Request Policy

 On iOS 4.x and higher, UIKit provides support for continuing activities for a
 limited amount of time in the background. RestKit provides simple support for
 continuing a request when in the background.
 */
typedef enum RKRequestBackgroundPolicy {
    /**
     Take no action with regards to backgrounding
     */
    RKRequestBackgroundPolicyNone = 0,
    /**
     Cancel the request on transition to the background
     */
    RKRequestBackgroundPolicyCancel,
    /**
     Continue the request in the background until time expires
     */
    RKRequestBackgroundPolicyContinue,
    /**
     Stop the request and place it back on the queue. It will fire when the app
     reopens.
     */
    RKRequestBackgroundPolicyRequeue
} RKRequestBackgroundPolicy;
#endif

/**
 Authentication type for the request

 Based on the authentication type that is selected, authentication functionality
 is triggered and other options may be required.
 */
typedef enum {
    /**
     Disable the use of authentication
     */
    RKRequestAuthenticationTypeNone = 0,
    /**
     Use NSURLConnection's HTTP AUTH auto-negotiation
     */
    RKRequestAuthenticationTypeHTTP,
    /**
     Force the use of HTTP Basic authentication.

     This will supress AUTH challenges as RestKit will add an Authorization
     header establishing login via HTTP basic.  This is an optimization that
     skips the challenge portion of the request.
     */
    RKRequestAuthenticationTypeHTTPBasic,
    /**
     Enable the use of OAuth 1.0 authentication.

     OAuth1ConsumerKey, OAuth1ConsumerSecret, OAuth1AccessToken, and
     OAuth1AccessTokenSecret must be set when using this type.
     */
    RKRequestAuthenticationTypeOAuth1,
    /**
     Enable the use of OAuth 2.0 authentication.

     OAuth2AccessToken must be set when using this type.
     */
    RKRequestAuthenticationTypeOAuth2
} RKRequestAuthenticationType;

@class RKRequest, RKResponse, RKRequestQueue, RKReachabilityObserver;
@protocol RKRequestDelegate, RKConfigurationDelegate;

///-----------------------------------------------------------------------------
/// @name Block Declarations
///-----------------------------------------------------------------------------
typedef void(^RKRequestDidLoadResponseBlock)(RKResponse *response);
typedef void(^RKRequestDidFailLoadWithErrorBlock)(NSError *error);

/**
 Models the request portion of an HTTP request/response cycle.
 */
@interface RKRequest : NSObject {
    BOOL _sentSynchronously;
    NSURLConnection *_connection;
    id<RKRequestDelegate> _delegate;
    NSTimer *_timeoutTimer;
    RKRequestCachePolicy _cachePolicy;

    RKRequestDidLoadResponseBlock _onDidLoadResponse;
    RKRequestDidFailLoadWithErrorBlock _onDidFailLoadWithError;
}

///-----------------------------------------------------------------------------
/// @name Creating a Request
///-----------------------------------------------------------------------------

/**
 Creates and returns a RKRequest object initialized to load content from a
 provided URL.

 @param URL The remote URL to load
 @return An autoreleased RKRequest object initialized with URL.
 */
+ (RKRequest *)requestWithURL:(NSURL *)URL;

/**
 Initializes a RKRequest object to load from a provided URL

 @param URL The remote URL to load
 @return An RKRequest object initialized with URL.
 */
- (id)initWithURL:(NSURL *)URL;

/**
 Creates and returns a RKRequest object initialized to load content from a
 provided URL with a specified delegate.

 @bug **DEPRECATED** in v0.10.0: Use [RKRequest requestWithURL:] instead
 @param URL The remote URL to load
 @param delegate The delegate that will handle the response callbacks.
 @return An autoreleased RKRequest object initialized with URL.
 */
+ (RKRequest *)requestWithURL:(NSURL *)URL delegate:(id)delegate DEPRECATED_ATTRIBUTE;

/**
 Initializes a RKRequest object to load from a provided URL

 @bug **DEPRECATED** in v0.10.0: Use [RKRequest initWithURL:] instead
 @param URL The remote URL to load
 @param delegate The delegate that will handle the response callbacks.
 @return An RKRequest object initialized with URL.
 */
- (id)initWithURL:(NSURL *)URL delegate:(id)delegate DEPRECATED_ATTRIBUTE;


///-----------------------------------------------------------------------------
/// @name Setting Properties
///-----------------------------------------------------------------------------

/**
 The URL this request is loading
 */
@property (nonatomic, retain) NSURL *URL;

/**
 The resourcePath portion of the request's URL
 */
@property (nonatomic, retain) NSString *resourcePath;

/**
 The HTTP verb in which the request is sent

 **Default**: RKRequestMethodGET
 */
@property (nonatomic, assign) RKRequestMethod method;

/**
 Returns HTTP method as a string used for this request.

 This should be set through the method property using an RKRequestMethod type.

 @see [RKRequest method]
 */
@property (nonatomic, readonly) NSString *HTTPMethod;

/**
 The response returned when the receiver was sent.
 */
@property (nonatomic, retain, readonly) RKResponse *response;

/**
 A serializable collection of parameters sent as the HTTP body of the request
 */
@property (nonatomic, retain) NSObject<RKRequestSerializable> *params;

/**
 A dictionary of additional HTTP Headers to send with the request
 */
@property (nonatomic, retain) NSDictionary *additionalHTTPHeaders;

/**
 The run loop mode under which the underlying NSURLConnection is performed

 *Default*: NSRunLoopCommonModes
 */
@property (nonatomic, copy) NSString *runLoopMode;

/**
 * An opaque pointer to associate user defined data with the request.
 */
@property (nonatomic, retain) id userData;

/**
 The underlying NSMutableURLRequest sent for this request
 */
@property (nonatomic, readonly) NSMutableURLRequest *URLRequest;

/**
 The default value used to decode HTTP body content when HTTP headers received do not provide information on the content.
 This encoding will be used by the RKResponse when creating the body content
 */
@property (nonatomic, assign) NSStringEncoding defaultHTTPEncoding;

///-----------------------------------------------------------------------------
/// @name Working with the HTTP Body
///-----------------------------------------------------------------------------

/**
 Sets the request body using the provided NSDictionary after passing the
 NSDictionary through serialization using the currently configured parser for
 the provided MIMEType.

 @param body An NSDictionary of key/value pairs to be serialized and sent as
 the HTTP body.
 @param MIMEType The MIMEType for the parser to use for the dictionary.
 */
- (void)setBody:(NSDictionary *)body forMIMEType:(NSString *)MIMEType;

/**
 The HTTP body as a NSData used for this request
 */
@property (nonatomic, retain) NSData *HTTPBody;

/**
 The HTTP body as a string used for this request
 */
@property (nonatomic, retain) NSString *HTTPBodyString;


///-----------------------------------------------------------------------------
/// @name Delegates
///-----------------------------------------------------------------------------

/**
 The delegate to inform when the request is completed

 If the object implements the RKRequestDelegate protocol, it will receive
 request lifecycle event messages.
 */
@property (nonatomic, assign) id<RKRequestDelegate> delegate;

/**
 A delegate responsible for configuring the request. Centralizes common
 configuration data (such as HTTP headers, authentication information, etc)
 for re-use.

 RKClient and RKObjectManager conform to the RKConfigurationDelegate protocol.
 Request and object loader instances built through these objects will have a
 reference to their parent client/object manager assigned as the configuration
 delegate.

 **Default**: nil
 @see RKClient
 @see RKObjectManager
 */
@property (nonatomic, assign) id<RKConfigurationDelegate> configurationDelegate;


///-----------------------------------------------------------------------------
/// @name Handling Blocks
///-----------------------------------------------------------------------------

/**
 A block to invoke when the receiver has loaded a response.

 @see [RKRequestDelegate request:didLoadResponse:]
 */
@property (nonatomic, copy) RKRequestDidLoadResponseBlock onDidLoadResponse;

/**
 A block to invoke when the receuver has failed loading due to an error.

 @see [RKRequestDelegate request:didFailLoadWithError:]
 */
@property (nonatomic, copy) RKRequestDidFailLoadWithErrorBlock onDidFailLoadWithError;

/**
 Whether this request should follow server redirects or not.

 @default YES
 */
@property (nonatomic, assign) BOOL followRedirect;

#if TARGET_OS_IPHONE
///-----------------------------------------------------------------------------
/// @name Background Tasks
///-----------------------------------------------------------------------------

/**
 The policy to take on transition to the background (iOS 4.x and higher only)

 **Default:** RKRequestBackgroundPolicyCancel
 */
@property (nonatomic, assign) RKRequestBackgroundPolicy backgroundPolicy;

/**
 Returns the identifier of the task that has been sent to the background.
 */
@property (nonatomic, readonly) UIBackgroundTaskIdentifier backgroundTaskIdentifier;
#endif


///-----------------------------------------------------------------------------
/// @name Authentication
///-----------------------------------------------------------------------------

/**
 The type of authentication to use for this request.

 This must be assigned one of the following:

 - `RKRequestAuthenticationTypeNone`: Disable the use of authentication
 - `RKRequestAuthenticationTypeHTTP`: Use NSURLConnection's HTTP AUTH
 auto-negotiation
 - `RKRequestAuthenticationTypeHTTPBasic`: Force the use of HTTP Basic
 authentication. This will supress AUTH challenges as RestKit will add an
 Authorization header establishing login via HTTP basic.  This is an
 optimization that skips the challenge portion of the request.
 - `RKRequestAuthenticationTypeOAuth1`: Enable the use of OAuth 1.0
 authentication. OAuth1ConsumerKey, OAuth1ConsumerSecret, OAuth1AccessToken,
 and OAuth1AccessTokenSecret must be set.
 - `RKRequestAuthenticationTypeOAuth2`: Enable the use of OAuth 2.0
 authentication. OAuth2AccessToken must be set.

 **Default**: RKRequestAuthenticationTypeNone
 */
@property (nonatomic, assign) RKRequestAuthenticationType authenticationType;

/**
 The username to use for authentication via HTTP AUTH.

 Used to respond to an authentication challenge when authenticationType is
 RKRequestAuthenticationTypeHTTP or RKRequestAuthenticationTypeHTTPBasic.

 @see authenticationType
 */
@property (nonatomic, retain) NSString *username;

/**
 The password to use for authentication via HTTP AUTH.

 Used to respond to an authentication challenge when authenticationType is
 RKRequestAuthenticationTypeHTTP or RKRequestAuthenticationTypeHTTPBasic.

 @see authenticationType
 */
@property (nonatomic, retain) NSString *password;


///-----------------------------------------------------------------------------
/// @name OAuth1 Secrets
///-----------------------------------------------------------------------------

/**
 The OAuth 1.0 consumer key

 Used to build an Authorization header when authenticationType is
 RKRequestAuthenticationTypeOAuth1

 @see authenticationType
 */
@property (nonatomic, retain) NSString *OAuth1ConsumerKey;

/**
 The OAuth 1.0 consumer secret

 Used to build an Authorization header when authenticationType is
 RKRequestAuthenticationTypeOAuth1

 @see authenticationType
 */
@property (nonatomic, retain) NSString *OAuth1ConsumerSecret;

/**
 The OAuth 1.0 access token

 Used to build an Authorization header when authenticationType is
 RKRequestAuthenticationTypeOAuth1

 @see authenticationType
 */
@property (nonatomic, retain) NSString *OAuth1AccessToken;

/**
 The OAuth 1.0 access token secret

 Used to build an Authorization header when authenticationType is
 RKRequestAuthenticationTypeOAuth1

 @see authenticationType
 */
@property (nonatomic, retain) NSString *OAuth1AccessTokenSecret;


///-----------------------------------------------------------------------------
/// @name OAuth2 Secrets
///-----------------------------------------------------------------------------

/**
 The OAuth 2.0 access token

 Used to build an Authorization header when authenticationType is
 RKRequestAuthenticationTypeOAuth2

 @see authenticationType
 */
@property (nonatomic, retain) NSString *OAuth2AccessToken;


/**
 The OAuth 2.0 refresh token

 Used to retrieve a new access token before expiration and to build an
 Authorization header when authenticationType is
 RKRequestAuthenticationTypeOAuth2

 @bug **NOT IMPLEMENTED**: This functionality is not yet implemented.

 @see authenticationType
 */
@property (nonatomic, retain) NSString *OAuth2RefreshToken;


///-----------------------------------------------------------------------------
/// @name Caching
///-----------------------------------------------------------------------------

/**
 Returns the cache key for getting/setting the cache entry for this request in
 the cache.

 The cacheKey is an MD5 value computed by hashing a combination of the
 destination URL, the HTTP verb, and the request body (when possible).
 */
@property (nonatomic, readonly) NSString *cacheKey;

/**
 The cache policy used when storing this request into the request cache
 */
@property (nonatomic, assign) RKRequestCachePolicy cachePolicy;

/**
 The request cache to store and load responses for this request.

 Generally configured by the RKClient instance that minted this request

 This must be assigned one of the following:

 - `RKRequestCachePolicyNone`: Never use the cache.
 - `RKRequestCachePolicyLoadIfOffline`: Load from the cache when offline.
 - `RKRequestCachePolicyLoadOnError`: Load from the cache if an error is
 encountered.
 - `RKRequestCachePolicyEtag`: Load from the cache if there is data stored and
 the server returns a 304 (Not Modified) response.
 - `RKRequestCachePolicyEnabled`: Load from the cache whenever data has been
 stored.
 - `RKRequestCachePolicyTimeout`: Load from the cache if the
 cacheTimeoutInterval is reached before the server responds.
 */
@property (nonatomic, retain) RKRequestCache *cache;

/**
 Returns YES if the request is cacheable

 Only GET requests are considered cacheable (see http://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html).
 */
- (BOOL)isCacheable;

/**
 The timeout interval within which the request should not be sent and the cached
 response should be used. Used if the cache policy includes
 RKRequestCachePolicyTimeout.
 */
@property (nonatomic, assign) NSTimeInterval cacheTimeoutInterval;


///-----------------------------------------------------------------------------
/// @name Handling SSL Validation
///-----------------------------------------------------------------------------

/**
 Flag for disabling SSL certificate validation.

 When YES, SSL certificates will not be validated.

 *Default*: NO

 @warning **WARNING**: This is a potential security exposure and should be used
 **ONLY while debugging** in a controlled environment.
 */
@property (nonatomic, assign) BOOL disableCertificateValidation;

/**
 A set of additional certificates to be used in evaluating server SSL
 certificates.
 */
@property (nonatomic, retain) NSSet *additionalRootCertificates;


///-----------------------------------------------------------------------------
/// @name Sending and Managing the Request
///-----------------------------------------------------------------------------
/**
 Setup the NSURLRequest.

 The request must be prepared right before dispatching.

 @return A boolean for the success of the URL preparation.
 */
- (BOOL)prepareURLRequest;

/**
 The request queue that this request belongs to
 */
@property (nonatomic, assign) RKRequestQueue *queue;

/**
 Send the request asynchronously. It will be added to the queue and dispatched
 as soon as possible.
 */
- (void)send;

/**
 Immediately dispatch a request asynchronously, skipping the request queue.
 */
- (void)sendAsynchronously;

/**
 Send the request synchronously and return a hydrated response object.

 @return An RKResponse object with the result of the request.
 */
- (RKResponse *)sendSynchronously;

/**
 Returns a Boolean value indicating whether the request has been cancelled.

 @return YES if the request was sent a cancel message, otherwise NO.
 */
@property (nonatomic, assign, readonly, getter=isCancelled) BOOL cancelled;

/**
 Cancels the underlying URL connection.

 This will call the requestDidCancel: delegate method if your delegate responds
 to it. This does not subsequently set the the request's delegate to nil.
 However, it's good practice to cancel the RKRequest and immediately set the
 delegate property to nil within the delegate's dealloc method.

 @see NSURLConnection:cancel
 */
- (void)cancel;

/**
 The reachability observer to consult for network status. Used for performing
 offline cache loads.

 Generally configured by the RKClient instance that minted this request.
 */
@property (nonatomic, retain) RKReachabilityObserver *reachabilityObserver;


///-----------------------------------------------------------------------------
/// @name Resetting the State
///-----------------------------------------------------------------------------

/**
 Resets the state of an RKRequest so that it can be re-sent.
 */
- (void)reset;


///-----------------------------------------------------------------------------
/// @name Callbacks
///-----------------------------------------------------------------------------

/**
 Callback performed to notify the request that the underlying NSURLConnection
 has failed with an error.

 @param error An NSError object containing the RKRestKitError that triggered
 the callback.
 */
- (void)didFailLoadWithError:(NSError *)error;

/**
 Callback performed to notify the request that the underlying NSURLConnection
 has completed with a response.

 @param response An RKResponse object with the result of the request.
 */
- (void)didFinishLoad:(RKResponse *)response;


///-----------------------------------------------------------------------------
/// @name Timing Out the Request
///-----------------------------------------------------------------------------

/**
 The timeout interval within which the request should be cancelled if no data
 has been received.

 The timeout timer is cancelled as soon as we start receiving data and are
 expecting the request to finish.

 **Default**: 120.0 seconds
 */
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

/**
 Creates a timeoutTimer to trigger the timeout method

 This is mainly used so we can test that the timer is only being created once.
 */
- (void)createTimeoutTimer;

/**
 Cancels request due to connection timeout exceeded.

 This method is invoked by the timeoutTimer upon its expiration and will return
 an RKRequestConnectionTimeoutError via didFailLoadWithError:
 */
- (void)timeout;

/**
 Invalidates the timeout timer.

 Called by RKResponse when the NSURLConnection begins receiving data.
 */
- (void)invalidateTimeoutTimer;


///-----------------------------------------------------------------------------
/// @name Determining the Request Type and State
///-----------------------------------------------------------------------------

/**
 Returns YES when this is a GET request
 */
- (BOOL)isGET;

/**
 Returns YES when this is a POST request
 */
- (BOOL)isPOST;

/**
 Returns YES when this is a PUT request
 */
- (BOOL)isPUT;

/**
 Returns YES when this is a DELETE request
 */
- (BOOL)isDELETE;

/**
 Returns YES when this is a HEAD request
 */
- (BOOL)isHEAD;

/**
 Returns YES when this request is in-progress
 */
@property (nonatomic, assign, readonly, getter = isLoading) BOOL loading;

/**
 Returns YES when this request has been completed
 */
@property (nonatomic, assign, readonly, getter = isLoaded) BOOL loaded;

/**
 Returns YES when this request has not yet been sent
 */
- (BOOL)isUnsent;

/**
 Returns YES when the request was sent to the specified resource path

 @param resourcePath A string of the resource path that we want to check against
 */
- (BOOL)wasSentToResourcePath:(NSString *)resourcePath;

/**
 Returns YES when the receiver was sent to the specified resource path with a given request method.

 @param resourcePath A string of the resource path that we want to check against
 @param method The HTTP method to confirm the request was sent with.
 */
- (BOOL)wasSentToResourcePath:(NSString *)resourcePath method:(RKRequestMethod)method;

@end

/**
 Lifecycle events for an RKRequest object
 */
@protocol RKRequestDelegate <NSObject>
@optional


///-----------------------------------------------------------------------------
/// @name Observing Request Progress
///-----------------------------------------------------------------------------

/**
 Tells the delegate the request is about to be prepared for sending to the remote host.

 @param request The RKRequest object that is about to be sent.
 */
- (void)requestWillPrepareForSend:(RKRequest *)request;

/**
 Sent when a request has received a response from the remote host.

 @param request The RKRequest object that received a response.
 @param response The RKResponse object for the HTTP response that was received.
 */
- (void)request:(RKRequest *)request didReceiveResponse:(RKResponse *)response;

/**
 Sent when a request has started loading

 @param request The RKRequest object that has begun loading.
 */
- (void)requestDidStartLoad:(RKRequest *)request;

/**
 Sent when a request has uploaded data to the remote site

 @param request The RKRequest object that is handling the loading.
 @param bytesWritten An integer of the bytes of the chunk just sent to the
 remote site.
 @param totalBytesWritten An integer of the total bytes that have been sent to
 the remote site.
 @param totalBytesExpectedToWrite An integer of the total bytes that will be
 sent to the remote site.
 */
- (void)request:(RKRequest *)request didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite;

/**
 Sent when request has received data from remote site

 @param request The RKRequest object that is handling the loading.
 @param bytesReceived An integer of the bytes of the chunk just received from
 the remote site.
 @param totalBytesReceived An integer of the total bytes that have been
 received from the remote site.
 @param totalBytesExpectedToReceive An integer of the total bytes that will be
 received from the remote site.
 */
- (void)request:(RKRequest *)request didReceiveData:(NSInteger)bytesReceived totalBytesReceived:(NSInteger)totalBytesReceived totalBytesExpectedToReceive:(NSInteger)totalBytesExpectedToReceive;


///-----------------------------------------------------------------------------
/// @name Handling Successful Requests
///-----------------------------------------------------------------------------

/**
 Sent when a request has finished loading

 @param request The RKRequest object that was handling the loading.
 @param response The RKResponse object containing the result of the request.
 */
- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response;


///-----------------------------------------------------------------------------
/// @name Handling Failed Requests
///-----------------------------------------------------------------------------

/**
 Sent when a request has failed due to an error

 @param request The RKRequest object that was handling the loading.
 @param error An NSError object containing the RKRestKitError that triggered
 the callback.
 */
- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error;

/**
 Sent to the delegate when a request was cancelled

 @param request The RKRequest object that was cancelled.
 */
- (void)requestDidCancelLoad:(RKRequest *)request;

/**
 Sent to the delegate when a request has timed out. This is sent when a
 backgrounded request expired before completion.

 @param request The RKRequest object that timed out.
 */
- (void)requestDidTimeout:(RKRequest *)request;

@end
