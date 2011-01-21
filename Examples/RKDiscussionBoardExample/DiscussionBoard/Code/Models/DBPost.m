//
//  DBPost.m
//  DiscussionBoard
//
//  Created by Jeremy Ellison on 1/7/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Three20/Three20+Additions.h>
#import <RestKit/Support/NSDictionary+RKAdditions.h>
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
@dynamic username;
@dynamic user;
@dynamic topic;

@synthesize newAttachment = _newAttachment;

/**
 * The property mapping dictionary. This method declares how elements in the JSON
 * are mapped to properties on the object
 */
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
			nil];
}

/**
 * Informs RestKit which property contains the primary key for identifying
 * this object. This is used to ensure that existing objects are updated during mapping
 */
+ (NSString*)primaryKeyProperty {
	return @"postID";
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
			@"topic", @"topicID",
			nil];
}

/**
 * Invoked just before this Post is sent in an object loader request via
 * getObject, postObject, putObject or deleteObject. Here we can manipulate
 * the request at will. 
 * 
 * The router only has the ability to work with simple dictionaries, so to 
 * support uploading the attachment we are going to supply our own params
 * for the request.
 */
- (void)willSendWithObjectLoader:(RKObjectLoader *)objectLoader {
	RKParams* params = [RKParams params];
	
	// NOTE - Since we have side-stepped the router, we need to
	// nest the param names under the model name ourselves
	[params setValue:self.body forParam:@"post[body]"];
	NSLog(@"Self Body: %@", self.body);
	if (_newAttachment) {
		NSData* data = UIImagePNGRepresentation(_newAttachment);
		NSLog(@"Data Size: %d", [data length]);
		RKParamsAttachment* attachment = [params setData:data MIMEType:@"application/octet-stream" forParam:@"post[attachment]"];
		attachment.fileName = @"image.png";
	}
	
	objectLoader.params = params;
}

- (BOOL)hasAttachment {
	return NO == [[self attachmentPath] isWhitespaceAndNewlines];
}

@end
