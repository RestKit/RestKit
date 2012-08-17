//
//  RKMappingDescriptor.h
//  GateGuru
//
//  Created by Blake Watters on 8/16/12.
//  Copyright (c) 2012 GateGuru, Inc. All rights reserved.
//

#import <RestKit/RestKit.h>

//RKMakeStatusCodeRange(RKStatusCodeRangeSuccessful)
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
