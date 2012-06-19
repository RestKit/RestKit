//
//  RKResponse.h
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

#import <Foundation/Foundation.h>
#import "RKRequest.h"

/**
 Models the response portion of an HTTP request/response cycle
 */
@interface RKResponse : NSObject {
    NSHTTPURLResponse *_httpURLResponse;
    NSMutableData *_body;
    BOOL _loading;
    NSDictionary *_responseHeaders;
}


///-----------------------------------------------------------------------------
/// @name Creating a Response
///-----------------------------------------------------------------------------

/**
 Initializes a new response object for a REST request.

 @param request The request that the response being created belongs to.
 @return An RKResponse object with the request parameter set.
 */
- (id)initWithRequest:(RKRequest *)request;

/**
 Initializes a new response object from a cached request.

 @param request The request that the response being created belongs to.
 @param body The data of the body of the response.
 @param headers A dictionary of the response's headers.
 @return An RKResponse object with the request, body, and header parameters set.
 */
- (id)initWithRequest:(RKRequest *)request body:(NSData *)body headers:(NSDictionary *)headers;

/**
 Initializes a response object from the results of a synchronous request.

 @param request The request that the response being created belongs to.
 @param URLResponse The response from the NSURLConnection call containing the
 headers and HTTP status code.
 @param body The data of the body of the response.
 @param error The error returned from the NSURLConnection call, if any.
 @return An RKResponse object with the results of the synchronous request
 derived from the NSHTTPURLResponse and body passed.
 */
- (id)initWithSynchronousRequest:(RKRequest *)request URLResponse:(NSHTTPURLResponse *)URLResponse body:(NSData *)body error:(NSError *)error;


///-----------------------------------------------------------------------------
/// @name Accessing the Request
///-----------------------------------------------------------------------------

/**
 The request that generated this response.
 */
@property (nonatomic, assign, readonly) RKRequest *request;

/**
 The URL the response was loaded from.
 */
@property (nonatomic, readonly) NSURL *URL;


///-----------------------------------------------------------------------------
/// @name Accessing the Response Components
///-----------------------------------------------------------------------------

/**
 The status code of the HTTP response.
 */
@property (nonatomic, readonly) NSInteger statusCode;

/**
 Return a dictionary of headers sent with the HTTP response.
 */
@property (nonatomic, readonly) NSDictionary *allHeaderFields;

/**
 An NSArray of NSHTTPCookie objects associated with the response.
 */
@property (nonatomic, readonly) NSArray *cookies;

/**
 Returns the localized human readable representation of the HTTP Status Code
 returned.
 */
- (NSString *)localizedStatusCodeString;


///-----------------------------------------------------------------------------
/// @name Accessing Common Headers
///-----------------------------------------------------------------------------

/**
 Returns the value of 'Content-Type' HTTP header
 */
- (NSString *)contentType;

/**
 Returns the value of the 'Content-Length' HTTP header
 */
- (NSString *)contentLength;

/**
 Returns the value of the 'Location' HTTP Header
 */
- (NSString *)location;


///-----------------------------------------------------------------------------
/// @name Reading the Body Content
///-----------------------------------------------------------------------------

/**
 The data returned as the response body.
 */
@property (nonatomic, readonly) NSData *body;

/**
 Returns the response body as an NSString
 */
- (NSString *)bodyAsString;

/**
 Returns the response body parsed as JSON into an object
 @bug **DEPRECATED** in v0.10.0
 */
- (id)bodyAsJSON DEPRECATED_ATTRIBUTE;

/**
 Returns the response body parsed as JSON into an object

 @param error An NSError to populate if something goes wrong while parsing the
 body JSON into an object.
 */
- (id)parsedBody:(NSError **)error;


///-----------------------------------------------------------------------------
/// @name Handling Errors
///-----------------------------------------------------------------------------

/**
 The error returned if the URL connection fails.
 */
@property (nonatomic, readonly) NSError *failureError;

/**
 Determines if there is an error object and uses it's localized message

 @return A string of the localized error message.
 */
- (NSString *)failureErrorDescription;

/**
 Indicates whether the response was loaded from RKCache

 @return YES if the response was loaded from the cache
 */
- (BOOL)wasLoadedFromCache;


///-----------------------------------------------------------------------------
/// @name Determining the Status Range of the Response
///-----------------------------------------------------------------------------

/**
 Indicates that the connection failed to reach the remote server. The details of
 the failure are available on the failureError reader.

 @return YES if the connection failed to reach the remote server.
 */
- (BOOL)isFailure;

