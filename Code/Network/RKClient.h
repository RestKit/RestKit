//
//  RKClient.h
//  RestKit
//
//  Created by Blake Watters on 7/28/09.
//  Copyright 2009 RestKit
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

#import "RKRequest.h"
#import "RKParams.h"
#import "RKResponse.h"
#import "NSDictionary+RKRequestSerialization.h"
#import "RKReachabilityObserver.h"
#import "RKRequestCache.h"
#import "RKRequestQueue.h"

/////////////////////////////////////////////////////////////////////////

/**
 @name URL & URL Path Convenience methods
 */

/**
 Returns an NSURL with the specified resource path appended to the base URL
 that the shared RKClient instance is configured with
 
 Shortcut for calling `[[RKClient sharedClient] URLForResourcePath:@"/some/path"]`
 
 @param resourcePath The resource path to append to the baseURL of the [RKClient sharedClient]
 @return A fully constructed NSURL consisting of baseURL of the shared client singleton and the supplied 
 */
NSURL *RKMakeURL(NSString *resourcePath);

/**
 Returns an NSString with the specified resource path appended to the base URL
 that the shared RKClient instance is configured with
 
 Shortcut for calling [[RKClient sharedClient] URLPathForResourcePath:@"/some/path"]
 */
NSString *RKMakeURLPath(NSString *resourcePath);

/**
 Convenience method for generating a path against the properties of an object. Takes
 a string with property names encoded with colons and interpolates the values of
 the properties specified and returns the generated path.  Defaults to adding escapes.  If desired,
 turn them off with RKMakePathWithObjectAddingEscapes
 
 For example, given an 'article' object with an 'articleID' property of 12345 and a 'name' of Blake,
 RKMakePathWithObject(@"articles/:articleID/:name", article) would generate @"articles/12345/Blake"
 
 This functionality is the basis for resource path generation in the Router.
 @param path The colon encoded path pattern string to use for interpolation.
 @param object The object containing the properties needed for interpolation.
 @return A new path string, replacing the pattern's parameters with the object's actual property values.
 @see RKMakePathWithObjectAddingEscapes
 */
NSString *RKMakePathWithObject(NSString *path, id object);

/**
 Convenience method for generating a path against the properties of an object. Takes
 a string with property names encoded with colons and interpolates the values of
 the properties specified and returns the generated path.
 
 For example, given an 'article' object with an 'articleID' property of 12345 and a 'code' of "This/That",
 RKMakePathWithObjectAddingEscapes(@"articles/:articleID/:code", article, YES) would generate @"articles/12345/This%2FThat"
 
 This functionality is the basis for resource path generation in the Router.
 @param path The colon encoded path pattern string to use for interpolation.
 @param object The object containing the properties needed for interpolation.
 @param addEscapes Conditionally add percent escapes to the interpolated property values.
 @return A new path string, replacing the pattern's parameters with the object's actual property values.
 */
NSString *RKMakePathWithObjectAddingEscapes(NSString *pattern, id object, BOOL addEscapes);

/**
 Returns a resource path with a dictionary of query parameters URL encoded and appended
 
 This is a convenience method for constructing a new resource path that includes a query. For example,
 when given a resourcePath of /contacts and a dictionary of parameters containing foo=bar and color=red,
 will return /contacts?foo=bar&amp;color=red
 
 *NOTE* - Assumes that the resource path does not already contain any query parameters.
 
 @param resourcePath The resource path to append the query parameters onto
 @param queryParams A dictionary of query parameters to be URL encoded and appended to the resource path
 @return A new resource path with the query parameters appended
 */
NSString *RKPathAppendQueryParams(NSString *resourcePath, NSDictionary *queryParams);

/////////////////////////////////////////////////////////////////////////

