//
//  DBPost.m
//  DiscussionBoard
//
//  Created by Jeremy Ellison on 1/7/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "DBPost.h"
#import <RestKit/Support/NSDictionary+RKAdditions.h>

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
@dynamic username;

@synthesize newAttachment = _newAttachment;

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
			@"attachment_updated_at", @"attachmentUpdatedAt",
			@"body", @"body",
			@"user_login", @"username",
			nil];
}

+ (NSString*)primaryKeyProperty {
	return @"postID";
}

- (id<RKRequestSerializable>)paramsForSerialization {
	RKParams* params = [RKParams params];
	[params setValue:self.body forParam:@"post[body]"];
	NSLog(@"Self Body: %@", self.body);
	if (_newAttachment) {
		NSData* data = UIImagePNGRepresentation(_newAttachment);
		NSLog(@"Data Size: %d", [data length]);
		RKParamsAttachment* attachment = [params setData:data MIMEType:@"application/octet-stream" forParam:@"post[attachment]"];
		attachment.fileName = @"image.png";
	}

	return params;
}

@end
