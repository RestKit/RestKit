//
//  RKTUser.m
//  RKTwitter
//
//  Created by Blake Watters on 9/5/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKTUser.h"

@implementation RKTUser

@synthesize userID = _userID;
@synthesize name = _name;
@synthesize screenName = _screenName;

#pragma mark RKObjectMappable methods

+ (NSDictionary*)elementToPropertyMappings {
	return [NSDictionary dictionaryWithKeysAndObjects:
			@"id", @"userID",
			@"screen_name", @"screenName",
			@"name", @"name",
			nil];
}

- (void)dealloc {
    [_userID release];
	[_name release];
	[_screenName release];
    
    [super dealloc];
}

@end
