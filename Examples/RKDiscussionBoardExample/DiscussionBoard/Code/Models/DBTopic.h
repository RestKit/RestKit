//
//  DBTopic.h
//  DiscussionBoard
//
//  Created by Daniel Hammond on 1/7/11.
//  Copyright 2011 Two Toasters. All rights reserved.
//

#import "DBContentObject.h"

/**
 * Models a Topic in the Discussion Board. Users can
 * create Post's on Topics to have discussions.
 */
@interface DBTopic : DBContentObject {
}

/**
 * The name of this Topic. Identifies what we are discussing
 */
@property (nonatomic, retain) NSString* name;

#pragma mark Relationship properties

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

@end
