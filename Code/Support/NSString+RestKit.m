//
//  NSString+RestKit.m
//  RestKit
//
//  Created by Blake Watters on 6/15/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "NSString+RestKit.h"
#import "../Network/RKClient.h"

@implementation NSString (RestKit)

- (NSString*)appendQueryParams:(NSDictionary*)queryParams {
    return RKPathAppendQueryParams(self, queryParams);
}

- (NSString*)interpolateWithObject:(id)object {
    return RKMakePathWithObject(self, object);
}

@end
