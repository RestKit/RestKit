//
//  RKResponseDescriptor.h
//  RestKit
//
//  Created by Blake Watters on 8/16/12.
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

#import "RKHTTPUtilities.h"

@class RKMapping, RKPathTemplate;

/**
 An `RKResponseDescriptor` object describes an object mapping configuration that is applicable to an HTTP response. Response descriptors are defined by specifying the `RKMapping` object that is to be used when performing object mapping on the deserialized response body and the URL path pattern, key path, and status codes for which the mapping is appropriate. The path pattern is a SOCKit `SOCPattern` string that will be matched against the URL of the request that loaded the response being mapped. If the path pattern is nil, the response descriptor is considered to be appropriate for a response loaded from any URL. The key path specifies the location of data within the deserialized response body for which the mapping is appropriate. If nil, the mapping is considered to apply to the entire response body.  The status codes specify a set of HTTP response status codes for which the mapping is appropriate. It is common to constrain a response descriptor to the HTTP Successful status code class (status codes in the 200-299 range). Object mapping for error responses can be configured by configuring a response descriptor to handle the Client Error status code class (status codes in the 400-499 range). Instances of `RKResponseDescriptor` are immutable.

 @see RKPathMatcher
 @see RKStatusCodeIndexSetFromClass
 */
@interface RKResponseDescriptor : NSObject


///-------------------------------------
/// @name Creating a Response Descriptor
///-------------------------------------

/**
 Creates and returns a new `RKResponseDescriptor` object.

 @param methods The HTTP method(s) for which the mapping is to be used.
 @param mapping The mapping for the response descriptor.
 @param pathTemplateString A string which to instantiate a path template object that matches the path of URLs for which the descriptor should be used.
 @param keyPath A key path specifying the subset of the parsed response for which the mapping is to be used.
 @param statusCodes A set of HTTP status codes for which the mapping is to be used.
 @return A new `RKResponseDescriptor` object.
*/
+ (instancetype)responseDescriptorWithMethods:(RKHTTPMethodOptions)methods
                           pathTemplateString:(NSString *)pathTemplateString
                         parameterConstraints:(NSArray *)parameterConstraints
                                      keyPath:(NSString *)keyPath
                                  statusCodes:(NSIndexSet *)statusCodes
                                      mapping:(RKMapping *)mapping;

///------------------------------------------------------
/// @name Getting Information About a Response Descriptor
///------------------------------------------------------

/**
 The HTTP method(s) for which the mapping is to be used.
 */
@property (nonatomic, assign, readonly) RKHTTPMethodOptions methods;

/**
 A path template that matches response URLs for which receiver is to be used. If `nil`, the response descriptor matches any URL.
 */
@property (nonatomic, copy, readonly) RKPathTemplate *pathTemplate;

/**
 An array of parameter constraint objects that must match the query and path parameters of the response URL for the receiver to match. If `nil`, the response descriptor matches any URL.
 
 @see RKParameterConstraint
 */
@property (nonatomic, copy, readonly) NSArray *parameterConstraints;

/**
 The key path to match against the deserialized response body. If `nil`, the response descriptor matches the entire response body.

 When evaluating a key path match, the Foundation object parsed from the response body is sent `valueForKeyPath:` with the keyPath of the receiver. If the value returned is non-nil, object mapping is performed using the response descriptor's mapping.
 */
@property (nonatomic, copy, readonly) NSString *keyPath;

/**
 The set of status codes for which response descriptor matches. If `nil`, the the response descriptor matches any status code.

 @see RKStatusCodeClass
 */
@property (nonatomic, copy, readonly) NSIndexSet *statusCodes;

/**
 The mapping to be used when object mapping the deserialized HTTP response body. Cannot be `nil`.
 */
@property (nonatomic, strong, readonly) RKMapping *mapping;

///---------------------------------
/// @name Using Response Descriptors
///---------------------------------

/**
 Returns a Boolean value that indicates if the receiver's path pattern matches the given path.

 Path matching is performed using an `RKPathMatcher` object. If the receiver has a `nil` path pattern or the given path is `nil`, `YES` is returned.

 @param path The path to compare with the path pattern of the receiver.
 @param parameters A pointer to a dictionary object that on output will be set to a dictionary containing the parameters matched from the given path using the path template. If the path template does not match the given path then the input dictionary will be set to `nil`.
 @return `YES` if the path matches the receiver's pattern, else `NO`.
 @see `RKPathMatcher`
 */
- (BOOL)matchesPath:(NSString *)path parameters:(NSDictionary **)parameters;

/**
 Returns a Boolean value that indicates if the given URL object matches the base URL and path pattern of the receiver.

 This method considers both the `baseURL` and `pathPattern` of the receiver when evaluating the given URL object. The results evaluate in the following ways:

 1. If the `baseURL` and `pathPattern` of the receiver are both `nil`, then `YES` is returned.
 1. If the `baseURL` of the receiver is `nil`, but the path pattern is not, then the entire path and query string of the given URL will be evaluated against the path pattern of the receiver using `matchesPath:`.
 1. If the `baseURL` and the `pathPattern` are both non-nil, then the given URL is first checked to verify that it is relative to the base URL using a string prefix comparison. If the absolute string value of the given URL is prefixed with the string value of the base URL, then the URL is considered relative. If the given URL is found not to be relative to the receiver's baseURL, then `NO` is returned. If the URL is found to be relative to the base URL, then the path and query string of the URL are evaluated against the path pattern of the receiver using `matchesPath:`.

 @param URL The URL to compare with the base URL and path pattern of the receiver.
 @return `YES` if the URL matches the base URL and path pattern of the receiver, else `NO`.
 */
- (BOOL)matchesURL:(NSURL *)URL relativeToBaseURL:(NSURL *)baseURL parameters:(NSDictionary **)parameters;

/**
 Returns a Boolean value that indicates if the given URL response object matches the receiver.

 The match is evaluated by checking if the URL of the response matches the base URL and path pattern of the receiver via the `matchesURL:` method. If the URL is found to match, then the status code of the response is checked for inclusion in the receiver's set of status codes.

 @param response The HTTP response object to compare with the base URL, path pattern, and status codes set of the receiver.
 @return `YES` if the response matches the base URL, path pattern, and status codes set of the receiver, else `NO`.
 @see `matchesURL:`
 */
- (BOOL)matchesResponse:(NSHTTPURLResponse *)response request:(NSURLRequest *)request relativeToBaseURL:(NSURL *)baseURL parameters:(NSDictionary **)parameters;

///-------------------------
/// @name Comparing Response Descriptors
///-------------------------

/**
 Returns `YES` if the receiver and the specified response descriptor are considered equivalent.

 */
// TODO: Just go with isEqual:
- (BOOL)isEqualToResponseDescriptor:(RKResponseDescriptor *)otherDescriptor;

@end
