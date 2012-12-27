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

@class RKMapping;

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
 
 @param mapping The mapping for the response descriptor.
 @param pathPattern A path pattern that matches against URLs for which the mapping should be used.
 @param keyPath A key path specifying the subset of the parsed response for which the mapping is to be used.
 @param statusCodes A set of HTTP status codes for which the mapping is to be used.
 @return A new `RKResponseDescriptor` object.
 */
+ (instancetype)responseDescriptorWithMapping:(RKMapping *)mapping
                                  pathPattern:(NSString *)pathPattern
                                      keyPath:(NSString *)keyPath
                                  statusCodes:(NSIndexSet *)statusCodes;

///------------------------------------------------------
/// @name Getting Information About a Response Descriptor
///------------------------------------------------------

/**
 The mapping to be used when object mapping the deserialized HTTP response body. Cannot be nil.
 */
@property (nonatomic, strong, readonly) RKMapping *mapping;

/**
 The path pattern to match against the request URL. If nil, the response descriptor matches any URL.
 
 @see `RKPathMatcher`
 */
@property (nonatomic, copy, readonly) NSString *pathPattern;

/**
 The key path to match against the deserialized response body. If nil, the response descriptor matches the entire response body.
 
 When evaluating a key path match, the Foundation object parsed from the response body is sent `valueForKeyPath:` with the keyPath of the receiver. If the value returned is non-nil, object mapping is performed using the response descriptor's mapping.
 */
@property (nonatomic, copy, readonly) NSString *keyPath;

/**
 The set of status codes for which response descriptor matches. If nil, the the response descriptor matches any status code.
 
 @see RKStatusCodeClass
 */
@property (nonatomic, copy, readonly) NSIndexSet *statusCodes;

///---------------------------
/// @name Setting the Base URL
///---------------------------

/**
 The base URL that the `pathPattern` is to be evaluated relative to.
 
 The base URL is set to the base URL of the object manager when a response descriptor is added to an object manager.

 @see `matchesURL:`
 */
@property (nonatomic, copy) NSURL *baseURL;

///---------------------------------
/// @name Using Response Descriptors
///---------------------------------

/**
 Returns a Boolean value that indicates if the receiver's path pattern matches the given path.
 
 Path matching is performed using an `RKPathMatcher` object. If the receiver has a `nil` path pattern or the given path is `nil`, `YES` is returned.
 
 @param path The path to compare with the path pattern of the receiver.
 @return `YES` if the path matches the receiver's pattern, else `NO`.
 @see `RKPathMatcher`
 */
- (BOOL)matchesPath:(NSString *)path;

/**
 Returns a Boolean value that indicates if the given URL object matches the base URL and path pattern of the receiver.
 
 This method considers both the `baseURL` and `pathPattern` of the receiver when evaluating the given URL object. The results evaluate in the following ways:
 
 1. If the `baseURL` and `pathPattern` of the receiver are both `nil`, then `YES` is returned.
 1. If the `baseURL` of the receiver is `nil`, but the path pattern is not, then the entire path and query string of the given URL will be evaluated against the path pattern of the receiver using `matchesPath:`.
 1. If the `baseURL` and the `pathPattern` are both non-nil, then the given URL is first checked to verify that it is relative to the base URL using a string prefix comparison. If the absolute string value of the given URL is prefixed with the string value of the base URL, then the URL is considered relative. If the given URL is found not to be relative to the receiver's baseURL, then `NO` is returned. If the URL is found to be relative to the base URL, then the path and query string of the URL are evaluated against the path pattern of the receiver using `matchesPath:`.
 
 @param URL The URL to compare with the base URL and path pattern of the receiver.
 @return `YES` if the URL matches the base URL and path pattern of the receiver, else `NO`.
 */
- (BOOL)matchesURL:(NSURL *)URL;

/**
 Returns a Boolean value that indicates if the given URL response object matches the receiver.
 
 The match is evaluated by checking if the URL of the response matches the base URL and path pattern of the receiver via the `matchesURL:` method. If the URL is found to match, then the status code of the response is checked for inclusion in the receiver's set of status codes.
 
 @param response The HTTP response object to compare with the base URL, path pattern, and status codes set of the receiver.
 @return `YES` if the response matches the base URL, path pattern, and status codes set of the receiver, else `NO`.
 @see `matchesURL:`
 */
- (BOOL)matchesResponse:(NSHTTPURLResponse *)response;

@end
