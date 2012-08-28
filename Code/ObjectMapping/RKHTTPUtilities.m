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

NSString *RKStringFromRequestMethod(RKRequestMethod method)
{
    switch (method) {
        case RKRequestMethodGET:
            return @"GET";
            break;
            
        case RKRequestMethodPOST:
            return @"POST";
            break;
            
        case RKRequestMethodPUT:
            return @"PUT";
            break;
            
        case RKRequestMethodPATCH:
            return @"PATCH";
            break;
            
        case RKRequestMethodDELETE:
            return @"DELETE";
            break;
            
        case RKRequestMethodHEAD:
            return @"HEAD";
            break;
            
        default:
            break;
    }
    
    return nil;
}

RKRequestMethod RKRequestMethodFromString(NSString *methodName)
{
    if ([methodName isEqualToString:@"GET"]) {
        return RKRequestMethodGET;
    } else if ([methodName isEqualToString:@"POST"]) {
        return RKRequestMethodPOST;
    } else if ([methodName isEqualToString:@"PUT"]) {
        return RKRequestMethodPUT;
    } else if ([methodName isEqualToString:@"DELETE"]) {
        return RKRequestMethodDELETE;
    } else if ([methodName isEqualToString:@"HEAD"]) {
        return RKRequestMethodHEAD;
    } else if ([methodName isEqualToString:@"PATCH"]) {
        return RKRequestMethodPATCH;
    }
    
    return RKRequestMethodInvalid;
}
