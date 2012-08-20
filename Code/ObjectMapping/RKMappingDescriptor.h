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

// 200..299
NSRange RKMakeSuccessfulStatusCodeRange(void);

// 400..499
NSRange RKMakeClientErrorStatusCodeRange(void);

/**
 An RKMappingDescriptor object describes an object mapping configuration
 that is available for a given HTTP request.
 */
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
