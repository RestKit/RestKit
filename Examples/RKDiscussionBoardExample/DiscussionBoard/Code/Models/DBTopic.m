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
@dynamic username;

#pragma mark RKObjectMappable methods

/**
 * The property mapping dictionary. This method declares how elements in the JSON
 * are mapped to properties on the object.
 */
+ (NSDictionary*)elementToPropertyMappings {
	return [NSDictionary dictionaryWithKeysAndObjects:
					@"id",@"topicID",
					@"name",@"name",
					@"user_id",@"userID",
					@"created_at",@"createdAt",
					@"updated_at",@"updatedAt",
					@"user_login", @"username",
					nil];
}

/**
 * Informs RestKit which property contains the primary key for identifying
 * this object. This is used to ensure that objects are updated
 */
+ (NSString*)primaryKeyProperty {
	return @"topicID";
}

// TODO: Eliminate this. Just use the Rails router
- (id<RKRequestSerializable>)paramsForSerialization {
	return [NSDictionary dictionaryWithObjectsAndKeys:
			self.name, @"topic[name]", nil];
}


@end
