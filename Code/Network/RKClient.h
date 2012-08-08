//
//  RKClient.h
//  RestKit
//
//  Created by Blake Watters on 7/28/09.
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

#import "RKURL.h"
#import "RKRequest.h"
#import "RKParams.h"
#import "RKResponse.h"
#import "NSDictionary+RKRequestSerialization.h"
#import "RKReachabilityObserver.h"
#import "RKRequestCache.h"
#import "RKRequestQueue.h"
#import "RKConfigurationDelegate.h"


/**
 RKClient exposes the low level client interface for working with HTTP servers
 and RESTful services. It wraps the request/response cycle with a clean, simple
 interface.

 RKClient can be thought of as analogous to a web browser or other HTTP user
 agent. The client's primary purpose is to configure and dispatch requests to a
 remote service for processing in a global way. When working with the Network
 layer, a user will generally construct and dispatch all RKRequest objects via
 the interfaces exposed by RKClient.


 ### Base URL and Resource Paths

 Core to an effective utilization of RKClient is an understanding of the Base
 URL and Resource Path concepts. The Base URL forms the common beginning part of
 a complete URL string that is used to access a remote web service. RKClient
 instances are configured with a Base URL and all requests dispatched through
 the client will be sent to a URL consisting of the base URL plus the resource
 path specified. The resource path is simply the remaining part of the URL once
 all common text is removed.

 For example, given a remote web service at `http://restkit.org` and RESTful
 services at `http://restkit.org/services` and `http://restkit.org/objects`, our
 base URL would be `http://restkit.org` and we would have resource paths of
 `/services` and `/objects`.

 Base URLs simplify interaction with remote services by freeing us from having
 to interpolate strings and construct NSURL objects to get work done. We are
 also able to quickly retarget an entire application to a different server or
 API version by changing the base URL. This is commonly done via conditional
 compilation to create builds against a staging and production server, for
 example.


 ### Memory Management

 Note that memory management of requests sent via RKClient instances are
 automatically managed for you. When sent, the request is retained by the
 requestQueue and is released when all request processing has completed.
 Generally speaking this means that you can dispatch requests and work with the
 response in the delegate methods without regard for memory management.


 ### Request Serialization

 RKClient and RKRequest support the serialization of objects into payloads to be
 sent as the body of a request. This functionality is commonly used to provide a
 dictionary of simple values to be encoded and sent as a form encoding with POST
 and PUT operations. It is worth noting however that this functionality is
 provided via the RKRequestSerializable protocol and is not specific to
 NSDictionary objects.

 ### Sending Asynchronous Requests

 A handful of methods are provided as a convenience to cover the common
 asynchronous request tasks. All other request needs should instantiate a
 request via [RKClient requestWithResourcePath:] and work with the RKRequest
 object directly.

 @see RKRequest
 @see RKResponse
 @see RKRequestQueue
 @see RKRequestSerializable
 */
@interface RKClient : NSObject <RKConfigurationDelegate> {
    NSMutableSet *_additionalRootCertificates;

    // Queue suspension flags
    BOOL _awaitingReachabilityDetermination;
}


///-----------------------------------------------------------------------------
/// @name Initializing a Client
///-----------------------------------------------------------------------------

/**
 Returns a client scoped to a particular base URL.

 If the singleton client is nil, the return client is set as the singleton.

 @see baseURL
 @param baseURL The baseURL to set for the client. All requests will be relative
 to this base URL.
 @return A configured RKClient instance ready to send requests
 */
+ (RKClient *)clientWithBaseURL:(NSURL *)baseURL;

/**
 Returns a client scoped to a particular base URL.

 If the singleton client is nil, the return client is set as the singleton.

 @see baseURL
 @param baseURLString The string to use to construct the NSURL to set the
 baseURL. All requests will be relative to this base URL.
 @return A configured RKClient instance ready to send requests
 */
+ (RKClient *)clientWithBaseURLString:(NSString *)baseURLString;

