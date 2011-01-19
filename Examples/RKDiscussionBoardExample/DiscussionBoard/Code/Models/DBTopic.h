//
//  DBTopic.h
//  DiscussionBoard
//
//  Created by Daniel Hammond on 1/7/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData/CoreData.h>
#import "DBUser.h"

/**
 * Models a Topic in the Discussion Board. Users can
 * create Post's on Topics to have discussions.
 */
@interface DBTopic : RKManagedObject {
}

/**
 * The name of this Topic. Identifies what we are discussing
 */
@property (nonatomic, retain) NSString* name;

/**
 * A timestamp of when the object was created
 */
@property (nonatomic, retain) NSDate* createdAt;

/**
 * A timestamp of when the object was last modified
 */
@property (nonatomic, retain) NSDate* updatedAt;

/**
 * The username of the User who created this Topic
 */
@property (nonatomic, retain) NSString* username;

#pragma mark Relationship properties

/**
 * The User who created this Topic within the Discussion Board.
 * This is a Core Data relationship to the User object with the
 * primary key value contained in the userID property
 */
@property (nonatomic, retain) DBUser* user;

/**
 * The collection of Post objects that belong to this Topic. This is
 * a Core Data relationship to the collection of Posts objects
 * with a postID equal to the primary key (topicID) of this object.
 */
@property (nonatomic, retain) NSSet* posts;

/**
 * The numeric primary key for this topic in the remote backend system
 */
@property (nonatomic, retain) NSNumber* topicID;

/**
 * The numeric primary key of the User who created this Topic
 */
@property (nonatomic, retain) NSNumber* userID;

@end
