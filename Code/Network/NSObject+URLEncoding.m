//
//  NSObject+URLEncoding.m
//  RestKit
//
//  Created by Jeff Arena on 7/11/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "NSObject+URLEncoding.h"


@implementation NSObject (URLEncoding)

- (NSString *)URLEncodedString
{
    NSString *string = [NSString stringWithFormat:@"%@", self];
    NSString *encodedString = (NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                                 (CFStringRef)string,
                                                                                 NULL,
                                                                                 (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                                 kCFStringEncodingUTF8);
    return [encodedString autorelease];
}

@end
