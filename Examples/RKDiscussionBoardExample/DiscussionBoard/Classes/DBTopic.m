//
//  DBTopic.m
//  DiscussionBoard
//
//  Created by Daniel Hammond on 1/7/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "DBTopic.h"

@implementation DBTopic

@dynamic topicID;
@dynamic name;
@dynamic userID;
@dynamic createdAt;
@dynamic updatedAt;

#pragma mark RKObjectMappable methods

+ (NSDictionary*)elementToPropertyMappings {
	return [NSDictionary dictionaryWithKeysAndObjects:
					@"id",@"topicID", 
					@"name",@"name", 
					@"user_id",@"userID",
					@"created_at",@"createdAt", 
					@"updated_at",@"updatedAt", 
					nil];
}

+ (NSString*)primaryKeyProperty {
	return @"topicID";
}


@end
