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
+ (RKResponseDescriptor *)responseDescriptorWithMapping:(RKMapping *)mapping
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
 
 @see RKPathMatcher
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

@end
