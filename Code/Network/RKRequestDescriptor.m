//
//  RKRequestDescriptor.m
//  RestKit
//
//  Created by Blake Watters on 8/24/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKRequestDescriptor.h"

@interface RKRequestDescriptor ()

@property (nonatomic, strong, readwrite) RKMapping *mapping;
@property (nonatomic, strong, readwrite) Class objectClass;
@property (nonatomic, copy, readwrite) NSString *rootKeyPath;

@end

@implementation RKRequestDescriptor

+ (id)requestDescriptorWithMapping:(RKMapping *)mapping objectClass:(Class)objectClass rootKeyPath:(NSString *)rootKeyPath
{
    NSParameterAssert(mapping);
    NSParameterAssert(objectClass);

    RKRequestDescriptor *requestDescriptor = [self new];
    requestDescriptor.mapping = mapping;
    requestDescriptor.objectClass = objectClass;
    requestDescriptor.rootKeyPath = rootKeyPath;
    return requestDescriptor;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p objectClass=%@ rootKeyPath=%@ : %@>",
            NSStringFromClass([self class]), self, NSStringFromClass(self.objectClass), self.rootKeyPath, self.mapping];
}

@end
