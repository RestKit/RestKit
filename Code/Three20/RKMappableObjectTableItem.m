//
//  RKMappableObjectTableItem.m
//  RestKit
//
//  Created by Blake Watters on 4/26/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKMappableObjectTableItem.h"

@implementation RKMappableObjectTableItem

@synthesize object = _object;

+ (id)itemWithObject:(NSObject*)object {
    RKMappableObjectTableItem* tableItem = [self new];
    tableItem.object = object;
    return [tableItem autorelease];
}

@end
