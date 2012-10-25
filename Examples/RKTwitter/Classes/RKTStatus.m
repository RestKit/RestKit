//
//  RKTStatus.m
//  RKTwitter
//
//  Created by Blake Watters on 9/5/10.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKTStatus.h"

@implementation RKTStatus

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ (ID: %@)", self.text, self.statusID];
}

@end