/**
 Returns a Rest client scoped to a particular base URL with a set of HTTP AUTH
 credentials.

 If the singleton client is nil, the return client is set as the singleton.

 @bug **DEPRECATED** in version 0.9.4: Use [RKClient clientWithBaseURLString:]
 and set username and password afterwards.
 @param baseURL The baseURL to set for the client. All requests will be relative
 to this base URL.
 @param username The username to use for HTTP Authentication challenges
 @param password The password to use for HTTP Authentication challenges
 @return A configured RKClient instance ready to send requests
 */
+ (RKClient *)clientWithBaseURL:(NSString *)baseURL username:(NSString *)username password:(NSString *)password DEPRECATED_ATTRIBUTE;

/**
 Returns a client scoped to a particular base URL. If the singleton client is
 nil, the return client is set as the singleton.

 @see baseURL
 @param baseURL The baseURL to set for the client. All requests will be relative
 to this base URL.
 @return A configured RKClient instance ready to send requests
 */
- (id)initWithBaseURL:(NSURL *)baseURL;

/**
 Returns a client scoped to a particular base URL. If the singleton client is
 nil, the return client is set as the singleton.

 @see baseURL
 @param baseURLString The string to use to construct the NSURL to set the
 baseURL. All requests will be relative to this base URL.
 @return A configured RKClient instance ready to send requests
 */
- (id)initWithBaseURLString:(NSString *)baseURLString;


///-----------------------------------------------------------------------------
/// @name Configuring the Client
///-----------------------------------------------------------------------------

/**
 The base URL all resources are nested underneath. All requests created through
 the client will their URL built by appending a resourcePath to the baseURL to
 form a complete URL.

 Changing the baseURL has the side-effect of causing the requestCache instance
 to be rebuilt. Caches are maintained a per-host basis.

 @see requestCache
 */
@property (nonatomic, retain) RKURL *baseURL;

/**
 A dictionary of headers to be sent with each request
 */
@property (nonatomic, retain, readonly) NSMutableDictionary *HTTPHeaders;

/**
 An optional timeout interval within which the request should be cancelled.

 This is passed along to RKRequest if set.  If it isn't set, it will default
 to RKRequest's default timeoutInterval.

 *Default*: Falls through to RKRequest's timeoutInterval
 */
@property (nonatomic, assign) NSTimeInterval timeoutInterval;

/**
 The request queue to push asynchronous requests onto.

 *Default*: A new request queue is instantiated for you during init.
 */
@property (nonatomic, retain) RKRequestQueue *requestQueue;

/**
 The run loop mode under which the underlying NSURLConnection is performed

 *Default*: NSRunLoopCommonModes
 */
@property (nonatomic, copy) NSString *runLoopMode;


/**
 The default value used to decode HTTP body content when HTTP headers received do not provide information on the content.
 This encoding will be used by the RKResponse when creating the body content
 */
@property (nonatomic, assign) NSStringEncoding defaultHTTPEncoding;

/**
 Adds an HTTP header to each request dispatched through the client

 @param value The string value to set for the HTTP header
 @param header The HTTP header to add
 @see HTTPHeaders
 */
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)header;


///-----------------------------------------------------------------------------
/// @name Handling SSL Validation
///-----------------------------------------------------------------------------

/**
 Flag for disabling SSL certificate validation.

 *Default*: NO

 @warning **WARNING**: This is a potential security exposure and should be used
 **ONLY while debugging** in a controlled environment.
 */
@property (nonatomic, assign) BOOL disableCertificateValidation;


/**
 A set of additional certificates to be used in evaluating server SSL
 certificates.
 */
@property (nonatomic, retain, readonly) NSSet *additionalRootCertificates;

/**
 Adds an additional certificate that will be used to evaluate server SSL certs.

 @param cert The SecCertificateRef to add to the list of additional SSL certs.
 @see additionalRootCertificates
 */
