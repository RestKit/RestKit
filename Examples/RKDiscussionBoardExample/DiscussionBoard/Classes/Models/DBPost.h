//
//  DBPost.h
//  DiscussionBoard
//
//  Created by Jeremy Ellison on 1/7/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit/CoreData/CoreData.h>

@interface DBPost : RKManagedObject {
	UIImage* _newAttachment;
}

@property (nonatomic, retain) NSString* attachmentContentType;
@property (nonatomic, retain) NSString* attachmentFileName;
@property (nonatomic, retain) NSNumber* attachmentFileSize;
@property (nonatomic, retain) NSString* attachmentPath;
@property (nonatomic, retain) NSDate* attachmentUpdatedAt;
@property (nonatomic, retain) NSString* body;
@property (nonatomic, retain) NSDate* createdAt;
@property (nonatomic, retain) NSNumber* topicID;
@property (nonatomic, retain) NSDate* updatedAt;
@property (nonatomic, retain) NSNumber* userID;
@property (nonatomic, retain) NSNumber* postID;
@property (nonatomic, retain) NSString* username;

@property (nonatomic, retain) UIImage* newAttachment;

@end