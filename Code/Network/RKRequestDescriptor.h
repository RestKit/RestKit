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

@class RKMapping;

/**
 An `RKRequestDescriptor` object describes an object mapping configuration that is used to construct the parameters of an HTTP request for an object. Request descriptors are defined by specifying the `RKMapping` object that is to be used when object mapping an object into an `NSDictionary` of parameters, the class of the type of object for which the mapping is to be applied, and an optional root key path under which the paramters are to be nested. Response descriptors are only utilized when construct parameters for an `NSURLRequest` with an HTTP method of `POST`, `PUT`, or `PATCH`.
 
 @see RKObjectParameterization
 @see [RKObjectMapping requestMapping]
 @see [RKObjectManager requestWithObject:method:path:parameters:]
 */
@interface RKRequestDescriptor : NSObject

///------------------------------------
/// @name Creating a Request Descriptor
///------------------------------------

/**
 Creates and returns a new `RKRequestDescriptor` object.
 
 @param mapping The mapping to be used when parameterizing an object using the request descriptor. Cannot be nil and must have an objectClass equal to `[NSMutableDictionary class]`.
 @param objectClass The class of objects for which the request descriptor should be used. Cannot be nil.
 @param rootKeyPath The root key path under which paramters constructed using the response descriptor will be nested. If nil, the parameters will not be nested and returned as a flat dictionary object.
 @return A new `RKRequestDescriptor` object.
 
 @see [RKObjectMapping requestMapping]
 @warning An exception will be raised if the objectClass of the given mapping is not `[NSMutableDictionary class]`.
 */
+ (instancetype)requestDescriptorWithMapping:(RKMapping *)mapping
                                 objectClass:(Class)objectClass
                                 rootKeyPath:(NSString *)rootKeyPath;

///-----------------------------------------------------
/// @name Getting Information About a Request Descriptor
///-----------------------------------------------------

/**
 The mapping specifying how the object being parameterized is to be mapped into an `NSDictionary` representation. The mapping must have an objectClass equal to `[NSMutableDictionary class]`.
 */
@property (nonatomic, strong, readonly) RKMapping *mapping;

/**
 The class of objects that the request descriptor is appropriate for use in parameterizing.
 */
@property (nonatomic, strong, readonly) Class objectClass;

/**
 The root key path that the paramters for the object are to be nested under. May be nil.
 */
@property (nonatomic, copy, readonly) NSString *rootKeyPath;

///--------------------------------
/// @name Using Request Descriptors
///--------------------------------

/**
 Returns `YES` if the given object is instance of objectClass or any class that inherits from objectClass, else `NO`.
 
 @param object The object to be matched against the receiver.
 @return `YES` if the given object matches objectClass, else `NO`.
 */
- (BOOL)matchesObject:(id)object;

@end
