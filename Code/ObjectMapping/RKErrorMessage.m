//
//  RKError.m
//  RestKit
//
//  Created by Jeremy Ellison on 5/10/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "RKErrorMessage.h"


@implementation RKErrorMessage

@synthesize errorMessage = _errorMessage;

- (void)dealloc {
    [_errorMessage release];
    [super dealloc];
}

- (NSString*)description {
    return _errorMessage;
}

@end
