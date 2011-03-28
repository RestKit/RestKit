//
//  RKClient.h
//  RestKit
//
//  Created by Blake Watters on 7/28/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "RKRequest.h"
#import "RKParams.h"
#import "RKResponse.h"
#import "NSDictionary+RKRequestSerialization.h"
#import "RKReachabilityObserver.h"

/////////////////////////////////////////////////////////////////////////

/**
 * URL & URL Path Convenience methods
 */

/**
 * Returns an NSURL with the specified resource path appended to the base URL
 * that the shared RKClient instance is configured with
 *
 * Shortcut for calling [[RKClient sharedClient] URLForResourcePath:@"/some/path"]
 */
NSURL* RKMakeURL(NSString* resourcePath);

/**
 * Returns an NSString with the specified resource path appended to the base URL
 * that the shared RKClient instance is configured with
 *
 * Shortcut for calling [[RKClient sharedClient] URLPathForResourcePath:@"/some/path"]
 */
NSString* RKMakeURLPath(NSString* resourcePath);

/**
 * Convenience method for generating a path against the properties of an object. Takes
 * a string with property names encoded in parentheses and interpolates the values of
 * the properties specified and returns the generated path.
 *
 * For example, given an 'article' object with an 'articleID' property of 12345
 * RKMakePathWithObject(@"articles/(articleID)", article) would generate @"articles/12345"
 *
 * This functionality is the basis for resource path generation in the Router.
 */
NSString* RKMakePathWithObject(NSString* path, id object);

/////////////////////////////////////////////////////////////////////////

/**
 * RKClient exposes the low level client interface for working
 * with HTTP servers and RESTful services. It wraps the request/response
 * cycle with a clean, simple interface.
 */
@interface RKClient : NSObject {
	NSString* _baseURL;
	NSString* _username;
	NSString* _password;
	NSMutableDictionary* _HTTPHeaders;
	RKReachabilityObserver* _baseURLReachabilityObserver;
	NSString* _serviceUnavailableAlertTitle;
	NSString* _serviceUnavailableAlertMessage;
	BOOL _serviceUnavailableAlertEnabled;
}

/**
 * The base URL all resources are nested underneath
 */
@property(nonatomic, retain) NSString* baseURL;

/**
 * The username to use for authentication via HTTP AUTH
 */
@property(nonatomic, retain) NSString* username;

/**
 * The password to use for authentication via HTTP AUTH
 */
@property(nonatomic, retain) NSString* password;

/**
 * A dictionary of headers to be sent with each request
 */
@property(nonatomic, readonly) NSDictionary* HTTPHeaders;

/**
 * The RKReachabilityObserver used to monitor whether or not the client has a connection
 * path to the baseURL
 */
@property(nonatomic, readonly) RKReachabilityObserver* baseURLReachabilityObserver;

/**
 * The title to use in the UIAlertView shown when a request encounters a
 * ServiceUnavailable (503) response.
 * If not provided, the default is: "Service Unavailable"
 */
@property(nonatomic, retain) NSString* serviceUnavailableAlertTitle;

/**
 * The message to use in the UIAlertView shown when a request encounters a
 * ServiceUnavailable (503) response.
 * If not provided, the default is: "The remote resource is unavailable. Please try again later."
 */
@property(nonatomic, retain) NSString* serviceUnavailableAlertMessage;

/**
 * Flag that determines whether the Service Unavailable alert is shown in response
 * to a ServiceUnavailable (503) response.
 * Defaults to NO.
 */
@property(nonatomic, assign) BOOL serviceUnavailableAlertEnabled;

/**
 * Return the configured singleton instance of the Rest client
 */
+ (RKClient*)sharedClient;

/**
 * Set the shared singleton issue of the Rest client
 */
+ (void)setSharedClient:(RKClient*)client;

/**
 * Return a Rest client scoped to a particular base URL. If the singleton client is nil, the return client is set as the singleton
 */
+ (RKClient*)clientWithBaseURL:(NSString*)baseURL;

/**
 * Return a Rest client scoped to a particular base URL with a set of HTTP AUTH credentials. If the singleton client is nil, the return client is set as the singleton
 */
+ (RKClient*)clientWithBaseURL:(NSString*)baseURL username:(NSString*)username password:(NSString*)password;

/**
 *  Will check for network connectivity (to google.com)
 */
- (BOOL)isNetworkAvailable;

/**
 * Adds an HTTP header to each request dispatched through the Rest client
 */
- (void)setValue:(NSString*)value forHTTPHeaderField:(NSString*)header;

/**
 * Returns a resource path with a dictionary of query parameters URL encoded and appended
 */
// TODO: Move this to a function instead of an RKClient method
- (NSString*)resourcePath:(NSString*)resourcePath withQueryParams:(NSDictionary*)queryParams;

/**
 * Returns a NSURL by adding a resource path to the base URL
 */
- (NSURL*)URLForResourcePath:(NSString*)resourcePath;

/**
 * Returns an NSString by adding a resource path to the base URL
 */
- (NSString*)URLPathForResourcePath:(NSString*)resourcePath;

/**
 * Returns a NSURL by adding a resource path to the base URL and appending a URL encoded set of query parameters
 */
- (NSURL*)URLForResourcePath:(NSString *)resourcePath queryParams:(NSDictionary*)queryParams;

- (void)setupRequest:(RKRequest*)request;

/**
 * Return a request object targetted at a resource path relative to the base URL. By default the method is set to GET
 * All headers set on the client will automatically be applied to the request as well.
 */
- (RKRequest*)requestWithResourcePath:(NSString*)resourcePath delegate:(id)delegate;

///////////////////////////////////////////////////////////////////////////////////////////////////////////
// Asynchronous Helper Methods
///////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * These methods are provided as a convenience to cover the common asynchronous request tasks. All other request
 * needs should instantiate a request via requestWithResourcePath:delegate:callback and work with the RKRequest
 * object directly.
 */

/**
 * Fetch a resource via an HTTP GET
 */
- (RKRequest*)get:(NSString*)resourcePath delegate:(NSObject<RKRequestDelegate>*)delegate;

/**
 * Fetch a resource via an HTTP GET with a dictionary of params
 *
 * Note that this request _only_ allows NSDictionary objects as the params. The dictionary will be coerced into a URL encoded
 * string and then appended to the resourcePath as the query string of the request.
 */
- (RKRequest*)get:(NSString*)resourcePath queryParams:(NSDictionary*)queryParams delegate:(NSObject<RKRequestDelegate>*)delegate;

/**
 * Create a resource via an HTTP POST with a set of form parameters
 */
- (RKRequest*)post:(NSString*)resourcePath params:(NSObject<RKRequestSerializable>*)params delegate:(NSObject<RKRequestDelegate>*)delegate;

/**
 * Update a resource via an HTTP PUT
 */
- (RKRequest*)put:(NSString*)resourcePath params:(NSObject<RKRequestSerializable>*)params delegate:(NSObject<RKRequestDelegate>*)delegate;

/**
 * Destroy a resource via an HTTP DELETE
 */
- (RKRequest*)delete:(NSString*)resourcePath delegate:(NSObject<RKRequestDelegate>*)delegate;

@end
