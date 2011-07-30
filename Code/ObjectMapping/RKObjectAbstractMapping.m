//
//  RKObjectAbstractMapping.m
//  RestKit
//
//  Created by Blake Watters on 7/29/11.
//  Copyright 2011 RestKit. All rights reserved.
//

#import "RKObjectAbstractMapping.h"

@implementation RKObjectAbstractMapping

- (BOOL)forceCollectionMapping {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (Class)objectClass {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

@end
