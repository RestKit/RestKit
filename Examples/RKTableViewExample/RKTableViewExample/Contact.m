//
//  Contact.m
//  RKTableViewExample
//
//  Created by Blake Watters on 8/3/11.
//  Copyright 2011 RestKit. All rights reserved.
//

#import "Contact.h"

@implementation Contact

@synthesize firstName;
@synthesize lastName;
@synthesize emailAddress;

- (id)init {
    self = [super init];
    if (self) {
        // Initialization code here.
    }

    return self;
}

- (NSString*)fullName {
    return [NSString stringWithFormat:@"%@ %@", firstName, lastName];
}

@end
