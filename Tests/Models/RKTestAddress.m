//
//  RKTestAddress.m
//  RestKit
//
//  Created by Blake Watters on 8/5/11.
//  Copyright (c) 2009-2012 RestKit. All rights reserved.
//

#import "RKTestAddress.h"

@implementation RKTestAddress

@synthesize addressID = _addressID;
@synthesize city = _city;
@synthesize state = _state;
@synthesize country = _country;

+ (RKTestAddress *)address
{
    return [[self new] autorelease];
}

// isEqual: is consulted by the mapping operation
// to determine if assocation values should be set
- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[RKTestAddress class]]) {
        return [[(RKTestAddress *)object addressID] isEqualToNumber:self.addressID];
    } else {
        return NO;
    }
}

@end
