//
//  RKHTTPRequestOperation.h
//  RestKit
//
//  Created by Blake Watters on 8/7/12.
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

#import "AFNetworking.h"
#import "AFHTTPRequestOperation.h"

// Expose the default headers from AFNetworking's AFHTTPClient
@interface AFHTTPClient ()
@property (readonly, nonatomic) NSDictionary *defaultHeaders;
@end

/**
 The `RKHTTPRequestOperation` class is a subclass of `AFHTTPRequestOperation` for HTTP or HTTPS requests made by RestKit. It provides per-instance configuration of the acceptable status codes and content types and integrates with the `RKLog` system to provide detailed requested and response logging. Instances of `RKHTTPRequest` are created by `RKObjectRequestOperation` and its subclasses to HTTP requests that will be object mapped. When used to make standalone HTTP requests, `RKHTTPRequestOperation` instance behave identically to `AFHTTPRequestOperation` with the exception of emitting logging information.
 */
@interface RKHTTPRequestOperation : AFHTTPRequestOperation

///------------------------------------------------------------
/// @name Configuring Acceptable Status Codes and Content Types
///------------------------------------------------------------

/**
 The set of status codes which the operation considers successful.
 
 When `nil`, the acceptability of status codes is deferred to the superclass implementation.
 
 **Default**: `nil`
 */
@property (nonatomic, strong) NSIndexSet *acceptableStatusCodes;

/**
 The set of content types which the operation considers successful.
 
 The set may contain `NSString` or `NSRegularExpression` objects. When `nil`, the acceptability of content types is deferred to the superclass implementation.
 
 **Default**: `nil`
 */
@property (nonatomic, strong) NSSet *acceptableContentTypes;

/**
 Whether the response received a 304 response, whether via the initial request, or by virtue of cache revalidation occurring from `NSURLCache`.
 */
@property (nonatomic, readonly) BOOL wasNotModified;

@end
