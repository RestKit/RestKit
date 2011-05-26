//
//  RKTUser.m
//  RKTwitter
//
//  Created by Blake Watters on 9/5/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKTUser.h"

@implementation RKTUser

@dynamic userID;
@dynamic name;
@dynamic screenName;

+ (NSString*)primaryKeyProperty {
	return @"userID";
}

@end
