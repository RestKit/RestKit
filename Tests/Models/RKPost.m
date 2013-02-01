//
//  RKPost.m
//  RestKit
//
//  Created by Blake Watters on 1/24/13.
//  Copyright (c) 2013 RestKit. All rights reserved.
//

#import "RKPost.h"

@implementation RKPost

@dynamic tags;

- (BOOL)validateTitle:(id *)ioValue error:(NSError **)outError {
    // Don't allow blank titles
    if ((*ioValue == nil) || ([[(NSString*)*ioValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""])) {
        return NO;
    }
    
    return YES;
}

@end
