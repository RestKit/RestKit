//
//  RKMappingDescriptor.h
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

#import <RestKit/RestKit.h>

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

/**
 An RKMappingDescriptor object describes an object mapping configuration
 that is available for a given HTTP request.
 */
// Becomes RKResponseDescriptor
@interface RKMappingDescriptor : NSObject

@property (nonatomic, strong, readonly) RKMapping *mapping;         // required
@property (nonatomic, strong, readonly) NSString *pathPattern;      // can be nil
@property (nonatomic, strong, readonly) NSString *keyPath;          // can be nil
@property (nonatomic, strong, readonly) NSIndexSet *statusCodes;    // can be nil

+ (RKMappingDescriptor *)mappingDescriptorWithMapping:(RKMapping *)mapping
                                          pathPattern:(NSString *)pathPattern
                                              keyPath:(NSString *)keyPath
                                          statusCodes:(NSIndexSet *)statusCodes;
@end
