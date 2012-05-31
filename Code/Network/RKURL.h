//
//  RKURL.h
//  RestKit
//
//  Created by Jeff Arena on 10/18/10.
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

/**
 RKURL extends the Cocoa NSURL base class to provide support for the concepts of
 base URL and resource path that are used extensively throughout the RestKit
 framework. RKURL is immutable, but provides numerous methods for constructing
 new RKURL instances where the received becomes the baseURL of the RKURL
 instance.

 Instances of RKURL are aware of:

 - the baseURL they were constructed against, if any
 - the resource path that was appended to that baseURL
 - any query parameters present in the URL

 ### Example

    NSDictionary *queryParams;
    queryParams = [NSDictionary dictionaryWithObjectsAndKeys:@"pitbull", @"username",
                                                             @"pickles", @"password", nil];

    RKURL *URL = [RKURL URLWithBaseURLString:@"http://restkit.org"
                                resourcePath:@"/test"
                             queryParameters:queryParams];
 */
@interface RKURL : NSURL

///-----------------------------------------------------------------------------
/// @name Creating an RKURL
///-----------------------------------------------------------------------------

/**
 Creates and returns an RKURL object intialized with a provided base URL.

 @param baseURL The URL object with which to initialize the RKURL object.
 @return An RKURL object initialized with baseURL.
 */
+ (id)URLWithBaseURL:(NSURL *)baseURL;

/**
 Creates and returns an RKURL object intialized with a provided base URL and
 resource path.

 @param baseURL The URL object with which to initialize the RKURL object.
 @param resourcePath The resource path for the RKURL object.
 @return An RKURL object initialized with baseURL and resourcePath.
 */
+ (id)URLWithBaseURL:(NSURL *)baseURL resourcePath:(NSString *)resourcePath;

/**
 Creates and returns an RKURL object intialized with a provided base URL,
 resource path, and a dictionary of query parameters.

 @param baseURL The URL object with which to initialize the RKURL object.
 @param resourcePath The resource path for the RKURL object.
 @param queryParameters The query parameters for the RKURL object.
 @return An RKURL object initialized with baseURL, resourcePath, and
 queryParameters.
 */
+ (id)URLWithBaseURL:(NSURL *)baseURL resourcePath:(NSString *)resourcePath queryParameters:(NSDictionary *)queryParameters;

/**
 Creates and returns an RKURL object intialized with a base URL constructed from
 the specified base URL string.

 @param baseURLString The string with which to initialize the RKURL object.
 @return An RKURL object initialized with baseURLString.
 */
+ (id)URLWithBaseURLString:(NSString *)baseURLString;

/**
 Creates and returns an RKURL object intialized with a base URL constructed from
 the specified base URL string and resource path.

 @param baseURLString The string with which to initialize the RKURL object.
 @param resourcePath The resource path for the RKURL object.
 @return An RKURL object initialized with baseURLString and resourcePath.
 */
+ (id)URLWithBaseURLString:(NSString *)baseURLString resourcePath:(NSString *)resourcePath;

/**
 Creates and returns an RKURL object intialized with a base URL constructed from
 the specified base URL string, resource path and a dictionary of query
 parameters.

 @param baseURLString The string with which to initialize the RKURL object.
 @param resourcePath The resource path for the RKURL object.
 @param queryParameters The query parameters for the RKURL object.
 @return An RKURL object initialized with baseURLString, resourcePath and
 queryParameters.
 */
+ (id)URLWithBaseURLString:(NSString *)baseURLString resourcePath:(NSString *)resourcePath queryParameters:(NSDictionary *)queryParameters;

/**
 Initializes an RKURL object with a base URL, a resource path string, and a
 dictionary of query parameters.

 `initWithBaseURL:resourcePath:queryParameters:` is the designated initializer.

 @param theBaseURL The NSURL with which to initialize the RKURL object.
 @param theResourcePath The resource path for the RKURL object.
 @param theQueryParameters The query parameters for the RKURL object.
 @return An RKURL object initialized with baseURL, resourcePath and queryParameters.
 */
