//
//  RKSearchable.m
//  RestKit
//
//  Created by Blake Watters on 7/26/11.
//  Copyright (c) 2011 Two Toasters. All rights reserved.
//

#import "RKSearchable.h"


@implementation RKSearchable

@dynamic title;
@dynamic body;

+ (NSArray*)searchableAttributes {
    return [NSArray arrayWithObjects:@"title", @"body", nil];
}

@end