/**
 RKClient exposes the low level client interface for working
 with HTTP servers and RESTful services. It wraps the request/response
 cycle with a clean, simple interface.
 
 RKClient can be thought of as analogous to a web browser or other HTTP
 user agent. The client's primary purpose is to configure and dispatch
 requests to a remote service for processing in a global way. When working
 with the Network layer, a user will generally construct and dispatch all
 RKRequest objects via the interfaces exposed by RKClient.
 
 Base URL and Resource Paths
 ---------------------------
 
 Core to an effective utilization of RKClient is an understanding of the
 Base URL and Resource Path concepts. The Base URL forms the common beginning part
 of a complete URL string that is used to access a remote web service. RKClient
 instances are configured with a Base URL and all requests dispatched through the
 client will be sent to a URL consisting of the base URL plus the resource path specified.
 The resource path is simply the remaining part of the URL once all common text is removed.
 
 For example, given a remote web service at http://restkit.org and RESTful services at 
 http://restkit.org/services and http://restkit.org/objects, our base URL would be http://restkit.org
 and we would have resource paths of /services and /objects.
 
 Base URL's simplify interaction with remote services by freeing us from having to interpolate
 strings and construct NSURL objects to get work done. We are also able to quickly retarget an
 entire application to a different server or API version by changing the base URL. This is commonly
 done via conditional compilation to create builds against a staging and production server, for example.
 
 Memory Management
 -----------------
 
 Note that memory management of requests sent via RKClient instances are automatically managed
 for you. When sent, the request is retained by the requestQueue
 and is released all request processing has completed. Generally speaking this means that you can dispatch
 requests and work with the response in the delegate methods without regard for memory management.
 
 Request Serialization
 ---------------------
 
 RKClient and RKRequest support the serialization of objects into payloads to be sent as the body of a request.
 This functionality is commonly used to provide a dictionary of simple values to be encoded and sent as a form
 encoding with POST and PUT operations. It is worth noting however that this functionality is provided via the
 RKRequestSerializable protocol and is not specific to NSDictionary objects.
 
 @see RKRequest
 @see RKResponse
 @see RKRequestQueue
 @see RKRequestSerializable
 */
@interface RKClient : NSObject {
	NSString *_baseURL;
    RKRequestAuthenticationType _authenticationType;
	NSString *_username;
	NSString *_password;
    NSString *_OAuth1ConsumerKey;
    NSString *_OAuth1ConsumerSecret;
    NSString *_OAuth1AccessToken;
    NSString *_OAuth1AccessTokenSecret;
    NSString *_OAuth2AccessToken;
    NSString *_OAuth2RefreshToken;
	NSMutableDictionary *_HTTPHeaders;
	RKReachabilityObserver *_reachabilityObserver;
	NSString *_serviceUnavailableAlertTitle;
	NSString *_serviceUnavailableAlertMessage;
	BOOL _serviceUnavailableAlertEnabled;
    RKRequestQueue *_requestQueue;
	RKRequestCache *_requestCache;
	RKRequestCachePolicy _cachePolicy;
    NSMutableSet *_additionalRootCertificates;
    BOOL _disableCertificateValidation;
    
    // Queue suspension flags
    BOOL _awaitingReachabilityDetermination;
}

/////////////////////////////////////////////////////////////////////////
/// @name Configuring the Client
/////////////////////////////////////////////////////////////////////////

/**
 The base URL all resources are nested underneath. All requests created through
 the client will their URL built by appending a resourcePath to the baseURL to
 form a complete URL.
 
 Changing the baseURL has the side-effect of causing the requestCache instance to
 be rebuilt. Caches are maintained a per-host basis.
 
 @see requestCache
 */
@property (nonatomic, retain) NSString *baseURL;

/**
 A dictionary of headers to be sent with each request
 */
@property (nonatomic, readonly) NSMutableDictionary *HTTPHeaders;

/**
 Accept all SSL certificates. This is a potential security exposure,
 and should be used ONLY while debugging in a controlled environment.
 
 *Default*: _NO_
 */
@property (nonatomic, assign) BOOL disableCertificateValidation;

/**
 The request queue to push asynchronous requests onto.
 
 *Default*: A new request queue is instantiated for you during init
 */
@property (nonatomic, retain) RKRequestQueue *requestQueue;

/**
 Convenience method for returning the current reachability status
 from the reachabilityObserver.
 
 Equivalent to executing `[[RKClient sharedClient] isNetworkReachable]`
 
 @see baseURL
 @see RKReachabilityObserver
 @return YES if the remote host is accessible
 */
- (BOOL)isNetworkReachable;
- (BOOL)isNetworkAvailable DEPRECATED_ATTRIBUTE;

/**
 * Adds an HTTP header to each request dispatched through the client
 * 
 * @param value The string value to set for the HTTP header
 * @param header The HTTP header to add
 * @see HTTPHeaders
 */
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)header;

