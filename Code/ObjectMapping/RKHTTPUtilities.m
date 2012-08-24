//
//  RKHTTPUtilities.m
//  RestKit
//
//  Created by Blake Watters on 8/24/12.
//  Copyright (c) 2012 RestKit. All rights reserved.
//

#import "RKHTTPUtilities.h"

NSUInteger RKStatusCodeRangeLength = 100;

NSRange RKStatusCodeRangeForClass(RKStatusCodeClass statusCodeClass)
{
    return NSMakeRange(statusCodeClass, RKStatusCodeRangeLength);
}

NSIndexSet * RKStatusCodeIndexSetForClass(RKStatusCodeClass statusCodeClass)
{
    return [NSIndexSet indexSetWithIndexesInRange:RKStatusCodeRangeForClass(statusCodeClass)];
}