- (void)addRootCertificate:(SecCertificateRef)cert;


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
/// @name Reachability & Service Availability Alerting
///-----------------------------------------------------------------------------

/**
 An instance of RKReachabilityObserver used for determining the availability of
 network access.

 Initialized using [RKReachabilityObserver reachabilityObserverForInternet] to
 monitor connectivity to the Internet. Can be changed to directly monitor a
 remote hostname/IP address or the local WiFi interface instead.

 @warning **WARNING**: Changing the reachability observer has the side-effect of
 temporarily suspending the requestQueue until reachability to the new host can
 be established.

 @see RKReachabilityObserver
 */
@property (nonatomic, retain) RKReachabilityObserver *reachabilityObserver;

/**
 The title to use in the alert shown when a request encounters a
 ServiceUnavailable (503) response.

 *Default*: _"Service Unavailable"_
 */
@property (nonatomic, retain) NSString *serviceUnavailableAlertTitle;

/**
 The message to use in the alert shown when a request encounters a
 ServiceUnavailable (503) response.

 *Default*: _"The remote resource is unavailable. Please try again later."_
 */
@property (nonatomic, retain) NSString *serviceUnavailableAlertMessage;

/**
 Flag that determines whether the Service Unavailable alert is shown in response
 to a ServiceUnavailable (503) response.

 *Default*: _NO_
 */
@property (nonatomic, assign) BOOL serviceUnavailableAlertEnabled;


///-----------------------------------------------------------------------------
/// @name Reachability helpers
///-----------------------------------------------------------------------------

/**
 Convenience method for returning the current reachability status from the
 reachabilityObserver.

 Equivalent to executing `[RKClient isNetworkReachable]` on the sharedClient

 @see RKReachabilityObserver
 @return YES if the remote host is accessible
 */
- (BOOL)isNetworkReachable;

/**
 Convenience method for returning the current reachability status from the
 reachabilityObserver.

 @bug **DEPRECATED** in v0.10.0: Use [RKClient isNetworkReachable]
 @see RKReachabilityObserver
 @return YES if the remote host is accessible
 */
- (BOOL)isNetworkAvailable DEPRECATED_ATTRIBUTE;


///-----------------------------------------------------------------------------
/// @name Caching
///-----------------------------------------------------------------------------

/**
 An instance of the request cache used to store/load cacheable responses for
 requests sent through this client

 @bug **DEPRECATED** in v0.10.0: Use requestCache instead.
 */
@property (nonatomic, retain) RKRequestCache *cache DEPRECATED_ATTRIBUTE;

/**
 An instance of the request cache used to store/load cacheable responses for
 requests sent through this client
 */
@property (nonatomic, retain) RKRequestCache *requestCache;

/**
 The timeout interval within which the requests should not be sent and the
 cached response should be used.

 This is only used if the cache policy includes RKRequestCachePolicyTimeout.
 */
@property (nonatomic, assign) NSTimeInterval cacheTimeoutInterval;

/**
 The default cache policy to apply for all requests sent through this client

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

 @see RKRequest
 */
@property (nonatomic, assign) RKRequestCachePolicy cachePolicy;

/**
 The path used to store response data for this client's request cache.

 The path that is used is the device's cache directory with
 `RKClientRequestCache-host` appended.
 */
@property (nonatomic, readonly) NSString *cachePath;


///-----------------------------------------------------------------------------
/// @name Shared Client Instance
///-----------------------------------------------------------------------------

/**
 Returns the shared instance of the client
 */
+ (RKClient *)sharedClient;

/**
 Sets the shared instance of the client, releasing the current instance (if any)

 @param client An RKClient instance to configure as the new shared instance
 */
+ (void)setSharedClient:(RKClient *)client;


///-----------------------------------------------------------------------------
/// @name Building Requests
///-----------------------------------------------------------------------------

