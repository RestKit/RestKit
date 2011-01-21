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
@dynamic posts;

#pragma mark RKObjectMappable methods

/**
 * The property mapping dictionary. This method declares how elements in the JSON
 * are mapped to properties on the object.
 */
+ (NSDictionary*)elementToPropertyMappings {
	return [NSDictionary dictionaryWithKeysAndObjects:
					@"id", @"topicID",
					@"name", @"name",
					@"user_id", @"userID",
					@"created_at", @"createdAt",
					@"updated_at", @"updatedAt",
					nil];
}

/**
 * Informs RestKit which properties contain the primary key values that
 * can be used to hydrate relationships to other objects. This hint enables
 * RestKit to automatically maintain true Core Data relationships between objects
 * in your local store.
 *
 * Here we have asked RestKit to connect the 'user' relationship by performing a
 * primary key lookup with the value in 'userID' property. This is the declarative
 * equivalent of doing self.user = [DBUser objectWithPrimaryKeyValue:self.userID];
 */
+ (NSDictionary*)relationshipToPrimaryKeyPropertyMappings {
	return [NSDictionary dictionaryWithKeysAndObjects:
			@"user", @"userID",
			nil];
}

/**
 * Informs RestKit which property contains the primary key for identifying
 * this object. This is used to ensure that objects are updated
 */
+ (NSString*)primaryKeyProperty {
	return @"topicID";
}

@end
