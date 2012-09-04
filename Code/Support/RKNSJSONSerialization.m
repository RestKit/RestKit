//
//  RKNSJSONSerialization.m
//  RestKit
//
//  Created by Blake Watters on 8/31/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKNSJSONSerialization.h"

@implementation RKNSJSONSerialization

+ (id)objectFromData:(NSData *)data error:(NSError **)error
{
    return [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
}

+ (NSData *)dataFromObject:(id)object error:(NSError **)error
{
    return [NSJSONSerialization dataWithJSONObject:object options:0 error:error];
}

@end