/////////////////////////////////////////////////////////////////////////
/// @name SSL Validation
/////////////////////////////////////////////////////////////////////////

/**
 * A set of additional certificates to be used in evaluating server
 * SSL certificates.
 */
@property(nonatomic, readonly) NSSet *additionalRootCertificates;

/**
 * Adds an additional certificate that will be used to evaluate server SSL certs
 *
 * @param cert The HTTP header to add
 * @see additionalRootCertificates
 */
- (void)addRootCertificate:(SecCertificateRef)cert;

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
 The username to use for authentication via HTTP AUTH
 
 Used to respond to an authentication challenge when authenticationType is
 RKRequestAuthenticationTypeHTTP or RKRequestAuthenticationTypeHTTPBasic
 
 @see authenticationType
 @see RKRequestAuthenticationType
 */
@property(nonatomic, retain) NSString *username;

/**
 The password to use for authentication via HTTP AUTH
 
 Used to respond to an authentication challenge when authenticationType is
 RKRequestAuthenticationTypeHTTP or RKRequestAuthenticationTypeHTTPBasic
 
 @see authenticationType
 @see RKRequestAuthenticationType
 */
@property(nonatomic, retain) NSString *password;

/*** @name OAuth Secrets */

/**
 The OAuth 1.0 consumer key
 
 Used to build an Authorization header wjem authenticationType is
 RKRequestAuthenticationTypeOAuth1
 
 @see authenticationType
 @see RKRequestAuthenticationType
 */
@property(nonatomic,retain) NSString *OAuth1ConsumerKey;

/**
 The OAuth 1.0 consumer secret
 
 Used to build an Authorization header wjem authenticationType is
 RKRequestAuthenticationTypeOAuth1
 
 @see authenticationType
 @see RKRequestAuthenticationType
 */
@property(nonatomic,retain) NSString *OAuth1ConsumerSecret;

/**
 The OAuth 1.0 access token
 
 Used to build an Authorization header wjem authenticationType is
 RKRequestAuthenticationTypeOAuth1
 
 @see authenticationType
 @see RKRequestAuthenticationType
 */
@property(nonatomic,retain) NSString *OAuth1AccessToken;

/**
 The OAuth 1.0 access token secret
 
 Used to build an Authorization header wjem authenticationType is
 RKRequestAuthenticationTypeOAuth1
 
 @see authenticationType
 @see RKRequestAuthenticationType
 */
@property(nonatomic,retain) NSString *OAuth1AccessTokenSecret;

/*** @name OAuth2 Secrets */

/**
 The OAuth 2.0 access token
 
 Used to build an Authorization header wjem authenticationType is
 RKRequestAuthenticationTypeOAuth2
 
 @see authenticationType
 @see RKRequestAuthenticationType
 */
@property(nonatomic,retain) NSString *OAuth2AccessToken;

/**
 The OAuth 2.0 refresh token. Used to retrieve a new access token before expiration
 
 Used to build an Authorization header wjem authenticationType is
 RKRequestAuthenticationTypeOAuth2
 
 @see authenticationType
 @see RKRequestAuthenticationType
 */
@property(nonatomic,retain) NSString *OAuth2RefreshToken;

/////////////////////////////////////////////////////////////////////////
/// @name Reachability &amp; Service Availability Alerting
/////////////////////////////////////////////////////////////////////////

/**
 An instance of RKReachabilityObserver used for determining the availability of 
 network access.
 
 Initialized using [RKReachabilityObserver reachabilityObserverForInternet] to monitor
 connectivity to the Internet. Can be changed to directly monitor a remote hostname/IP
 address or the local WiFi interface instead.
 
 Changing the reachability observer has the side-effect of temporarily suspending the
 requestQueue until reachability to the new host can be established.
 
 @see RKReachabilityObserver
 */
@property(nonatomic, retain) RKReachabilityObserver *reachabilityObserver;

/**
 The title to use in the alert shown when a request encounters a
 ServiceUnavailable (503) response.
 
 *Default*: _"Service Unavailable"_
 */
@property(nonatomic, retain) NSString *serviceUnavailableAlertTitle;

/**
 The message to use in the alert shown when a request encounters a
 ServiceUnavailable (503) response.
 
 *Default*: _"The remote resource is unavailable. Please try again later."_
 */
