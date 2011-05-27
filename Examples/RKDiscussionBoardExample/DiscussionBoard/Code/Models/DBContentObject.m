//
//  DBContentObject.m
//  DiscussionBoard
//
//  Created by Blake Watters on 1/20/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "DBContentObject.h"

NSString* const DBContentObjectDidChangeNotification = @"DBContentObjectDidChangeNotification";

@implementation DBContentObject

@dynamic userID;
@dynamic createdAt;
@dynamic updatedAt;
@dynamic user;

- (BOOL)isNewRecord {
	return [[self primaryKeyValue] intValue] == 0;
}

- (NSString*)username {
	return self.user.username;
}

@end
