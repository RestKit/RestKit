//
//  DBPost.h
//  DiscussionBoard
//
//  Created by Jeremy Ellison on 1/7/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit/CoreData/CoreData.h>
#import "DBUser.h"
#import "DBTopic.h"
#import "DBContentObject.h"

/**
 * The Post models an individual piece of content posted to
 * a Topic by a User within the Discussion Board.
 */
@interface DBPost : DBContentObject {
	UIImage* _newAttachment;
}

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Content properties

/**
 * The textual content of the Post as entered by the User
 */
@property (nonatomic, retain) NSString* body;

/**
 * A timestamp of when the Post was created
 */
@property (nonatomic, retain) NSDate* createdAt;

/**
 * A timestamp of when the Post was last updated
 */
@property (nonatomic, retain) NSDate* updatedAt;

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Relationship properties

/**
 * The Topic that this Post belongs to. This is a Core Data relationship
 * to the Topic object with the primary key value contained in the topicID property
 */
@property (nonatomic, retain) DBTopic* topic;

/**
 * The numeric primary key to the Topic this Post was made to
 */
@property (nonatomic, retain) NSNumber* topicID;

/**
 * The numeric primary key identifying this Post in the remote backend. This
 * is the value used to uniquely identify this Post within the object store.
 */
@property (nonatomic, retain) NSNumber* postID;

////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark File Attachment properties

/**
 * The MIME type of the attached file
 */
@property (nonatomic, retain) NSString* attachmentContentType;

/**
 * The filename of the attached file
 */
@property (nonatomic, retain) NSString* attachmentFileName;

/**
 * The size in bytes of the attached file
 */
@property (nonatomic, retain) NSNumber* attachmentFileSize;

/**
 * The filesystem path to the attached file on the remote system
 */
@property (nonatomic, retain) NSString* attachmentPath;

/**
 * A timestamp of the last time the attachment was modified (or created)
 */
@property (nonatomic, retain) NSDate* attachmentUpdatedAt;

/**
 * An accessor for supplying a new image to be attached to this Post
 */
@property (nonatomic, retain) UIImage* newAttachment;

/**
 * Returns YES when there is already an Image attached to this Post
 */
- (BOOL)hasAttachment;

@end
