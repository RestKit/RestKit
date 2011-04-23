//
//  RKMappableAssociation.m
//  RestKit
//
//  Created by Jeremy Ellison on 8/17/09.
//  Copyright 2009 Two Toasters. All rights reserved.
//

#import "RKMappableAssociation.h"

@implementation RKMappableAssociation

@synthesize testString = _testString;
@synthesize date = _date;

- (void)dealloc {
    [_testString release];
    [_date release];
    [super dealloc];
}

@end