@property(nonatomic, retain) NSString *serviceUnavailableAlertMessage;

/**
 Flag that determines whether the Service Unavailable alert is shown in response
 to a ServiceUnavailable (503) response.
 
 *Default*: _NO_
 */
@property(nonatomic, assign) BOOL serviceUnavailableAlertEnabled;

/////////////////////////////////////////////////////////////////////////
/// @name Cacheing
/////////////////////////////////////////////////////////////////////////

/**
 An instance of the request cache used to store/load cacheable responses for requests
 sent through this client
 */
@property (nonatomic, retain) RKRequestCache *cache DEPRECATED_ATTRIBUTE;

/**
 An instance of the request cache used to store/load cacheable responses for requests
 sent through this client
 */
@property (nonatomic, retain) RKRequestCache *requestCache;

/**
 The default cache policy to apply for all requests sent through this client
 
 @see RKRequestCache
 */
@property (nonatomic, assign) RKRequestCachePolicy cachePolicy;

/**
 The path used to store response data for this client's request cache
 */
@property (nonatomic, readonly) NSString *cachePath;

/////////////////////////////////////////////////////////////////////////
/// @name Shared Client Instance
/////////////////////////////////////////////////////////////////////////

/**
 Return the shared instance of the client
 */
+ (RKClient *)sharedClient;

/**
 Set the shared instance of the client, releasing the current instance (if any)
 
 @param client An RKClient instance to configure as the new shared instance
 */
+ (void)setSharedClient:(RKClient *)client;

/////////////////////////////////////////////////////////////////////////
/// @name Initializing a Client
/////////////////////////////////////////////////////////////////////////

/**
 Return a client scoped to a particular base URL. If the singleton client is nil, the return client is set as the singleton
 
 @param baseURL The baseURL to set for the client. All requests will be relative to this base URL
 @see baseURL
 @return A configured RKClient instance ready to send requests
 */
+ (RKClient *)clientWithBaseURL:(NSString *)baseURL;

/**
 Return a Rest client scoped to a particular base URL with a set of HTTP AUTH credentials. 
 If the [singleton client]([RKClient sharedClient]) is nil, the client instantiated will become the singleton instance
 
 @param baseURL The baseURL to set for the client. All requests will be relative to this base URL
 @param username The username to use for HTTP Authentication challenges
 @param password The password to use for HTTP Authentication challenges
 @return A configured RKClient instance ready to send requests
 */
+ (RKClient *)clientWithBaseURL:(NSString *)baseURL username:(NSString *)username password:(NSString *)password;

/**
 Return a client scoped to a particular base URL. If the singleton client is nil, the return client is set as the singleton
 
 @param baseURL The baseURL to set for the client. All requests will be relative to this base URL
 @see baseURL
 @return A configured RKClient instance ready to send requests
 */
- (id)initWithBaseURL:(NSString *)baseURL;

/////////////////////////////////////////////////////////////////////////
/// @name Constructing Resource Paths and URLs
/////////////////////////////////////////////////////////////////////////

/**
 Returns a NSURL by adding a resource path to the base URL
 
 @param resourcePath The resource path to build a URL against
 @return An NSURL constructed by concatenating the baseURL and the resourcePath
 */
- (NSURL *)URLForResourcePath:(NSString *)resourcePath;

/**
 Returns an NSString by adding a resource path to the base URL
 
 @param resourcePath The resource path to build a URL against
 @return A string URL constructed by concatenating the baseURL and the resourcePath
 */
- (NSString *)URLPathForResourcePath:(NSString *)resourcePath;

/**
 Returns a resource path with a dictionary of query parameters URL encoded and appended
 
 This is a convenience method for constructing a new resource path that includes a query. For example,
 when given a resourcePath of /contacts and a dictionary of parameters containing foo=bar and color=red,
 will return /contacts?foo=bar&amp;color=red
 
 *NOTE* - Assumes that the resource path does not already contain any query parameters.
 
 @param resourcePath The resource path to append the query parameters onto
 @param queryParams A dictionary of query parameters to be URL encoded and appended to the resource path
 @return A new resource path with the query parameters appended
 
 @see RKPathAppendQueryParams()
 @deprecated Use RKPathAppendQueryParams instead
 */
