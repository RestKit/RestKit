//
//  RKResponse.h
//  RestKit
//
//  Created by Blake Watters on 7/28/09.
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

#import <Foundation/Foundation.h>
#import "RKRequest.h"

/**
 Models the response portion of an HTTP request/response cycle.
 */
@interface RKResponse : NSObject {
	RKRequest* _request;
	NSHTTPURLResponse* _httpURLResponse;
	NSMutableData* _body;
	NSError* _failureError;
	BOOL _loading;
	NSDictionary* _responseHeaders;
}

/**
 * The request that generated this response
 */
@property(nonatomic, readonly) RKRequest* request;

/**
 * The URL the response was loaded from
 */
@property(nonatomic, readonly) NSURL* URL;

/**
 * The MIME Type of the response body
 */
@property(nonatomic, readonly) NSString* MIMEType;

/**
 * The status code of the HTTP response
 */
@property(nonatomic, readonly) NSInteger statusCode;

/**
 * Return a dictionary of headers sent with the HTTP response
 */
@property(nonatomic, readonly) NSDictionary* allHeaderFields;

/**
 * The data returned as the response body
 */
@property(nonatomic, readonly) NSData* body;

/**
 * The error returned if the URL connection fails
 */
@property(nonatomic, readonly) NSError* failureError;

/**
 * An NSArray of NSHTTPCookie objects associated with the response
 */
@property(nonatomic, readonly) NSArray* cookies;

/**
 * Initialize a new response object for a REST request
 */
- (id)initWithRequest:(RKRequest*)request;

/**
 * Initialize a new response object from a cached request
 */
- (id)initWithRequest:(RKRequest*)request body:(NSData*)body headers:(NSDictionary*)headers;

/**
 * Initializes a response object from the results of a synchronous request
 */
- (id)initWithSynchronousRequest:(RKRequest*)request URLResponse:(NSHTTPURLResponse*)URLResponse body:(NSData*)body error:(NSError*)error;

/**
 * Return the localized human readable representation of the HTTP Status Code returned
 */
- (NSString*)localizedStatusCodeString;

/**
 * Return the response body as an NSString
 */
- (NSString*)bodyAsString;

/**
 * Return the response body parsed as JSON into an object
 * @deprecated in version 2.0
 */
- (id)bodyAsJSON DEPRECATED_ATTRIBUTE;

/**
 * Return the response body parsed as JSON into an object
 */
- (id)parsedBody:(NSError**)error;

/**
 * Will determine if there is an error object and use it's localized message
 */
- (NSString*)failureErrorDescription;

/**
 * Indicates whether the response was loaded from RKCache
 */
- (BOOL)wasLoadedFromCache;

/**
 * Indicates that the connection failed to reach the remote server. The details of the failure
 * are available on the failureError reader.
 */
- (BOOL)isFailure;

/**
 * Indicates an invalid HTTP response code less than 100 or greater than 600
 */
- (BOOL)isInvalid;

/**
 * Indicates an HTTP response code between 100 and 199
 */
- (BOOL)isInformational;

/**
 * Indicates an HTTP response code between 200 and 299
 */
- (BOOL)isSuccessful;

/**
 * Indicates an HTTP response code between 300 and 399
 */
- (BOOL)isRedirection;

/**
 * Indicates an HTTP response code between 400 and 499
 */
- (BOOL)isClientError;

/**
 * Indicates an HTTP response code between 500 and 599
 */
- (BOOL)isServerError;

/**
 * Indicates that the response is either a server or a client error
 */
- (BOOL)isError;

/**
 * Indicates an HTTP response code of 200
 */
- (BOOL)isOK;

/**
 * Indicates an HTTP response code of 201
 */
- (BOOL)isCreated;

/**
 * Indicates an HTTP response code of 204
 */
- (BOOL)isNoContent;

/**
 * Indicates an HTTP response code of 304
 */
- (BOOL)isNotModified;

/**
 * Indicates an HTTP response code of 401
 */
- (BOOL)isUnauthorized;

/**
 * Indicates an HTTP response code of 403
 */
- (BOOL)isForbidden;

/**
 * Indicates an HTTP response code of 404
 */
- (BOOL)isNotFound;

/**
 * Indicates an HTTP response code of 409
 */
- (BOOL)isConflict;

/**
 * Indicates an HTTP response code of 410
 */
- (BOOL)isGone;

/**
 * Indicates an HTTP response code of 422
 */
- (BOOL)isUnprocessableEntity;

/**
 * Indicates an HTTP response code of 301, 302, 303 or 307
 */
- (BOOL)isRedirect;

/**
 * Indicates an empty HTTP response code of 201, 204, or 304
 */
- (BOOL)isEmpty;

/**
 * Indicates an HTTP response code of 503
 */
- (BOOL)isServiceUnavailable;

/**
 * Returns the value of 'Content-Type' HTTP header
 */
- (NSString*)contentType;

/**
 * Returns the value of the 'Content-Length' HTTP header
 */
- (NSString*)contentLength;

/**
 * Returns the value of the 'Location' HTTP Header
 */
- (NSString*)location;

/**
 * True when the server turned an HTML response (MIME type is text/html)
 */
- (BOOL)isHTML;

/**
 * True when the server turned an XHTML response (MIME type is application/xhtml+xml)
 */
- (BOOL)isXHTML;

/**
 * True when the server turned an XML response (MIME type is application/xml)
 */
- (BOOL)isXML;

/**
 * True when the server turned an JSON response (MIME type is application/json)
 */
- (BOOL)isJSON;

@end
