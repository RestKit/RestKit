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
@dynamic topicID;
@dynamic postID;
@dynamic username;
@dynamic topic;

@synthesize newAttachment = _newAttachment;

- (BOOL)isNewRecord {
	return [self.postID intValue] == 0;
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
	RKLogDebug(@"Self Body: %@", self.body);
	if (_newAttachment) {
		NSData* data = UIImagePNGRepresentation(_newAttachment);
		RKLogDebug(@"Data Size: %d", [data length]);
		RKParamsAttachment* attachment = [params setData:data MIMEType:@"application/octet-stream" forParam:@"post[attachment]"];
		attachment.fileName = @"image.png";
	}
	
	objectLoader.params = params;
}

- (BOOL)hasAttachment {
	return NO == [[self attachmentPath] isWhitespaceAndNewlines];
}

@end
