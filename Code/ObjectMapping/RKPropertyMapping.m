//
//  RKPropertyMapping.m
//  RestKit
//
//  Created by Blake Watters on 8/27/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKPropertyMapping.h"

@interface RKPropertyMapping ()
@property (nonatomic, strong, readwrite) NSString *sourceKeyPath;
@property (nonatomic, strong, readwrite) NSString *destinationKeyPath;
@end

@implementation RKPropertyMapping

- (id)copyWithZone:(NSZone *)zone
{
    RKPropertyMapping *copy = [[[self class] allocWithZone:zone] init];
    copy.sourceKeyPath = self.sourceKeyPath;
    copy.destinationKeyPath = self.destinationKeyPath;
    return copy;
}

- (BOOL)isEqualToMapping:(RKPropertyMapping *)otherMapping
{
    return [otherMapping isMemberOfClass:[self class]] &&
    [self.sourceKeyPath isEqual:otherMapping.sourceKeyPath] &&
    [self.destinationKeyPath isEqual:otherMapping.destinationKeyPath];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p %@ => %@>", self.class, self, self.sourceKeyPath, self.destinationKeyPath];
}

@end