- (NSString *)resourcePath:(NSString *)resourcePath withQueryParams:(NSDictionary *)queryParams DEPRECATED_ATTRIBUTE;

/**
 Returns a NSURL by adding a resource path to the base URL and appending a URL encoded set of query parameters
 
 This is a convenience method for constructing a new resource path that includes a query. For example,
 when given a resourcePath of /contacts and a dictionary of parameters containing foo=bar and color=red,
 will return /contacts?foo=bar&amp;color=red
 
 *NOTE* - Assumes that the resource path does not already contain any query parameters.
 
 @param resourcePath The resource path to append the query parameters onto
 @param queryParams A dictionary of query parameters to be URL encoded and appended to the resource path
 @return A URL constructed by concatenating the baseURL and the resourcePath with the query parameters appended
 */
- (NSURL *)URLForResourcePath:(NSString *)resourcePath queryParams:(NSDictionary *)queryParams;

/////////////////////////////////////////////////////////////////////////
/// @name Building Requests
/////////////////////////////////////////////////////////////////////////

/**
 Configures a request with the headers and authentication settings applied to this client
 
 @param request A request to apply the configuration to
 @see HTTPHeaders
 @see username
 @see password
 */
- (void)setupRequest:(RKRequest *)request;

/**
 Return a request object targetted at a resource path relative to the base URL. By default the method is set to GET
 All headers set on the client will automatically be applied to the request as well.
 
 @param resourcePath The resource path to configure the request for
 @param delegate A delegate to inform of events in the request lifecycle
 @return A fully configured RKRequest instance ready for sending
 @see RKRequestDelegate
 */
- (RKRequest *)requestWithResourcePath:(NSString *)resourcePath delegate:(NSObject<RKRequestDelegate> *)delegate;

///////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * These methods are provided as a convenience to cover the common asynchronous request tasks. All other request
 * needs should instantiate a request via requestWithResourcePath:delegate:callback and work with the RKRequest
 * object directly.
 *
 * @name Sending Asynchronous Requests
 */

/**
 Perform an asynchronous GET request for a resource and inform a delegate of the results
 
 @param resourcePath The resourcePath to target the request at
 @param delegate A delegate object to inform of the results
 @return The RKRequest object built and sent to the remote system
 */
- (RKRequest *)get:(NSString *)resourcePath delegate:(NSObject<RKRequestDelegate> *)delegate;

/**
 Fetch a resource via an HTTP GET with a dictionary of params
 
 Note that this request _only_ allows NSDictionary objects as the params. The dictionary will be coerced into a URL encoded
 string and then appended to the resourcePath as the query string of the request.
 
 @param resourcePath The resourcePath to target the request at
 @param queryParams A dictionary of query parameters to append to the resourcePath. Assumes that resourcePath does not contain a query string.
 @param delegate A delegate object to inform of the results
 @return The RKRequest object built and sent to the remote system
 */
- (RKRequest *)get:(NSString *)resourcePath queryParams:(NSDictionary *)queryParams delegate:(NSObject<RKRequestDelegate> *)delegate;

/**
 Create a resource via an HTTP POST with a set of form parameters
 
 @param resourcePath The resourcePath to target the request at
 @param params A RKRequestSerializable object to use as the body of the request
 @param delegate A delegate object to inform of the results
 @return The RKRequest object built and sent to the remote system
 @see RKRequestSerializable
 */
- (RKRequest *)post:(NSString *)resourcePath params:(NSObject<RKRequestSerializable> *)params delegate:(NSObject<RKRequestDelegate> *)delegate;

/**
 Update a resource via an HTTP PUT
 
 @param resourcePath The resourcePath to target the request at
 @param params A RKRequestSerializable object to use as the body of the request
 @param delegate A delegate object to inform of the results
 @return The RKRequest object built and sent to the remote system
 @see RKRequestSerializable
 */
- (RKRequest *)put:(NSString *)resourcePath params:(NSObject<RKRequestSerializable> *)params delegate:(NSObject<RKRequestDelegate> *)delegate;

/**
 Destroy a resource via an HTTP DELETE
 
 @param resourcePath The resourcePath to target the request at
 @param delegate A delegate object to inform of the results
 @return The RKRequest object built and sent to the remote system
 */
- (RKRequest *)delete:(NSString *)resourcePath delegate:(NSObject<RKRequestDelegate> *)delegate;

@end
