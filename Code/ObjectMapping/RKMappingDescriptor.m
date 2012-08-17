//
//  RKMappingDescriptor.m
//  GateGuru
//
//  Created by Blake Watters on 8/16/12.
//  Copyright (c) 2012 GateGuru, Inc. All rights reserved.
//

#import <RestKit/RKPathMatcher.h>
#import "RKMappingDescriptor.h"

NSRange RKMakeSuccessfulStatusCodeRange(void)
{
    return NSMakeRange(200, 100);
}

NSRange RKMakeClientErrorStatusCodeRange(void)
{
    return NSMakeRange(400, 100);
}

// Cloned from AFStringFromIndexSet -- method should be non-static for reuse
static NSString * RKStringFromIndexSet(NSIndexSet *indexSet) {
    NSMutableString *string = [NSMutableString string];
    
    NSRange range = NSMakeRange([indexSet firstIndex], 1);
    while (range.location != NSNotFound) {
        NSUInteger nextIndex = [indexSet indexGreaterThanIndex:range.location];
        while (nextIndex == range.location + range.length) {
            range.length++;
            nextIndex = [indexSet indexGreaterThanIndex:nextIndex];
        }
        
        if (string.length) {
            [string appendString:@","];
        }
        
        if (range.length == 1) {
            [string appendFormat:@"%u", range.location];
        } else {
            NSUInteger firstIndex = range.location;
            NSUInteger lastIndex = firstIndex + range.length - 1;
            [string appendFormat:@"%u-%u", firstIndex, lastIndex];
        }
        
        range.location = nextIndex;
        range.length = 1;
    }
    
    return string;
}

@interface RKMappingDescriptor ()
@property (nonatomic, strong, readwrite) RKMapping *mapping;
@property (nonatomic, strong, readwrite) NSString *pathPattern;
@property (nonatomic, strong, readwrite) NSString *keyPath;
@property (nonatomic, strong, readwrite) NSIndexSet *statusCodes;
@end

@implementation RKMappingDescriptor

+ (RKMappingDescriptor *)mappingDescriptorWithMapping:(RKMapping *)mapping
                                          pathPattern:(NSString *)pathPattern
                                              keyPath:(NSString *)keyPath
                                          statusCodes:(NSIndexSet *)statusCodes
{
    RKMappingDescriptor *mappingDescriptor = [self new];
    mappingDescriptor.mapping = mapping;
    mappingDescriptor.pathPattern = pathPattern;
    mappingDescriptor.keyPath = keyPath;
    mappingDescriptor.statusCodes = statusCodes;
    
    return mappingDescriptor;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p pathPattern=%@ keyPath=%@ statusCodes=%@ : %@>",
            NSStringFromClass([self class]), self, self.pathPattern, self.keyPath, RKStringFromIndexSet(self.statusCodes), self.mapping];
}

@end