/**
 Return a request object targetted at a resource path relative to the base URL.

 By default the method is set to GET.  All headers set on the client will
 automatically be applied to the request as well.

 @bug **DEPRECATED** in v0.10.0: Use [RKClient requestWithResourcePath:] instead.
 @param resourcePath The resource path to configure the request for.
 @param delegate A delegate to inform of events in the request lifecycle.
 @return A fully configured RKRequest instance ready for sending.
 @see RKRequestDelegate
 */
- (RKRequest *)requestWithResourcePath:(NSString *)resourcePath delegate:(NSObject<RKRequestDelegate> *)delegate DEPRECATED_ATTRIBUTE;

/**
 Return a request object targeted at a resource path relative to the base URL.

 By default the method is set to GET.  All headers set on the client will
 automatically be applied to the request as well.

 @param resourcePath The resource path to configure the request for.
 @return A fully configured RKRequest instance ready for sending.
 @see RKRequestDelegate
 */
- (RKRequest *)requestWithResourcePath:(NSString *)resourcePath;


///-----------------------------------------------------------------------------
/// @name Sending Asynchronous Requests
///-----------------------------------------------------------------------------

/**
 Perform an asynchronous GET request for a resource and inform a delegate of the
 results.

 @param resourcePath The resourcePath to target the request at
 @param delegate A delegate object to inform of the results
 @return The RKRequest object built and sent to the remote system
 */
- (RKRequest *)get:(NSString *)resourcePath delegate:(NSObject<RKRequestDelegate> *)delegate;

/**
 Fetch a resource via an HTTP GET with a dictionary of params.

 This request _only_ allows NSDictionary objects as the params. The dictionary
 will be coerced into a URL encoded string and then appended to the resourcePath
 as the query string of the request.

 @param resourcePath The resourcePath to target the request at
 @param queryParameters A dictionary of query parameters to append to the
 resourcePath. Assumes that resourcePath does not contain a query string.
 @param delegate A delegate object to inform of the results
 @return The RKRequest object built and sent to the remote system
 */
- (RKRequest *)get:(NSString *)resourcePath queryParameters:(NSDictionary *)queryParameters delegate:(NSObject<RKRequestDelegate> *)delegate;

/**
 Fetches a resource via an HTTP GET after executing a given a block using the configured request object.

 @param resourcePath The resourcePath to target the request at
 @param block The block to execute with the request before sending it for processing.
 */
- (void)get:(NSString *)resourcePath usingBlock:(void (^)(RKRequest *request))block;

/**
 Create a resource via an HTTP POST with a set of form parameters.

 The form parameters passed here must conform to RKRequestSerializable, such as
 an instance of RKParams.

 @see RKParams
 @param resourcePath The resourcePath to target the request at
 @param params A RKRequestSerializable object to use as the body of the request
 @param delegate A delegate object to inform of the results
 @return The RKRequest object built and sent to the remote system
 @see RKRequestSerializable
 */
- (RKRequest *)post:(NSString *)resourcePath params:(NSObject<RKRequestSerializable> *)params delegate:(NSObject<RKRequestDelegate> *)delegate;

/**
 Creates a resource via an HTTP POST after executing a given a block using the configured request object.

 @param resourcePath The resourcePath to target the request at
 @param block The block to execute with the request before sending it for processing.
 */
- (void)post:(NSString *)resourcePath usingBlock:(void (^)(RKRequest *request))block;

/**
 Update a resource via an HTTP PUT.

 The form parameters passed here must conform to RKRequestSerializable, such as
 an instance of RKParams.

 @see RKParams

 @param resourcePath The resourcePath to target the request at
 @param params A RKRequestSerializable object to use as the body of the request
 @param delegate A delegate object to inform of the results
 @return The RKRequest object built and sent to the remote system
 @see RKRequestSerializable
 */
- (RKRequest *)put:(NSString *)resourcePath params:(NSObject<RKRequestSerializable> *)params delegate:(NSObject<RKRequestDelegate> *)delegate;

/**
 Updates a resource via an HTTP PUT after executing a given a block using the configured request object.

 @param resourcePath The resourcePath to target the request at
 @param block The block to execute with the request before sending it for processing.
 */
