//
//  RKTStatus.m
//  RKTwitter
//
//  Created by Blake Watters on 9/5/10.
//  Copyright 2010 Two Toasters. All rights reserved.
//

#import "RKTStatus.h"

@implementation RKTStatus

@dynamic statusID;
@dynamic createdAt;
@dynamic text;
@dynamic urlString;
@dynamic inReplyToScreenName;
@dynamic isFavorited;
@dynamic user;

#pragma mark RKObjectMappable methods

// TODO: Move to the object mapping...
+ (NSString*)primaryKeyProperty {
	return @"statusID";
}

- (NSString*)description {
	return [NSString stringWithFormat:@"%@ (ID: %@ Date: %@)", self.text, self.statusID, self.createdAt];
}

@end
