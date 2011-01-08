//
//  DBPost.m
//  DiscussionBoard
//
//  Created by Jeremy Ellison on 1/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DBPost.h"


@implementation DBPost

@dynamic attachmentContentType;
@dynamic attachmentFileName;
@dynamic attachmentFileSize;
@dynamic attachmentPath;
@dynamic attachmentUpdatedAt;
@dynamic body;
@dynamic createdAt;
@dynamic topicID;
@dynamic updatedAt;
@dynamic userID;
@dynamic postID;

+ (NSDictionary*)elementToPropertyMappings {
	return [NSDictionary dictionaryWithKeysAndObjects:
			@"id",@"postID", 
			@"topic_id",@"topicID",
			@"user_id",@"userID",
			@"created_at",@"createdAt", 
			@"updated_at",@"updatedAt",
			@"attachment_content_type", @"attachmentContentType",
			@"attachment_file_name", @"attachmentFileName",
			@"attachment_file_size", @"attachmentFileSize",
			@"attachment_path", @"attachmentPath",
			@"attachment_updated_at", @"attachment_updated_at",
			nil];
}

+ (NSString*)primaryKeyProperty {
	return @"postID";
}

@end