- (void)put:(NSString *)resourcePath usingBlock:(void (^)(RKRequest *request))block;

/**
 Destroy a resource via an HTTP DELETE.

 @param resourcePath The resourcePath to target the request at
 @param delegate A delegate object to inform of the results
 @return The RKRequest object built and sent to the remote system
 */
- (RKRequest *)delete:(NSString *)resourcePath delegate:(NSObject<RKRequestDelegate> *)delegate;

/**
 Destroys a resource via an HTTP DELETE after executing a given a block using the configured request object.

 @param resourcePath The resourcePath to target the request at
 @param block The block to execute with the request before sending it for processing.
 */
- (void)delete:(NSString *)resourcePath usingBlock:(void (^)(RKRequest *request))block;

///-----------------------------------------------------------------------------
/// @name Constructing Resource Paths and URLs
///-----------------------------------------------------------------------------

/**
 Returns a NSURL by adding a resource path to the base URL

 @bug **DEPRECATED** in v0.10.0: Use [RKURL URLByAppendingResourcePath:]

 @param resourcePath The resource path to build a URL against
 @return An NSURL constructed by concatenating the baseURL and the resourcePath
 */
- (NSURL *)URLForResourcePath:(NSString *)resourcePath DEPRECATED_ATTRIBUTE;

/**
 Returns an NSString by adding a resource path to the base URL

 @bug **DEPRECATED**: Use `[RKURL URLByAppendingResourcePath:] absoluteString`

 @param resourcePath The resource path to build a URL against
 @return A string URL constructed by concatenating the baseURL and the
 resourcePath.
 */
- (NSString *)URLPathForResourcePath:(NSString *)resourcePath DEPRECATED_ATTRIBUTE;

/**
 Returns a resource path with a dictionary of query parameters URL encoded and
 appended

 This is a convenience method for constructing a new resource path that includes
 a query. For example, when given a resourcePath of /contacts and a dictionary
 of parameters containing foo=bar and color=red, will return
 /contacts?foo=bar&amp;color=red

 @warning **NOTE**: This assumes that the resource path does not already contain
 any query parameters.

 @bug **DEPRECATED**: Use [RKURL URLByAppendingQueryParameters:]

 @param resourcePath The resource path to append the query parameters onto
 @param queryParams A dictionary of query parameters to be URL encoded and
 appended to the resource path.
 @return A new resource path with the query parameters appended
 */
- (NSString *)resourcePath:(NSString *)resourcePath withQueryParams:(NSDictionary *)queryParams DEPRECATED_ATTRIBUTE;

/**
 Returns a NSURL by adding a resource path to the base URL and appending a URL
 encoded set of query parameters

 This is a convenience method for constructing a new resource path that includes
 a query. For example, when given a resourcePath of /contacts and a dictionary
 of parameters containing foo=bar and color=red, will return
 /contacts?foo=bar&amp;color=red

 @warning **NOTE**: Assumes that the resource path does not already contain any
 query parameters.

 @bug **DEPRECATED**: Use [RKURL URLByAppendingResourcePath:queryParameters:]

 @param resourcePath The resource path to append the query parameters onto
 @param queryParams A dictionary of query parameters to be URL encoded and
 appended to the resource path.
 @return A URL constructed by concatenating the baseURL and the resourcePath
 with the query parameters appended.
 */
- (NSURL *)URLForResourcePath:(NSString *)resourcePath queryParams:(NSDictionary *)queryParams DEPRECATED_ATTRIBUTE;

@end


///-----------------------------------------------------------------------------
/// @name URL & URL Path Convenience methods
///-----------------------------------------------------------------------------

