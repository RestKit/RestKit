//
//  RKDynamicMappingMatcher.m
//  RestKit
//
//  Created by Jeff Arena on 8/2/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKDynamicMappingMatcher.h"
#import "RKObjectUtilities.h"

///////////////////////////////////////////////////////////////////////////////////////////////////

@interface RKDynamicMappingMatcher ()
@property (nonatomic, copy) NSString *keyPath;
@property (nonatomic, strong, readwrite) id expectedValue;
@property (nonatomic, strong, readwrite) RKObjectMapping *objectMapping;
@end

@implementation RKDynamicMappingMatcher

- (id)initWithKeyPath:(NSString *)keyPath expectedValue:(id)expectedValue objectMapping:(RKObjectMapping *)objectMapping
{
    NSParameterAssert(keyPath);
    NSParameterAssert(expectedValue);
    NSParameterAssert(objectMapping);
    self = [super init];
    if (self) {
        self.keyPath = keyPath;
        self.expectedValue = expectedValue;
        self.objectMapping = objectMapping;
    }

    return self;
}

- (BOOL)matches:(id)object
{
    id value = [object valueForKeyPath:self.keyPath];
    if (value == nil) return NO;
    return RKObjectIsEqualToObject(value, self.expectedValue);
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p when `%@` == '%@' objectMapping: %@>", NSStringFromClass([self class]), self, self.keyPath, self.expectedValue, self.objectMapping];
}

@end
