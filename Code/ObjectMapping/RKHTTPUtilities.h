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

/**
 HTTP methods for requests
 */
typedef enum RKRequestMethod {
    RKRequestMethodInvalid = -1,
    RKRequestMethodGET,
    RKRequestMethodPOST,
    RKRequestMethodPUT,
    RKRequestMethodDELETE,
    RKRequestMethodHEAD,
    RKRequestMethodPATCH,
    RKRequestMethodOPTIONS
} RKRequestMethod;  // RKHTTPMethod? RKStringFromHTTPMethod... RKHTTPMethodFromString

/**
 Returns the corresponding string for value for a given HTTP request method.
 
 For example, given `RKRequestMethodGET` would return `@"GET"`.
 */
NSString * RKStringFromRequestMethod(RKRequestMethod);

/**
 Returns the corresponding request method value for a given string.
 
 For example, given `@"PUT"` would return `@"RKRequestMethodPUT"`
 */
RKRequestMethod RKRequestMethodFromString(NSString *);

/**
 The HTTP status code classes

 See http://tools.ietf.org/html/rfc2616#section-10
 */
enum {
    RKStatusCodeClassInformational  = 100,
    RKStatusCodeClassSuccessful     = 200,
    RKStatusCodeClassRedirection    = 300,
    RKStatusCodeClassClientError    = 400,
    RKStatusCodeClassServerError    = 500
};
typedef NSUInteger RKStatusCodeClass;

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

// TODO: Implement these guys...
//NSString * RKStringFromStatusCode(NSInteger statusCode);
//NSInteger RKStatusCodeFromString(NSString *statusCode);

/*
 * Parse HTTP Date: http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.3.1
 */
NSDate *RKDateFromHTTPDateString(NSString *);
NSDate *RKHTTPCacheExpirationDateFromHeadersWithStatusCode(NSDictionary *headers, NSInteger statusCode);
