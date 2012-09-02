//
//  RKHTTPUtilities.h
//  RestKit
//
//  Created by Blake Watters on 8/24/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
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
    RKRequestMethodPATCH
} RKRequestMethod;

NSString *RKStringFromRequestMethod(RKRequestMethod);
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
NSIndexSet * RKStatusCodeIndexSetForClass(RKStatusCodeClass statusCodeClass);

// TODO: Implement these guys...
//NSString * RKStringFromStatusCode(NSInteger statusCode);
//NSInteger RKStatusCodeFromString(NSString *statusCode);
