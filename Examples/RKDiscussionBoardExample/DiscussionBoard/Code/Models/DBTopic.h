//
//  DBTopic.h
//  DiscussionBoard
//
//  Created by Daniel Hammond on 1/7/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <RestKit/CoreData/CoreData.h>

/**
 * Models a Topic in the Discussion Board. Users can
 * create Post's on Topics to have discussions.
 */
@interface DBTopic : RKManagedObject {

}

/**
 * The numeric primary key for this topic in the remote backend system
 */
@property (nonatomic, retain) NSNumber* topicID;

/**
 * The name of this Topic. Identifies what we are discussing
 */
@property (nonatomic, retain) NSString* name;

/**
 * The numeric primary key of the User who created this Topic
 */
@property (nonatomic, retain) NSNumber* userID;

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

// TODO: Association with User

@end
