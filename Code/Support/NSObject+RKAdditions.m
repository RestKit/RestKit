//
//  NSObject+RKAdditions.m
//  RestKit
//
//  Created by John Earl on 29/09/2011.
//  Copyright 2011 RestKit. All rights reserved.
//

#import "NSObject+RKAdditions.h"

@implementation NSObject(RKAdditions)

-(BOOL)isCollection
{
    return [self isKindOfClass:[NSSet class]] || [self isKindOfClass:[NSArray class]];
}

@end
