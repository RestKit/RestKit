//
//  RKHTTPUtilities.h
//  RestKit
//
//  Created by Blake Watters on 8/24/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
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

#ifdef __cplusplus
extern "C" {
#endif

/**
 HTTP methods for requests
 */
typedef NS_OPTIONS(NSInteger, RKRequestMethod) {
    RKRequestMethodGET          = 1 << 0,
    RKRequestMethodPOST         = 1 << 1,
    RKRequestMethodPUT          = 1 << 2,
    RKRequestMethodDELETE       = 1 << 3,
    RKRequestMethodHEAD         = 1 << 4,
    RKRequestMethodPATCH        = 1 << 5,
    RKRequestMethodOPTIONS      = 1 << 6,
    RKRequestMethodAny          = (RKRequestMethodGET |
                                   RKRequestMethodPOST |
                                   RKRequestMethodPUT |
                                   RKRequestMethodDELETE |
                                   RKRequestMethodHEAD |
                                   RKRequestMethodPATCH |
                                   RKRequestMethodOPTIONS)
};

/**
 Returns YES if the given HTTP request method is an exact match of the RKRequestMethod enum, and NO if it's a bit mask combination.
 */
BOOL RKIsSpecificRequestMethod(RKRequestMethod method);

/**
 Returns the corresponding string for value for a given HTTP request method.
 
 For example, given `RKRequestMethodGET` would return `@"GET"`.
 
 @param method The request method to return the corresponding string value for. The given request method must be specific.
 */
NSString *RKStringFromRequestMethod(RKRequestMethod method);

/**
 Returns the corresponding request method value for a given string.
 
 For example, given `@"PUT"` would return `@"RKRequestMethodPUT"`
 */
RKRequestMethod RKRequestMethodFromString(NSString *);

/**
 The HTTP status code classes

 See http://tools.ietf.org/html/rfc2616#section-10
 */
typedef NS_ENUM(NSUInteger, RKStatusCodeClass) {
    RKStatusCodeClassInformational  = 100,
    RKStatusCodeClassSuccessful     = 200,
    RKStatusCodeClassRedirection    = 300,
    RKStatusCodeClassClientError    = 400,
    RKStatusCodeClassServerError    = 500
};

/**
 Creates a new range covering the status codes in the given class.

 @param statusCodeClass The status code class to create a range covering.
 @return A new range covering the status codes in the given class.
 */
NSRange RKStatusCodeRangeForClass(RKStatusCodeClass statusCodeClass);

/**
 Creates a new index set covering the status codes in the given class.

 @param statusCodeClass The status code class to create an index set covering.
 @return A new index set covering the status codes in the given class.
 */
NSIndexSet *RKStatusCodeIndexSetForClass(RKStatusCodeClass statusCodeClass);

/**
 Creates and returns a new index set including all HTTP response status codes that are cacheable.

 @return A new index set containing all cacheable status codes.
 */
NSIndexSet *RKCacheableStatusCodes(void);

/**
 Returns string representation of a given HTTP status code.
 
 The list of supported status codes was built from http://en.wikipedia.org/wiki/List_of_HTTP_status_codes
 
 @param statusCode The HTTP status code to return a string from.
 @return A string representation of the given status code.
 */
NSString *RKStringFromStatusCode(NSInteger statusCode);

/**
 Parse HTTP Date: http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.3.1
 */
NSDate *RKDateFromHTTPDateString(NSString *);

/**
 Returns the cache expiration data from a dictionary of HTTP response headers as appropriate for the given status code. If the status code is not cachable, `nil` is returned.
 
 @param headers The HTTP response headers from which to extract the cache expiration date.
 @param statusCode The HTTP response status code of the response.
 @return The expiration date as specified by the cache headers or `nil` if none was found.
 */
NSDate *RKHTTPCacheExpirationDateFromHeadersWithStatusCode(NSDictionary *headers, NSInteger statusCode);

/**
 Returns a Boolean value that indicates if a given URL is relative to another URL.

 This method does not rely on the `baseURL` method of `NSURL` as it only indicates a relationship between the initialization of two URL objects. The relativity of the given URL is assessed by evaluating a prefix match of the URL's absolute string value with the absolute string value of the potential base URL.

 @param URL The URL to assess the relativity of.
 @param baseURL The base URL to determine if the given URL is relative to.
 @return `YES` is URL is relative to the base URL, else `NO`.
 */
BOOL RKURLIsRelativeToURL(NSURL *URL, NSURL *baseURL);

/**
 Returns a string object containing the relative path and query string of a given URL object and a base URL that the given URL is relative to.

 If the given URL is found not to be relative to the baseURL, `nil` is returned.

 @param URL The URL to retrieve the relative path and query string of.
 @param baseURL The base URL to be omitted from the returned path and query string.
 @return A string containing the relative path and query parameters.
 */
NSString *RKPathAndQueryStringFromURLRelativeToURL(NSURL *URL, NSURL *baseURL);

/**
 *  Returns an index set of the status codes with optional response bodies
 *
 *  @return An index set of the status codes with optional response bodies
 */
NSIndexSet *RKStatusCodesOfResponsesWithOptionalBodies(void);

#ifdef __cplusplus
}
#endif