/**
 Indicates an invalid HTTP response code less than 100 or greater than 600

 @return YES if the HTTP response code is less than 100 or greater than 600
 */
- (BOOL)isInvalid;

/**
 Indicates an informational HTTP response code between 100 and 199

 @return YES if the HTTP response code is between 100 and 199
 */
- (BOOL)isInformational;

/**
 Indicates an HTTP response code between 200 and 299.

 Confirms that the server received, understood, accepted and processed the
 request successfully.

 @return YES if the HTTP response code is between 200 and 299
 */
- (BOOL)isSuccessful;

/**
 Indicates an HTTP response code between 300 and 399.

 This class of status code indicates that further action needs to be taken by
 the user agent in order to fulfil the request. The action required may be
 carried out by the user agent without interaction with the user if and only if
 the method used in the second request is GET or HEAD.

 @return YES if the HTTP response code is between 300 and 399.
 */
- (BOOL)isRedirection;

/**
 Indicates an HTTP response code between 400 and 499.

 This status code is indented for cases in which the client seems to have erred.

 @return YES if the HTTP response code is between 400 and 499.
 */
- (BOOL)isClientError;

/**
 Indicates an HTTP response code between 500 and 599.

 This state code occurs when the server failed to fulfill an apparently valid
 request.

 @return YES if the HTTP response code is between 500 and 599.
 */
- (BOOL)isServerError;


///-----------------------------------------------------------------------------
/// @name Determining Specific Statuses
///-----------------------------------------------------------------------------

/**
 Indicates that the response is either a server or a client error.

 @return YES if the response is either a server or client error, with a response
 code between 400 and 599.
 */
- (BOOL)isError;

/**
 Indicates an HTTP response code of 200.

 @return YES if the response is 200 OK.
 */
- (BOOL)isOK;

/**
 Indicates an HTTP response code of 201.

 @return YES if the response is 201 Created.
 */
- (BOOL)isCreated;

/**
 Indicates an HTTP response code of 204.

 @return YES if the response is 204 No Content.
 */
- (BOOL)isNoContent;

/**
 Indicates an HTTP response code of 304.

 @return YES if the response is 304 Not Modified.
 */
- (BOOL)isNotModified;

/**
 Indicates an HTTP response code of 401.

 @return YES if the response is 401 Unauthorized.
 */
- (BOOL)isUnauthorized;

/**
 Indicates an HTTP response code of 403.

 @return YES if the response is 403 Forbidden.
 */
- (BOOL)isForbidden;

/**
 Indicates an HTTP response code of 404.

 @return YES if the response is 404 Not Found.
 */
- (BOOL)isNotFound;

/**
 Indicates an HTTP response code of 409.

 @return YES if the response is 409 Conflict.
 */
- (BOOL)isConflict;

/**
 Indicates an HTTP response code of 410.

 @return YES if the response is 410 Gone.
 */
- (BOOL)isGone;

/**
 Indicates an HTTP response code of 422.

 @return YES if the response is 422 Unprocessable Entity.
 */
- (BOOL)isUnprocessableEntity;

/**
 Indicates an HTTP response code of 301, 302, 303 or 307.

 @return YES if the response requires a redirect to finish processing.
 */
- (BOOL)isRedirect;

/**
 Indicates an empty HTTP response code of 201, 204, or 304

 @return YES if the response body is empty.
 */
- (BOOL)isEmpty;

/**
 Indicates an HTTP response code of 503

 @return YES if the response is 503 Service Unavailable.
 */
- (BOOL)isServiceUnavailable;


///-----------------------------------------------------------------------------
/// @name Accessing the Response's MIME Type and Encoding
///-----------------------------------------------------------------------------

/**
 The MIME Type of the response body.
 */
@property (nonatomic, readonly) NSString *MIMEType;

/**
 True when the server turned an HTML response.

 @return YES when the MIME type is text/html.
 */
- (BOOL)isHTML;

/**
 True when the server turned an XHTML response

 @return YES when the MIME type is application/xhtml+xml.
 */
- (BOOL)isXHTML;

/**
 True when the server turned an XML response

 @return YES when the MIME type is application/xml.
 */
- (BOOL)isXML;

/**
 True when the server turned an JSON response

 @return YES when the MIME type is application/json.
 */
- (BOOL)isJSON;

/**
 Returns the name of the string encoding used for the response body
 */
- (NSString *)bodyEncodingName;

/**
 Returns the string encoding used for the response body
 */
- (NSStringEncoding)bodyEncoding;

@end
