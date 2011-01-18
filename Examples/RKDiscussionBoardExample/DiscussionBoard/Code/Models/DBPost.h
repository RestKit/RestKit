//
//  DBPost.h
//  DiscussionBoard
//
//  Created by Jeremy Ellison on 1/7/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit/CoreData/CoreData.h>

/**
 * The Post models an individual piece of content posted to
 * a Topic by a User within the Discussion Board.
 */
@interface DBPost : RKManagedObject {
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
 * The numeric primary key to the Topic this Post was made to
 *
 * TODO: This is the primary key, used in the automatic primary key association. Document it.
 */
@property (nonatomic, retain) NSNumber* topicID;

/**
 * The numeric primary key to the User this Post was created by
 * TODO: Create relationship and document
 */
@property (nonatomic, retain) NSNumber* userID;

/**
 * The numeric primary key identifying this Post in the remote backend. This
 * is the value used to uniquely identify this Post within the object store.
 */
@property (nonatomic, retain) NSNumber* postID;

/**
 * The username of the User who created this Post
 */
@property (nonatomic, retain) NSString* username;

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

// TODO: Relationship to the User???
// TODO: Relationship to the Topic???

@end