/**
 Returns an NSURL with the specified resource path appended to the base URL that
 the shared RKClient instance is configured with.

 Shortcut for calling `[[RKClient sharedClient] URLForResourcePath:@"/some/path"]`

 @bug **DEPRECATED** in v0.10.0: Use [[RKClient sharedClient].baseURL
 URLByAppendingResourcePath:]
 @param resourcePath The resource path to append to the baseURL of the
 `[RKClient sharedClient]`
 @return A fully constructed NSURL consisting of baseURL of the shared client
 singleton and the supplied resource path
 */
NSURL *RKMakeURL(NSString *resourcePath) DEPRECATED_ATTRIBUTE;

/**
 Returns an NSString with the specified resource path appended to the base URL
 that the shared RKClient instance is configured with

 Shortcut for calling
 `[[RKClient sharedClient] URLPathForResourcePath:@"/some/path"]`

 @bug **DEPRECATED** in v0.10.0: Use
 [[[RKClient sharedClient].baseURL URLByAppendingResourcePath:] absoluteString]
 @param resourcePath The resource path to append to the baseURL of the
 `[RKClient sharedClient]`
 @return A fully constructed NSURL consisting of baseURL of the shared client
 singleton and the supplied resource path
 */
NSString *RKMakeURLPath(NSString *resourcePath) DEPRECATED_ATTRIBUTE;

/**
 Convenience method for generating a path against the properties of an object.
 Takes a string with property names encoded with colons and interpolates the
 values of the properties specified and returns the generated path.  Defaults to
 adding escapes.  If desired, turn them off with
 RKMakePathWithObjectAddingEscapes.

 For example, given an 'article' object with an 'articleID' property of 12345
 and a 'name' of Blake, RKMakePathWithObject(@"articles/:articleID/:name", article)
 would generate @"articles/12345/Blake"

 This functionality is the basis for resource path generation in the Router.

 @bug **DEPRECATED** in v0.10.0: Use [NSString interpolateWithObject:]

 @param path The colon encoded path pattern string to use for interpolation.
 @param object The object containing the properties needed for interpolation.
 @return A new path string, replacing the pattern's parameters with the object's
 actual property values.
 @see RKMakePathWithObjectAddingEscapes
 */
NSString *RKMakePathWithObject(NSString *path, id object) DEPRECATED_ATTRIBUTE;

/**
 Convenience method for generating a path against the properties of an object. Takes
 a string with property names encoded with colons and interpolates the values of
 the properties specified and returns the generated path.

 For example, given an 'article' object with an 'articleID' property of 12345
 and a 'code' of "This/That", `RKMakePathWithObjectAddingEscapes(@"articles/:articleID/:code", article, YES)`
 would generate @"articles/12345/This%2FThat"

 This functionality is the basis for resource path generation in the Router.

 @bug **DEPRECATED** in v0.10.0: Use [NSString interpolateWithObject:addingEscapes:]
 @param path The colon encoded path pattern string to use for interpolation.
 @param object The object containing the properties needed for interpolation.
 @param addEscapes Conditionally add percent escapes to the interpolated
 property values.
 @return A new path string, replacing the pattern's parameters with the object's
 actual property values.
 */
NSString *RKMakePathWithObjectAddingEscapes(NSString *pattern, id object, BOOL addEscapes) DEPRECATED_ATTRIBUTE;

/**
 Returns a resource path with a dictionary of query parameters URL encoded and
 appended.

 This is a convenience method for constructing a new resource path that includes
 a query. For example, when given a resourcePath of /contacts and a dictionary
 of parameters containing `foo=bar` and `color=red`, will return
 `/contacts?foo=bar&amp;color=red`.

 @warning This assumes that the resource path does not already contain any query
 parameters.

 @bug **DEPRECATED** in v0.10.0: Use [NSString stringByAppendingQueryParameters:]
 instead

 @param resourcePath The resource path to append the query parameters onto
 @param queryParams A dictionary of query parameters to be URL encoded and
 appended to the resource path.
 @return A new resource path with the query parameters appended.
 */
NSString *RKPathAppendQueryParams(NSString *resourcePath, NSDictionary *queryParams) DEPRECATED_ATTRIBUTE;
