//
//  RKSpecAddress.m
//  RestKit
//
//  Created by Blake Watters on 8/5/11.
//  Copyright 2011 RestKit. All rights reserved.
//

#import "RKSpecAddress.h"

@implementation RKSpecAddress

@synthesize addressID = _addressID;
@synthesize city = _city;
@synthesize state = _state;
@synthesize country = _country;

+ (RKSpecAddress*)address {
    return [[self new] autorelease];
}

// isEqual: is consulted by the mapping operation
// to determine if assocation values should be set
- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[RKSpecAddress class]]) {
        return [[(RKSpecAddress*)object addressID] isEqualToNumber:self.addressID];
    } else {
        return NO;
    }
}

@end