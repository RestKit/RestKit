//
//  RKRoute.m
//  RestKit
//
//  Created by Blake Watters on 5/31/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKRoute.h"

@implementation RKRoute

@synthesize name = _name;
@synthesize objectClass = _objectClass;
@synthesize method = _method;
@synthesize resourcePathPattern = _resourcePathPattern;
@synthesize shouldEscapeResourcePath = _shouldEscapeResourcePath;

- (BOOL)isNamedRoute
{
    return [self.name length] > 0;
}

- (BOOL)isClassRoute
{
    return self.objectClass != nil;
}

- (NSString *)description
{
    if ([self isNamedRoute]) {
        return [NSString stringWithFormat:@"<%@: %p name=%@ resourcePathPattern=%@>",
                NSStringFromClass([self class]), self, self.name, self.resourcePathPattern];
    } else if ([self isClassRoute]) {
        return [NSString stringWithFormat:@"<%@: %p objectClass=%@ method=%@ resourcePathPattern=%@>",
                NSStringFromClass([self class]), self, NSStringFromClass(self.objectClass),
                RKRequestMethodNameFromType(self.method), self.resourcePathPattern];
    }

    return [super description];
}

@end
