//
//  RKObjectMappingDefinition.m
//  RestKit
//
//  Created by Blake Watters on 2/15/12.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKObjectMappingDefinition.h"

@implementation RKObjectMappingDefinition

@synthesize rootKeyPath;
@synthesize forceCollectionMapping;

- (BOOL)isEqualToMapping:(RKObjectMappingDefinition *)otherMapping
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

@end
