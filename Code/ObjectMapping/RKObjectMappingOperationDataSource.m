//
//  RKObjectMappingOperationDataSource.m
//  RestKit
//
//  Created by Blake Watters on 7/3/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKObjectMappingOperationDataSource.h"
#import "RKObjectMapping.h"

@implementation RKObjectMappingOperationDataSource

- (id)objectForMappableContent:(id)mappableContent mapping:(RKObjectMapping *)mapping
{
    return [[mapping.objectClass new] autorelease];
}

@end
