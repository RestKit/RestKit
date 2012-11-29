//
//  RKTweet.m
//  RKTwitter
//
//  Created by Blake Watters on 9/5/10.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKTweet.h"

@implementation RKTweet

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ (ID: %@)", self.text, self.statusID];
}

@end
