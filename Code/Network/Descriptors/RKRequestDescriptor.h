//
//  RKRequestDescriptor.h
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
#import "RKHTTPUtilities.h"

@class RKMapping;

/**
 An `RKRequestDescriptor` object describes an object mapping configuration that is used to construct the parameters of an HTTP request for an object. Request descriptors are defined by specifying the `RKMapping` object (whose `objectClass` must be `NSMutableDictionary`) that is to be used when object mapping an object into an `NSDictionary` of parameters, the class of the type of object for which the mapping is to be applied, and an optional root key path under which the paramters are to be nested. Response descriptors are only utilized when construct parameters for an `NSURLRequest` with an HTTP method of `POST`, `PUT`, or `PATCH`.

 @see RKObjectParameterization
 @see [RKObjectMapping requestMapping]
 @see [RKObjectManager requestWithObject:method:path:parameters:]
 */
@interface RKRequestDescriptor : NSObject

///------------------------------------
/// @name Creating a Request Descriptor
///------------------------------------

// new initializer
+ (instancetype)requestDescriptorWithObjectClass:(Class)objectClass
                                          method:(RKHTTPMethodOptions)method
                                     rootKeyPath:(NSString *)rootKeyPath
                                         mapping:(RKMapping *)mapping;

///-----------------------------------------------------
/// @name Getting Information About a Request Descriptor
///-----------------------------------------------------

/**
 The class of objects that the request descriptor is appropriate for use in parameterizing.
 */
@property (nonatomic, strong, readonly) Class objectClass;

/**
 The HTTP method(s) for which the mapping is to be used.
 */
@property (nonatomic, assign, readonly) RKHTTPMethodOptions methods;

/**
 The root key path that the paramters for the object are to be nested under. May be nil.
 */
@property (nonatomic, copy, readonly) NSString *rootKeyPath;

/**
 The mapping specifying how the object being parameterized is to be mapped into an `NSDictionary` representation. The mapping must have an objectClass equal to `[NSMutableDictionary class]`.
 */
@property (nonatomic, strong, readonly) RKMapping *mapping;

///-------------------------
/// @name Comparing Request Descriptors
///-------------------------

/**
 Returns `YES` if the receiver and the specified request descriptor are considered equivalent.

 */
// TODO: Replace with `isEqual:`
- (BOOL)isEqualToRequestDescriptor:(RKRequestDescriptor *)otherDescriptor;

@end