- (id)initWithBaseURL:(NSURL *)theBaseURL resourcePath:(NSString *)theResourcePath queryParameters:(NSDictionary *)theQueryParameters;


///-----------------------------------------------------------------------------
/// @name Accessing the URL parts
///-----------------------------------------------------------------------------

/**
 Returns the base URL of the receiver.

 The base URL includes everything up to the resource path, typically the portion
 that is repeated in every API call.
 */
@property (nonatomic, copy, readonly) NSURL *baseURL;

/**
 Returns the resource path of the receiver.

 The resource path is the path portion of the complete URL beyond that contained
 in the baseURL.
 */
@property (nonatomic, copy, readonly) NSString *resourcePath;

/**
 Returns the query component of a URL conforming to RFC 1808 as a dictionary.

 If the receiver does not conform to RFC 1808, returns nil just as
 `NSURL query` does.
 */
@property (nonatomic, readonly) NSDictionary *queryParameters;


///-----------------------------------------------------------------------------
/// @name Modifying the URL
///-----------------------------------------------------------------------------

/**
 Returns a new RKURL object with a new resource path appended to its path.

 @param theResourcePath The resource path to append to the receiver's path.
 @return A new RKURL that refers to a new resource at theResourcePath.
 */
- (RKURL *)URLByAppendingResourcePath:(NSString *)theResourcePath;

/**
 Returns a new RKURL object with a new resource path appended to its path and a
 dictionary of query parameters merged with the existing query component.

 @param theResourcePath The resource path to append to the receiver's path.
 @param theQueryParameters A dictionary of query parameters to merge with any
 existing query parameters.
 @return A new RKURL that refers to a new resource at theResourcePath with a new
 query component including the values from theQueryParameters.
 */
- (RKURL *)URLByAppendingResourcePath:(NSString *)theResourcePath queryParameters:(NSDictionary *)theQueryParameters;

/**
 Returns a new RKURL object with a dictionary of query parameters merged with
 the existing query component.

 @param theQueryParameters A dictionary of query parameters to merge with any
 existing query parameters.
 @return A new RKURL that refers to the same resource as the receiver with a new
 query component including the values from theQueryParameters.
 */
- (RKURL *)URLByAppendingQueryParameters:(NSDictionary *)theQueryParameters;

/**
 Returns a new RKURL object with the baseURL of the receiver and a new
 resourcePath.

 @param newResourcePath The resource path to replace the value of resourcePath
 in the new RKURL object.
 @return An RKURL object with newResourcePath appended to the receiver's baseURL.
 */
- (RKURL *)URLByReplacingResourcePath:(NSString *)newResourcePath;

/**
 Returns a new RKURL object with its resource path processed as a pattern and
 evaluated against the specified object.

 Resource paths may contain pattern strings prefixed by colons (":") that refer
 to key-value coding accessible properties on the provided object.

 For example:

    // Given an RKURL initialized as:
    RKURL *myURL = [RKURL URLWithBaseURLString:@"http://restkit.org"
                                resourcePath:@"/paginate?per_page=:perPage&page=:page"];

    // And a dictionary containing values:
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"25", @"perPage",
                                                                          @"5", @"page", nil];

    // A new RKURL can be constructed by interpolating the dictionary with the original URL
    RKURL *interpolatedURL = [myURL URLByInterpolatingResourcePathWithObject:dictionary];

 The absoluteString of this new URL would be:
 `http://restkit.org/paginate?per_page=25&page=5`

 @see RKPathMatcher

 @param object The object to call methods on for the pattern strings in the
 resource path.
 @return A new RKURL object with its resource path evaluated as a pattern and
 interpolated with properties of object.
 */
- (RKURL *)URLByInterpolatingResourcePathWithObject:(id)object;

@end
